# TASK-001-007: Metade A do contrato

**Slug**: defeitos-f
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-007
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-f
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Controle negativo: `contratoCongelado` está em crase na DEC do PLAN — compartilhado por desenho (4.300), o lint fica mudo.

## Escopo

### Inclui

- Metade servidor em `src/Api/ContratoA.php` honrando `contratoCongelado`

### Não inclui

- Nada além do PLAN

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-007 comportamento observável do item
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit --group unit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-007: abrir o painel e ver o resultado esperado.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
