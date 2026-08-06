#!/usr/bin/env bash
# next-id.sh — alocador mecânico de número de artefato SDD (decisões 4.86/4.151).
#
# Uso: next-id.sh <dir-do-slug> alloc
#      next-id.sh <dir-do-slug> task <MMM>
#      next-id.sh <dir-do-slug> --check
#
#   alloc        próximo número do ALOCADOR ÚNICO do slug (index-contract.md, 4.86):
#                max(todos os NNN/MMM já usados em specs/, plans/, briefs/ numerados
#                e tasks/) + 1, zero-padded em 3 dígitos. Vale para SPEC (com o BRIEF
#                pareado), PLAN e brief avulso — densidade por tipo não é contrato.
#   task <MMM>   próximo XXX de TASK-MMM-XXX (max XXX existente do MMM + 1, 3 dígitos)
#   --check      confere o pareamento brief ↔ SPEC (4.86): SPEC cujo cabeçalho declara
#                **Brief**: BRIEF-KKK com KKK ≠ NNN da própria SPEC, ou apontando
#                BRIEF sem arquivo. Saída: SEVERIDADE<TAB>check<TAB>detalhe (formato
#                do graph.sh); catálogo só tem WARNING — nunca reprova.
#
# Regras herdadas do contrato: buraco de numeração NÃO é defeito e nunca se preenche
# (max+1, jamais o menor livre — graph-contract §4.1); arquivo existente nunca se
# renumera. BRIEF épico (`BRIEF-<yyyy-mm-dd>-*-epic.md`, id por data) fica fora da
# numeração. Read-only. Exit: 0 ok · 2 uso incorreto.
#
# Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; }

DIR="${1:-}"
[ -n "$DIR" ] || { usage >&2; exit 2; }
case "$DIR" in -h|--help) usage; exit 0 ;; esac
[ -d "$DIR" ] || die2 "diretório não existe: $DIR"
shift

ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

# número imediatamente após "PREFIX-" no basename; descarta épico datado e não-numérico
numof() { # $1 = basename, $2 = prefixo (SPEC|PLAN|TASK|BRIEF)
  b="$1"; p="$2"
  case "$b" in
    "$p"-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*) return 1 ;; # id por data (épico)
    *-epic.md) return 1 ;;
  esac
  n="$(printf '%s\n' "$b" | sed -n "s/^$p-\([0-9][0-9]*\)[-.].*/\1/p")"
  [ -n "$n" ] || return 1
  printf '%s\n' "$n"
}

maxnum=0
scan() { # $1 = glob-dir, $2 = prefixo
  for f in "$1"/"$2"-*.md; do
    [ -f "$f" ] || continue
    n="$(numof "$(basename "$f")" "$2")" || continue
    n=$((10#0$n))
    [ "$n" -gt "$maxnum" ] && maxnum=$n
  done
  return 0
}

case "$ACTION" in
  alloc)
    [ $# -eq 0 ] || die2 "alloc não recebe argumentos extras."
    scan "$DIR/specs" SPEC
    scan "$DIR/plans" PLAN
    scan "$DIR/briefs" BRIEF
    scan "$DIR/tasks" TASK
    printf '%03d\n' $((maxnum + 1))
    exit 0 ;;

  task)
    MMM="${1:-}"
    [ -n "$MMM" ] || die2 "task exige o MMM da âncora (ex.: 001)."
    case "$MMM" in *[!0-9]*|'') die2 "MMM deve ser numérico (ex.: 001)." ;; esac
    mval=$((10#0$MMM))
    maxx=0
    for f in "$DIR"/tasks/TASK-*.md; do
      [ -f "$f" ] || continue
      b="$(basename "$f")"
      case "$b" in *-INDEX.md) continue ;; esac
      pair="$(printf '%s\n' "$b" | sed -n 's/^TASK-\([0-9][0-9]*\)-\([0-9][0-9]*\)[-.].*/\1 \2/p')"
      [ -n "$pair" ] || continue
      fm="${pair%% *}"; fx="${pair##* }"
      [ $((10#0$fm)) -eq "$mval" ] || continue
      fx=$((10#0$fx))
      [ "$fx" -gt "$maxx" ] && maxx=$fx
    done
    printf '%03d\n' $((maxx + 1))
    exit 0 ;;

  --check)
    [ $# -eq 0 ] || die2 "--check não recebe argumentos extras."
    for f in "$DIR"/specs/SPEC-*.md; do
      [ -f "$f" ] || continue
      b="$(basename "$f")"
      nnn="$(numof "$b" SPEC)" || continue
      # cabeçalho markdown (nunca YAML — sdd-conventions): **Brief**: BRIEF-KKK
      kkk="$(sed -n 's/^\*\*Brief\*\*[ 	]*:[ 	]*BRIEF-\([0-9][0-9]*\).*/\1/p' "$f" | sed -n 1p)"
      [ -n "$kkk" ] || continue
      if [ $((10#0$kkk)) -ne $((10#0$nnn)) ]; then
        printf 'WARNING\tspec-brief-divergente\t%s declara Brief BRIEF-%s (pareamento 1:1 esperava BRIEF-%s — 4.86)\n' "$b" "$kkk" "$nnn"
        continue
      fi
      found=0
      for bf in "$DIR"/briefs/BRIEF-"$kkk"*.md; do
        [ -f "$bf" ] && { found=1; break; }
      done
      if [ "$found" -eq 0 ]; then
        printf 'WARNING\tspec-brief-orfao\t%s declara Brief BRIEF-%s mas briefs/BRIEF-%s*.md nao existe\n' "$b" "$kkk" "$kkk"
      fi
    done
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use alloc, task <MMM> ou --check)" ;;
esac
