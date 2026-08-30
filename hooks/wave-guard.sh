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
# Descendência (decisão 4.298): subagent/teammate tem session_id próprio e lia o
# run do PRÓPRIO lead como "de terceiro", gastando turnos para concluir não-ação
# (caso real de campo). Antes de acusar, o guard sobe a ancestralidade de PPIDs
# do próprio processo: um ancestral cuja invocação carrega
# `--parent-session-id <dono>` prova que ESTE processo é da equipe do dono — o
# run é do lead, não é meu para continuar/encerrar nem para inventariar → aquele
# arquivo sai da checagem em silêncio. A decisão é POR ARQUIVO: um run meu no
# mesmo diretório continua cobrado. Falha de `ps`/parse degrada para a acusação
# de posse atual (nunca para silêncio — erro de leitura não vira absolvição).
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

# Descendência (4.298): devolve 0 se algum ancestral do próprio processo carrega
# `--parent-session-id <dono>` na invocação — a marca que o harness põe no
# processo de subagent/teammate (amostra de campo na fixture da suíte). Qualquer
# falha de ps/parse devolve 1: o run segue acusado como de terceiro (degradação
# preserva a mensagem de posse, nunca silencia). Bounded: 20 saltos.
descende_do_dono() {
  _dono="$1"; _pid=$$; _hops=0
  while [ "$_hops" -lt 20 ]; do
    _linha="$(ps -ww -o ppid=,command= -p "$_pid" 2>/dev/null | sed -n 1p || true)"
    [ -n "$_linha" ] || return 1
    case "$_linha" in
      *"--parent-session-id $_dono"*|*"--parent-session-id=$_dono"*) return 0 ;;
    esac
    _novo="$(printf '%s\n' "$_linha" | awk '{print $1}')"
    case "$_novo" in ''|*[!0-9]*) return 1 ;; esac
    [ "$_novo" -le 1 ] && return 1
    [ "$_novo" = "$_pid" ] && return 1
    _pid="$_novo"; _hops=$((_hops + 1))
  done
  return 1
}

n=0
alheio=0
detalhes=""
# casa da sessão (4.314) + caminho legado: run de qualquer sessão desta máquina
# é visto — a posse (4.251) decide o que fazer com ele
for f in "$cwd"/thoughts/local/run-state-*.md "$cwd"/thoughts/local/sessions/*/run-state-*.md; do
  [ -f "$f" ] || continue
  grep -q '^status: em_andamento' "$f" 2>/dev/null || continue
  # Posse (decisão 4.251): run cuja `sessao:` aponta outra sessão viva não é deste
  # turno — a mensagem muda para a terceira saída. Sem session_id no payload ou sem
  # o campo (formato antigo/"desconhecida") → comporta-se como antes, nunca acusa.
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$f" 2>/dev/null | sed -n 1p)"
  if [ -n "$session_id" ] && [ -n "$dono" ] && [ "$dono" != "desconhecida" ] && [ "$dono" != "$session_id" ]; then
    # Equipe do dono (4.298): run do meu lead não é meu nem de terceiro — este
    # arquivo sai da checagem; a decisão é por arquivo (um run MEU ao lado
    # continua cobrado).
    if descende_do_dono "$dono"; then
      continue
    fi
    alheio=1
  fi
  n=$((n + 1))
  campos="$(grep -E '^(slug|plan|waves_concluidas|waves_total|retomada|sessao):' "$f" 2>/dev/null | sed 's/^/    /' || true)"
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
