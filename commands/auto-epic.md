---
description: Encadeia as fatias restantes de um épico sem o Diretor entre elas — revezamento desacoplado, uma sessão `claude -p` por fatia com contexto limpo; pré-voo, status e stop; merge, PR e deploy continuam humanos
argument-hint: "<slug | caminho de BRIEF épico> [status | stop] [--max-fatias N] [--timeout-min M]"
disable-model-invocation: true
---

# /keelson:auto-epic

Você é o **Tech Lead** recebendo do Diretor o pedido de rodar as fatias restantes de um
épico **sem parar entre elas** (decisão 4.465). Este comando não conduz fatia nenhuma:
ele lança o **revezamento** de `${CLAUDE_PLUGIN_ROOT}/scripts/epic-run.sh` — um processo
desacoplado desta sessão que roda **uma sessão `claude -p` por fatia**, cada uma retomando
pelo `/keelson:continue` com contexto limpo e lendo o estado do disco. Invocar este comando
**é** o ato do Diretor para o épico inteiro: a confirmação que o `continue` pediria a cada
fatia foi dada aqui, uma vez (refina a régua "disparar cada ciclo é ato do Diretor" — 4.39,
4.127).

**Princípio inviolável 1**: a fila do BRIEF épico é o único fato que decide a próxima
fatia e o fim — o revezamento relê a fila depois de cada sessão e para quando ela não
avança; nunca inventa estado novo na tabela. Este comando é também a **porta de retomada
do épico** (4.466): fatia parcial por queda, pausa ou `stop` é retomada pela sessão filha;
fatia parada **aguardando você** nunca é retomada às cegas.

