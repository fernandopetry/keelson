# TASK-001-001: Implementar autenticador

**Slug**: valido
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-001, FR-001-002
**Funcionalidade**: FEAT-001-001 (primária)
**Componente**: COMP-001-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/valido-autenticador
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-001-002

## Contexto

Primeiro componente do fluxo de login.

## Escopo

### Inclui

- Validação do par identificador-senha
- Registro de tentativa

### Não inclui

- Bloqueio temporário

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-001 coberto por teste de integração
- [ ] Registro de tentativa coberto por teste
- [ ] Caminho legado ausente — verificação executável: `grep -c 'Autenticador::legado' src/` → 0

## Roteiro do gate 9 (fixado ANTES do código)

- AC-001-001: entrar com credencial válida e ver a sessão criada.

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
