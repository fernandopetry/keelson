#!/usr/bin/env bash
# run-state.sh — escritor canônico do estado de run de waves (decisão 4.151).
# Formato e ciclo de vida: docs/_meta/conventions/sdd-conventions.md ("Estado de run");
# o leitor é o hook wave-guard (Stop), que bloqueia encerramento com status em_andamento.
# Este script garante que as chaves canônicas nunca nasçam erradas de memória.
#
# Uso: run-state.sh <raiz-do-repo> init <slug> <PLAN-MMM> <waves_total> <retomada…>
#      run-state.sh <raiz-do-repo> wave-done <slug>
#      run-state.sh <raiz-do-repo> close <slug> <motivo…>
#      run-state.sh <raiz-do-repo> remove <slug>
#      run-state.sh <raiz-do-repo> show <slug>
#
#   init       escreve thoughts/local/run-state-<slug>.md com as chaves canônicas
#              (waves_concluidas: 0, status: em_andamento). Arquivo em_andamento
#              existente é sobrescrito com aviso em stderr (a largada é o dono).
#   wave-done  incrementa waves_concluidas (exit 2 se o arquivo não existe)
#   close      status: encerrado — <motivo> (o wave-guard deixa de bloquear)
#   remove     apaga o arquivo (idempotente)
#   show       imprime o arquivo (nada se ausente)
#
# Exit: 0 ok · 2 uso incorreto/arquivo ausente onde obrigatório.
# Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift
SLUG="${1:-}"
[ -n "$SLUG" ] || die2 "toda ação exige o <slug>."
shift
case "$SLUG" in */*|*" "*) die2 "slug inválido: $SLUG" ;; esac

DIR="$ROOT/thoughts/local"
F="$DIR/run-state-$SLUG.md"

case "$ACTION" in
  init)
    PLAN="${1:-}"; TOTAL="${2:-}"
    [ -n "$PLAN" ] && [ -n "$TOTAL" ] || die2 "init exige <PLAN-MMM> e <waves_total>."
    case "$PLAN" in PLAN-[0-9]*) ;; *) die2 "PLAN-MMM inválido: $PLAN" ;; esac
    case "$TOTAL" in ''|*[!0-9]*) die2 "waves_total deve ser numérico: $TOTAL" ;; esac
    shift 2
    RET="${*:-}"
    [ -n "$RET" ] || die2 "init exige a linha de retomada (caminhos dos artefatos)."
    mkdir -p "$DIR" || die2 "não consegui criar $DIR"
    if [ -f "$F" ] && grep -q '^status: em_andamento' "$F" 2>/dev/null; then
      echo "run-state: aviso — sobrescrevendo run em andamento de $SLUG (largada nova é a dona)." >&2
    fi
    {
      printf 'status: em_andamento\n'
      printf 'slug: %s\n' "$SLUG"
      printf 'plan: %s\n' "$PLAN"
      printf 'waves_concluidas: 0\n'
      printf 'waves_total: %s\n' "$TOTAL"
      printf 'retomada: %s\n' "$RET"
    } > "$F" || die2 "não consegui escrever $F"
    exit 0 ;;

  wave-done)
    [ -f "$F" ] || die2 "run-state ausente: $F (init não rodou?)"
    cur="$(sed -n 's/^waves_concluidas:[ 	]*//p' "$F" | sed -n 1p)"
    case "$cur" in ''|*[!0-9]*) die2 "waves_concluidas ilegível em $F: \"$cur\"" ;; esac
    nxt=$((cur + 1))
    tmp="$F.tmp.$$"
    sed "s/^waves_concluidas:.*/waves_concluidas: $nxt/" "$F" > "$tmp" || die2 "sed falhou"
    mv "$tmp" "$F" || die2 "não consegui atualizar $F"
    printf '%s\n' "$nxt"
    exit 0 ;;

  close)
    [ -f "$F" ] || die2 "run-state ausente: $F (nada a encerrar)"
    MOT="${*:-}"
    [ -n "$MOT" ] || die2 "close exige o <motivo> (parada é ato deliberado, nunca esquecimento)."
    tmp="$F.tmp.$$"
    sed "s/^status:.*/status: encerrado — $(printf '%s' "$MOT" | sed 's/[&/\\]/ /g')/" "$F" > "$tmp" || die2 "sed falhou"
    mv "$tmp" "$F" || die2 "não consegui atualizar $F"
    exit 0 ;;

  remove)
    rm -f "$F"
    exit 0 ;;

  show)
    [ -f "$F" ] && cat "$F"
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use init, wave-done, close, remove ou show)" ;;
esac
