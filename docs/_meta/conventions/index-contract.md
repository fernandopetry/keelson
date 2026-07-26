# Artefatos, IDs e contrato do INDEX

> Fonte única (ex-§6 do method-guide): árvore de artefatos, IDs, contrato da tabela "PLANs",
> template canônico do INDEX.md e receita de atualização — nenhum comando redefine nada disso.

```
<docsRoot>/                    # docsRoot da ficha; "docs/" por padrão
├── _meta/
│   ├── decisions.md           # governança do processo
│   ├── method-guide.md        # guia humano do método
│   └── learning-log.md        # ledger do auto-aprendizado (mantido pelo process-tuner)
└── <slug>/
    ├── INDEX.md               # estado atual (GERADO — não editar)
    ├── briefs/BRIEF-NNN.md    # intenção do Diretor + interpretação do PO (contrato abaixo; vazio na maioria dos slugs)
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
| `BRIEF-NNN` | Brief da demanda — pedido do Diretor + interpretação do PO (contrato Diretor–PO, decisões 4.37/4.38) | NNN = nº da SPEC pareada (1:1) |
| `FR-NNN-XXX` / `NFR-NNN-XXX` | Requisito funcional / não-funcional | NNN = nº da SPEC |
| `AC-NNN-XXX` | Critério de aceitação (Given-When-Then) | NNN = nº da SPEC |
| `RISK-NNN-XXX` / `A-NNN-XXX` / `Q-NNN-XXX` | Risco / premissa / questão aberta | NNN = nº da SPEC |
| `FEAT-NNN-XXX` | Funcionalidade — fluxo entregável, unidade de teste do QA (camada opcional: só com 2+ fluxos na SPEC; decisão 4.27) | NNN = nº da SPEC |
| `COMP-MMM-XXX` | Componente | MMM = nº do PLAN |
| `DEC-MMM-XXX` | Decisão arquitetural (com alternativas e flag `Irreversível`) | MMM = nº do PLAN |
| `TRISK-MMM-XXX` | Risco técnico | MMM = nº do PLAN |
| `TASK-MMM-XXX` | Tarefa | MMM = PLAN ao qual pertence |

Nomes de arquivo de TASK por tipo: `-fix-` (bugfix), `-refactor-` (refactor), `-chore-` (chore); sem sufixo = feature.

### Contrato do BRIEF (fonte única — decisão 4.38)

O BRIEF é o artefato-âncora do contrato Diretor–PO (4.37): o pedido do Diretor capturado
**como dito** + a interpretação do PO. O PO valida SPEC e entrega **contra ele** — nunca
contra a própria opinião. Só existe no **ciclo formal** (rota feature/risco do
`/keelson:auto` e do `/keelson:guided`, pareado 1:1 com a SPEC que nasce dele — o NNN é
alocado pela mesma varredura que numera a SPEC); bug/refactor usam espelho inline sem
arquivo, e trivial não tem brief.

```markdown
# BRIEF-NNN: <título curto da demanda>

**Slug**: <slug>
**Status**: Emitido | Aceito | Vetado
**Data**: <YYYY-MM-DD>
**SPEC**: SPEC-NNN
**Epico**: <caminho do BRIEF épico pai — só quando a demanda veio de uma decomposição; omita a linha caso contrário>

## Pedido como dito
<verbatim do Diretor — sem reescrita>

## Interpretação do PO
<~5 linhas, na linguagem do Diretor>

## Premissas decididas

## Fora de escopo
```

Ciclo de vida: `Emitido` na largada (antes da SPEC) → `Aceito` na Entrega, junto do
relatório de aceitação do PO. Veto do Diretor → o brief é **reescrito e re-emitido**,
nunca apagado. A SPEC pareada grava `**Brief**: BRIEF-NNN` no front-matter; o par
brief ↔ SPEC é a trilha de auditoria da aceitação.

**Variação épico (decisão 4.39)**: brief de nível portfólio, gravado pelo
`/keelson:specify-epic` no slug-âncora como `briefs/BRIEF-<yyyy-mm-dd>-<descricao>-epic.md`
(id por data, precedente dos handoffs — o épico **não pareia com SPEC**, então não usa a
numeração NNN nem a linha `**SPEC**:`). Conteúdo: pedido épico verbatim + decomposição
confirmada do PM (demandas-filhas: prioridade, título, resumo, slug de destino,
dependências, riscos). Cada filha ganha seu `BRIEF-NNN` normal **no slug de destino**
quando o ciclo dela começa, com a linha `**Epico**:` apontando ao pai.

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

Seção ainda sem conteúdo leva nota curta do que a preenche (ex.: "(vazio até /keelson:plan)"). Variações por comando:

- **`/keelson:rebuild-index`**: acrescenta ao aviso a linha `> Última reconstrução completa via /keelson:rebuild-index: <ISO 8601>` e, se houver, a seção final `## Inconsistências conhecidas` (descrição + ação sugerida).
- **`/keelson:migrate-legacy`**: acrescenta `**Origem**: migrado de legado em <YYYY-MM-DD> via /keelson:migrate-legacy`; capacidades legadas entram em `### Implementadas (legado, sem rastreabilidade SDD)` com marcador 📜 e origem (`legacy/<arquivo>`); decisões extraídas viram `LEGACY-DEC-*`; "SPECs"/"PLANs" ficam vazios com nota de que não há artefatos retroativos; seção extra `## Documentação legada` lista os arquivos preservados.
- **Slug migrado** (em qualquer rebuild): as seções espelhadas do legado abrem com `> Fonte durável: legacy/TRIAGE-<data>.md` — é do TRIAGE que o rebuild as reespelha.
- **Granularidade das Capacidades**: SPEC que declara FEATs → **uma entrada de capacidade por FEAT**, no formato `<nome da FEAT> (SPEC-NNN/FEAT-NNN-XXX, PLAN-MMM, <marcador>)`, movida entre subseções quando a FEAT fica pronta (todos os FRs dela cobertos por PLANs **e** todas as TASKs que a listam em `Funcionalidade` — primária ou secundária, em qualquer PLAN do slug — Done); SPEC sem FEATs → uma entrada por SPEC, como sempre.

### Receita de atualização do INDEX (fonte única)

Todo comando que **atualiza** um INDEX existente aplica — mesclando, nunca sobrescrevendo:

1. Atualizar `Última atualização`.
2. Refletir o artefato na tabela correspondente (SPECs/PLANs — contrato acima) e nas seções que ele afeta: capacidades (movendo entre "Especificadas" → "Em desenvolvimento" → "Implementadas" conforme o ciclo; por FEAT quando a SPEC as declara), glossário (termo já existente com definição diferente → **parar e reportar conflito**), decisões irreversíveis, riscos ativos.
3. Adicionar entrada ao "Histórico recente" com timestamp e ação — **máximo 10 entradas**.
