#!/usr/bin/env bash
# run.sh — suíte de regressão do next-id.sh (decisões 4.86/4.151).
#
# Fixtures montadas em diretório temporário (só nomes de arquivo importam para o
# alocador; o --check lê o cabeçalho **Brief**: das SPECs). Regras provadas:
# alocador único cruza tipos (max de SPEC/PLAN/BRIEF/TASK), buraco não se preenche,
# épico datado fica fora, XXX de task é por MMM, pareamento brief↔SPEC.
#
# Uso: scripts/tests/next-id/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
NEXTID="$HERE/../../next-id.sh"

[ -f "$NEXTID" ] || { echo "ERRO: next-id.sh não encontrado em $NEXTID" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

check() { # nome exit-esperado saida-esperada -- args...
  name="$1"; wantexit="$2"; want="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  total=$((total + 1))
  got="$(bash "$NEXTID" "$@" 2>"$TMP/err")"
  st=$?
  if [ "$st" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $st (esperado $wantexit)"
    sed 's/^/  stderr: /' "$TMP/err"
    fail=$((fail + 1)); return
  fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $name: saída divergente"
    printf '  esperado: [%s]\n  obtido:   [%s]\n' "$want" "$got"
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

bash -n "$NEXTID" || { echo "FAIL bash -n next-id.sh"; exit 1; }
echo "ok   bash -n next-id.sh"

# --- slug vazio (recém-criado): tudo começa em 001 ---
S0="$TMP/vazio"; mkdir -p "$S0/specs"
check alloc-vazio 0 "001" -- "$S0" alloc
check task-vazio  0 "001" -- "$S0" task 001

# --- slug povoado: alocador único cruza tipos (4.86) ---
S1="$TMP/povoado"
mkdir -p "$S1/specs" "$S1/plans" "$S1/briefs" "$S1/tasks"
touch "$S1/specs/SPEC-001-login.md" \
      "$S1/plans/PLAN-002-login.md" \
      "$S1/briefs/BRIEF-001.md" \
      "$S1/briefs/BRIEF-004-ajuste-menu-avulso.md" \
      "$S1/tasks/TASK-002-001-endpoint.md" \
      "$S1/tasks/TASK-002-003-tela.md" \
      "$S1/tasks/TASK-002-INDEX.md"
# max entre {001, 002, 001, 004, 002} = 4 → próximo 005 (o buraco 003 NÃO se preenche)
check alloc-cruzado 0 "005" -- "$S1" alloc
# XXX por MMM: TASK-002 tem 001 e 003 → próximo 004 (buraco não se preenche)
check task-por-mmm 0 "004" -- "$S1" task 002
check task-sem-zero-pad 0 "004" -- "$S1" task 2
# MMM sem task nenhuma → 001
check task-mmm-virgem 0 "001" -- "$S1" task 007

# --- épico datado fica fora da numeração ---
S2="$TMP/com-epico"
mkdir -p "$S2/specs" "$S2/briefs"
touch "$S2/specs/SPEC-003-relatorios.md" \
      "$S2/briefs/BRIEF-2026-08-06-plataforma-lms-epic.md"
check alloc-ignora-epico 0 "004" -- "$S2" alloc

# --- --check: pareamento brief ↔ SPEC ---
S3="$TMP/pareamento"
mkdir -p "$S3/specs" "$S3/briefs"
cat > "$S3/specs/SPEC-005-perfil.md" <<'EOF'
# SPEC-005: Perfil

**Status**: Draft
**Brief**: BRIEF-005
EOF
touch "$S3/briefs/BRIEF-005.md"
cat > "$S3/specs/SPEC-006-conta.md" <<'EOF'
# SPEC-006: Conta

**Status**: Draft
**Brief**: BRIEF-004
EOF
cat > "$S3/specs/SPEC-007-senha.md" <<'EOF'
# SPEC-007: Senha

**Status**: Draft
**Brief**: BRIEF-007
EOF
cat > "$S3/specs/SPEC-008-sem-brief.md" <<'EOF'
# SPEC-008: Sem brief

**Status**: Draft
EOF
check pareamento 0 "WARNING	spec-brief-divergente	SPEC-006-conta.md declara Brief BRIEF-004 (pareamento 1:1 esperava BRIEF-006 — 4.86)
WARNING	spec-brief-orfao	SPEC-007-senha.md declara Brief BRIEF-007 mas briefs/BRIEF-007*.md nao existe" -- "$S3" --check

# slug pareado sem defeito sai limpo
S4="$TMP/pareamento-ok"
mkdir -p "$S4/specs" "$S4/briefs"
cat > "$S4/specs/SPEC-001-ok.md" <<'EOF'
# SPEC-001: Ok

**Brief**: BRIEF-001
EOF
touch "$S4/briefs/BRIEF-001.md"
check pareamento-limpo 0 "" -- "$S4" --check

# --- uso incorreto ---
total=$((total + 1))
bash "$NEXTID" "$TMP/nao-existe" alloc >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   dir-inexistente-exit-2"
else echo "FAIL dir-inexistente-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$NEXTID" "$S1" task abc >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   mmm-nao-numerico-exit-2"
else echo "FAIL mmm-nao-numerico-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$NEXTID" "$S1" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-acao-exit-2"
else echo "FAIL sem-acao-exit-2: exit $st"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "next-id: $fail de $total casos falharam"
  exit 1
fi
echo "next-id: $total casos verdes"
exit 0
