# TASK-001-016: Esperado com placeholder

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-016
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-esperado-placeholder
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Critérios com comando conferido mas não executado: o esperado traz placeholder.

## Escopo

### Inclui

- Serviço de alocações

### Não inclui

- Telas

## Implementação sugerida

Seguir o contrato do COMP-001-004.

## Critérios de pronto

- [ ] AC-001-016 coberto — verificação executável: `vendor/bin/phpunit --filter AlocacaoServiceTest` → `OK (N tests), N > 0`
- [ ] Lint verde — verificação executável: `vendor/bin/phpcs src/Alocacao` → `OK (N)`

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
