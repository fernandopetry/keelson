# TASK-001-002: Implementar bloqueador

**Slug**: defeitos-b
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-003 / AC-001-002
**Funcionalidade**: FEAT-001-002 (primária)
**Componente**: COMP-001-002
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: bugfix
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/valido-bloqueador
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-001
- **Bloqueia**: nenhuma

## Contexto

Segundo componente do fluxo de login.

## Escopo

### Inclui

- Contador de falhas persistido
- Aplicação do bloqueio temporário

### Não inclui

- Notificação por e-mail

## Implementação sugerida

Seguir o contrato do COMP-001-002.

## Critérios de pronto

- [ ] AC-001-002 coberto por teste de integração

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-002: falhar cinco vezes e ver o bloqueio aplicado.

## Riscos específicos

Corrida no contador (TRISK-001-001).

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
