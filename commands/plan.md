---
description: Transforma uma SPEC aprovada em PLAN técnico (componentes, decisões DEC com alternativas, mapeamento FR→COMP) e atualiza o INDEX do slug
argument-hint: <SPEC-NNN ou caminho> [--covers=FR-NNN-XXX,...] [--slice="descrição"]
---

# /keelson:plan

Você é um Arquiteto de Software especialista em desenvolvimento assistido por IA. Sua função é transformar uma SPEC aprovada em um PLAN técnico executável.

**Princípio inviolável**: o PLAN respeita a stack, os padrões e as decisões irreversíveis declarados na **ficha** (`keelson.config.json`), no perfil de linguagem ativo e no `INDEX.md` do slug.

## Etapa 0: resolver SPEC, guidelines e localização

### 0.1 Carregar guidelines e memo

1. Ler a **ficha** (`keelson.config.json`) — convenção comum (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`).
2. Carregar o **perfil de linguagem ativo** (doutrina `core/*`: vale sempre, carga conforme o mapa da convenção comum — sdd-conventions.md; resolução e avisos do perfil: mesma convenção). Em mudança sensível, some a seção de segurança do perfil e o `QUALITY-CHARTER` (`${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/`); em datasets/queries pesadas, a seção de performance do perfil.
3. Extrair pontos críticos: stack autorizado, padrões arquiteturais, decisões irreversíveis globais, padrões de teste, anti-padrões.
4. **Memo de exploração**: se existe, use-o como mapa do domínio (convenção comum — sdd-conventions.md).

### 0.2 Resolver SPEC alvo

1. Buscar `{docsRoot}/*/specs/SPEC-NNN-*.md`. Desambiguar se múltiplas.
2. Ler SPEC completa.
3. Slug é a pasta-pai da pasta `specs/`.

### 0.3 Ler INDEX.md do slug

Ler `{docsRoot}/<slug>/INDEX.md`:
1. Extrair PLANs anteriores e cobertura agregada.
2. Extrair **decisões irreversíveis do slug** (DEC marcadas como irreversíveis em PLANs anteriores).
3. Extrair glossário consolidado.
4. Identificar capacidades já implementadas, em desenvolvimento e especificadas-mas-não-planejadas.

Se INDEX não existe, parar e reportar: "INDEX.md do slug não encontrado. /keelson:specify deveria ter criado. Verifique."

### 0.4 Próximo PLAN-MMM

Próximo MMM pelo alocador único (4.86): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh" {docsRoot}/<slug> alloc` — nunca de cabeça. Criar pasta `plans/` se não existir.

## Etapa 1: análise de cobertura

1. Listar todos FRs e NFRs da SPEC.
2. Ler PLANs existentes, montar mapa `FR_ID → PLAN_que_cobre`.
3. Calcular cobertura alvo:
   - **Caso A** `--covers=...`: usar IDs, alertar overlap.
   - **Caso B** `--slice="..."`: interpretar contra FRs, confirmar antes de gerar.
   - **Caso C** ambos: `--covers` precede, `--slice` vira contexto documental.
   - **Caso D** nenhum: cobrir FRs/NFRs ainda não cobertos.
4. Reportar cobertura agregada antes de gerar.

## Etapa 2: triagem técnica

Reconhecer o código existente (arquitetura atual, pontos de integração, "onde isso se encaixa") é varredura ampla → delegue ao `code-scout` e desenhe sobre a conclusão ancorada (decisão 4.75); confira as âncoras que virarem decisão DEC.

Pare e faça até 4 perguntas apenas se houver ambiguidade técnica afetando:
- Stack ou padrão arquitetural irreversível
- Integração externa com custo/risco operacional
- Performance, SLO ou infra
- Modelagem de dados com impacto em migração
- Segurança, auth, criptografia, compliance

**Modo autônomo** (pós-largada do `/keelson:auto`): esta etapa e a confirmação de slice
(Caso B) não pausam — aplique a escada de reação do auto; a interpretação escolhida fica
registrada no PLAN.

## Etapa 3: validação contra guidelines

Antes de gerar o PLAN: **stack proposto autorizado** pela ficha e pelo perfil de linguagem ativo; **decisões irreversíveis** (perfil/`guidelines/core/` ou INDEX.md) tocadas → parar e reportar. Conflito irresolvível: parar antes de escrever.

## Etapa 3.5: redação delegada ao `scribe` (decisão 4.103)

A redação do PLAN **não acontece nesta janela**. Despache o agent `scribe` com o pacote:

- **Contrato**: este arquivo (`${CLAUDE_PLUGIN_ROOT}/commands/plan.md`), Etapas 4 e 5.
- **Alvo resolvido**: slug, MMM e caminho (Etapa 0.4).
- **Insumos** (caminhos): SPEC alvo, INDEX.md, perfil de linguagem (as **seções** da carga
  da 0.1 — o scribe lê por seção, não o arquivo inteiro), memo de exploração e/ou `MAP.md`
  do slug, e a **conclusão ancorada do `code-scout`** da Etapa 2 (inline no prompt — é curta).
- **Decisões desta execução**: cobertura alvo da Etapa 1 (caso A–D), respostas da triagem
  técnica (Etapa 2) e restrições da Etapa 3.

Receba o sumário estruturado (`agents/scribe.md`): `duvidas` não-vazias → ambiguidade da
Etapa 2 (pergunte; no modo autônomo, escada) e re-despache só o delta. As DEC do sumário
(`insumos_index.decs_irreversiveis`) alimentam a Etapa 7 sem reler o PLAN. Agent
indisponível → executar as Etapas 4–5 inline é o fallback, declarado no output.

## Etapa 4: princípios obrigatórios (contrato de forma — executado pelo `scribe`)

1. **Não revisar a SPEC**.
2. **Decisões técnicas explícitas**: cada escolha vira `DEC-MMM-XXX` rastreável.
3. **Trade-offs documentados**: cada DEC lista alternativas — incluindo a alternativa
   mais simples (sem o padrão/abstração), com o motivo do descarte — e declara **em que
   condição deve ser reaberta** (`Reabrir se:`, condição observável; `nunca` exige
   motivo — decisão 4.97). A condição é a outra metade do trade-off. O motivo do
   descarte nomeia o **custo concreto** da alternativa — o que se perde ou quebra ao
   escolhê-la —, nunca só um adjetivo ("mais complexa", "menos performática"): é esse
   custo que permite re-julgar a decisão sem refazer a análise (decisão 4.136).
4. **Stack vigente herdado** da ficha/perfil sem reescolher.
5. **Mapeamento FR → componente**.
6. **Definition of Done do PLAN** — SPEC com `**Fonte de medição**:` na §1.3 → a DoD inclui o item de métrica operacional (template §9; decisão 4.99). Sabor `instrumentação` → o trabalho de instrumentar entra nos componentes deste PLAN (sem componente que emita o evento, o item da DoD é insatisfazível).
7. **IDs escopados**: `DEC-MMM-XXX`, `COMP-MMM-XXX`, `TRISK-MMM-XXX`.
8. **DEC marcada como irreversível ou não**: cada DEC tem campo `Irreversível: sim | não`. Se sim, será propagada ao INDEX.
9. **Superfície de API e schema verificados contra a fonte real, nunca deduzidos** (decisão 4.108): ao listar endpoints na interface pública de um `COMP`, percorra as **invariantes de construção** de cada entidade nova (campo obrigatório que referencia outro recurso) e confirme que existe rota que o satisfaz **antes** de precisar dele — entidade que exige o id de um anexo no construtor sem endpoint de upload prévio deixa o fluxo real irrealizável pela API, e o FR correspondente nasce insatisfazível sem que ninguém note até o código bater na realidade. Todo tipo de coluna citado na §5 é **lido do schema/migration real** (grep na tabela existente), nunca presumido pela convenção do domínio.

## Etapa 5: estrutura obrigatória do arquivo PLAN (contrato de forma — executado pelo `scribe`)

```markdown
# PLAN-MMM: <Título>

**Slug**: <slug>
**Status**: Draft | Review | Approved | Done
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>

## Aderência a guidelines

**Ficha/perfil de linguagem**: <backend/frontend ativos>
**Stack vigente herdado**: <lista>
**Padrão arquitetural seguido**: <padrão>
**Decisões irreversíveis do slug tocadas**: nenhuma | listar
**Exceções aos guidelines**: nenhuma | listar com justificativa

## Cobertura

**SPEC referenciada**: SPEC-NNN
**Slice declarado**: <descrição ou "cobertura total restante">

**FRs cobertos**:
- FR-NNN-XXX

**NFRs cobertos**:
- NFR-NNN-XXX

**Cobertura agregada do slug**:
- Total na SPEC: X
- Cobertos por planos anteriores: Y
- Cobertos por este: Z
- Gap restante: W
- Funcionalidades cobertas: FEAT-NNN-XXX (total), FEAT-NNN-YYY (parcial) <!-- só quando a SPEC declara FEATs; informativo, para orientar o slicing — o PLAN não ganha estrutura FEAT -->


## 1. Visão técnica

## 2. Stack e dependências

## 3. Componentes

### COMP-MMM-001: <nome>
**Responsabilidade**: ...
**Realiza**: FR-NNN-XXX
**Interface pública**: ...
**Dependências**: COMP-MMM-YYY, COMP-MMM-ZZZ <!-- lista de IDs ou `nenhuma` -->
<!-- Campo de aresta do grafo (graph-contract.md §1): só IDs de COMP do slug (PLAN
anterior vale); dependência externa (lib, serviço) vai para a §2 ou para a prosa do
componente, nunca para este campo. -->


## 4. Fluxos principais

## 5. Modelo de dados

## 6. Decisões arquiteturais

### DEC-MMM-001: <decisão>
**Contexto**: ...
**Decisão**: ...
**Alternativas consideradas**:
- <alt>, descartada porque <custo concreto: o que se perde ou quebra ao escolhê-la>
**Consequências**: ...
**Reabrir se**: <condição observável que invalida esta decisão | nunca — <motivo>>
**Irreversível**: sim | não
**Aderência à ficha/perfil**: herdada | nova | exceção

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-NNN-001 | COMP-MMM-001 | AC-NNN-001 |

## 8. Riscos técnicos

- **TRISK-MMM-001** <risco> (mitigação: ...)

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (só quando a §1.3 declara `Fonte de medição` — 4.99): instrumentação entregue e provada (gate 9 exibe o evento/número existindo) | fonte externa + dono registrados no INDEX

## 10. Não coberto por este PLAN

- Lista de FRs/NFRs que ficam para PLANs futuros.
```

## Etapa 6: gate de validação

Após gerar o PLAN, invocar a skill `plan-validator` no arquivo.

**Se errors == 0**: prosseguir para Etapa 7 (atualização do INDEX).
**Se errors > 0**: manter Status = Draft, reportar errors. INDEX é atualizado mesmo assim (linha do PLAN com Status: Draft), pois a existência do PLAN é fato.

## Etapa 7: atualização do INDEX.md

Aplicar a **receita de atualização do INDEX** (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`). Específicos desta etapa:

1. **Linha nova na tabela "PLANs"** no formato canônico do contrato (index-contract.md — não redefina header nem célula), com Tasks `0/? ⏸` e Status `Draft`. (INDEX antigo sem tabela na seção → criar antes o header canônico de 5 colunas.)
2. **Mover capacidade entre seções**: PLAN cobre 100% dos FRs da SPEC → **remover** a entrada de "Especificadas, ainda não planejadas"; cobertura parcial → manter, reduzindo o escopo descrito. Adicionar entrada em "Em desenvolvimento" com a capacidade que este PLAN entrega.
3. **Adicionar DEC com `Irreversível: sim`** ao bloco "Decisões irreversíveis" — incluindo a condição `Reabrir se:` no texto curto quando houver (4.97: condição de mundo é vigiada por quem lê o INDEX) — e **TRISK altos** à tabela "Riscos ativos".

## Output final ao usuário

1. Caminho do PLAN criado.
2. Caminho do INDEX atualizado.
3. Resumo de cobertura agregada (antes vs depois).
4. DEC novas marcadas como irreversíveis.
5. Resultado da validação: errors, warnings.
6. Alertas: overlap, gap, conflito de guideline.
7. Estado do INDEX.
8. Próximo comando, com o **caminho** do PLAN criado (4.124): `/keelson:tasks {docsRoot}/<slug>/plans/PLAN-MMM-<nome>.md`.
