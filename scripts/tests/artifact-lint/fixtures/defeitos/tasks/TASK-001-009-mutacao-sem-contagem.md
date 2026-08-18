# TASK-001-009: Escopo de tenant sem fechamento contável

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-011
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-escopo-tenant
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Repositório com predicado de escopo por tenant. O critério pede mutação mas
enumera instâncias em vez de declarar o par contável.

## Escopo

### Inclui

- Repositório de alocações com escopo por tenant

### Não inclui

- Telas

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-011 coberto — o predicado de escopo de tenant do repositório tem prova de mutação no findBySquad (fixture de dois pais, mutação do predicado reprova)

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
