#!/usr/bin/env bash
# version.sh — qual keelson está rodando NESTA sessão, e como ele se compara ao que
# a CLI diz ter instalado (decisão 4.381). Invocado pelo /keelson:version; rodável
# também à mão.
#
# Uso: version.sh [--root <dir>] [--plugins-dir <dir>]
#   --root         raiz do plugin carregado (default: $CLAUDE_PLUGIN_ROOT, senão a
#                  árvore deste script)
#   --plugins-dir  loja da CLI (default: ~/.claude/plugins) — para testes
#
# O que reporta, nesta ordem:
#   1. a versão CARREGADA — lida de <root>/.claude-plugin/plugin.json, o único fato
#      sobre o que esta sessão executa (a ficha da CLI pode dizer outra coisa);
#   2. a origem da árvore: cache da CLI · repositório de desenvolvimento · loja própria
#      do Claude Desktop · fora da loja da CLI (caso real: Desktop congelado numa
#      versão enquanto a CLI dizia "já atualizado" — o /keelson:update lê a ficha da
#      CLI e é cego à cópia que a sessão carregou);
#   3. a ficha da CLI (installed_plugins.json), uma linha por scope, marcando a que
#      aponta para esta árvore;
#   4. o cache local do marketplace — a última versão CONHECIDA, do último refresh,
#      nunca "a última publicada" (não há rede aqui: refresh é o /keelson:update);
#   5. um veredito de uma linha por comparação, com a ação (reiniciar a sessão ·
#      /keelson:update · atualizar pelo app).
#
# Read-only, sem rede, sem chamar a CLI (`claude --version` é a única exceção,
# best-effort, para o report de bug). Bash 3.2-compatível; jq quando existe (leitura
# confiável da ficha), fallback sed/awk best-effort sem ele. Nunca aborta por falta de
# arquivo: cada fonte ausente vira linha "nao encontrado" — o que não se sabe, se diz.
# Exit: 0 report emitido · 2 uso incorreto ou raiz sem plugin.json.

set -u
LC_ALL=C
export LC_ALL

PLUGIN_ID="keelson@keelson"
ROOT=""
PLUGINS_DIR="${HOME}/.claude/plugins"

while [ $# -gt 0 ]; do
  case "$1" in
    --root) shift; [ $# -gt 0 ] || { echo "ERRO: --root exige um caminho." >&2; exit 2; }; ROOT="$1" ;;
    --plugins-dir) shift; [ $# -gt 0 ] || { echo "ERRO: --plugins-dir exige um caminho." >&2; exit 2; }; PLUGINS_DIR="$1" ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

[ -n "$ROOT" ] || ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "ERRO: raiz do plugin nao existe." >&2; exit 2; }

jsonver() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$1" 2>/dev/null | head -1; }

# Compara versões X.Y.Z numericamente: imprime -1, 0 ou 1 (a < b, a = b, a > b).
vercmp() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, pa, "."); nb = split(b, pb, ".")
    n = (na > nb) ? na : nb
    for (i = 1; i <= n; i++) {
      x = (i <= na) ? pa[i] + 0 : 0; y = (i <= nb) ? pb[i] + 0 : 0
      if (x < y) { print -1; exit } if (x > y) { print 1; exit }
    }
    print 0
  }'
}

# --- 1. versão carregada ---
PJ="$ROOT/.claude-plugin/plugin.json"
if [ ! -f "$PJ" ]; then
  echo "ERRO: $PJ nao existe — a raiz informada nao e um plugin keelson." >&2
  exit 2
fi
LOADED="$(jsonver "$PJ")"
[ -n "$LOADED" ] || { echo "ERRO: nao achei \"version\" em $PJ." >&2; exit 2; }

CHARTER=""
CH="$ROOT/guidelines/_meta/QUALITY-CHARTER.md"
[ -f "$CH" ] && CHARTER="$(sed -n 's/.*\*\*Versao: *\([0-9][0-9.]*\)\*\*.*/\1/p; s/.*\*\*Versão: *\([0-9][0-9.]*\)\*\*.*/\1/p' "$CH" | head -1)"

if [ -n "$CHARTER" ]; then
  echo "keelson carregado nesta sessao: $LOADED (Quality Charter $CHARTER)"
