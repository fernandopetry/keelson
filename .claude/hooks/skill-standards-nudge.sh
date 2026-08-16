#!/usr/bin/env bash
# skill-standards-nudge — hook PostToolUse (Write|Edit) do REPO DE DESENVOLVIMENTO
# do keelson (tooling do mantenedor, fora do pacote — decisões 4.182/4.213).
#
# Quando um artefato de instrução (commands/*.md, agents/*.md, skills/**/*.md,
# .claude/skills/**/*.md) é criado ou editado, injeta UM lembrete por arquivo por
# sessão para rodar a skill /skill-standards antes do commit. Não bloqueia nada:
# é cutucada, não gate — o juízo de conteúdo é trabalho de LLM, não de script.
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem input parseável ou
# qualquer erro → exit 0, nunca travar o fluxo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

proj="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Só o repo dev do plugin — em consumidor este hook nem é distribuído, mas o
# guard protege worktrees/cópias.
{ [ -f "$proj/.claude-plugin/plugin.json" ] && \
  grep -q '"name"[[:space:]]*:[[:space:]]*"keelson"' "$proj/.claude-plugin/plugin.json" 2>/dev/null; } || exit 0

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tool_name" in
  Write|Edit) : ;;
  *) exit 0 ;;
esac

fpath="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -n "$fpath" ] || exit 0
case "$fpath" in
  *.md) : ;;
  *) exit 0 ;;
esac

# Caminho relativo ao repo (aceita absoluto ou relativo).
rel="${fpath#"$proj"/}"
case "$rel" in
  .claude/worktrees/*) exit 0 ;;  # cópias integrais do repo — fora
  commands/*|agents/*|skills/*|.claude/skills/*) : ;;
  *) exit 0 ;;
esac

# Anti-renudge: um lembrete por arquivo por sessão (janela append-only, 4.141).
git_dir="$(git -C "$proj" rev-parse --absolute-git-dir 2>/dev/null || true)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "sem-sessao"' 2>/dev/null || true)"
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-skill-standards.recent"
  fingerprint="$(printf '%s\n%s' "$session_id" "$rel" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ]; then
    if [ -f "$marker" ] && grep -qxF "$fingerprint" "$marker" 2>/dev/null; then
      exit 0
    fi
    printf '%s\n' "$fingerprint" >> "$marker" 2>/dev/null || true
    # Janela limitada: 200 entradas bastam para qualquer leva; evita crescer para sempre.
    if [ "$(wc -l < "$marker" 2>/dev/null || echo 0)" -gt 200 ]; then
      tail -n 200 "$marker" > "$marker.tmp" 2>/dev/null && mv "$marker.tmp" "$marker" 2>/dev/null || true
    fi
  fi
fi

jq -n --arg rel "$rel" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("Artefato de instrução do keelson alterado (" + $rel + "): antes do commit desta leva, rode a skill /skill-standards sobre ele (roteamento do CLAUDE.md, decisão 4.212 — inclui checar o frescor do digest da doc Anthropic). Um lembrete por arquivo por sessão.")
  }
}'
exit 0
