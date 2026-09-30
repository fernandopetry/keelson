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
#   5. genérico de exploração → silêncio;
#   6. scribe com pacote de correção (4.445): `modo:` fora do enum → deny 1×
#      citando os dois eixos; a mesma chamada repetida → silêncio (válvula);
#      "pacote de correção" sem `modo:` → deny 1×; `modo: edits`/`reescrita`
#      (puro, em negrito, com crase, com enum colado do contrato, com "modo
#      resolução" do PO em prosa junto) → silêncio; redação sem `modo:` →
#      silêncio; `modo_aplicado:` não é `modo:`; scribe NOMEADO com `modo:`
#      ruim → o motivo do modo tem precedência.
#
# Uso: scripts/tests/agent-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
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

# 6. Scribe com pacote de correção (4.445) — JSON montado por jq (prompt com
#    quebras de linha e apóstrofo).
scribe_json() { # subagent_type name description prompt -> JSON
  jq -cn --arg st "$1" --arg nm "$2" --arg d "$3" --arg p "$4" \
    '{tool_name:"Agent",tool_input:({subagent_type:$st,description:$d,prompt:$p} + (if $nm=="" then {} else {name:$nm} end))}'
}
PACOTE_RUIM=$(printf 'Pacote de correção da SPEC-001.\nmodo: julgamento\nAjustes:\n- FR-03 (## Requisitos, "o sistema deve"): reescrever em EARS.')
roda "$(scribe_json keelson:scribe '' 'Correção da SPEC' "$PACOTE_RUIM")"
contem "scribe/enum/deny"     '"permissionDecision": "deny"'
contem "scribe/enum/decisao"  '4.445'
contem "scribe/enum/valor"    'modo: julgamento'
contem "scribe/enum/eixo"     'validator-protocol.md §4.5'
contem "scribe/enum/backstop" '4.429'

# 6b. Válvula: a mesma chamada repetida passa (o scribe é o backstop).
roda "$(scribe_json keelson:scribe '' 'Correção da SPEC' "$PACOTE_RUIM")"
silencio "scribe/enum/valvula"

# 6c. Pacote de correção sem `modo:` algum → deny 1× (motivo de ausência).
roda "$(scribe_json keelson:scribe '' 'Correção' "$(printf 'Pacote de correção consolidado (Etapa 3.5).\nAjustes:\n- TASK-001-002 (## Critérios de pronto): comando com --filter.')")"
contem "scribe/ausente/deny"   '"permissionDecision": "deny"'
contem "scribe/ausente/motivo" 'sem `modo:` declarado'

# 6d. Valores válidos nas formas que a main session emite → silêncio.
for forma in 'modo: edits' 'modo: reescrita' '**modo:** edits' '`modo: reescrita`' 'Modo: edits (12 ajustes)' 'modo: edits | reescrita'; do
  roda "$(scribe_json keelson:scribe '' 'Correção' "$(printf 'Pacote de correção da SPEC-001.\n%s\nAjustes:\n- FR-03: reescrever.' "$forma")")"
  silencio "scribe/valido/[$forma]"
done

# 6e. `modo: edits` real + "modo resolução" do PO em prosa e "(modo: aprovação)" citado → silêncio.
roda "$(scribe_json keelson:scribe '' 'Correção' "$(printf 'Pacote de correção. modo: edits\nResoluções do po (modo: resolução) e o veredito da aprovação (modo: aprovação) já aplicados.\n- AC-2: reescrever.')")"
silencio "scribe/valido/prosa-do-po"

# 6f. Redação (SPEC nova) sem `modo:` e sem "pacote de correção" → silêncio;
#     `modo_aplicado:` citado do formato de saída não é `modo:`.
roda "$(scribe_json keelson:scribe '' 'Redigir SPEC' "$(printf 'Redija a SPEC-002 pelo contrato do /keelson:specify. Devolva o sumário YAML (modo_aplicado: ausente na redação) e as dúvidas.')")"
silencio "scribe/redacao"

# 6g. Scribe NOMEADO com `modo:` ruim → o motivo do modo tem precedência sobre o do nome.
roda "$(scribe_json keelson:scribe scribe-1 'Correção' "$(printf 'Pacote de correção.\nmodo: fatos\n- FR-01: ajustar.')")"
contem "scribe/nomeado/modo-primeiro" '4.445'
contem "scribe/nomeado/valor"         'modo: fatos'

if [ "$fail" -gt 0 ]; then
  echo "agent-guard: $fail/$total asserções falharam"
  exit 1
fi
echo "agent-guard: $total asserções ok"
exit 0
