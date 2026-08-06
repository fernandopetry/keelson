#!/usr/bin/env bash
# epic-state.sh — deriva o estado da fila de um BRIEF épico (decisão 4.154).
# Implementa a parte MECÂNICA da Etapa 1 do /keelson:continue (autodeclarada
# "determinístico — primeira regra que casa vence"): lê a fila do BRIEF pai
# (contrato: index-contract.md, variação épico), verifica cada fatia contra os
# artefatos filhos e aponta a primeira regra da tabela que casa. A prosa do
# "você está aqui", a proposta ao Diretor e o julgamento de dependência entre
# fatias continuam do comando.
#
# Uso: epic-state.sh <caminho-do-BRIEF-epico> [--docs-root <dir>]
#
#   <caminho>    briefs/BRIEF-*-epic.md (o chamador resolve qual épico — Etapa 0;
#                working tree já no checkout certo: estado vive na branch, 4.126)
#   --docs-root  raiz dos slugs (default: <dir-do-brief>/../..; fatias apontam
#                slugs de destino relativos a ela)
#
# Saída (TSV):
#   epico<TAB>status<TAB>branch<TAB>estrategia
#   fatia<TAB><n>-<TAB><slug><TAB><declarado><TAB><verificado>
#   divergencia<TAB><n><TAB><declarado> vs <verificado>
#   regra<TAB><1..6><TAB><rótulo da tabela do continue>
# Verificado: aguardando-produto · parcial · pre-task · entregue · - (não verificável).
# Exit: 0 ok · 2 uso incorreto. Read-only; bash 3.2 + awk POSIX.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; }

BRIEF=""
DOCSROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --docs-root) shift; [ $# -gt 0 ] || die2 "--docs-root exige um diretório."; DOCSROOT="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1" ;;
    *) [ -z "$BRIEF" ] || die2 "apenas um BRIEF por vez."; BRIEF="$1" ;;
  esac
  shift
done
[ -n "$BRIEF" ] || { usage >&2; exit 2; }
[ -f "$BRIEF" ] || die2 "BRIEF não existe: $BRIEF"
if [ -z "$DOCSROOT" ]; then
  DOCSROOT="$(cd "$(dirname "$BRIEF")/../.." && pwd)" || die2 "não resolvi --docs-root"
fi
[ -d "$DOCSROOT" ] || die2 "docs-root não existe: $DOCSROOT"

hdr() { sed -n "s/^\*\*$1\*\*[ 	]*:[ 	]*//p" "$2" | sed -n 1p | sed 's/[ 	]*$//'; }

E_STATUS="$(hdr Status "$BRIEF")"
E_BRANCH="$(hdr Branch "$BRIEF")"
E_ESTR="$(hdr 'Estrat[^*]*' "$BRIEF")"
printf 'epico\t%s\t%s\t%s\n' "${E_STATUS:--}" "${E_BRANCH:--}" "${E_ESTR:--}"

# ---- fila: | # | Fatia | Slug de destino | Estado | ----
TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT
awk '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  /^## Fila/ { on = 1; next }
  /^## /     { on = 0 }
  on && /^\|/ {
    n = split($0, c, "|")
    if (n < 5) next
    num = trim(c[2])
    if (num !~ /^[0-9]+$/) next
    printf "%s\t%s\t%s\n", num, trim(c[4]), trim(c[5])
  }
' "$BRIEF" > "$TMP/fila.tsv"
[ -s "$TMP/fila.tsv" ] || die2 "BRIEF sem seção '## Fila' parseável (contrato: index-contract.md, variação épico)."

