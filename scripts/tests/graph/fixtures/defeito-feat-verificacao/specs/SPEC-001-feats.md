# SPEC-001: Funcionalidades em andamento

**Slug**: defeito-feat-verificacao
**Status**: Approved
**Data**: 2026-08-02

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Entrada
> Completa e sem verificação declarada — deve reprovar.

- **FR-001-001** [MUST] Quando o usuário entra, o sistema DEVE registrar.

### FEAT-001-002: Saída
> Completa e com verificação declarada — não reprova.

**Verificação (gate 9)**: 2026-08-02 — verificada no browser (qa), claro + escuro

- **FR-001-002** [MUST] Quando o usuário sai, o sistema DEVE registrar.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** (cobre FR-001-001)
  - Given usuário, When entra, Then registro criado.
- **AC-001-002** (cobre FR-001-002)
  - Given usuário, When sai, Then registro criado.
