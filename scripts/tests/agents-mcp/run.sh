#!/usr/bin/env bash
# run.sh — suíte de regressão do check-agents.sh (decisão 4.105).
#
# Fixtures são diretórios de agents sintéticos; as saídas esperadas vivem em expected/.
# Regra da suíte: fixture válida sai limpa (zero achado espúrio) e toda violação
# plantada é acusada. Caso novo de grant/citação → fixture nova com expected congelado.
# O último caso roda o check sobre os agents REAIS do repo: o elenco embarcado nunca
# regride para um papel que cita MCP sem grant.
#
# Uso: scripts/tests/agents-mcp/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-agents.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-agents.sh não encontrado em $CHECK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome dir-fixture exit-esperado arquivo-esperado
  name="$1"; fx="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  out="$TMP/$name.out"
  bash "$CHECK" --agents-dir "$FIX/$fx" > "$out" 2> "$TMP/$name.err"
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

bash -n "$CHECK" || { echo "FAIL bash -n check-agents.sh"; exit 1; }
echo "ok   bash -n check-agents.sh"

runcase ok    ok    0 ok.txt
runcase viola viola 1 viola.txt

# uso incorreto: diretório inexistente → exit 2
total=$((total + 1))
bash "$CHECK" --agents-dir "$TMP/nao-existe" >/dev/null 2>&1
got=$?
if [ "$got" -eq 2 ]; then echo "ok   uso-incorreto"; else echo "FAIL uso-incorreto: exit $got (esperado 2)"; fail=$((fail + 1)); fi

# os agents reais do repo passam (o qa carrega o grant do Playwright desde a 4.105)
total=$((total + 1))
if out="$(bash "$CHECK" --agents-dir "$HERE/../../../agents" 2>&1)"; then
  echo "ok   repo-real"
else
  echo "FAIL repo-real: check-agents falhou nos agents do repo:"
  printf '%s\n' "$out" | sed 's/^/  /'
  fail=$((fail + 1))
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "agents-mcp: $fail de $total casos falharam"
  exit 1
fi
echo "agents-mcp: $total casos verdes"
exit 0
