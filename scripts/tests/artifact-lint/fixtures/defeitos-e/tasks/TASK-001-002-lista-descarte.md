# TASK-001-002: Lista de descarte

**Slug**: defeitos-e
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-002
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

Defeito plantado: cita nos Critérios o marcador que a TASK-001-001 cria, na mesma wave, sem `Depende de`.

## Escopo

### Inclui

- Lista em `src/Ui/DiscardList.vue`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-002 painel abre o card `data-testid="discard-card"` ao clicar — verificação executável: `vendor/bin/phpunit --filter DiscardListTest` → `OK`
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-002: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
