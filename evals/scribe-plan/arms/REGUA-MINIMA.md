# Contrato de forma do PLAN (braço MÍNIMO — controle "regra × default do modelo")

> Braço de controle da camada de evals (4.304, diretriz "poda só com prova"): contém
> **só o template do PLAN, zero princípio**. Mede o que o modelo faz por default — eixo
> em que ele acerta sem instrução é candidato a poda COM prova; eixo em que erra é regra
> que paga o próprio custo.

## O que fazer

Desenhe você a solução técnica para a SPEC sobre o território do memo — use o seu próprio
julgamento de arquitetura. Não há princípios aqui além do template abaixo.

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
