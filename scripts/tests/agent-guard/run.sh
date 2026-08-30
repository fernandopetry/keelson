#!/usr/bin/env bash
# run.sh — suíte de regressão do agent-guard (decisões 4.42/4.141/4.297).
#
# Roda o hook de verdade (stdin JSON, jq, git para a janela de fingerprints) num
# repo temporário com keelson.config.json. Casos inline (asserção por grep):
#   1. papel anônimo (keelson:*) → silêncio;
#   2. papel NOMEADO → deny 1× citando 4.293 (conversão em teammate);
#   3. válvula (4.141): a MESMA chamada nomeada repetida → silêncio (rota do
#      modo teams deliberado);
#   4. controle positivo do comportamento antigo: genérico com verbo de papel
#      → deny citando o elenco;
#   5. genérico de exploração → silêncio.
#
# Uso: scripts/tests/agent-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/agent-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "agent-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# Projeto keelson sintético: ficha + repo git (a janela de fingerprints mora no .git).
PROJ="$TMP/proj"
mkdir -p "$PROJ"
: > "$PROJ/keelson.config.json"
git -C "$PROJ" init -q 2>/dev/null || { echo "ERRO: git init falhou" >&2; exit 1; }

fail=0
total=0

roda() { # stdin-json -> saída em $TMP/out, exit em $st
  CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" > "$TMP/out" 2>"$TMP/err" <<< "$1"
  st=$?
}

contem() { # nome padrão
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then :; else
    echo "FAIL $1: saída não contém [$2]"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

silencio() { # nome — saída vazia e exit 0
  total=$((total + 1))
  if [ "$st" -ne 0 ] || [ -s "$TMP/out" ]; then
    echo "FAIL $1: esperava silêncio (exit $st)"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

# 1. Papel anônimo: elenco sem name → passa em silêncio.
roda '{"tool_name":"Agent","tool_input":{"subagent_type":"keelson:developer","description":"Implementar TASK","prompt":"Implemente a TASK-001-002 conforme o PLAN."}}'
silencio "anonimo"

# 2. Papel NOMEADO: deny citando a conversão em teammate (4.293/4.297).
roda '{"tool_name":"Agent","tool_input":{"subagent_type":"keelson:developer","name":"dev-task-002","description":"Implementar TASK","prompt":"Implemente a TASK-001-002 conforme o PLAN."}}'
contem "nomeado/deny"    '"permissionDecision": "deny"'
contem "nomeado/decisao" '4.293'
contem "nomeado/motivo"  'nome de instância'
contem "nomeado/valvula" '--force-mode=teams'

# 3. Válvula (4.141): a mesma chamada repetida passa — rota do teams deliberado.
roda '{"tool_name":"Agent","tool_input":{"subagent_type":"keelson:developer","name":"dev-task-002","description":"Implementar TASK","prompt":"Implemente a TASK-001-002 conforme o PLAN."}}'
silencio "valvula"

# 4. Controle positivo do comportamento antigo (4.42): genérico com verbo de papel.
roda '{"tool_name":"Task","tool_input":{"subagent_type":"general-purpose","description":"dev","prompt":"Implemente a TASK-001-003 com testes."}}'
contem "generico/deny"   '"permissionDecision": "deny"'
contem "generico/elenco" 'keelson:developer'

# 5. Exploração genérica: sem verbo de papel → silêncio.
roda '{"tool_name":"Task","tool_input":{"subagent_type":"general-purpose","description":"explorar","prompt":"Explore o diretório src e resuma a arquitetura em 10 linhas."}}'
silencio "exploracao"

if [ "$fail" -gt 0 ]; then
  echo "agent-guard: $fail/$total asserções falharam"
  exit 1
fi
echo "agent-guard: $total asserções ok"
exit 0
