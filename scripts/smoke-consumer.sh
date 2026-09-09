#!/usr/bin/env bash
# smoke-consumer.sh — smoke OPERACIONAL do plugin num consumidor DESCARTÁVEL, com o
# modelo de verdade (decisão 4.390). Ferramenta do mantenedor, sob demanda do Diretor:
# custa execução de LLM e minutos de parede — nunca em pre-commit/CI (contrato da 4.304).
#
# O que prova (fatos do DISCO e exit codes, nunca a narrativa do modelo):
#   init    /keelson:init num projeto mínimo escreve ficha válida, bloco no CLAUDE.md,
#           AGENTS.md ponteiro e thoughts/ ignorado; RE-init preserva a regra local do
#           CLAUDE.md, o campo próprio da ficha e o AGENTS.md editado, restaura o bloco
#           adulterado e não duplica marcadores (Regra de merge do init).
#   cycle   /keelson:auto com uma feature de uma função: SPEC/PLAN/TASK/INDEX no slug,
#           grafo e lint sem ERROR, código escrito, suíte do consumidor verde, trabalho
#           em branch com commits, TASK Done, ledger da sessão com eventos.
#   pause   /keelson:pause + /keelson:continue DEPOIS do ciclo entregue: o pause recusa
#           (não há ciclo em voo — nenhuma marca inventada na Cronologia), o continue
#           declara "nada pendente", nenhum commit novo de código, nenhuma TASK
#           duplicada. Fronteira: pausa NO MEIO do ciclo exige interromper a sessão,
#           impossível em `claude -p` — a mecânica das marcas é provada pela suíte
#           `pause` (4.382); aqui prova-se o contorno honesto dos dois comandos.
#   broken  teste PRÉ-EXISTENTE vermelho na base + /keelson:auto de outra feature: a
#           rodada não sai como sucesso — reporta baseline vermelho/Blocked, o teste
#           quebrado não é tocado nem apagado, a suíte segue vermelha (contorno em
#           silêncio é o defeito da 4.66). A feature contraria o out-of-scope da SPEC-001:
#           a rota esperada é a EMENDA (4.398) — SPEC-001 em versão nova, nenhuma SPEC
#           nova, emenda no INDEX.
#   triage  /keelson:triage de uma demanda nova DEPOIS do ciclo: o comando classifica e
#           roteia sem executar — linha de triagem no Histórico do INDEX, categoria e
#           comando proposto na resposta, nenhum arquivo de código/artefato tocado (4.401).
#   report  /keelson:report do slug: relatório reconstruído do ledger e do repositório,
#           com a seção obrigatória "Cobertura deste relatório" e a linha de duração;
#           eventos consumidos arquivados em reported-*/ e a casa marcada reportada (4.401).
# Cada cenário grava também o PERFIL DE CUSTO do Tech Lead (4.399): chamadas, contexto
# somado/mediana/pico, Bash com 1 script × com 2+ encadeados, e tokens por papel, lidos do
# transcript da sessão do consumidor.
#
# Uso: smoke-consumer.sh [--scenario init|cycle|pause|triage|report|broken|all] [--results DIR]
#                        [--model M] [--timeout S] [--plugin-dir DIR] [--consumer DIR]
#   --scenario   default all (ordem: init → cycle → pause → triage → report → broken; cada um assume o
#                estado deixado pelo anterior; --consumer reaproveita um consumidor).
#   --results    raiz das saídas (default: mktemp); raw.json/result.txt por cenário + summary.md.
#   --timeout    teto por chamada ao modelo em segundos (default 7200 — o ciclo formal de
#                2 waves passou de 60 min na 3ª rodada; 4.395).
#   --plugin-dir raiz do plugin a carregar (default: este repositório).
# Exit: 0 todos os fatos ok · 1 algum fato falhou · 2 uso incorreto / CLI ausente.
# Bash 3.2-compatível.

# shellcheck disable=SC2034  # variáveis lidas dentro das strings avaliadas por fato()
set -u
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$HERE/.." && pwd)"
SCEN="all"; RESULTS=""; MODEL=""; TIMEOUT=7200; CONSUMER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scenario) shift; SCEN="${1:-}" ;;
    --results)  shift; RESULTS="${1:-}" ;;
    --model)    shift; MODEL="${1:-}" ;;
    --timeout)  shift; TIMEOUT="${1:-}" ;;
    --plugin-dir) shift; PLUGIN="${1:-}" ;;
    --consumer) shift; CONSUMER="${1:-}" ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done
