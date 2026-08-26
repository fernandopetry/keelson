#!/usr/bin/env bash
# run.sh — corpus de regressão dos motores mecânicos (decisão 4.260).
#
# fixtures/corpus é um slug SDD sintético-REALISTA (formas de campo multi-linha,
# AC citado em continuação de item, anotação parentética legada, transversal,
# bugfix com repro, closures preenchidas, roteiro do gate 9) — a variedade que as
# fixtures mínimas das suítes por-motor não têm. As saídas de TODOS os motores
# read-only ficam congeladas em expected/: evolução que muda a leitura do corpus
# aparece como diff e exige justificativa na decisão da leva (nunca "aceitar o
# diff sem olhar"). Prova de origem: os motores pré-4.254 falham esta suíte
# (ac-sem-task falso no AC em continuação, task-criterio-sem-ac falso na mesma
# TASK) — é o cinto contra reintroduzir a classe.
#
# Uso: scripts/tests/corpus/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$HERE/../.."
FIX="$HERE/fixtures"
EXP="$HERE/expected"

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome comando... (compara com $EXP/<nome>.txt; exit esperado no $2)
  name="$1"; wantexit="$2"; shift 2
  total=$((total + 1))
  out="$TMP/$name.out"
  ( cd "$FIX" && "$@" ) > "$out" 2> "$TMP/$name.err"
  got=$?
  if [ "$got" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $got (esperado $wantexit)"
    sed 's/^/  stderr: /' "$TMP/$name.err"
    fail=$((fail + 1)); return
  fi
  if ! diff -u "$EXP/$name.txt" "$out" > "$TMP/$name.diff" 2>&1; then
    echo "FAIL $name: saída difere do esperado (mudança de leitura do corpus exige justificativa na decisão)"
    head -40 "$TMP/$name.diff" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

runcase graph--check    0 bash "$SCRIPTS/graph.sh" corpus --check
runcase graph--tsv      0 bash "$SCRIPTS/graph.sh" corpus --format=tsv
runcase artifact-lint   0 bash "$SCRIPTS/artifact-lint.sh" corpus
runcase index-check     0 bash "$SCRIPTS/index-check.sh" corpus

# determinismo: duas execuções do TSV idênticas byte a byte
total=$((total + 1))
( cd "$FIX" && bash "$SCRIPTS/graph.sh" corpus --format=tsv ) > "$TMP/t1.out" 2>/dev/null
( cd "$FIX" && bash "$SCRIPTS/graph.sh" corpus --format=tsv ) > "$TMP/t2.out" 2>/dev/null
if cmp -s "$TMP/t1.out" "$TMP/t2.out"; then echo "ok   determinismo"
else echo "FAIL determinismo: execuções divergem"; fail=$((fail + 1)); fi

# read-only: nenhum arquivo do corpus modificado pelos motores
total=$((total + 1))
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-antes.txt"
( cd "$FIX" && bash "$SCRIPTS/graph.sh" corpus --check >/dev/null 2>&1
  bash "$SCRIPTS/artifact-lint.sh" corpus >/dev/null 2>&1
  bash "$SCRIPTS/index-check.sh" corpus >/dev/null 2>&1 )
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-depois.txt"
if cmp -s "$TMP/ck-antes.txt" "$TMP/ck-depois.txt"; then echo "ok   read-only"
else echo "FAIL read-only: fixture modificada"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "corpus: $fail de $total casos falharam"
  exit 1
fi
echo "corpus: $total casos verdes"
exit 0
