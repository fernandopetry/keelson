# TASK-001-018: Escrita no repositório de registro

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-033
**Componente**: COMP-001-004
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-repo-escrita
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

A escrita idempotente entra no repositório de registro.

## Escopo

### Inclui

- Acrescentar o método de escrita idempotente em src/Repositorio/RegistroRepository.php — ver SPEC-001-login-defeituosa.md
- Migração da chave única e teste de RegistroRepository.php (componente em Vue.js, arquivos *.vue)

### Não inclui

- Rotas do fluxo A

## Implementação sugerida

Seguir o contrato do COMP-001-004.

## Critérios de pronto

- [ ] AC-001-023 coberto por teste de integração
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-023: escrever duas vezes e ver um registro só.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
