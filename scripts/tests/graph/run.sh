#!/usr/bin/env bash
# run.sh — suíte de regressão do graph.sh (contrato: docs/_meta/conventions/graph-contract.md §6).
#
# Fixtures são slugs sintéticos em fixtures/; as saídas esperadas vivem em expected/.
# Regra da suíte: fixture válida sai limpa (zero achado espúrio) e todo defeito
# plantado é acusado pelo check esperado. Check novo no catálogo → fixture nova aqui.
#
# Uso: scripts/tests/graph/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
GRAPH="$HERE/../../graph.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$GRAPH" ] || { echo "ERRO: graph.sh não encontrado em $GRAPH" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome dir exit-esperado arquivo-esperado [args do graph.sh...]
  name="$1"; dir="$2"; wantexit="$3"; expfile="$4"; shift 4
  total=$((total + 1))
  out="$TMP/$name.out"
  bash "$GRAPH" "$FIX/$dir" "$@" > "$out" 2> "$TMP/$name.err"
  got=$?
  if [ "$got" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $got (esperado $wantexit)"
    sed 's/^/  stderr: /' "$TMP/$name.err"
    fail=$((fail + 1)); return
  fi
  if ! diff -u "$EXP/$expfile" "$out" > "$TMP/$name.diff" 2>&1; then
    echo "FAIL $name: saída difere do esperado"
    head -40 "$TMP/$name.diff" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

bash -n "$GRAPH" || { echo "FAIL bash -n graph.sh"; exit 1; }
echo "ok   bash -n graph.sh"

runcase valido-check             valido             0 valido--check.txt               --check
runcase valido-tsv               valido             0 valido--tsv.txt                 --format=tsv
runcase valido-mermaid           valido             0 valido--mermaid.txt             --format=mermaid
runcase valido-mermaid-comp      valido             0 valido--mermaid-comp.txt        --format=mermaid-comp
runcase valido-legado-check      valido-legado      0 valido-legado--check.txt        --check
runcase valido-legado-tsv        valido-legado      0 valido-legado--tsv.txt          --format=tsv
runcase ciclo-task-check         defeito-ciclo-task 1 defeito-ciclo-task--check.txt   --check
runcase ciclo-comp-check         defeito-ciclo-comp 1 defeito-ciclo-comp--check.txt   --check
runcase ciclo-comp-stage-plan    defeito-ciclo-comp 1 defeito-ciclo-comp--check-stage-plan.txt --check --stage=plan
runcase refs-check               defeito-refs       1 defeito-refs--check.txt         --check
runcase cobertura-check          defeito-cobertura  1 defeito-cobertura--check.txt    --check
runcase legado-done-check        defeito-legado-done 0 defeito-legado-done--check.txt --check
runcase plan-sem-tasks-check     plan-sem-tasks     1 plan-sem-tasks--check.txt       --check
runcase plan-sem-tasks-stage     plan-sem-tasks     0 plan-sem-tasks--check-stage-plan.txt --check --stage=plan
runcase parse-degrade-check      defeito-parse-degrade 0 defeito-parse-degrade--check.txt --check
# --plan aceita MMM sem zero-padding (mesmo resultado do padded)
runcase cobertura-plan-1         defeito-cobertura  1 defeito-cobertura--check-plan.txt --check --plan 1

# Determinismo: duas execuções idênticas byte a byte (AC-001-001)
total=$((total + 1))
bash "$GRAPH" "$FIX/valido" --format=tsv > "$TMP/d1.out" 2>/dev/null
bash "$GRAPH" "$FIX/valido" --format=tsv > "$TMP/d2.out" 2>/dev/null
if cmp -s "$TMP/d1.out" "$TMP/d2.out"; then echo "ok   determinismo-tsv"
else echo "FAIL determinismo-tsv: execuções divergem"; fail=$((fail + 1)); fi

# Read-only: nenhum artefato modificado pela execução (AC-001-016)
total=$((total + 1))
( cd "$FIX" && find . -type f -name '*.md' -exec cksum {} \; | sort ) > "$TMP/ck-antes.txt"
bash "$GRAPH" "$FIX/valido" --check > /dev/null 2>&1
bash "$GRAPH" "$FIX/defeito-refs" --check > /dev/null 2>&1
( cd "$FIX" && find . -type f -name '*.md' -exec cksum {} \; | sort ) > "$TMP/ck-depois.txt"
if cmp -s "$TMP/ck-antes.txt" "$TMP/ck-depois.txt"; then echo "ok   read-only"
else echo "FAIL read-only: artefato de fixture foi modificado"; fail=$((fail + 1)); fi

# Uso incorreto → exit 2
total=$((total + 1))
bash "$GRAPH" "$FIX/valido" > /dev/null 2>&1
if [ $? -eq 2 ]; then echo "ok   uso-sem-modo-exit-2"
else echo "FAIL uso-sem-modo-exit-2"; fail=$((fail + 1)); fi
total=$((total + 1))
bash "$GRAPH" /caminho/que/nao/existe --check > /dev/null 2>&1
if [ $? -eq 2 ]; then echo "ok   dir-inexistente-exit-2"
else echo "FAIL dir-inexistente-exit-2"; fail=$((fail + 1)); fi
total=$((total + 1))
bash "$GRAPH" "$FIX/valido" --check --plan 999 > /dev/null 2>&1
if [ $? -eq 2 ]; then echo "ok   plan-inexistente-exit-2"
else echo "FAIL plan-inexistente-exit-2 (filtro inválido não pode sair verde)"; fail=$((fail + 1)); fi

echo ""
if [ "$fail" -gt 0 ]; then
  echo "SUITE: $fail de $total casos falharam."
  exit 1
fi
echo "SUITE: $total casos, tudo verde."
exit 0