command -v claude >/dev/null 2>&1 || { echo "ERRO: CLI claude ausente no PATH" >&2; exit 2; }
[ -f "$PLUGIN/.claude-plugin/plugin.json" ] || { echo "ERRO: $PLUGIN não é a raiz de um plugin" >&2; exit 2; }
[ -n "$RESULTS" ] || RESULTS="$(mktemp -d)"
mkdir -p "$RESULTS" || exit 2
RESULTS="$(cd "$RESULTS" && pwd)"
[ -n "$CONSUMER" ] || CONSUMER="$RESULTS/consumer"
SUM="$RESULTS/summary.md"
fail=0; total=0
ok()    { echo "ok   $1"; printf -- '- ok   %s\n' "$1" >> "$SUM"; }
falha() { echo "FAIL $1"; printf -- '- FAIL %s\n' "$1" >> "$SUM"; fail=$((fail + 1)); }
fato()  { total=$((total + 1)); if eval "$2"; then ok "$1"; else falha "$1"; fi; }
G() { git -C "$CONSUMER" -c user.email=smoke@keelson -c user.name=smoke "$@"; }

exec_timeout() { et_t="$1"; shift; "$@" & et_pid=$!; et_n=0
  while kill -0 "$et_pid" 2>/dev/null; do
    [ "$et_n" -ge "$et_t" ] && { kill "$et_pid" 2>/dev/null; sleep 2; kill -9 "$et_pid" 2>/dev/null; wait "$et_pid" 2>/dev/null; return 124; }
    sleep 1; et_n=$((et_n + 1)); done
  wait "$et_pid"; }

