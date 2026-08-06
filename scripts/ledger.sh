#!/usr/bin/env bash
# ledger.sh — mecânica do ledger de sessão (decisões 4.76/4.151).
# Formato, catálogo de tipos e ciclo de vida: docs/_meta/conventions/sdd-conventions.md
# ("Ledger de sessão"). Este script cuida da parte mecânica (nome ordenável, timestamp
# medido, arquivamento seletivo); O QUE anotar e QUANDO continua sendo da doutrina.
#
# Uso: ledger.sh <raiz-do-repo> append <tipo> <origem> <slug> [--ref <caminho>] [--ts <iso>]
#      ledger.sh <raiz-do-repo> list [--archived]
#      ledger.sh <raiz-do-repo> count
#      ledger.sh <raiz-do-repo> archive [--keep <arquivo>]… [--ts <iso>]
#
#   append   cria thoughts/local/session-ledger/<yyyymmdd-hhmmss>-<tipo>-<origem>.md
#            com o cabeçalho canônico; o corpo (2–3 linhas) entra pelo stdin.
#            Tipos (catálogo FECHADO): gate decisao fora_de_escopo pendencia tracker marco.
#            Timestamp medido (TZ=America/Sao_Paulo); --ts <iso> só para testes.
#            Colisão de segundo ganha sufixo -2, -3… Ecoa o caminho criado.
#   list     eventos ativos (um por linha, ordenados); --archived lista os consumidos
#   count    contagem de eventos ativos por tipo
#   archive  move os ativos para reported-<yyyymmdd-hhmmss>/, preservando os --keep
#            (evento que continua pendente permanece na pasta ativa)
#
# Exit: 0 ok · 2 uso incorreto. Nunca é gate: ledger vazio não é erro.
# Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

LDIR="$ROOT/thoughts/local/session-ledger"

stamp() { # $1 = iso opcional; ecoa "yyyymmdd-hhmmss<TAB>iso"
  iso="$1"
  if [ -z "$iso" ]; then
    iso="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z)"
  fi
  compact="$(printf '%s\n' "$iso" | sed 's/[-:]//g; s/T/-/; s/+.*$//; s/\([0-9]\{8\}-[0-9]\{6\}\).*/\1/')"
  case "$compact" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) die2 "timestamp ilegível: $iso" ;;
  esac
  printf '%s\t%s\n' "$compact" "$iso"
}

case "$ACTION" in
  append)
    TIPO="${1:-}"; ORIGEM="${2:-}"; SLUG="${3:-}"
    [ -n "$TIPO" ] && [ -n "$ORIGEM" ] && [ -n "$SLUG" ] || die2 "append exige <tipo> <origem> <slug>."
    shift 3
    case "$TIPO" in
      gate|decisao|fora_de_escopo|pendencia|tracker|marco) ;;
      *) die2 "tipo fora do catálogo fechado (4.76): $TIPO — use gate, decisao, fora_de_escopo, pendencia, tracker ou marco" ;;
    esac
    case "$ORIGEM" in */*|*" "*) die2 "origem inválida (sem espaço/barra): $ORIGEM" ;; esac
    REF=""; TS=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --ref) shift; [ $# -gt 0 ] || die2 "--ref exige um caminho."; REF="$1" ;;
        --ts)  shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$1" ;;
        *) die2 "opção desconhecida: $1" ;;
      esac
      shift
    done
    pair="$(stamp "$TS")" || exit 2
    compact="${pair%%	*}"; iso="${pair##*	}"
    mkdir -p "$LDIR" || die2 "não consegui criar $LDIR"
    base="$LDIR/$compact-$TIPO-$ORIGEM"
    f="$base.md"; n=1
    while [ -e "$f" ]; do
      n=$((n + 1))
      f="$base-$n.md"
    done
    corpo="$(cat)"
    {
      printf 'ts: %s · tipo: %s · origem: %s · slug: %s\n' "$iso" "$TIPO" "$ORIGEM" "$SLUG"
      if [ -n "$corpo" ]; then printf '%s\n' "$corpo"; fi
      if [ -n "$REF" ]; then printf 'ref: %s\n' "$REF"; fi
    } > "$f" || die2 "não consegui escrever $f"
    printf '%s\n' "$f"
    exit 0 ;;

  list)
    MODE="active"
    [ "${1:-}" = "--archived" ] && MODE="archived"
    if [ "$MODE" = "active" ]; then
      for f in "$LDIR"/*.md; do
        [ -f "$f" ] && printf '%s\n' "$f"
      done | sort
    else
      for f in "$LDIR"/reported-*/*.md; do
        [ -f "$f" ] && printf '%s\n' "$f"
      done | sort
    fi
    exit 0 ;;

  count)
    for f in "$LDIR"/*.md; do
      [ -f "$f" ] || continue
      printf '%s\n' "$(basename "$f")"
    done | sed -n 's/^[0-9]\{8\}-[0-9]\{6\}-\([a-z_]*\)-.*/\1/p' | sort | uniq -c | awk '{ print $2 "\t" $1 }'
    exit 0 ;;

  archive)
    TS=""
    KEEPLIST=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --keep) shift; [ $# -gt 0 ] || die2 "--keep exige o nome do arquivo."; KEEPLIST="$KEEPLIST $(basename "$1")" ;;
        --ts)   shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$1" ;;
        *) die2 "opção desconhecida: $1" ;;
      esac
      shift
    done
    have=0
    for f in "$LDIR"/*.md; do
      [ -f "$f" ] && { have=1; break; }
    done
    if [ "$have" = 0 ]; then
      echo "ledger: nada a arquivar."
      exit 0
    fi
    pair="$(stamp "$TS")" || exit 2
    compact="${pair%%	*}"
    dest="$LDIR/reported-$compact"
    mkdir -p "$dest" || die2 "não consegui criar $dest"
    moved=0; kept=0
    for f in "$LDIR"/*.md; do
      [ -f "$f" ] || continue
      b="$(basename "$f")"
      keep=0
      for k in $KEEPLIST; do
        [ "$b" = "$k" ] && { keep=1; break; }
      done
      if [ "$keep" = 1 ]; then
        kept=$((kept + 1))
      else
        mv "$f" "$dest/" || die2 "não consegui mover $b"
        moved=$((moved + 1))
      fi
    done
    printf 'ledger: %d evento(s) arquivado(s) em %s · %d pendente(s) preservado(s)\n' "$moved" "$dest" "$kept"
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use append, list, count ou archive)" ;;
esac
