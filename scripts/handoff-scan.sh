#!/usr/bin/env bash
# handoff-scan.sh — varredura mecânica de handoffs de verificação pendentes (decisão 4.154).
# Formato do handoff: docs/_meta/conventions/handoff-protocol.md §8.2. Usado pelo
# /keelson:verify-handoff (Etapa 0), /keelson:integrate (destaque no PR) e pela
# Entrega do /keelson:auto — a lista (worktree, branch, slug, id, itens V* pendentes)
# chega como fato; a dedupe semântica de fluxo×realm continua do comando.
#
# Uso: handoff-scan.sh [--repo <dir>] [--no-worktrees]
#
#   --repo          repo de partida (default: cwd)
#   --no-worktrees  só o diretório dado (sem enumerar worktrees do git)
#
# Saída (TSV, ordenada): handoff<TAB><worktree><TAB><branch><TAB><slug><TAB><id><TAB><pendentes>/<total-V>
#   Só handoffs com `status: Pendente` no front-matter. Item V pendente = seção
#   `### V*` cuja linha **Evidência** segue vazia/placeholder (sem ✅/❌).
# Exit: 0 (informacional — nenhum pendente = saída vazia) · 2 uso incorreto.
# Read-only; bash 3.2 + awk POSIX. Sem git → varre só o --repo, sem branch.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/ficha.sh"

REPO="$PWD"
WORKTREES=1
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) shift; [ $# -gt 0 ] || die2 "--repo exige um diretório."; REPO="$1" ;;
    --no-worktrees) WORKTREES=0 ;;
    -h|--help) usage; exit 0 ;;
    *) die2 "opção desconhecida: $1" ;;
  esac
  shift
done
[ -d "$REPO" ] || die2 "repo não existe: $REPO"

TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT

# lista de worktrees: "caminho<TAB>branch"
if [ "$WORKTREES" = 1 ] && command -v git >/dev/null 2>&1 \
   && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$REPO" worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { wt = substr($0, 10) }
    /^branch /   { b = substr($0, 8); sub(/^refs\/heads\//, "", b); print wt "\t" b; wt = "" }
    /^detached/  { if (wt != "") print wt "\t(detached)"; wt = "" }
  ' > "$TMP/wts.tsv"
else
  printf '%s\t-\n' "$REPO" > "$TMP/wts.tsv"
fi

scan_handoff() { # $1 = arquivo, $2 = worktree, $3 = branch
  awk -v WT="$2" -v BR="$3" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    NR == 1 && /^---$/ { fm = 1; next }
    fm && /^---$/ { fm = 0; next }
    fm {
      if ($0 ~ /^id:/)     { v = $0; sub(/^id:[ \t]*/, "", v); id = trim(v) }
      if ($0 ~ /^slug:/)   { v = $0; sub(/^slug:[ \t]*/, "", v); slug = trim(v) }
      if ($0 ~ /^status:/) { v = $0; sub(/^status:[ \t]*/, "", v); sub(/#.*$/, "", v); status = trim(v) }
      next
    }
    /^### V[0-9]/ { flushv(); inv = 1; tot++; pendente = 1; next }
    /^### / || /^## / { flushv() }
    inv && /\*\*Evid/ {
      # linha de evidencia preenchida (tem ✅ ou ❌) → item fechado
      if ($0 ~ /\342\234\205/ || $0 ~ /\342\235\214/) pendente = 0
    }
    function flushv() { if (inv && pendente) pend++; inv = 0; pendente = 0 }
    END {
      flushv()
      if (status == "Pendente")
        printf "handoff\t%s\t%s\t%s\t%s\t%d/%d\n", WT, BR, (slug == "" ? "-" : slug), (id == "" ? "-" : id), pend, tot
    }
  ' "$1"
}

while IFS='	' read -r wt br; do
  [ -d "$wt" ] || continue
  droot="docs"
  if [ -f "$wt/keelson.config.json" ] && [ -f "$FICHA_SH" ]; then
    droot="$(bash "$FICHA_SH" "$wt" --get docsRoot --default docs 2>/dev/null || echo docs)"
  fi
  for h in "$wt/$droot"/*/handoffs/HANDOFF-*.md; do
    [ -f "$h" ] || continue
    scan_handoff "$h" "$wt" "$br"
  done
done < "$TMP/wts.tsv" | sort

exit 0
