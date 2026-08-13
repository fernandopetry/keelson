#!/usr/bin/env bash
# check-release.sh — verificações mecânicas de release (decisão 4.83).
#
# O que a doutrina exige e este script prova:
#   - versão sincronizada nos 3 lugares: .claude-plugin/plugin.json ·
#     .claude-plugin/marketplace.json · seção Status do README.md
#   - a versão atual tem entrada "## [X.Y.Z]" no CHANGELOG.md (§4.48: bump sem
#     entrada é release incompleto)
#   - a entrada da versão atual declara "Re-init: required|none" (§4.189: é o
#     que o update.sh lê para avisar o consumidor sobre re-rodar o init)
#   - todo espelho do MIRRORS (scripts/publish-wiki.sh) aponta para arquivo existente
#   - bash -n em todos os scripts do repo (scripts/*.sh, git-hooks, testes)
#
# Uso: check-release.sh [--root <dir>]   (default: raiz do repo via git)
# Exit: 0 tudo certo · 1 violações (todas listadas de uma vez) · 2 uso incorreto.
# Bash 3.2-compatível, sem jq — os campos são extraídos por sed/grep.

set -u
LC_ALL=C
export LC_ALL

ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) shift; [ $# -gt 0 ] || { echo "ERRO: --root exige um caminho." >&2; exit 2; }; ROOT="$1" ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || { echo "ERRO: fora de um repo git e sem --root." >&2; exit 2; }
fi
cd "$ROOT" || { echo "ERRO: não consegui entrar em $ROOT" >&2; exit 2; }

fails=0
fail() { echo "FALHA: $*"; fails=$((fails + 1)); }
ok()   { echo "ok    $*"; }

jsonver() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$1" 2>/dev/null | head -1; }

# --- 1. Versão sincronizada nos 3 lugares ---
VP="$(jsonver .claude-plugin/plugin.json)"
VM="$(jsonver .claude-plugin/marketplace.json)"
VR="$(sed -n 's/^`\([0-9][0-9.]*\)`.*/\1/p' README.md 2>/dev/null | head -1)"

[ -n "$VP" ] || fail "não achei a versão em .claude-plugin/plugin.json"
[ -n "$VM" ] || fail "não achei a versão em .claude-plugin/marketplace.json"
[ -n "$VR" ] || fail "não achei a versão na seção Status do README.md (linha \`X.Y.Z\`)"
if [ -n "$VP" ] && [ -n "$VM" ] && [ -n "$VR" ]; then
  if [ "$VP" = "$VM" ] && [ "$VP" = "$VR" ]; then
    ok "versão $VP sincronizada nos 3 lugares"
  else
    fail "versões divergem: plugin.json=$VP marketplace.json=$VM README=$VR"
  fi
fi

# --- 2. CHANGELOG tem a entrada da versão atual (§4.48) ---
if [ -n "$VP" ]; then
  if grep -q "^## \[$VP\]" CHANGELOG.md 2>/dev/null; then
    ok "CHANGELOG.md tem a entrada [$VP]"
  else
    fail "CHANGELOG.md sem entrada \"## [$VP]\" — bump sem entrada é release incompleto (§4.48)"
  fi
fi

# --- 2b. Entrada da versão atual declara o marcador Re-init (§4.189) ---
# Escopo restrito à versão corrente ($VP), nunca ao arquivo inteiro: um marcador
# esquecido numa entrada histórica não pode bloquear commits que nada têm a ver.
if [ -n "$VP" ] && grep -q "^## \[$VP\]" CHANGELOG.md 2>/dev/null; then
  if sed -n "/^## \[$VP\]/,/^## \[/p" CHANGELOG.md \
       | grep -qE '^Re-init: (required|none)$'; then
    ok "entrada [$VP] declara o marcador Re-init"
  else
    fail "entrada [$VP] do CHANGELOG.md sem a linha \"Re-init: required\" ou \"Re-init: none\" (§4.189)"
  fi
fi
if [ -f scripts/publish-wiki.sh ]; then
  miss=0
  for src in $(sed -n "/^MIRRORS='/,/'\$/p" scripts/publish-wiki.sh \
                 | sed -e "s/^MIRRORS='//" -e "s/'\$//" | cut -d'|' -f1); do
    [ -n "$src" ] || continue
    if [ ! -f "$src" ]; then fail "MIRRORS aponta para arquivo inexistente: $src"; miss=1; fi
  done
  [ "$miss" -eq 0 ] && ok "todos os espelhos do MIRRORS existem"
else
  fail "scripts/publish-wiki.sh não encontrado"
fi

# --- 4. bash -n em todos os scripts ---
bad=0
for f in scripts/*.sh scripts/git-hooks/* scripts/tests/*/run.sh; do
  [ -f "$f" ] || continue
  if ! bash -n "$f" 2>/dev/null; then
    fail "bash -n falhou em $f"
    bash -n "$f" 2>&1 | sed 's/^/      /'
    bad=1
  fi
done
[ "$bad" -eq 0 ] && ok "bash -n limpo em todos os scripts"

echo ""
if [ "$fails" -gt 0 ]; then
  echo "check-release: $fails violação(ões)."
  exit 1
fi
echo "check-release: tudo certo."
exit 0
