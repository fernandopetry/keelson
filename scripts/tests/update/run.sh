#!/usr/bin/env bash
# run.sh — suíte do fluxo COMPLETO do update.sh (decisões 4.57/4.189/4.386).
#
# A suíte release prova só a varredura (--reinit-scan). Aqui o script roda inteiro
# contra uma CLI `claude` FALSA no PATH (registra cada chamada; simula sucesso,
# falha, e o efeito do update: ficha reescrita + árvore nova no cache irmão) e um
# HOME temporário com ~/.claude/plugins/installed_plugins.json. Provado:
#   ordem — marketplace update ANTES de plugin update; falha do marketplace impede
#     o update (exit 1, segunda chamada nunca acontece); falha do update → exit 1;
#   scope — --scope project lê a entrada certa da ficha e repassa --scope à CLI;
#     plugin ausente no scope → exit 1 com a receita de install;
#   versão — antes/depois da ficha; inalterada → "ja estava na ultima versao";
#   re-init — o CHANGELOG lido é o da árvore NOVA (irmã, nome = versão nova), nunca o
#     da árvore velha; árvore nova ausente/divergente → "nao determinavel";
#   auto-substituição — o update troca o próprio update.sh no meio da execução e o
#     relatório final ainda sai (fluxo inteiro dentro de main(), 4.386 — o script anterior falha este caso);
#   CLI ausente → exit 1.
#
# Uso: scripts/tests/update/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
UPDATE="$HERE/../../update.sh"
[ -f "$UPDATE" ] || { echo "ERRO: update.sh não encontrado em $UPDATE" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "update: AVISO — jq ausente (a leitura confiável da ficha exige jq); pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$UPDATE" || { echo "FAIL bash -n update.sh"; exit 1; }
echo "ok   bash -n update.sh"

FAKEHOME="$TMP/home"; BIN="$TMP/bin"; CACHE="$TMP/cache/keelson/keelson"; LOG="$TMP/claude.log"
FICHA="$FAKEHOME/.claude/plugins/installed_plugins.json"

changelog() { # dir marcador-da-0.12.0
  cat > "$1/CHANGELOG.md" <<EOF
# Changelog

## [0.12.0] — 2026-08-12

Re-init: $2

## [0.11.0] — 2026-08-11

Re-init: none

## [0.10.0] — 2026-08-10

Re-init: none
EOF
}

tree() { # versao marcador → cria $CACHE/<versao> com plugin.json, CHANGELOG e cópia do update.sh
  mkdir -p "$CACHE/$1/.claude-plugin" "$CACHE/$1/scripts"
  printf '{\n  "name": "keelson",\n  "version": "%s"\n}\n' "$1" > "$CACHE/$1/.claude-plugin/plugin.json"
  changelog "$CACHE/$1" "$2"
  cp "$UPDATE" "$CACHE/$1/scripts/update.sh"; chmod +x "$CACHE/$1/scripts/update.sh"
}

ficha() { # versao scope [versao2 scope2]
  mkdir -p "$(dirname "$FICHA")"
  {
    printf '{ "version": 2, "plugins": { "keelson@keelson": [ { "scope": "%s", "version": "%s" }' "$2" "$1"
    [ -n "${3:-}" ] && printf ', { "scope": "%s", "version": "%s" }' "$4" "$3"
    printf ' ] } }\n'
  } > "$FICHA"
}

# CLI falsa: registra os argumentos; comportamento por variáveis de ambiente.
mkdir -p "$BIN"
cat > "$BIN/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_LOG"
case "$1 $2" in
  "plugin marketplace")
    [ "${FAKE_MARKETPLACE_FAIL:-0}" = "1" ] && { echo "marketplace: network error" >&2; exit 1; }
    echo "marketplace refreshed" ;;
  "plugin update")
    [ "${FAKE_UPDATE_FAIL:-0}" = "1" ] && { echo "update: not installed" >&2; exit 1; }
    scope="user"; while [ $# -gt 0 ]; do [ "$1" = "--scope" ] && scope="$2"; shift; done
    if [ -n "${FAKE_NEW_VERSION:-}" ]; then
      # efeito do update: ficha reescrita no scope pedido + árvore nova no cache irmão
      python3 - "$FAKE_FICHA" "$scope" "$FAKE_NEW_VERSION" <<'PY'
import json, sys
p, scope, v = sys.argv[1:4]
d = json.load(open(p))
for e in d["plugins"]["keelson@keelson"]:
    if e["scope"] == scope: e["version"] = v
json.dump(d, open(p, "w"))
PY
      if [ "${FAKE_SKIP_TREE:-0}" != "1" ]; then
        mkdir -p "$FAKE_CACHE/$FAKE_NEW_VERSION/.claude-plugin"
        printf '{ "name": "keelson", "version": "%s" }\n' "${FAKE_TREE_VERSION:-$FAKE_NEW_VERSION}" > "$FAKE_CACHE/$FAKE_NEW_VERSION/.claude-plugin/plugin.json"
        cp "$FAKE_NEW_CHANGELOG" "$FAKE_CACHE/$FAKE_NEW_VERSION/CHANGELOG.md"
      fi
      # auto-substituição: o update troca o próprio script em disco no meio da execução
      [ "${FAKE_CLOBBER:-0}" = "1" ] && printf '#!/usr/bin/env bash\necho "ARQUIVO NOVO — nao deveria executar"\nexit 99\n' > "$FAKE_OLD_TREE/scripts/update.sh"
    fi
    echo "plugin updated" ;;
  "plugin list") echo "keelson@keelson"; echo "  Version: 0.0.0" ;;
  *) echo "fake claude: $*" ;;
