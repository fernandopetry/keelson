#!/usr/bin/env bash
# run.sh — suíte de regressão do edge-diff.sh (decisões 4.117/4.154).
#
# Regras provadas: aresta derrubada pela reescrita é acusada (perdida), acréscimo é
# informativo, versão idêntica sai limpa (exit 0), ACs citados em critérios contam,
# modo --old sem git, arquivo não rastreado é exit 2 com causa.
#
# Uso: scripts/tests/edge-diff/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige git.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ED="$HERE/../../edge-diff.sh"

[ -f "$ED" ] || { echo "ERRO: edge-diff.sh não encontrado" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

R="$TMP/repo"
mkdir -p "$R/docs/lms/tasks"
git -C "$R" init -q
git -C "$R" config user.email t@t
git -C "$R" config user.name t

T="$R/docs/lms/tasks/TASK-002-001-grid.md"
cat > "$T" <<'EOF'
# TASK-002-001: Grid de relatórios

**Slug**: lms
**Pertence a**: PLAN-002
**Realiza (FRs)**: FR-002-001, FR-002-002
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-002-001
**Wave**: 2

## Dependências

- **Depende de**: TASK-002-000, TASK-001-003
- **Bloqueia**: TASK-002-002

## Critérios de pronto

- [ ] AC-002-001 coberto por teste de integração
- [ ] AC-002-002 coberto por teste de tela

## Roteiro do gate 9 (fixado ANTES do código)

- AC-002-003: abrir o grid e conferir a ordenação.
EOF
git -C "$R" add -A && git -C "$R" commit -qm base

# ---- reescrita que derruba arestas: perde 1 dep, 1 FR e 1 AC de critério ----
cat > "$T" <<'EOF'
# TASK-002-001: Grid de relatórios

**Slug**: lms
**Pertence a**: PLAN-002
**Realiza (FRs)**: FR-002-001
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-002-001
**Wave**: 2

## Dependências

- **Depende de**: TASK-002-000
- **Bloqueia**: TASK-002-002

## Critérios de pronto

- [ ] AC-002-001 coberto por teste de integração
- [ ] AC-002-004 coberto por teste novo

## Roteiro do gate 9 (fixado ANTES do código)

- AC-002-003: abrir o grid e conferir a ordenação.
EOF

total=$((total + 1))
got="$(bash "$ED" "$T" 2>"$TMP/err")"; st=$?
want="perdida	criterio	AC-002-002
perdida	depende-de	TASK-001-003
perdida	realiza	FR-002-002
acrescida	criterio	AC-002-004"
if [ "$st" -eq 1 ] && [ "$got" = "$want" ]; then echo "ok   arestas-perdidas"
else echo "FAIL arestas-perdidas (exit $st)"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/  /'; fail=$((fail + 1)); fi

# ---- versão idêntica → limpa ----
git -C "$R" checkout -q -- docs/lms/tasks/TASK-002-001-grid.md
total=$((total + 1))
got="$(bash "$ED" "$T" 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && [ -z "$got" ]; then echo "ok   identica-limpa"
else echo "FAIL identica-limpa (exit $st): [$got]"; fail=$((fail + 1)); fi

# ---- modo --old (sem depender de git) sobre um PLAN: cobre COMP e cobertura ----
OLDP="$TMP/plan-old.md"; NEWP="$TMP/plan-new.md"
cat > "$OLDP" <<'EOF'
# PLAN-002: Relatórios

## Cobertura

**SPEC referenciada**: SPEC-002

**FRs cobertos**:
- FR-002-001
- FR-002-002

## 3. Componentes

### COMP-002-001: Grid

**Realiza**: FR-002-001, FR-002-002
**Dependências**: COMP-002-000
EOF
sed 's/, FR-002-002$//; /^- FR-002-002$/d' "$OLDP" > "$NEWP"
total=$((total + 1))
got="$(bash "$ED" "$NEWP" --old "$OLDP" 2>/dev/null)"; st=$?
want="perdida	fr-coberto	FR-002-002
perdida	realiza(COMP-002-001)	FR-002-002"
if [ "$st" -eq 1 ] && [ "$got" = "$want" ]; then echo "ok   modo-old-plan"
else echo "FAIL modo-old-plan (exit $st)"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/  /'; fail=$((fail + 1)); fi

# ---- arquivo não rastreado → exit 2 com causa ----
N="$R/docs/lms/tasks/TASK-002-009-novo.md"
printf '# TASK-002-009: Novo\n' > "$N"
total=$((total + 1))
bash "$ED" "$N" >/dev/null 2>"$TMP/err"
st=$?
if [ "$st" -eq 2 ] && grep -q 'não rastreado' "$TMP/err"; then echo "ok   nao-rastreado-exit-2"
else echo "FAIL nao-rastreado-exit-2 (exit $st)"; sed 's/^/  /' "$TMP/err"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then echo "edge-diff: $fail de $total casos falharam"; exit 1; fi
echo "edge-diff: $total casos verdes"
exit 0
