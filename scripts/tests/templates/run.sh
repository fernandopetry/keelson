#!/usr/bin/env bash
# run.sh — suíte de regressão do check-templates.sh (decisão 4.405).
#
# Cada fixture é uma raiz sintética (commands/ + templates/artifacts/); a suíte copia a
# fixture para um diretório temporário e injeta o artifact-lint.sh REAL em scripts/,
# porque a prova 4 do check (template ⇄ lint) roda o lint de verdade. Regra da suíte:
# fixture válida sai limpa e todo defeito plantado é acusado — `dup` (2ª cópia do
# esqueleto num comando), `sem-heading` (heading exigido pelo lint removido do template),
# `sem-ponteiro` (comando sem o caminho do template + template ausente). O repo real
# também é provado (o mesmo check do pre-commit/CI).
#
# Uso: scripts/tests/templates/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOTREAL="$HERE/../../.."
CHECK="$ROOTREAL/scripts/check-templates.sh"
LINT="$ROOTREAL/scripts/artifact-lint.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-templates.sh não encontrado em $CHECK" >&2; exit 1; }
[ -f "$LINT" ]  || { echo "ERRO: artifact-lint.sh não encontrado em $LINT" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$CHECK" || { echo "FAIL bash -n check-templates.sh"; exit 1; }
echo "ok   bash -n check-templates.sh"

runcase() { # $1 nome  $2 fixture  $3 exit esperado  $4 expected
  name="$1"; fx="$2"; want="$3"; exp="$4"
  total=$((total + 1))
  root="$TMP/$fx"
  mkdir -p "$root/scripts"
  cp -R "$FIX/$fx/." "$root/"
  cp "$LINT" "$root/scripts/artifact-lint.sh"
  out="$TMP/$name.out"
  bash "$CHECK" --root "$root" > "$out" 2> "$TMP/$name.err"
  got=$?
  # a raiz temporária é ruído: normalizar para comparar
  sed "s#$root/##g" "$out" | LC_ALL=C sort > "$out.norm"
  if [ "$got" -ne "$want" ]; then
    echo "FAIL $name: exit $got (esperado $want)"; cat "$out" "$TMP/$name.err"
    fail=$((fail + 1)); return
  fi
  if ! diff -u "$EXP/$exp" "$out.norm" > "$TMP/$name.diff"; then
    echo "FAIL $name: saída divergente de expected/$exp"; cat "$TMP/$name.diff"
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

runcase ok           ok           0 ok.txt
runcase dup          dup          1 dup.txt
runcase sem-heading  sem-heading  1 sem-heading.txt
runcase sem-ponteiro sem-ponteiro 1 sem-ponteiro.txt

# uso incorreto: raiz sem artifact-lint.sh → exit 2
total=$((total + 1))
mkdir -p "$TMP/vazio"
bash "$CHECK" --root "$TMP/vazio" >/dev/null 2>&1
got=$?
if [ "$got" -eq 2 ]; then echo "ok   uso-incorreto"; else echo "FAIL uso-incorreto: exit $got (esperado 2)"; fail=$((fail + 1)); fi

# repo real: o mesmo check do pre-commit/CI
total=$((total + 1))
if out="$(bash "$CHECK" --root "$ROOTREAL" 2>&1)"; then
  echo "ok   repo-real"
else
  echo "FAIL repo-real: check-templates.sh reprovou o repositório"; printf '%s\n' "$out"
  fail=$((fail + 1))
fi

if [ "$fail" -gt 0 ]; then
  echo "templates: $fail de $total casos falharam"
  exit 1
fi
echo "templates: $total casos ok"
exit 0
