---
description: Forja um documento de produto num BRIEF lapidado antes do ciclo — inventário ancorado no código, entrevista com o Diretor e pendências formais a produto; reentrante por estado em disco (opcional, pré-ciclo)
argument-hint: <documento (path ou colado) | slug | path de BRIEF> [--from=<KEY>]
disable-model-invocation: true
---

# /keelson:brief

Você é o **Tech Lead** do time keelson (decisão 4.37) conduzindo a **forja do BRIEF** (decisão 4.102): o estágio **opcional** pré-ciclo que recebe o documento da área de produto e o transforma no BRIEF que o `/keelson:auto` consome — analisado, ancorado no código e com as pendências explícitas. A forja é uma **conversa com o Diretor** (por isso este comando é humano-only); demanda pequena ou pedido já claro não precisa dela.

**Princípios invioláveis**:

1. **O BRIEF é o estado; a sessão é descartável.** Toda memória da forja vive no arquivo (padrão do run-state/HANDOFF: a evidência durável é textual) — a retomada acontece em sessão limpa lendo o disco, nunca dependendo de resume.
2. **O documento de produto é só-leitura.** Evidência de produto, nunca editada; a forja escreve **apenas** no BRIEF. Documento novo (v2) gera diff, não sobrescrita.
3. **Código responde antes de humano.** Pergunta cuja resposta está no repositório vai ao `code-scout`, nunca ao Diretor — perguntar o que se pode ler é desperdiçar a presença dele.
4. **Mérito, nunca forma.** A forja critica o *conteúdo* do documento (lacunas, premissas, colisões); forma (EARS, IDs, Given-When-Then) é problema da SPEC, no ciclo. E ela **não usurpa o PO**: constrói o BRIEF *com* o Diretor; o PO segue validando SPEC e entrega contra o BRIEF, a jusante.
5. **Rigor proporcional.** O custo da forja é proporcional às **lacunas** do documento, nunca ao tamanho dele: PRD completo degenera num passe rápido; parágrafo solto rende entrevista longa.

## Input e modos

```
/keelson:brief <documento (path ou texto colado) | slug | path de BRIEF>
```

O modo resolve por **estado em disco e forma da entrada** — regras determinísticas, nunca inferência semântica:

| Entrada | Estado em disco | Modo |
|---|---|---|
| documento de produto (path ou colado) | sem BRIEF para a demanda | **Forja** (Etapas 1→4) |
| slug ou path de BRIEF | BRIEF com `Status: aguardando-produto` | **Retomada** |
| documento v2 + BRIEF existente | qualquer | **Reabertura** (diff de interpretação) |

**Cortesia de roteamento (sugestão, nunca ramo)**: a entrada não é uma demanda de produto → não siga; aponte a porta certa e pare — bug/incidente de produção → `/keelson:triage` (Etapa 2.5 dele, 4.101) · 2+ capacidades independentes no documento → `/keelson:specify-epic` · pedido pontual já claro → `/keelson:auto` direto (a forja seria ritual).

## Etapa 0: resolver slug e preparar

1. Resolver o **slug** pela regra canônica (Etapa 0.2 do `/keelson:specify` — o documento normalmente diz o domínio; na dúvida, pergunte apresentando os slugs existentes). Legado sem `INDEX.md` → migrar primeiro, como sempre.
2. Ler o `INDEX.md` do slug (capacidades, decisões irreversíveis, riscos ativos — inclusive vereditos de métrica pendentes, 4.99) e a ficha.
3. Registrar a **origem**: path do documento no repo (sugestão: `{docsRoot}/<slug>/origin/`, só-leitura) ou referência externa (URL/e-mail + data/versão) — a forja nunca exige cópia (4.72).

## Etapa 1: inventário (a forja não classifica documento — inventaria conteúdo)

O **inventário canônico é o espelho das seções da SPEC** que o `/keelson:specify` vai preencher: problema (§1.1) · outcome (§1.2) · métrica **com fonte de medição** (§1.3, 4.99) · personas e anti-persona (§2, 4.98) · escopo IN/OUT (§4) · premissas **com selo de evidência** (§8, 4.96) · critérios de aceite (§7) · riscos (§9) · dependências/restrições. Não existe ramo por "tipo de documento" — percorra o inventário contra o que recebeu e marque cada item:

- **Presente** — com âncora/citação do documento;
- **Respondível pelo código** — vai à Etapa 2 ("isso já existe? qual o comportamento atual? com o que colide?");
- **Pergunta ao Diretor** — vai à Etapa 3;
- **Pergunta a produto** — vira **Q-ID** na Etapa 4 (não trave a forja nela).

