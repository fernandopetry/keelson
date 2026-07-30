#!/usr/bin/env bash
# noverify-guard — hook PreToolUse (Bash) que bloqueia o contorno de verificação
# via `git commit --no-verify` / `git push --no-verify`.
#
# Cenário real (decisão 4.66): sessão encontrou teste pré-existente vermelho na
# main, e em vez de reportar o bloqueio (TESTING.md, "Verificação que falha não
# se contorna") commitou com --no-verify em silêncio — a entrega saiu sem prova
# e sem rastro. A doutrina cobre o agente que a lê; este guard cobre o que não
# leu: pular hook de verificação é sempre um ato DECLARADO, nunca silencioso.
#
# Escape consciente e nomeado (mesma régua da 4.63): prefixar o comando com
# KEELSON_ALLOW_NO_VERIFY=1 — o humano que sabe por que está pulando diz isso
# no próprio comando, e o rastro fica no transcript.
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem input parseável
# ou qualquer erro → exit 0, nunca travar o fluxo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# Só interessa git commit/push carregando --no-verify no mesmo comando simples
# (sem atravessar | ; && — evita falso positivo de outro comando do pipeline).
printf '%s' "$cmd" | grep -Eq 'git[^|;&]*\b(commit|push)\b[^|;&]*--no-verify' || exit 0

# Escape nomeado: o humano assumiu o pulo explicitamente.
case "$cmd" in
  *KEELSON_ALLOW_NO_VERIFY=1*) exit 0 ;;
esac

reason="noverify-guard (keelson): --no-verify pula os hooks de verificação, e verificação que falha não se contorna — corrija a causa ou pare e reporte o bloqueio (TESTING.md, 'Verificação que falha não se contorna'; erro pré-existente → Blocked/furo_no_plano, nunca silêncio). Se o pulo for um ato consciente do humano, ele aprova repetindo o comando prefixado com KEELSON_ALLOW_NO_VERIFY=1."
jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