esac
exit 0
EOF
chmod +x "$BIN/claude"

NEWCL="$TMP/new-changelog.md"; mkdir -p "$TMP/n"; changelog "$TMP/n" required; mv "$TMP/n/CHANGELOG.md" "$NEWCL"

reset() { # limpa cache/ficha/log; árvore velha 0.10.0 (CHANGELOG velho com 0.12.0=none, para provar que a nova é a lida)
  rm -rf "$TMP/cache" "$FAKEHOME"; : > "$LOG"
  tree 0.10.0 none
  ficha 0.10.0 user
}

roda() { # args... → stdout+stderr em $TMP/out, exit em $st (env FAKE_* já exportado)
  ( cd "$TMP" && HOME="$FAKEHOME" PATH="$BIN:$PATH" CLAUDE_PLUGIN_ROOT="$CACHE/0.10.0" \
      FAKE_LOG="$LOG" FAKE_FICHA="$FICHA" FAKE_CACHE="$CACHE" FAKE_NEW_CHANGELOG="${FAKE_NEW_CHANGELOG:-$NEWCL}" FAKE_OLD_TREE="$CACHE/0.10.0" \
      bash "$CACHE/0.10.0/scripts/update.sh" "$@" ) > "$TMP/out" 2>&1
  st=$?
}
tem() { grep -qF -- "$1" "$TMP/out"; }
chamadas() { cat "$LOG"; }

