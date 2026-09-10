# PLAN-001: Degradação por parse

**Slug**: defeito-parse-degrade
**Status**: Approved

## Cobertura

**SPEC referenciada**: SPEC-001

**FRs cobertos**:
- FR-001-001
- FR-001-002

## 3. Componentes

### COMP-001-001: Nucleo
**Responsabilidade**: fixture.
**Realiza**: FR-001-001
**Dependências**: nenhuma

### COMP-001-002: Realiza nao-parseavel
**Responsabilidade**: fixture — token irreconhecivel em **Realiza** degrada fr-sem-comp a [parse] (4.409).
**Realiza**: realiza o segundo fluxo descrito acima
**Dependências**: nenhuma
