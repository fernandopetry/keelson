#!/usr/bin/env bash
# run.sh — suíte de regressão do close-task.sh (decisão 4.476).
#
# Slug sintético em mktemp (TASK no template canônico, TASK-INDEX com checklist,
# INDEX com a tabela PLANs). Regras provadas: dry-run não grava; closure escreve
# Status/Histórico/checklist/gates e nada mais (mesma contagem de linhas, headings
# intactos); TASK-INDEX marcado; célula Tasks recomputada (🟡 parcial → ✅ todas) e
# Última atualização; index-check sem index-tasks-cell; idempotência; artefato fora do
# template → exit 3 sem gravar; TASK ausente → exit 3; sem --sha → exit 2; --inicio
# ausente deixa o campo intocado; Jira só com --jira.
#
# Uso: scripts/tests/close-task/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL
HERE="$(cd "$(dirname "$0")" && pwd)"
CT="$HERE/../../close-task.sh"
[ -f "$CT" ] || { echo "ERRO: close-task.sh não encontrado em $CT" >&2; exit 1; }
TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT
fail=0; total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }
caso()  { total=$((total + 1)); }

S="$TMP/docs/jira"; mkdir -p "$S/tasks" "$S/plans" "$S/specs"
task_file() { # $1 caminho · $2 id · $3 status
  cat > "$1" <<EOT
# $2: Fazer algo

**Slug**: jira
**Pertence a**: PLAN-001
**Status**: $3

## Dependências

- **Depende de**: nenhuma

## Critérios de pronto

- [ ] Testes cobrem AC-001-001 — verificação executável: \`make test\` → OK

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa>
EOT
}
task_file "$S/tasks/TASK-001-001-extrator.md" TASK-001-001 "In Progress"
task_file "$S/tasks/TASK-001-002-leitor.md"   TASK-001-002 "Todo"
printf '# PLAN-001: x\n\n**Status**: Approved\n' > "$S/plans/PLAN-001-x.md"
printf '# SPEC-001: x\n\n**Status**: Approved\n' > "$S/specs/SPEC-001-x.md"
cat > "$S/tasks/TASK-001-INDEX.md" <<'EOT'
# TASK-001-INDEX

### Wave 1 (paralelizável)
- [ ] TASK-001-001 ⏸ Todo
- [ ] TASK-001-002 ⏸ Todo
EOT
cat > "$S/INDEX.md" <<'EOT'
# INDEX — jira

**Última atualização**: 2026-08-01T10:00:00-03:00

## Capacidades

### Implementadas
- nenhuma

### Em desenvolvimento
- Extração (SPEC-001, PLAN-001, ⏸ 0/2 tasks Done)

## SPECs

| ID | Título | Status | Data |
|---|---|---|---|
| SPEC-001 | x | Approved | 2026-08-01 |

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|---|---|---|---|---|
| PLAN-001 | SPEC-001 | extração | 0/2 ⏸ | Approved |

## Histórico recente

- 2026-08-01: criado
EOT
T1="$S/tasks/TASK-001-001-extrator.md"; T2="$S/tasks/TASK-001-002-leitor.md"
before="$(cat "$T1")"; ibefore="$(cat "$S/INDEX.md")"

# --- dry-run não grava ---
caso; out="$(bash "$CT" "$S" TASK-001-001 --sha abc1234 --dry-run 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q '^dry-run: nada gravado$' && [ "$(cat "$T1")" = "$before" ] && [ "$(cat "$S/INDEX.md")" = "$ibefore" ]; then ok "dry-run: plano impresso, nada gravado"; else falha "dry-run rc=$rc [$out]"; fi
caso; printf '%s\n' "$out" | grep -q '^index: Tasks PLAN-001 = 1/2 🟡' && ok "dry-run: célula prevista 1/2 🟡" || falha "dry-run célula: [$out]"

# --- closure da 001 ---
caso; out="$(bash "$CT" "$S" TASK-001-001 --sha abc1234 --inicio 2026-10-12T10:00:00-0300 --fim 2026-10-12T11:00:00-0300 --jira OPS-1 --gate8 "n/a — sem área sensível" --gate9 "consolidado (FEAT-001-001)" 2>&1)"; rc=$?
[ $rc -eq 0 ] && ok "closure 001: exit 0" || falha "closure 001 rc=$rc [$out]"
caso; grep -q '^\*\*Status\*\*: Done$' "$T1" && ok "Status Done" || falha "Status"
caso; grep -q '^\*\*Data início\*\*: 2026-10-12T10:00:00-0300$' "$T1" && grep -q '^\*\*Data conclusão\*\*: 2026-10-12T11:00:00-0300$' "$T1" && grep -q '^\*\*Commit SHA\*\*: abc1234$' "$T1" && grep -q '^\*\*Jira\*\*: OPS-1$' "$T1" && ok "Histórico: 4 campos preenchidos" || falha "Histórico: [$(grep -n 'Data\|SHA\|Jira' "$T1")]"
caso; [ "$(grep -c '^- \[x\] ' "$T1")" = "8" ] && grep -q '^- \[x\] Segurança (gate 8): n/a — sem área sensível$' "$T1" && grep -q '^- \[x\] Comportamento (gate 9): consolidado (FEAT-001-001)$' "$T1" && ok "checklist: 6 fixos + gate 8 + gate 9 marcados" || falha "checklist: $(grep -c '^- \[x\] ' "$T1")"
caso; grep -q '^- \[ \] Testes cobrem AC-001-001' "$T1" && ok "Critérios de pronto intocados" || falha "critério tocado"
caso; [ "$(printf '%s\n' "$before" | wc -l | tr -d ' ')" = "$(wc -l < "$T1" | tr -d ' ')" ] && [ "$(printf '%s\n' "$before" | grep '^#')" = "$(grep '^#' "$T1")" ] && ok "invariante 4.259: linhas e headings iguais" || falha "invariante"
caso; grep -q '^- \[x\] TASK-001-001 ✅ Done$' "$S/tasks/TASK-001-INDEX.md" && grep -q '^- \[ \] TASK-001-002 ⏸ Todo$' "$S/tasks/TASK-001-INDEX.md" && ok "TASK-INDEX: só a 001 marcada" || falha "TASK-INDEX: [$(cat "$S/tasks/TASK-001-INDEX.md")]"
caso; grep -q '^| PLAN-001 | SPEC-001 | extração | 1/2 🟡 | Approved |$' "$S/INDEX.md" && ok "INDEX: célula 1/2 🟡" || falha "INDEX célula: [$(grep PLAN-001 "$S/INDEX.md")]"
caso; grep -q '^\*\*Última atualização\*\*: 2026-10-12T11:00:00-0300$' "$S/INDEX.md" && ok "INDEX: Última atualização" || falha "Última atualização"
caso; if printf '%s\n' "$out" | grep -q 'index-tasks-cell'; then falha "index-check acusou tasks-cell"; else ok "index-check: sem index-tasks-cell"; fi

# --- idempotência ---
caso; snap="$(cat "$T1" "$S/INDEX.md" "$S/tasks/TASK-001-INDEX.md")"
bash "$CT" "$S" TASK-001-001 --sha abc1234 --inicio 2026-10-12T10:00:00-0300 --fim 2026-10-12T11:00:00-0300 --jira OPS-1 --gate8 "n/a — sem área sensível" --gate9 "consolidado (FEAT-001-001)" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && [ "$(cat "$T1" "$S/INDEX.md" "$S/tasks/TASK-001-INDEX.md")" = "$snap" ] && ok "idempotente: segunda rodada não muda nada" || falha "idempotência rc=$rc"

# --- closure da 002 sem --inicio/--jira: campos intocados; célula ✅ ---
caso; bash "$CT" "$S" TASK-001-002 --sha def5678 --fim 2026-10-12T12:00:00-0300 >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && grep -q '^\*\*Data início\*\*: $' "$T2" && grep -q '^\*\*Jira\*\*: $' "$T2" && grep -q '^\*\*Commit SHA\*\*: def5678$' "$T2" && ok "002: inicio/jira intocados sem flag, SHA gravado" || falha "002 rc=$rc"
caso; grep -q '^- \[ \] Segurança (gate 8):' "$T2" && ok "002: gate 8 intocado sem --gate8" || falha "002 gate8"
caso; grep -q '| 2/2 ✅ |' "$S/INDEX.md" && ok "INDEX: célula 2/2 ✅" || falha "INDEX 2/2: [$(grep PLAN-001 "$S/INDEX.md")]"

# --- recusas ---
caso; bash "$CT" "$S" TASK-001-009 --sha x >/dev/null 2>&1; [ $? -eq 3 ] && ok "TASK ausente → exit 3" || falha "TASK ausente"
caso; bash "$CT" "$S" TASK-001-001 >/dev/null 2>&1; [ $? -eq 2 ] && ok "sem --sha → exit 2" || falha "sem sha"
caso; bash "$CT" "$S" TASK-1-1 --sha x >/dev/null 2>&1; [ $? -eq 2 ] && ok "id inválido → exit 2" || falha "id inválido"
caso; printf '# TASK-001-003: legado\n\n**Status**: Todo\n\nsem histórico\n' > "$S/tasks/TASK-001-003-legado.md"
leg="$(cat "$S/tasks/TASK-001-003-legado.md")"; bash "$CT" "$S" TASK-001-003 --sha x >/dev/null 2>&1; rc=$?
[ $rc -eq 3 ] && [ "$(cat "$S/tasks/TASK-001-003-legado.md")" = "$leg" ] && ok "fora do template → exit 3, nada gravado" || falha "legado rc=$rc"

echo "---"
if [ "$fail" -gt 0 ]; then echo "close-task: $fail de $total casos falharam"; exit 1; fi
echo "close-task: $total casos verdes"
exit 0
