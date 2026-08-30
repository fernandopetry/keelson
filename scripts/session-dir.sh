#!/usr/bin/env bash
# session-dir.sh — resolvedor canônico da casa da sessão (decisão 4.314).
# Regra e ciclo de vida: docs/_meta/conventions/sdd-conventions.md ("Casa da sessão").
# Este script é o ÚNICO dono da resolução: nome da pasta, manifest e fallback
# legado — chamador nenhum re-deriva caminho de sessão por conta própria.
#
# Uso: session-dir.sh <raiz-do-repo> dir        [--create] [--slug <slug>] [--ts <iso>]
#      session-dir.sh <raiz-do-repo> ledger-dir [--create] [--slug <slug>] [--ts <iso>]
#      session-dir.sh <raiz-do-repo> window-log [--create] [--ts <iso>]
#      session-dir.sh <raiz-do-repo> show
#      session-dir.sh <raiz-do-repo> latest-for <slug>
#      session-dir.sh <raiz-do-repo> memo-find <slug> [--all]
#      session-dir.sh <raiz-do-repo> adopt-memo <slug> [--ts <iso>]
#      session-dir.sh <raiz-do-repo> mark-reported
#
#   dir         ecoa a pasta da sessão corrente: thoughts/local/sessions/<yyyymmdd-hhmmss>-<sid8>
#               (criada com session.meta sob --create). SEM id de sessão → ecoa a
#               casa LEGADA (thoughts/local): os chamadores colapsam no layout
#               antigo e nada muda de comportamento.
#   ledger-dir  ecoa a pasta do ledger da sessão (<dir>/ledger; legado:
#               thoughts/local/session-ledger).
#   window-log  ecoa o CAMINHO DO ARQUIVO do log de janela (<dir>/window.log;
#               legado: thoughts/local/session-window.log).
#   show        imprime o session.meta da sessão corrente (nada se ausente).
#   latest-for  ecoa a pasta da sessão MAIS RECENTE (excluindo a corrente) cujo
#               manifest registra o slug — a âncora do handover local (4.315);
#               vazio se nenhuma.
#   memo-find   ecoa o memo de exploração existente na CADEIA de leitura:
#               casa própria → casas anteriores (mais recente primeiro) →
#               legado thoughts/local/exploration-<slug>.md. Sem id de sessão,
#               só o legado. --all lista todos os existentes (é o que a closure
#               remove); sem --all, o primeiro. Vazio se nenhum.
#   adopt-memo  garante memo EDITÁVEL na casa própria (edição nunca toca o
#               memo de outra sessão): memo próprio existe → ecoa; herdado na
#               cadeia → copia para a casa própria e grava `anterior:` (id da
#               sessão de origem, ou "legado") no manifest; nada na cadeia →
#               ecoa o caminho próprio para o chamador criar. Sem id de sessão,
#               ecoa o caminho legado (comportamento antigo).
#   mark-reported  marca `estado: reportada` no manifest da casa corrente
#               (fecho de report — 4.315); sem casa, no-op silencioso. Uma
#               escrita posterior com --create reabre para `estado: ativa`.
#
#   --create    cria a pasta (e o session.meta, se nascendo agora) antes de ecoar.
#               Idempotente: pasta existente é resolvida, nunca duplicada.
#   --slug      registra o slug na linha `slugs:` do session.meta (dedup) — só
#               tem efeito quando a casa é a nova e a pasta existe/nasce agora.
#   --ts        timestamp ISO para o NOME de pasta recém-criada (determinismo em
#               teste; sem ele, medido com TZ=America/Sao_Paulo).
#
# Identidade da sessão: KEELSON_SESSAO quando DEFINIDA (override de teste; vazia
# ou "desconhecida" força o modo legado), senão CLAUDE_CODE_SESSION_ID. A pasta
# usa <sid8> = 8 primeiros caracteres alfanuméricos do id; o session.meta guarda
# o id completo, e a resolução confere o meta (colisão de prefixo não confunde).
#
# Exit: 0 ok (inclusive modo legado) · 2 uso incorreto. Nunca falha por estado.
# Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,56p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

# latest-for / memo-find / adopt-memo levam o slug como argumento posicional
ARG_SLUG=""
case "$ACTION" in
  latest-for|memo-find|adopt-memo)
    ARG_SLUG="${1:-}"
    [ -n "$ARG_SLUG" ] || die2 "$ACTION exige o <slug>."
    shift ;;
esac
case "$ARG_SLUG" in */*|*" "*) die2 "slug inválido: $ARG_SLUG" ;; esac

CREATE=0; SLUG=""; TS=""; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --create) CREATE=1 ;;
    --all)  ALL=1 ;;
    --slug) shift; [ $# -gt 0 ] || die2 "--slug exige o slug."; SLUG="$1" ;;
    --ts)   shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$1" ;;
    *) die2 "opção desconhecida: $1" ;;
  esac
  shift
done
case "$SLUG" in */*|*" "*) die2 "slug inválido: $SLUG" ;; esac

