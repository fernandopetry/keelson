# Artefatos, IDs e contrato do INDEX

> Fonte única (ex-§6 do method-guide): árvore de artefatos, IDs, contrato da tabela "PLANs",
> template canônico do INDEX.md e receita de atualização — nenhum comando redefine nada disso.

```
<docsRoot>/                    # docsRoot da ficha; "docs/" por padrão
├── _meta/
│   ├── decisions.md           # governança do processo
│   ├── method-guide.md        # guia humano do método
│   └── learning-log.md        # ledger do auto-aprendizado (mantido pelo agile-coach)
└── <slug>/
    ├── INDEX.md               # estado atual (GERADO — não editar)
    ├── briefs/BRIEF-NNN.md    # intenção do Diretor + interpretação do PO (contrato abaixo; vazio na maioria dos slugs)
    │       └── BRIEF-MMM-*-avulso.md  # 3º sabor: mudança avulsa, sem SPEC/PLAN (decisão 4.86)
    ├── specs/SPEC-NNN-*.md
    ├── plans/PLAN-MMM-*.md
    ├── tasks/
    │   ├── TASK-MMM-INDEX.md
    │   └── TASK-MMM-XXX-*.md
    ├── handoffs/HANDOFF-*.md  # verificação de tela pendente (ver handoff-protocol.md; vazio na maioria dos slugs)
    └── legacy/                # docs pré-migração (quando aplicável)
```

| ID | Significado | Escopo da numeração |
|---|---|---|
| `BRIEF-NNN` | Brief da demanda — pedido do Diretor + interpretação do PO (contrato Diretor–PO, decisões 4.37/4.38) | NNN = nº da SPEC pareada (1:1); sabor **avulso** usa MMM próprio do alocador único (4.86) |
| `FR-NNN-XXX` / `NFR-NNN-XXX` | Requisito funcional / não-funcional | NNN = nº da SPEC |
| `AC-NNN-XXX` | Critério de aceitação (Given-When-Then) | NNN = nº da SPEC |
| `RISK-NNN-XXX` / `A-NNN-XXX` / `Q-NNN-XXX` | Risco / premissa / questão aberta | NNN = nº da SPEC |
| `FEAT-NNN-XXX` | Funcionalidade — fluxo entregável, unidade de teste do QA (camada opcional: só com 2+ fluxos na SPEC; decisão 4.27) | NNN = nº da SPEC |
| `COMP-MMM-XXX` | Componente | MMM = nº do PLAN |
| `DEC-MMM-XXX` | Decisão arquitetural (com alternativas e flag `Irreversível`) | MMM = nº do PLAN |
| `TRISK-MMM-XXX` | Risco técnico | MMM = nº do PLAN |
| `TASK-MMM-XXX` | Tarefa | MMM = âncora à qual pertence: PLAN (campo `**Pertence a**:`) **ou** brief avulso (campo `**Brief**:` — decisão 4.86); nunca os dois |

Nomes de arquivo de TASK por tipo: `-fix-` (bugfix), `-refactor-` (refactor), `-chore-` (chore); sem sufixo = feature.

**Alocação de número (decisão 4.86)**: número novo de artefato numerado do slug — SPEC
(com seu BRIEF pareado), PLAN ou brief avulso — sai de um **alocador único**:
`max(todos os NNN e MMM já usados no slug) + 1`. O executor canônico é
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh" <dir-do-slug> alloc` (e `task <MMM>` para o
próximo XXX de TASK — decisão 4.151) — sempre via `bash`, a forma que não depende do bit
de execução do pacote instalado (4.195); o `--check` confere o pareamento brief ↔ SPEC.
Alocar de cabeça é o que colide. Consequências: nunca nascem dois
artefatos novos com o mesmo número (a colisão de nome BRIEF-pareado × BRIEF-avulso é
impossível por construção); pares NNN/MMM iguais pré-4.86 (ex.: SPEC-001 + PLAN-001)
permanecem válidos; **densidade por tipo não é contrato** — PLAN-002 seguido de PLAN-004
é normal quando o 003 foi um avulso ou uma SPEC.

