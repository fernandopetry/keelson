#!/usr/bin/env bash
# graph.sh — extrai, verifica e desenha o grafo dos artefatos SDD de um slug (decisão 4.82).
#
# Uso: graph.sh <dir-do-slug> ( --check | --format=tsv|mermaid|mermaid-comp )
#               [--stage=plan|tasks] [--plan MMM]
#
#   <dir-do-slug>  diretório já resolvido ({docsRoot}/<slug> — quem resolve docsRoot
#                  é o chamador; este script não lê a ficha)
#   --check        emite achados "SEVERIDADE<TAB>check<TAB>detalhe"; exit 1 se houver ERROR
#   --stage=plan   só os checks computáveis sem TASKs (gate do /keelson:plan)
#   --stage=tasks  todos os checks (gate do /keelson:tasks) — igual ao default
#   --plan MMM     restringe os achados ao PLAN-MMM e suas TASKs (ex.: --plan 001)
#   --format=tsv   emite o grafo (node/edge/warn) em TSV determinístico
#   --format=mermaid       flowchart das TASKs por wave (status no rótulo)
#   --format=mermaid-comp  flowchart FR → COMP + dependências COMP → COMP
#
# Contrato (dono único — sintaxe canônica, catálogo de arestas/checks, severidades):
# docs/_meta/conventions/graph-contract.md. O grafo é DERIVADO: este script é
# read-only sobre o slug e escreve apenas em stdout/stderr.
# Exit: 0 sem ERROR · 1 com ERROR (--check) · 2 uso incorreto.
#
# Bash 3.2-compatível, awk POSIX, sem dependências novas. Nomes de arquivo SDD são
# kebab-case sem espaço (convenção dos templates) — o script assume isso.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }

MODE=""
STAGE="all"
PLANF=""
SLUG_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      [ -z "$MODE" ] || die2 "use apenas um modo (--check ou --format)."
      MODE="check" ;;
    --format=tsv|--format=mermaid|--format=mermaid-comp)
      [ -z "$MODE" ] || die2 "use apenas um modo (--check ou --format)."
      MODE="${1#--format=}" ;;
    --format)
      shift; [ $# -gt 0 ] || die2 "--format exige um valor (tsv|mermaid|mermaid-comp)."
      case "$1" in tsv|mermaid|mermaid-comp) ;; *) die2 "formato desconhecido: $1" ;; esac
      [ -z "$MODE" ] || die2 "use apenas um modo (--check ou --format)."
      MODE="$1" ;;
    --stage=plan|--stage=tasks) STAGE="${1#--stage=}" ;;
    --plan)
      shift; [ $# -gt 0 ] || die2 "--plan exige o MMM (ex.: 001)."
      PLANF="${1#PLAN-}" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1 (use --help)" ;;
    *)
      [ -z "$SLUG_DIR" ] || die2 "apenas um diretório de slug por vez."
      SLUG_DIR="$1" ;;
  esac
  shift
done

[ -n "$SLUG_DIR" ] || { usage >&2; exit 2; }
[ -n "$MODE" ] || { usage >&2; exit 2; }
[ -d "$SLUG_DIR" ] || die2 "diretório não existe: $SLUG_DIR"

cd "$SLUG_DIR" || die2 "não consegui entrar em $SLUG_DIR"

SRC="$( { ls specs/SPEC-*.md plans/PLAN-*.md tasks/TASK-*.md 2>/dev/null || true; } | grep -v -- '-INDEX\.md$' || true)"
IDX="$(ls tasks/TASK-*-INDEX.md 2>/dev/null || true)"
[ -n "$SRC" ] || die2 "nenhum artefato SDD (specs/SPEC-*.md, plans/PLAN-*.md, tasks/TASK-*.md) em: $SLUG_DIR"

TMP="$(mktemp -d)" || die2 "não consegui criar diretório temporário."
trap 'rm -rf "$TMP"' EXIT

