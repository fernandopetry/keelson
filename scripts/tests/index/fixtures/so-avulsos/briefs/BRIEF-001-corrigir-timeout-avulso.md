# BRIEF-001: Corrigir timeout da exportação

**Slug**: so-avulsos
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-11-06
**Origem**: Diretor (pedido em sessão)

## Pedido como dito

O export de relatório está estourando timeout com mais de 10k linhas.

## Interpretação

Aumentar o timeout do worker de exportação e documentar o novo limite.

## Critério de aceite

- Exportação de 10k linhas conclui sem timeout (medida em ambiente local)

## TASKs

nenhuma — o brief é a unidade de execução

## Execução

- **Implementado por**: developer
- **Revisado por**: code-reviewer (gates 1–7) · qa (gate 9)
- **Commit**: pendente — commit é ato do Diretor
