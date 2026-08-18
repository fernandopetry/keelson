# TASK-001-008: Prova de permissão herdando grupo de suíte

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-010
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-prova-permissao
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Prova de permissão do endpoint de exportação. O comando herdou o grupo padrão do
projeto como boilerplate — nada aqui proíbe a tag, então não há contradição textual.

## Escopo

### Inclui

- tests/Security/ExportPermissionTest.php

### Não inclui

- Rate limit

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-010 coberto por prova de recusa — verificação executável: `vendor/bin/phpunit --filter ExportPermissionTest --group integration` → `OK (3 tests)`

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
