#!/usr/bin/env bash
# ledger.sh — mecânica do ledger de sessão (decisões 4.76/4.151).
# Formato, catálogo de tipos e ciclo de vida: docs/_meta/conventions/sdd-conventions.md
# ("Ledger de sessão"). Este script cuida da parte mecânica (nome ordenável, timestamp
# medido, arquivamento seletivo); O QUE anotar e QUANDO continua sendo da doutrina.
#
# Uso: ledger.sh <raiz-do-repo> append <tipo> <origem> <slug> [--ref <caminho>] [--ts <iso>]
#                                                             [--diff-id <hash|none>]
#      ledger.sh <raiz-do-repo> mark gate <origem> <slug> [--ts <iso>]
#      ledger.sh <raiz-do-repo> list [--archived]
#      ledger.sh <raiz-do-repo> count
#      ledger.sh <raiz-do-repo> last <tipo> <origem>
#      ledger.sh <raiz-do-repo> archive [--keep <arquivo>]… [--ts <iso>]
#
#   append   cria <yyyymmdd-hhmmss>-<tipo>-<origem>.md no ledger da CASA DA SESSÃO
#            (nome reservado atomicamente — dois append no mesmo segundo ganham
#            sufixos distintos, nunca o mesmo arquivo; 4.384)
#            (decisão 4.314 — resolvida por session-dir.sh:
#            thoughts/local/sessions/<ts>-<sid8>/ledger/; sem id de sessão, o
#            caminho legado thoughts/local/session-ledger/) com o cabeçalho
#            canônico; o corpo (2–3 linhas) entra pelo stdin.
#            Tipos (catálogo FECHADO): gate decisao intervencao fora_de_escopo pendencia tracker marco wave_sequencial.
#            Timestamp medido (TZ=America/Sao_Paulo); --ts <iso> só para testes.
#            A linha `ts:` do cabeçalho é DESTE script — linha `ts:` no início do
#            stdin é descartada (4.156: ts estimado de memória não entra no evento).
#            Evento `gate` de code-reviewer (escopo review) ou security-engineer
#            (escopo security) ganha a linha `diff_id: <hash>` — identidade do diff que
#            o guard correspondente vigia, tomada da MARCA feita no despacho (`mark`,
#            abaixo): o estado que o revisor recebeu, nunca a árvore do instante do
#            registro (4.378/4.379 — medir a árvore no registro não prova que ela foi
#            revisada). A marca é consumida; se a identidade atual difere da marca, o
#            evento ganha `diff_id_nota:` (a árvore mudou entre despacho e registro — o
#            parecer cobre a marca, o guard cutuca). SEM marca → sem linha (o guard cai
#            no mtime). --diff-id explícito substitui (`none` suprime — testes/legado).
#            Linha `diff_id:` vinda pelo stdin é descartada como a `ts:` — o hash é
#            medido, nunca escrito de memória.
#   mark     grava a marca do despacho: mede AGORA a identidade do escopo do guard da
#            origem (code-reviewer → review; security-engineer → security) via
#            `diff-facts.sh --guard`, só na árvore principal (worktree vinculado não
#            marca), em `<ledger>/mark-gate-<origem>` (sem `.md`: invisível a list/
#            count/last/archive) com `ts:`, `diff_id:`, `scope:` e `slug:`; ecoa o
#            caminho. O append só consome marca do MESMO slug — marca órfã de outro
#            fluxo é ignorada (veredito sem diff_id). A marca morre com a casa (gc).
#            Chamada pelo comando ANTES de despachar o revisor. Sem ficha, git, escopo
#            ou raiz principal → aviso em stderr, exit 0, nada gravado (nunca é gate).
#            Colisão de segundo ganha sufixo -2, -3… Ecoa o caminho criado.
#   list     eventos ativos (um por linha, ordenados); --archived lista os consumidos
#   count    contagem de eventos ativos por tipo
#   last     caminho do evento MAIS RECENTE do par tipo/origem — ativos e arquivados
#            (reported-*/), casa da sessão e legado; vazio + exit 0 sem evento.
#            Leitor: os stop-guards (review-guard/security-guard) comparam o `diff_id:`
#            dele com a identidade atual do diff — "o veredito cobre a árvore?" (4.378);
#            evento sem `diff_id:` cai na comparação por mtime (4.365).
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
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
# (a checagem de árvore principal do diff_id, 4.378, é a única chamada direta daqui)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,/^# Bash 3.2-compat/p' "$0" | sed 's/^# \{0,1\}//'; }

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
DF="$(cd "$(dirname "$0")" && pwd)/diff-facts.sh"
# medir_identidade <review|security> → identidade do escopo do guard na ÁRVORE PRINCIPAL
# (num worktree vinculado --git-dir ≠ --git-common-dir e a identidade nunca casaria com a
# do guard, que roda na raiz do projeto); vazio quando não dá para medir.
medir_identidade() {
  gd="$(git -C "$ROOT" rev-parse --git-dir 2>/dev/null || true)"
  gcd="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
  { [ -f "$DF" ] && [ -n "$gd" ] && [ "$gd" = "$gcd" ]; } || return 0
  bash "$DF" --repo "$ROOT" --guard "$1" 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2; exit }'
  return 0
}
escopo_da_origem() { # code-reviewer → review · security-engineer → security · outro → vazio
  case "$1" in code-reviewer) echo review ;; security-engineer) echo security ;; esac
}
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
      gate|decisao|intervencao|fora_de_escopo|pendencia|tracker|marco|wave_sequencial) ;;
      *) die2 "tipo fora do catálogo fechado (4.76/4.244/4.301): $TIPO — use gate, decisao, intervencao, fora_de_escopo, pendencia, tracker, marco ou wave_sequencial" ;;
    esac
    case "$ORIGEM" in */*|*" "*) die2 "origem inválida (sem espaço/barra): $ORIGEM" ;; esac
    REF=""; TS=""; DIFFID=""; DIFFID_SET=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --ref) shift; [ $# -gt 0 ] || die2 "--ref exige um caminho."; REF="$1" ;;
        --ts)  shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$1" ;;
        --diff-id) shift; [ $# -gt 0 ] || die2 "--diff-id exige um hash (ou none)."; DIFFID="$1"; DIFFID_SET=1 ;;
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
    # diff_id (4.378/4.379): o veredito carrega a identidade do estado ENTREGUE ao
    # revisor — a marca gravada no despacho (`mark`) —, nunca a árvore do instante do
    # registro; a marca é consumida aqui. Árvore diferente da marca → nota no evento
    # (o guard cutuca, porque o estado revisado não é o da árvore). Sem marca → sem linha.
    NOTA=""
    if [ "$TIPO" = "gate" ] && [ "$DIFFID_SET" -eq 0 ]; then
      scope="$(escopo_da_origem "$ORIGEM")"
      markf="$LDIR/mark-gate-$ORIGEM"
      if [ -n "$scope" ] && [ -f "$markf" ]; then
        mslug="$(sed -n 's/^slug: //p' "$markf" 2>/dev/null | sed -n 1p)"
        if [ "$mslug" = "$SLUG" ]; then
          DIFFID="$(sed -n 's/^diff_id: //p' "$markf" 2>/dev/null | sed -n 1p)"
          agora="$(medir_identidade "$scope")"
          if [ -n "$DIFFID" ] && [ -n "$agora" ] && [ "$agora" != "$DIFFID" ]; then
            NOTA="diff_id_nota: a arvore mudou entre o despacho e o registro — o parecer cobre o estado da marca, nao o atual"
          fi
          rm -f "$markf"
        else
          # marca órfã de OUTRO slug (fluxo que despachou e não registrou): nunca é consumida
          # por veredito alheio — o evento sai sem diff_id (degradação segura, mtime)
          echo "ledger: marca pendente de $ORIGEM pertence ao slug '$mslug', não a '$SLUG' — ignorada; veredito sem diff_id." >&2
        fi
      fi
    fi
    [ "$DIFFID" = "none" ] && DIFFID=""
    base="$LDIR/$compact-$TIPO-$ORIGEM"
    f="$base.md"; n=1
    # Reserva ATÔMICA do nome (4.384): `set -C` (noclobber) faz o `>` falhar se o arquivo
    # já existe — dois append concorrentes no mesmo segundo nunca escolhem o mesmo
    # caminho (testar-existir-depois-escrever perdia um evento). A reserva precede a
    # leitura do stdin; o sufixo de colisão continua o mesmo (-2, -3, …).
    while ! ( set -C; : > "$f" ) 2>/dev/null; do
      # falhou e o arquivo NÃO existe → não é colisão, é escrita impossível (permissão,
      # disco): erro nomeado na hora, nunca 9999 tentativas (4.387)
      [ -e "$f" ] || die2 "não consegui escrever em $LDIR (permissão? disco?)"
      n=$((n + 1))
      [ "$n" -le 9999 ] || die2 "não consegui reservar um nome livre a partir de $base"
      f="$base-$n.md"
    done
    corpo="$(cat)"
    # cabeçalho é do script: linha ts: duplicada no stdin (formato pré-4.151) sai, e
    # diff_id: escrita de memória também (4.378 — o hash é medido, nunca declarado)
    case "$corpo" in
      "ts: "*|"ts:"*) corpo="$(printf '%s\n' "$corpo" | sed 1d)" ;;
    esac
    corpo="$(printf '%s\n' "$corpo" | sed '/^diff_id:/d')"
    {
      printf 'ts: %s · tipo: %s · origem: %s · slug: %s\n' "$iso" "$TIPO" "$ORIGEM" "$SLUG"
      if [ -n "$corpo" ]; then printf '%s\n' "$corpo"; fi
      if [ -n "$DIFFID" ] && [ -n "$NOTA" ]; then printf '%s\n' "$NOTA"; fi
      if [ -n "$REF" ]; then printf 'ref: %s\n' "$REF"; fi
      if [ -n "$DIFFID" ]; then printf 'diff_id: %s\n' "$DIFFID"; fi
    } > "$f" || { rm -f "$f"; die2 "não consegui escrever $f"; }
    printf '%s\n' "$f"
    exit 0 ;;

  mark)
    TIPO="${1:-}"; ORIGEM="${2:-}"; SLUG="${3:-}"
    [ "$TIPO" = "gate" ] || die2 "mark existe só para o tipo gate."
    [ -n "$ORIGEM" ] && [ -n "$SLUG" ] || die2 "mark exige gate <origem> <slug>."
    shift 3
    TS=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --ts) shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$1" ;;
        *) die2 "opção desconhecida: $1" ;;
      esac
      shift
    done
    scope="$(escopo_da_origem "$ORIGEM")"
    [ -n "$scope" ] || die2 "mark: origem sem guard correspondente: $ORIGEM (code-reviewer|security-engineer)"
    pair="$(stamp "$TS")" || exit 2
    iso="${pair##*	}"
    id="$(medir_identidade "$scope")"
    if [ -z "$id" ]; then
      echo "ledger: marca não gravada (sem ficha, git, escopo ou raiz principal) — o veredito de $ORIGEM seguirá sem diff_id." >&2
      exit 0
    fi
    if [ -f "$SDS" ]; then
      d="$(bash "$SDS" "$ROOT" ledger-dir --create --slug "$SLUG" ${TS:+--ts "$TS"} 2>/dev/null)" || d=""
      [ -n "$d" ] && LDIR="$d"
    fi
    mkdir -p "$LDIR" || die2 "não consegui criar $LDIR"
    markf="$LDIR/mark-gate-$ORIGEM"
    printf 'ts: %s\ndiff_id: %s\nscope: %s\nslug: %s\n' "$iso" "$id" "$scope" "$SLUG" > "$markf" || die2 "não consegui escrever $markf"
    printf '%s\n' "$markf"
    exit 0 ;;

  last)
    TIPO="${1:-}"; ORIGEM="${2:-}"
    [ -n "$TIPO" ] && [ -n "$ORIGEM" ] || die2 "last exige <tipo> <origem>."
    # evento MAIS RECENTE do par tipo/origem — ativos e arquivados (reported-*/), casa
    # legada e casa da sessão: o nome é ordenável (yyyymmdd-hhmmss), o maior basename
    # vence. Leitor: os stop-guards perguntam "o último veredito cobre a árvore?"
    # (decisão 4.365) comparando o mtime deste arquivo com o dos arquivos alterados.
    # Vazio + exit 0 quando não há evento (nunca é gate).
    # shellcheck disable=SC2329,SC2317  # invocada indiretamente via em_cada_casa (SC2317: shellcheck novo re-acusa o corpo)
    last_casa() {
      for f in "$1"/*-"$TIPO"-"$ORIGEM"*.md "$1"/reported-*/*-"$TIPO"-"$ORIGEM"*.md; do
        [ -f "$f" ] || continue
        printf '%s\t%s\n' "$(basename "$f")" "$f"
      done
      return 0
    }
    em_cada_casa last_casa | sort | tail -n 1 | cut -f2-
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

  *) die2 "ação desconhecida: $ACTION (use append, mark, last, list, count ou archive)" ;;
esac
