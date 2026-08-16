#!/usr/bin/env bash
# run.sh — suíte de regressão do check-frontmatter.sh (contrato: cabeçalho do script, 4.211).
#
# Três casos: fixture válida sai limpa; fixture quebrada tem TODO defeito plantado
# acusado no modo estrito (controle positivo 4.186 — inclui o erro literal que o
# GitHub mostrou em campo); e o fallback heurístico (python3 indisponível, simulado
# por shim) acusa a classe colon-space com aviso. Limite conhecido do fallback:
# frontmatter sem fechamento só é acusado no modo estrito.
#
# Uso: scripts/tests/frontmatter/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-frontmatter.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-frontmatter.sh não encontrado em $CHECK" >&2; exit 1; }
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "ERRO: a suíte exige python3+PyYAML (o modo estrito é o que ela prova)" >&2
  exit 1
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # $1 = nome do caso, $2 = fixture, $3 = exit esperado, $4 = PATH extra (shim) ou ""
  nome="$1"; fx="$2"; want="$3"; shim="$4"
  total=$((total + 1))
  tree="$TMP/$nome"
  mkdir -p "$tree"
  cp -R "$FIX/$fx/tree/." "$tree/"
  if [ -n "$shim" ]; then
    out="$(PATH="$shim:$PATH" bash "$CHECK" --root "$tree" 2>&1)"
  else
    out="$(bash "$CHECK" --root "$tree" 2>&1)"
  fi
  got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FALHA [$nome]: exit $got (esperado $want)" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  if ! printf '%s\n' "$out" | diff -u "$EXP/$nome.out" - >/dev/null 2>&1; then
    echo "FALHA [$nome]: saída diverge do esperado" >&2
    printf '%s\n' "$out" | diff -u "$EXP/$nome.out" - | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  echo "ok [$nome]"
}

# Shim: python3 "ausente" (falha em qualquer chamada) → força o fallback heurístico.
mkdir -p "$TMP/bin"
printf '#!/bin/sh\nexit 1\n' > "$TMP/bin/python3"
chmod +x "$TMP/bin/python3"

runcase valida     valida   0 ""
runcase quebrada   quebrada 1 ""
runcase heuristica quebrada 1 "$TMP/bin"

if [ "$fail" -gt 0 ]; then
  echo "suíte frontmatter: $fail/$total caso(s) falharam." >&2
  exit 1
fi
echo "suíte frontmatter: $total/$total casos verdes."
exit 0
