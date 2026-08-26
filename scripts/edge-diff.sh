#!/usr/bin/env bash
# edge-diff.sh — diff de arestas antes/depois da reescrita de um artefato (decisão 4.117/4.154).
# A reescrita por Write integral (scribe) preserva toda aresta que o ajuste não mira;
# este script PROVA isso: extrai os campos de aresta e os ACs citados em critérios das
# duas versões e reporta o delta. Quem roda é a main session, após o retorno do scribe
# (ele não tem shell — 4.114); aresta perdida de propósito é decisão declarada, nunca
# efeito colateral silencioso.
#
# Uso: edge-diff.sh <arquivo> [--base <ref>] [--old <arquivo>]
#
#   --base  versão anterior via `git show <ref>:<caminho>` (default: HEAD)
#   --old   versão anterior num arquivo (ex.: cópia salva antes do re-despacho);
#           tem precedência sobre --base
#
# Saída: perdida<TAB><campo><TAB><ID>  (aresta da versão antiga ausente na nova)
#        acrescida<TAB><campo><TAB><ID> (informativa)
# Campos: os de aresta do graph-contract §2 (Pertence a, Brief, Realiza (FRs),
# AC violado, Componente, Funcionalidade, Depende de, Bloqueia, SPEC referenciada,
# FRs/NFRs cobertos, Realiza/Dependências por COMP, cobre por AC) + `criterio`
# (IDs citados nas seções Critérios de pronto/Roteiro do gate 9 — qualquer linha,
# continuação de item incluída, mesma âncora do graph.sh, 4.254).
# Exit: 0 nada perdido · 1 aresta perdida · 2 uso incorreto.
# Read-only; bash 3.2 + awk POSIX.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; }

FILE=""
BASE="HEAD"
OLDF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) shift; [ $# -gt 0 ] || die2 "--base exige uma ref."; BASE="$1" ;;
    --old)  shift; [ $# -gt 0 ] || die2 "--old exige um arquivo."; OLDF="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1" ;;
    *) [ -z "$FILE" ] || die2 "apenas um arquivo por vez."; FILE="$1" ;;
  esac
  shift
done
[ -n "$FILE" ] || { usage >&2; exit 2; }
[ -f "$FILE" ] || die2 "arquivo não existe: $FILE"

TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT

if [ -n "$OLDF" ]; then
  [ -f "$OLDF" ] || die2 "versão antiga não existe: $OLDF"
  cp "$OLDF" "$TMP/old.md" || die2 "não consegui ler $OLDF"
else
  command -v git >/dev/null 2>&1 || die2 "sem git para ler a versão base (use --old)."
  dir="$(cd "$(dirname "$FILE")" && pwd)"
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || die2 "fora de repositório git (use --old)."
  rel="$(cd "$dir" && git ls-files --full-name --error-unmatch "$(basename "$FILE")" 2>/dev/null)" \
    || die2 "arquivo não rastreado em $BASE (arquivo novo não tem 'antes' — nada a comparar; use --old se houver cópia)."
  git -C "$root" show "$BASE:$rel" > "$TMP/old.md" 2>/dev/null \
    || die2 "não consegui ler $BASE:$rel (arquivo novo nessa ref?)."
fi

extract() { # $1 = arquivo → linhas "campo<TAB>ID" ordenadas e únicas
  awk '
    function ids(campo, s,   id) {
      while (match(s, /(FR|NFR|AC|FEAT|COMP|TASK|PLAN|SPEC|BRIEF)-[0-9]+(-[0-9]+)?/)) {
        id = substr(s, RSTART, RLENGTH)
        print campo "\t" id
        s = substr(s, RSTART + RLENGTH)
      }
    }
    function rest(line,   p) { p = index(line, ":"); return (p ? substr(line, p + 1) : "") }
    { line = $0; sub(/\r$/, "", line) }
    /^### COMP-[0-9]+-[0-9]+/ { if (match(line, /COMP-[0-9]+-[0-9]+/)) ctx = substr(line, RSTART, RLENGTH); next }
    /^### /                    { ctx = "" }
    /^## /                     { ctx = ""
      if (line ~ /^## Crit/ || line ~ /^## Roteiro do gate 9/) sect = "crit"
      else sect = ""
      next
    }
    /^\*\*Pertence a\*\*[ \t]*:/       { ids("pertence-a", rest(line)); next }
    /^\*\*Brief\*\*[ \t]*:/            { ids("brief", rest(line)); next }
    /^\*\*Realiza \(FRs\)\*\*[ \t]*:/  { ids("realiza", rest(line)); next }
    /^\*\*AC violado\*\*[ \t]*:/       { ids("ac-violado", rest(line)); next }
    /^\*\*Componente\*\*[ \t]*:/       { ids("componente", rest(line)); next }
    /^\*\*Funcionalidade\*\*[ \t]*:/   { ids("funcionalidade", rest(line)); next }
    /^- \*\*Depende de\*\*[ \t]*:/     { ids("depende-de", rest(line)); next }
    /^- \*\*Bloqueia\*\*[ \t]*:/       { ids("bloqueia", rest(line)); next }
    /^\*\*SPEC referenciada\*\*[ \t]*:/ { ids("spec-ref", rest(line)); next }
    /^\*\*FRs cobertos\*\*/            { ids("fr-coberto", rest(line)); cover = "fr"; next }
    /^\*\*NFRs cobertos\*\*/           { ids("nfr-coberto", rest(line)); cover = "nfr"; next }
    /^\*\*Realiza\*\*[ \t]*:/ && ctx != "" { ids("realiza(" ctx ")", rest(line)); next }
    /^\*\*Depend/ && ctx != "" && index($0, "ncias**") > 0 { ids("dep(" ctx ")", rest(line)); next }
    /^\*\*/                            { cover = "" }
    cover == "fr"  && /^- /            { ids("fr-coberto", line); next }
    cover == "nfr" && /^- /            { ids("nfr-coberto", line); next }
    /^- \*\*AC-[0-9]+/ {
      if (match(line, /AC-[0-9]+-[0-9]+/)) ac = substr(line, RSTART, RLENGTH)
      ci = index(line, "(cobre")
      if (ci > 0) ids("cobre(" ac ")", substr(line, ci))
      next
    }
    # toda linha das secoes de criterio/gate 9 — mesma ancora do graph.sh (4.254):
    # item multi-linha cita AC na continuacao, que nao tem bullet
    sect == "crit" { ids("criterio", line); next }
  ' "$1" | sort -u
}

extract "$TMP/old.md" > "$TMP/old.tsv"
extract "$FILE"       > "$TMP/new.tsv"

perdidas=0
# comm exige entrada ordenada (extract já ordena)
comm -23 "$TMP/old.tsv" "$TMP/new.tsv" > "$TMP/lost.tsv"
comm -13 "$TMP/old.tsv" "$TMP/new.tsv" > "$TMP/added.tsv"
while IFS='	' read -r campo id; do
  [ -n "$campo" ] || continue
  printf 'perdida\t%s\t%s\n' "$campo" "$id"
  perdidas=$((perdidas + 1))
done < "$TMP/lost.tsv"
while IFS='	' read -r campo id; do
  [ -n "$campo" ] || continue
  printf 'acrescida\t%s\t%s\n' "$campo" "$id"
done < "$TMP/added.tsv"

[ "$perdidas" -eq 0 ] && exit 0
exit 1
