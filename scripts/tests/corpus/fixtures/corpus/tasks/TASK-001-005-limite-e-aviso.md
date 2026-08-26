# TASK-001-005: Limite de exportação e aviso de conclusão

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-003, FR-001-004
**Funcionalidade**: transversal (FEAT-001-001, FEAT-001-002)
**Componente**: COMP-001-002, COMP-001-003
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/corpus-limite-e-aviso
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-001, TASK-001-002
- **Bloqueia**: TASK-001-007

## Contexto

Fatia vertical que fecha o ciclo: o gerador respeita o limite de cem mil pedidos
e, ao terminar, o avisador envia o aviso de conclusão com o endereço de retirada
assinado (DEC-001-002).

## Escopo

### Inclui

- Limite de cem mil pedidos no gerador, com orientação de divisão do período
- Envio do aviso de conclusão ao fim da geração

### Não inclui

- Reenvio do aviso (TASK-001-007)
- Expiração do endereço (TASK-001-003)

## Implementação sugerida

Gerador conta antes de consolidar; avisador escuta o término da geração.

## Critérios de pronto

- [ ] AC-001-006: limite excedido interrompe com orientação de divisão — verificação executável: `make test` → caso com cem mil e um pedidos aponta a orientação, `OK (4 tests)`
- [ ] Término da geração dispara o aviso de conclusão — verificação executável: `make test` → caso do aviso com endereço assinado presente, verde

## Riscos específicos

Aviso disparado duas vezes se o término da geração for reprocessado pela fila.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app local em endereço padrão do projeto, realm de desenvolvimento.
**Sujeito**: operador de desenvolvimento com credencial da ficha local.
**Pré-condição**: período com pedidos carregados pela carga de exemplo; restaurar
apagando a solicitação criada ao fim.

- AC-001-003: solicitar exportação de período pequeno, aguardar a conclusão e
  conferir o aviso recebido com o endereço de retirada abrindo o arquivo.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