### Contrato do BRIEF (fonte única — decisão 4.38)

O BRIEF é o artefato-âncora do contrato Diretor–PO (4.37): o pedido do Diretor capturado
**como dito** + a interpretação do PO. O PO valida SPEC e entrega **contra ele** — nunca
contra a própria opinião. No **ciclo formal** (rota feature/risco do
`/keelson:auto` e do `/keelson:guided`) é pareado 1:1 com a SPEC que nasce dele — o NNN é
alocado pela mesma varredura que numera a SPEC; bug/refactor **no ciclo** usam espelho
inline sem arquivo, e trivial não tem brief. Fora do ciclo, a mudança avulsa usa o
**3º sabor** (variação avulsa, decisão 4.86 — abaixo).

```markdown
# BRIEF-NNN: <título curto da demanda>

**Slug**: <slug>
**Status**: Emitido | Aceito | Vetado
**Data**: <YYYY-MM-DD>
**Largada**: <YYYY-MM-DDTHH:MM:SS-0300 — medida com `TZ=America/Sao_Paulo date`, nunca estimada>
**SPEC**: SPEC-NNN
**Epico**: <caminho do BRIEF épico pai — só quando a demanda veio de uma decomposição; omita a linha caso contrário>
**Jira**: <KEY da raiz criada na largada (§16 do protocolo, decisão 4.191) — omita a linha sem tracker; o gancho do specify copia esta key para a SPEC>

## Pedido como dito
<verbatim do Diretor — sem reescrita>

## Interpretação do PO
<~5 linhas, na linguagem do Diretor>

## Premissas decididas

## Fora de escopo

## Cronologia
<anexada pelo condutor do ciclo — uma linha `- <etapa>: <timestamp>` ao concluir cada etapa>
```

Ciclo de vida: `Emitido` na largada (antes da SPEC) → `Aceito` na Entrega, junto do
relatório de aceitação do PO. As marcas de `Largada` e `Cronologia` são **medidas**
(`TZ=America/Sao_Paulo date`) e alimentam a linha de duração do report da Entrega —
a regra (formato, degradação sem marca) é do `/keelson:auto`, Etapa 5 item 6.3
(decisão 4.56). Veto do Diretor → o brief é **reescrito e re-emitido**,
nunca apagado. A SPEC pareada grava `**Brief**: BRIEF-NNN` no front-matter; o par
brief ↔ SPEC é a trilha de auditoria da aceitação.

**Variação épico (decisões 4.39, 4.125, 4.126)**: brief de nível portfólio, gravado pelo
`/keelson:specify-epic` no slug-âncora como `briefs/BRIEF-<yyyy-mm-dd>-<descricao>-epic.md`
(id por data, precedente dos handoffs — o épico **não pareia com SPEC**, então não usa a
numeração NNN nem a linha `**SPEC**:`). Cabeçalho:

```markdown
# BRIEF épico: <título da iniciativa>

**Slug**: <slug-âncora>
**Status**: Emitido | em execução | concluído
**Data**: <YYYY-MM-DD>
**Origem**: <caminho do BRIEF forjado (4.128) | pedido em sessão>
**Branch**: feat/<slug>-<descricao-curta>
**Estratégia**: unica | por-fatia
**Jira**: <KEY do Epic — opcional; raiz criada na largada, §16 do protocolo (4.191)>
```

Conteúdo: pedido épico verbatim + **fila viva** (decisão 4.125) — a decomposição
confirmada do PM como tabela com estado por fatia:

```markdown
## Fila

| # | Fatia | Slug de destino | Estado |
|---|---|---|---|
| 1 | <título/resumo> | <slug> | entregue (<YYYY-MM-DD>) |
| 2 | <título/resumo> | <slug> | em ciclo (<caminho do BRIEF filho>) |
| 3 | <título/resumo> | <slug> | aguardando-produto (Q-07) |
| 4 | <título/resumo> | <slug> | pendente |
```

