#!/usr/bin/env bash
# run.sh — suíte de regressão do check-doctrine.sh (contrato: cabeçalho do próprio script, 4.442).
#
# Cada fixture é uma árvore que vira repo git temporário (o check enumera por
# `git ls-files`). Regra da suíte (mesma do refs/graph): fixture válida sai limpa —
# zero achado espúrio, inclusive nas formas que PARECEM história e não são (SHA
# ilustrativo `a1b2c3d`, "deixa de ser" no presente, comentário `#` de hook, perfil de
# linguagem com "deixou de existir no PHP 8", citação `(4.NNN)`) — e TODO defeito
# plantado é acusado: uma ocorrência de cada classe textual, uma linha acima do teto
# duro e um arquivo cuja contagem de linhas longas passou da baseline (catraca). O
# controle positivo da 4.186 é a fixture `plantada`, com a saída congelada em expected/.
# Caso novo de classe → fixture nova (ou linha nova na plantada + expected regravado).
#
# Uso: scripts/tests/doctrine/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-doctrine.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-doctrine.sh não encontrado em $CHECK" >&2; exit 1; }
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

# --write-baseline regrava a partir do estado e sai 0; a rodada seguinte é limpa.
runbaseline() {
  total=$((total + 1))
  repo="$TMP/baseline"
  mkdir -p "$repo"
  cp -R "$FIX/plantada/tree/." "$repo/"
  git -C "$repo" init -q
  git -C "$repo" add -A
  rm -f "$repo/scripts/doctrine-baseline.tsv"
  if ! bash "$CHECK" --root "$repo" --write-baseline >/dev/null 2>&1; then
    echo "FALHA [baseline]: --write-baseline saiu com erro" >&2; fail=$((fail + 1)); return
  fi
  if ! grep -q '^commands/tasks.md	2$' "$repo/scripts/doctrine-baseline.tsv"; then
    echo "FALHA [baseline]: baseline não registrou commands/tasks.md com 2 linhas longas" >&2
    sed 's/^/    /' "$repo/scripts/doctrine-baseline.tsv" >&2
    fail=$((fail + 1)); return
  fi
  out="$(bash "$CHECK" --root "$repo" 2>&1)"
  if printf '%s\n' "$out" | grep -q 'monolito-cresceu'; then
    echo "FALHA [baseline]: catraca ainda acusa depois de regravar a baseline" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    fail=$((fail + 1)); return
  fi
  echo "ok [baseline]"
}

runcase limpa 0
runcase plantada 1
runbaseline

if [ "$fail" -gt 0 ]; then
  echo "doctrine: $fail de $total caso(s) FALHARAM" >&2
  exit 1
fi
echo "doctrine: $total casos verdes"
exit 0
