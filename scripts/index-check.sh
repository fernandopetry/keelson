#!/usr/bin/env bash
# index-check.sh — checagem mecânica do INDEX.md de um slug (decisão 4.151).
# Contrato do INDEX (template, tabela PLANs, receita): docs/_meta/conventions/index-contract.md.
#
# Uso: index-check.sh <dir-do-slug>       # {docsRoot}/<slug>, já resolvido pelo chamador
#
# Saída: SEVERIDADE<TAB>check<TAB>detalhe (formato do graph.sh), ordenada (LC_ALL=C).
# Checks (catálogo sem ERROR — o INDEX é derivado; divergência se corrige regenerando):
#   index-ausente          WARNING  INDEX.md não existe mas o slug tem SPECs/PLANs
#   index-secao-ausente    WARNING  seção nuclear do template ausente
#   index-spec-fantasma    WARNING  linha da tabela SPECs sem arquivo correspondente
#   index-spec-fora        WARNING  arquivo de SPEC fora da tabela SPECs
#   index-plan-fantasma    WARNING  linha da tabela PLANs sem arquivo correspondente
#   index-plan-fora        WARNING  arquivo de PLAN fora da tabela PLANs
#   index-tasks-cell       WARNING  célula Tasks (X/Y M) diverge do computado das TASKs
#   index-status-verbatim  WARNING  coluna Status ≠ Status do PLAN (exceção: "Done (sugerido)")
#   index-capacidade-adiantada WARNING  capacidade em "Implementadas" com TASKs abertas
#   index-historico-teto   INFO     "Histórico recente" com mais de 10 entradas
# Exit: 0 normal · 2 uso incorreto.
#
# Princípios (irmãos do graph.sh/map-check.sh, 4.82/4.104): read-only; bash 3.2 +
# awk POSIX, sem dependências novas; na dúvida degrada em silêncio — falso-positivo
# num INDEX legítimo é o pior defeito desta camada.

set -u
LC_ALL=C
export LC_ALL

dir="${1:-}"
if [ -z "$dir" ]; then
  echo "uso: index-check.sh <dir-do-slug>" >&2
  exit 2
fi
if [ ! -d "$dir" ]; then
  echo "index-check: diretório não encontrado: $dir" >&2
  exit 2
fi

TMP="$(mktemp -d)" || { echo "index-check: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

idx="$dir/INDEX.md"
if [ ! -f "$idx" ]; then
  have=0
  for f in "$dir"/specs/SPEC-*.md "$dir"/plans/PLAN-*.md; do
    [ -f "$f" ] && { have=1; break; }
  done
  if [ "$have" = 1 ]; then
    printf 'WARNING\tindex-ausente\t%s sem INDEX.md apesar de ter artefatos SDD (rode /keelson:rebuild-index)\n' "$dir"
  fi
  exit 0
fi

# ---- fatos do filesystem (TSV intermediário) ----
FACTS="$TMP/facts.tsv"
: > "$FACTS"

for f in "$dir"/specs/SPEC-*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  n="$(printf '%s\n' "$b" | sed -n 's/^SPEC-\([0-9][0-9]*\)[-.].*/\1/p')"
  [ -n "$n" ] || continue
  printf 'specfile\t%s\n' "$n" >> "$FACTS"
done

for f in "$dir"/plans/PLAN-*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  n="$(printf '%s\n' "$b" | sed -n 's/^PLAN-\([0-9][0-9]*\)[-.].*/\1/p')"
  [ -n "$n" ] || continue
  st="$(sed -n 's/^\*\*Status\*\*[ 	]*:[ 	]*//p' "$f" | sed -n 1p | sed 's/[ 	]*$//')"
  printf 'planfile\t%s\t%s\n' "$n" "$st" >> "$FACTS"
done

for f in "$dir"/tasks/TASK-*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  case "$b" in *-INDEX.md) continue ;; esac
  pair="$(printf '%s\n' "$b" | sed -n 's/^TASK-\([0-9][0-9]*\)-[0-9][0-9]*[-.].*/\1/p')"
  [ -n "$pair" ] || continue
  st="$(sed -n 's/^\*\*Status\*\*[ 	]*:[ 	]*//p' "$f" | sed -n 1p | sed 's/[ 	]*$//')"
  printf 'taskfile\t%s\t%s\n' "$pair" "$st" >> "$FACTS"
done

