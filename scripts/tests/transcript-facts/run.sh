#!/usr/bin/env bash
# run.sh — suíte do transcript-facts.sh (decisão 4.434): transcripts sintéticos provam
# `escreveu_codigo` (Edit sob code path · Edit fora · developer despachado · git commit no
# Bash · sem --code-paths qualquer Edit conta) e `em_voo` (Agent em background lançado e
# notificado → 0 · lançado sem notificação → 1 com o subagent_type · Bash em background
# idem · notificação em attachment queued_command conta) · transcript ausente → exit 2 e
# stdout vazio (o hook chamador volta ao comportamento anterior).
#
# Uso: scripts/tests/transcript-facts/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.
# shellcheck disable=SC2034  # out/st são lidos dentro da string avaliada por fato()
set -u
LC_ALL=C; export LC_ALL
HERE="$(cd "$(dirname "$0")" && pwd)"
TF="$HERE/../../transcript-facts.sh"
[ -f "$TF" ] || { echo "ERRO: transcript-facts.sh não encontrado" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "transcript-facts: AVISO — python3 ausente; pulando." >&2; exit 0; }
TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT
fail=0; total=0
ok() { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }
bash -n "$TF" || { echo "FAIL bash -n"; exit 1; }
echo "ok   bash -n transcript-facts.sh"

# helpers de linha do transcript
ass_use() { # id name input-json
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":%s}]}}\n' "$1" "$2" "$3"
}
usr_result() { # tool_use_id texto
  printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"%s","content":"%s"}]}}\n' "$1" "$2"
}
usr_text() { printf '{"type":"user","message":{"content":"%s"}}\n' "$1"; }
att_notif() { printf '{"type":"attachment","attachment":{"type":"queued_command","prompt":"<task-notification><task-id>%s</task-id></task-notification>"}}\n' "$1"; }
fato() { total=$((total + 1)); if eval "$2"; then ok "$1"; else falha "$1"; fi; }
campo() { bash "$TF" "$1" ${2:+--code-paths "$2"} 2>/dev/null | awk -F'\t' -v k="$3" '$1==k{print $2; exit}'; }

