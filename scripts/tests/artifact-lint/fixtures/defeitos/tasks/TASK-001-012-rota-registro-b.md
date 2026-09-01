# TASK-001-012: Registrar rota do fluxo B

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-021
**Componente**: COMP-001-004
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-rota-b
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

Fluxo B precisa de rota própria no registro central.

## Escopo

### Inclui

- Acrescentar a rota do fluxo B em src/Rotas/registro.php e o handler em src/Rotas/HandlerB.php
- Validação da entrada do fluxo B

### Não inclui

- Rotas do fluxo A

## Implementação sugerida

Seguir o contrato do COMP-001-004.

## Critérios de pronto

- [ ] AC-001-021 coberto por teste de integração
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-021: chamar a rota do fluxo B e ver a resposta esperada.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
