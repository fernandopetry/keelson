#!/usr/bin/env bash
# wave-guard — hook Stop que impede o encerramento do turno no meio de um run
# de waves do keelson (decisões 4.23/4.24; LRN-018: "fôlego não é gatilho").
#
# Por que existe: instrução não sobrevive a sumarização de contexto. Em execução
# longa (overnight), a regra "não pare entre waves" pode se perder do resumo e o
# agente volta a encerrar o turno na wave 2 de 6 perguntando "continuo?". Este
# guard não depende do contexto do modelo: lê o arquivo de estado em disco
# (thoughts/local/run-state-<slug>.md, formato canônico no method-guide §3.0,
# escrito pelo /keelson:implement a cada wave) e renudgeia o agente se ele
# tentar encerrar com `status: em_andamento`.
#
# O que este guard NÃO faz: julgar mérito da parada. Parada legítima existe
# (Entrega concluída, degrau 3 da escada, pedido explícito do humano) — e a
# saída é o próprio agente registrar `status: encerrado — <motivo>` (ou remover
# o arquivo) antes de encerrar. O guard só garante que parar seja um ato
# deliberado e registrado, nunca esquecimento ou "ponto limpo" inventado.
#
# Fallback gracioso: sem python3, sem cwd, sem arquivo de estado → exit 0
# (nunca trava o fluxo). stop_hook_active evita loop: cutuca 1× por encerramento.

set -euo pipefail

input="$(cat)"

active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null || echo False)"
if [ "$active" = "True" ]; then
  exit 0
fi

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
  exit 0
fi

n=0
detalhes=""
for f in "$cwd"/thoughts/local/run-state-*.md; do
  [ -f "$f" ] || continue
  grep -q '^status: em_andamento' "$f" 2>/dev/null || continue
  n=$((n + 1))
  campos="$(grep -E '^(slug|plan|waves_concluidas|waves_total|retomada):' "$f" 2>/dev/null | sed 's/^/    /' || true)"
  detalhes="${detalhes}
— ${f#"$cwd"/}:
${campos}"
done

if [ "$n" -eq 0 ]; then
  exit 0
fi

reason="Guarda de waves (decisão 4.23): há run do keelson com status EM ANDAMENTO — encerrar o turno agora deixaria o trabalho parado no meio, com o humano ausente.
${detalhes}

Fôlego não é gatilho: sessão longa, contexto sumarizado ou \"ponto limpo\" não autorizam parar. Faça agora UMA das duas coisas:
1. CONTINUE: leia os artefatos apontados em 'retomada' (INDEX do slug + TASK-INDEX), execute a próxima wave e siga até a Entrega. Os artefatos SDD são o checkpoint — nada se perdeu.
2. Se a parada é LEGÍTIMA (Entrega já concluída, degrau 3 da escada com a pergunta já disparada, ou pedido explícito do humano NESTA execução): atualize o arquivo acima para 'status: encerrado — <motivo>' (ou remova-o) e aí sim encerre.
Não encerre sem fazer uma das duas."

printf '%s' "$reason" | python3 -c 'import sys,json; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))' 2>/dev/null || exit 0

exit 0
