# PLAN-001: Plano antigo

**Slug**: legado
**Status**: Done
**Versão**: 1.0
**Autor**: Fernando
**Data**: 2025-01-15

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend ativo
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: total

**FRs cobertos**:
- FR-001-001

**Cobertura agregada do slug**: 1/1 FR coberto.

## 1. Visão técnica

Executor agendado.

## 2. Stack e dependências

Sem dependência nova.

## 3. Componentes

### COMP-001-001: Executor

**Responsabilidade**: executar o fluxo
**Realiza**: FR-001-001
**Interface pública**: executar()
**Dependências**: nenhuma

## 4. Fluxos principais

Agendamento e execução.

## 5. Modelo de dados

Tabela de execuções.

## 6. Decisões arquiteturais

### DEC-001-001: Execução única

**Contexto**: sobreposição corrompe o resultado.
**Decisão**: trava de execução única.
**Alternativas consideradas**:
- Fila serializada — infraestrutura nova só para isso.
- Sem trava — corrompe o resultado na sobreposição.
**Consequências**: execução atrasada espera a anterior.
**Irreversível**: não

## 7. Mapeamento FR -> componente

| FR | Componente | ACs |
|----|------------|-----|
| FR-001-001 | COMP-001-001 | AC-001-001 |

## 8. Riscos técnicos

### TRISK-001-001: Trava presa

Trava não liberada após falha.

## 9. Definition of Done deste PLAN

- [ ] Cobertura de testes do executor
- [ ] Aderência à ficha/perfil verificada

## 10. Não coberto por este PLAN

Nada.