# ---- INDEX (awk extrai) + fatos → achados ----
awk '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  function cell(line, i,   n, c) { n = split(line, c, "|"); if (i + 1 > n) return ""; return trim(c[i + 1]) }
  function finding(sev, chk, det) { print sev "\t" chk "\t" det }
  function mnum(id,   x) { x = id; sub(/^[A-Z]+-/, "", x); return x + 0 }

  # ---------- fase 1: fatos do filesystem ----------
  FNR == NR && $1 == "specfile" { fspec[$2 + 0] = $2; next }
  FNR == NR && $1 == "planfile" { fplan[$2 + 0] = $2; fplanst[$2 + 0] = $3; next }
  FNR == NR && $1 == "taskfile" {
    ttot[$2 + 0]++
    if ($3 == "Done") tdone[$2 + 0]++
    next
  }
  FNR == NR { next }

  # ---------- fase 2: INDEX.md ----------
  /^## /  { sec = trim(substr($0, 4)); subsec = ""; seen[sec] = 1; next }
  /^### / { subsec = trim(substr($0, 5)); next }

  sec == "SPECs" && /^\|/ {
    id = cell($0, 1)
    if (id ~ /^SPEC-[0-9]+$/) { ispec_n++; ispec[ispec_n] = id }
    next
  }
  sec == "PLANs" && /^\|/ {
    id = cell($0, 1)
    if (id !~ /^PLAN-[0-9]+$/) next
    iplan_n++
    iplan[iplan_n] = id
    iplan_cell[iplan_n] = cell($0, 4)
    iplan_st[iplan_n] = cell($0, 5)
    next
  }
  sec == "Capacidades" && subsec == "Implementadas" && /^- / {
    line = $0
    while (match(line, /PLAN-[0-9]+/)) {
      cap_n++; cap_p[cap_n] = substr(line, RSTART, RLENGTH); cap_l[cap_n] = FNR
      line = substr(line, RSTART + RLENGTH)
    }
    next
  }
  sec == "Historico recente" || sec ~ /^Hist/ {
    if ($0 ~ /^- /) hist++
    next
  }

  END {
    # seções nucleares do template (index-contract)
    core_n = split("Resumo Capacidades SPECs PLANs", core, " ")
    for (i = 1; i <= core_n; i++)
      if (!(core[i] in seen))
        finding("WARNING", "index-secao-ausente", "secao \"## " core[i] "\" ausente do INDEX (template no index-contract.md)")
    histseen = 0
    for (s in seen) if (s ~ /^Hist/) histseen = 1
    if (!histseen)
      finding("WARNING", "index-secao-ausente", "secao \"## Historico recente\" ausente do INDEX (template no index-contract.md)")

    # SPECs: tabela vs arquivos, nos dois sentidos
    for (i = 1; i <= ispec_n; i++) {
      m = mnum(ispec[i])
      if (!(m in fspec))
        finding("WARNING", "index-spec-fantasma", ispec[i] " listada na tabela SPECs sem arquivo specs/SPEC-" sprintf("%03d", m) "-*.md")
      ispec_seen[m] = 1
    }
    for (m in fspec)
      if (!(m in ispec_seen))
        finding("WARNING", "index-spec-fora", "SPEC-" fspec[m] " existe em specs/ e nao esta na tabela SPECs")

    # PLANs: tabela vs arquivos + celula Tasks + Status verbatim
    for (i = 1; i <= iplan_n; i++) {
      m = mnum(iplan[i])
      iplan_seen[m] = 1
      if (!(m in fplan)) {
        finding("WARNING", "index-plan-fantasma", iplan[i] " listado na tabela PLANs sem arquivo plans/PLAN-" sprintf("%03d", m) "-*.md")
        continue
      }
      # celula Tasks: computado X/Y M das TASKs reais (progressao do contrato)
      x = (m in tdone) ? tdone[m] : 0
      y = (m in ttot)  ? ttot[m]  : 0
      if (y == 0) want = "0/? \342\217\270"
      else if (x == 0) want = "0/" y " \342\217\270"
      else if (x < y)  want = x "/" y " \360\237\237\241"
      else             want = x "/" y " \342\234\205"
      gotc = iplan_cell[i]
      gsub(/\357\270\217/, "", gotc)   # seletor de variacao de emoji (U+FE0F) e ruido
      gsub(/[ \t]+/, " ", gotc); gotc = trim(gotc)
      if (gotc != "" && gotc != want)
        finding("WARNING", "index-tasks-cell", iplan[i] ": celula Tasks \"" gotc "\" difere do computado \"" want "\" (" x " Done de " y ")")
      # Status: verbatim do PLAN, unica excecao "Done (sugerido)" (index-contract)
      fst = fplanst[m]
      if (fst != "" && iplan_st[i] != "" && iplan_st[i] != fst && iplan_st[i] != "Done (sugerido)")
        finding("WARNING", "index-status-verbatim", iplan[i] ": coluna Status \"" iplan_st[i] "\" difere do Status do arquivo \"" fst "\"")
    }
    for (m in fplan)
      if (!(m in iplan_seen))
        finding("WARNING", "index-plan-fora", "PLAN-" fplan[m] " existe em plans/ e nao esta na tabela PLANs")

    # capacidade em Implementadas com TASKs abertas (so quando ha TASKs conhecidas)
    for (i = 1; i <= cap_n; i++) {
      m = mnum(cap_p[i])
      x = (m in tdone) ? tdone[m] : 0
      y = (m in ttot)  ? ttot[m]  : 0
      if (y > 0 && x < y)
        finding("WARNING", "index-capacidade-adiantada", "linha " cap_l[i] ": capacidade em \"Implementadas\" cita " cap_p[i] " com " x "/" y " TASKs Done")
    }

    if (hist > 10)
      finding("INFO", "index-historico-teto", "\"Historico recente\" com " hist " entradas (teto 10 - index-contract.md)")
  }
' "$FACTS" "$idx" | sort

exit 0
