# TASK-001-004: Extrair consulta de pedidos do gerador

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: nenhuma
**Componente**: COMP-001-002
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: refactor
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: refactor/corpus-consulta-pedidos
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-001
- **Bloqueia**: TASK-001-006

## Contexto

A consulta de pedidos do período vive embutida no gerador; extraí-la prepara a
geração em blocos do TRISK-001-001 sem mudar comportamento.

## Escopo

### Inclui

- Extração da consulta de pedidos para colaborador próprio do gerador

### Não inclui

- Geração em blocos (plano B do TRISK-001-001)

## Implementação sugerida

Mover a consulta preservando assinatura e ordenação; o gerador delega.

## Critérios de pronto

- [ ] Comportamento observável idêntico — verificação executável: `make test` → suíte inteira verde, sem caso novo e sem caso alterado
- [ ] Baseline da suíte capturada antes da extração e comparada depois — verificação executável: `make test` → mesma contagem de casos da baseline

## Riscos específicos

Ordenação implícita da consulta original perdida na extração.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
