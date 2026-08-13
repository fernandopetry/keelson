#!/usr/bin/env bash
# run.sh — suíte de regressão do artifact-lint.sh (decisão 4.152).
# Contrato do catálogo: docs/_meta/conventions/lint-contract.md.
#
# Fixtures são slugs sintéticos em fixtures/; as saídas esperadas vivem em expected/.
# Regra da suíte: fixture válida sai limpa (zero achado espúrio) e todo defeito
# plantado é acusado pelo check esperado. Check novo no catálogo → fixture nova.
# "legado" prova o rebaixamento ERROR → WARNING [legacy] em artefato Done.
#
# Uso: scripts/tests/artifact-lint/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/../../artifact-lint.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$LINT" ] || { echo "ERRO: artifact-lint.sh não encontrado em $LINT" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome alvo exit-esperado arquivo-esperado
  name="$1"; alvo="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  out="$TMP/$name.out"
  ( cd "$FIX" && bash "$LINT" "$alvo" ) > "$out" 2> "$TMP/$name.err"
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

bash -n "$LINT" || { echo "FAIL bash -n artifact-lint.sh"; exit 1; }
echo "ok   bash -n artifact-lint.sh"

runcase valido          valido   0 valido.txt
runcase defeitos        defeitos 1 defeitos.txt
runcase legado          legado   0 legado.txt
runcase arquivo-valido  valido/specs/SPEC-001-login.md 0 arquivo-unico-valido.txt
runcase arquivo-defeito defeitos/tasks/TASK-001-005-refactor-extrai.md 1 arquivo-unico-defeito.txt

# determinismo: duas execuções idênticas byte a byte
total=$((total + 1))
( cd "$FIX" && bash "$LINT" defeitos ) > "$TMP/d1.out" 2>/dev/null
( cd "$FIX" && bash "$LINT" defeitos ) > "$TMP/d2.out" 2>/dev/null
if cmp -s "$TMP/d1.out" "$TMP/d2.out"; then echo "ok   determinismo"
else echo "FAIL determinismo: execuções divergem"; fail=$((fail + 1)); fi

# read-only: nenhuma fixture modificada
total=$((total + 1))
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-antes.txt"
( cd "$FIX" && bash "$LINT" valido >/dev/null 2>&1; bash "$LINT" defeitos >/dev/null 2>&1 )
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-depois.txt"
if cmp -s "$TMP/ck-antes.txt" "$TMP/ck-depois.txt"; then echo "ok   read-only"
else echo "FAIL read-only: fixture modificada"; fail=$((fail + 1)); fi

# uso incorreto
total=$((total + 1))
bash "$LINT" "$TMP/nao-existe.md" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   caminho-inexistente-exit-2"
else echo "FAIL caminho-inexistente-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$LINT" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-arg-exit-2"
else echo "FAIL sem-arg-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
printf 'x\n' > "$TMP/OUTRO-001-x.md"
bash "$LINT" "$TMP/OUTRO-001-x.md" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   tipo-desconhecido-exit-2"
else echo "FAIL tipo-desconhecido-exit-2: exit $st"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "artifact-lint: $fail de $total casos falharam"
  exit 1
fi
echo "artifact-lint: $total casos verdes"
exit 0
