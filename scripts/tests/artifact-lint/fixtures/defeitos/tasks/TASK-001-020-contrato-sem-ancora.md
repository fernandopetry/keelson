# TASK-001-020: Tela de configuração consome a rota de salvar

**Slug**: defeitos
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-077
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/defeitos-contrato-sem-ancora
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Critério de tela fixa status HTTP e envelope `success:` lidos do PLAN, sem âncora
`arquivo:linha` da rota real (4.467) — a tela nasce contra a crença, não contra o servidor.

## Escopo

### Inclui

- Tela de configuração que chama a rota de salvar

### Não inclui

- A rota em si (já existe)

## Implementação sugerida

Seguir o contrato do COMP-001-001.

## Critérios de pronto

- [ ] AC-001-077 coberto — campo inválido: a tela mostra o erro quando a rota devolve status 422 com `success: false`
- [ ] AC-001-077 coberto — campo válido (controle positivo, não acusa): a rota devolve `HTTP 201` conforme `app/Http/Actions/SalvarConfig.php:42`, e a tela fecha o modal

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