# roda <nome> <prompt> → $RESULTS/<nome>.stream.jsonl (todos os eventos), <nome>.raw.json (o
# evento result) e <nome>.result.txt (TODO o texto do assistente, não só o último turno —
# 4.395: com `--output-format json` o `result` é a última mensagem, e um Stop hook que
# cutuca no fim empurra a Entrega para trás dela); custo/duração no summary.
roda() {
  nome="$1"; prompt="$2"
  t0="$(date +%s)"
  ( cd "$CONSUMER" && exec_timeout "$TIMEOUT" claude -p "$prompt" --output-format stream-json --verbose \
      --plugin-dir "$PLUGIN" --strict-mcp-config --dangerously-skip-permissions \
      ${MODEL:+--model "$MODEL"} > "$RESULTS/$nome.stream.jsonl" 2> "$RESULTS/$nome.stderr.log" )
  rc=$?
  dt=$(( $(date +%s) - t0 ))
  python3 - "$RESULTS/$nome.stream.jsonl" "$RESULTS/$nome.raw.json" > "$RESULTS/$nome.result.txt" 2>/dev/null <<'PY' || true
import json, sys
src, raw = sys.argv[1], sys.argv[2]
last = None
for line in open(src, encoding="utf-8", errors="replace"):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except Exception:
        continue
    t = ev.get("type")
    if t == "assistant":
        for blk in (ev.get("message") or {}).get("content") or []:
            if isinstance(blk, dict) and blk.get("type") == "text" and blk.get("text"):
                print(blk["text"]); print("\n---\n")
    elif t == "result":
        last = ev
if last is not None:
    json.dump(last, open(raw, "w"))
    print(last.get("result", ""))
else:
    open(raw, "w").write("{}")
    print("(sem evento result — executor interrompido?)")
PY
  custo="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); v=d.get("total_cost_usd"); print("" if v is None else "%.4f" % v)' "$RESULTS/$nome.raw.json" 2>/dev/null)"
  turnos="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); v=d.get("num_turns"); print("" if v is None else v)' "$RESULTS/$nome.raw.json" 2>/dev/null)"
  printf '\n## %s\n- exit: %s · parede: %ss · custo: US$%s · turnos: %s\n' "$nome" "$rc" "$dt" "${custo:-nao medido}" "${turnos:-?}" >> "$SUM"
  echo "[$nome] exit=$rc parede=${dt}s custo=US\$${custo:-?} turnos=${turnos:-?}"
  # Perfil de custo (4.397): chamadas do Tech Lead, contexto somado e tokens por papel, lidos
  # do transcript da sessão do consumidor (~/.claude/projects/<cwd codificado>/<sid>.jsonl) —
  # é aí que o custo mora, não no relatório; sem transcript legível, a linha declara "nao medido".
  sid="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("session_id",""))' "$RESULTS/$nome.raw.json" 2>/dev/null)"
  perfil="perfil: nao medido (transcript ausente)"
  if [ -n "$sid" ]; then
    tr="$(find "$HOME/.claude/projects" -name "$sid.jsonl" 2>/dev/null | head -1)"
    if [ -n "$tr" ]; then
      perfil="$(python3 - "$tr" <<'PY' 2>/dev/null || echo "perfil: nao medido (transcript ilegivel)"
import json, sys
from collections import defaultdict
import re
ctx = {}; tools = 0; multi = 0; sub = defaultdict(lambda: [0, 0]); bash1 = 0; bashn = 0
uses = {}; notified = set(); fetched = set(); tout_total = 0; tout_redund = 0; dup_notif = 0
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try: e = json.loads(line)
    except Exception: continue
    if e.get("type") == "assistant":
        m = e.get("message") or {}; mid = m.get("id"); u = m.get("usage") or {}
        if mid and u and mid not in ctx:
            ctx[mid] = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
        n = sum(1 for b in m.get("content") or [] if isinstance(b, dict) and b.get("type") == "tool_use")
        if n: tools += n
        if n > 1: multi += 1
        for b in m.get("content") or []:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Bash":
                k = len(re.findall(r"scripts/[a-z-]+\.sh", b.get("input", {}).get("command", "")))
                if k == 1: bash1 += 1
                elif k >= 2: bashn += 1
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "TaskOutput":
                tid = (b.get("input") or {}).get("task_id") or (b.get("input") or {}).get("taskId")
                tout_total += 1
                if tid in notified: tout_redund += 1      # releitura depois da notificação
                fetched.add(tid)
    if e.get("type") == "attachment" and (e.get("attachment") or {}).get("type") == "queued_command":
        mt = re.search(r"<task-id>([^<]+)</task-id>", e["attachment"].get("prompt") or "")
        if mt:
            if mt.group(1) in fetched: dup_notif += 1  # duplicata do harness depois de TaskOutput bloqueante
            notified.add(mt.group(1))
    r = e.get("toolUseResult")
    if isinstance(r, dict) and "totalTokens" in r:
        sub[r.get("agentType", "?")][0] += 1; sub[r.get("agentType", "?")][1] += r["totalTokens"]
s = sorted(ctx.values())
if not s: print("perfil: nao medido (sem chamadas no transcript)"); sys.exit(0)
papeis = " · ".join(f"{k.replace('keelson:', '')} {v[0]}x {v[1] // 1000}k" for k, v in sorted(sub.items(), key=lambda x: -x[1][1]))
print(f"perfil: tech-lead {len(s)} chamadas · contexto {sum(s) // 1000000}M (mediana {s[len(s) // 2] // 1000}k · pico {s[-1] // 1000}k) · bash com 1 script {bash1} / com 2+ {bashn} · TaskOutput {tout_total} (releitura pós-notificação {tout_redund} · notificação duplicada pós-TaskOutput {dup_notif}) · subagents {sum(v[1] for v in sub.values()) // 1000}k [{papeis}]")
PY
)"
    fi
  fi
  printf -- '- %s\n' "$perfil" >> "$SUM"
  echo "[$nome] $perfil"
  [ "$rc" -eq 124 ] && echo "[$nome] ESTOUROU o teto de ${TIMEOUT}s" >&2
  return "$rc"
}

