#!/usr/bin/env bash
# update.sh — atualiza o plugin keelson instalado, via CLI do Claude Code
# (decisão 4.57). Invocado pelo /keelson:update; rodável também à mão.
#
# Uso: update.sh [--scope user|project|local]
#      update.sh --reinit-scan <before> <after> <changelog>   (só a varredura — testes)
#
# Passos: refresh do marketplace E update do plugin — nesta ordem, porque
# atualizar só o marketplace NÃO atualiza o plugin instalado (README, Install).
# A versão antes/depois vem da ficha de plugins da CLI
# (~/.claude/plugins/installed_plugins.json, via jq, selecionada pelo scope);
# sem jq, cai para o parse best-effort de `claude plugin list`.
# Após o update, lê o CHANGELOG.md recém-instalado (marcadores
# "Re-init: required|none" por entrada — decisão 4.189) e reporta se alguma
# versão do salto (BEFORE, AFTER] exige re-rodar /keelson:init no consumidor.
# Sem CHANGELOG legível, sem marcador ou com a árvore lida divergindo da versão
# instalada, degrada para "não determinável" — nunca afirma "não precisa" sem
# evidência (régua da 4.156).
# O que NÃO faz: recarregar a sessão — o update só vale após reiniciar a
# sessão do Claude Code, e o script termina dizendo exatamente isso.
#
# Bash 3.2-compatível. Diferente dos hooks, aqui falhar alto é o correto:
# o humano invocou pedindo o update — CLI ausente, plugin não instalado ou
# update falho é erro nomeado (exit 1), nunca silêncio.
#
# Nota de implementação: `claude plugin update` SUBSTITUI este próprio arquivo
# no meio da execução — toda a lógica pós-update vive em funções definidas
# aqui no topo (parseadas antes da mutação) e o rodapé do script é uma única
# linha de chamada.

set -u
LC_ALL=C
export LC_ALL

PLUGIN="keelson"
MARKETPLACE="keelson"
PLUGIN_ID="${PLUGIN}@${MARKETPLACE}"
INSTALLED_JSON="${HOME}/.claude/plugins/installed_plugins.json"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Leitura confiável (ficha + jq, filtrada pelo scope) ou fallback best-effort
# (parse de `claude plugin list`). Nunca aborta: erro de leitura → vazio.
can_read_ficha() {
  [ -f "$INSTALLED_JSON" ] && command -v jq >/dev/null 2>&1
}

installed_version() {
  if can_read_ficha; then
    jq -r --arg id "$PLUGIN_ID" --arg scope "$SCOPE" \
      '(.plugins[$id] // []) | map(select(.scope == $scope)) | (.[0].version // "")' \
      "$INSTALLED_JSON" 2>/dev/null || true
  else
    claude plugin list 2>/dev/null \
      | awk -v id="$PLUGIN_ID" '$0 ~ id {found=1; next} found && /Version:/ {print $2; exit}' \
      || true
  fi
}

jsonver() {
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$1" 2>/dev/null | head -1
}

# --- Detecção de re-init (decisão 4.189) ---
# Varre o CHANGELOG no intervalo (before, after] — o arquivo é newest-first,
# então lê do topo a partir de "## [after]" e para em "## [before]" — e
# classifica cada versão pelo marcador "Re-init: required|none". Degrada para
# "não determinável" quando não há evidência; nunca inventa "não precisa".
reinit_scan() {
  rs_before="$1"; rs_after="$2"; rs_changelog="$3"

  if [ ! -f "$rs_changelog" ]; then
    echo "Re-init: nao determinavel — CHANGELOG.md nao encontrado no plugin instalado."
    echo "Confira no repositorio do keelson se alguma versao do salto exige /keelson:init."
    return 0
  fi

  rs_out="$(awk -v before="$rs_before" -v after="$rs_after" '
    /^## \[[0-9]/ {
      v = $0; sub(/^## \[/, "", v); sub(/\].*/, "", v)
      if (v == before) { found_before = 1; exit }
      if (v == after) { active = 1 }
      if (active) { cur = v; n++; order[n] = cur; verdict[cur] = "missing" }
      next
    }
    active && cur != "" && /^Re-init:/ {
      val = $0; sub(/^Re-init:[ \t]*/, "", val)
      if (val == "required" || val == "none") verdict[cur] = val
      next
    }
    END {
      if (!found_before) { print "NOBEFORE"; exit }
      if (n == 0)        { print "NOAFTER";  exit }
      req = ""; ind = ""
      for (i = 1; i <= n; i++) {
        v = order[i]
        if (verdict[v] == "required")  req = req " " v
        else if (verdict[v] != "none") ind = ind " " v
      }
      print "REQ:" req
      print "IND:" ind
    }' "$rs_changelog")"

  case "$rs_out" in
    NOBEFORE)
      echo "Re-init: nao determinavel — a versao anterior ($rs_before) nao aparece no"
      echo "CHANGELOG instalado; nao da para delimitar o salto. Confira o CHANGELOG a mao." ;;
    NOAFTER)
      echo "Re-init: nao determinavel — a entrada da versao instalada ($rs_after) nao"
      echo "aparece no CHANGELOG lido. Confira o CHANGELOG a mao." ;;
    *)
      rs_req="$(printf '%s\n' "$rs_out" | sed -n 's/^REQ: *//p')"
      rs_ind="$(printf '%s\n' "$rs_out" | sed -n 's/^IND: *//p')"
      if [ -n "$rs_req" ]; then
        echo "ATENCAO: este salto inclui versao(oes) que mudaram o bloco do CLAUDE.md ou a"
        echo "ficha — re-rode /keelson:init apos reiniciar a sessao. Versao(oes): $rs_req"
      elif [ -n "$rs_ind" ]; then
        echo "Re-init: nao determinavel para a(s) versao(oes): $rs_ind (entrada sem marcador"
        echo "\"Re-init:\" no CHANGELOG). Confira essas entradas a mao antes de assumir que nao."
      else
        echo "Re-init: nenhuma versao do salto ($rs_before -> $rs_after) exige /keelson:init."
      fi ;;
  esac
}

