# PLAN-001: Login de usuários

**Slug**: valido
**Status**: Review
**Versão**: 0.1
**Autor**: Fernando
**Data**: 2026-08-02

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

**NFRs cobertos**:
- NFR-001-001

**Cobertura agregada do slug**: 4/4 FRs da SPEC-001 cobertos por este PLAN.

## 1. Visão técnica

Serviço de autenticação em camadas.

## 2. Stack e dependências

Sem dependência nova.

## 3. Componentes

### COMP-001-001: Autenticador

**Responsabilidade**: validar credencial e criar sessão
**Realiza**: FR-001-001, FR-001-002
**Interface pública**: autenticar(identificador, senha)
**Dependências**: nenhuma

### COMP-001-002: Bloqueador

**Responsabilidade**: aplicar e consultar bloqueio temporário
**Realiza**: FR-001-003, FR-001-004
**Interface pública**: registrarFalha(identificador)
**Dependências**: COMP-001-001

## 4. Fluxos principais

Envio de credencial, validação, sessão ou bloqueio.

## 5. Modelo de dados

Tabela de tentativas com contador por identificador.

## 6. Decisões arquiteturais

### DEC-001-001: Contador de falhas persistido

**Contexto**: o bloqueio precisa sobreviver a reinício do processo.
**Decisão**: persistir o contador de falhas por identificador.
**Alternativas consideradas**:
- Contador em memória do processo — perde o estado no reinício e libera o ataque.
- Contador no armazenamento existente — custo de leitura extra por tentativa.
**Consequências**: uma leitura adicional por tentativa de login.
**Reabrir se**: o volume de tentativas passar de mil por minuto.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

## 7. Mapeamento FR -> componente

| FR | Componente | ACs |
|----|------------|-----|
| FR-001-001 | COMP-001-001 | AC-001-001 |
| FR-001-002 | COMP-001-001 | AC-001-001 |
| FR-001-003 | COMP-001-002 | AC-001-002 |
| FR-001-004 | COMP-001-002 | AC-001-002 |

## 8. Riscos técnicos

### TRISK-001-001: Corrida no contador

Duas tentativas simultâneas podem contar como uma.

## 9. Definition of Done deste PLAN

- [ ] Cobertura de testes dos fluxos de autenticação e bloqueio
- [ ] Aderência à ficha/perfil de linguagem verificada

## 10. Não coberto por este PLAN

Nada — cobertura total da SPEC-001.
