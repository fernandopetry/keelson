# TASK-001-019: Guard sem grupo

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-034
**Componente**: COMP-001-004
**Wave**: 4
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-guard-sem-grupo
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

Guard de permissão do endpoint de consulta. NUNCA leva `@group skip-migration` — roda no `make test`.

## Escopo

### Inclui

- Guard de permissão do endpoint de consulta
- Teste de recusa do guard

### Não inclui

- Rotas do fluxo A

## Implementação sugerida

Seguir o contrato do COMP-001-004.

## Critérios de pronto

- [ ] AC-001-024 coberto por teste de integração — verificação executável: `vendor/bin/phpunit --group migration --filter MigracaoGuardTest` (sem `--group skip-migration`) → `OK (1 test)`
- [ ] GuardConsultaTest nasce **sem** `--group skip-migration` — verificação executável: `vendor/bin/phpunit --filter GuardConsultaTest` → `OK (2 tests)`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-024: chamar sem permissão e ver 403.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