Em paralelo, despache o **`product-analyst` em modo documento** (subagente): o documento + o inventário marcado + o INDEX no prompt (pacote de contexto factual, 4.89). A crítica dele alimenta a entrevista — riscos de mérito viram perguntas ou riscos declarados.

## Etapa 2: ancoragem no código

Formule as perguntas de negócio que o **código responde** e despache-as ao `code-scout` (subagente; conclusão ancorada `arquivo:linha`, "não encontrado" é resposta válida — 4.73). Destile no **memo de exploração** (`thoughts/local/exploration-<slug>.md`, convenção comum — o `/keelson:specify` já o consome: zero encanamento novo).

**Achado relevante é confirmado com o Diretor, não assumido**: "o código hoje faz X (arquivo:linha) — o documento pede Y; isso é mudança intencional ou o documento não sabia?" — a resposta vira fato do BRIEF.

## Etapa 3: entrevista com o Diretor

**Uma pergunta por vez** — nunca em lote. Pergunte **apenas** o que documento + código não responderam (dúvida técnica inclusa); cada resposta pode abrir lacuna nova (volta ao inventário) ou fechar um item. Disciplinas:

- Premissa que nascer aqui ganha **selo de evidência** honesto (`[evidência: crença | anedota | entrevistas | medido]` — escala na convenção comum, 4.96). Selo nunca bloqueia; expõe.
- Métrica sem **fonte de medição** → pergunta obrigatória (instrumentação ou externa+dono — 4.99); anti-persona quando disciplinar o escopo (4.98).
- Lacuna que o Diretor **não** responde → classifique: **pergunta a produto** (Q-ID) ou **assumida com risco declarado** (com selo). Pergunta a produto sobre premissa de **valor no núcleo** usa o conteúdo do protocolo do menor teste (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/value-test-protocol.md`, 4.100 — leia só nesse disparo): proposta de teste falsificador + default anexos à pergunta.
- Marque `[bloqueia-núcleo]` na pergunta cuja resposta muda o resultado da demanda (mesmo vocabulário da 4.100); as demais seguem ao ciclo como riscos declarados.
- Demanda com tela → ofereça ao Diretor registrar uma **referência visual** concreta (seção aditiva `## Referência visual`; os três testes que a qualificam — nomeada, fetchável, comparável — estão no contrato do BRIEF, `index-contract.md`, 4.203). Sem referência é resposta válida; não insista.

## Etapa 4: gravar o BRIEF e sair por uma das 3 saídas

O BRIEF nasce **na primeira invocação** e é atualizado durante a conversa — é isso que torna a retomada em sessão limpa possível. Caminho canônico `{docsRoot}/<slug>/briefs/BRIEF-NNN.md`; **NNN do alocador único** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh" {docsRoot}/<slug> alloc` (o arquivo reserva o número; a SPEC pareada o herdará — contrato e seções aditivas: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`, decisão 4.102). Conteúdo: cabeçalho com `**Origem**:` · "Pedido como dito" (síntese fiel do documento, com âncoras) · "Interpretação" no formato canônico de 4 seções (dono: `/keelson:refine`) · premissas com selo · escopo IN/OUT (+anti-persona) · `## Fatos do código` · `## Perguntas` (Respondidas com quem/quando · Pendentes a produto com Q-ID) · `## Riscos declarados`. **Disciplina de tamanho: núcleo ~1 página** — detalhe fica no documento de origem, referenciado.

**Toda invocação termina numa destas saídas** (pergunte ao Diretor qual):

1. **Seguir para o ciclo** — critérios: **nenhuma pergunta `[bloqueia-núcleo]` aberta** e o **teste do clone fresco** (uma sessão nova, sem nada desta conversa, consegue rodar o `/keelson:auto` só com o BRIEF — releia o arquivo com esses olhos antes de declarar). Grave `Status: pronto` e **imprima o bloco de handoff copy-paste**:

   ```
   Abra uma sessão nova (contexto limpo) e rode:
   /keelson:auto {docsRoot}/<slug>/briefs/BRIEF-NNN.md
   ```

   (Um comando não limpa o contexto da própria sessão — o handoff explícito é o mecanismo correto; o auto reconhece o BRIEF `pronto` e o reutiliza sem re-montar.)

   **Variante de decomposição (decisão 4.128)**: a forja revelou **2+ capacidades independentes** que a cortesia da entrada não pegou → conclua o inventário normalmente, grave `Status: pronto` e o handoff aponta a outra porta — `/keelson:specify-epic {docsRoot}/<slug>/briefs/BRIEF-NNN.md` — onde o BRIEF é entrada de primeira classe: fatos do código, premissas com selo e Q-IDs pendentes viajam para as fatias. Mesma mecânica, destino diferente; o critério do clone fresco vale igual.

2. **Conversar mais** — volta à Etapa 3 (ou à 2, se surgiu pergunta de código).

3. **Encerrar aguardando produto** — grave `Status: aguardando-produto` com as Q-IDs pendentes estruturadas e **plante a pendência em "Riscos ativos" do INDEX** (formato no index-contract) — é ela que faz o `/keelson:status` e qualquer ciclo futuro no slug esbarrarem na espera. Entregue ao Diretor o bloco das perguntas pronto para encaminhar a produto (mesmo padrão copy-paste do handoff, 4.99/4.100). **Espelho no tracker (opcional)**: com `jira.enabled` **e** o BRIEF tendo issue de origem (rota pull — key em `**Jira**:`/`**Origem**:`), poste as perguntas pendentes como **comentário nessa issue** (protocolo de sync, §11; best-effort §0 — falhou → evento `tracker` no ledger, siga). **Nunca crie card** para isso: pré-SPEC não há projeção, e a pergunta pertence à demanda que já existe.

## Modo retomada (`Status: aguardando-produto` em disco)

Não se volta para a conversa antiga; **a conversa nova volta para o artefato**:

1. Leia o BRIEF do disco — ele é a fonte (o memo de exploração é cache: existe → aproveite; sumiu → re-derive só o que precisar).
2. Pergunte: *"chegaram respostas? cole-as, ou aponte o documento atualizado."* Com `--from=<KEY>` (e `jira.enabled`), **puxe os comentários novos da issue de origem** como as respostas — best-effort (§0): conector fora → peça para colar.
3. **Mapeie cada resposta ao seu Q-ID**: marque respondida (quem/quando) na seção `### Respondidas`; **promova o selo** da premissa destravada **só com evidência real** (`crença → entrevistas/medido` conforme o que veio — nunca por otimismo); re-analise **só o delta** — as partes que as respostas tocam, nunca a análise inteira (convergência da 4.88). Resposta que abre lacuna nova → volta ao loop (Etapas 1–3 no que mudou).
4. **Resposta parcial é o caso normal**: Q respondida resolve, Q pendente permanece. Termine nas mesmas 3 saídas; ao gravar `pronto`, **retire a pendência de Riscos ativos** (+1 linha no Histórico recente do INDEX).

## Modo reabertura (documento v2 + BRIEF existente)

Produto mandou versão nova do documento. O original nunca foi editado (princípio 2), então o diff da fonte é limpo por construção:

1. Salve/referencie a v2 na origem (**nunca** sobrescreva a v1) e atualize `**Origem**:` com a versão nova, mantendo a anterior como histórico.
2. **Diff de interpretação, não de texto** — três perguntas: o que a v2 **muda** (itens do inventário alterados) · o que ela **responde** (Q-ID pendente resolvido → mapeie como na retomada, promovendo selo com a evidência) · o que ela **quebra** (fato do código, premissa aceita ou decisão já registrada no BRIEF que a v2 contradiz).
3. Re-analise **só o delta** (4.88) e apresente o diff de interpretação ao Diretor **antes** de regravar o BRIEF; lacuna nova → volta ao loop (Etapas 1–3 no que mudou).
4. Termine nas mesmas 3 saídas. BRIEF `pronto` contradito em ponto de núcleo → regride a `rascunho`/`aguardando-produto` — **declarado, nunca silencioso**. E se o ciclo **já consumiu** o BRIEF (a SPEC pareada existe), a reabertura **não reescreve história** — o BRIEF é trilha de auditoria da aceitação: a mudança segue o caminho normal de demanda nova (`/keelson:triage`), levando o diff de interpretação como insumo.

## Output final ao usuário

1. Caminho do BRIEF + `Status` final.
2. Inventário: itens presentes (com âncora) · respondidos pelo código · respondidos pelo Diretor · pendentes a produto (Q-IDs, `[bloqueia-núcleo]` destacado) · assumidos com risco (com selo).
3. Crítica de mérito do `product-analyst` (resumo) e fatos do código que mudaram a interpretação.
4. A saída tomada — com o bloco copy-paste dela (handoff do ciclo, ou perguntas a produto).
5. Estado do INDEX (pendência plantada/retirada).

## Limites

Não cria SPEC/PLAN/TASK nem inicia o ciclo (o handoff é do Diretor); não edita o documento de produto; não roda validators de forma; não decide mérito de produto no lugar do dono (formaliza a pergunta); não coordena incidente (porta: `/keelson:triage`). Fronteira com o `/keelson:refine`: ideia crua e leve é lá; documento de produto e profundidade é aqui.
