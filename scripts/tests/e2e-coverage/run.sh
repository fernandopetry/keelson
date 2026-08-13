#!/usr/bin/env bash
# run.sh — suíte de regressão do e2e-coverage.sh (decisão 4.166).
#
# Fixtures em fixtures/ (slug sintético + specs E2E com defeitos plantados); saídas
# esperadas congeladas em expected/. Regra da suíte: fixture válida sai só com o fato
# de cobertura (zero achado espúrio) e todo defeito plantado é acusado pelo check
# esperado. Check novo → fixture nova.
#
# Uso: scripts/tests/e2e-coverage/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../../e2e-coverage.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$SCRIPT" ] || { echo "ERRO: e2e-coverage.sh não encontrado em $SCRIPT" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome fixture-subdir args... (últimos 2 args = slug-dir e2e-dir)
  name="$1"; sub="$2"; slugdir="$3"; e2edir="$4"; wantexit="$5"; expfile="$6"
  total=$((total + 1))
  out="$TMP/$name.out"
  ( cd "$FIX/$sub" && bash "$SCRIPT" "$slugdir" "$e2edir" ) > "$out" 2> "$TMP/$name.err"
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

bash -n "$SCRIPT" || { echo "FAIL bash -n e2e-coverage.sh"; exit 1; }
echo "ok   bash -n e2e-coverage.sh"

runcase valido      valido  demo e2e             0 valido.txt
runcase defeito     defeito demo e2e             0 defeito.txt
runcase dir-ausente defeito demo e2e-nao-existe  0 dir-ausente.txt

# uso incorreto: sem args → exit 2, nada no stdout
total=$((total + 1))
( cd "$FIX" && bash "$SCRIPT" ) > "$TMP/uso.out" 2>/dev/null
if [ $? -eq 2 ] && [ ! -s "$TMP/uso.out" ]; then
  echo "ok   uso-incorreto"
else
  echo "FAIL uso-incorreto: esperado exit 2 e stdout vazio"
  fail=$((fail + 1))
fi

# determinismo: duas execuções idênticas byte a byte
total=$((total + 1))
( cd "$FIX/defeito" && bash "$SCRIPT" demo e2e ) > "$TMP/d1.out" 2>/dev/null
( cd "$FIX/defeito" && bash "$SCRIPT" demo e2e ) > "$TMP/d2.out" 2>/dev/null
if cmp -s "$TMP/d1.out" "$TMP/d2.out"; then
  echo "ok   determinismo"
else
  echo "FAIL determinismo: execuções divergem"
  fail=$((fail + 1))
fi

echo "----"
echo "$((total - fail))/$total casos verdes"
[ "$fail" -eq 0 ] || exit 1
exit 0