(dependências e riscos por fatia seguem em seções próprias, fora da tabela). Quem
escreve o estado é o **marco do ciclo filho**: a largada do `/keelson:auto` marca
`em ciclo` (junto do `**Epico**:` no filho); a Entrega marca `entregue` — a fila é
registro curado, nunca segunda fonte: divergência resolve pelos artefatos filhos
(4.58). `Status` do épico: `Emitido` → `em execução` (1ª fatia larga) → `concluído`
(última fatia entregue; merge final continua ato do Diretor). `**Branch**` +
`**Estratégia**` (default `unica`, decisão 4.126) registram onde as fatias vivem —
é esse registro que separa reuso **deliberado** de branch do acidental que a 4.119
proíbe. Cada filha ganha seu `BRIEF-NNN` normal **no slug de destino** quando o
ciclo dela começa, com a linha `**Epico**:` apontando ao pai. BRIEF forjado
decomposto em épico (4.128) recebe `Status: decomposto` + o caminho do épico — o
NNN reservado dele não gera SPEC, e o rastro explica o buraco na numeração.

**Variação avulsa (decisão 4.86)**: a tarefa do dia a dia — bugfix, melhoria pequena,
chore **sem SPEC/PLAN aplicável** — nasce como brief avulso em
`briefs/BRIEF-MMM-<descricao>-avulso.md` (MMM do alocador único), **antes do código**:
é o briefing destilado do modo sob demanda (4.75) materializado em arquivo, e a origem
da Story `standalone` no tracker (protocolo Jira §7). Esqueleto literal:

```markdown
# BRIEF-MMM: <título curto da mudança>

**Slug**: <slug-morada> — toca também: <slug2>, <slug3> (forma curta só quando multi-slug)
**Tipo**: avulso
**Status**: Aberto | Concluído
**Data**: <YYYY-MM-DD>
**Largada**: <YYYY-MM-DDTHH:MM:SS-0300 — medida com `TZ=America/Sao_Paulo date`, nunca estimada (4.196: é a fonte de duração do worklog da telemetria nesta rota)>
**Origem**: <Diretor (pedido em sessão) | key do tracker (rota pull, ex.: PROJ-123)>
**Jira**: <KEY — gravada pelo sync (§10 do protocolo); linha ausente = não sincronizado>

## Pedido como dito
<verbatim — do Diretor, ou a descrição do card do tracker (rota pull)>

## Interpretação
<~3 linhas do Tech Lead: o quê, onde, por que agora>

## Critério de aceite
- <observável e verificável — é contra isto que code-reviewer e qa avaliam>

## TASKs
<nenhuma — o brief é a unidade de execução | TASK-MMM-001..N quando o trabalho reparte>

## Execução
<closure quando não há TASKs (com TASKs, a closure vive nelas):>
- **Implementado por**: <developer | inline — <motivo> (4.75)>
- **Revisado por**: <cada gate aplicável com estado declarado — régua simétrica (4.85)>
- **Commit**: <SHA | pendente — commit é ato do Diretor>
```

Réguas (falsificáveis — na dúvida, promova): **avulso ou ciclo?** — muda o que o sistema
promete, ou a decomposição exigiria escolher entre alternativas técnicas (haveria uma
DEC) → ciclo; só reparte trabalho mecânico → avulso. **Com ou sem TASK?** — um executor,
um diff → sem TASK; repartível em pedaços independentes → TASKs, cada uma com
`**Brief**: BRIEF-MMM` no lugar de `**Pertence a**:` (âncora polimórfica — o grafo
verifica a referência e a forma: `task-brief` e `brief-sem-criterio` no
`graph-contract.md`). Avulso que acumular decisão técnica ou tocar contrato no meio do
caminho **para e promove** (vira SPEC/ciclo), declarando. O trivial inline (4.75)
continua sem brief. Slug com avulsos ganha no INDEX a seção `## Avulsas`
(tabela `| ID | Título | Status | Jira | Data |`), mantida por quem fecha o avulso.

