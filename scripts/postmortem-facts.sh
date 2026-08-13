#!/usr/bin/env bash
# postmortem-facts.sh — fatos de cabeçalho do /keelson:postmortem (decisão 4.154).
# A ANÁLISE (mecanismo, causa-raiz, classificação) continua do comando; aqui só o que
# o disco e o git provam: versão instalada do plugin (sem ela o mantenedor não sabe se
# a doutrina vigente já cobre o caso), branch/HEAD e a janela de commits do episódio.
#
# Uso: postmortem-facts.sh [--repo <dir>] [--since <ref>] [--plugin-root <dir>]
#
#   --since  ref inicial da janela (ex.: main, um SHA, HEAD~8) — imprime os commits
#            de <ref>..HEAD e o diffstat de <ref>...HEAD
#
# Saída: versao=<plugin> · branch=… · head=… · commit<TAB><sha><TAB><subject> ·
#        diffstat=<resumo>. Campo indisponível sai como valor "-" (nunca silêncio).
# Exit: 0 · 2 uso incorreto. Read-only; bash 3.2.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

REPO="$PWD"
SINCE=""
PLUGROOT="${CLAUDE_PLUGIN_ROOT:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)  shift; [ $# -gt 0 ] || die2 "--repo exige um diretório."; REPO="$1" ;;
    --since) shift; [ $# -gt 0 ] || die2 "--since exige uma ref."; SINCE="$1" ;;
    --plugin-root) shift; [ $# -gt 0 ] || die2 "--plugin-root exige um diretório."; PLUGROOT="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) die2 "opção desconhecida: $1" ;;
  esac
  shift
done
[ -d "$REPO" ] || die2 "repo não existe: $REPO"
[ -n "$PLUGROOT" ] || PLUGROOT="$(cd "$(dirname "$0")/.." && pwd)"

# versão do plugin instalado (extração sed, mesmo padrão do check-release)
ver="-"
pj="$PLUGROOT/.claude-plugin/plugin.json"
if [ -f "$pj" ]; then
  v="$(sed -n 's/.*"version"[ \t]*:[ \t]*"\([^"]*\)".*/\1/p' "$pj" | sed -n 1p)"
  [ -n "$v" ] && ver="$v"
fi
printf 'versao=%s\n' "$ver"

if command -v git >/dev/null 2>&1 && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  printf 'branch=%s\n' "$(git -C "$REPO" symbolic-ref --short HEAD 2>/dev/null || echo '-')"
  printf 'head=%s\n' "$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo '-')"
  if [ -n "$SINCE" ]; then
    git -C "$REPO" rev-parse --verify --quiet "$SINCE" >/dev/null 2>&1 || die2 "ref não resolve: $SINCE"
    git -C "$REPO" log --format='commit%x09%h%x09%s' "$SINCE..HEAD" 2>/dev/null
    ds="$(git -C "$REPO" diff --stat "$SINCE...HEAD" 2>/dev/null | tail -1 | sed 's/^[ \t]*//')"
    printf 'diffstat=%s\n' "${ds:--}"
  fi
else
  printf 'branch=-\nhead=-\n'
  [ -n "$SINCE" ] && printf 'diffstat=-\n'
fi
exit 0
