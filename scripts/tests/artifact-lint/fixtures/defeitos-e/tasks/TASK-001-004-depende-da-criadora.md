# TASK-001-004: Atalho para o card

**Slug**: defeitos-e
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-004
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

- **Depende de**: TASK-001-001
- **Bloqueia**: nenhuma

## Contexto

Controle negativo: declara `Depende de` a criadora — a coerência de wave é do grafo (`wave-incoerente`), o lint não duplica o achado.

## Escopo

### Inclui

- Atalho em `src/Ui/Atalho.vue`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-004 atalho rola até `data-testid="discard-card"`
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-004: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
