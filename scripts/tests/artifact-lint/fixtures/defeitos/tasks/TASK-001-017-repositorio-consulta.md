# TASK-001-017: Consulta do repositório de registro

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-032
**Componente**: COMP-001-004
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-repo-consulta
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

A consulta por período entra no repositório de registro.

## Escopo

### Inclui

- Acrescentar o método de consulta por período em RegistroRepository.php (contrato v1.2, e.g. filtro por data) — ver SPEC-001-login-defeituosa.md
- DTO de resposta da consulta (componente em Vue.js, arquivos *.vue)

### Não inclui

- Rotas do fluxo A

## Implementação sugerida

Seguir o contrato do COMP-001-004.

## Critérios de pronto

- [ ] AC-001-022 coberto por teste de integração
- [ ] Suíte unitária verde — verificação executável: `vendor/bin/phpunit` → `OK`

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-022: consultar por período e ver a lista esperada.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
