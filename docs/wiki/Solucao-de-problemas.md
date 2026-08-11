# Solução de problemas

Sintomas comuns, a causa provável e o que fazer.

## Instalação e comandos

### Os comandos `/keelson:*` não aparecem

O plugin não está carregado na sessão. Na ordem:

1. Confira a instalação em `/plugin`.
2. **Reinicie a sessão** do Claude Code — plugin recém-instalado ou recém-atualizado só
   entra em sessão nova.
3. Ainda nada? Reinstale: `/plugin marketplace add fernandopetry/keelson` e
   `/plugin install keelson@keelson`.

### Atualizei, mas o comportamento é o antigo

Esperado: **o update não vale para a sessão corrente**. Reinicie a sessão.

E lembre que são dois passos — atualizar o marketplace sozinho não atualiza o plugin
instalado. `/keelson:update` faz os dois na ordem certa.

### O comando reclama que não achou a ficha

Você está fora da raiz do repositório, ou o projeto ainda não foi configurado. Rode
`/keelson:init` **de dentro da raiz** do repositório consumidor (é lá que mora
`keelson.config.json`).

## Gates que reprovam

### O gate de testes reprova, mas os testes passam na minha mão

O `quality.test` da [ficha](Ficha-do-projeto) não é o comando real do projeto — o gate
está rodando outra coisa (ou nada). Corrija na ficha e rode de novo. Mesma causa vale para
`lint`, `typecheck` e `build`.

### A entrega parou por mutantes sobreviventes

A suíte passou, mas o comando `quality.mutation` da [ficha](Ficha-do-projeto) saiu com
erro — mutantes sobreviveram além do threshold que **você** configurou no próprio
comando. Vale tanto no fecho do `/keelson:auto` quanto no `/keelson:integrate` (que
reaproveita, com dispensa declarada, uma rodada verde do ciclo quando o código não
mudou desde ela). Isso significa que existe comportamento que pode regredir sem que teste algum
acuse: o report lista os sobreviventes. Dois caminhos legítimos: fortalecer as asserções
dos testes apontados, ou recalibrar o threshold no comando da ficha (decisão sua — o
keelson não define score mínimo). Remover o campo desliga o gate por completo: ele é
opt-in.

### O gate de comportamento (9) ficou pendente

O keelson **não finge** que verificou. A pendência vem com a causa nomeada:

| Causa | O que fazer |
|---|---|
| Runtime de browser ausente | `npx playwright install chromium` (Linux: `--with-deps`) |
| Servidor MCP não configurado | Configure o `@playwright/mcp` e **reinicie a sessão** |
| Credencial ausente | Preencha o `keelson.local.json` (realm, `baseUrl`, login de dev) |
| App fora do ar | Suba a aplicação, ou preencha `quality.boot` para que o gate saiba subir |
| Ambiente sem tela (worktree, nuvem) | O ciclo gera um [handoff de verificação](Handoff-de-verificacao); feche-o com `/keelson:verify-handoff` numa sessão com tela |

Uma entrega com handoff aberto é **parcial** até o handoff ser fechado — isso é
intencional.

### O validator marcou ERROR e travou a promoção

`ERROR` bloqueia mesmo: SPEC/PLAN não vai a `Approved`, TASK vira `Blocked`. Ou você
corrige o artefato, ou registra um **override consciente** — um bloco declarado no próprio
artefato, no formato definido pelo protocolo dos validators. Não existe "ignorar em
silêncio".

### O perfil de linguagem está marcado como não revisado

Perfil gerado nasce `reviewed: false` de propósito. Ele funciona, mas você deve lê-lo e
assinar embaixo. Se discordar de alguma regra, edite o perfil no seu projeto — ele é seu.

## Artefatos e estado

### O `INDEX.md` está errado ou desatualizado

Não corrija à mão: ele é gerado e a próxima execução sobrescreve.

```
/keelson:rebuild-index <slug>
```

Ele faz backup do INDEX atual antes. Se apontar inconsistências críticas (FRs órfãos,
PLAN sem SPEC), pergunta antes de prosseguir.

> Achados de migração legada vêm do `legacy/TRIAGE-*.md`. **O que não estiver no TRIAGE se
> perde no rebuild** — se você anotou algo direto no INDEX, mova para o TRIAGE antes.

### Um slug antigo não é reconhecido pelos comandos

Pasta de docs sem `INDEX.md` é slug legado:

```
/keelson:migrate-legacy <slug>
```

Migre **antes** de qualquer outra coisa naquele slug. A migração não cria SPECs
retroativas — o histórico keelson começa ali.

### Apareceu senha em trace, screenshot ou contexto de erro do E2E

A saída de execução da suíte E2E autenticada é **material sensível**: o setup de login
digita a credencial, e qualquer captura ativa naquele momento a grava. O setup guiado
atual (`/keelson:e2e-setup`) já gera o esqueleto com `trace: 'off'` e `screenshot: 'off'`
nos projects de setup — se o seu foi gerado antes disso, re-rode o comando (modo reparo)
ou aplique os dois `off` à mão. Duas coisas não mudam com config: o contexto de erro de
uma falha sempre carrega snapshot da página (credencial inclusa), então a pasta de saída
(`thoughts/e2e/`) precisa estar gitignored **comprovadamente** (`git check-ignore`); e
essa saída nunca deve virar artefato publicado de CI.

