---
description: Pausa o ciclo em curso num ponto seguro, a pedido do Diretor — espera a closure em voo, exige árvore limpa, grava a marca de pausa commitada e pushada na Cronologia do BRIEF, para o continue medir o tempo parado de qualquer máquina
argument-hint: "[motivo]"
disable-model-invocation: true
---

# /keelson:pause

Você é o **Tech Lead** recebendo do Diretor o pedido de **parar num ponto seguro**. Este
comando é a forma mecânica do "pare em um lugar seguro" — a única parada antecipada que
"fôlego não é gatilho" admite (pedido explícito do humano nesta execução, decisões
4.23/4.24) — e faz a pausa virar **fato commitado**: a linha `- pausa:` na `## Cronologia`
do BRIEF (contrato: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`),
que o `/keelson:continue` lê de qualquer máquina e fecha com a marca de retomada
(decisão 4.382). Mecânica: `${CLAUDE_PLUGIN_ROOT}/scripts/pause.sh` — a marca é
**medida** pelo script, nunca escrita de memória (4.151/4.156).

**Princípio inviolável 1**: só o Diretor pausa. Duração da sessão, contexto, custo ou
"ponto limpo" não são pausa — sem este comando (ou o pedido explícito dele nesta
execução), o ciclo segue até a Entrega.

**Princípio inviolável 2**: ponto seguro é **closure commitada**, nunca árvore com
trabalho em voo. Pausar não é abandonar TASK no meio.

**Princípio inviolável 3**: a pausa **fecha** o `run-state` (`close`), nunca o remove —
o continue na mesma máquina lê o run encerrado como sugestão rotulada (4.315);
cross-máquina, só a marca commitada **e pushada** viaja.

## Input

```
/keelson:pause [motivo]
```

Raiz do repo em todos os passos: `git rev-parse --show-toplevel` do working tree
principal.

## Etapa 0: pré-condições (falhou uma → parar e dizer; nada é escrito)

1. **Run desta sessão em andamento**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run-state.sh"
   <raiz> show <slug>` para o slug em curso (o `slug:` do run desta sessão; sem saber
   qual, liste os `run-state-*.md` da casa da sessão — `session-dir.sh <raiz> dir`). Sem
   run `em_andamento` → responda *"nada em andamento — não há ciclo para pausar"* e
   encerre: sessão livre não tem o que pausar (a mudança sob demanda fecha com o
   relatório). Run `em_andamento` de **outra** sessão → terceira saída da posse (4.251):
   não pausa, inventaria e escala ao Diretor; `FORCE=1` não é saída.
2. **Warroom ativo nesta sessão** (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" <raiz>
   status`) → não há run (os dois estados se excluem): aponte `/keelson:warroom close`,
   que fecha a janela e cobra a dívida.

## Etapa 1: chegar ao ponto seguro

1. **Inventário do que está em voo**: agents em background (lista de tasks do harness),
   TASK `In Progress`, wave com closure pendente; ciclo em modo teams → confira também a
   mesa de processos (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/agent-teams.md`,
   4.303b). **Nada novo é despachado** depois do pedido — nem TASK, nem wave, nem gate
   além dos que a closure em curso exige.
2. **Espere o que está em voo fechar**: TASK em execução termina pelo rito do
   `/keelson:implement` (gates, closure §3.4.1, commit da closure); etapa de forja
   termina no commit do marco. Artefato de forja que ainda não pode fechar (validação
   pendente) é commitado **no Status em que está** — `Draft` é Status legal e o continue
   deriva dele: `git commit -m "docs(<slug>): <artefato> draft (pause)" -- <arquivo>`.
   Declare a espera ao Diretor em uma linha (*"aguardando a closure de TASK-MMM-XXX para
   pausar"*) — o turno segue até ela.
3. **Árvore limpa no escopo**: `git status --porcelain -- <docsRoot>/<slug> <codePaths da
   ficha>` vazio. Sujo → liste os arquivos e pare: commitar ou descartar trabalho fora do
   rito é ato do Diretor, não pausa.
4. **Último veredito cobre o código**: os stop-guards (`review-guard`, `security-guard`)
   voltam a vigiar assim que o run fecha — são a rede da sessão livre. Cutucada deles ao
   encerrar = o ponto **não** era seguro (código sem veredito que o cubra): despache o gate
   faltante pelo rito da wave e só então repita a pausa. Nunca encerre por cima da
   cutucada.

## Etapa 2: marcar, commitar, pushar, encerrar

1. **Nomeie o ponto** (uma linha): `TASK-MMM-XXX closure (wave N de M)` · `SPEC-NNN
   Draft` · `PLAN-MMM commitado` · `TASKs commitadas, wave 1 não iniciada`.
2. **Marca**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/pause.sh" <raiz> mark-pause <slug>
   --ponto "<ponto>" [--motivo "<motivo do Diretor>"]` — ecoa `brief` e `linha`. Exit 3
   (nenhum BRIEF ativo — TASK avulsa ancorada em PLAN, sem brief) → declare: a pausa vale
   só por-clone (run-state + ledger); o continue na outra máquina cai no piso pelo último
   commit.
3. **Ledger**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ledger.sh" <raiz> append marco
   tech-lead <slug>` com o corpo `pausa em <ponto>` (tipo `marco` do catálogo fechado,
   4.76 — é a marca que o `/keelson:report` desta sessão lê).
4. **Commit por pathspec** (4.163): `git commit -m "docs(<slug>): pause at <ponto>" --
   <BRIEF>`.
5. **Push da branch da demanda**: `git push -u origin <branch>` — exceção declarada da
   Entrega como dona do push (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`,
   "Commit por marco"): o ato é do Diretor, que invocou o comando. Falhou (sem remoto,
   offline) → o commit fica; declare que o cross-máquina depende do push dele.
6. **Encerre o run**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run-state.sh" <raiz> close
   <slug> "pausa: <ponto>"` — `close`, nunca `remove` (princípio 3). É o que libera o
   `wave-guard`.
7. **Mensagem de fecho** (≤ 6 linhas): onde parou (ponto) · marca gravada (linha literal)
   · commit e push (SHA; push ok ou falhou) · retomada: `/keelson:continue <slug>` — em
   qualquer máquina, ele mede o tempo parado e grava a retomada.

Então encerre o turno. Não há relatório de fecho aqui — a pausa não entrega nada; o
report é da Entrega, que lerá a cauda `pausas` da linha `Duração`
(`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/report-contract.md`).

## Limites

Não despacha trabalho novo; não faz PR nem merge (4.37/4.41); não pausa sessão livre nem
warroom; não decide pelo Diretor o que fazer com árvore suja; não usa `FORCE=1`; não
estima instante de pausa — sem BRIEF a marca não existe, e a retomada usa o piso pelo
commit, rotulado.
