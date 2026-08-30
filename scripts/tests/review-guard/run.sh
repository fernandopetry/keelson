#!/usr/bin/env bash
# run.sh — suíte de regressão do review-guard (decisões 4.103/4.252/4.314).
#
# Roda o hook de verdade (stdin JSON, jq, repo git sintético sem base main —
# a detecção cai no working tree e os untracked entram). Foco: o silenciador de
# ciclo formal (run-state ativo → a rede da sessão livre cala) nos DOIS layouts:
#   1. controle positivo: diff acima do limiar, sem run-state → block;
#   2. run-state LEGADO em andamento → silêncio;
#   3. run-state na casa da sessão (thoughts/local/sessions/*/ — 4.314) → silêncio;
#   4. run-state de OUTRA sessão (4.252) → NÃO silencia, block.
# Cada caso usa repo próprio (o anti-renudge de .git/ não vaza entre casos).
#
# Uso: scripts/tests/review-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/review-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "review-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

repo() { # $1 = dir — repo git com ficha e mudança de código acima do limiar
  mkdir -p "$1/src"
  ( cd "$1" && git init -q . )
  printf '{ "codePaths": { "backend": ["src"] } }\n' > "$1/keelson.config.json"
  i=0
  : > "$1/src/novo.php"
  while [ "$i" -lt 40 ]; do
    echo "linha $i;" >> "$1/src/novo.php"
    i=$((i + 1))
  done
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

# 1. Controle positivo: mudança acima do limiar, sem run-state → cutuca
D1="$TMP/c1"; repo "$D1"
roda "$D1" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "positivo/decision" '"decision": "block"'
contem "positivo/gate"     'Gate de Code Review'

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

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "review-guard: $fail de $total casos falharam"
  exit 1
fi
echo "review-guard: $total casos verdes"
exit 0
