## Etapa 4: princípios obrigatórios (contrato de forma — executado pelo `scribe`)

1. **Não revisar a SPEC**.
2. **Decisões técnicas explícitas, em dois níveis — a forma é proporcional ao que a DEC decide**: cada escolha vira `DEC-MMM-XXX` rastreável. **DEC nova** — escolha que este PLAN faz e que ficha, perfil, INDEX ou memo **não ditam** — e toda DEC **irreversível** ou **exceção** ganham a forma completa (princípio 3). **DEC herdada** — escolha que já vem decidida da ficha, do perfil, de DEC vigente do INDEX **ou da própria SPEC** (premissa decidida, NFR), e que este PLAN apenas aplica — é **uma linha** na lista `### Decisões herdadas` da §6: o enunciado + a fonte; sem Contexto, Alternativas nem Reabrir se (quem decidiu já os registrou na fonte). A linha herdada cobre **só o que a fonte dita**: a escolha que **sobra** ao aplicá-la — *como* cumprir um requisito diante do que o território impõe (ex.: um teto de tempo sobre um cliente que já faz retry por conta própria) — é DEC nova, em forma completa. Na dúvida entre os dois níveis, é nova: alternativa inventada para justificar o que a ficha manda é ruído, mas decisão real rebaixada a uma linha perde o trade-off.
3. **Trade-offs documentados**: cada DEC **nova** lista alternativas — incluindo a alternativa
   mais simples (sem o padrão/abstração), com o motivo do descarte — e declara **em que
   condição deve ser reaberta** (`Reabrir se:`, condição observável; `nunca` exige
   motivo — decisão 4.97). A condição é a outra metade do trade-off. O motivo do
   descarte nomeia o **custo concreto** da alternativa — o que se perde ou quebra ao
   escolhê-la —, nunca só um adjetivo ("mais complexa", "menos performática"): é esse
   custo que permite re-julgar a decisão sem refazer a análise (decisão 4.136).
4. **Stack vigente herdado** da ficha/perfil sem reescolher.
5. **Mapeamento FR → componente é derivado** (4.409): cada COMP declara `**Realiza**:` — obrigatório (`plan-comp-sem-realiza`), única fonte da aresta; a tabela sai de `graph.sh --format=tables` e não se escreve.
6. **Definition of Done do PLAN** — SPEC com `**Fonte de medição**:` na §1.3 → a DoD inclui o item de métrica operacional (template §9; decisão 4.99). Sabor `instrumentação` → o trabalho de instrumentar entra nos componentes deste PLAN (sem componente que emita o evento, o item da DoD é insatisfazível).
7. **IDs escopados**: `DEC-MMM-XXX`, `COMP-MMM-XXX`, `TRISK-MMM-XXX`.
8. **DEC marcada como irreversível ou não**: cada DEC tem campo `Irreversível: sim | não` — valor **literal** do enum, sem prosa; a justificativa mora em Contexto/Consequências da própria DEC (valor fora do enum é ERROR do lint, `plan-dec-irreversivel-enum` — decisão 4.367). Se sim, será propagada ao INDEX.

## Etapa 5: estrutura obrigatória do arquivo PLAN (contrato de forma — executado pelo `scribe`)

Template canônico: `${CLAUDE_PLUGIN_ROOT}/templates/artifacts/PLAN.md` — o scribe o lê na
fonte e reproduz a estrutura à risca; comentários `<!-- -->` são régua, nunca conteúdo
(decisão 4.405).

---
<!-- anexo da régua: templates/artifacts/PLAN.md -->
<!-- Template canônico do PLAN (decisão 4.405). Dono da régua de forma: commands/plan.md, Etapa 4. Comentários <!-- --> são instrução ao scribe, nunca conteúdo do artefato gerado. -->

# PLAN-MMM: <Título>

**Slug**: <slug>
**Status**: Draft | Review | Approved | Done
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma | listar
**Decisões irreversíveis de outros slugs em conflito**: nenhuma | `{docsRoot}/<outro-slug>/INDEX.md` DEC-MMM-XXX — <justificativa: por que este PLAN não a quebra, ou por que a divergência é legítima>
**Exceções aos guidelines**: nenhuma | listar com justificativa

## Cobertura

**SPEC referenciada**: SPEC-NNN
**Slice declarado**: <descrição ou "cobertura total restante">

**FRs cobertos**:
- FR-NNN-XXX

**NFRs cobertos**:
- NFR-NNN-XXX

<!-- Cobertura agregada do slug (total, anteriores, este, gap) e o mapeamento FR -> COMP
NÃO se escrevem (4.409): são derivados de `graph.sh <slug> --format=tables` a partir de
FRs cobertos + **Realiza** dos COMPs. -->

## 1. Visão técnica

## 2. Stack e dependências

## 3. Componentes

### COMP-MMM-001: <nome>
**Responsabilidade**: ...
**Realiza**: FR-NNN-XXX <!-- obrigatório: única fonte da aresta FR -> COMP (lint plan-comp-sem-realiza) -->
**Interface pública**: ...
**Dependências**: COMP-MMM-YYY, COMP-MMM-ZZZ <!-- lista de IDs ou `nenhuma` -->
<!-- Campo de aresta do grafo (graph-contract.md §1): só IDs de COMP do slug (PLAN
anterior vale); dependência externa (lib, serviço) vai para a §2 ou para a prosa do
componente, nunca para este campo. -->


## 4. Fluxos principais

## 5. Modelo de dados

## 6. Decisões arquiteturais

### Decisões herdadas
<!-- Uma linha por escolha que ficha, perfil ou INDEX já ditam e este PLAN só aplica
(princípio 2) — ficha, perfil, INDEX ou a própria SPEC: o ID continua citável por COMP, TASK e código. Sem herdadas → omitir o heading. -->
- **DEC-MMM-00N** [herdada] <enunciado em uma frase> — fonte: <ficha (campo) | perfil §X | INDEX DEC-PPP-XXX | SPEC A-NNN-XXX/NFR-NNN-XXX>

### DEC-MMM-001: <decisão nova, irreversível ou exceção>
**Contexto**: ...
**Decisão**: ...
**Alternativas consideradas**:
- <alt>, descartada porque <custo concreto: o que se perde ou quebra ao escolhê-la>
**Consequências**: ...
**Reabrir se**: <condição observável que invalida esta decisão | nunca — <motivo>>
**Irreversível**: sim | não
**Aderência à ficha/perfil**: nova | exceção

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
