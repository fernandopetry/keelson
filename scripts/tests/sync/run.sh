#!/usr/bin/env bash
# run.sh — suíte de regressão do check-sync.sh (decisão 4.147).
#
# Fixtures são mini-repos sintéticos (commands/, agents/, README, method-guide,
# bloco); as saídas esperadas vivem em expected/. Regra da suíte: fixture válida
# sai limpa (zero achado espúrio) e toda violação plantada é acusada. Caso novo
# de dessincronização → fixture nova com expected congelado.
# O último caso roda o check sobre o REPO REAL: comandos e agents embarcados
# nunca regridem para um estado dessincronizado (AVISO não falha — carência
# conhecida é declarada, nunca bloqueia).
#
# Uso: scripts/tests/sync/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-sync.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-sync.sh não encontrado em $CHECK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome dir-fixture exit-esperado arquivo-esperado
  name="$1"; fx="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  out="$TMP/$name.out"
  bash "$CHECK" --root "$FIX/$fx" > "$out" 2> "$TMP/$name.err"
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

bash -n "$CHECK" || { echo "FAIL bash -n check-sync.sh"; exit 1; }
echo "ok   bash -n check-sync.sh"

runcase ok    ok    0 ok.txt
runcase viola viola 1 viola.txt

# uso incorreto: raiz sem commands/ → exit 2
total=$((total + 1))
mkdir -p "$TMP/vazio"
bash "$CHECK" --root "$TMP/vazio" >/dev/null 2>&1
got=$?
if [ "$got" -eq 2 ]; then echo "ok   uso-incorreto"; else echo "FAIL uso-incorreto: exit $got (esperado 2)"; fail=$((fail + 1)); fi

# o repo real passa (AVISOs de carência conhecida não falham)
total=$((total + 1))
if out="$(bash "$CHECK" --root "$HERE/../../.." 2>&1)"; then
  echo "ok   repo-real"
else
  echo "FAIL repo-real: check-sync falhou no repo:"
  printf '%s\n' "$out" | sed 's/^/  /'
  fail=$((fail + 1))
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "sync: $fail de $total casos falharam"
  exit 1
fi
echo "sync: $total casos verdes"
exit 0
