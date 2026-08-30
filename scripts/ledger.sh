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
#   append   cria <yyyymmdd-hhmmss>-<tipo>-<origem>.md no ledger da CASA DA SESSÃO
#            (decisão 4.314 — resolvida por session-dir.sh:
#            thoughts/local/sessions/<ts>-<sid8>/ledger/; sem id de sessão, o
#            caminho legado thoughts/local/session-ledger/) com o cabeçalho
#            canônico; o corpo (2–3 linhas) entra pelo stdin.
#            Tipos (catálogo FECHADO): gate decisao intervencao fora_de_escopo pendencia tracker marco.
#            Timestamp medido (TZ=America/Sao_Paulo); --ts <iso> só para testes.
#            A linha `ts:` do cabeçalho é DESTE script — linha `ts:` no início do
#            stdin é descartada (4.156: ts estimado de memória não entra no evento).
#            Colisão de segundo ganha sufixo -2, -3… Ecoa o caminho criado.
#   list     eventos ativos (um por linha, ordenados); --archived lista os consumidos
#   count    contagem de eventos ativos por tipo
#   archive  move os ativos para reported-<yyyymmdd-hhmmss>/, preservando os --keep
#            (evento que continua pendente permanece na pasta ativa)
#
# Leitura dupla (carência 4.314): list/count/archive agregam a casa da sessão E a
# legada quando distintas (legado primeiro — é o trecho mais antigo da sessão que
# atravessou o update); archive arquiva cada casa dentro de si mesma, nunca mistura.
#
# Exit: 0 ok · 2 uso incorreto. Nunca é gate: ledger vazio não é erro.
# Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

# Casa da sessão (4.314): session-dir.sh é o dono da resolução; ausente ou
# falhando, degrada para o caminho legado. LDIRS lista as casas de leitura
# (legado primeiro quando as duas existem como conceitos distintos).
SDS="$(cd "$(dirname "$0")" && pwd)/session-dir.sh"
LDIR_LEG="$ROOT/thoughts/local/session-ledger"
LDIR="$LDIR_LEG"
if [ -f "$SDS" ]; then
  d="$(bash "$SDS" "$ROOT" ledger-dir 2>/dev/null)" || d=""
  [ -n "$d" ] && LDIR="$d"
fi
# em_cada_casa <fn>: aplica fn ao legado e (quando distinta) à casa da sessão —
# roda no shell corrente, então fn pode acumular em variáveis globais
em_cada_casa() {
  "$1" "$LDIR_LEG"
  [ "$LDIR" != "$LDIR_LEG" ] && "$1" "$LDIR"
  return 0
}

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
      gate|decisao|intervencao|fora_de_escopo|pendencia|tracker|marco) ;;
      *) die2 "tipo fora do catálogo fechado (4.76/4.244): $TIPO — use gate, decisao, intervencao, fora_de_escopo, pendencia, tracker ou marco" ;;
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
    # escrita é sempre na casa resolvida com --create (registra o slug no meta)
    if [ -f "$SDS" ]; then
      d="$(bash "$SDS" "$ROOT" ledger-dir --create --slug "$SLUG" ${TS:+--ts "$TS"} 2>/dev/null)" || d=""
      [ -n "$d" ] && LDIR="$d"
    fi
    mkdir -p "$LDIR" || die2 "não consegui criar $LDIR"
    base="$LDIR/$compact-$TIPO-$ORIGEM"
    f="$base.md"; n=1
    while [ -e "$f" ]; do
      n=$((n + 1))
      f="$base-$n.md"
    done
    corpo="$(cat)"
    # cabeçalho é do script: linha ts: duplicada no stdin (formato pré-4.151) sai
    case "$corpo" in
      "ts: "*|"ts:"*) corpo="$(printf '%s\n' "$corpo" | sed 1d)" ;;
    esac
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
    # shellcheck disable=SC2329,SC2317  # invocada indiretamente via em_cada_casa (SC2317: shellcheck novo re-acusa o corpo)
    list_casa() {
      if [ "$MODE" = "active" ]; then
        for f in "$1"/*.md; do
          [ -f "$f" ] && printf '%s\n' "$f"
        done | sort
      else
        for f in "$1"/reported-*/*.md; do
          [ -f "$f" ] && printf '%s\n' "$f"
        done | sort
      fi
      return 0
    }
    em_cada_casa list_casa
    exit 0 ;;

  count)
    # shellcheck disable=SC2329,SC2317  # invocada indiretamente via em_cada_casa (SC2317: shellcheck novo re-acusa o corpo)
    count_casa() {
      for f in "$1"/*.md; do
        [ -f "$f" ] || continue
        printf '%s\n' "$(basename "$f")"
      done
      return 0
    }
    em_cada_casa count_casa | sed -n 's/^[0-9]\{8\}-[0-9]\{6\}-\([a-z_]*\)-.*/\1/p' | sort | uniq -c | awk '{ print $2 "\t" $1 }'
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
    # shellcheck disable=SC2329,SC2317  # invocada indiretamente via em_cada_casa (SC2317: shellcheck novo re-acusa o corpo)
    have_casa() {
      for f in "$1"/*.md; do
        [ -f "$f" ] && { have=1; break; }
      done
      return 0
    }
    em_cada_casa have_casa
    if [ "$have" = 0 ]; then
      echo "ledger: nada a arquivar."
      exit 0
    fi
    pair="$(stamp "$TS")" || exit 2
    compact="${pair%%	*}"
    # cada casa arquiva DENTRO DE SI (4.314 — nunca mistura); casa sem ativo fica muda
    # shellcheck disable=SC2329,SC2317  # invocada indiretamente via em_cada_casa (SC2317: shellcheck novo re-acusa o corpo)
    archive_casa() {
      tem=0
      for f in "$1"/*.md; do
        [ -f "$f" ] && { tem=1; break; }
      done
      [ "$tem" = 1 ] || return 0
      dest="$1/reported-$compact"
      mkdir -p "$dest" || die2 "não consegui criar $dest"
      moved=0; kept=0
      for f in "$1"/*.md; do
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
      return 0
    }
    em_cada_casa archive_casa
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use append, list, count ou archive)" ;;
esac
