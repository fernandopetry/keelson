# TASK-001-015: Comando amplo sem isolar o alvo

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-015
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-alvo-nao-isolado
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Critério de não-regressão cita o comando amplo da ficha e nomeia arquivos de
teste como alvo, sem isolar o alvo (4.368) — o agregado verde não prova que eles rodaram.

## Escopo

### Inclui

- Repositório de alocações com escopo por tenant

### Não inclui

- Telas

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-011 coberto — não-regressão dos consumidores: `make test` → `OK (5088 tests)`;
      alvos: tests/Unit/EnviaEmailTest.php e tests/Integration/NotificaAlocacaoTest.php
- [ ] Alvo isolado (controle positivo, não acusa): `vendor/bin/phpunit --filter EnviaEmailTest` → `OK (3 tests)` em tests/Unit/EnviaEmailTest.php

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