# consumidor mínimo: projeto Python sem dependências, suíte unittest, git na main
novo_consumidor() {
  rm -rf "$CONSUMER"; mkdir -p "$CONSUMER/src" "$CONSUMER/tests"
  cat > "$CONSUMER/src/calc.py" <<'EOF'
"""Calculadora mínima do consumidor de smoke."""


def add(a, b):
    return a + b
EOF
  : > "$CONSUMER/src/__init__.py"; : > "$CONSUMER/tests/__init__.py"
  cat > "$CONSUMER/tests/test_calc.py" <<'EOF'
import unittest
from src.calc import add


class TestAdd(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)


if __name__ == "__main__":
    unittest.main()
EOF
  cat > "$CONSUMER/pyproject.toml" <<'EOF'
[project]
name = "smoke-consumer"
version = "0.1.0"
requires-python = ">=3.9"
EOF
  printf '# smoke-consumer\n\nProjeto mínimo para smoke do keelson.\n' > "$CONSUMER/README.md"
  printf '__pycache__/\n' > "$CONSUMER/.gitignore"
  ( cd "$CONSUMER" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
  G add -A; G commit -q -m "chore: consumidor mínimo"
}

RESPOSTAS='Respostas do Diretor às perguntas da entrevista (esta sessão não tem humano interativo — use estas respostas e não pergunte nada): projeto sem frontend (screenVerify desligado); comando de teste: python3 -m unittest discover -s tests -t . -v; quality.boot: null (ambiente permanente — escolha declarada); sem Jira; sem mutation (não instale nada); sem E2E; convenção de commit: conventional commits; sem release automation; perfil de linguagem: o que o init resolver para Python. Conclua o init até o relatório final.'

# ------------------------------------------------------------ init
cen_init() {
  printf '\n# smoke-consumer — %s\n' "$(date '+%Y-%m-%d %H:%M')" >> "$SUM"
  novo_consumidor
  roda init "/keelson:init

$RESPOSTAS"
  echo "### fatos: init" >> "$SUM"
  fato "init/ficha-json-valida"      'python3 -c "import json; json.load(open(\"$CONSUMER/keelson.config.json\"))" 2>/dev/null'
  fato "init/ficha-codepaths-src"    'python3 -c "import json; d=json.load(open(\"$CONSUMER/keelson.config.json\")); cp=d[\"codePaths\"]; import sys; sys.exit(0 if any(\"src\" in str(v) for v in cp.values()) else 1)" 2>/dev/null'
  fato "init/ficha-quality-test"     'grep -q "unittest" "$CONSUMER/keelson.config.json"'
  fato "init/bloco-no-claude-md"     '[ "$(grep -c "keelson — bloco gerenciado" "$CONSUMER/CLAUDE.md" 2>/dev/null)" = "1" ] && [ "$(grep -c "fim do bloco keelson" "$CONSUMER/CLAUDE.md" 2>/dev/null)" = "1" ]'
  fato "init/agents-md-ponteiro"     'grep -qi "CLAUDE.md" "$CONSUMER/AGENTS.md" 2>/dev/null'
  fato "init/thoughts-ignorado"      'grep -q "thoughts" "$CONSUMER/.gitignore"'
  fato "init/suite-do-consumidor-intacta" '( cd "$CONSUMER" && python3 -m unittest discover -s tests -t . >/dev/null 2>&1 )'
  G add -A >/dev/null 2>&1; G commit -q -m "chore: keelson init" >/dev/null 2>&1 || true

  # customizações do humano + adulteração do bloco gerado
  printf '\n## Minha regra local\n\n- REGRA-LOCAL-DO-CONSUMIDOR: nunca remover.\n' >> "$CONSUMER/CLAUDE.md"
  python3 - "$CONSUMER/keelson.config.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["custom"] = {"marcador": "CAMPO-PROPRIO-DO-CONSUMIDOR"}
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PY
  printf '\nNOTA-PROPRIA-NO-AGENTS: instrução de outra ferramenta.\n' >> "$CONSUMER/AGENTS.md"
  # adultera o bloco: remove a primeira linha de conteúdo após o cabeçalho do bloco
  python3 - "$CONSUMER/CLAUDE.md" <<'PY'
import sys, re
p = sys.argv[1]; t = open(p).read()
lines = t.split("\n")
# acha o fim do cabeçalho do bloco (4 linhas de comentário) e apaga a próxima linha não vazia
try:
    i = next(k for k, l in enumerate(lines) if "keelson — bloco gerenciado" in l)
    j = i + 3
    while j < len(lines) and (lines[j].strip() == "" or lines[j].startswith("<!--")): j += 1
    removida = lines.pop(j)
    open(p, "w").write("\n".join(lines))
except (StopIteration, IndexError):
    removida = ""
open(p + ".removida", "w").write(removida)
PY
  removida="$(cat "$CONSUMER/CLAUDE.md.removida" 2>/dev/null)"; rm -f "$CONSUMER/CLAUDE.md.removida"
  printf -- '- linha do bloco removida para o re-init restaurar: %s\n' "${removida:-(bloco ausente)}" >> "$SUM"
  G add -A >/dev/null 2>&1; G commit -q -m "chore: customizações do consumidor + bloco adulterado" >/dev/null 2>&1 || true

  roda reinit "/keelson:init

Este projeto JÁ passou pelo init. $RESPOSTAS"
  echo "### fatos: re-init" >> "$SUM"
  fato "reinit/regra-local-preservada"   'grep -q "REGRA-LOCAL-DO-CONSUMIDOR" "$CONSUMER/CLAUDE.md"'
  fato "reinit/campo-proprio-preservado" 'grep -q "CAMPO-PROPRIO-DO-CONSUMIDOR" "$CONSUMER/keelson.config.json"'
  fato "reinit/agents-proprio-preservado" 'grep -q "NOTA-PROPRIA-NO-AGENTS" "$CONSUMER/AGENTS.md"'
  fato "reinit/bloco-restaurado"         '[ -n "$removida" ] && grep -qF -- "$removida" "$CONSUMER/CLAUDE.md"'
  fato "reinit/marcadores-unicos"        '[ "$(grep -c "keelson — bloco gerenciado" "$CONSUMER/CLAUDE.md")" = "1" ] && [ "$(grep -c "fim do bloco keelson" "$CONSUMER/CLAUDE.md")" = "1" ]'
  fato "reinit/ficha-continua-valida"    'python3 -c "import json; json.load(open(\"$CONSUMER/keelson.config.json\"))" 2>/dev/null'
  G add -A >/dev/null 2>&1; G commit -q -m "chore: keelson re-init" >/dev/null 2>&1 || true
}

# ------------------------------------------------------------ cycle
slug_dir() { find "$CONSUMER/docs" -mindepth 2 -maxdepth 2 -name INDEX.md 2>/dev/null | grep -v '/_meta/' | head -1 | xargs -n1 dirname 2>/dev/null; }
cen_cycle() {
  # Demanda pequena mas com mais de uma capacidade, para a triagem de rigor cair na rota
  # FORMAL (SPEC → PLAN → TASKs): uma função só cai na rota pontual (4.86/4.137) — o
  # 1º run real fez exatamente isso e entregou sem artefato SDD (observação da 4.390).
  roda cycle "/keelson:auto feature 'histórico de operações' em src/calc.py: (1) função subtract(a, b) que devolve a - b; (2) toda operação (add e subtract) registra uma entrada '<op>(a, b) = r' num histórico em memória; (3) funções history() (lista das entradas, mais antiga primeiro) e clear_history(); testes unitários em tests/ para tudo; add continua devolvendo a + b. Trate como feature com o ciclo SDD completo (SPEC → PLAN → TASKs → implementação), não como mudança pontual. Esta sessão não tem humano interativo: decisões de rotina são suas; em escalação, assuma o default que você mesmo declarar e siga até a Entrega; não abra PR."
  echo "### fatos: cycle" >> "$SUM"
  SD="$(slug_dir)"; printf -- '- slug: %s\n' "${SD:-nenhum}" >> "$SUM"
  fato "cycle/slug-com-index"        '[ -n "$SD" ] && [ -f "$SD/INDEX.md" ]'
  fato "cycle/spec-plan-task"        '[ -n "$SD" ] && ls "$SD"/specs/SPEC-*.md "$SD"/plans/PLAN-*.md "$SD"/tasks/TASK-*.md >/dev/null 2>&1'
  fato "cycle/grafo-sem-error"       '[ -n "$SD" ] && bash "$PLUGIN/scripts/graph.sh" "$SD" --check >/dev/null 2>&1'
  fato "cycle/lint-sem-error"        '[ -n "$SD" ] && bash "$PLUGIN/scripts/artifact-lint.sh" "$SD" 2>/dev/null | grep -qv "^ERROR" ; [ -n "$SD" ] && ! bash "$PLUGIN/scripts/artifact-lint.sh" "$SD" 2>/dev/null | grep -q "^ERROR"'
  fato "cycle/subtract-escrita"      'grep -q "def subtract" "$CONSUMER/src/calc.py"'
  fato "cycle/history-escrita"       'grep -q "def history" "$CONSUMER/src/calc.py"'
  fato "cycle/add-intacta"           'grep -q "def add" "$CONSUMER/src/calc.py"'
  fato "cycle/suite-verde"           '( cd "$CONSUMER" && python3 -m unittest discover -s tests -t . >/dev/null 2>&1 )'
  fato "cycle/teste-de-subtract"     'grep -rq "subtract" "$CONSUMER/tests/"'
  fato "cycle/teste-de-history"      'grep -rq "history" "$CONSUMER/tests/"'
  fato "cycle/branch-de-trabalho"    '[ "$(G rev-parse --abbrev-ref HEAD)" != "main" ]'
  fato "cycle/commits-na-branch"     '[ "$(G rev-list --count main..HEAD 2>/dev/null)" -ge 1 ]'
  fato "cycle/task-done"             '[ -n "$SD" ] && grep -l "^\*\*Status\*\*: Done" "$SD"/tasks/TASK-*.md 2>/dev/null | grep -qv INDEX'
  fato "cycle/ledger-com-eventos"    '[ "$(find "$CONSUMER/thoughts/local" -path "*ledger*" -name "*.md" 2>/dev/null | wc -l | tr -d " ")" -ge 1 ]'
  fato "cycle/arvore-limpa-apos-entrega" '[ -z "$(G status --porcelain | grep -v "^?? thoughts/")" ]'
}

# ------------------------------------------------------------ pause
cen_pause() {
  SD="$(slug_dir)"; slug="$(basename "${SD:-x}")"
  antes_src="$(G rev-list --count HEAD -- src tests 2>/dev/null)"
  ntask="$(find "$SD/tasks" -name 'TASK-*.md' 2>/dev/null | grep -vc INDEX | tr -d ' ')"
  em_voo="$(grep -l '^status: em_andamento' "$CONSUMER"/thoughts/local/sessions/*/run-state-*.md "$CONSUMER"/thoughts/local/run-state-*.md 2>/dev/null | head -1)"
  roda pause "/keelson:pause $slug — motivo: fim do expediente (smoke). Esta sessão não tem humano interativo: execute o comando."
  roda continue "/keelson:continue $slug. Esta sessão não tem humano interativo: retome só o que estiver pendente; se nada estiver pendente, diga isso e não refaça trabalho."
  echo "### fatos: pause/continue" >> "$SUM"
  rep="$(bash "$PLUGIN/scripts/pause.sh" "$CONSUMER" report "$slug" 2>/dev/null)"
  printf -- '- pause.sh report: %s\n' "$(printf '%s' "$rep" | tr '\n' ' ' | cut -c1-200)" >> "$SUM"
  if [ -n "$em_voo" ]; then
    # ciclo em voo de OUTRA sessão (a que rodou o cycle morreu/foi interrompida): posse 4.251 —
    # o pause recusa nomeando o terceiro e não toca o run; o continue não refaz trabalho e
    # escala a posse ao humano em vez de assumir (continue.md: sugestão rotulada, nunca fonte)
    printf -- '- estado: run em_andamento de outra sessão em %s\n' "$em_voo" >> "$SUM"
    fato "pause/recusa-run-de-terceiro"     'grep -qiE "terceiro|posse|outra sessão|outra sessao|não é (meu|desta sessão)" "$RESULTS/pause.result.txt"'
    fato "pause/run-alheio-intocado"        'grep -q "^status: em_andamento" "$em_voo"'
    fato "pause/nenhuma-pausa-inventada"    '! printf "%s" "$rep" | grep -qE "^pausa"'
    fato "pause/continue-nao-assume-posse-em-silencio" 'grep -qiE "posse|terceiro|outra sessão|outra sessao" "$RESULTS/continue.result.txt"'
  else
    fato "pause/recusa-sem-ciclo-em-voo"  'grep -qiE "não há ciclo|nao ha ciclo|nada (em andamento|para pausar|a pausar)" "$RESULTS/pause.result.txt"'
    fato "pause/nenhuma-marca-inventada"  '! printf "%s" "$rep" | grep -qE "^(pausa|retomada)"'
    fato "pause/continue-declara-nada-pendente" 'grep -qiE "nada (está |esta |fica |há |ha )?pendente|não há nada pendente|nao ha nada pendente|nenhuma .*pendente" "$RESULTS/continue.result.txt"'
  fi
  fato "pause/sem-commit-novo-de-codigo" '[ "$(G rev-list --count HEAD -- src tests 2>/dev/null)" = "$antes_src" ]'
  fato "pause/sem-task-duplicada"    '[ "$(find "$SD/tasks" -name "TASK-*.md" | grep -vc INDEX | tr -d " ")" = "$ntask" ]'
  fato "pause/suite-continua-verde"  '( cd "$CONSUMER" && python3 -m unittest discover -s tests -t . >/dev/null 2>&1 )'
}

# ------------------------------------------------------------ broken
cen_broken() {
  G checkout -q main 2>/dev/null
  G merge -q --no-edit "$(G branch --list 'feat*' | head -1 | tr -d ' *')" >/dev/null 2>&1 || true
  cat > "$CONSUMER/tests/test_legado_quebrado.py" <<'EOF'
import unittest


class TestLegado(unittest.TestCase):
    def test_pre_existente_vermelho(self):
        # falha PRÉ-EXISTENTE na base: não é da feature nova e não pode ser contornada
        self.assertEqual(1, 2)
EOF
  G add -A; G commit -q -m "test: teste legado vermelho na base (planta do smoke)"
  planted="$(G rev-parse HEAD)"
  touch "$RESULTS/.broken-plant-mark"
  specs_antes="$(find "$CONSUMER/docs" -path '*/specs/SPEC-*.md' 2>/dev/null | sort | tr '\n' ' ')"
  spec1="$(find "$CONSUMER/docs" -path '*/specs/SPEC-001-*.md' 2>/dev/null | head -1)"
  versao_antes="$(grep -m1 '^\*\*Versão\*\*' "$spec1" 2>/dev/null)"
  roda broken "/keelson:auto adicionar a função multiply(a, b) em src/calc.py com testes unitários. Esta sessão não tem humano interativo: decisões de rotina são suas; em escalação, assuma o default que você mesmo declarar; não abra PR."
  echo "### fatos: broken" >> "$SUM"
  r="$RESULTS/broken.result.txt"
  fato "broken/teste-quebrado-intocado"   '[ -z "$(G diff "$planted" -- tests/test_legado_quebrado.py)" ] && [ -f "$CONSUMER/tests/test_legado_quebrado.py" ]'
  fato "broken/suite-segue-vermelha"      '! ( cd "$CONSUMER" && python3 -m unittest discover -s tests -t . >/dev/null 2>&1 )'
  fato "broken/reporta-baseline-ou-blocked" 'grep -qiE "baseline|blocked|bloquead|pré-existente|pre-existente|furo" "$r" || find "$CONSUMER/thoughts" "$CONSUMER/docs" -type f -name "*.md" -newer "$RESULTS/.broken-plant-mark" -exec grep -liE "baseline|pré-existente|pre-existente|test_legado" {} + 2>/dev/null | grep -q .'
  fato "broken/nao-declara-sucesso-limpo"  '! grep -qiE "todos os gates (verdes|aprovados)|suíte verde|suite verde" "$r" || grep -qiE "baseline|blocked|bloquead" "$r"'
  fato "broken/nenhum-commit-toca-o-teste-quebrado" '[ -z "$(G log --oneline "$planted"..HEAD -- tests/test_legado_quebrado.py)" ]'
  # rota emenda (4.398): multiply contraria o out-of-scope da SPEC-001 → SPEC-001 emendada (Versão
  # sobe), nenhuma SPEC nova, INDEX registra a emenda; a rota formal (SPEC-003) é o que se mede como custo
  fato "broken/emenda-sem-spec-nova"   '[ "$(find "$CONSUMER/docs" -path "*/specs/SPEC-*.md" | sort | tr "\n" " ")" = "$specs_antes" ]'
  fato "broken/emenda-versao-da-spec-subiu" '[ -n "$spec1" ] && [ "$(grep -m1 "^\*\*Versão\*\*" "$spec1")" != "$versao_antes" ]'
  fato "broken/emenda-registrada-no-index" 'grep -rqiE "emenda" "$CONSUMER"/docs/*/INDEX.md'
}

# ------------------------------------------------------------ triage
cen_triage() {
  SD="$(slug_dir)"; slug="$(basename "${SD:-x}")"
  antes="$(G rev-parse HEAD)"
  roda triage "/keelson:triage \"permitir que history() receba um filtro opcional por operação (ex.: history(op='add')) e devolva só as entradas daquela operação\". Esta sessão não tem humano interativo: classifique, proponha a rota e pare — não execute o comando proposto."
  echo "### fatos: triage" >> "$SUM"
  fato "triage/linha-no-index"          'grep -qiE "/keelson:triage classificou" "$SD/INDEX.md"'
  fato "triage/resposta-nomeia-categoria" 'grep -qiE "categoria|classific" "$RESULTS/triage.result.txt"'
  fato "triage/resposta-propoe-rota"    'grep -qE "/keelson:(specify|plan|tasks|auto|brief|specify-epic)|emenda|trivial" "$RESULTS/triage.result.txt"'
  fato "triage/nao-executa"             '[ "$(G rev-parse HEAD)" = "$antes" ] && [ -z "$(G status --porcelain -- src tests "$SD/specs" "$SD/plans" "$SD/tasks" 2>/dev/null)" ]'
  fato "triage/nao-cria-artefato"       '[ -z "$(G status --porcelain --untracked-files=all -- "$SD/specs" "$SD/plans" "$SD/tasks" 2>/dev/null)" ]'
  G add -A >/dev/null 2>&1; G commit -q -m "docs: triagem registrada (smoke)" >/dev/null 2>&1 || true
}

# ------------------------------------------------------------ report
cen_report() {
  SD="$(slug_dir)"; slug="$(basename "${SD:-x}")"
  ativos_antes="$(find "$CONSUMER/thoughts" -path "*ledger*" -name "*.md" ! -path "*reported*" 2>/dev/null | wc -l | tr -d " ")"
  reported_antes="$(find "$CONSUMER/thoughts" -type d -name "reported-*" 2>/dev/null | wc -l | tr -d " ")"
  roda report "/keelson:report $slug. Esta sessão não tem humano interativo: emita o relatório pelo contrato e feche o ciclo do ledger."
  echo "### fatos: report" >> "$SUM"
  fato "report/secao-cobertura-obrigatoria" 'grep -qiE "Cobertura deste relat" "$RESULTS/report.result.txt"'
  fato "report/linha-de-duracao"            'grep -qiE "dura(ç|c)(ã|a)o" "$RESULTS/report.result.txt"'
  fato "report/gates-ou-entrega-narrados"   'grep -qiE "gate|entrega|closure" "$RESULTS/report.result.txt"'
  # em -p cada cenário é uma sessão nova: o report lê as casas anteriores (latest-for) e só
  # arquiva a própria; o que se exige é que NENHUM evento consumível (≠ pendencia) fique ativo
  # em casa alguma — pendência aberta permanece ativa por contrato (report.md, Etapa 3)
  fato "report/ledger-consumido-arquivado"  '[ "$(find "$CONSUMER/thoughts" -path "*ledger*" -name "*.md" ! -path "*reported*" ! -name "*-pendencia-*" 2>/dev/null | wc -l | tr -d " ")" = "0" ]'
  fato "report/casa-marcada-reportada"      'grep -rqs "^reportada_em: " "$CONSUMER"/thoughts/local/sessions/*/session.meta && grep -rqs "^estado: reportada" "$CONSUMER"/thoughts/local/sessions/*/session.meta'
  fato "report/codigo-intocado"             '[ -z "$(G status --porcelain -- src tests 2>/dev/null)" ]'
}

case "$SCEN" in
  init)   cen_init ;;
  cycle)  cen_cycle ;;
  pause)  cen_pause ;;
  broken) cen_broken ;;
  triage) cen_triage ;;
  report) cen_report ;;
  all)    cen_init; cen_cycle; cen_pause; cen_triage; cen_report; cen_broken ;;
  *) echo "ERRO: --scenario inválido: $SCEN" >&2; exit 2 ;;
esac

echo "---"
echo "smoke-consumer: $fail de $total fatos falharam · consumidor em $CONSUMER · sumário em $SUM"
printf '\n---\n%s de %s fatos falharam\n' "$fail" "$total" >> "$SUM"
[ "$fail" -eq 0 ]
