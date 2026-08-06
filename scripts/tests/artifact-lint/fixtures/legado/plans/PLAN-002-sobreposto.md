# PLAN-002: Plano sobreposto

**Slug**: legado
**Status**: Done
**Versão**: 1.0
**Autor**: Fernando
**Data**: 2025-03-10

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend ativo
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: retrabalho do fluxo

**FRs cobertos**:
- FR-001-001

**Cobertura agregada do slug**: FR-001-001 retrabalhado por este PLAN.

## 1. Visão técnica

Reexecutor do fluxo.

## 2. Stack e dependências

Sem dependência nova.

## 3. Componentes

### COMP-002-001: Reexecutor

**Responsabilidade**: reexecutar o fluxo
**Realiza**: FR-001-001
**Interface pública**: reexecutar()
**Dependências**: nenhuma

## 4. Fluxos principais

Reexecução manual.

## 5. Modelo de dados

Reusa a tabela de execuções.

## 6. Decisões arquiteturais

### DEC-002-001: Reuso do executor

**Contexto**: lógica duplicada entre execução e reexecução.
**Decisão**: reusar o executor com parâmetro.
**Alternativas consideradas**:
- Duplicar a lógica — dois pontos de manutenção.
- Extrair um serviço novo — custo alto para o ganho atual.
**Consequências**: parâmetro adicional no executor.
**Irreversível**: não

## 7. Mapeamento FR -> componente

| FR | Componente | ACs |
|----|------------|-----|
| FR-001-001 | COMP-002-001 | AC-001-001 |

## 8. Riscos técnicos

### TRISK-002-001: Reexecução dupla

Cliques repetidos disparam duas reexecuções.

## 9. Definition of Done deste PLAN

- [ ] Cobertura de testes do reexecutor
- [ ] Aderência à ficha/perfil verificada

## 10. Não coberto por este PLAN

Nada.