# --- caminho feliz: ordem, versões, re-init lido da árvore NOVA ---
reset; FAKE_NEW_VERSION=0.12.0 roda
total=$((total + 1))
if [ "$st" -eq 0 ] && [ "$(chamadas)" = "plugin marketplace update keelson
plugin update keelson@keelson --scope user" ]; then ok ordem-marketplace-antes-do-update
else falha "ordem-marketplace-antes-do-update: exit=$st chamadas=[$(chamadas | tr '\n' ';')]"; fi
total=$((total + 1))
if tem "keelson instalado: 0.10.0 (scope user)" && tem "keelson atualizado: 0.10.0 -> 0.12.0"; then ok versoes-antes-depois
else falha "versoes-antes-depois: $(cat "$TMP/out")"; fi
total=$((total + 1))
if tem "ATENCAO: este salto inclui versao(oes)" && tem "Versao(oes): 0.12.0"; then ok reinit-le-changelog-da-arvore-nova
else falha "reinit-le-changelog-da-arvore-nova: $(cat "$TMP/out")"; fi
total=$((total + 1))
if tem "reinicie a sessao"; then ok avisa-reiniciar-sessao; else falha "avisa-reiniciar-sessao"; fi

# --- árvore nova com CHANGELOG limpo → veredito limpo (controle do caso acima) ---
reset; mkdir -p "$TMP/n2"; changelog "$TMP/n2" none
FAKE_NEW_VERSION=0.12.0 FAKE_NEW_CHANGELOG="$TMP/n2/CHANGELOG.md" roda
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "Re-init: nenhuma versao do salto (0.10.0 -> 0.12.0) exige"; then ok reinit-limpo-controle
else falha "reinit-limpo-controle: $(cat "$TMP/out")"; fi

# --- falhas da CLI ---
reset; FAKE_MARKETPLACE_FAIL=1 FAKE_NEW_VERSION=0.12.0 roda
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "ERRO: refresh do marketplace falhou" && [ "$(chamadas)" = "plugin marketplace update keelson" ]; then ok marketplace-falha-impede-update
else falha "marketplace-falha-impede-update: exit=$st chamadas=[$(chamadas | tr '\n' ';')]"; fi

reset; FAKE_UPDATE_FAIL=1 roda
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "ERRO: 'claude plugin update keelson@keelson' falhou"; then ok update-falha-exit-1
else falha "update-falha-exit-1: exit=$st $(cat "$TMP/out")"; fi

# --- CLI ausente ---
reset
( cd "$TMP" && HOME="$FAKEHOME" PATH="$TMP/vazio" CLAUDE_PLUGIN_ROOT="$CACHE/0.10.0" /bin/bash "$CACHE/0.10.0/scripts/update.sh" ) > "$TMP/out" 2>&1; st=$?
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "CLI 'claude' nao encontrada no PATH"; then ok cli-ausente-exit-1
else falha "cli-ausente-exit-1: exit=$st $(cat "$TMP/out")"; fi

# --- scope ---
reset; ficha 0.10.0 project
FAKE_NEW_VERSION=0.12.0 roda
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "nao esta instalado no scope 'user'" && tem "claude plugin install keelson@keelson" && [ -z "$(chamadas)" ]; then ok scope-errado-exit-1-sem-chamar-cli
else falha "scope-errado-exit-1-sem-chamar-cli: exit=$st $(cat "$TMP/out")"; fi
reset; ficha 0.9.0 user 0.10.0 project
FAKE_NEW_VERSION=0.12.0 roda --scope project
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "keelson instalado: 0.10.0 (scope project)" && tem "keelson atualizado: 0.10.0 -> 0.12.0" \
   && grep -q -- '--scope project' "$LOG" && [ "$(jq -r '.plugins["keelson@keelson"][] | select(.scope=="user") | .version' "$FICHA")" = "0.9.0" ]; then ok scope-project-preservado
else falha "scope-project-preservado: exit=$st $(cat "$TMP/out")"; fi

# --- versão inalterada ---
reset; FAKE_NEW_VERSION=0.10.0 roda
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "ja estava na ultima versao publicada (0.10.0)"; then ok versao-inalterada
else falha "versao-inalterada: exit=$st $(cat "$TMP/out")"; fi

# --- árvore nova ausente ou divergente → nao determinavel (nunca lê o CHANGELOG velho) ---
reset; FAKE_NEW_VERSION=0.12.0 FAKE_SKIP_TREE=1 roda
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "nao localizei a arvore instalada da versao 0.12.0" && ! tem "Re-init: nenhuma"; then ok arvore-nova-ausente-degrada
else falha "arvore-nova-ausente-degrada: $(cat "$TMP/out")"; fi
reset; FAKE_NEW_VERSION=0.12.0 FAKE_TREE_VERSION=0.11.9 roda
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "nao localizei a arvore instalada da versao 0.12.0"; then ok arvore-nova-divergente-degrada
else falha "arvore-nova-divergente-degrada: $(cat "$TMP/out")"; fi

# --- auto-substituição do próprio script no meio da execução ---
reset; FAKE_NEW_VERSION=0.12.0 FAKE_CLOBBER=1 roda
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "keelson atualizado: 0.10.0 -> 0.12.0" && ! tem "ARQUIVO NOVO"; then ok sobrevive-a-auto-substituicao
else falha "sobrevive-a-auto-substituicao: exit=$st $(cat "$TMP/out")"; fi

# --- uso incorreto do modo de teste continua exit 2 ---
total=$((total + 1))
bash "$UPDATE" --reinit-scan 0.1.0 >/dev/null 2>&1; st=$?
if [ "$st" -eq 2 ]; then ok reinit-scan-args-exit-2; else falha "reinit-scan-args-exit-2: $st"; fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "update: $fail de $total casos falharam"
  exit 1
fi
echo "update: $total casos verdes"
exit 0
