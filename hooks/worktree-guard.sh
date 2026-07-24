#!/usr/bin/env bash
# worktree-guard — hook PreToolUse (Edit|Write|NotebookEdit) que impede edição
# ACIDENTAL do checkout principal quando a sessão trabalha numa WORKTREE.
#
# Cenário real (decisão 4.30): sessão rodando numa worktree quase editou o
# arquivo homônimo no repositório principal — o diff iria para a cópia errada,
# invisível para os gates da branch. O guard só age quando:
#   1. o diretório do projeto da sessão É uma worktree vinculada (git-dir ≠
#      git-common-dir), e
#   2. o alvo do Edit/Write resolve para DENTRO do working tree principal
#      (o dono do .git comum) e FORA da worktree da sessão.
# Todo o resto passa sem ruído: repo normal, paths fora de qualquer repo,
# scratchpad, memória, o próprio working tree da sessão.
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem input parseável,
# sem git ou qualquer erro → exit 0, nunca travar o fluxo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null || true)"
[ -z "$file_path" ] && exit 0

proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "$proj" ] || exit 0

# Path relativo resolve contra o cwd reportado no input (fallback: cwd do hook).
case "$file_path" in
  /*) : ;;
  *)
    base="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
    [ -d "$base" ] || base="$(pwd)"
    file_path="$base/$file_path"
    ;;
esac

# canon <path> — física e sem exigir que o arquivo exista (canoniza o diretório
# existente mais profundo e reanexa o resto). Falhou → devolve vazio.
canon() {
  local p="$1" rest=""
  while [ ! -d "$p" ]; do
    rest="/$(basename "$p")$rest"
    p="$(dirname "$p")"
    [ "$p" = "/" ] && break
  done
  local abs
  abs="$(cd "$p" 2>/dev/null && pwd -P || true)"
  [ -z "$abs" ] && { echo ""; return; }
  [ "$abs" = "/" ] && abs=""
  printf '%s%s\n' "$abs" "$rest"
}

git_dir="$(git -C "$proj" rev-parse --git-dir 2>/dev/null || true)"
common_dir="$(git -C "$proj" rev-parse --git-common-dir 2>/dev/null || true)"
[ -z "$git_dir" ] || [ -z "$common_dir" ] && exit 0

git_dir="$(canon "$git_dir")"
common_dir="$(canon "$common_dir")"
[ -z "$git_dir" ] || [ -z "$common_dir" ] && exit 0

# Checkout principal (git-dir == common-dir) → não é worktree vinculada → sai.
[ "$git_dir" = "$common_dir" ] && exit 0

# Raiz do working tree principal: o diretório que contém o .git comum.
# Common dir que não termina em .git (repo bare/layout exótico) → não arriscar.
case "$common_dir" in
  */.git) main_root="$(dirname "$common_dir")" ;;
  *) exit 0 ;;
esac

proj_abs="$(canon "$proj")"
target="$(canon "$file_path")"
[ -z "$proj_abs" ] || [ -z "$target" ] || [ -z "$main_root" ] && exit 0

# Dentro da worktree da sessão → legítimo.
case "$target" in
  "$proj_abs"/*|"$proj_abs") exit 0 ;;
esac

# Dentro do working tree principal (mas fora do .git dele) → alvo errado: bloquear.
case "$target" in
  "$common_dir"/*) exit 0 ;;
  "$main_root"/*|"$main_root")
    reason="worktree-guard (keelson): esta sessão trabalha na worktree $proj_abs, mas o alvo desta edição está no CHECKOUT PRINCIPAL ($main_root): $target. Editar lá manda o diff para a cópia errada — fora da branch e dos gates deste run. Use o caminho equivalente dentro da worktree. Se a edição no checkout principal for INTENCIONAL, diga isso ao humano e peça a ele para aprovar/repetir a operação."
    jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
    exit 0
    ;;
esac

exit 0
