# TASK-001-010: Varredura de IDs SDD na copy

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-012
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-varredura-ids
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Copy voltada ao usuário não carrega rastro de processo. O critério abaixo contém a
substring "AC-" (dentro do regex) sem citar nenhum AC bem-formado — o check
task-criterio-sem-ac tem de disparar mesmo assim (plant da 4.254).

## Escopo

### Inclui

- Limpeza de IDs SDD na copy das views

### Não inclui

- Refatoração das views

## Implementação sugerida

Remover os IDs da copy, preservando as âncoras de código.

## Critérios de pronto

- [ ] Nenhum ID SDD na copy — verificação executável: `grep -rcE 'AC-[0-9]+-[0-9]+' resources/views/` → 0
- [ ] Helper legado ausente — verificação executável: `grep -rc 'Copy::helper' resources/views/` → 0

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
