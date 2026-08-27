#!/usr/bin/env bash
# field-intake-nudge — hook UserPromptSubmit do REPO DE DESENVOLVIMENTO do keelson
# (tooling do mantenedor, fora do pacote — decisões 4.182/4.270).
#
# Quando o prompt do Diretor menciona marcador de insumo de campo de consumidor
# (PROPOSTA_PLUGIN, postmortem, LRN-<n>, "insumo/relato de campo"), injeta UM
# lembrete por sessão apontando a rota /field-intake (registro na inbox antes do
# parecer — 4.111). Não bloqueia nada: é cutucada, não gate — reconhecer se o
# material é mesmo insumo (e não conversa sobre o processo) é trabalho de LLM.
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

prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)"
[ -n "$prompt" ] || exit 0

# Marcadores fortes de insumo de campo. Cobertura declarada (4.270): relato do
# Diretor que não usa nenhum destes termos não dispara — o nudge reduz o furo,
# não o fecha; grep -i cobre variação de caixa, bash 3.2 não tem ${var,,}.
printf '%s' "$prompt" | grep -qiE 'PROPOSTA_PLUGIN|post-?mortem|LRN-[0-9]|(insumo|relato)s? de campo' || exit 0

# Anti-renudge: um lembrete por sessão (janela append-only, 4.141) — uma vez
# lembrada a rota, o sequenciador da skill assume; repetir a cada prompt é ruído.
git_dir="$(git -C "$proj" rev-parse --absolute-git-dir 2>/dev/null || true)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "sem-sessao"' 2>/dev/null || true)"
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-field-intake.recent"
  fingerprint="$(printf '%s\nfield-intake-nudge' "$session_id" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ]; then
    if [ -f "$marker" ] && grep -qxF "$fingerprint" "$marker" 2>/dev/null; then
      exit 0
    fi
    printf '%s\n' "$fingerprint" >> "$marker" 2>/dev/null || true
    # Janela limitada: 200 sessões bastam; evita crescer para sempre.
    if [ "$(wc -l < "$marker" 2>/dev/null || echo 0)" -gt 200 ]; then
      tail -n 200 "$marker" > "$marker.tmp" 2>/dev/null && mv "$marker.tmp" "$marker" 2>/dev/null || true
    fi
  fi
fi

jq -n '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "O prompt menciona marcador de insumo de campo de consumidor (postmortem, ledger, PROPOSTA_PLUGIN, LRN-n ou relato de campo). Se material de campo está chegando para parecer, a rota é a skill /field-intake — registro na proposal-inbox ANTES de qualquer parecer (4.111), reincidência e precedente (4.269). Se for só conversa sobre o processo, ignore este lembrete. Um lembrete por sessão (4.270)."
  }
}'
exit 0
