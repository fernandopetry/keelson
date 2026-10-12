#!/usr/bin/env bash
# close-task.sh — escritor canônico da closure de uma TASK (decisão 4.476).
# Contrato dos artefatos: templates/artifacts/TASK.md (Histórico de execução),
# templates/artifacts/TASK-INDEX.md (checklist de waves) e
# docs/_meta/conventions/index-contract.md (célula Tasks, Última atualização).
#
# O que este script escreve — e só isto (4.409: branch, tentativas, arquivos, revisores
# e narrativa vivem no ledger e no commit):
#   TASK-MMM-XXX-*.md   `**Status**: Done` · Histórico de execução: Data início, Data
#                       conclusão, Commit SHA, Jira · checklist Quality gates (os 6 itens
#                       fixos marcados; gate 8 e gate 9 com o texto dado)
#   TASK-MMM-INDEX.md   `- [ ] TASK-MMM-XXX …` → `- [x] TASK-MMM-XXX ✅ Done`
#   INDEX.md            célula Tasks da linha PLAN-MMM recomputada das TASKs reais
#                       (mesma regra do index-check.sh) · `Última atualização`
# O que fica com a main session (semântico): mover capacidade para "Implementadas",
# FEAT completa, Status do PLAN.
#
# Toda edição é por linha, ancorada no marcador literal do template: nenhuma linha é
# removida nem acrescentada (invariante da 4.259 — provado antes de gravar: mesma
# contagem de linhas e nenhuma linha de heading alterada; falhou → nada gravado, exit 4).
# Artefato fora do template (sem `**Status**:`, sem `## Histórico de execução`, sem
# `**Commit SHA**:`) → exit 3, nada gravado: o Edit ancorado à mão continua sendo a
# saída para o legado. Idempotente: rodar de novo com os mesmos valores não muda nada.
#
# Uso: close-task.sh <dir-do-slug> TASK-MMM-XXX --sha <SHA> [--inicio <ISO>] [--fim <ISO>]
#                    [--jira <texto>] [--gate8 <texto>] [--gate9 <texto>] [--dry-run]
#   <dir-do-slug>  {docsRoot}/<slug>, já resolvido pelo chamador (como o index-check)
#   --fim ausente  → agora (TZ=America/Sao_Paulo); --inicio ausente → campo intocado
#   --gate8/--gate9 → texto após "Segurança (gate 8): " / "Comportamento (gate 9): "
#   --dry-run      → imprime o plano, não grava
# Saída: uma linha por artefato (`task:`, `task-index:`, `index:`) e o `index-check`
# do slug ao fim. Exit: 0 ok · 1 `index-tasks-cell` do PLAN ainda acusado após a
# escrita · 2 uso incorreto · 3 artefato fora do template (nada gravado) ·
# 4 invariante de edição violado (nada gravado).
# Bash 3.2-compatível, awk POSIX, sem dependências novas.
set -u
LC_ALL=C
export LC_ALL

usage() { sed -n '25,36p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

dir="${1:-}"; task="${2:-}"
[ -n "$dir" ] && [ -n "$task" ] || usage
case "$task" in TASK-[0-9][0-9][0-9]-[0-9][0-9][0-9]) ;; *) echo "close-task: id inválido: $task (esperado TASK-MMM-XXX)" >&2; exit 2 ;; esac
shift 2
sha=""; inicio=""; fim=""; jira=""; gate8=""; gate9=""; dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --sha)    shift; [ $# -gt 0 ] || usage; sha="$1" ;;
    --inicio) shift; [ $# -gt 0 ] || usage; inicio="$1" ;;
    --fim)    shift; [ $# -gt 0 ] || usage; fim="$1" ;;
    --jira)   shift; [ $# -gt 0 ] || usage; jira="$1" ;;
    --gate8)  shift; [ $# -gt 0 ] || usage; gate8="$1" ;;
    --gate9)  shift; [ $# -gt 0 ] || usage; gate9="$1" ;;
    --dry-run) dry=1 ;;
    *) echo "close-task: opção desconhecida: $1" >&2; usage ;;
  esac
  shift
