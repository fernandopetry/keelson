#!/usr/bin/env bash
# wave-guard — hook Stop que impede o encerramento do turno no meio de um run
# de waves do keelson (decisões 4.23/4.24; LRN-018: "fôlego não é gatilho").
#
# Por que existe: instrução não sobrevive a sumarização de contexto. Em execução
# longa (overnight), a regra "não pare entre waves" pode se perder do resumo e o
# agente volta a encerrar o turno na wave 2 de 6 perguntando "continuo?". Este
# guard não depende do contexto do modelo: lê o arquivo de estado em disco
# (thoughts/local/run-state-<slug>.md, formato canônico em docs/_meta/conventions/sdd-conventions.md,
# escrito pelo /keelson:implement a cada wave) e renudgeia o agente se ele
# tentar encerrar com `status: em_andamento`.
#
# O que este guard NÃO faz: julgar mérito da parada. Parada legítima existe
# (Entrega concluída, degrau 3 da escada, pedido explícito do humano) — e a
# saída é o próprio agente registrar `status: encerrado — <motivo>` (ou remover
# o arquivo) antes de encerrar. O guard só garante que parar seja um ato
# deliberado e registrado, nunca esquecimento ou "ponto limpo" inventado.
#
# Posse (decisão 4.251): em sessões paralelas no mesmo checkout, um run pode ser
# de OUTRA sessão viva (campo `sessao:` ≠ session_id do payload). Nesse caso as
# duas saídas habituais são destrutivas (continuar = entrar na worktree alheia;
# encerrar = apagar checkpoint de terceiro) — a mensagem muda para a terceira
# saída: inventariar e escalar ao humano. Sem o campo ou sem session_id →
# comportamento antigo, nunca acusa (falso-positivo é o pior defeito da camada).
#
# Cutuca 1× por ESTADO do run, não por turno (decisão 4.165): com agents em
# background, encerrar o turno e ser reacordado pela task-notification é o
# desenho correto (anti-polling, 4.118) — bloquear todo encerramento cobrava um
# turno extra por notificação colhida (41 numa sessão real de 8 waves). O
# fingerprint dos campos do run-state entra numa janela append-only (mesmo
# desenho do agent-guard, 4.141): estado igual já cutucado → passa; a wave
# avançou (waves_concluidas mudou) → cutuca de novo, uma vez.
#
# Fallback gracioso: sem python3, sem cwd, sem arquivo de estado → exit 0
# (nunca trava o fluxo); sem git dir para a janela → comporta-se como antes
# (cutuca 1× por encerramento). stop_hook_active evita loop dentro do turno.

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

session_id="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id", ""))' 2>/dev/null || echo "")"

n=0
alheio=0
detalhes=""
for f in "$cwd"/thoughts/local/run-state-*.md; do
  [ -f "$f" ] || continue
  grep -q '^status: em_andamento' "$f" 2>/dev/null || continue
  n=$((n + 1))
  campos="$(grep -E '^(slug|plan|waves_concluidas|waves_total|retomada|sessao):' "$f" 2>/dev/null | sed 's/^/    /' || true)"
  # Posse (decisão 4.251): run cuja `sessao:` aponta outra sessão viva não é deste
  # turno — a mensagem muda para a terceira saída. Sem session_id no payload ou sem
  # o campo (formato antigo/"desconhecida") → comporta-se como antes, nunca acusa.
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$f" 2>/dev/null | sed -n 1p)"
  if [ -n "$session_id" ] && [ -n "$dono" ] && [ "$dono" != "desconhecida" ] && [ "$dono" != "$session_id" ]; then
    alheio=1
  fi
  detalhes="${detalhes}
— ${f#"$cwd"/}:
${campos}"
done

if [ "$n" -eq 0 ]; then
  exit 0
fi

# Válvula por estado (4.165): fingerprint dos campos do run — janela append-only.
# Composto com o session_id do LEITOR (padrão do skill-standards-nudge): o marcador
# é por repo, e sem o id a sessão A engoliria a cutucada devida à sessão B — o caso
# exato que a terceira saída (4.251) existe para tratar.
git_dir="$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-wave-guard.recent"
  fingerprint="$(printf '%s\n%s' "$session_id" "$detalhes" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && grep -qxF "$fingerprint" "$marker" 2>/dev/null; then
    exit 0
  fi
fi

if [ "$alheio" = "1" ]; then
  reason="Guarda de waves (decisão 4.23): há run do keelson EM ANDAMENTO cujo campo 'sessao' aponta OUTRA sessão — posse de terceiro, não é seu (decisão 4.251).
${detalhes}

Isto não é 'fôlego': a regra 'fôlego não é gatilho' veta parar o SEU run — ela não autoriza continuar nem encerrar o run dos outros, e nenhuma das duas saídas habituais é segura aqui (continuar entraria na worktree de uma sessão viva; marcar 'encerrado' apagaria o checkpoint dela no meio de uma TASK). Faça a TERCEIRA saída:
1. NÃO edite o arquivo alheio, NÃO continue a wave dele, NÃO o marque 'encerrado' nem o remova.
2. INVENTARIE: mtime do run-state, 'git status' da worktree apontada em 'retomada', sessões/processos pares vivos.
3. ESCALE o achado ao humano na sua resposta, nomeando o run, o dono e o inventário.
Se algum run acima pertencer a ESTA sessão (campo 'sessao' igual à sua), esse continua normalmente. Só então encerre."
else
  reason="Guarda de waves (decisão 4.23): há run do keelson com status EM ANDAMENTO — encerrar o turno agora deixaria o trabalho parado no meio, com o humano ausente.
${detalhes}

Fôlego não é gatilho: sessão longa, contexto sumarizado ou \"ponto limpo\" não autorizam parar. Faça agora UMA das duas coisas:
1. CONTINUE: leia os artefatos apontados em 'retomada' (INDEX do slug + TASK-INDEX), execute a próxima wave e siga até a Entrega. Os artefatos SDD são o checkpoint — nada se perdeu. (Agents em voo em background contam como continuar: encerre o turno e reaja às notificações — este aviso não se repete para este mesmo estado do run.)
2. Se a parada é LEGÍTIMA (Entrega já concluída, degrau 3 da escada com a pergunta já disparada, ou pedido explícito do humano NESTA execução): atualize o arquivo acima para 'status: encerrado — <motivo>' (ou remova-o) e aí sim encerre.
Não encerre sem fazer uma das duas. (Exceção de posse, decisão 4.251: run cujo campo 'sessao' aponte OUTRA sessão viva não é seu — esse não se continua nem se encerra; inventarie e escale ao humano.)"
fi

if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s\n' "$fingerprint" >> "$marker" 2>/dev/null || true
  # Truncamento fora do caminho quente (mesma régua do agent-guard, 4.141).
  if [ "$(wc -l < "$marker" 2>/dev/null || echo 0)" -gt 40 ]; then
    tail -n 20 "$marker" > "$marker.$$" 2>/dev/null && mv -f "$marker.$$" "$marker" 2>/dev/null || rm -f "$marker.$$" 2>/dev/null || true
  fi
fi

printf '%s' "$reason" | python3 -c 'import sys,json; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))' 2>/dev/null || exit 0

exit 0
