# TASK-001-011: Cadeia: ponta

**Slug**: defeitos-f
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-011
**Componente**: COMP-001-001
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-f
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-010
- **Bloqueia**: nenhuma

## Contexto

Controle negativo: alcança a criadora só por transitividade (011 → 010 → 009).

## Escopo

### Inclui

- Usar `helperEmCadeia` em `src/Ui/CadeiaC.vue`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-011 comportamento observável do item
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-011: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