### A sessão não encerra o turno

Há um ciclo em andamento. O hook de wave lê o arquivo de estado da execução
(`thoughts/local/run-state-<slug>.md`) **fora do contexto do modelo** e bloqueia o
encerramento enquanto o status for `em_andamento`. Ou deixe o ciclo terminar, ou peça
explicitamente para parar — aí o estado é encerrado com o motivo registrado.

## Ciclo e comportamento do time

### Pedi uma coisa e veio outra

Leia o **brief** (`<docsRoot>/<slug>/briefs/BRIEF-NNN.md`): é contra ele que o PO valida a
entrega. Se a interpretação do PO estava torta, é aí que se corrige — a correção reemite o
brief. A janela de veto existe justamente para isso; se você não estava olhando na hora,
corrija e reemita.

### O ciclo fez perguntas demais / de menos

- Perguntas demais antes da largada: o pedido tinha ambiguidade crítica. Use
  `/keelson:refine` para lapidar a ideia antes, ou seja mais específico no pedido.
- Nenhuma pergunta e o resultado saiu torto: ambiguidade menor vira premissa `[assumido]`
  no artefato. Revise as premissas na SPEC — elas ficam explícitas.
- Quer aprovar etapa a etapa: `/keelson:guided`.

### O pedido é grande demais

Dois ou mais recursos independentes, dois ou mais slugs prováveis, um roadmap numa frase:

```
/keelson:specify-epic "<pedido grande>"
```

O PM decompõe em demandas priorizadas e **você confirma a decomposição** — depois cada
demanda segue seu próprio ciclo.

### Uma mudança pequena está levando horas em rodadas de review

O sintoma: reviewer acha algo, developer corrige, a correção reabre os gates, e as
últimas rodadas discutem só comentários — que o próprio processo gerou. Desde a decisão
4.88 isso tem régua de **convergência**: re-review é sobre o **delta** da correção
(nunca o diff inteiro de novo), um gate que reprova duas vezes **escala para você** com
proposta em vez de rodar uma 3ª vez sozinho, e correção que só muda comentário/doc não
reabre os gates de comportamento. Se uma sessão entrar nesse loop mesmo assim, mande
parar e fechar declarando o estado dos gates — e rode `/keelson:postmortem`: a mensagem
ao mantenedor é o caminho de correção do processo.

## Jira

### O ciclo terminou e o Jira não soube de nada

A sincronização é *best-effort*: ela nunca bloqueia o ciclo, mas **sempre registra**. Uma
linha no `INDEX.md` do slug diz o motivo do pulo e a evidência da sondagem. Para
reconciliar depois:

```
/keelson:jira-sync <slug>
```

É idempotente — pode rodar quantas vezes quiser. Use `--dry-run` para ver a projeção antes.

### A criação de issues falhou por campo obrigatório ou hierarquia

- **Campo obrigatório:** o sync consulta o *createmeta* antes de criar em lote, então você
  ouve isso antes da primeira criação. Preencha o mapa de campos (`jira.mapFile`).
- **Hierarquia que não aninha:** o Jira só liga níveis estritamente adjacentes. O
  `/keelson:init` valida o seu mapeamento de tipos e avisa qual perna não fecha, com o tipo
  correto.

### A Story ficou concluída no fim do ciclo

Isso é bug, não sucesso. O estado-alvo ao fim do ciclo é: sub-tasks concluídas, Story na
coluna de "pronto para QA" esperando você, Epic intocado. Concluir a Story é **ato seu**
(`/keelson:jira-sync <slug> --phase finish-dev`, ou na mão).

### O `jira.<PROJECT>.md` está crescendo com listas de issues

O mapa é **config, nunca ledger**: as três seções do protocolo (Campos, Etapas/Colunas,
Trilho do board) mais notas de manutenção — e só. Se ele acumulou seções por SPEC com a
árvore de issues criada (keys, sub-tarefas, estado do quadro), isso é contaminação de
alguma sessão antiga que virou "convenção" do arquivo: nada na doutrina manda anotar ali,
e a informação já vive nos artefatos SDD (linhas `**Jira**:`) e no próprio Jira. **Pode
podar sem perder nada.** O `/keelson:init` aponta o problema
(`mapa com registro de execução — config, não ledger`), mas a poda é sua — o arquivo é
do humano. Atenção a notas do próprio mapa que pedem a anotação ("lacuna declarada"):
lacuna de ledger não é lacuna, é o sintoma se perpetuando.

## Nada disso resolveu

- `/keelson:status <slug>` mostra o estado real do slug.
- `/keelson:review` roda a doutrina sobre um diff avulso, mesmo sem artefato SDD.
- `/keelson:postmortem`, no fim da sessão, investiga **por que** o processo deixou passar e
  gera a mensagem pronta para o mantenedor do plugin.
- Bug ou lacuna no próprio keelson: abra uma
  [issue](https://github.com/fernandopetry/keelson/issues).
