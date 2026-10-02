# TASK-001-003: Implementar repositório escopado

**Slug**: valido
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-005
**Funcionalidade**: FEAT-001-003 (primária)
**Componente**: COMP-001-003
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/valido-repositorio-escopado
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Repositório com predicado de escopo por tenant. O par contável vem na forma
rótulo seguido de número — a forma que o lint reconhece ao lado de "N métodos".

## Escopo

### Inclui

- Repositório de alocações com escopo por tenant em AlocacaoRepository.php e src/Alocacao/Servico.php

### Não inclui

- Telas

## Implementação sugerida

Seguir o contrato do COMP-001-003.

## Critérios de pronto

- [ ] AC-001-005 coberto — mutação do predicado de escopo de tenant com fechamento contável; métodos que tocam a tabela: 4; provas: 4 (fixture de dois pais, predicado neutralizado reprova) — verificação executável: `vendor/bin/phpunit --filter AlocacaoRepositoryTest` → `OK (8 tests)`

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
