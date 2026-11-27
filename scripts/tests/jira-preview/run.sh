#!/usr/bin/env bash
# run.sh — suíte de regressão do jira-preview.sh.
#
# Cada fixture é uma raiz de projeto sintética (ficha + mapa); a saída inteira do script
# é comparada com expected/<fixture>.txt. Fixtures: "pleno" (auto, mapa completo, trilho),
# "compacta" (multi-feature, comment, mapa legado sem coluna Nível), "sem-feature"
# (modo link, sem mapa, projeção inviável), "desligado" e "mapa-furado" (marco ausente,
# alvo fora do trilho, linha de fase sem nível, marco não-canônico). Os casos inline
# cobrem --levels e os exits de uso/degradação.
#
# Uso: scripts/tests/jira-preview/run.sh [--update]
#   --update   regrava expected/ com a saída atual (revise o diff antes de commitar)
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SUT="$HERE/../../jira-preview.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"
UPDATE=0
[ "${1:-}" = "--update" ] && UPDATE=1

[ -f "$SUT" ] || { echo "ERRO: jira-preview.sh não encontrado em $SUT" >&2; exit 1; }
TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$SUT" || { echo "FAIL bash -n jira-preview.sh"; exit 1; }
ok "bash -n jira-preview.sh"

for f in pleno compacta sem-feature desligado mapa-furado; do
  total=$((total + 1))
  bash "$SUT" "$FIX/$f" > "$TMP/$f.txt" 2>"$TMP/err"; st=$?
  if [ "$st" -ne 0 ]; then bad "$f: exit $st"; sed 's/^/  stderr: /' "$TMP/err"; continue; fi
  if [ "$UPDATE" = "1" ]; then cp "$TMP/$f.txt" "$EXP/$f.txt"; ok "$f (regravado)"; continue; fi
  if diff -u "$EXP/$f.txt" "$TMP/$f.txt" > "$TMP/diff" 2>&1; then ok "$f"
  else bad "$f: saída divergente"; sed 's/^/  /' "$TMP/diff"; fi
done

has() { # nome arquivo padrão-fixo
  total=$((total + 1))
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1: faltou [$3]"; fi
}
hasnt() {
  total=$((total + 1))
  if grep -qF -- "$3" "$2"; then bad "$1: não deveria conter [$3]"; else ok "$1"; fi
}
exitis() { # nome exit-esperado -- args
  name="$1"; want="$2"; shift 3
  total=$((total + 1))
  bash "$SUT" "$@" >/dev/null 2>&1; st=$?
  if [ "$st" -eq "$want" ]; then ok "$name"; else bad "$name: exit $st (esperado $want)"; fi
}
T="$(printf '\t')"

# --levels: níveis medidos mudam a projeção
bash "$SUT" "$FIX/pleno" --levels spec=1,feature=0,task=0,standalone=0 > "$TMP/link.txt" 2>/dev/null
has    levels-medidos        "$TMP/link.txt" "config${T}ok${T}niveis${T}medidos"
has    levels-task-nao-sub   "$TMP/link.txt" "cenario${T}spec-multi-feat${T}2 niveis por link"
bash "$SUT" "$FIX/pleno" --levels spec=0,feature=0,task=-1,standalone=0 > "$TMP/n0.txt" 2>/dev/null
has    levels-spec-nivel0    "$TMP/n0.txt"   "cenario${T}spec-multi-feat${T}2 niveis valido"
bash "$SUT" "$FIX/pleno" --levels spec=1,feature=1,task=-1,standalone=0 > "$TMP/f1.txt" 2>/dev/null
has    levels-feature-ruim   "$TMP/f1.txt"   "config${T}aviso${T}jira.issueType.feature"
has    levels-cai-isolada    "$TMP/f1.txt"   "cenario${T}spec-multi-feat${T}2 niveis via tarefa isolada"

# o que o script deve recusar afirmar
has    teto-vira-comentario  "$EXP/pleno.txt"       "Funcionalidade pronta p/ QA${T}Story${T}comentario"
hasnt  comment-nunca-move    "$EXP/compacta.txt"    "${T}sub-task${T}move${T}"
has    epic-intocado         "$EXP/pleno.txt"       "${T}Epic${T}nada${T}"
hasnt  epic-comentado-fora   "$EXP/pleno.txt"       "fase-start-dev-epic${T}alvo"
has    fase-sem-nivel        "$EXP/mapa-furado.txt" "mapa${T}aviso${T}nao-parseavel"
hasnt  fase-sem-nivel-fato   "$EXP/mapa-furado.txt" "mapa${T}ok${T}fase-start-dev-subtask"
has    nao-canonico          "$EXP/mapa-furado.txt" "marcos-nao-canonicos${T}1 linha"
has    fora-do-trilho        "$EXP/mapa-furado.txt" "alvo 999 (task-concluida) fora do trilho"
hasnt  sem-mapa-nao-move     "$EXP/sem-feature.txt" "${T}move${T}"

# exits
exitis sem-ficha       3 -- "$TMP"
exitis flag-ruim       2 -- "$FIX/pleno" --nope
exitis levels-ruim     2 -- "$FIX/pleno" --levels spec=x
exitis levels-chave    2 -- "$FIX/pleno" --levels epic=1
mkdir -p "$TMP/quebrada"; printf '{ nao e json' > "$TMP/quebrada/keelson.config.json"
exitis ficha-quebrada  3 -- "$TMP/quebrada"

echo "---"
echo "$((total - fail))/$total verdes"
[ "$fail" -eq 0 ] || exit 1
exit 0
