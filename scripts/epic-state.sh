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
#   aviso<TAB><n><TAB><detalhe>            (estado fora do vocabulário — degradação 4.156 —
#                                           ou fatia em ciclo sem brief filho resolvível, 4.170)
#   regra<TAB><1..6 | -><TAB><rótulo da tabela do continue>
# Verificado: aguardando-produto · parcial · pre-task · entregue · - (não verificável).
# Colunas da fila mapeadas PELO HEADER da tabela (4.156): além do contrato canônico
# (| # | Fatia | Slug de destino | Estado |), aceita o formato de campo
# (| # | Fatia | Estado | Âncora |) — negrito/backtick no estado é removido e o
# caminho do brief filho pode vir da coluna Âncora. Estado fora do vocabulário
# fechado (pendente · em ciclo · entregue · aguardando-produto) degrada com `aviso`
# e nunca elege fatia por conta (regra `-` quando não sobra fato parseável).
# Exit: 0 ok · 2 uso incorreto. Read-only; bash 3.2 + awk POSIX.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; }

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

# ---- fila: colunas mapeadas pelo header (4.156) ----
# Canônico: | # | Fatia | Slug de destino | Estado | (index-contract.md).
# Legado de campo: | # | Fatia | Estado | Âncora | — sem coluna de slug, caminho
# do brief filho na Âncora. Sem header reconhecível, vale o default canônico.
TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT
awk '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  BEGIN { slugcol = 4; estcol = 5; anccol = 0 }
  /^## Fila/ { on = 1; next }
  /^## /     { on = 0 }
  on && /^\|/ {
    n = split($0, c, "|")
    if (n < 4) next
    num = trim(c[2])
    if (num == "#") {                       # header: mapeia as colunas pelo nome
      slugcol = 0; estcol = 0; anccol = 0
      for (i = 3; i < n; i++) {
        col = tolower(trim(c[i]))
        if (col ~ /slug/)   slugcol = i
        if (col ~ /estado/) estcol = i
        if (col ~ /ncora/)  anccol = i      # "Âncora" — casa pelo sufixo ASCII
      }
      if (estcol == 0) estcol = 5           # header sem "Estado" → default canônico
      next
    }
    if (num !~ /^[0-9]+$/) next
    if (n <= estcol) next
    slug = (slugcol > 0 ? trim(c[slugcol]) : "-")
    est = trim(c[estcol])
    gsub(/[*`]/, "", est); est = trim(est)  # **entregue** (…) → entregue (…)
    anc = (anccol > 0 && n > anccol ? trim(c[anccol]) : "")
    gsub(/`/, "", anc)
    printf "%s\t%s\t%s\t%s\n", num, slug, est, anc
  }
' "$BRIEF" > "$TMP/fila.tsv"
[ -s "$TMP/fila.tsv" ] || die2 "BRIEF sem seção '## Fila' parseável (contrato: index-contract.md, variação épico)."
EPICDIR="$(cd "$(dirname "$BRIEF")/.." && pwd)"   # slug-âncora: resolve caminho relativo da Âncora legada

# verificação de uma fatia "em ciclo": estado real pelos artefatos do filho
verifica() { # $1 = estado declarado (parênteses podem ter o caminho) $2 = âncora (formato legado)
  path="$(printf '%s' "$1" | sed -n 's/.*(\(.*\)).*/\1/p')"
  case "$path" in
    *.md) ;;                                 # caminho plausível
    *) path="" ;;                            # ex.: data "(2026-08-09)" no formato legado
  esac
  if [ -z "$path" ] && [ -n "${2:-}" ]; then
    path="$(printf '%s\n' "$2" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /\.md$/) { print $i; exit } }')"
  fi
  child=""
  if [ -n "$path" ]; then
    if   [ -f "$path" ]; then child="$path"
    elif [ -f "$DOCSROOT/../$path" ]; then child="$DOCSROOT/../$path"
    elif [ -f "$EPICDIR/$path" ]; then child="$EPICDIR/$path"
    fi
  fi
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
  # o header de campo carrega decoração ('SPEC-008 (a criar na Etapa 1)') ou caminho
  # (4.124) — o vínculo BRIEF→PLAN casa pelo ID, nunca pela string crua (4.170)
  specid="$(printf '%s\n' "$spec" | sed -n 's/.*\(SPEC-[0-9][0-9]*\).*/\1/p')"
  if [ -z "$specid" ] || [ ! -d "$sdir/plans" ]; then
    printf 'pre-task\n'
    return
  fi
  mmms="$(grep -El "^\\*\\*SPEC referenciada\\*\\*[[:space:]]*:.*${specid}([^0-9]|\$)" "$sdir"/plans/PLAN-*.md 2>/dev/null \
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
nao_parseavel=0
prox_estado=""; prox_n=""
while IFS='	' read -r n slug estado ancora; do
  case "$estado" in
    "em ciclo"*)
      all_entregue=0
      v="$(verifica "$estado" "$ancora")"
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "$v"
      case "$v" in
        aguardando-produto)
          printf 'divergencia\t%s\t%s vs %s\n' "$n" "$estado" "$v"
          [ -n "$regra" ] || { regra=1; regra_det="fatia $n: forja aguardando produto — retomar /keelson:brief $slug"; } ;;
        entregue)
          printf 'divergencia\t%s\t%s vs %s\n' "$n" "$estado" "$v"
          [ -n "$regra" ] || { regra=3; regra_det="fatia $n: tudo entregue nos artefatos — corrigir a fila declarando e propor a proxima"; } ;;
        sem-artefatos)
          # em ciclo declarado sem brief filho resolvível: a resolução falhou ou a
          # âncora está ausente — degradação visível, nunca rota eleita em silêncio (4.170)
          printf 'aviso\t%s\tfatia em ciclo sem brief filho resolvivel — ancora ausente ou caminho errado; derive por leitura\n' "$n"
          [ -n "$regra" ] || { regra=2; regra_det="fatia $n: retomar a implementacao onde parou (sem-artefatos — confirme por leitura)"; } ;;
        *)
          [ -n "$regra" ] || { regra=2; regra_det="fatia $n: retomar a implementacao onde parou ($v)"; } ;;
      esac ;;
    entregue*)
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "entregue" ;;
    pendente*|aguardando-produto*)
      all_entregue=0
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "-"
      if [ -z "$prox_estado" ]; then prox_estado="$estado"; prox_n="$n"; fi ;;
    *)
      # vocabulário desconhecido → degradar, nunca eleger fatia por conta (4.156)
      all_entregue=0
      nao_parseavel=1
      printf 'fatia\t%s\t%s\t%s\t%s\n' "$n" "$slug" "$estado" "-"
      printf 'aviso\t%s\testado nao-parseavel: "%s" — fila fora do contrato (index-contract.md); derive dos artefatos\n' "$n" "$estado" ;;
  esac
done < "$TMP/fila.tsv"

if [ -z "$regra" ]; then
  if [ "$all_entregue" = 1 ]; then
    regra=6; regra_det="fila toda entregue — apontar /keelson:integrate (PR do epico, ato do Diretor)"
  elif [ -n "$prox_estado" ]; then
    case "$prox_estado" in
      aguardando-produto*)
        regra=5; regra_det="proxima fatia aguardando produto ($prox_n) — mostrar a pendencia; fatia posterior nao bloqueada pode ser proposta (julgamento do comando)" ;;
      *)
        regra=4; regra_det="proxima fatia pendente ($prox_n) — propor /keelson:auto com o epico no titulo (sync de largada 4.126)" ;;
    esac
  elif [ "$nao_parseavel" = 1 ]; then
    regra='-'; regra_det="fila com estado nao-parseavel e nenhum fato restante — derive dos artefatos e corrija a fila declarando"
  else
    regra=6; regra_det="fila toda entregue — apontar /keelson:integrate (PR do epico, ato do Diretor)"
  fi
fi
printf 'regra\t%s\t%s\n' "$regra" "$regra_det"
exit 0