# verificação de uma fatia "em ciclo": estado real pelos artefatos do filho
verifica() { # $1 = estado declarado (com o caminho do brief filho entre parênteses)
  path="$(printf '%s' "$1" | sed -n 's/.*(\(.*\)).*/\1/p')"
  child=""
  [ -n "$path" ] && { [ -f "$path" ] && child="$path" || { [ -f "$DOCSROOT/../$path" ] && child="$DOCSROOT/../$path"; }; }
  if [ -z "$child" ]; then
    printf 'sem-artefatos\n'
    return
  fi
  cst="$(hdr Status "$child")"
  case "$cst" in
    aguardando-produto*) printf 'aguardando-produto\n'; return ;;
  esac
  spec="$(hdr SPEC "$child")"
  sdir="$(cd "$(dirname "$child")/.." && pwd)"
  if [ -z "$spec" ] || [ ! -d "$sdir/plans" ]; then
    printf 'pre-task\n'
    return
  fi
  mmms="$(grep -l "^\*\*SPEC referenciada\*\*[ 	]*:[ 	]*$spec" "$sdir"/plans/PLAN-*.md 2>/dev/null \
          | sed -n 's/.*PLAN-\([0-9][0-9]*\)[-.].*/\1/p')"
  [ -n "$mmms" ] || { printf 'pre-task\n'; return; }
  tot=0; done_=0
  for m in $mmms; do
    for t in "$sdir"/tasks/TASK-"$m"-*.md; do
      [ -f "$t" ] || continue
      case "$(basename "$t")" in *-INDEX.md) continue ;; esac
      tot=$((tot + 1))
      [ "$(hdr Status "$t")" = "Done" ] && done_=$((done_ + 1))
    done
  done
  if [ "$tot" -eq 0 ]; then printf 'pre-task\n'
  elif [ "$done_" -eq "$tot" ]; then printf 'entregue\n'
  else printf 'parcial\n'; fi
}

regra=""; regra_det=""
all_entregue=1
prox_estado=""; prox_n=""
while IFS='	' read -r n slug estado; do
  case "$estado" in
    "em ciclo"*)
      all_entregue=0
      v="$(verifica "$estado")"
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "$v"
      case "$v" in
        aguardando-produto)
          printf 'divergencia\t%s\t%s vs %s\n' "$n" "$estado" "$v"
          [ -n "$regra" ] || { regra=1; regra_det="fatia $n: forja aguardando produto — retomar /keelson:brief $slug"; } ;;
        entregue)
          printf 'divergencia\t%s\t%s vs %s\n' "$n" "$estado" "$v"
          [ -n "$regra" ] || { regra=3; regra_det="fatia $n: tudo entregue nos artefatos — corrigir a fila declarando e propor a proxima"; } ;;
        *)
          [ -n "$regra" ] || { regra=2; regra_det="fatia $n: retomar a implementacao onde parou ($v)"; } ;;
      esac ;;
    entregue*)
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "entregue" ;;
    *)
      all_entregue=0
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "-"
      if [ -z "$prox_estado" ]; then prox_estado="$estado"; prox_n="$n"; fi ;;
  esac
done < "$TMP/fila.tsv"

if [ -z "$regra" ]; then
  if [ "$all_entregue" = 1 ]; then
    regra=6; regra_det="fila toda entregue — apontar /keelson:integrate (PR do epico, ato do Diretor)"
  elif [ -n "$prox_estado" ]; then
    case "$prox_estado" in
      pendente*)
        regra=4; regra_det="proxima fatia pendente ($prox_n) — propor /keelson:auto com o epico no titulo (sync de largada 4.126)" ;;
      aguardando-produto*)
        regra=5; regra_det="proxima fatia aguardando produto ($prox_n) — mostrar a pendencia; fatia posterior nao bloqueada pode ser proposta (julgamento do comando)" ;;
      *)
        regra=4; regra_det="proxima fatia nao-entregue ($prox_n: $prox_estado) — propor retomada" ;;
    esac
  else
    regra=6; regra_det="fila toda entregue — apontar /keelson:integrate (PR do epico, ato do Diretor)"
  fi
fi
printf 'regra\t%s\t%s\n' "$regra" "$regra_det"
exit 0
