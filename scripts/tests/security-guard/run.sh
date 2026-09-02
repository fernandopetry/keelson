#!/usr/bin/env bash
# run.sh — suíte de regressão do security-guard (decisões 4.103/4.252/4.314).
#
# Roda o hook de verdade (stdin JSON, jq, repo git sintético sem base main —
# a detecção cai no working tree e os untracked entram). Foco: o silenciador de
# ciclo formal (run-state ativo → a rede da sessão livre cala) nos DOIS layouts:
#   1. controle positivo: mudança sensível (sensitiveGlobs + conteúdo), sem
#      run-state → block;
#   2. run-state LEGADO em andamento → silêncio;
#   3. run-state na casa da sessão (thoughts/local/sessions/*/ — 4.314) → silêncio;
#   4. run-state de OUTRA sessão (4.252) → NÃO silencia, block;
#   5–7. veredito no ledger (4.365): evento `gate` do security-engineer mais novo que
#      todo arquivo sensível → silêncio; arquivo editado depois do veredito e veredito
#      de outro gate → cutuca.
# Cada caso usa repo próprio (o anti-renudge de .git/ não vaza entre casos).
#
# Uso: scripts/tests/security-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/security-guard.sh"
LEDGER="$HERE/../../ledger.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "security-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

repo() { # $1 = dir — repo git com ficha e mudança sensível (glob + conteúdo)
  mkdir -p "$1/src"
  ( cd "$1" && git init -q . )
  printf '{ "sensitiveGlobs": ["src/**"] }\n' > "$1/keelson.config.json"
  printf '<?php $senha = password_hash($password, PASSWORD_ARGON2ID);\n' > "$1/src/auth.php"
}

run_state() { # dir-do-run-state slug sessao
  mkdir -p "$1"
  cat > "$1/run-state-$2.md" <<EOF
status: em_andamento
slug: $2
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: wave 2 em curso
sessao: $3
EOF
}

roda() { # proj payload-json -> $TMP/out, $st
  printf '%s' "$2" | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO CLAUDE_PROJECT_DIR="$1" bash "$HOOK" > "$TMP/out" 2>/dev/null
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

# 1. Controle positivo: mudança sensível, sem run-state → cutuca
D1="$TMP/c1"; repo "$D1"
roda "$D1" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "positivo/decision" '"decision": "block"'
contem "positivo/gate"     'Gate de Segurança'

# 2. Run-state LEGADO em andamento → rede da sessão livre cala
D2="$TMP/c2"; repo "$D2"; run_state "$D2/thoughts/local" alfa desconhecida
roda "$D2" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "legado-silencia"

# 3. Run-state na casa da sessão (4.314) → mesmo silêncio
D3="$TMP/c3"; repo "$D3"
run_state "$D3/thoughts/local/sessions/20260830-100000-sessaoeu" beta sessao-eu
roda "$D3" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "sessao-silencia"

# 4. Run-state de OUTRA sessão (4.252) → não silencia a rede desta
D4="$TMP/c4"; repo "$D4"
run_state "$D4/thoughts/local/sessions/20260830-100000-sessoutr" gama sessao-outra
roda "$D4" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "alheio/decision" '"decision": "block"'

# 5. Veredito do security-engineer no ledger da sessão mais novo que os arquivos → silêncio (4.365)
D5="$TMP/c5"; repo "$D5"
touch -t 202601010000 "$D5/src/auth.php"
printf 'APROVADO — sem achado\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D5" append gate security-engineer meu-slug >/dev/null 2>&1
roda "$D5" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "veredito-cobre-arvore"

# 6. Arquivo sensível editado DEPOIS do veredito → cutuca de novo
D6="$TMP/c6"; repo "$D6"
ev="$(printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" append gate security-engineer meu-slug 2>/dev/null)"
touch -t 202601010000 "$ev"
roda "$D6" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "pos-veredito/decision" '"decision": "block"'

# 7. Veredito de OUTRO gate (code-reviewer) não cala o security-guard
D7="$TMP/c7"; repo "$D7"
touch -t 202601010000 "$D7/src/auth.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D7" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D7" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "outro-gate/decision" '"decision": "block"'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "security-guard: $fail de $total casos falharam"
  exit 1
fi
echo "security-guard: $total casos verdes"
exit 0
