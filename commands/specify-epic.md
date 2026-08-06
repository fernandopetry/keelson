---
description: Decompõe uma demanda grande (épico) em demandas independentes priorizadas via agente PM, grava o BRIEF épico e devolve a fila — cada demanda segue seu próprio ciclo SDD
argument-hint: <pedido épico ou @arquivo> [--slug=<âncora>]
---

# /keelson:specify-epic

Você é o **Tech Lead** conduzindo a camada de **portfólio** do time (modelo de time — decisões 4.37/4.39): um pedido do Diretor grande demais para uma demanda é decomposto pelo **PM** em demandas independentes e priorizadas. Este comando **não executa ciclos**: entrega a fila; disparar cada ciclo é ato do Diretor.

**Modo**: humano presente. A confirmação da decomposição pelo Diretor é **intencional** (cláusula de modo — 4.33): decomposição errada contamina N ciclos — é "ambiguidade que muda o resultado" em escala.

## Input

```
/keelson:specify-epic <pedido épico em linguagem natural ou @arquivo> [--slug=<âncora>]
```

**BRIEF forjado é entrada de primeira classe (decisão 4.128)**: `@arquivo` apontando um
BRIEF do `/keelson:brief` (path em `briefs/`, seções da forja presentes) → não é um
documento qualquer: o inventário, os `## Fatos do código`, as premissas com selo e as
`## Perguntas` pendentes **viajam** — ver Etapas 1 e 3.

## Etapa 0: resolver o slug-âncora

O brief épico mora no slug que a iniciativa gravita. Aplicar a regra canônica de resolução (Etapa 0.2 do `/keelson:specify`): slug existente cujo domínio cubra a iniciativa → use-o (legado → migrar primeiro); domínio genuinamente novo → proponha slug kebab-case e **confirme com o Diretor**. Não existe "slug portfólio": iniciativa que merece épico merece slug.

## Etapa 1: decomposição pelo PM

Invocar o agent `pm` com: o pedido épico **verbatim**, a lista dos slugs de `{docsRoot}/` (com 1 linha de resumo do INDEX de cada um) e o contexto que você tiver. O PM devolve `demandas[]` priorizadas + `perguntas_ao_diretor[]`.

**Entrada é BRIEF forjado (4.128)** → o PM recebe o **BRIEF inteiro** no prompt (não um resumo): os fatos do código informam o corte das fatias, e cada premissa com selo e cada Q-ID pendente é **atribuída à fatia que a toca** na decomposição devolvida.

## Etapa 2: confirmação do Diretor

1. Apresente a decomposição **no corpo da conversa**, em tabela: prioridade · título · resumo · slug de destino · dependências · riscos. Inclua as `perguntas_ao_diretor` (cada uma com proposta + default).
2. **Estratégia de branch (decisão 4.126)**: junto da tabela, proponha a estratégia — default **`unica`** (todas as fatias empilhadas em `feat/<slug>-<descricao-curta>`, sync com a main a cada fronteira de fatia, um PR ao final) · `por-fatia` (fatias genuinamente paralelas, com pessoas diferentes — cada uma na sua branch, regra 4.119 pura). A escolha entra na mesma confirmação abaixo.
3. **Só então** confirme via AskUserQuestion com pergunta **curta** (ex.: *"A decomposição acima está certa?"*, opções "Confirmo" / "Ajustar") — **nunca** embuta a tabela na pergunta (mesma lição do espelho, 4.14). Pediu ajuste → reapresente ajustada e confirme de novo.

## Etapa 3: persistir o BRIEF épico

1. Gravar `{docsRoot}/<slug-âncora>/briefs/BRIEF-<yyyy-mm-dd>-<descricao-curta>-epic.md` (contrato do BRIEF no `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`, variação épico): cabeçalho com `**Branch**:` + `**Estratégia**:` (4.126) e `**Origem**:`, pedido épico **verbatim**, perguntas respondidas e a decomposição confirmada como **fila viva** (4.125) — tabela com coluna `Estado`: fatias nascem `pendente`, exceto fatia cuja Q-ID `[bloqueia-núcleo]` pende de produto → nasce `aguardando-produto (Q-NN)`. `Status: Emitido`; o épico **não pareia com SPEC**. Entrada era BRIEF forjado (4.128) → atualize-o para `Status: decomposto` + caminho do épico (trilha nos dois sentidos; o NNN reservado dele não gera SPEC).
2. **Semear o `MAP.md` do slug** (decisão 4.104 — contrato: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/map-contract.md`): a exploração que sustentou a decomposição (memo, "Fatos do código" da forja quando houver) vira entradas canônicas datadas em `{docsRoot}/<slug-âncora>/MAP.md` — as fatias leem o território sem re-explorar, e cada closure delas anexa o delta. MAP já existente → mesclar, re-datando o que esta decomposição re-verificou.
3. Se o slug-âncora tem `INDEX.md`: 1 linha no `## Histórico recente` — `<data>: épico decomposto em N demandas via /keelson:specify-epic (BRIEF-...-epic)` — e a linha do MAP no cabeçalho (template do index-contract), se ele nasceu agora.

## Etapa 4: output — a fila do Diretor

1. Caminho do brief épico.
2. A fila priorizada (tabela confirmada, com estados).
3. Comando pronto para a demanda 1: `/keelson:auto "<título/resumo da demanda 1> (épico: <caminho do BRIEF épico>)" --slug=<slug de destino>` — quando o ciclo da filha rodar, o brief dela grava `**Epico**:` apontando ao pai.
4. **A retomada tem porta única (decisão 4.127)** — deixe em bloco copy-paste, e diga com todas as letras que é a única coisa a decorar:

   ```
   Para continuar este épico a qualquer momento (amanhã, segunda-feira, outra sessão):
   /keelson:continue <slug-âncora>
   ```

   O `continue` lê a fila e propõe o próximo passo — ninguém precisa lembrar qual fatia é a próxima nem como compor o comando.
5. Deixe explícito: **disparar cada ciclo é decisão do Diretor** — este comando não inicia nenhum.

## Limites

Não executa ciclos nem invoca `/keelson:auto`, não cria SPEC/PLAN/TASK, não re-decompõe pós-largada de um ciclo (expansão de escopo descoberta no meio é escalação do PO — 4.38), e o único registro que faz é o brief épico + a linha de histórico.
