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

## Etapa 0: resolver o slug-âncora

O brief épico mora no slug que a iniciativa gravita. Aplicar a regra canônica de resolução (Etapa 0.2 do `/keelson:specify`): slug existente cujo domínio cubra a iniciativa → use-o (legado → migrar primeiro); domínio genuinamente novo → proponha slug kebab-case e **confirme com o Diretor**. Não existe "slug portfólio": iniciativa que merece épico merece slug.

## Etapa 1: decomposição pelo PM

Invocar o agent `pm` com: o pedido épico **verbatim**, a lista dos slugs de `{docsRoot}/` (com 1 linha de resumo do INDEX de cada um) e o contexto que você tiver. O PM devolve `demandas[]` priorizadas + `perguntas_ao_diretor[]`.

## Etapa 2: confirmação do Diretor

1. Apresente a decomposição **no corpo da conversa**, em tabela: prioridade · título · resumo · slug de destino · dependências · riscos. Inclua as `perguntas_ao_diretor` (cada uma com proposta + default).
2. **Só então** confirme via AskUserQuestion com pergunta **curta** (ex.: *"A decomposição acima está certa?"*, opções "Confirmo" / "Ajustar") — **nunca** embuta a tabela na pergunta (mesma lição do espelho, 4.14). Pediu ajuste → reapresente ajustada e confirme de novo.

## Etapa 3: persistir o BRIEF épico

1. Gravar `{docsRoot}/<slug-âncora>/briefs/BRIEF-<yyyy-mm-dd>-<descricao-curta>-epic.md` (contrato do BRIEF no `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`, variação épico): pedido épico **verbatim** + decomposição confirmada (a tabela da Etapa 2) + perguntas respondidas. `Status: Emitido`; o épico **não pareia com SPEC**.
2. Se o slug-âncora tem `INDEX.md`: 1 linha no `## Histórico recente` — `<data>: épico decomposto em N demandas via /keelson:specify-epic (BRIEF-...-epic)`.

## Etapa 4: output — a fila do Diretor

1. Caminho do brief épico.
2. A fila priorizada (tabela confirmada).
3. Comando pronto para a demanda 1: `/keelson:auto "<título/resumo da demanda 1> (épico: <caminho do BRIEF épico>)" --slug=<slug de destino>` — quando o ciclo da filha rodar, o brief dela grava `**Epico**:` apontando ao pai.
4. Deixe explícito: **disparar cada ciclo é decisão do Diretor** — este comando não inicia nenhum.

## Limites

Não executa ciclos nem invoca `/keelson:auto`, não cria SPEC/PLAN/TASK, não re-decompõe pós-largada de um ciclo (expansão de escopo descoberta no meio é escalação do PO — 4.38), e o único registro que faz é o brief épico + a linha de histórico.