**Princípio inviolável 2**: cada fatia é uma sessão **sem humano**: a regra do que ela
decide sozinha e do que a encerra sem marcar `entregue` tem dono único em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md` ("Sessão sem humano").

**Princípio inviolável 3**: merge, PR e deploy continuam humanos. O revezamento termina na
Entrega da última fatia; o PR do épico é o `/keelson:integrate`, apontado pelo `continue`.

**Princípio inviolável 4**: a sessão filha roda com `--dangerously-skip-permissions`
(decisão do Diretor, 4.465) — ninguém responderia um prompt de permissão. Declare isso na
confirmação; nunca omita.

## Input

```
/keelson:auto-epic <slug | caminho de BRIEF épico> [status | stop] [--max-fatias N] [--timeout-min M]
```

Raiz do repo em todos os passos: `git rev-parse --show-toplevel` do working tree principal.
`status` e `stop` não lançam nada — são consultas e parada do revezamento em curso.

## Etapa 0: resolver o alvo e consultar

1. Caminho de BRIEF épico → é ele. Slug → o BRIEF épico **não-concluído** mais recente em
   `{docsRoot}/<slug>/briefs/*-epic.md` (mesma regra da Etapa 0 do `/keelson:continue`).
   Sem épico → responda que o revezamento só existe para épico e aponte o `/keelson:auto`.
2. `status` → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/epic-run.sh" <raiz> status <slug-âncora>`:
   transcreva a linha (rodando com fatia, instante de início, idade do último evento e wave;
   parado com motivo; ou nenhum revezamento) e o caminho do `RESUMO.md`. Encerre.
3. `stop` → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/epic-run.sh" <raiz> stop <slug-âncora>`
   é **gracioso**: a fatia em curso termina na Entrega e a próxima não é lançada — o ponto
   seguro do revezamento é a fronteira de fatia (4.466). `stop --now` interrompe na hora e
   a fatia fica como sessão que caiu. Transcreva a saída e aponte `/keelson:auto-epic
   <slug-âncora>` (ou `/keelson:continue`) como retomada. Encerre.

## Etapa 1: pré-voo (o script decide; você mostra)

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/epic-run.sh" <raiz> launch <BRIEF> --dry-run` com as
flags que o Diretor passou. A primeira linha do stdout traz a classe (4.466):

- **`pré-voo: ok`** → siga à Etapa 2. A linha diz se o revezamento começa por fatia nova
  ou **retoma** uma fatia parcial (queda, pausa feita na sessão dela, `stop`, run de
  sessão morta): a sessão filha a retoma pelo `continue`, na wave onde parou.
- **`pré-voo: aguarda-diretor`** (exit 5) → a fatia parou por decisão sua e **não se
  retoma sem você**: transcreva o motivo, mostre o último relatório que a linha aponta
  (a pergunta pendente está nele) e execute `/keelson:continue <slug-âncora>` **nesta
  sessão**, com você presente, até a Entrega dessa fatia; só então volte à Etapa 1 para
  lançar o revezamento pelas restantes.
- **`pré-voo: posse-incerta`** (exit 6) → há run em andamento cuja sessão pode estar viva
  (tocada há menos de 20 min). Uma pergunta via AskUserQuestion: *"A sessão anterior
  morreu? Forçar a posse?"* — "Sim" → repita o dry-run com `--force-claim` (a
  confirmação viaja no prompt da sessão filha; `FORCE=1` é ato do humano, 4.431);
  "Não" → espere o limiar ou feche aquela sessão.
- **`pré-voo: recusado`** (exit 3) → transcreva e **pare**: estratégia `por-fatia`
  (fatia dependente só larga após merge, ato do Diretor — 4.190), fila na regra 1/5/6,
  árvore suja, `thoughts/` não ignorado, driver já vivo. Nada aqui se contorna.

Passou → monte o **"você está aqui"**: a fila com estados (a saída do `epic-state.sh` já
está no dry-run) e a fatia pela qual o revezamento começa ou retoma.

## Etapa 2: confirmar (uma pergunta)

**Uma** proposta via AskUserQuestion — *"Lançar o revezamento a partir da fatia N?"*,
opções "Lançar" / "Outra coisa" — precedida de três linhas fixas: (a) cada fatia roda numa
sessão própria sem humano, com `--dangerously-skip-permissions`; (b) o que encerra o
revezamento sem marcar `entregue` (regra do dono: parte estacionada que a próxima fatia
consome, degrau 3, conflito de sync, base da branch fora da default) e onde o motivo fica
(`status`, `RESUMO.md`, run-state da sessão filha); (c) a árvore não deve ser usada por
outra sessão enquanto o revezamento roda — a fatia commita em HEAD. Com `--max-fatias` ou
`--timeout-min`, diga o teto; falha de infraestrutura (rede, API) ganha nova tentativa da
mesma fatia após a espera, até `--retry` vezes (default 2). "Outra coisa" → o Diretor diz
o quê.

## Etapa 3: lançar e encerrar o turno

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/epic-run.sh" <raiz> launch <BRIEF> [flags]` —
   ecoa `revezamento: lançado · pid · dir`. Transcreva.
2. Mensagem de fecho (≤ 6 linhas): fatia inicial (nova ou retomada) · teto, se houver ·
   como acompanhar (`/keelson:auto-epic <slug> status`) · como parar (`/keelson:auto-epic
   <slug> stop`, gracioso; `--now` na hora) · onde o resumo de cada fatia aparece
   (`thoughts/local/epic-run/<slug-âncora>/RESUMO.md`) · retomada depois de qualquer
   parada: `/keelson:auto-epic <slug-âncora>` de novo (fatia que aguarda você passa pelo
   `continue` com você presente).
3. **Encerre o turno.** O revezamento leva horas e não depende desta sessão: não espere, não
   sonde o log, não abra a árvore. O `wave-guard` reconhece o run da sessão filha enquanto o
   driver está vivo (4.465) e não o acusa como posse de terceiro.

## Limites

Não conduz fatia (cada uma é uma sessão `claude -p` própria); não altera a fila nem o
vocabulário de estados dela (4.156); não decide permissão por conta própria além do que a
4.465 fixou; não faz merge, PR nem deploy (4.37/4.41); não relança sobre driver vivo nem
sobre run de sessão viva sem a sua confirmação; não retoma fatia parada `aguarda Diretor`
sem você presente; não responde pelo Diretor às perguntas estacionadas — elas ficam nos
relatórios de cada fatia (`RESUMO.md`) e no ledger da sessão filha, e nada estacionado é
aplicado sem resposta.
