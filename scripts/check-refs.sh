#!/usr/bin/env bash
# check-refs.sh — ponteiros internos da doutrina apontam para arquivos que existem (decisão 4.209).
#
# O que este script prova: toda citação de caminho do pacote feita na doutrina
# (span de crase em prosa, ou `${CLAUDE_PLUGIN_ROOT}/...` em qualquer posição,
# inclusive dentro de fence) resolve para arquivo ou diretório existente no repo.
#
# Superfícies varridas (via `git ls-files` — nunca `find .`, que enxergaria
# cópias untracked como .claude/worktrees/):
#   CLAUDE.md · commands/*.md · agents/*.md · skills/**/*.md · guidelines/**/*.md
#   docs/_meta/conventions/*.md · templates/*.md
#
# Régua de precisão (falso-positivo em artefato legítimo é o pior defeito desta
# camada — mesmo princípio do graph.sh, 4.82): só é candidato o caminho que
# começa por raiz conhecida do pacote (commands/ agents/ skills/ guidelines/
# templates/ hooks/ scripts/ docs/_meta/ docs/wiki/ .claude-plugin/ .claude/
# .github/). Todo o resto é ignorado — em particular caminhos do CONSUMIDOR
# usados como exemplo (docs/<slug>/..., app/, thoughts/, keelson.config.json).
# Exceção dentro de raiz conhecida: guidelines/project/** só existe no
# consumidor (materializado pelo /keelson:init) — nunca é verificado aqui.
# Placeholders nunca acusam: token com { } < > [ ] * ou espaço é pulado.
# Âncora de linha (`arquivo:12` / `arquivo:12-15`) é aparada antes do teste.
# `${CLAUDE_PLUGIN_ROOT}/` normaliza para a raiz do repo; barra final aceita
# diretório (`-e` cobre ambos). Prosa fora de crase não é varrida (falso
# negativo preferível a acusar prosa).
#
# Fronteira de dono: o manifesto MIRRORS de scripts/publish-wiki.sh continua
# provado por check-release.sh — este script cobre citação em prosa .md, nunca
# o manifesto.
#
# Uso: check-refs.sh [--root <dir>]   (default: raiz do repo via git)
# Exit: 0 tudo resolve · 1 ponteiro quebrado · 2 uso incorreto.
# Bash 3.2-compatível, POSIX grep/sed/awk, read-only.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "uso: check-refs.sh [--root <dir>]" >&2; exit 2; }
            ROOT="$2"; shift 2 ;;
    *) echo "uso: check-refs.sh [--root <dir>]" >&2; exit 2 ;;
  esac
done
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "ERRO: fora de repo git e sem --root" >&2; exit 2; }
fi
[ -d "$ROOT" ] || { echo "ERRO: raiz inexistente: $ROOT" >&2; exit 2; }

# Superfícies: doutrina do pacote + CLAUDE.md do repo (ls-files ignora untracked).
surfaces="$(git -C "$ROOT" ls-files -- \
  'CLAUDE.md' 'commands/*.md' 'agents/*.md' 'skills/*.md' 'skills/**/*.md' \
  'guidelines/*.md' 'guidelines/**/*.md' 'docs/_meta/conventions/*.md' \
  'templates/*.md' 2>/dev/null)"
[ -n "$surfaces" ] || { echo "ERRO: nenhuma superfície encontrada em $ROOT" >&2; exit 2; }

# Extrai candidatos: "arquivo<TAB>linha<TAB>caminho", um por linha.
extract() { # $1 = arquivo relativo à raiz
  awk -v FILE="$1" '
    BEGIN { fence = 0 }
    /^[ \t]*```/ { fence = !fence; next }
    {
      line = $0
      if (fence) {
        # Dentro de fence só ${CLAUDE_PLUGIN_ROOT}/... interessa (leitura de runtime).
        rest = line
        while (match(rest, /\$\{CLAUDE_PLUGIN_ROOT\}\/[^"'"'"' `)\]]+/)) {
          tok = substr(rest, RSTART, RLENGTH)
          printf "%s\t%d\t%s\n", FILE, NR, tok
          rest = substr(rest, RSTART + RLENGTH)
        }
        next
      }
      # Fora de fence: spans de crase (campos pares de split por crase).
      n = split(line, seg, /`/)
      for (i = 2; i <= n; i += 2)
        printf "%s\t%d\t%s\n", FILE, NR, seg[i]
    }
  ' "$ROOT/$1"
}

fails=0
checked=0
printf '%s\n' "$surfaces" | while IFS= read -r f; do
  extract "$f"
done | while IFS="$(printf '\t')" read -r file lineno tok; do
  # Normaliza o prefixo de runtime do plugin.
  path="$(printf '%s' "$tok" | sed 's|^\${CLAUDE_PLUGIN_ROOT}/||')"
  # Placeholder / glob / múltiplos tokens → nunca acusa.
  case "$path" in
    *'{'*|*'}'*|*'<'*|*'>'*|*'['*|*']'*|*'*'*|*' '*|*'	'*|*'...'*) continue ;;
  esac
  # Só raiz conhecida do pacote entra no teste (docs/ restrito a _meta e wiki).
  case "$path" in
    guidelines/project|guidelines/project/*) continue ;;
    commands/*|agents/*|skills/*|guidelines/*|templates/*|hooks/*|scripts/*) : ;;
    docs/_meta/*|docs/wiki/*) : ;;
    .claude-plugin/*|.claude/*|.github/*) : ;;
    *) continue ;;
  esac
  # Apara âncora de linha e pontuação de cauda; barra final indica diretório.
  path="$(printf '%s' "$path" | sed -e 's/:[0-9][0-9-]*$//' -e 's/[,;:)]*$//' -e 's|/$||')"
  [ -n "$path" ] || continue
  checked=$((checked + 1))
  if [ ! -e "$ROOT/$path" ]; then
    echo "ERRO: $file:$lineno: ponteiro quebrado: $tok"
    fails=$((fails + 1))
  fi
  # Subshell do pipe: estado sai pelo arquivo de resultado.
  printf '%s %s\n' "$checked" "$fails" > "${TMPDIR:-/tmp}/check-refs.$$"
done

state="${TMPDIR:-/tmp}/check-refs.$$"
if [ -f "$state" ]; then
  checked="$(awk '{print $1}' "$state")"
  fails="$(awk '{print $2}' "$state")"
  rm -f "$state"
fi
if [ "${fails:-0}" -gt 0 ]; then
  echo "check-refs: $fails ponteiro(s) quebrado(s) em $checked citação(ões) verificada(s)." >&2
  exit 1
fi
echo "check-refs: ok — $checked citação(ões) de caminho verificadas, todas resolvem."
exit 0
