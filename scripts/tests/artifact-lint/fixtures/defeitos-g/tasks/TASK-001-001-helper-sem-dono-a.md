# TASK-001-001: Selo de idade

**Slug**: defeitos-g
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-001
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-g
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Defeito plantado (4.494): o mesmo par da defeitos-f, num PLAN SEM crase alguma — o contrato de plano vazio não pode silenciar o check.

## Escopo

### Inclui

- Helper `formatarDataHoje` em `src/Util/DataA.php`
- Selo em `src/Ui/SeloIdade.vue`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-001 comportamento observável do item
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-001: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
