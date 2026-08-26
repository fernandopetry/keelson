# TASK-001-002: Recusar solicitação idêntica em andamento

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-002 (contrato herdado do registrador)
**Funcionalidade**: FEAT-001-001 (primária)
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: feat/corpus-dedupe-solicitacao
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-001-003, TASK-001-005

## Contexto

Enquanto uma solicitação do operador está em andamento, a idêntica é recusada
apontando a existente — regra de negócio do registrador, não corrida de banco.

## Escopo

### Inclui

- Guarda de deduplicação no registrador de solicitações

### Não inclui

- Deduplicação entre operadores distintos

## Implementação sugerida

Consultar a situação "em andamento" do operador antes de registrar.

## Critérios de pronto

- [ ] Recusa de solicitação idêntica coberta por teste de integração — verificação executável:
  `make test` → o caso da recusa lista o cenário do AC-001-002 com a solicitação
  em andamento apontada na resposta, `OK (3 tests)`
- [ ] Solicitação de período distinto do mesmo operador segue aceita — verificação executável: `make test` → verde

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-08-15T09:05:00-03:00
**Data conclusão**: 2026-08-15T11:52:00-03:00
**Commit SHA**: d4e5f6a
**Implementado por**: developer
**Revisado por**: code-reviewer

- [x] code review aprovado (wave 1)
- [x] testes passando aprovado (wave 1)