# Report final (roda DEPOIS de `claude plugin update` substituir este arquivo
# em disco — por isso é função, parseada antes).
final_report() {
  AFTER="$(installed_version)"

  echo ""
  if [ -n "$BEFORE" ] && [ "$AFTER" = "$BEFORE" ]; then
    echo "keelson ja estava na ultima versao publicada ($BEFORE). Nada a fazer."
    return 0
  fi

  if [ -n "$AFTER" ]; then
    echo "keelson atualizado: ${BEFORE:-?} -> $AFTER"
  else
    echo "Update aplicado (versao nao exibida — ficha/jq indisponiveis)."
  fi

  echo ""
  if [ -z "$BEFORE" ] || [ -z "$AFTER" ]; then
    echo "Re-init: nao determinavel — sem as versoes antes/depois nao da para delimitar"
    echo "o salto. Confira o CHANGELOG do keelson a mao."
  else
    # O cache da CLI é versionado (…/cache/keelson/keelson/<versão>/): este
    # script roda da árvore ANTIGA, e a nova nasce no diretório irmão com o
    # nome de $AFTER. Candidatos em ordem; só vale árvore cuja versão bate
    # com $AFTER — divergiu, degrada (nunca ler CHANGELOG velho e afirmar).
    TREE=""
    for cand in "$(dirname "$PLUGIN_DIR")/$AFTER" "$PLUGIN_DIR"; do
      [ -f "$cand/.claude-plugin/plugin.json" ] || continue
      if [ "$(jsonver "$cand/.claude-plugin/plugin.json")" = "$AFTER" ]; then
        TREE="$cand"; break
      fi
    done
    if [ -n "$TREE" ]; then
      reinit_scan "$BEFORE" "$AFTER" "$TREE/CHANGELOG.md"
    else
      echo "Re-init: nao determinavel — nao localizei a arvore instalada da versao $AFTER"
      echo "para ler o CHANGELOG. Confira o CHANGELOG do keelson a mao."
    fi
  fi

  echo ""
  echo "A sessao corrente continua na versao antiga — reinicie a sessao do"
  echo "Claude Code para carregar a versao nova."
}

# Entrada de teste: só a varredura, sem tocar na CLI (usada pela suíte
# scripts/tests/release/run.sh).
if [ "${1:-}" = "--reinit-scan" ]; then
  [ $# -eq 4 ] || { echo "Uso: update.sh --reinit-scan <before> <after> <changelog>" >&2; exit 2; }
  reinit_scan "$2" "$3" "$4"
  exit 0
fi

SCOPE="user"
if [ "${1:-}" = "--scope" ] && [ -n "${2:-}" ]; then
  SCOPE="$2"
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "ERRO: CLI 'claude' nao encontrada no PATH — impossivel atualizar o plugin." >&2
  echo "Garanta a CLI do Claude Code no PATH e rode de novo: /keelson:update" >&2
  exit 1
fi

BEFORE="$(installed_version)"

# Gate "não instalado": só quando a leitura é confiável — no fallback, vazio
# significa "não sei ler", não "não instalado", e o update segue best-effort.
if [ -z "$BEFORE" ] && can_read_ficha; then
  echo "ERRO: plugin '$PLUGIN_ID' nao esta instalado no scope '$SCOPE'." >&2
  echo "Instale com: claude plugin install $PLUGIN_ID" >&2
  echo "(ja instalado? confira o scope real com 'claude plugin list' e repasse via --scope)" >&2
  exit 1
fi

if [ -n "$BEFORE" ]; then
  echo "keelson instalado: $BEFORE (scope $SCOPE)"
fi

echo "==> claude plugin marketplace update $MARKETPLACE"
if ! claude plugin marketplace update "$MARKETPLACE"; then
  echo "ERRO: refresh do marketplace falhou — sem ele o update usaria o cache velho" >&2
  echo "e reportaria 'ja atualizado' sem estar. Veja a saida acima (rede? git?)." >&2
  exit 1
fi

echo "==> claude plugin update $PLUGIN_ID --scope $SCOPE"
if ! claude plugin update "$PLUGIN_ID" --scope "$SCOPE"; then
  echo "ERRO: 'claude plugin update $PLUGIN_ID' falhou — veja a saida acima." >&2
  echo "Causas tipicas: plugin nao instalado via marketplace neste scope" >&2
  echo "(tente --scope project|local) ou instalacao de desenvolvimento (skills-dir)." >&2
  exit 1
fi

final_report
