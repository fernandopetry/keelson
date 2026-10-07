# TASK-001-002: Corrigir validação do login

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-001
**Componente**: COMP-001-001
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: bugfix
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: fix/defeitos-login
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Validação aceita credencial vazia.

## Escopo

### Inclui

- Rejeição de credencial vazia

### Não inclui

- Novas regras de senha

## Implementação sugerida

Cobrir o caso vazio antes da validação.

## Critérios de pronto

- [ ] AC-001-001 verificado com credencial vazia
- [ ] Sem parâmetro de confirmação — verificação executável: `grep -icE "confirm" src/Login.php` → 0
- [ ] Nome antigo ausente — verificação executável: `grep -rl moverRegistro backend` → vazio (e `git grep -rn moverRegistro backend` já é a forma rastreada; `grep -rn Legado src/` escolhe a subárvore)
- [ ] Legado intocado — verificação executável: `git diff --name-only main...HEAD -- src/Legacy/` → vazio
- [ ] Login tocado — verificação executável: `git diff --name-only main...HEAD -- src/` → não vazio, inclui `src/Login.php`
- [ ] Legado intocado nesta TASK — verificação executável: `git diff 3f2a9c1..HEAD -- src/Legacy/` → vazio
- [ ] Guard chamado — verificação executável: `grep -cE "^\s*return $this->guard\(\)" src/Login.php` → 1

## Riscos específicos

Nenhum.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
