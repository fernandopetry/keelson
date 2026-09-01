# TASK-001-014: Coluna de componente na tabela

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-030
**Funcionalidade**: FEAT-001-030
**Componente**: COMP-001-030
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-coluna
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Coluna nova derivada de campo existente do payload.

## Escopo

### Inclui

- Renderização da coluna nova na tabela

### Não inclui

- Consulta nova ao backend

## Implementação sugerida

Derivar a célula do campo já presente na resposta.

## Critérios de pronto

- [x] AC-001-030 coberto por teste de renderização

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-030: abrir a tela e ver a coluna preenchida.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-08-31 (não medida na abertura pelo developer — lacuna declarada)
**Data conclusão**: 2026-09-01T16:02:11-0300
**Commit SHA**: abc1234
