# TASK-001-006: Consome o helper legado

**Slug**: defeitos-f
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-006
**Componente**: COMP-001-001
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-f
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-005
- **Bloqueia**: nenhuma

## Contexto

Controle negativo: único carregador não-Done de `helperLegado`.

## Escopo

### Inclui

- Usar `helperLegado` em `src/Ui/Legado.vue`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-006 comportamento observável do item
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-006: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