**Morada multi-slug (decisão 4.87)**: mudança avulsa que toca vários slugs continua com
**um brief só** — a unidade do brief é a mudança, não o slug; nunca duplique brief nem
card. A morada é o **slug dominante** — teste falsificável: *se isto crescesse para um
ciclo, em qual slug viveria a SPEC?* Na prática, o slug dono do código que **realiza** a
mudança (o componente/mecanismo compartilhado), não os que apenas a recebem; sem
mecanismo comum, o do efeito observável principal; empate genuíno → qualquer um,
**declarado na interpretação**. Na entrega, cada slug adicional recebe **1 linha no
`## Histórico recente` do INDEX** apontando a morada
(`<data>: <descrição> — brief avulso em <slug>/briefs/BRIEF-MMM (<key>)`) — referência,
nunca cópia; `## Avulsas` existe só no slug-morada. TASKs do brief vivem **no slug do
brief**: a âncora `**Brief**:` não cruza slug — o grafo opera por diretório, e âncora
cross-slug reprova como `ref-quebrada` por design.

**Forja do BRIEF — pré-estados e seções aditivas (decisão 4.102)**: o BRIEF pareado
pode nascer **antes** da SPEC, pela forja (`/keelson:brief`, estágio opcional
pré-ciclo). Tudo aqui é aditivo — BRIEFs existentes continuam válidos sem alteração:

- **Pré-estados do sabor pareado**: `rascunho` (forja em andamento) →
  `aguardando-produto` (perguntas Q-ID pendentes fora do time) → `pronto` (nenhuma
  `[bloqueia-núcleo]` aberta). Na largada, o `/keelson:auto` promove `pronto → Emitido`;
  daí em diante vale o ciclo atual (`Emitido → Aceito | Vetado`).
- **Numeração**: o par BRIEF↔SPEC pode se separar no tempo — a forja aloca o NNN pelo
  **alocador único** (o arquivo em disco já reserva o número no max+1) e a SPEC pareada
  **herda** o NNN do BRIEF.
- **Origem**: além de `Diretor` e key do tracker, `**Origem**:` aceita o **documento de
  produto** — path no repo (sugestão: `<docsRoot>/<slug>/origin/`, irmã de `briefs/`,
  **em inglês como as pastas irmãs da árvore**; **só-leitura**: a forja nunca o edita)
  ou referência externa (URL, e-mail); a forja nunca exige cópia (4.72 — o literal fica
  com o dono).
- **Seções aditivas do BRIEF forjado** (opcionais; nenhum validator as exige — check
  futuro nasceria WARNING `[legacy]`):

  ```markdown
  ## Fatos do código
  <conclusões ancoradas do code-scout (arquivo:linha) que sustentam a interpretação>

  ## Perguntas
  ### Respondidas
  - **Q-01** — <pergunta> · **Resposta** (<código | Diretor | produto>, <data>): <resposta>
  ### Pendentes a produto
  - **Q-02** `[bloqueia-núcleo]` — destrava: <premissa/FR> · contexto: <fato do código> · <pergunta> · **Resposta**: — (pendente desde <data>)

  ## Riscos declarados
  - <o que foi assumido conscientemente, com o selo de evidência (4.96)>
  ```

- **Pendência viva**: BRIEF `aguardando-produto` → 1 linha em **Riscos ativos** do INDEX
  (`| BRF-NNN | BRIEF-NNN aguardando produto: <Q-IDs> pendente(s) desde <data> | retomar via /keelson:brief <slug> | BRIEF-NNN |`),
  retirada quando o BRIEF fica `pronto` (+1 linha no Histórico recente).
- A interpretação do BRIEF forjado segue o formato canônico de 4 seções cujo **dono é o
  `/keelson:refine`** (Contexto · Pedido · Premissas decididas · Fora de escopo) — a
  forja preenche mais fundo, nunca redefine a moldura; as premissas carregam selo (4.96).

### Contrato da tabela "PLANs" do INDEX (fonte única)