done
[ -n "$sha" ] || { echo "close-task: --sha é obrigatório (o commit da closure ancora a TASK)" >&2; exit 2; }
[ -d "$dir" ] || { echo "close-task: diretório não encontrado: $dir" >&2; exit 2; }
[ -n "$fim" ] || fim="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"

mmm="${task#TASK-}"; mmm="${mmm%%-*}"
HERE="$(cd "$(dirname "$0")" && pwd)"

# --- localizar a TASK (exatamente um arquivo) ---
n=0; tfile=""
for f in "$dir"/tasks/"$task"*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in "$task"|"$task"[-.]*) n=$((n + 1)); tfile="$f" ;; esac
done
if [ "$n" -eq 0 ]; then echo "close-task: TASK não encontrada em $dir/tasks/: $task" >&2; exit 3; fi
if [ "$n" -gt 1 ]; then echo "close-task: $n arquivos casam $task em $dir/tasks/ — resolva o duplicado antes" >&2; exit 3; fi

# --- marcadores do template presentes? (fora do template → nada gravado) ---
falta=""
grep -q '^\*\*Status\*\*[ 	]*:' "$tfile" || falta="$falta **Status**"
grep -q '^## Histórico de execução' "$tfile" || falta="$falta '## Histórico de execução'"
grep -q '^\*\*Commit SHA\*\*[ 	]*:' "$tfile" || falta="$falta **Commit SHA**"
if [ -n "$falta" ]; then
  echo "close-task: $(basename "$tfile") fora do template — marcador ausente:$falta (feche por Edit ancorado, 4.259)" >&2
  exit 3
fi

