#!/usr/bin/env bash
# run.sh — suíte de regressão do index-check.sh (decisão 4.151).
#
# Fixtures são slugs sintéticos em fixtures/; as saídas esperadas vivem em expected/.
# Regra da suíte: fixture válida sai limpa (zero achado espúrio) e todo defeito
# plantado é acusado pelo check esperado. Check novo no catálogo → fixture nova.
# Os casos rodam com caminho RELATIVO (cd em fixtures/) — o detalhe do index-ausente
# cita o caminho recebido e precisa ser estável.
#
# Uso: scripts/tests/index/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../index-check.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: index-check.sh não encontrado em $CHECK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome fixture exit-esperado arquivo-esperado
  name="$1"; fx="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  out="$TMP/$name.out"
  ( cd "$FIX" && bash "$CHECK" "$fx" ) > "$out" 2> "$TMP/$name.err"
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

bash -n "$CHECK" || { echo "FAIL bash -n index-check.sh"; exit 1; }
echo "ok   bash -n index-check.sh"

runcase valido    valido    0 valido.txt
runcase defeitos  defeitos  0 defeitos.txt
runcase sem-index sem-index 0 sem-index.txt

# read-only: nenhuma fixture modificada pela execução
total=$((total + 1))
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-antes.txt"
( cd "$FIX" && bash "$CHECK" valido >/dev/null 2>&1; bash "$CHECK" defeitos >/dev/null 2>&1 )
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-depois.txt"
if cmp -s "$TMP/ck-antes.txt" "$TMP/ck-depois.txt"; then echo "ok   read-only"
else echo "FAIL read-only: fixture modificada"; fail=$((fail + 1)); fi

# uso incorreto
total=$((total + 1))
bash "$CHECK" "$TMP/nao-existe" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   dir-inexistente-exit-2"
else echo "FAIL dir-inexistente-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$CHECK" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-arg-exit-2"
else echo "FAIL sem-arg-exit-2: exit $st"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "index: $fail de $total casos falharam"
  exit 1
fi
echo "index: $total casos verdes"
exit 0
