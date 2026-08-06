# SPEC-001: Autenticação de demonstração

**Slug**: valido
**Status**: Approved
**Data**: 2026-08-01

## 1. Contexto e objetivo

Fixture válida da suíte do graph.sh — exercita todos os tipos de nó e aresta.

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Login no portal
> Fluxo de entrada do usuário.

- **FR-001-001** [MUST] Quando o usuário submete credenciais válidas, o sistema DEVE iniciar sessão.
- **FR-001-002** [MUST] Quando as credenciais são inválidas, o sistema DEVE recusar com mensagem.

### FEAT-001-002: Relatório de acessos
> Fluxo de consulta.

- **FR-001-003** [MUST] Enquanto autenticado, o usuário DEVE poder listar os próprios acessos.

## 6. Requisitos não-funcionais

- **NFR-001-001** [MUST] O login responde em menos de 1s.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** (cobre FR-001-001)
  - Given credenciais válidas, When submete, Then sessão iniciada.
- **AC-001-002** (cobre FR-001-002)
  - Given credenciais inválidas, When submete, Then recusa com mensagem.
- **AC-001-003** (cobre FR-001-003, NFR-001-001)
  - Given usuário autenticado, When lista acessos, Then vê apenas os próprios em menos de 1s.
