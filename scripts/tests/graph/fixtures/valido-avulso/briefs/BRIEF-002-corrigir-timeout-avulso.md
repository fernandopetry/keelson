# BRIEF-002: Corrigir timeout da exportação

**Slug**: valido-avulso
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-08-02
**Origem**: PROJ-123 (rota pull)
**Jira**: PROJ-123

## Pedido como dito

O export de relatório está estourando timeout com mais de 10k linhas.

## Interpretação

Aumentar o timeout do worker de exportação e documentar o novo limite.

## Critério de aceite

- Exportação de 10k linhas conclui sem timeout (medida em ambiente local)

## Lições aplicáveis

--- id=timeout-de-exportacao-tem-teste-de-volume estado=ativa via=path origem=gate | Timeout de exportação tem teste com volume real | paths=src/Export/** | tags=teste
# lessons.sh match: omitidas=1 por --max-bytes 40000: worker-sem-retry — `show <id>` traz o texto

## TASKs

TASK-002-001, TASK-002-002

## Execução

<closure nas TASKs>
