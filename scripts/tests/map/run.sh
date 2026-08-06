#!/usr/bin/env bash
# run.sh — suíte de regressão do map-check.sh (contrato: docs/_meta/conventions/map-contract.md §5).
#
# Fixtures são pares slug + tree (código na raiz do repo sintético); como o check
# `map-frescor` depende de git, cada caso MONTA um repo temporário com datas de commit
# fixas (determinísticas): commit base em 2026-01-15 e, para os paths listados em
# `touch-later` da fixture, um segundo commit em 2026-07-01. As saídas esperadas vivem
# em expected/. Regra da suíte: fixture válida sai limpa (zero achado espúrio) e todo
# defeito plantado é acusado pelo check esperado. Check novo no catálogo → fixture nova.
#
# Uso: scripts/tests/map/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL
export TZ=UTC

HERE="$(cd "$(dirname "$0")" && pwd)"
MAPCHECK="$HERE/../../map-check.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$MAPCHECK" ] || { echo "ERRO: map-check.sh não encontrado em $MAPCHECK" >&2; exit 1; }

if ! command -v git >/dev/null 2>&1; then
  echo "ERRO: a suíte do map exige git (map-frescor)" >&2
  exit 1
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

buildrepo() { # fixture → monta $TMP/<fixture>/repo com commits datados; ecoa o path do slug
  fx="$1"
  repo="$TMP/$fx/repo"
  mkdir -p "$repo"
  [ -d "$FIX/$fx/tree" ] && cp -R "$FIX/$fx/tree/." "$repo/"
  mkdir -p "$repo/docs"
  cp -R "$FIX/$fx/slug" "$repo/docs/slug"
  git -C "$repo" init -q
  git -C "$repo" config user.email map@test
  git -C "$repo" config user.name map-test
  git -C "$repo" add -A
  GIT_AUTHOR_DATE="2026-01-15T12:00:00Z" GIT_COMMITTER_DATE="2026-01-15T12:00:00Z" \
    git -C "$repo" commit -qm base
  if [ -f "$FIX/$fx/touch-later" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      printf '// touched later\n' >> "$repo/$p"
    done < "$FIX/$fx/touch-later"
    git -C "$repo" add -A
    GIT_AUTHOR_DATE="2026-07-01T12:00:00Z" GIT_COMMITTER_DATE="2026-07-01T12:00:00Z" \
      git -C "$repo" commit -qm touch-later
  fi
  printf '%s\n' "$repo/docs/slug"
}

runcase() { # nome fixture exit-esperado arquivo-esperado
  name="$1"; fx="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  slugdir="$(buildrepo "$fx")"
  out="$TMP/$name.out"
  bash "$MAPCHECK" "$slugdir" > "$out" 2> "$TMP/$name.err"
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

bash -n "$MAPCHECK" || { echo "FAIL bash -n map-check.sh"; exit 1; }
echo "ok   bash -n map-check.sh"

runcase valido   valido   0 valido.txt
runcase defeitos defeitos 0 defeitos.txt
runcase sem-map  sem-map  0 sem-map.txt

# uso incorreto: diretório inexistente → exit 2
total=$((total + 1))
if bash "$MAPCHECK" "$TMP/nao-existe" >/dev/null 2>&1; then
  echo "FAIL uso-incorreto: exit 0 (esperado 2)"; fail=$((fail + 1))
else
  got=$?
  if [ "$got" -eq 2 ]; then echo "ok   uso-incorreto"; else echo "FAIL uso-incorreto: exit $got (esperado 2)"; fail=$((fail + 1)); fi
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "map: $fail de $total casos falharam"
  exit 1
fi
echo "map: $total casos verdes"
exit 0
