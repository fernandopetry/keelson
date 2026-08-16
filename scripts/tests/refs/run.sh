#!/usr/bin/env bash
# run.sh — suíte de regressão do check-refs.sh (contrato: cabeçalho do próprio script, 4.209).
#
# Cada fixture é uma árvore que vira repo git temporário (o check enumera por
# `git ls-files`). Regra da suíte (mesma do map/graph): fixture válida sai limpa
# (zero achado espúrio) e TODO defeito plantado é acusado — o controle positivo
# da 4.186 é a fixture `plantada`, cujos 3 ponteiros quebrados têm de aparecer
# na saída congelada em expected/. Caso novo de extração → fixture nova.
#
# Uso: scripts/tests/refs/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-refs.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-refs.sh não encontrado em $CHECK" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git (ls-files)" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # $1 = fixture, $2 = exit esperado
  fx="$1"; want="$2"
  total=$((total + 1))
  repo="$TMP/$fx"
  mkdir -p "$repo"
  cp -R "$FIX/$fx/tree/." "$repo/"
  git -C "$repo" init -q
  git -C "$repo" add -A
  out="$(bash "$CHECK" --root "$repo" 2>&1)"
  got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FALHA [$fx]: exit $got (esperado $want)" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  if ! printf '%s\n' "$out" | diff -u "$EXP/$fx.out" - >/dev/null 2>&1; then
    echo "FALHA [$fx]: saída diverge do esperado" >&2
    printf '%s\n' "$out" | diff -u "$EXP/$fx.out" - | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  echo "ok [$fx]"
}

runcase limpa 0
runcase plantada 1

if [ "$fail" -gt 0 ]; then
  echo "suíte refs: $fail/$total caso(s) falharam." >&2
  exit 1
fi
echo "suíte refs: $total/$total casos verdes."
exit 0
