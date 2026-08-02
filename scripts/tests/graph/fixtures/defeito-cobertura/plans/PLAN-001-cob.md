# PLAN-001: Defeitos de cobertura

**Slug**: defeito-cobertura
**Status**: Approved

## Cobertura

**SPEC referenciada**: SPEC-001

**FRs cobertos**:
- FR-001-001
- FR-001-002

## 3. Componentes

### COMP-001-001: Principal
**Responsabilidade**: fixture.
**Realiza**: FR-001-001, FR-001-002
**Dependências**: nenhuma

### COMP-001-002: Orfao
**Responsabilidade**: fixture sem linha na §7.
**Realiza**: 
**Dependências**: nenhuma

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-001-001 | COMP-001-001 | AC-001-001 |
| FR-001-003 | COMP-001-001 | AC-001-003 |