TMP="$(mktemp -d)" || { echo "close-task: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

# --- TASK: reescrita linha a linha, só os marcadores ---
awk -v inicio="$inicio" -v fim="$fim" -v sha="$sha" -v jira="$jira" -v g8="$gate8" -v g9="$gate9" '
BEGIN { st = 0; hist = 0 }
function val(line, v,   p) {           # mantém o rótulo, troca o valor
  p = index(line, ":")
  return substr(line, 1, p) " " v
}
{
  line = $0
  if (!st && line ~ /^\*\*Status\*\*[ \t]*:/) { st = 1; print "**Status**: Done"; next }
  if (line ~ /^## /) { hist = (line ~ /^## Histórico de execução/) ? 1 : 0; print line; next }
  if (hist) {
    if (inicio != "" && line ~ /^\*\*Data início\*\*[ \t]*:/)   { print val(line, inicio); next }
    if (line ~ /^\*\*Data conclusão\*\*[ \t]*:/)                 { print val(line, fim); next }
    if (line ~ /^\*\*Commit SHA\*\*[ \t]*:/)                     { print val(line, sha); next }
    if (jira != "" && line ~ /^\*\*Jira\*\*[ \t]*:/)             { print val(line, jira); next }
    if (line ~ /^- \[ \] (Implementação completa|Testes passando|Lint limpo|Aderência à ficha\/perfil|Code review aprovado|ACs verificados)[ \t]*$/) {
      sub(/^- \[ \]/, "- [x]", line); print line; next
    }
    if (g8 != "" && line ~ /^- \[[ x]\] Segurança \(gate 8\):/) { print "- [x] Segurança (gate 8): " g8; next }
    if (g9 != "" && line ~ /^- \[[ x]\] Comportamento \(gate 9\):/) { print "- [x] Comportamento (gate 9): " g9; next }
  }
  print line
}' "$tfile" > "$TMP/task.new"

# invariante 4.259: mesma contagem de linhas, nenhum heading alterado
if [ "$(wc -l < "$tfile")" != "$(wc -l < "$TMP/task.new")" ] \
   || ! cmp -s <(grep '^#' "$tfile") <(grep '^#' "$TMP/task.new"); then
  echo "close-task: invariante de edição violado em $(basename "$tfile") — nada gravado (4.259)" >&2
  exit 4
fi

# --- TASK-INDEX: marcar no checklist da wave ---
tindex="$dir/tasks/TASK-$mmm-INDEX.md"
ti_state="ausente"
if [ -f "$tindex" ]; then
  if grep -q "^- \[x\] $task " "$tindex"; then ti_state="já marcado"
  elif grep -q "^- \[ \] $task\([^0-9]\|$\)" "$tindex"; then
    awk -v t="$task" '
      index($0, "- [ ] " t) == 1 && (length($0) == length("- [ ] " t) || substr($0, length("- [ ] " t) + 1, 1) !~ /[0-9]/) { print "- [x] " t " ✅ Done"; next }
      { print }' "$tindex" > "$TMP/tindex.new"
    ti_state="marcado"
  else ti_state="linha da TASK não encontrada"; fi
fi

# --- INDEX.md: célula Tasks recomputada + Última atualização ---
index="$dir/INDEX.md"
ix_state="ausente"; cell=""
if [ -f "$index" ]; then
  x=0; y=0
  for f in "$dir"/tasks/TASK-"$mmm"-[0-9][0-9][0-9]*.md; do
    [ -f "$f" ] || continue
    y=$((y + 1))
    if [ "$f" = "$tfile" ]; then stv="Done"
    else stv="$(sed -n 's/^\*\*Status\*\*[ 	]*:[ 	]*//p' "$f" | sed -n 1p | sed 's/\r$//; s/[ 	]*$//')"; fi
    [ "$stv" = "Done" ] && x=$((x + 1))
  done
  if [ "$y" -eq 0 ]; then cell="0/? ⏸"
  elif [ "$x" -eq 0 ]; then cell="0/$y ⏸"
  elif [ "$x" -lt "$y" ]; then cell="$x/$y 🟡"
  else cell="$x/$y ✅"; fi
  awk -F'|' -v OFS='|' -v plan="PLAN-$mmm" -v cell="$cell" -v fim="$fim" '
    $0 ~ /^\|/ && NF >= 6 {
      p = $2; gsub(/^[ \t]+|[ \t]+$/, "", p)
      if (p == plan) { $5 = " " cell " "; print; next }
    }
    /^\*\*Última atualização\*\*[ \t]*:/ { print "**Última atualização**: " fim; next }
    { print }' "$index" > "$TMP/index.new"
  if cmp -s "$index" "$TMP/index.new"; then ix_state="inalterado"; else ix_state="atualizado"; fi
fi

# --- plano / gravação ---
echo "task: $(basename "$tfile") → Status Done · inicio=${inicio:-"(intocado)"} · fim=$fim · sha=$sha · jira=${jira:-"(intocado)"} · gate8=${gate8:-"(intocado)"} · gate9=${gate9:-"(intocado)"}"
echo "task-index: $ti_state"
[ -n "$cell" ] && echo "index: Tasks PLAN-$mmm = $cell · Última atualização = $fim ($ix_state)" || echo "index: $ix_state"
if [ "$dry" -eq 1 ]; then
  echo "dry-run: nada gravado"
  exit 0
fi
cat "$TMP/task.new" > "$tfile"
[ -f "$TMP/tindex.new" ] && cat "$TMP/tindex.new" > "$tindex"
[ -f "$TMP/index.new" ] && [ "$ix_state" = "atualizado" ] && cat "$TMP/index.new" > "$index"

# --- conferência mecânica (4.151): o commit da closure só sai sem index-tasks-cell ---
rc=0
if [ -f "$HERE/index-check.sh" ] && [ -f "$index" ]; then
  out="$(bash "$HERE/index-check.sh" "$dir" 2>/dev/null || true)"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/index-check: /'
  if printf '%s\n' "$out" | grep -q "index-tasks-cell	PLAN-$mmm:"; then
    echo "close-task: index-tasks-cell ainda acusado para PLAN-$mmm — corrija antes do commit da closure" >&2
    rc=1
  fi
fi
exit "$rc"
