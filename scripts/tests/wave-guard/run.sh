#!/usr/bin/env bash
# run.sh — suíte de regressão do wave-guard (decisões 4.23/4.165/4.251/4.298).
#
# Roda o hook de verdade (stdin JSON, python3, ps real). O caso de descendência
# usa um WRAPPER cuja invocação carrega `--parent-session-id <dono>` — a mesma
# marca que o harness põe no processo de subagent/teammate (amostra de campo,
# proposal-inbox 2026-08-29): o hook, filho do wrapper, encontra a marca na
# ancestralidade real de PPIDs. Casos inline (asserção por grep):
#   1. controle positivo: run MEU em andamento → block "Guarda de waves";
#   2. run de TERCEIRO (sessao != minha, sem ancestral marcado) → block de posse;
#   3. descendência (4.298): run do MEU LEAD sob wrapper marcado → silêncio;
#   4. por-arquivo (4.298): run do lead + run MEU no mesmo diretório → block
#      citando o meu e omitindo o do lead;
#   5. stop_hook_active → silêncio;
#   6. sem run-state → silêncio;
#   7. casa da sessão (4.314): run MEU em thoughts/local/sessions/*/ também é
#      visto — o glob duplo cobre as duas casas.
#
# Os cwd de cada caso NÃO são repos git: sem janela de fingerprints (4.165), cada
# invocação cutuca de novo — o que isola os casos entre si.
#
# Uso: scripts/tests/wave-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/wave-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v python3 >/dev/null 2>&1; then
  echo "wave-guard: AVISO — python3 ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

EU="sessao-eu-1111"
DONO="sessao-lead-2222"

run_state() { # dir slug sessao
  mkdir -p "$1/thoughts/local"
  cat > "$1/thoughts/local/run-state-$2.md" <<EOF
status: em_andamento
slug: $2
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: wave 2 em curso
sessao: $3
EOF
}

# Wrapper com a marca do teammate na própria invocação; o hook roda como filho.
cat > "$TMP/fake-teammate.sh" <<'SH'
#!/bin/bash
# argv carrega --parent-session-id <dono>; repassa stdin ao hook.
hook="$1"
bash "$hook"
SH
chmod +x "$TMP/fake-teammate.sh"

fail=0
total=0

roda() { # stdin-json -> $TMP/out, $st
  bash "$HOOK" > "$TMP/out" 2>"$TMP/err" <<< "$1"
  st=$?
}

roda_como_teammate() { # dono stdin-json -> $TMP/out, $st
  bash "$TMP/fake-teammate.sh" "$HOOK" --parent-session-id "$1" > "$TMP/out" 2>"$TMP/err" <<< "$2"
  st=$?
}

contem() {
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then :; else
    echo "FAIL $1: saída não contém [$2]"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

nao_contem() {
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then
    echo "FAIL $1: saída contém [$2] e não devia"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

silencio() {
  total=$((total + 1))
  if [ "$st" -ne 0 ] || [ -s "$TMP/out" ]; then
    echo "FAIL $1: esperava silêncio (exit $st)"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

# 1. Controle positivo: run meu → cutucada normal.
D1="$TMP/c1"; run_state "$D1" alfa "$EU"
roda "{\"stop_hook_active\": false, \"cwd\": \"$D1\", \"session_id\": \"$EU\"}"
contem "meu/decision" '"decision": "block"'
contem "meu/guarda"   'Guarda de waves'
contem "meu/slug"     'slug: alfa'

# 2. Run de terceiro, sem ancestral marcado → mensagem de posse (4.251).
D2="$TMP/c2"; run_state "$D2" beta "$DONO"
roda "{\"stop_hook_active\": false, \"cwd\": \"$D2\", \"session_id\": \"$EU\"}"
contem "terceiro/decision" '"decision": "block"'
contem "terceiro/posse"    'posse de terceiro'

# 3. Descendência (4.298): mesmo run, mas o hook roda sob wrapper com
#    --parent-session-id <dono> → equipe do lead, silêncio.
roda_como_teammate "$DONO" "{\"stop_hook_active\": false, \"cwd\": \"$D2\", \"session_id\": \"$EU\"}"
silencio "descendencia"

# 4. Por-arquivo (4.298): run do lead + run MEU → cutuca citando só o meu.
D4="$TMP/c4"; run_state "$D4" gama "$DONO"; run_state "$D4" delta "$EU"
roda_como_teammate "$DONO" "{\"stop_hook_active\": false, \"cwd\": \"$D4\", \"session_id\": \"$EU\"}"
contem     "por-arquivo/decision" '"decision": "block"'
contem     "por-arquivo/meu"      'slug: delta'
nao_contem "por-arquivo/lead"     'slug: gama'
nao_contem "por-arquivo/posse"    'posse de terceiro'

# 5. stop_hook_active: sai antes de inspecionar.
roda "{\"stop_hook_active\": true, \"cwd\": \"$D1\", \"session_id\": \"$EU\"}"
silencio "stop-active"

# 6. Sem run-state: silêncio.
D6="$TMP/c6"; mkdir -p "$D6"
roda "{\"stop_hook_active\": false, \"cwd\": \"$D6\", \"session_id\": \"$EU\"}"
silencio "mesa-limpa"

# 7. Casa da sessão (4.314): run MEU sob thoughts/local/sessions/*/ é visto.
run_state_casa() { # dir slug sessao — run-state no layout novo
  mkdir -p "$1/thoughts/local/sessions/20260830-100000-teste001"
  cat > "$1/thoughts/local/sessions/20260830-100000-teste001/run-state-$2.md" <<EOF
status: em_andamento
slug: $2
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: wave 2 em curso
sessao: $3
EOF
}
D7="$TMP/c7"; run_state_casa "$D7" epsilon "$EU"
roda "{\"stop_hook_active\": false, \"cwd\": \"$D7\", \"session_id\": \"$EU\"}"
contem "casa/decision" '"decision": "block"'
contem "casa/slug"     'slug: epsilon'

if [ "$fail" -gt 0 ]; then
  echo "wave-guard: $fail/$total asserções falharam"
  exit 1
fi
echo "wave-guard: $total asserções ok"
exit 0
