#!/usr/bin/env bash
# run.sh — suíte de regressão do legacy-move.sh (decisão 4.154).
#
# Regras provadas: move só os .md da raiz (subpasta e não-md ficam), git mv quando
# rastreado, aviso sdd-parcial, ROLLBACK completo quando um destino está ocupado,
# INDEX.md presente é exit 2 (não é slug legado).
#
# Uso: scripts/tests/legacy-move/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige git.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LM="$HERE/../../legacy-move.sh"

[ -f "$LM" ] || { echo "ERRO: legacy-move.sh não encontrado" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

mkrepo() { r="$TMP/$1"; mkdir -p "$r"; git -C "$r" init -q; git -C "$r" config user.email t@t; git -C "$r" config user.name t; printf '%s\n' "$r"; }

# ---- caso feliz: tracked + untracked, subpasta e não-md intactos ----
R="$(mkrepo feliz)"
S="$R/docs/velho"
mkdir -p "$S/anexos"
printf 'a\n' > "$S/arquitetura.md"
printf 'b\n' > "$S/notas.md"
printf 'x\n' > "$S/anexos/diagrama.md"
printf 'y\n' > "$S/dados.csv"
git -C "$R" add docs/velho/arquitetura.md && git -C "$R" commit -qm base
total=$((total + 1))
got="$(bash "$LM" "$S" 2>"$TMP/err")"; st=$?
want="movido	arquitetura.md
movido	notas.md"
if [ "$st" -eq 0 ] && [ "$got" = "$want" ] && [ -f "$S/legacy/arquitetura.md" ] && [ -f "$S/legacy/notas.md" ] \
   && [ ! -f "$S/arquitetura.md" ] && [ -f "$S/anexos/diagrama.md" ] && [ -f "$S/dados.csv" ]; then
  echo "ok   feliz"
else
  echo "FAIL feliz (exit $st): [$got]"; sed 's/^/  stderr: /' "$TMP/err"; fail=$((fail + 1))
fi
# o rastreado moveu por git mv (aparece como renamed/staged)
total=$((total + 1))
if git -C "$R" status --porcelain | grep -q '^R.*arquitetura'; then echo "ok   git-mv-rastreado"
else echo "FAIL git-mv-rastreado"; git -C "$R" status --porcelain | sed 's/^/  /'; fail=$((fail + 1)); fi

# ---- sdd-parcial: specs/ com conteúdo vira aviso, nunca movida ----
R2="$(mkrepo parcial)"
S2="$R2/docs/meio"
mkdir -p "$S2/specs"
printf 's\n' > "$S2/specs/SPEC-001-x.md"
printf 'n\n' > "$S2/velho.md"
total=$((total + 1))
got="$(bash "$LM" "$S2" 2>/dev/null)"; st=$?
case "$got" in
  "aviso	sdd-parcial	specs/"*"
movido	velho.md")
    [ "$st" -eq 0 ] && [ -f "$S2/specs/SPEC-001-x.md" ] && echo "ok   sdd-parcial" || { echo "FAIL sdd-parcial exit=$st"; fail=$((fail + 1)); } ;;
  *) echo "FAIL sdd-parcial: [$got]"; fail=$((fail + 1)) ;;
esac

# ---- rollback: destino ocupado no 2º arquivo desfaz o 1º ----
R3="$(mkrepo rollback)"
S3="$R3/docs/conflito"
mkdir -p "$S3/legacy"
printf 'a\n' > "$S3/aaa.md"
printf 'b\n' > "$S3/bbb.md"
printf 'ocupado\n' > "$S3/legacy/bbb.md"
total=$((total + 1))
got="$(bash "$LM" "$S3" 2>/dev/null)"; st=$?
if [ "$st" -eq 1 ] && [ -f "$S3/aaa.md" ] && [ -f "$S3/bbb.md" ] && [ ! -f "$S3/legacy/aaa.md" ] \
   && printf '%s\n' "$got" | grep -q '^rollback	aaa.md'; then
  echo "ok   rollback"
else
  echo "FAIL rollback (exit $st): [$got]"; fail=$((fail + 1))
fi

# ---- INDEX.md presente → exit 2; nada a mover → aviso ----
R4="$(mkrepo com-index)"
S4="$R4/docs/pronto"; mkdir -p "$S4"; printf 'i\n' > "$S4/INDEX.md"
total=$((total + 1))
bash "$LM" "$S4" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   com-index-exit-2" || { echo "FAIL com-index-exit-2"; fail=$((fail + 1)); }

S5="$R4/docs/vazio"; mkdir -p "$S5"
total=$((total + 1))
got="$(bash "$LM" "$S5" 2>/dev/null)"; st=$?
case "$got" in
  "aviso	nada-a-mover"*) [ "$st" -eq 0 ] && echo "ok   nada-a-mover" || { echo "FAIL nada-a-mover"; fail=$((fail + 1)); } ;;
  *) echo "FAIL nada-a-mover: [$got]"; fail=$((fail + 1)) ;;
esac

echo "---"
if [ "$fail" -gt 0 ]; then echo "legacy-move: $fail de $total casos falharam"; exit 1; fi
echo "legacy-move: $total casos verdes"
exit 0