Todo escritor do INDEX (`/keelson:specify`, `/keelson:plan`, `/keelson:tasks`, `/keelson:implement`, `/keelson:rebuild-index`) usa **exatamente** este formato — nenhum comando redefine header ou célula por conta própria:

```markdown
| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|
| PLAN-MMM | SPEC-NNN | <resumo curto> | X/Y M | <Status> |
```

- **Header**: as 5 colunas acima, nesta ordem. O `/keelson:specify` já cria a seção "## PLANs" com o header (tabela vazia); quem adiciona a primeira linha **não** inventa header.
- **Célula `Tasks`** = `X/Y M`: `X` tasks Done, `Y` total (`?` até o `/keelson:tasks` rodar), `M` marcador — `⏸` (nenhuma Done), `🟡` (parcial), `✅` (todas Done). Progressão: `0/? ⏸` (plan) → `0/N ⏸` (tasks) → `X/N 🟡` (implement, closure por task) → `N/N ✅` (última closure).
- **Coluna `Status`** = o Status do front-matter do arquivo PLAN, **verbatim** (`Draft | Review | Approved | Done`), com um único sufixo permitido: `Done (sugerido)`, escrito pelo `/keelson:implement` quando a DoD está satisfeita mas a promoção humana ainda não aconteceu. O "status efetivo" que o `/keelson:rebuild-index` calcula serve **só** para posicionar a capacidade na seção "Capacidades" — nunca entra nesta coluna.

### Template canônico do INDEX.md (fonte única)

Todo comando que **cria** um INDEX (`/keelson:specify` na 1ª SPEC, `/keelson:rebuild-index`, `/keelson:migrate-legacy`) usa este esqueleto — nenhum comando redefine seções por conta própria:

```markdown
# <Nome do slug em formato título>

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.

**Slug**: <slug>
**Última atualização**: <ISO 8601 com timezone>
**Mapa do território**: MAP.md <!-- linha opcional — só quando {docsRoot}/<slug>/MAP.md existe (decisão 4.104; contrato: map-contract.md); quem cria o MAP acrescenta a linha -->

## Resumo
<2 a 3 linhas derivadas dos outcomes das SPECs — ou do legado, na migração>

## Capacidades

### Implementadas
- <capacidade> (SPEC-NNN, PLAN-MMM, ✅ <data>)

### Em desenvolvimento
- <capacidade> (SPEC-NNN, PLAN-MMM, 🟡 X/Y tasks Done)

### Especificadas, ainda não planejadas
- <outcome> (SPEC-NNN, ⏸ aguardando /keelson:plan)

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|

## Decisões irreversíveis

- **DEC-MMM-XXX** (PLAN-MMM): <texto curto>

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|

## Histórico recente

- <YYYY-MM-DD HH:MM>: <ação> via /keelson:<comando>
```

Seção ainda sem conteúdo leva nota curta do que a preenche (ex.: "(vazio até /keelson:plan)").

**Risco/pendência tem dono em artefato-fonte (decisão 4.179)**: a coluna `Origem` de
"Riscos ativos" aponta um artefato **versionado** (TASK, PLAN, SPEC, brief) que carrega o
mesmo registro — o INDEX é derivado, e um rebuild o reescreve dos artefatos: pendência cuja
única morada é o INDEX morre no rebuild sem rastro. Quem estaciona um débito registra
primeiro no artefato de origem e então espelha aqui. Caso real: débito de sessão registrado
só no INDEX; o code-reviewer pegou antes do rebuild apagar.

Variações por comando:

- **`/keelson:rebuild-index`**: acrescenta ao aviso a linha `> Última reconstrução completa via /keelson:rebuild-index: <ISO 8601>` e, se houver, a seção final `## Inconsistências conhecidas` (descrição + ação sugerida).
- **`/keelson:migrate-legacy`**: acrescenta `**Origem**: migrado de legado em <YYYY-MM-DD> via /keelson:migrate-legacy`; capacidades legadas entram em `### Implementadas (legado, sem rastreabilidade SDD)` com marcador 📜 e origem (`legacy/<arquivo>`); decisões extraídas viram `LEGACY-DEC-*`; "SPECs"/"PLANs" ficam vazios com nota de que não há artefatos retroativos; seção extra `## Documentação legada` lista os arquivos preservados.
- **Slug migrado** (em qualquer rebuild): as seções espelhadas do legado abrem com `> Fonte durável: legacy/TRIAGE-<data>.md` — é do TRIAGE que o rebuild as reespelha.
- **Slug com briefs avulsos (decisão 4.86)**: seção adicional `## Avulsas` — tabela `| ID | Título | Status | Jira | Data |`, uma linha por `briefs/BRIEF-*-avulso.md`, derivável dos próprios arquivos (o rebuild a reconstrói de lá).
- **Granularidade das Capacidades**: SPEC que declara FEATs → **uma entrada de capacidade por FEAT**, no formato `<nome da FEAT> (SPEC-NNN/FEAT-NNN-XXX, PLAN-MMM, <marcador>)`, movida entre subseções quando a FEAT fica pronta (todos os FRs dela cobertos por PLANs **e** todas as TASKs que a listam em `Funcionalidade` — primária ou secundária, em qualquer PLAN do slug — Done); SPEC sem FEATs → uma entrada por SPEC, como sempre.

### Receita de atualização do INDEX (fonte única)

Todo comando que **atualiza** um INDEX existente aplica — mesclando, nunca sobrescrevendo:

1. Atualizar `Última atualização`.
2. Refletir o artefato na tabela correspondente (SPECs/PLANs — contrato acima) e nas seções que ele afeta: capacidades (movendo entre "Especificadas" → "Em desenvolvimento" → "Implementadas" conforme o ciclo; por FEAT quando a SPEC as declara), glossário (termo já existente com definição diferente → **parar e reportar conflito**), decisões irreversíveis, riscos ativos.
3. Adicionar entrada ao "Histórico recente" com timestamp e ação — **máximo 10 entradas**.
4. **Conferir com o checker** (decisão 4.151): `${CLAUDE_PLUGIN_ROOT}/scripts/index-check.sh <dir-do-slug>` — irmão do `map-check.sh`, saída no formato do `graph.sh`, catálogo sem ERROR (o INDEX é derivado; divergência se corrige regenerando). Checks: `index-ausente` · `index-secao-ausente` · `index-spec-fantasma`/`-fora` · `index-plan-fantasma`/`-fora` · `index-tasks-cell` (célula `X/Y M` vs TASKs reais) · `index-status-verbatim` (coluna vs arquivo, exceção `Done (sugerido)`) · `index-capacidade-adiantada` (capacidade em "Implementadas" com TASK aberta) · `index-historico-teto` (INFO, >10). Achado é fato a corrigir na mesma edição; suíte em `scripts/tests/index/`.

### Pendência e veredito de métrica (decisão 4.99)

Entrega de PLAN cuja SPEC declara `**Fonte de medição**:` na §1.3 planta a pendência em
**"Riscos ativos"** — formato da linha (ID `MET-NNN`, NNN da SPEC):

```markdown
| MET-NNN | Métrica de SPEC-NNN sem veredito: <métrica, alvo> até <prazo> | medir via <fonte declarada> | SPEC-NNN |
```

O veredito, quando medido, é gravado **na SPEC**, sob a §1.3 — presença é o contrato,
conteúdo legível (o padrão da linha de verificação do gate 9, 4.90):

```markdown
**Veredito de métrica**: ✅ confirmada | ❌ não movida | 🤔 inconclusiva — <data> · <medido vs alvo>
```

Gravado o veredito: a linha `MET-NNN` sai de "Riscos ativos" (+1 linha no Histórico
recente); `❌` nomeia a capacidade **candidata a sunset** no report da Entrega —
descontinuar é decisão de produto, nunca do ciclo. Enquanto a pendência existir, o
check `metrica-sem-veredito` (INFO — graph-contract.md §3) a lembra a cada validação.
