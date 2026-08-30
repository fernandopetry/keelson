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
#   init       escreve run-state-<slug>.md na CASA DA SESSÃO (decisão 4.314 —
#              resolvida por session-dir.sh: thoughts/local/sessions/<ts>-<sid8>/;
#              sem id de sessão, o caminho legado thoughts/local/) com as chaves
#              canônicas (waves_concluidas: 0, status: em_andamento, sessao: <id>).
#              Arquivo em_andamento DESTA sessão é sobrescrito com aviso em stderr
#              (a largada é a dona); run legado em_andamento não-alheio do mesmo
#              slug é absorvido (removido com aviso) — nunca fica órfão.
#   wave-done  incrementa waves_concluidas (exit 2 se o arquivo não existe)
#   close      status: encerrado — <motivo> (o wave-guard deixa de bloquear)
#   remove     apaga o arquivo (idempotente; cobre casa da sessão E legado)
#   show       imprime o arquivo (nada se ausente)
#
# Leitura dupla (carência 4.314): wave-done/close/show operam no arquivo da casa
# da sessão quando ele existe, senão no caminho legado — um run iniciado antes do
# update continua operável; a ESCRITA de run novo é sempre na casa resolvida.
#
# Posse (decisão 4.251): `sessao:` identifica quem escreveu — fonte RUN_STATE_SESSAO,
# senão CLAUDE_CODE_SESSION_ID (mesmo UUID que os hooks recebem no payload), senão
# "desconhecida". init/wave-done/close/remove recusam (exit 2) run em_andamento de
# OUTRA sessão quando ambos os ids são conhecidos — degradam ao comportamento antigo
# quando algum lado é "desconhecida". FORCE=1 assume a posse de propósito.
#
# Exit: 0 ok · 2 uso incorreto/arquivo ausente onde obrigatório/run de terceiro.
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

SESSAO="${RUN_STATE_SESSAO:-${CLAUDE_CODE_SESSION_ID:-desconhecida}}"

# Casa da sessão (4.314): session-dir.sh é o dono da resolução; ausente ou
# falhando, degrada para o caminho legado (nunca trava o run por causa de layout).
SDS="$(cd "$(dirname "$0")" && pwd)/session-dir.sh"
DIR_LEG="$ROOT/thoughts/local"
F_LEG="$DIR_LEG/run-state-$SLUG.md"
sd() { KEELSON_SESSAO="$SESSAO" bash "$SDS" "$ROOT" "$@" 2>/dev/null; }

resolve_leitura() { # F = arquivo da casa da sessão se existe, senão o legado
  F="$F_LEG"
  [ -f "$SDS" ] || return 0
  d="$(sd dir)" || d=""
  [ -n "$d" ] || return 0
  [ -f "$d/run-state-$SLUG.md" ] && F="$d/run-state-$SLUG.md"
}

# Posse (4.251): run em_andamento de outra sessão não se toca — exit 2 com instrução
# de terceira saída. Só acusa com ambos os ids conhecidos; na dúvida, degrada (nunca
# bloqueio cego). FORCE=1 é a assunção deliberada.
recusa_se_alheio() { # $1 = arquivo (default: $F)
  alvo="${1:-$F}"
  [ -f "$alvo" ] || return 0
  grep -q '^status: em_andamento' "$alvo" 2>/dev/null || return 0
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$alvo" 2>/dev/null | sed -n 1p)"
  [ -n "$dono" ] || return 0
  [ "$dono" = "desconhecida" ] && return 0
  [ "$SESSAO" = "desconhecida" ] && return 0
  [ "$dono" = "$SESSAO" ] && return 0
  [ "${FORCE:-}" = "1" ] && return 0
  die2 "run em andamento de $SLUG pertence à sessão '$dono' (esta é '$SESSAO') — posse de terceiro (4.251). Não continue nem encerre o run alheio: inventarie (mtime, git status da worktree em 'retomada', sessões pares vivas) e escale ao humano. FORCE=1 assume a posse de propósito."
}

