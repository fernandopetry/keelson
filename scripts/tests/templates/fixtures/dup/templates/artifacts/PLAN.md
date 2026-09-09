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
