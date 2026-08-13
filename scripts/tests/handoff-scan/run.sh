#!/usr/bin/env bash
# run.sh — suíte de regressão do handoff-scan.sh (decisão 4.154).
#
# Monta repo git com worktree adicional e handoffs sintéticos (§8.2). Regras provadas:
# só `status: Pendente` entra, contagem de V* pendentes (Evidência sem ✅/❌),
# varredura por worktree com branch, docsRoot da ficha, --no-worktrees.
#
# Uso: scripts/tests/handoff-scan/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige git.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HS="$HERE/../../handoff-scan.sh"

[ -f "$HS" ] || { echo "ERRO: handoff-scan.sh não encontrado" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
TMP="$(cd "$TMP" && pwd -P)"   # caminho físico (macOS: /var → /private/var no git worktree)
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

R="$TMP/repo"
mkdir -p "$R"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" checkout -qb main; }
git -C "$R" config user.email t@t
git -C "$R" config user.name t
printf '{ "docsRoot": "docs" }\n' > "$R/keelson.config.json"
git -C "$R" add -A && git -C "$R" commit -qm base
# worktree criada ANTES dos handoffs: cada worktree só vê os seus (uncommitted)
git -C "$R" worktree add -q -b feat/crm "$TMP/wt-crm" main
mkdir -p "$R/docs/lms/handoffs"
cat > "$R/docs/lms/handoffs/HANDOFF-PLAN-002.md" <<'EOF'
---
id: HANDOFF-PLAN-002
slug: lms
branch: feat/lms-relatorios
status: Pendente
criado: 2026-08-06T10:00:00-0300
origem: PLAN-002
motivo: app_fora_do_ar
sonda: curl -m 5 http://localhost:8080 → connection refused
---

# Handoff de verificação de tela — relatórios

## 4. Roteiro de verificação (itens pendentes)

### V1 — Grid carrega (AC-002-001)
- **Tela/rota**: /relatorios
- **Passos**: 1) abrir 2) conferir
- **Esperado**: grid com dados do dia
- **Evidência**: ✅ verificado em 2026-08-06 — grid ok

### V2 — Export desabilitado (AC-002-002)
- **Tela/rota**: /relatorios
- **Passos**: 1) abrir 2) conferir botão
- **Esperado**: botão de export ausente
- **Evidência**: _(preencher na verificação)_
EOF
cat > "$R/docs/lms/handoffs/HANDOFF-2026-08-01-menu.md" <<'EOF'
---
id: HANDOFF-2026-08-01-menu
slug: lms
status: Concluído
---

### V1 — Menu
- **Evidência**: ✅ ok
EOF
mkdir -p "$TMP/wt-crm/docs/crm/handoffs"
cat > "$TMP/wt-crm/docs/crm/handoffs/HANDOFF-PLAN-001.md" <<'EOF'
---
id: HANDOFF-PLAN-001
slug: crm
status: Pendente
---

### V1 — Cadastro (AC-001-001)
- **Evidência**: _(preencher na verificação)_
EOF

total=$((total + 1))
got="$(bash "$HS" --repo "$R" 2>"$TMP/err")"; st=$?
want="handoff	$R	main	lms	HANDOFF-PLAN-002	1/2
handoff	$TMP/wt-crm	feat/crm	crm	HANDOFF-PLAN-001	1/1"
if [ "$st" -eq 0 ] && [ "$got" = "$want" ]; then echo "ok   worktrees"
else echo "FAIL worktrees (exit $st)"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/  /'; fail=$((fail + 1)); fi

# --no-worktrees: só o diretório dado
total=$((total + 1))
got="$(bash "$HS" --repo "$TMP/wt-crm" --no-worktrees 2>/dev/null)"; st=$?
want="handoff	$TMP/wt-crm	-	crm	HANDOFF-PLAN-001	1/1"
if [ "$st" -eq 0 ] && [ "$got" = "$want" ]; then echo "ok   no-worktrees"
else echo "FAIL no-worktrees: [$got]"; fail=$((fail + 1)); fi

# repo sem handoff pendente → saída vazia, exit 0
R2="$TMP/limpo"; mkdir -p "$R2"
total=$((total + 1))
got="$(bash "$HS" --repo "$R2" --no-worktrees 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && [ -z "$got" ]; then echo "ok   sem-pendencia-vazio"
else echo "FAIL sem-pendencia-vazio (exit $st): [$got]"; fail=$((fail + 1)); fi

# uso incorreto
total=$((total + 1))
bash "$HS" --repo "$TMP/nao-existe" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   repo-inexistente-exit-2" || { echo "FAIL repo-inexistente-exit-2"; fail=$((fail + 1)); }

echo "---"
if [ "$fail" -gt 0 ]; then echo "handoff-scan: $fail de $total casos falharam"; exit 1; fi
echo "handoff-scan: $total casos verdes"
exit 0
