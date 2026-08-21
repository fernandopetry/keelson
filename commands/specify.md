---
description: Cria uma SPEC funcional (FRs em EARS, ACs em Given-When-Then, glossário) agnóstica de tecnologia e atualiza o INDEX do slug
argument-hint: <descrição ou @arquivo> [--slug=<nome>]
---

# /keelson:specify

Você é um Senior Product Engineer especialista em escrever especificações funcionais para desenvolvimento assistido por IA. Sua spec será consumida por outro agente de IA nas fases seguintes (`/keelson:plan`, `/keelson:tasks`), portanto precisa ser inequívoca, completa e testável.

**Princípio inviolável**: SPEC é agnóstica de tecnologia. Stack, framework e padrão técnico não entram aqui.

**Princípio de visibilidade**: ao final, o `INDEX.md` do slug é atualizado automaticamente.

## Etapa 0: resolver slug, guidelines e localização

### 0.1 Carregar guidelines e memo

1. Ler a **ficha** (`keelson.config.json`) na raiz — convenção comum (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`).
2. Ler o `CLAUDE.md` do projeto se existir e extrair apenas o relevante para SPEC: glossário de domínio, convenções de linguagem, anti-padrões de spec.
3. **Memo de exploração**: se a demanda exigiu explorar o código/domínio, salve/complemente o memo (convenção comum — sdd-conventions.md). Varredura ampla é delegada ao `code-scout`, que devolve conclusão ancorada em `arquivo:linha` (decisão 4.75) — a main session não varre a codebase inline.

### 0.2 Resolver slug

**Antes de criar qualquer slug novo, verifique se a demanda pertence a um slug já existente — inclusive legado.** Criar um slug paralelo para uma faceta de um domínio que já tem pasta em `{docsRoot}/` é um erro recorrente (ex.: criar `order-refund-window` quando já existe `{docsRoot}/orders/`).

1. **Slug explícito**: se veio `--slug=<nome>` ou a origem é `@{docsRoot}/<slug>/...`, use esse slug — mas **cheque legado antes**: se `{docsRoot}/<slug>/` tem `.md` na raiz e **não** tem `INDEX.md`, pare e rode `/keelson:migrate-legacy <slug>` primeiro. Sem pendência de legado, vá para o passo 4.
2. **Procurar slug de domínio existente**: liste as pastas de `{docsRoot}/` e procure um slug cujo domínio cubra a demanda — **inclusive legados** (pasta com `.md` na raiz mas **sem** `INDEX.md`). Há sobreposição quando a demanda incide sobre uma entidade/capacidade já representada por um slug.
3. **Decidir o slug** — a SPEC entra no slug do domínio, nunca em um paralelo:
   - **Slug de domínio relacionado com `INDEX.md`** → use-o.
   - **Slug de domínio relacionado, porém legado (sem `INDEX.md`)** → **pare e rode `/keelson:migrate-legacy <slug>` primeiro** (regra de ouro: "legado primeiro migra, depois muda"); só então retome esta SPEC nesse slug. **Nunca** crie um slug novo para contornar o legado.
   - **Nenhum slug relacionado (domínio genuinamente novo)** → proponha um slug kebab-case e **confirme com o humano**, apresentando os slugs existentes mais próximos. Um slug próprio só se justifica para um **domínio/capacidade de alto nível distinto**, **não** para uma regra/faceta de um domínio já existente.
4. Garantir `{docsRoot}/<slug>/specs/`: criar se não existir.
5. Próximo SPEC-NNN pelo alocador único (4.86): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh" {docsRoot}/<slug> alloc` — nunca de cabeça.
6. Nome do arquivo: `SPEC-NNN-<titulo-kebab>.md`, máximo 5 palavras.
7. **Ciclo com BRIEF** (invocado pelo `/keelson:auto`/`/keelson:guided` com brief já emitido): o slug e o NNN **foram resolvidos na largada** (Etapa 0.5 do auto) — **reutilize-os** (não renumere; divergência com `briefs/BRIEF-NNN.md` → pare e reporte) e preencha o front-matter `Brief: BRIEF-NNN` da SPEC na Etapa 3.

### 0.3 Ler INDEX.md do slug

Se `{docsRoot}/<slug>/INDEX.md` existe:
1. Ler INDEX completo.
2. Extrair glossário consolidado para reutilização.
3. Extrair decisões irreversíveis para não contrariar.
4. Identificar capacidades já implementadas e em desenvolvimento.
5. Coletar pendências de **veredito de métrica** em "Riscos ativos" (decisão 4.99): a demanda atual **constrói sobre** a capacidade pendente → ambiguidade crítica (Etapa 1 — apostar sobre valor não provado muda o resultado); as demais seguem ao output (item 6.5).

Se não existe: será criado ao final desta execução (Etapa 5).

### 0.4 Specs anteriores no slug

O **glossário consolidado do INDEX** (lido na 0.3) é canônico para Ubiquitous Language — **não reler as SPECs anteriores**; use apenas os títulos da tabela "SPECs" do INDEX para consistência. Só abra uma SPEC anterior se a nova SPEC precisar referenciar um FR/AC específico dela. SPECs são independentes (sem supersede automático).

## Etapa 1: triagem de ambiguidade

Pare e faça até 4 perguntas apenas se houver ambiguidade que afete:
- Contrato com sistema externo
- Comportamento em falha
- Critério de aceitação
- Requisito de segurança/compliance/privacidade
- Decisão arquitetural irreversível

Ambiguidade não crítica vira premissa `[assumido]`.

**Modo autônomo** (pós-largada do `/keelson:auto`): esta etapa e as confirmações da 0.2
não pausam — aplique a escada de reação do auto (decidir e registrar → estacionar →
interromper em último caso).

## Etapa 1.5: redação delegada ao `scribe` (decisão 4.103)

A redação da SPEC **não acontece nesta janela** — os insumos dela ficariam residentes no
contexto do Tech Lead até o fim do ciclo. Despache o agent `scribe` com o pacote:

- **Contrato**: este arquivo (`${CLAUDE_PLUGIN_ROOT}/commands/specify.md`), Etapas 2 e 3
  — a régua de forma que ele lê na fonte.
- **Alvo resolvido** (Etapa 0.2): slug, NNN, caminho do arquivo; `Brief: BRIEF-NNN` quando houver.
- **Insumos** (caminhos, nunca conteúdo colado): BRIEF e/ou documento de origem, INDEX.md
  (glossário/decisões extraídos na 0.3 podem ir resumidos), memo de exploração e/ou
  `MAP.md` do slug, recorte do `CLAUDE.md` do projeto (0.1).
- **Decisões desta execução**: premissas resolvidas na Etapa 1 (o scribe as aplica, não as reabre).

Receba o **sumário estruturado** (contrato de output no `agents/scribe.md`): `artefatos`,
`insumos_index`, `premissas_marcadas`, `duvidas`. `duvidas` não-vazias → trate como
ambiguidade da Etapa 1 (pergunte; no modo autônomo, escada) e re-despache **só o delta**.
Agent indisponível → executar as Etapas 2–3 inline é o fallback, declarado no output.

## Etapa 2: princípios obrigatórios (contrato de forma — executado pelo `scribe`)

1. **Outcome-first**: comece pelo resultado esperado.
2. **Ubiquitous Language**: defina termos no glossário, reutilize do glossário consolidado do INDEX.md (canônico — Etapa 0.4). **Termo herdado de fonte legada tem proveniência (decisão 4.240)**: quando a demanda se baseia em artefato legado (código, queries, telas), termo de domínio voltado ao usuário entra no glossário com a âncora da fonte que o usa (`arquivo:linha` ou identificador da consulta); termo que a fonte não decide — sinônimos concorrentes, leitura parcial — é escolha de produto: vira premissa da §8 (`[confirmar]` ou `[assumido]` com default declarado), nunca escolha silenciosa. Teste: "quem escolheu esta palavra?" responde-se com uma âncora ou uma premissa — "ninguém" é o defeito.
3. **EARS para FRs**:
   - Ubiquitous: `O <sistema> deve <resposta>.`
   - Event-driven: `Quando <gatilho>, o <sistema> deve <resposta>.`
   - State-driven: `Enquanto <estado>, o <sistema> deve <resposta>.`
   - Optional: `Onde <feature presente>, o <sistema> deve <resposta>.`
   - Unwanted: `Se <gatilho indesejado>, então o <sistema> deve <resposta>.`
4. **RFC 2119**: MUST, SHOULD, MAY em maiúsculas.
5. **IDs escopados ao SPEC**: `FR-NNN-001`, `NFR-NNN-001`, `AC-NNN-001`, `RISK-NNN-001`, `FEAT-NNN-001`.
6. **Funcionalidades (FEAT)** — só quando há 2+ fluxos entregáveis: regra completa no comentário do template da §5 (Etapa 3).
7. **Suposições explícitas**: `[confirmar]` ou `[assumido]` — e cada premissa da §8 carrega o **selo de evidência** `[evidência: crença | anedota | entrevistas | medido]` (escala e regra: convenção comum, sdd-conventions.md — decisão 4.96). O selo declara o que sustenta a aposta; nunca bloqueia. **Orçamento de pendência (decisão 4.144)**: no máximo **3** `[confirmar]` por SPEC — candidatos além do teto se resolvem por prioridade (**escopo > segurança/privacidade > experiência do usuário > detalhe técnico**) e os cortados viram `[assumido]` com o default escolhido declarado na própria premissa (o palpite + por que é razoável). Pendência de verdade é a que muda o resultado; preferência com default razoável de indústria não gasta o orçamento.
8. **Escopo e não-escopo simétricos — com teste** (decisão 4.158): cada item do In-scope
   tem o vizinho que um leitor assumiria incluído **nomeado** no Out-of-scope (cadastro
   entra → "e a recuperação de senha?" tem resposta escrita, dentro ou fora).
   Out-of-scope vazio ou genérico ("não inclui refatorações") com In-scope não-trivial é
   o sinal do princípio violado. A simetria é o que torna julgável o `não solicitado` do
   gate 4 (4.143): sem fronteira declarada, excesso de escopo vira opinião.
9. **Três estados da ação de UI** (decisão 4.67): FR de ação iniciada pelo usuário na
   interface DEVE especificar o comportamento **observável** dos três estados — *em
   andamento* (ação disparada, resultado pendente: botão desabilita? indicador aparece?),
   *sucesso* e *falha*. Efeito invisível (e-mail enviado, registro gravado, job
   disparado) **não é feedback** — feedback é o que a tela mostra ao usuário. FR de ação
   sem os três estados está incompleta; cada estado vira AC verificável (e os gates 1 e 9
   herdam a prova de graça).
10. **Par de leitura do que se persiste** (decisão 4.225): FR que introduz campo ou
    estado persistível novo **sem par de leitura está incompleto** — algum FR ou AC da
    mesma SPEC nomeia onde o valor salvo **reaparece** (recarga da tela, payload de
    consulta, exibição). AC de leitura no próprio FR satisfaz; não é preciso FR novo.
    Caso real: percentual especificado só na escrita nasceu sumindo ao recarregar e
    ausente do payload — 4 correções encadeadas que a SPEC teria evitado numa linha.

## Etapa 3: estrutura obrigatória do arquivo SPEC (contrato de forma — executado pelo `scribe`)

```markdown
# SPEC-NNN: <Nome>

**Slug**: <slug>
**Status**: Draft | Review | Approved
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>
**Jira**: <KEY — só quando a integração Jira está ativa; no modo `link`, preencha com a issue existente; omita a linha se `jira.enabled` for false>
**Jira Story**: <KEY da Story implícita — só quando a SPEC não declara FEATs e `issueType.feature` está preenchido (degrau (0) do §7.0 do protocolo de sync); omita a linha nos demais casos>
**Brief**: <BRIEF-NNN — quando a SPEC nasce de um brief (contrato Diretor–PO, decisão 4.38); omita a linha sem brief>

## 1. Contexto e objetivo
### 1.1 Problema
### 1.2 Outcome esperado
### 1.3 Métrica de sucesso
<!-- Número + prazo + a linha de fonte (decisão 4.99) — sem fonte, a métrica é
estimativa eterna e o veredito do ciclo seguinte não tem de onde sair: -->
**Fonte de medição**: <instrumentação — evento/consulta que o sistema emitirá | externa — ferramenta + dono do número>

## 2. Personas e jobs-to-be-done
<!-- Anti-persona (opcional, 1 linha — decisão 4.98): "para quem isto NÃO é", quando
disciplinar o escopo. Capacidade que "serve todo mundo" é sinal de persona genérica. -->

## 3. Glossário (Ubiquitous Language)

## 4. Escopo
### 4.1 In-scope
### 4.2 Out-of-scope

## 5. Requisitos funcionais (EARS)
<!-- Com 1 único fluxo entregável, mantenha a lista plana — NÃO declare a camada FEAT
(a funcionalidade é a própria SPEC): -->
- **FR-NNN-001** [MUST] ...
<!-- Com 2+ fluxos entregáveis (fluxos que o QA testa de ponta a ponta de forma independente,
ex.: "login no portal" e "lançamento de horas"), agrupe TODOS os FRs sob headings FEAT —
cada FR pertence a exatamente UMA FEAT (partição total); os ACs NÃO redeclaram filiação:
derivam da FEAT do FR que cobrem. Forma:
### FEAT-NNN-001: <Nome do fluxo entregável>
> <1–2 linhas: o fluxo do ponto de vista do QA — o que se testa de ponta a ponta>

**Jira**: <KEY da Story — só com projeção 3 níveis ativa; omita a linha se não sincronizada>

- **FR-NNN-001** [MUST] ...
-->

## 6. Requisitos não-funcionais
- **NFR-NNN-001** [MUST] ...

## 7. Critérios de aceitação (Given-When-Then)
- **AC-NNN-001** (cobre FR-NNN-001, FR-NNN-002)
<!-- O "(cobre …)" é campo de aresta do grafo: IDs completos de FR/NFR separados por
vírgula — sem barra-abreviação (FR-x/y) nem sub-item (FR-x-001a). Com FEATs declaradas
na §5, os FRs de um mesmo "(cobre …)" pertencem à MESMA FEAT — a filiação do AC deriva
dela; AC atravessando FEATs é cenário mal fatiado: divida o AC. Régua:
${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md §1. -->

## 8. Premissas e decisões prévias
- **A-NNN-001** [assumido] [evidência: crença] ...

## 9. Riscos e questões abertas
- **RISK-NNN-001** ...
- **Q-NNN-001** ...

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
```

## Etapa 4: gate de validação

Com o scribe encerrado (sumário recebido, sem re-despacho pendente), despache **numa
mesma rodada, em paralelo** (decisão 4.113): a skill `spec-validator` (forma), o agent
`product-analyst` (mérito — Etapa 4.1) e, quando `jira.enabled`, o `tracker-sync`
(Etapa 5.3). Nenhum depende do outro — validator e analyst só leem a SPEC; o sync só
escreve as linhas de key. A única exclusão: **nunca com o scribe ainda editando** o
arquivo (pacote de ajustes pendente → primeiro ele termina). Encadeá-los em fila é puro
custo de relógio: numa sessão real foram 3 × ~6 min seriais onde 1 × ~6 min bastava.

**Se errors == 0**: prosseguir para Etapa 5 (atualização do INDEX).
**Se errors > 0**: manter Status = Draft e reportar os errors — a crítica do
`product-analyst` (que rodou em paralelo) é reportada do mesmo jeito (mérito não depende
de forma), e **executar a Etapa 5 mesmo assim**: a existência da SPEC é fato e o INDEX é
derivado dos arquivos (mesma filosofia do `/keelson:plan`); a linha na tabela "SPECs"
entra com Status Draft.

## Etapa 4.1: crítica de produto (mérito)

Despachado em paralelo com o `spec-validator` (Etapa 4 — decisão 4.113), o agent
`product-analyst` **não** checa forma — questiona **mérito**: problema vs solução, qualidade da métrica de sucesso, cenários faltantes, premissas arriscadas, conflito com capacidades/decisões do INDEX.

A crítica **não bloqueia** a criação da SPEC nem a atualização do INDEX (a SPEC nasce em `Draft`); o resultado é reportado ao usuário.

**Com BRIEF pareado** (front-matter `Brief:` preenchido — a demanda entrou pelo ciclo com brief): após a crítica **e o veredito de forma** (o PO consome ambos — ele fica fora da rodada paralela), invocar o agent `po` em **modo aprovação** (BRIEF + SPEC + crítica + INDEX). O veredito (`APROVAR | ESCALAR`, com resoluções e decisões em nome do Diretor) entra no output final; quem age sobre ele é o invocador — `/keelson:auto` promove ou aplica a escada; `/keelson:guided` o apresenta como recomendação no CHECKPOINT 1. **Sem BRIEF** (specify avulso): não invocar o `po` — a promoção a `Approved` permanece com o humano.

## Etapa 5: atualização do INDEX.md

### 5.1 Criar INDEX se não existe

Criar do zero seguindo o **template canônico do INDEX** (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`), preenchido com a SPEC recém-criada: linha na tabela "SPECs", capacidade em "Especificadas, ainda não planejadas" (derivada do outcome esperado), glossário e riscos da SPEC, Histórico recente com `SPEC-NNN criada via /keelson:specify`. Fonte: os `insumos_index` do sumário do scribe — releia seções da SPEC só para o que faltar neles.

### 5.2 Atualizar INDEX se já existe

Aplicar a **receita de atualização do INDEX** (index-contract.md). Específicos desta etapa: linha nova na tabela "SPECs"; capacidade nova em "Especificadas, ainda não planejadas" (texto curto do outcome); termos e riscos da SPEC mesclados.

### 5.3 Sincronização com Jira (opcional)

Só quando a ficha tem `jira.enabled: true`: **despache o agent `tracker-sync`** (decisão 4.103 — os payloads do conector e o protocolo ficam na janela dele) **na rodada paralela da Etapa 4** (decisão 4.113 — sync é best-effort e nunca ocupa o caminho crítico sozinho) com o gancho **`specify`**: caminhos do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; §§ do gancho: §6.2, §7.0 — pré-check de hierarquia —, §8, §10 — e §17 quando `jira.telemetry` (worklog + contadores da etapa); mais `jira-sync-feat.md` quando a SPEC declara FEATs ∧ `issueType.feature` preenchido), da ficha e da SPEC recém-criada. Raiz criada na largada (§16) → a key já está no BRIEF: ele **copia** para a SPEC e enriquece o stub, nunca cria segunda issue. Ele cria/vincula a issue principal (e Stories de FEAT, ou a Story implícita do degrau (0) do §7.0), **grava as keys nas linhas `**Jira**:`/`**Jira Story**:`** da SPEC e devolve o resumo canônico. Best-effort (§0): `eventos_tracker` no retorno → grave-os como evento `tracker` no ledger de sessão e monte a **seção de reconexão da §14** no fecho deste comando; num `/keelson:auto`, o evento desagua no item 7.4 da Entrega. Agent indisponível → aplicar o protocolo inline (mesmos §§) é o fallback, declarado no output.

## Output final ao usuário

1. Caminho da SPEC criada.
2. Caminho do INDEX (criado ou atualizado).
3. Resumo de 3 linhas do que foi especificado.
4. Guidelines carregados (ficha lida; `CLAUDE.md` presente sim/não).
5. Resultado da validação:
   - Auto-fixes aplicados
   - Errors pendentes (se houver)
   - Warnings relevantes
   - Crítica de produto (`product-analyst`): riscos de mérito e perguntas a decidir antes de `Approved`
   - Veredito do PO (quando há BRIEF): decisão, resoluções pelo brief e escalações com proposta + default
6. Premissas `[assumido]` que precisam confirmação — destacando selo `crença`/`anedota` em requisito central (4.96).
6.5. Vereditos de métrica pendentes no slug (4.99), com os vencidos destacados — no ciclo, a Entrega do `/keelson:auto` cobra (item 6.4); no specify avulso, repasse ao Diretor.
7. Estado do INDEX após esta operação.
8. Próximo comando, com o **caminho** da SPEC criada (4.124 — o ID se repete entre slugs): `/keelson:plan {docsRoot}/<slug>/specs/SPEC-NNN-<nome>.md` (com `--slice="..."` se aplicável) se errors == 0.
