#!/usr/bin/env bash
# agent-guard — hook PreToolUse (Task|Agent) que garante que trabalho do ciclo
# keelson seja despachado aos agents do ELENCO (keelson:*), não a um subagent
# genérico com prompt improvisado (decisão 4.42).
#
# O modelo escolhe o subagent_type a cada spawn; este guard corrige o desvio no
# ato, uma única vez por chamada (anti-renudge por fingerprint):
#   - subagent_type keelson:* → passa (é o elenco).
#   - genérico com prompt "cara de trabalho de papel" (gates, crítica de mérito,
#     modos do po/qa, implementar TASK...) → deny com instrução de refazer a
#     chamada com o agent certo.
#   - validators são SKILLS (fora do elenco): spawn genérico é legítimo QUANDO o
#     briefing cita o SKILL.md canônico (validator-protocol §2) — sem citar → deny.
# Exploração/pesquisa genéricas passam: o fingerprint exige verbo de papel, não
# a mera menção a um artefato SPEC-/PLAN-/TASK-.
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem ficha, sem input
# parseável ou qualquer erro → exit 0, nunca travar o fluxo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

# Só age em projeto keelson: ficha na raiz (consumidor) ou o repo dev do plugin.
proj="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ ! -f "$proj/keelson.config.json" ] && \
   ! { [ -f "$proj/.claude-plugin/plugin.json" ] && grep -q '"name"[[:space:]]*:[[:space:]]*"keelson"' "$proj/.claude-plugin/plugin.json" 2>/dev/null; }; then
  exit 0
fi

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tool_name" in
  Task|Agent) : ;;
  *) exit 0 ;;
esac

stype="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)"
case "$stype" in
  keelson:*) exit 0 ;;   # elenco do keelson → sempre legítimo
esac

texto="$(printf '%s' "$input" | jq -r '((.tool_input.description // "") + " " + (.tool_input.prompt // ""))' 2>/dev/null || true)"
[ -z "${texto// /}" ] && exit 0

# --- validators (skills): genérico passa SE o briefing cita o SKILL.md canônico ---
if printf '%s' "$texto" | grep -Eiq 'spec-validator|plan-validator|task-validator'; then
  if printf '%s' "$texto" | grep -q 'SKILL\.md'; then
    exit 0
  fi
  motivo_extra="Este spawn parece executar um VALIDATOR (skill do keelson): o briefing DEVE citar o caminho do SKILL.md canônico da skill (\${CLAUDE_PLUGIN_ROOT}/skills/<skill>/SKILL.md) com instrução de aplicá-lo integralmente e devolver o output no formato do validator-protocol — validar 'de memória' usa outra régua."
else
  # --- trabalho de papel do elenco: exige verbo de papel, não só menção a artefato ---
  printf '%s' "$texto" | grep -Eiq \
    'crítica de mérito|quality gates|gates 1.7|gate [89]([^0-9]|$)|modo aprovação|modo aceitação|modo resolução|modo pré-código|contra o brief|relatório de aceitação|impleme?nt(e|ar) a TASK|corrija os achados|revis(e|ão) (o diff|de segurança)|decomp(onha|osição).*(épico|epico)' \
    || exit 0
  motivo_extra="Este spawn parece executar trabalho de um PAPEL do time keelson com um agent genérico — o agent do elenco carrega a doutrina do papel (input, gates, formato de report), e o genérico não."
fi

# Anti-renudge: mesma chamada (tipo + texto) só é bloqueada uma vez — a segunda
# tentativa passa (válvula para uso genérico intencional, ex.: exploração).
git_dir="$(git -C "$proj" rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-agent-guard.last"
  fingerprint="$(printf '%s\n%s' "$stype" "$texto" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

reason="$(cat <<EOF
agent-guard (keelson, decisão 4.42): subagent_type "${stype:-ausente}" para trabalho do ciclo keelson.

${motivo_extra}

Refaça a chamada com o agent correto do elenco: keelson:developer (implementar TASK) · keelson:code-reviewer (gates 1–7) · keelson:qa (gate 9 / modo pré-código) · keelson:security-engineer (gate 8) · keelson:product-analyst (crítica de mérito) · keelson:po (modos aprovação/aceitação/resolução) · keelson:pm (decomposição de épico). Validators (spec/plan/task-validator) são skills: o spawn genérico é aceito quando o briefing cita o SKILL.md canônico.

Se o uso genérico for INTENCIONAL (exploração, pesquisa, tarefa fora do ciclo), repita a chamada — este aviso não se repete para esta mesma chamada.
EOF
)"

if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi

jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
