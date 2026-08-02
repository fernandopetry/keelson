# TASK-002-001: Atualizar timeout do worker de exportação

**Slug**: valido-avulso
**Brief**: BRIEF-002
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-002-002

## Contexto

Fixture de brief avulso (decisão 4.86): TASK ancorada por `Brief`, sem PLAN.

## Escopo

### Inclui
- config do worker de exportação

### Não inclui
- fila de jobs

## Critérios de pronto

- [ ] Exportação de 10k linhas conclui sem timeout — verificação executável: `make export-test` → verde

## Histórico de execução (preenchido pelo /keelson:implement)
