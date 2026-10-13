#!/usr/bin/env bash
# run.sh — suíte de regressão do scope-scan.sh (decisão 4.479).
#
# Slug sintético em mktemp: SPEC-001 Approved com multiplicação no Out-of-scope,
# SPEC-002 Draft com multiplicação no In-scope e persistência no Out-of-scope.
# Regras provadas: acerto no 4.2 e no 4.1 com Status e seção certos; termo sem acerto
# → saída vazia, exit 0; caixa e acento não distinguem; vários termos somam; bullet
# fora do §4 nunca entra; uso incorreto → exit 2.
#
# Uso: scripts/tests/scope-scan/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.
set -u
LC_ALL=C
export LC_ALL
HERE="$(cd "$(dirname "$0")" && pwd)"
SS="$HERE/../../scope-scan.sh"
[ -f "$SS" ] || { echo "ERRO: scope-scan.sh não encontrado em $SS" >&2; exit 1; }
TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT
fail=0; total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }
caso()  { total=$((total + 1)); }
S="$TMP/docs/calc"; mkdir -p "$S/specs"
cat > "$S/specs/SPEC-001-historico.md" <<'EOT'
# SPEC-001: Histórico

**Status**: Approved

## 1. Contexto
- Multiplicação citada fora do escopo não conta aqui.

## 4. Escopo
### 4.1 In-scope
- Operação subtração entre dois valores (`subtract(a, b)`).
- Consulta do histórico (`history()`).

### 4.2 Out-of-scope
- Persistência do histórico em disco ou banco.
- Outras operações além da subtração (multiplicação, divisão etc.).
- Interface de usuário/linha de comando.

## 5. Requisitos
- A Multiplicação aqui também não conta.
EOT
cat > "$S/specs/SPEC-002-multiplicacao.md" <<'EOT'
# SPEC-002: Multiplicação

**Status**: Draft

## 4. Escopo
### 4.1 In-scope
* Operação multiplicação (`multiply(a, b)`).
### 4.2 Out-of-scope
- Persistência do histórico.
EOT

caso; out="$(bash "$SS" "$S" multiplic)"
exp="$(printf 'SPEC-001\tApproved\t4.2\tOutras operações além da subtração (multiplicação, divisão etc.).\nSPEC-002\tDraft\t4.1\tOperação multiplicação (`multiply(a, b)`).')"
[ "$out" = "$exp" ] && ok "multiplic: 4.2 da Approved e 4.1 da Draft, nada fora do §4" || falha "multiplic: [$out]"
caso; out="$(bash "$SS" "$S" MULTIPLICAÇÃO)"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = "2" ] && ok "caixa e acento não distinguem" || falha "acento: [$out]"
caso; out="$(bash "$SS" "$S" divis)"
[ "$out" = "$(printf 'SPEC-001\tApproved\t4.2\tOutras operações além da subtração (multiplicação, divisão etc.).')" ] && ok "divis: só o 4.2 da SPEC-001" || falha "divis: [$out]"
caso; out="$(bash "$SS" "$S" persist comando)"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = "3" ] && ok "vários termos somam (persist ×2 + comando)" || falha "vários termos: [$out]"
caso; out="$(bash "$SS" "$S" exportacao)"; rc=$?
[ $rc -eq 0 ] && [ -z "$out" ] && ok "sem acerto → vazio, exit 0" || falha "sem acerto rc=$rc [$out]"
caso; bash "$SS" "$S" >/dev/null 2>&1; [ $? -eq 2 ] && ok "sem termo → exit 2" || falha "sem termo"
caso; bash "$SS" "$TMP/nao-existe" x >/dev/null 2>&1; [ $? -eq 2 ] && ok "dir inexistente → exit 2" || falha "dir inexistente"
caso; mkdir -p "$TMP/vazio/specs"; if out="$(bash "$SS" "$TMP/vazio" x)" && [ -z "$out" ]; then ok "slug sem SPEC → vazio, exit 0"; else falha "slug vazio"; fi

echo "---"
if [ "$fail" -gt 0 ]; then echo "scope-scan: $fail de $total casos falharam"; exit 1; fi
echo "scope-scan: $total casos verdes"
exit 0
