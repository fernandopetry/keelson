# TASK-001-003: Painel com marcador compartilhado

**Slug**: defeitos-e
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-003
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

Controle negativo: o marcador também está no próprio Inclui (contrato congelado, 4.106) — o lint fica em silêncio.

## Escopo

### Inclui

- Painel em `src/Ui/Painel.vue` reusando o marcador `data-testid="discard-card"` (contrato congelado)

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-003 painel foca o card `data-testid="discard-card"`
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-003: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