# 1. Edit sob code path → 1 (edit)
T1="$TMP/t1.jsonl"; { usr_text "oi"; ass_use u1 Edit '{"file_path":"/repo/src/a.php","old_string":"x","new_string":"y"}'; } > "$T1"
fato "edit-sob-code-path-escreveu" '[ "$(campo "$T1" src escreveu_codigo)" = "1" ]'
# 2. Edit fora do code path → 0
T2="$TMP/t2.jsonl"; { ass_use u1 Edit '{"file_path":"/repo/docs/x/INDEX.md","old_string":"x","new_string":"y"}'; ass_use u2 Write '{"file_path":"thoughts/local/a.md","content":"z"}'; } > "$T2"
fato "edit-fora-do-code-path-nao-escreveu" '[ "$(campo "$T2" src escreveu_codigo)" = "0" ]'
# 3. sem --code-paths: .md e thoughts/ não contam; qualquer outro arquivo conta
fato "sem-code-paths-md-e-thoughts-nao-contam" '[ "$(campo "$T2" "" escreveu_codigo)" = "0" ]'
T3="$TMP/t3.jsonl"; { ass_use u1 Edit '{"file_path":"lib/x.php","old_string":"a","new_string":"b"}'; } > "$T3"
fato "sem-code-paths-outro-arquivo-conta" '[ "$(campo "$T3" "" escreveu_codigo)" = "1" ]'
# 4. developer despachado → 1
T4="$TMP/t4.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:developer","prompt":"Implementar TASK-001-001"}'; } > "$T4"
fato "developer-despachado-escreveu" '[ "$(campo "$T4" src escreveu_codigo)" = "1" ]'
# 5. outro agent (reviewer) não conta
T5="$TMP/t5.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:code-reviewer","prompt":"Gates 1-7"}'; } > "$T5"
fato "reviewer-despachado-nao-escreveu" '[ "$(campo "$T5" src escreveu_codigo)" = "0" ]'
# 6. git commit no Bash → 1; git status não
T6="$TMP/t6.jsonl"; { ass_use u1 Bash '{"command":"git status --porcelain"}'; ass_use u2 Bash '{"command":"git commit -q -m \"feat: x\" -- src/a.php"}'; } > "$T6"
fato "git-commit-no-bash-escreveu" '[ "$(campo "$T6" src escreveu_codigo)" = "1" ]'
T7="$TMP/t7.jsonl"; { ass_use u1 Bash '{"command":"git status && git log --oneline -3"}'; } > "$T7"
fato "git-so-leitura-nao-escreveu" '[ "$(campo "$T7" src escreveu_codigo)" = "0" ]'
# 8. Agent em background lançado e notificado → 0 em voo
T8="$TMP/t8.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:scribe","run_in_background":true,"prompt":"x"}'; usr_result u1 "Async agent launched successfully. agentId: abc123"; usr_text "<task-notification><task-id>abc123</task-id></task-notification>"; } > "$T8"
fato "background-notificado-zero-em-voo" '[ "$(campo "$T8" "" agentes_em_voo)" = "0" ]'
# 9. lançado sem notificação → 1 em voo com o tipo
T9="$TMP/t9.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:tracker-sync","run_in_background":true,"prompt":"x"}'; usr_result u1 "Async agent launched successfully. agentId: def456"; } > "$T9"
fato "background-sem-notificacao-em-voo" '[ "$(campo "$T9" "" agentes_em_voo)" = "1" ]'
fato "em-voo-carrega-o-tipo" 'bash "$TF" "$T9" | grep -q "^em_voo	def456	keelson:tracker-sync$"'
# 10. Bash em background idem; notificação via attachment conta
T10="$TMP/t10.jsonl"; { ass_use u1 Bash '{"command":"make test","run_in_background":true}'; usr_result u1 "Command running in background with ID: b789"; ass_use u2 Bash '{"command":"sleep 1","run_in_background":true}'; usr_result u2 "Command running in background with ID: b790"; att_notif b789; } > "$T10"
fato "bash-background-um-em-voo" '[ "$(campo "$T10" "" agentes_em_voo)" = "1" ]'
fato "attachment-notifica" '! bash "$TF" "$T10" | grep -q "b789"'
# 10b. sed -i e redirecionamento para code path contam; git checkout também
T10b="$TMP/t10b.jsonl"; { ass_use u1 Bash '{"command":"sed -i \"s/a/b/\" src/x.py"}'; } > "$T10b"
fato "sed-i-escreveu" '[ "$(campo "$T10b" src escreveu_codigo)" = "1" ]'
T10c="$TMP/t10c.jsonl"; { ass_use u1 Bash '{"command":"cat a > src/novo.py"}'; } > "$T10c"
fato "redirect-para-code-path-escreveu" '[ "$(campo "$T10c" src escreveu_codigo)" = "1" ]'
T10d="$TMP/t10d.jsonl"; { ass_use u1 Bash '{"command":"cat a > thoughts/local/x.txt"}'; } > "$T10d"
fato "redirect-fora-nao-escreveu" '[ "$(campo "$T10d" src escreveu_codigo)" = "0" ]'
# 10e. TaskOutput colhe (4.400); queue-operation notifica
ass_use_ts() { printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":%s}]}}\n' "$1" "$2" "$3" "$4"; }
usr_result_ts() { printf '{"type":"user","timestamp":"%s","message":{"content":[{"type":"tool_result","tool_use_id":"%s","content":"%s"}]}}\n' "$1" "$2" "$3"; }
T10e="$TMP/t10e.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:qa","run_in_background":true,"prompt":"x"}'; usr_result u1 "Async agent launched successfully. agentId: qa1"; ass_use u2 TaskOutput '{"task_id":"qa1"}'; } > "$T10e"
fato "taskoutput-colhe" '[ "$(campo "$T10e" "" agentes_em_voo)" = "0" ]'
T10f="$TMP/t10f.jsonl"; { ass_use u1 Agent '{"subagent_type":"keelson:qa","run_in_background":true,"prompt":"x"}'; usr_result u1 "Async agent launched successfully. agentId: qa2"; printf '{"type":"queue-operation","operation":"enqueue","content":"<task-notification><task-id>qa2</task-id></task-notification>"}\n'; } > "$T10f"
fato "queue-operation-notifica" '[ "$(campo "$T10f" "" agentes_em_voo)" = "0" ]'
# 10g. órfão: lançado há 3 h sem notificação NÃO conta (4.252); lançado agora conta
agora="$(python3 -c 'from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"))')"
velho="$(python3 -c 'from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(hours=3)).strftime("%Y-%m-%dT%H:%M:%S.000Z"))')"
T10g="$TMP/t10g.jsonl"; { ass_use_ts "$velho" u1 Agent '{"subagent_type":"keelson:developer","run_in_background":true,"prompt":"x"}'; usr_result_ts "$velho" u1 "Async agent launched successfully. agentId: orf1"; } > "$T10g"
fato "orfao-velho-nao-conta" '[ "$(campo "$T10g" "" agentes_em_voo)" = "0" ]'
T10h="$TMP/t10h.jsonl"; { ass_use_ts "$agora" u1 Agent '{"subagent_type":"keelson:developer","run_in_background":true,"prompt":"x"}'; usr_result_ts "$agora" u1 "Async agent launched successfully. agentId: viv1"; } > "$T10h"
fato "lancado-agora-conta" '[ "$(campo "$T10h" "" agentes_em_voo)" = "1" ]'
# 10i. transcript do subagent parado há > 30 min → não conta; recente → conta
mkdir -p "$TMP/t10h/subagents"; : > "$TMP/t10h/subagents/agent-viv1.jsonl"; touch -t 202601010000 "$TMP/t10h/subagents/agent-viv1.jsonl"
fato "subagent-parado-nao-conta" '[ "$(campo "$T10h" "" agentes_em_voo)" = "0" ]'
touch "$TMP/t10h/subagents/agent-viv1.jsonl"
fato "subagent-recente-conta" '[ "$(campo "$T10h" "" agentes_em_voo)" = "1" ]'
# 11. ausente → exit 2, stdout vazio
out="$(bash "$TF" "$TMP/nao-existe.jsonl" 2>/dev/null)"; st=$?
fato "ausente-exit-2-vazio" '[ "$st" -eq 2 ] && [ -z "$out" ]'
# 12. linha ilegível não derruba
T12="$TMP/t12.jsonl"; { echo "isto não é json"; ass_use u1 Edit '{"file_path":"src/b.py","old_string":"","new_string":"x"}'; } > "$T12"
fato "linha-ilegivel-tolerada" '[ "$(campo "$T12" src escreveu_codigo)" = "1" ]'

echo "---"
[ "$fail" -gt 0 ] && { echo "transcript-facts: $fail de $total casos falharam"; exit 1; }
echo "transcript-facts: $total casos verdes"
