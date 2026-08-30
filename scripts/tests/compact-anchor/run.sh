#!/usr/bin/env bash
# run.sh — suíte de regressão do compact-anchor (decisões 4.146/4.314).
#
# Roda o hook de verdade (stdin JSON, python3). Regras provadas: pós-compact com
# run em andamento → fatos do disco reinjetados; ledger ativo contado (reported-*/
# fora da conta); nada em andamento → silêncio; source ≠ compact → silêncio;
# casa da sessão (4.314): run-state em thoughts/local/sessions/*/ aparece, e o
# ledger da PRÓPRIA sessão (payload session_id) soma com o legado.
#
# Uso: scripts/tests/compact-anchor/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/compact-anchor.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v python3 >/dev/null 2>&1; then
  echo "compact-anchor: AVISO — python3 ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

run_state() { # dir-do-run-state slug
  mkdir -p "$1"
  cat > "$1/run-state-$2.md" <<EOF
status: em_andamento
slug: $2
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: wave 2 em curso
sessao: sessao-x
EOF
}

roda() { # payload-json -> $TMP/out, $st
  printf '%s' "$1" | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO bash "$HOOK" > "$TMP/out" 2>/dev/null
  st=$?
}

contem() {
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then echo "ok   $1"; else
    echo "FAIL $1: saída não contém [$2]"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

silencio() {
  total=$((total + 1))
  if [ "$st" -ne 0 ] || [ -s "$TMP/out" ]; then
    echo "FAIL $1: esperava silêncio (exit $st)"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  else
    echo "ok   $1"
  fi
}

# 1. Run legado em andamento + ledger legado (2 ativos, 1 arquivado fora da conta)
D1="$TMP/c1"; run_state "$D1/thoughts/local" alfa
mkdir -p "$D1/thoughts/local/session-ledger/reported-20260801-120000"
printf 'x\n' > "$D1/thoughts/local/session-ledger/20260830-100000-gate-qa.md"
printf 'x\n' > "$D1/thoughts/local/session-ledger/20260830-100001-marco-tech-lead.md"
printf 'x\n' > "$D1/thoughts/local/session-ledger/reported-20260801-120000/20260801-110000-gate-qa.md"
roda "{\"source\": \"compact\", \"cwd\": \"$D1\"}"
contem "legado/ancora"  'Contexto recém-compactado'
contem "legado/slug"    'slug: alfa'
contem "legado/ledger"  '2 evento(s) ativo(s)'

# 2. source ≠ compact → silêncio
roda "{\"source\": \"startup\", \"cwd\": \"$D1\"}"
silencio "source-diverso"

# 3. Mesa limpa → silêncio
D3="$TMP/c3"; mkdir -p "$D3"
roda "{\"source\": \"compact\", \"cwd\": \"$D3\"}"
silencio "mesa-limpa"

# 4. Casa da sessão (4.314): run-state em sessions/*/ aparece na âncora
D4="$TMP/c4"
mkdir -p "$D4/thoughts/local/sessions/20260830-100000-sessaoz1"
printf 'sessao: sessao-z-11112222\niniciada: 2026-08-30T10:00:00-0300\nestado: ativa\nslugs: beta\n' \
  > "$D4/thoughts/local/sessions/20260830-100000-sessaoz1/session.meta"
run_state "$D4/thoughts/local/sessions/20260830-100000-sessaoz1" beta
roda "{\"source\": \"compact\", \"cwd\": \"$D4\"}"
contem "sessao/slug" 'slug: beta'

# 5. Casa da sessão: ledger da PRÓPRIA sessão soma com o legado
mkdir -p "$D4/thoughts/local/sessions/20260830-100000-sessaoz1/ledger"
printf 'x\n' > "$D4/thoughts/local/sessions/20260830-100000-sessaoz1/ledger/20260830-110000-gate-qa.md"
mkdir -p "$D4/thoughts/local/session-ledger"
printf 'x\n' > "$D4/thoughts/local/session-ledger/20260830-090000-marco-tech-lead.md"
roda "{\"source\": \"compact\", \"cwd\": \"$D4\", \"session_id\": \"sessao-z-11112222\"}"
contem "sessao/ledger-somado" '2 evento(s) ativo(s)'

# 6. Ledger de OUTRA sessão não entra na conta desta
roda "{\"source\": \"compact\", \"cwd\": \"$D4\", \"session_id\": \"sessao-outra-9999\"}"
contem "sessao/ledger-so-legado" '1 evento(s) ativo(s)'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "compact-anchor: $fail de $total casos falharam"
  exit 1
fi
echo "compact-anchor: $total casos verdes"
exit 0
