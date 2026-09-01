# TASK-002-011: Registrar rota do lote

**Slug**: defeitos
**Pertence a**: PLAN-002
**Realiza (FRs)**: FR-002-020
**Componente**: COMP-002-001
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-rota-lote
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-002-001
- **Bloqueia**: nenhuma

## Contexto

Waves são numeradas por PLAN: mesma wave em PLANs distintos não é colisão.

## Escopo

### Inclui

- Editar `src/Rotas/registro.php` para registrar a rota do lote

### Não inclui

- Rotas de PLAN-001

## Implementação sugerida

Seguir o contrato do COMP-002-001.

## Critérios de pronto

- [ ] AC-002-020 coberto por teste de integração
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-002-020: chamar a rota do lote e ver a resposta esperada.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
