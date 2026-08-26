# TASK-001-001: Registrar solicitação de exportação

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-001
**Funcionalidade**: FEAT-001-001 (primária)
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: feat/corpus-registrador-solicitacoes
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-001-004, TASK-001-005

## Contexto

Primeiro passo do fluxo: a solicitação vira registro com operador, período e
situação, e entra na fila de geração (DEC-001-001).

## Escopo

### Inclui

- Registro da solicitação com validação de período
- Enfileiramento da geração na fila existente

### Não inclui

- Deduplicação de solicitação em andamento (TASK-001-002)
- Geração do arquivo (COMP-001-002)

## Implementação sugerida

Seguir o contrato do COMP-001-001; situação inicial "em andamento".

## Critérios de pronto

- [ ] AC-001-001 coberto por teste de integração — verificação executável: `make test` → `OK (2 tests)` no grupo do registrador
- [ ] Período inválido recusado com mensagem orientativa — verificação executável: `make test` → caso de período invertido vermelho antes do fix do validador, verde depois
- [ ] Solicitação registrada com carimbo de data medido (NFR-001-002)

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-08-14T09:12:00-03:00
**Data conclusão**: 2026-08-14T16:40:00-03:00
**Commit SHA**: a1b2c3d
**Implementado por**: developer
**Revisado por**: code-reviewer

- [x] code review aprovado (wave 1)
- [x] testes passando aprovado (wave 1)