else
  echo "keelson carregado nesta sessao: $LOADED"
fi
echo "  raiz: $ROOT"

# --- 2. origem da árvore ---
CACHE_DIR="$PLUGINS_DIR/cache/keelson/keelson"
ORIGIN=""
case "$ROOT" in
  "$CACHE_DIR"/*) ORIGIN="cli-cache" ;;
  */local-agent-mode-sessions/*/rpm/plugin_*) ORIGIN="desktop" ;;
  *)
    if [ -e "$ROOT/.git" ]; then ORIGIN="dev"; else ORIGIN="other"; fi ;;
esac
case "$ORIGIN" in
  cli-cache) echo "  origem: cache da CLI ($CACHE_DIR/<versao>)" ;;
  desktop)   echo "  origem: loja propria do Claude Desktop (--plugin-dir), separada da loja da CLI" ;;
  dev)       echo "  origem: repositorio de desenvolvimento (arvore com .git)" ;;
  other)     echo "  origem: fora da loja da CLI (--plugin-dir ou copia avulsa)" ;;
esac

# --- 3. ficha da CLI (installed_plugins.json) ---
FICHA="$PLUGINS_DIR/installed_plugins.json"
FICHA_LINES=""   # "scope|version|installPath" por linha
FICHA_STATE="ausente"
if [ -f "$FICHA" ]; then
  if command -v jq >/dev/null 2>&1; then
    FICHA_LINES="$(jq -r --arg id "$PLUGIN_ID" \
      '(.plugins[$id] // []) | .[] | "\(.scope // "?")|\(.version // "")|\(.installPath // "")"' \
      "$FICHA" 2>/dev/null)" && FICHA_STATE="jq" || { FICHA_LINES=""; FICHA_STATE="ilegivel"; }
  else
    # Best-effort sem jq: isola o array do plugin, quebra por objeto e extrai os campos.
    FICHA_LINES="$(tr -d '\n' < "$FICHA" | sed -n 's/.*"'"$PLUGIN_ID"'"[[:space:]]*:[[:space:]]*\[\(.*\)/\1/p' \
      | awk 'BEGIN { RS = "}" }
        /"scope"/ {
          s = ""; v = ""; p = ""
          if (match($0, /"scope"[[:space:]]*:[[:space:]]*"[^"]*"/)) { s = substr($0, RSTART, RLENGTH); sub(/.*:[[:space:]]*"/, "", s); sub(/"$/, "", s) }
          if (match($0, /"version"[[:space:]]*:[[:space:]]*"[^"]*"/)) { v = substr($0, RSTART, RLENGTH); sub(/.*:[[:space:]]*"/, "", v); sub(/"$/, "", v) }
          if (match($0, /"installPath"[[:space:]]*:[[:space:]]*"[^"]*"/)) { p = substr($0, RSTART, RLENGTH); sub(/.*:[[:space:]]*"/, "", p); sub(/"$/, "", p) }
          print s "|" v "|" p
        }
        /\]/ { exit }')"
    FICHA_STATE="best-effort"
  fi
fi

echo "instalado na CLI (ficha $FICHA):"
THIS_SCOPES=""    # scopes cuja installPath == ROOT
OTHER_VERSIONS="" # "scope:version" dos scopes que apontam para outra árvore
case "$FICHA_STATE" in
  ausente)  echo "  ficha nao encontrada — plugin nao instalado pela CLI nesta maquina, ou loja em outro lugar" ;;
  ilegivel) echo "  ficha ilegivel (jq falhou ao ler o arquivo)" ;;
  *)
    if [ -z "$FICHA_LINES" ]; then
      echo "  $PLUGIN_ID nao consta na ficha (nenhum scope)"
    else
      [ "$FICHA_STATE" = "best-effort" ] && echo "  (leitura best-effort sem jq)"
      printf '%s\n' "$FICHA_LINES" | while IFS='|' read -r scope ver path; do
        [ -n "$scope" ] || continue
        if [ -n "$path" ] && [ "$path" = "$ROOT" ]; then
          echo "  $scope: ${ver:-?}  <- esta sessao"
        else
          echo "  $scope: ${ver:-?}"
        fi
      done
      THIS_SCOPES="$(printf '%s\n' "$FICHA_LINES" | awk -F'|' -v r="$ROOT" '$3 == r { printf "%s%s", sep, $1; sep = " " }')"
      OTHER_VERSIONS="$(printf '%s\n' "$FICHA_LINES" | awk -F'|' -v r="$ROOT" '$3 != r && $2 != "" { printf "%s%s:%s", sep, $1, $2; sep = " " }')"
    fi ;;
esac

# --- 4. cache local do marketplace ---
MK="$PLUGINS_DIR/marketplaces/keelson/.claude-plugin/marketplace.json"
KNOWN="$PLUGINS_DIR/known_marketplaces.json"
MK_VER=""
MK_DATE=""
if [ -f "$MK" ]; then
  MK_VER="$(jsonver "$MK")"
  if [ -f "$KNOWN" ]; then
    if command -v jq >/dev/null 2>&1; then
      MK_DATE="$(jq -r '.keelson.lastUpdated // ""' "$KNOWN" 2>/dev/null || true)"
    else
      MK_DATE="$(tr -d '\n' < "$KNOWN" | sed -n 's/.*"keelson"[[:space:]]*:[[:space:]]*{[^}]*"lastUpdated"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
  fi
fi
if [ -n "$MK_VER" ]; then
  echo "marketplace (cache local, ultimo refresh ${MK_DATE:-em data desconhecida}): $MK_VER"
else
  echo "marketplace: cache local nao encontrado ($MK)"
fi

# --- 5. Claude Code (best-effort, para o report de bug) ---
if command -v claude >/dev/null 2>&1; then
  CC="$(claude --version 2>/dev/null | head -1)"
  echo "Claude Code: ${CC:-versao nao exibida}"
else
  echo "Claude Code: CLI 'claude' nao encontrada no PATH"
fi

# --- 6. veredito ---
echo ""
case "$ORIGIN" in
  desktop)
    echo "ATENCAO: esta sessao carrega a copia da loja do Claude Desktop — o /keelson:update"
    echo "atualiza a loja da CLI e NAO alcanca esta copia. Atualize o plugin pelo gerenciador"
    echo "de plugins do proprio app (re-sync do marketplace) e reabra a sessao." ;;
  other)
    echo "ATENCAO: esta sessao carrega uma arvore fora da loja da CLI — o /keelson:update nao"
    echo "a alcanca. Atualize essa copia por onde ela foi instalada (--plugin-dir)." ;;
  dev)
    echo "Arvore de desenvolvimento: a versao e a do checkout, nao a de uma instalacao." ;;
  cli-cache)
    if [ "$FICHA_STATE" = "ausente" ] || [ "$FICHA_STATE" = "ilegivel" ] || [ -z "$FICHA_LINES" ]; then
      echo "Nao da para comparar com a ficha da CLI (ver acima)."
    elif [ -n "$THIS_SCOPES" ]; then
      echo "Sessao e instalacao coincidem (scope: $THIS_SCOPES)."
    else
      echo "ATENCAO: a ficha da CLI nao aponta mais para esta arvore ($OTHER_VERSIONS) — update"
      echo "aplicado sem reiniciar a sessao? A sessao corrente continua em $LOADED; reinicie-a."
    fi ;;
esac

if [ -n "$MK_VER" ]; then
  case "$(vercmp "$LOADED" "$MK_VER")" in
    -1) echo "Ha versao mais nova conhecida no marketplace: $MK_VER (esta sessao: $LOADED)."
        case "$ORIGIN" in
          cli-cache) echo "Atualize com /keelson:update — a versao nova so carrega ao reiniciar a sessao." ;;
        esac ;;
    0)  echo "E a ultima versao conhecida no cache local do marketplace. Para checar a publicada:"
        echo "/keelson:update (faz o refresh e atualiza, se houver)." ;;
    1)  echo "A frente do marketplace conhecido ($MK_VER) — cache velho ou arvore de desenvolvimento." ;;
  esac
else
  echo "Sem cache do marketplace nao da para dizer se ha versao mais nova; /keelson:update faz o refresh."
fi

exit 0
