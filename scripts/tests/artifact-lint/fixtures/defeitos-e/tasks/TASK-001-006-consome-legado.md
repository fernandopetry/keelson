# TASK-001-006: Consome o legado

**Slug**: defeitos-e
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-006
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-e
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Controle negativo: cita artefato de criadora Done.

## Escopo

### Inclui

- Teste em `tests/Ui/LegacyTest.php`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-006 legado presente — o arquivo `src/Ui/Legacy.vue` existe — verificação executável: `test -f src/Ui/Legacy.vue && echo ok` → `ok`
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-006: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
