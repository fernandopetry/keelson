# TASK-001-003: Corrigir expiração do endereço de retirada

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-006
**Funcionalidade**: FEAT-001-002 (primária)
**Componente**: COMP-001-003
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: bugfix
**AC violado**: AC-001-004
**Status**: In Progress

## Convenções (do projeto)

**Branch sugerida**: fix/corpus-expiracao-retirada
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-002
- **Bloqueia**: nenhuma

## Contexto

Comportamento atual: endereço de retirada com mais de sete dias segue abrindo o
arquivo. Esperado (AC-001-004): acesso negado com orientação de nova solicitação.
A validade era conferida na emissão, nunca na retirada.

## Escopo

### Inclui

- Conferência de validade no ato da retirada, no avisador de conclusão

### Não inclui

- Mudança da validade de sete dias (DEC-001-002, irreversível)

## Implementação sugerida

Conferir a validade assinada no manipulador da retirada, antes de servir o arquivo.

## Critérios de pronto

- [ ] Repro vermelho capturado antes do fix — verificação executável: `make test` → caso da retirada aos oito dias FALHOU com "arquivo servido após validade" (evidência do vermelho); após o fix, o mesmo caso verde e vira regressão do AC-001-004
- [ ] Retirada dentro da validade segue funcionando — verificação executável: `make test` → verde

## Riscos específicos

Arquivos já expirados com retirada em curso no momento da publicação.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