LEGACY="$ROOT/thoughts/local"
SESSIONS="$LEGACY/sessions"

if [ "${KEELSON_SESSAO+definida}" = "definida" ]; then
  SID="$KEELSON_SESSAO"
else
  SID="${CLAUDE_CODE_SESSION_ID:-}"
fi
[ "$SID" = "desconhecida" ] && SID=""
SID8="$(printf '%s' "$SID" | tr -cd 'A-Za-z0-9' | cut -c1-8)"
[ -n "$SID8" ] || SID=""

stamp_compact() { # ecoa yyyymmdd-hhmmss a partir de $TS (ou medido)
  iso="$TS"
  if [ -z "$iso" ]; then
    iso="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z)"
  fi
  compact="$(printf '%s\n' "$iso" | sed 's/[-:]//g; s/T/-/; s/+.*$//; s/\([0-9]\{8\}-[0-9]\{6\}\).*/\1/')"
  case "$compact" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) die2 "timestamp ilegível: $iso" ;;
  esac
  printf '%s\n' "$compact"
}

# resolve_dir: ecoa a pasta da sessão em RESOLVED ("" se nenhuma existe).
# Percorre em ordem lexicográfica; múltiplos matches (não deveria) → o mais recente.
resolve_dir() {
  RESOLVED=""
  for d in "$SESSIONS"/*-"$SID8"; do
    [ -d "$d" ] || continue
    [ -f "$d/session.meta" ] || continue
    grep -qxF "sessao: $SID" "$d/session.meta" 2>/dev/null || continue
    RESOLVED="$d"
  done
}

# registra o slug na linha `slugs:` do meta (dedup; uma linha, separada por espaço)
touch_slug() { # $1 = pasta
  [ -n "$SLUG" ] || return 0
  meta="$1/session.meta"
  [ -f "$meta" ] || return 0
  atual="$(sed -n 's/^slugs:[ 	]*//p' "$meta" 2>/dev/null | sed -n 1p)"
  for s in $atual; do
    [ "$s" = "$SLUG" ] && return 0
  done
  novo="$atual $SLUG"
  novo="${novo# }"
  tmp="$meta.tmp.$$"
  sed "s|^slugs:.*|slugs: $novo|" "$meta" > "$tmp" 2>/dev/null && mv "$tmp" "$meta" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}

session_home() { # ecoa a pasta da sessão (cria sob --create); vazio = use o legado
  [ -n "$SID" ] || { printf '\n'; return 0; }
  resolve_dir
  if [ -n "$RESOLVED" ]; then
    # escrita sobre casa já reportada reabre o estado (4.315): a sessão voltou
    # a trabalhar, e um próximo fecho re-marcará
    if [ "$CREATE" -eq 1 ] && grep -qx 'estado: reportada' "$RESOLVED/session.meta" 2>/dev/null; then
      tmp="$RESOLVED/session.meta.tmp.$$"
      sed 's/^estado:.*/estado: ativa/' "$RESOLVED/session.meta" > "$tmp" 2>/dev/null \
        && mv "$tmp" "$RESOLVED/session.meta" 2>/dev/null || rm -f "$tmp" 2>/dev/null
    fi
    touch_slug "$RESOLVED"
    printf '%s\n' "$RESOLVED"
    return 0
  fi
  if [ "$CREATE" -eq 1 ]; then
    compact="$(stamp_compact)" || exit 2
    d="$SESSIONS/$compact-$SID8"
    mkdir -p "$d" || die2 "não consegui criar $d"
    if [ ! -f "$d/session.meta" ]; then
      iso="$TS"
      [ -n "$iso" ] || iso="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z)"
      {
        printf 'sessao: %s\n' "$SID"
        printf 'iniciada: %s\n' "$iso"
        printf 'estado: ativa\n'
        printf 'slugs:\n'
      } > "$d/session.meta" || die2 "não consegui escrever $d/session.meta"
    fi
    touch_slug "$d"
    printf '%s\n' "$d"
    return 0
  fi
  printf '\n'
}

