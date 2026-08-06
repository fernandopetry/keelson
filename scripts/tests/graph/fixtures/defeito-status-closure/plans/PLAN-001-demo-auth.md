# PLAN-001: Autenticação de demonstração

**Slug**: valido
**Status**: Approved
**Versão**: 0.1
**Autor**: fixture
**Data**: 2026-08-01

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: cobertura total

**FRs cobertos**:
- FR-001-001
- FR-001-002
- FR-001-003

**NFRs cobertos**:
- NFR-001-001

## 3. Componentes

### COMP-001-001: AuthService
**Responsabilidade**: autenticação.
**Realiza**: FR-001-001, FR-001-002
**Interface pública**: login()
**Dependências**: nenhuma

### COMP-001-002: AccessReport
**Responsabilidade**: relatório de acessos.
**Realiza**: FR-001-003
**Interface pública**: list()
**Dependências**: COMP-001-001

## 6. Decisões arquiteturais

### DEC-001-001: sessão por cookie
**Contexto**: fixture.
**Decisão**: cookie httpOnly.
**Alternativas consideradas**:
- token no localStorage, descartado porque fixture.
**Consequências**: nenhuma.
**Irreversível**: não

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-001-001 | COMP-001-001 | AC-001-001 |
| FR-001-002 | COMP-001-001 | AC-001-002 |
| FR-001-003 | COMP-001-002 | AC-001-003 |