case "$ACTION" in
  init)
    PLAN="${1:-}"; TOTAL="${2:-}"
    [ -n "$PLAN" ] && [ -n "$TOTAL" ] || die2 "init exige <PLAN-MMM> e <waves_total>."
    case "$PLAN" in PLAN-[0-9]*) ;; *) die2 "PLAN-MMM inválido: $PLAN" ;; esac
    case "$TOTAL" in ''|*[!0-9]*) die2 "waves_total deve ser numérico: $TOTAL" ;; esac
    shift 2
    RET="${*:-}"
    [ -n "$RET" ] || die2 "init exige a linha de retomada (caminhos dos artefatos)."
    DIR="$DIR_LEG"
    if [ -f "$SDS" ]; then
      d="$(sd dir --create --slug "$SLUG")" || d=""
      [ -n "$d" ] && DIR="$d"
    fi
    mkdir -p "$DIR" || die2 "não consegui criar $DIR"
    F="$DIR/run-state-$SLUG.md"
    recusa_se_alheio "$F"
    # run LEGADO em_andamento do mesmo slug: alheio recusa; não-alheio é absorvido
    # (removido com aviso) — a largada nova é a dona e órfão re-acusaria no wave-guard
    if [ "$F" != "$F_LEG" ] && [ -f "$F_LEG" ] && grep -q '^status: em_andamento' "$F_LEG" 2>/dev/null; then
      recusa_se_alheio "$F_LEG"
      echo "run-state: aviso — absorvendo run legado em andamento de $SLUG (largada nova, casa da sessão)." >&2
      rm -f "$F_LEG"
    fi
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
      printf 'sessao: %s\n' "$SESSAO"
    } > "$F" || die2 "não consegui escrever $F"
    exit 0 ;;

  wave-done)
    resolve_leitura
    [ -f "$F" ] || die2 "run-state ausente: $F (init não rodou?)"
    recusa_se_alheio "$F"
    cur="$(sed -n 's/^waves_concluidas:[ 	]*//p' "$F" | sed -n 1p)"
    case "$cur" in ''|*[!0-9]*) die2 "waves_concluidas ilegível em $F: \"$cur\"" ;; esac
    nxt=$((cur + 1))
    tmp="$F.tmp.$$"
    sed "s/^waves_concluidas:.*/waves_concluidas: $nxt/" "$F" > "$tmp" || die2 "sed falhou"
    mv "$tmp" "$F" || die2 "não consegui atualizar $F"
    printf '%s\n' "$nxt"
    exit 0 ;;

  close)
    resolve_leitura
    [ -f "$F" ] || die2 "run-state ausente: $F (nada a encerrar)"
    recusa_se_alheio "$F"
    MOT="${*:-}"
    [ -n "$MOT" ] || die2 "close exige o <motivo> (parada é ato deliberado, nunca esquecimento)."
    tmp="$F.tmp.$$"
    sed "s/^status:.*/status: encerrado — $(printf '%s' "$MOT" | sed 's/[&/\\]/ /g')/" "$F" > "$tmp" || die2 "sed falhou"
    mv "$tmp" "$F" || die2 "não consegui atualizar $F"
    exit 0 ;;

  remove)
    # cobre as DUAS casas (resíduo legado da mesma sessão não fica para trás),
    # cada arquivo com a própria checagem de posse
    resolve_leitura
    recusa_se_alheio "$F"
    rm -f "$F"
    if [ "$F" != "$F_LEG" ] && [ -f "$F_LEG" ]; then
      recusa_se_alheio "$F_LEG"
      rm -f "$F_LEG"
    fi
    exit 0 ;;

  show)
    resolve_leitura
    [ -f "$F" ] && cat "$F"
    exit 0 ;;

  *) die2 "ação desconhecida: $ACTION (use init, wave-done, close, remove ou show)" ;;
esac