case "$ACTION" in
  dir)
    home="$(session_home)" || exit 2
    if [ -n "$home" ]; then
      printf '%s\n' "$home"
    else
      [ "$CREATE" -eq 1 ] && { mkdir -p "$LEGACY" || die2 "não consegui criar $LEGACY"; }
      printf '%s\n' "$LEGACY"
    fi
    exit 0 ;;

  ledger-dir)
    home="$(session_home)" || exit 2
    if [ -n "$home" ]; then
      d="$home/ledger"
    else
      d="$LEGACY/session-ledger"
    fi
    [ "$CREATE" -eq 1 ] && { mkdir -p "$d" || die2 "não consegui criar $d"; }
    printf '%s\n' "$d"
    exit 0 ;;

  window-log)
    home="$(session_home)" || exit 2
    if [ -n "$home" ]; then
      printf '%s\n' "$home/window.log"
    else
      [ "$CREATE" -eq 1 ] && { mkdir -p "$LEGACY" || die2 "não consegui criar $LEGACY"; }
      printf '%s\n' "$LEGACY/session-window.log"
    fi
    exit 0 ;;

  show)
    [ -n "$SID" ] || exit 0
    resolve_dir
    [ -n "$RESOLVED" ] && [ -f "$RESOLVED/session.meta" ] && cat "$RESOLVED/session.meta"
    exit 0 ;;

  latest-for)
    RESOLVED=""
    [ -n "$SID" ] && resolve_dir
    last=""
    for d in "$SESSIONS"/*; do
      [ -d "$d" ] || continue
      [ "$d" = "${RESOLVED:-}" ] && continue
      linha="$(sed -n 's/^slugs:[ 	]*//p' "$d/session.meta" 2>/dev/null | sed -n 1p)"
      for s in $linha; do
        [ "$s" = "$ARG_SLUG" ] && { last="$d"; break; }
      done
    done
    [ -n "$last" ] && printf '%s\n' "$last"
    exit 0 ;;

  memo-find)
    if [ -n "$SID" ]; then
      RESOLVED=""; resolve_dir
      if [ -n "$RESOLVED" ] && [ -f "$RESOLVED/exploration-$ARG_SLUG.md" ]; then
        printf '%s\n' "$RESOLVED/exploration-$ARG_SLUG.md"
        [ "$ALL" -eq 0 ] && exit 0
      fi
      # casas anteriores, mais recente primeiro (prepend inverte a ordem do glob)
      set --
      for d in "$SESSIONS"/*; do
        [ -d "$d" ] || continue
        [ "$d" = "${RESOLVED:-}" ] && continue
        [ -f "$d/exploration-$ARG_SLUG.md" ] || continue
        set -- "$d" "$@"
      done
      for d in "$@"; do
        printf '%s\n' "$d/exploration-$ARG_SLUG.md"
        [ "$ALL" -eq 0 ] && exit 0
      done
    fi
    [ -f "$LEGACY/exploration-$ARG_SLUG.md" ] && printf '%s\n' "$LEGACY/exploration-$ARG_SLUG.md"
    exit 0 ;;

  adopt-memo)
    if [ -z "$SID" ]; then
      mkdir -p "$LEGACY" || die2 "não consegui criar $LEGACY"
      printf '%s\n' "$LEGACY/exploration-$ARG_SLUG.md"
      exit 0
    fi
    CREATE=1; SLUG="$ARG_SLUG"
    home="$(session_home)" || exit 2
    alvo="$home/exploration-$ARG_SLUG.md"
    if [ -f "$alvo" ]; then
      printf '%s\n' "$alvo"
      exit 0
    fi
    # herdar da cadeia: casas anteriores (mais recente primeiro), depois o legado
    origem=""; origem_id=""
    set --
    for d in "$SESSIONS"/*; do
      [ -d "$d" ] || continue
      [ "$d" = "$home" ] && continue
      [ -f "$d/exploration-$ARG_SLUG.md" ] || continue
      set -- "$d" "$@"
    done
    for d in "$@"; do
      origem="$d/exploration-$ARG_SLUG.md"
      origem_id="$(sed -n 's/^sessao:[ 	]*//p' "$d/session.meta" 2>/dev/null | sed -n 1p)"
      [ -n "$origem_id" ] || origem_id="desconhecida"
      break
    done
    if [ -z "$origem" ] && [ -f "$LEGACY/exploration-$ARG_SLUG.md" ]; then
      origem="$LEGACY/exploration-$ARG_SLUG.md"; origem_id="legado"
    fi
    if [ -n "$origem" ]; then
      cp "$origem" "$alvo" 2>/dev/null || die2 "não consegui copiar $origem"
      meta="$home/session.meta"
      # a primeira herança fica registrada; adoções posteriores não a sobrescrevem
      if [ -f "$meta" ] && ! grep -q '^anterior:' "$meta" 2>/dev/null; then
        printf 'anterior: %s\n' "$origem_id" >> "$meta"
      fi
    fi
    printf '%s\n' "$alvo"
    exit 0 ;;

  mark-reported)
    [ -n "$SID" ] || exit 0
    RESOLVED=""; resolve_dir
    [ -n "$RESOLVED" ] || exit 0
    meta="$RESOLVED/session.meta"
    [ -f "$meta" ] || exit 0
    tmp="$meta.tmp.$$"
    sed 's/^estado:.*/estado: reportada/' "$meta" > "$tmp" 2>/dev/null \
      && mv "$tmp" "$meta" 2>/dev/null || rm -f "$tmp" 2>/dev/null
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use dir, ledger-dir, window-log, show, latest-for, memo-find, adopt-memo ou mark-reported)" ;;
esac
