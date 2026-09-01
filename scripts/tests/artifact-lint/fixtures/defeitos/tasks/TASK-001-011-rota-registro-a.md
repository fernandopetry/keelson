# TASK-001-011: Registrar rota do fluxo A

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-020
**Componente**: COMP-001-003
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-rota-a
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

Fluxo A precisa de rota própria no registro central.

## Escopo

### Inclui

- Editar `src/Rotas/registro.php` para registrar a rota do fluxo A
- Handler do fluxo A

### Não inclui

- Rotas do fluxo B

## Implementação sugerida

Seguir o contrato do COMP-001-003.

## Critérios de pronto

- [ ] AC-001-020 coberto por teste de integração
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-020: chamar a rota do fluxo A e ver a resposta esperada.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
