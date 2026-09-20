# Contrato de forma do PLAN (fixture fixa deste caso)


> Fixture fixa: o caso mede a HERANÇA brief → SPEC, não o contrato do PLAN — por isso o
> contrato é idêntico nos dois braços e reduzido ao template mais três princípios de forma.

## Princípios

1. Não revisar a SPEC; cada escolha técnica vira `DEC-001-XXX` com alternativas e `Reabrir se:`.
2. Stack vigente herdado da ficha (memo) sem reescolher; `Realiza` obrigatório em cada COMP.
3. O que a SPEC decide (atores, premissas, escopo) o PLAN respeita — inclusive o que ela
   herda de outro documento por referência.

## Template canônico

# PLAN-MMM: <Título>

**Slug**: <slug>
**Status**: Draft
**Versão**: 0.1
**Autor**: scribe
**Data**: <YYYY-MM-DD>

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma | listar
**Decisões irreversíveis de outros slugs em conflito**: nenhuma | listar
**Exceções aos guidelines**: nenhuma | listar com justificativa

## Cobertura

**SPEC referenciada**: SPEC-NNN
**Slice declarado**: <descrição ou "cobertura total restante">

**FRs cobertos**:
- FR-NNN-XXX

**NFRs cobertos**:
- NFR-NNN-XXX

## 1. Visão técnica

## 2. Stack e dependências

## 3. Componentes

### COMP-MMM-001: <nome>
**Responsabilidade**: ...
**Realiza**: FR-NNN-XXX
**Interface pública**: ...
**Dependências**: COMP-MMM-YYY | nenhuma

## 4. Fluxos principais

## 5. Modelo de dados

## 6. Decisões arquiteturais

### DEC-MMM-001: <decisão>
**Contexto**: ...
**Decisão**: ...
**Alternativas consideradas**:
- <alt>, descartada porque <motivo>
**Consequências**: ...
**Reabrir se**: <condição>
**Irreversível**: sim | não
**Aderência à ficha/perfil**: herdada | nova | exceção

## 8. Riscos técnicos

- **TRISK-MMM-001** <risco> (mitigação: ...)

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Todos os ACs cobertos por teste

## 10. Não coberto por este PLAN

- <FRs/NFRs que ficam para PLANs futuros | nenhum>
