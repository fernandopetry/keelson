# PLAN-001: Exportação de pedidos

**Slug**: corpus
**Status**: Approved
**Versão**: 0.2
**Autor**: Fernando
**Data**: 2026-08-12

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend ativo
**Stack vigente herdado**: linguagem do projeto
**Padrão arquitetural seguido**: camadas do projeto
**Decisões irreversíveis do slug tocadas**: nenhuma
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: cobertura total restante

**FRs cobertos**:
- FR-001-001
- FR-001-002
- FR-001-003
- FR-001-004
- FR-001-005
- FR-001-006

**NFRs cobertos**:
- NFR-001-001
- NFR-001-002

**Cobertura agregada do slug**: 6/6 FRs da SPEC-001 cobertos por este PLAN.

## 1. Visão técnica

Geração assíncrona em fila: a solicitação vira registro, um processador gera o
arquivo e o avisador fecha o ciclo com o solicitante.

## 2. Stack e dependências

Sem dependência nova — fila e canal de aviso já existentes no projeto.

## 3. Componentes

### COMP-001-001: Registrador de solicitações

**Responsabilidade**: validar, registrar e deduplicar solicitações de exportação
**Realiza**: FR-001-001, FR-001-002
**Interface pública**: solicitar(operador, periodo, filtros)
**Dependências**: nenhuma

### COMP-001-002: Gerador de exportação

**Responsabilidade**: consolidar os pedidos do período no arquivo de exportação, respeitando o limite
**Realiza**: FR-001-003
**Interface pública**: gerar(solicitacaoId)
**Dependências**: COMP-001-001

### COMP-001-003: Avisador de conclusão

**Responsabilidade**: enviar, reenviar e expirar o aviso de conclusão com o endereço de retirada
**Realiza**: FR-001-004, FR-001-005, FR-001-006
**Interface pública**: avisar(solicitacaoId), reenviar(solicitacaoId), expirar(solicitacaoId)
**Dependências**: COMP-001-002

## 4. Fluxos principais

Solicitação → registro e deduplicação → geração em fila → aviso de conclusão →
retirada ou expiração.

## 5. Modelo de dados

Tabela de solicitações com operador, período, situação e carimbo de data; tabela
de avisos com destino, situação de envio e validade do endereço de retirada.

## 6. Decisões arquiteturais

### DEC-001-001: Geração assíncrona em fila única

**Contexto**: exportações grandes travariam a requisição se geradas em linha.
**Decisão**: toda geração roda na fila existente do projeto, uma solicitação por vez por operador.
**Alternativas consideradas**:
- Geração em linha na própria requisição — trava a tela e estoura o tempo limite nos períodos largos.
- Fila dedicada nova — custo de operação de uma fila a mais sem volume que a justifique.
**Consequências**: a tela mostra situação "em andamento" e o ciclo fecha pelo aviso de conclusão.
**Reabrir se**: o tempo de espera na fila compartilhada passar de 10 minutos.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-001-002: Endereço de retirada assinado com validade

**Contexto**: o arquivo consolidado carrega dados de pedidos e não pode ficar aberto por tempo indefinido.
**Decisão**: o aviso de conclusão carrega endereço assinado com validade de sete dias; expirado, só nova solicitação.
**Alternativas consideradas**:
- Anexar o arquivo no próprio aviso — estoura o limite do canal corporativo nos períodos largos.
- Endereço permanente atrás de autenticação — mantém arquivo velho acessível para sempre e amplia a superfície de dado exposto.
**Consequências**: reenvio reaproveita o mesmo endereço enquanto válido; expirado, o fluxo recomeça.
**Reabrir se**: a área de conformidade fixar validade diferente de sete dias.
**Irreversível**: sim
**Aderência à ficha/perfil**: herdada

## 7. Mapeamento FR -> componente

| FR | Componente | ACs |
|----|------------|-----|
| FR-001-001 | COMP-001-001 | AC-001-001 |
| FR-001-002 | COMP-001-001 | AC-001-002 |
| FR-001-003 | COMP-001-002 | — |
| FR-001-004 | COMP-001-003 | AC-001-003 |
| FR-001-005 | COMP-001-003 | AC-001-005 |
| FR-001-006 | COMP-001-003 | AC-001-004 |

## 8. Riscos técnicos

### TRISK-001-001: Consolidação além do limite de memória

Período largo com pedidos volumosos pode estourar a memória do processador da
fila; o limite do FR-001-003 é a contenção, e a geração em blocos é o plano B.

## 9. Definition of Done deste PLAN

- [ ] Cobertura de testes dos fluxos de solicitação, geração e aviso
- [ ] Aderência à ficha/perfil de linguagem verificada
- [ ] Comportamento verificado de ponta a ponta (gate 9) por funcionalidade

## 10. Não coberto por este PLAN

Nada — cobertura total da SPEC-001.
