# PLAN-001: Login com defeitos

**Slug**: defeitos
**Status**: Rascunho
**Versão**: 0.1
**Data**: 2026-08-02

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend ativo
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**:
**Slice declarado**: parcial

**FRs cobertos**:

## 1. Visão técnica

Serviço de autenticação.

## 2. Stack e dependências

Sem dependência nova.

## 3. Componentes

### COMP-002-001: Componente com número errado

**Responsabilidade**: validar credencial
**Realiza**: FR-001-001
**Interface pública**: autenticar(identificador, senha)
**Dependências**: nenhuma

## 4. Fluxos principais

Envio e validação de credencial.

## 6. Decisões arquiteturais

### DEC-001-001: Escolha do armazenamento do contador

**Contexto**: o bloqueio precisa sobreviver a reinício.
**Decisão**: persistir o contador.
**Alternativas consideradas**:
**Irreversível**: talvez

### DEC-001-2: Estratégia de fila

**Contexto**: processamento assíncrono das tentativas.
**Decisão**: usar a fila existente.
**Alternativas consideradas**:
- Processar em linha na própria requisição.
**Consequências**: acoplamento com a fila existente.
**Reabrir se**: nunca
**Irreversível**: SIM

## 7. Mapeamento FR -> componente

| FR | Componente | ACs |
|----|------------|-----|

## 8. Riscos técnicos

### TRISK-001-001: Corrida no contador

Duas tentativas simultâneas podem contar como uma.

## 9. Definition of Done deste PLAN

- Publicar o serviço com <preencher>

## 10. Não coberto por este PLAN

Recuperação de conta.