# ============================ EXTRATOR ============================
# Lê os artefatos e emite linhas cruas:
#   node <TIPO> <ID> <arquivo> <attrs>
#   edge <tipo> <DE> <PARA> <arquivo:linha>
#   warn nao-parseavel <arquivo> <campo> <trecho>
#   index-wave / index-frcov / index-accov  (do TASK-MMM-INDEX, só p/ index-desatualizado)
cat > "$TMP/extract.awk" <<'AWK'
function warnout(field, snippet) {
  gsub(/\t/, " ", snippet)
  sub(/^[ \t]+/, "", snippet); sub(/[ \t]+$/, "", snippet)
  if (length(snippet) > 80) snippet = substr(snippet, 1, 77) "..."
  print "warn\tnao-parseavel\t" FILENAME "\t" field "\t" snippet
}
function trimtok(t) {
  gsub(/\*/, "", t); gsub(/`/, "", t)
  sub(/^[ \t]+/, "", t); sub(/[ \t.;]+$/, "", t)
  return t
}
# lista canônica: IDs separados por vírgula, ou nenhuma/vazio. Popula TOK[1..TN].
# Devolve 1 se parseável; 0 se irreconhecível (nesse caso NENHUMA aresta é emitida).
function parselist(val, typere,   n, i, t, arr, low) {
  TN = 0
  sub(/^[ \t]+/, "", val); sub(/[ \t]+$/, "", val)
  if (val == "") return 1
  low = tolower(trimtok(val))
  if (low == "nenhuma" || low == "nenhum" || low == "-" || low == "n/a") return 1
  n = split(val, arr, ",")
  for (i = 1; i <= n; i++) {
    t = trimtok(arr[i])
    if (t == "") continue
    if (t !~ typere) { TN = 0; return 0 }
    TN++; TOK[TN] = t
  }
  return 1
}
function fieldrest(line,   p) {
  p = index(line, ":")
  if (p == 0) return ""
  return substr(line, p + 1)
}
function node(type, id) {
  ND++; NDT[ND] = type; NDI[ND] = id; NDF[ND] = FILENAME
  return ND
}
function edge(type, from, to) {
  print "edge\t" type "\t" from "\t" to "\t" FILENAME ":" FNR
}
function listedges(type, from, val, typere, field,   i) {
  if (!parselist(val, typere)) { warnout(field, val); return }
  for (i = 1; i <= TN; i++) edge(type, from, TOK[i])
}
function grabid(line, re) {
  if (match(line, re)) return substr(line, RSTART, RLENGTH)
  return ""
}
# extrai todos os IDs que casam re e emite covers-ac dedupado
function allac(line, from,   s, id) {
  s = line
  while (match(s, /AC-[0-9]+-[0-9]+/)) {
    id = substr(s, RSTART, RLENGTH)
    if (!((from SUBSEP id) in SEENAC)) {
      SEENAC[from, id] = 1
      edge("covers-ac", from, id)
    }
    s = substr(s, RSTART + RLENGTH)
  }
}
function sortjoin(arr, n,   i, j, t, out) {
  for (i = 2; i <= n; i++)
    for (j = i; j > 1 && arr[j] < arr[j-1]; j--) { t = arr[j]; arr[j] = arr[j-1]; arr[j-1] = t }
  out = ""
  for (i = 1; i <= n; i++) out = (out == "" ? arr[i] : out " " arr[i])
  return out
}

FNR == 1 {
  ftype = "?"
  if (FILENAME ~ /-INDEX\.md$/)              ftype = "I"
  else if (FILENAME ~ /(^|\/)specs\//)       ftype = "S"
  else if (FILENAME ~ /(^|\/)plans\//)       ftype = "P"
  else if (FILENAME ~ /(^|\/)tasks\//)       ftype = "T"
  cur_feat = ""; cur_comp = ""; cur_nd = 0; sect = ""; covermode = ""; curwave = ""
  fmmm = ""
  if (match(FILENAME, /TASK-[0-9]+/)) fmmm = substr(FILENAME, RSTART + 5, RLENGTH - 5)
}

{
  line = $0
  sub(/\r$/, "", line)
  if (FNR == 1 && index(line, "\357\273\277") == 1) line = substr(line, 4)
  while ((ci = index(line, "<!--")) > 0) {
    rest = substr(line, ci + 4)
    ce = index(rest, "-->")
    if (ce == 0) { line = substr(line, 1, ci - 1); break }
    line = substr(line, 1, ci - 1) substr(rest, ce + 3)
  }
}

# ---------- SPEC ----------
ftype == "S" && line ~ /^# SPEC-[0-9]+/ {
  id = grabid(line, "SPEC-[0-9]+"); if (id != "") node("SPEC", id); next
}
ftype == "S" && line ~ /^## / { cur_feat = ""; next }
ftype == "S" && line ~ /^### FEAT-[0-9]+-[0-9]+/ {
  id = grabid(line, "FEAT-[0-9]+-[0-9]+")
  if (id != "") { node("FEAT", id); cur_feat = id }
  next
}
ftype == "S" && line ~ /^- \*\*FR-[0-9]+-[0-9]+\*\*/ {
  id = grabid(line, "FR-[0-9]+-[0-9]+")
  if (id != "") { node("FR", id); if (cur_feat != "") edge("feat-of", id, cur_feat) }
  next
}
ftype == "S" && line ~ /^- \*\*NFR-[0-9]+-[0-9]+\*\*/ {
  id = grabid(line, "NFR-[0-9]+-[0-9]+"); if (id != "") node("NFR", id); next
}
ftype == "S" && line ~ /^- \*\*AC-[0-9]+-[0-9]+\*\*/ {
  id = grabid(line, "AC-[0-9]+-[0-9]+")
  if (id == "") next
  node("AC", id)
  ci = index(line, "(cobre")
  if (ci > 0) {
    rest = substr(line, ci + 6)
    ce = index(rest, ")")
    if (ce > 0) listedges("ac-covers", id, substr(rest, 1, ce - 1), "^(FR|NFR)-[0-9]+-[0-9]+$", "cobre")
    else warnout("cobre", line)
  }
  next
}

# ---------- PLAN ----------
ftype == "P" && line ~ /^# PLAN-[0-9]+/ {
  id = grabid(line, "PLAN-[0-9]+")
  if (id != "") cur_nd = node("PLAN", id)
  next
}
ftype == "P" && line ~ /^## / {
  cur_comp = ""; covermode = ""
  if (line ~ /Mapeamento FR/) sect = "map7"
  else if (line ~ /^## Cobertura/) sect = "cob"
  else sect = ""
  next
}
ftype == "P" && line ~ /^\*\*Status\*\*[ \t]*:/ && cur_nd > 0 && cur_comp == "" {
  NSTAT[cur_nd] = trimtok(fieldrest(line)); next
}
ftype == "P" && line ~ /^\*\*SPEC referenciada\*\*[ \t]*:/ {
  id = NDI[cur_nd]
  if (id != "") listedges("spec-ref", id, fieldrest(line), "^SPEC-[0-9]+$", "SPEC referenciada")
  next
}
ftype == "P" && sect == "cob" && line ~ /^\*\*FRs cobertos\*\*/  { covermode = "fr";  next }
ftype == "P" && sect == "cob" && line ~ /^\*\*NFRs cobertos\*\*/ { covermode = "nfr"; next }
ftype == "P" && sect == "cob" && line ~ /^\*\*/                  { covermode = "";    next }
ftype == "P" && sect == "cob" && covermode != "" && line ~ /^- / {
  v = trimtok(substr(line, 3))
  sub(/[ \t].*$/, "", v)
  if (covermode == "fr" && v ~ /^FR-[0-9]+-[0-9]+$/)        edge("plan-covers", NDI[cur_nd], v)
  else if (covermode == "nfr" && v ~ /^NFR-[0-9]+-[0-9]+$/) edge("plan-covers", NDI[cur_nd], v)
  else warnout((covermode == "fr" ? "FRs cobertos" : "NFRs cobertos"), line)
  next
}
ftype == "P" && line ~ /^### COMP-[0-9]+-[0-9]+/ {
  id = grabid(line, "COMP-[0-9]+-[0-9]+")
  if (id != "") { node("COMP", id); cur_comp = id }
  next
}
ftype == "P" && line ~ /^### DEC-[0-9]+-[0-9]+/ {
  id = grabid(line, "DEC-[0-9]+-[0-9]+"); if (id != "") node("DEC", id)
  cur_comp = ""
  next
}
ftype == "P" && line ~ /^### / { cur_comp = ""; next }
ftype == "P" && cur_comp != "" && line ~ /^\*\*Realiza\*\*[ \t]*:/ {
  listedges("comp-realiza", cur_comp, fieldrest(line), "^(FR|NFR)-[0-9]+-[0-9]+$", "Realiza")
  next
}
ftype == "P" && cur_comp != "" && line ~ /^\*\*Depend/ && index(line, "ncias**") > 0 {
  listedges("comp-dep", cur_comp, fieldrest(line), "^COMP-[0-9]+-[0-9]+$", "Dependências")
  next
}
ftype == "P" && sect == "map7" && line ~ /^\|/ {
  n = split(line, c, "|")
  if (n < 4) next
  fr = trimtok(c[2]); comp = trimtok(c[3])
  if (fr !~ /^(FR|NFR)-[0-9]+-[0-9]+$/) next
  if (comp ~ /^COMP-[0-9]+-[0-9]+$/) edge("maps", fr, comp)
  else warnout("Mapeamento §7", line)
  s = c[4]
  while (match(s, /AC-[0-9]+-[0-9]+/)) {
    edge("maps-ac", fr, substr(s, RSTART, RLENGTH))
    s = substr(s, RSTART + RLENGTH)
  }
  next
}

# ---------- TASK ----------
ftype == "T" && line ~ /^# TASK-[0-9]+-[0-9]+/ {
  id = grabid(line, "TASK-[0-9]+-[0-9]+")
  if (id != "") { cur_nd = node("TASK", id); cur_task = id }
  next
}
ftype == "T" && line ~ /^## / {
  if (line ~ /^## Crit/) sect = "crit"
  else if (line ~ /^## Roteiro do gate 9/) sect = "gate9"
  else sect = ""
  next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Pertence a\*\*[ \t]*:/ {
  listedges("belongs-to", cur_task, fieldrest(line), "^PLAN-[0-9]+$", "Pertence a"); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Realiza \(FRs\)\*\*[ \t]*:/ {
  listedges("realiza", cur_task, fieldrest(line), "^FR-[0-9]+-[0-9]+$", "Realiza (FRs)"); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*AC violado\*\*[ \t]*:/ {
  listedges("violates", cur_task, fieldrest(line), "^AC-[0-9]+-[0-9]+$", "AC violado"); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Componente\*\*[ \t]*:/ {
  listedges("implements", cur_task, fieldrest(line), "^COMP-[0-9]+-[0-9]+$", "Componente"); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Wave\*\*[ \t]*:/ {
  v = trimtok(fieldrest(line))
  if (v ~ /^[0-9]+$/) NWAVE[cur_nd] = v
  else if (v != "") warnout("Wave", v)
  next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Status\*\*[ \t]*:/ {
  NSTAT[cur_nd] = trimtok(fieldrest(line)); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Tipo\*\*[ \t]*:/ {
  NTIPO[cur_nd] = trimtok(fieldrest(line)); next
}
ftype == "T" && cur_task != "" && line ~ /^\*\*Funcionalidade\*\*[ \t]*:/ {
  v = fieldrest(line)
  sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
  if (v == "") next
  if (tolower(v) ~ /^transversal/) {
    ci = index(v, "(")
    ce = 0; if (ci > 0) ce = index(substr(v, ci), ")")
    if (ci > 0 && ce > 1) {
      listedges("declares-feat", cur_task, substr(v, ci + 1, ce - 2), "^FEAT-[0-9]+-[0-9]+$", "Funcionalidade")
    } else warnout("Funcionalidade", v)
    next
  }
  n = split(v, arr, ",")
  ok = 1
  for (i = 1; i <= n; i++) {
    t = arr[i]
    isp = 0
    if (index(t, "(prim") > 0) { isp = 1; sub(/\(prim[^)]*\)/, "", t) }
    t = trimtok(t)
    if (t == "") continue
    if (t !~ /^FEAT-[0-9]+-[0-9]+$/) { ok = 0; break }
    PF_N++; PF_T[PF_N] = t; PF_P[PF_N] = isp
  }
  if (!ok) { PF_N = 0; warnout("Funcionalidade", v); next }
  for (i = 1; i <= PF_N; i++) {
    edge("declares-feat", cur_task, PF_T[i])
    if (PF_P[i]) edge("feat-primaria", cur_task, PF_T[i])
  }
  PF_N = 0
  next
}
ftype == "T" && cur_task != "" && line ~ /^- \*\*Depende de\*\*[ \t]*:/ {
  listedges("task-dep", cur_task, fieldrest(line), "^TASK-[0-9]+-[0-9]+$", "Depende de"); next
}
ftype == "T" && cur_task != "" && line ~ /^- \*\*Bloqueia\*\*[ \t]*:/ {
  listedges("blocks", cur_task, fieldrest(line), "^TASK-[0-9]+-[0-9]+$", "Bloqueia"); next
}
ftype == "T" && cur_task != "" && sect == "crit" && line ~ /^- \[[ xX]\]/ { allac(line, cur_task); next }
ftype == "T" && cur_task != "" && sect == "gate9" { allac(line, cur_task); next }

# ---------- TASK-MMM-INDEX (só p/ index-desatualizado) ----------
ftype == "I" && line ~ /^### Wave [0-9]+/ {
  curwave = grabid(line, "[0-9]+"); sect = "wave"; next
}
ftype == "I" && line ~ /^## Cobertura de FRs/ { sect = "frcov"; curwave = ""; next }
ftype == "I" && line ~ /^## Cobertura de ACs/ { sect = "accov"; curwave = ""; next }
ftype == "I" && line ~ /^## / { sect = ""; curwave = ""; next }
ftype == "I" && sect == "wave" && curwave != "" && line ~ /TASK-[0-9]+-[0-9]+/ && line ~ /^- / {
  id = grabid(line, "TASK-[0-9]+-[0-9]+")
  if (id != "") print "index-wave\t" fmmm "\t" id "\t" curwave "\t" FILENAME
  next
}
(ftype == "I") && (sect == "frcov" || sect == "accov") && line ~ /^\|/ {
  n = split(line, c, "|")
  if (n < 3) next
  key = trimtok(c[2])
  if (sect == "frcov" && key !~ /^FR-[0-9]+-[0-9]+$/) next
  if (sect == "accov" && key !~ /^AC-[0-9]+-[0-9]+$/) next
  tn = 0; s = c[3]
  while (match(s, /TASK-[0-9]+-[0-9]+/)) {
    tn++; tl[tn] = substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
  }
  print (sect == "frcov" ? "index-frcov" : "index-accov") "\t" fmmm "\t" key "\t" sortjoin(tl, tn) "\t" FILENAME
  next
}

END {
  for (i = 1; i <= ND; i++) {
    a = ""
    if (i in NWAVE) a = "wave=" NWAVE[i]
    if (i in NSTAT) a = a (a == "" ? "" : " ") "status=" NSTAT[i]
    if (i in NTIPO) a = a (a == "" ? "" : " ") "tipo=" NTIPO[i]
    print "node\t" NDT[i] "\t" NDI[i] "\t" NDF[i] "\t" a
  }
}
AWK

# shellcheck disable=SC2086
awk -f "$TMP/extract.awk" $SRC $IDX > "$TMP/raw.tsv" || die2 "extração falhou."
sort "$TMP/raw.tsv" > "$TMP/graph.tsv"

if [ "$MODE" = "tsv" ]; then
  grep -v '^index-' "$TMP/graph.tsv" || true
  exit 0
fi

if [ "$MODE" = "mermaid" ] || [ "$MODE" = "mermaid-comp" ]; then
  cat > "$TMP/mermaid.awk" <<'AWK'
BEGIN { FS = "\t" }
function sid(id,   s) { s = id; gsub(/-/, "_", s); return s }
function icon(st) {
  if (st == "Done") return "\342\234\205"
  if (st == "In Progress") return "\360\237\224\265"
  if (st == "Blocked") return "\360\237\232\253"
  return "\342\217\270"
}
$1 == "node" && $2 == "TASK" && M == "task" {
  w = "?"; st = ""
  n = split($5, a, " ")
  for (i = 1; i <= n; i++) {
    if (a[i] ~ /^wave=/)   w = substr(a[i], 6)
    if (a[i] ~ /^status=/) st = substr(a[i], 8)
  }
  # status pode ter espaço ("In Progress") — re-junta o que sobrou depois de status=
  if (index($5, "status=") > 0) {
    st = substr($5, index($5, "status=") + 7)
    sub(/ tipo=.*$/, "", st)
  }
  TN++; TID[TN] = $3; TW[TN] = w; TST[TN] = st
  if (!(w in WSEEN)) { WSEEN[w] = 1; WN++; WL[WN] = w }
}
$1 == "edge" && $2 == "task-dep" && M == "task" { EN++; EF[EN] = $3; ET[EN] = $4 }
$1 == "node" && ($2 == "FR" || $2 == "COMP") && M == "comp" { CN++; CT[CN] = $2; CI[CN] = $3 }
$1 == "edge" && $2 == "maps" && M == "comp"     { EN++; EF[EN] = $3; ET[EN] = $4 }
$1 == "edge" && $2 == "comp-dep" && M == "comp" { DN++; DF[DN] = $3; DT[DN] = $4 }
END {
  print "flowchart TD"
  if (M == "task") {
    for (x = 2; x <= WN; x++)
      for (y = x; y > 1 && WL[y] + 0 < WL[y-1] + 0; y--) { t = WL[y]; WL[y] = WL[y-1]; WL[y-1] = t }
    for (x = 1; x <= WN; x++) {
      wid = WL[x]; gsub(/[^0-9A-Za-z]/, "x", wid)
      print "  subgraph W" wid "[\"Wave " WL[x] "\"]"
      for (i = 1; i <= TN; i++)
        if (TW[i] == WL[x]) print "    " sid(TID[i]) "[\"" TID[i] " " icon(TST[i]) "\"]"
      print "  end"
    }
    for (i = 1; i <= EN; i++) print "  " sid(ET[i]) " --> " sid(EF[i])
  } else {
    for (i = 1; i <= CN; i++)
      if (CT[i] == "FR") print "  " sid(CI[i]) "[\"" CI[i] "\"]"
    for (i = 1; i <= CN; i++)
      if (CT[i] == "COMP") print "  " sid(CI[i]) "([\"" CI[i] "\"])"
    for (i = 1; i <= EN; i++) print "  " sid(EF[i]) " --> " sid(ET[i])
    for (i = 1; i <= DN; i++) print "  " sid(DF[i]) " --> " sid(DT[i])
  }
}
AWK
  M="task"; [ "$MODE" = "mermaid-comp" ] && M="comp"
  awk -v M="$M" -f "$TMP/mermaid.awk" "$TMP/graph.tsv"
  exit 0
fi

# ============================ CHECKER ============================
cat > "$TMP/check.awk" <<'AWK'
BEGIN { FS = "\t" }
function mmm(id,   a, n) { n = split(id, a, "-"); return a[2] }
function finding(sev, chk, det) { print sev "\t" chk "\t" det }
function scope_of(f) {
  if (match(f, /PLAN-[0-9]+/)) return substr(f, RSTART + 5, RLENGTH - 5)
  if (match(f, /TASK-[0-9]+/)) return substr(f, RSTART + 5, RLENGTH - 5)
  return ""
}
function inplan(f,   s) {
  if (PLANF == "") return 1
  s = scope_of(f)
  return (s == "" || s == PLANF)
}
function ssortidx(arr, n,   i, j, t) {
  for (i = 2; i <= n; i++)
    for (j = i; j > 1 && arr[j] < arr[j-1]; j--) { t = arr[j]; arr[j] = arr[j-1]; arr[j-1] = t }
}

$1 == "warn" { finding("WARNING", "nao-parseavel", $3 " campo \"" $4 "\": " $5); next }

$1 == "node" {
  type = $2; id = $3; f = $4
  cnt[type SUBSEP id]++
  if (cnt[type, id] == 1) { NN++; NTY[NN] = type; NID[NN] = id }
  nfiles[type, id] = ((type, id) in nfiles ? nfiles[type, id] ", " f : f)
  exist[id] = 1
  nodefile[id] = f
  if ($5 != "") {
    if (match($5, /wave=[0-9]+/)) wave[id] = substr($5, RSTART + 5, RLENGTH - 5)
    if (index($5, "status=") > 0) {
      st = substr($5, index($5, "status=") + 7)
      sub(/ tipo=.*$/, "", st)
      status[id] = st
    }
  }
  if (type == "TASK") { TKN++; TK[TKN] = id }
  if (type == "COMP") { CPN++; CP[CPN] = id }
  if (type == "PLAN") { planbymmm[mmm(id)] = id }
  next
}
$1 == "edge" {
  EN++; ET[EN] = $2; EF[EN] = $3; ETO[EN] = $4; EL[EN] = $5
  if ($2 == "task-dep")      { td[$3 SUBSEP $4] = $5 }
  if ($2 == "blocks")        { bl[$3 SUBSEP $4] = $5 }
  if ($2 == "belongs-to")    { belongs[$3] = $4 }
  if ($2 == "plan-covers")   { pcov[$3 SUBSEP $4] = 1 }
  if ($2 == "realiza")       { RZN++; RZF[RZN] = $3; RZT[RZN] = $4 }
  if ($2 == "maps")          { mapped_to[$4] = 1; MPN++; MPF[MPN] = $3; MPT[MPN] = $4; MPL[MPN] = $5 }
  if ($2 == "comp-realiza")  { CRN++; CRF[CRN] = $3; CRT[CRN] = $4 }
  if ($2 == "ac-covers")     { ACN++; ACF[ACN] = $3; ACT[ACN] = $4 }
  if ($2 == "covers-ac")     { covac[$3 SUBSEP $4] = 1 }
  if ($2 == "declares-feat") { dfn[$3]++; df[$3 SUBSEP $4] = 1; DFN++; DFF[DFN] = $3; DFT[DFN] = $4 }
  if ($2 == "feat-primaria") { fprim[$3] = $4 }
  if ($2 == "feat-of")       { featof[$3] = $4 }
  next
}
$1 == "index-wave"  { IWN++; IWM[IWN] = $2; IWT[IWN] = $3; IWW[IWN] = $4; IWF[IWN] = $5; idxseen[$2] = 1; next }
$1 == "index-frcov" { IFN++; IFM[IFN] = $2; IFK[IFN] = $3; IFL[IFN] = $4; idxfr[$2] = 1; next }
$1 == "index-accov" { IAN++; IAM[IAN] = $2; IAK[IAN] = $3; IAL[IAN] = $4; idxac[$2] = 1; next }

END {
  planside["spec-ref"] = 1;  planside["plan-covers"] = 1; planside["maps"] = 1
  planside["maps-ac"] = 1;   planside["comp-realiza"] = 1; planside["comp-dep"] = 1
  planside["ac-covers"] = 1; planside["feat-of"] = 1

  # planof(task): belongs-to quando existe, senão MMM do ID
  for (i = 1; i <= TKN; i++) {
    t = TK[i]
    p = (t in belongs) ? belongs[t] : ""
    if (p == "" && (mmm(t) in planbymmm)) p = planbymmm[mmm(t)]
    planof[t] = p
  }

  # ---- id-duplicado (todo stage) ----
  for (i = 1; i <= NN; i++) {
    if (cnt[NTY[i], NID[i]] > 1)
      finding("ERROR", "id-duplicado", NID[i] " declarado " cnt[NTY[i], NID[i]] "x (" nfiles[NTY[i], NID[i]] ")")
  }

  # ---- ref-quebrada ----
  for (i = 1; i <= EN; i++) {
    if (STAGE == "plan" && !(ET[i] in planside)) continue
    if (!inplan(EL[i])) continue
    if (!(ETO[i] in exist))
      finding("ERROR", "ref-quebrada", EF[i] " -> " ETO[i] " nao existe no slug (" ET[i] ", " EL[i] ")")
  }

  # ---- ciclo-comp (Kahn sobre comp-dep) ----
  cyc("comp-dep", "ciclo-comp")

  if (STAGE != "plan") {
    # ---- ciclo-task ----
    cyc("task-dep", "ciclo-task")

    # ---- wave-incoerente ----
    for (k in td) {
      split(k, kk, SUBSEP); t = kk[1]; d = kk[2]
      if (!inplan(nodefile[t])) continue
      if (!(t in exist) || !(d in exist)) continue
      if (planof[t] != planof[d] || planof[t] == "") continue
      if (!(t in wave) || !(d in wave)) continue
      if (wave[t] + 0 <= wave[d] + 0) {
        det = t " (wave " wave[t] ") depende de " d " (wave " wave[d] ")"
        if (status[t] == "Done") finding("WARNING", "wave-incoerente", det " [legacy]")
        else finding("ERROR", "wave-incoerente", det)
      }
    }

    # ---- fr-sem-task / ac-sem-task ----
    for (k in pcov) {
      split(k, kk, SUBSEP); p = kk[1]; fr = kk[2]
      if (fr !~ /^FR-/) continue
      if (!(fr in exist)) continue
      if (PLANF != "" && mmm(p) != PLANF) continue
      hit = 0
      for (i = 1; i <= RZN; i++) if (RZT[i] == fr && planof[RZF[i]] == p) { hit = 1; break }
      if (!hit) {
        det = fr " coberto por " p " sem TASK que o realize"
        if (status[p] == "Done") finding("WARNING", "fr-sem-task", det " [legacy]")
        else finding("ERROR", "fr-sem-task", det)
      }
    }
    for (i = 1; i <= ACN; i++) {
      ac = ACF[i]; fr = ACT[i]
      for (j = 1; j <= NN; j++) if (NTY[j] == "PLAN") {
        p = NID[j]
        if (!((p SUBSEP fr) in pcov)) continue
        if (PLANF != "" && mmm(p) != PLANF) continue
        hit = 0
        for (x = 1; x <= TKN; x++) if (planof[TK[x]] == p && ((TK[x] SUBSEP ac) in covac)) { hit = 1; break }
        if (!hit) {
          det = ac " (cobre " fr ", " p ") sem TASK que o cubra em criterio ou roteiro"
          if (status[p] == "Done") finding("WARNING", "ac-sem-task", det " [legacy]")
          else finding("ERROR", "ac-sem-task", det)
        }
      }
    }

    # ---- realiza-fora-cobertura ----
    for (i = 1; i <= RZN; i++) {
      t = RZF[i]; fr = RZT[i]
      if (!inplan(nodefile[t])) continue
      if (!(fr in exist)) continue
      p = planof[t]
      if (p == "" || !(p in exist)) continue
      if (!((p SUBSEP fr) in pcov))
        finding("ERROR", "realiza-fora-cobertura", t " realiza " fr " que " p " nao cobre")
    }

    # ---- feat-divergente ----
    for (i = 1; i <= TKN; i++) {
      t = TK[i]
      if (!inplan(nodefile[t])) continue
      dn = 0; delete want
      for (j = 1; j <= RZN; j++) if (RZF[j] == t && (RZT[j] in featof)) want[featof[RZT[j]]] = 1
      for (w in want) dn++
      if (dn == 0) continue
      if (!(t in dfn)) continue
      bad = ""
      for (j = 1; j <= DFN; j++) if (DFF[j] == t && !(DFT[j] in want)) bad = bad (bad == "" ? "" : ", ") DFT[j]
      miss = ""
      for (w in want) if (!((t SUBSEP w) in df)) miss = miss (miss == "" ? "" : ", ") w
      if (bad != "" || miss != "") {
        det = t ": Funcionalidade declarada diverge do derivado"
        if (bad != "")  det = det " (sobrando: " bad ")"
        if (miss != "") det = det " (faltando: " miss ")"
        finding("ERROR", "feat-divergente", det)
      } else if ((t in fprim) && !(fprim[t] in want)) {
        finding("ERROR", "feat-divergente", t ": primaria " fprim[t] " fora do conjunto derivado")
      }
    }

    # ---- dep-bloqueia-assimetrica ----
    for (k in td) {
      split(k, kk, SUBSEP); a = kk[1]; b = kk[2]
      if (!inplan(nodefile[a])) continue
      if (!((b SUBSEP a) in bl))
        finding("WARNING", "dep-bloqueia-assimetrica", a " depende de " b " sem " b " declarar Bloqueia " a)
    }
    for (k in bl) {
      split(k, kk, SUBSEP); b = kk[1]; a = kk[2]
      if (!inplan(nodefile[b])) continue
      if (!((a SUBSEP b) in td))
        finding("WARNING", "dep-bloqueia-assimetrica", b " bloqueia " a " sem " a " declarar Depende de " b)
    }

    # ---- pertence-vs-arquivo ----
    for (i = 1; i <= TKN; i++) {
      t = TK[i]
      if (!inplan(nodefile[t])) continue
      fm = ""
      if (match(nodefile[t], /TASK-[0-9]+/)) fm = substr(nodefile[t], RSTART + 5, RLENGTH - 5)
      if (fm != "" && fm != mmm(t))
        finding("ERROR", "pertence-vs-arquivo", t ": MMM do arquivo (" fm ") difere do ID (" nodefile[t] ")")
      if ((t in belongs) && mmm(belongs[t]) != mmm(t))
        finding("ERROR", "pertence-vs-arquivo", t ": Pertence a " belongs[t] " difere do MMM do ID")
    }

    # ---- index-desatualizado ----
    for (i = 1; i <= IWN; i++) {
      if (PLANF != "" && IWM[i] != PLANF) continue
      t = IWT[i]
      if (!(t in exist))
        finding("WARNING", "index-desatualizado", IWF[i] ": lista " t " que nao existe")
      else if ((t in wave) && wave[t] != IWW[i])
        finding("WARNING", "index-desatualizado", IWF[i] ": " t " em Wave " IWW[i] " mas o arquivo declara wave " wave[t])
    }
    for (i = 1; i <= IFN; i++) {
      if (PLANF != "" && IFM[i] != PLANF) continue
      cn2 = 0; delete cl
      for (j = 1; j <= RZN; j++) if (RZT[j] == IFK[i] && mmm(RZF[j]) == IFM[i]) { cn2++; cl[cn2] = RZF[j] }
      ssortidx(cl, cn2)
      comp2 = ""
      for (j = 1; j <= cn2; j++) comp2 = (comp2 == "" ? cl[j] : comp2 " " cl[j])
      if (comp2 != IFL[i])
        finding("WARNING", "index-desatualizado", "Cobertura de FRs (" IFK[i] "): INDEX lista \"" IFL[i] "\", computado \"" comp2 "\"")
    }
    for (i = 1; i <= IAN; i++) {
      if (PLANF != "" && IAM[i] != PLANF) continue
      cn2 = 0; delete cl
      for (t in planof) if (mmm(t) == IAM[i] && ((t SUBSEP IAK[i]) in covac)) { cn2++; cl[cn2] = t }
      ssortidx(cl, cn2)
      comp2 = ""
      for (j = 1; j <= cn2; j++) comp2 = (comp2 == "" ? cl[j] : comp2 " " cl[j])
      if (comp2 != IAL[i])
        finding("WARNING", "index-desatualizado", "Cobertura de ACs (" IAK[i] "): INDEX lista \"" IAL[i] "\", computado \"" comp2 "\"")
    }
  }

  # ---- fr-sem-comp (FR coberto sem linha na §7 do seu PLAN) ----
  for (k in pcov) {
    split(k, kk, SUBSEP); p = kk[1]; fr = kk[2]
    if (fr !~ /^FR-/) continue
    if (!(fr in exist)) continue
    if (PLANF != "" && mmm(p) != PLANF) continue
    hit = 0
    for (i = 1; i <= MPN; i++) if (MPF[i] == fr && mmm(MPT[i]) == mmm(p)) { hit = 1; break }
    if (!hit) {
      det = fr " coberto por " p " sem linha no Mapeamento FR -> componente (§7)"
      if (status[p] == "Done") finding("WARNING", "fr-sem-comp", det " [legacy]")
      else finding("ERROR", "fr-sem-comp", det)
    }
  }

  # ---- fr-mapeado-fora-cobertura / comp-sem-fr / realiza-vs-mapeamento (todo stage) ----
  for (i = 1; i <= MPN; i++) {
    fr = MPF[i]; comp = MPT[i]
    if (!inplan(MPL[i])) continue
    if (!(fr in exist)) continue
    p = (mmm(comp) in planbymmm) ? planbymmm[mmm(comp)] : ""
    if (p == "") continue
    if (!((p SUBSEP fr) in pcov))
      finding("ERROR", "fr-mapeado-fora-cobertura", "§7 mapeia " fr " -> " comp " mas " p " nao o cobre")
  }
  for (i = 1; i <= CPN; i++) {
    if (!inplan(nodefile[CP[i]])) continue
    if (!(CP[i] in mapped_to))
      finding("WARNING", "comp-sem-fr", CP[i] " sem linha no Mapeamento FR -> componente (§7)")
  }
  for (i = 1; i <= CPN; i++) {
    comp = CP[i]
    if (!inplan(nodefile[comp])) continue
    diff = ""
    for (j = 1; j <= CRN; j++) if (CRF[j] == comp) {
      hit = 0
      for (x = 1; x <= MPN; x++) if (MPT[x] == comp && MPF[x] == CRT[j]) { hit = 1; break }
      if (!hit) diff = diff (diff == "" ? "" : ", ") CRT[j] " (so no Realiza)"
    }
    for (x = 1; x <= MPN; x++) if (MPT[x] == comp) {
      hit = 0
      for (j = 1; j <= CRN; j++) if (CRF[j] == comp && CRT[j] == MPF[x]) { hit = 1; break }
      if (!hit) diff = diff (diff == "" ? "" : ", ") MPF[x] " (so na §7)"
    }
    if (diff != "")
      finding("WARNING", "realiza-vs-mapeamento", comp ": Realiza e §7 divergem — " diff)
  }
}

# Kahn: detecta ciclo no tipo de aresta et; reporta um ciclo concreto por componente
function cyc(et, chk,   i, n, ids, indeg, succ, nsucc, changed, rem, remn, j, k, path, pn, cur, seenw, out, t) {
  n = 0
  for (i = 1; i <= EN; i++) {
    if (ET[i] != et) continue
    if (PLANF != "" && !inplan(EL[i])) continue
    if (!(EF[i] in exist) || !(ETO[i] in exist)) continue
    nsucc[EF[i]]++; succ[EF[i], nsucc[EF[i]]] = ETO[i]
    indeg[ETO[i]]++
    if (!(EF[i] in ids)) { ids[EF[i]] = 1; n++ }
    if (!(ETO[i] in ids)) { ids[ETO[i]] = 1; n++ }
  }
  changed = 1
  while (changed) {
    changed = 0
    for (k in ids) {
      if (ids[k] == 1 && (!(k in indeg) || indeg[k] == 0)) {
        ids[k] = 0; changed = 1
        for (j = 1; j <= nsucc[k]; j++) indeg[succ[k, j]]--
      }
    }
  }
  remn = 0
  for (k in ids) if (ids[k] == 1) { remn++; rem[remn] = k }
  if (remn == 0) return
  ssortidx(rem, remn)
  for (i = 1; i <= remn; i++) {
    cur = rem[i]
    if (cur in seenw) continue
    pn = 0; delete path
    while (!(cur in path)) {
      path[cur] = ++pn; seenw[cur] = 1
      t = ""
      for (j = 1; j <= nsucc[cur]; j++) {
        k = succ[cur, j]
        if (ids[k] == 1 && (t == "" || k < t)) t = k
      }
      if (t == "") break
      cur = t
    }
    if (cur in path) {
      out = cur
      # reconstruir na ordem do caminho a partir do ponto onde o ciclo fecha
      for (j = path[cur] + 1; j <= pn; j++)
        for (k in path) if (path[k] == j) out = out " -> " k
      out = out " -> " cur
      finding("ERROR", chk, out)
    }
  }
}
AWK

awk -v STAGE="$STAGE" -v PLANF="$PLANF" -f "$TMP/check.awk" "$TMP/graph.tsv" > "$TMP/findings.txt" || die2 "verificação falhou."
sort "$TMP/findings.txt"
if grep -q '^ERROR' "$TMP/findings.txt"; then exit 1; fi
exit 0
