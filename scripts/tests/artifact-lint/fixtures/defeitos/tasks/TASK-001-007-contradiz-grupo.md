# TASK-001-007: Guard de permissão do lote

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-009
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-guard-lote
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Prova de permissão do endpoint de lote. Lição do projeto: prova de segurança
NUNCA leva `@group skip-migration` — ela precisa rodar no `make test`.

## Escopo

### Inclui

- Guard de permissão do endpoint de lote

### Não inclui

- Rate limit

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-009 coberto por prova de recusa — verificação executável: `vendor/bin/phpunit --filter GuardLoteTest --group skip-migration` → `OK (3 tests)`

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
