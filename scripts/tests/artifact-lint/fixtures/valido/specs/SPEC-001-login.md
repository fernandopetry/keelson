# SPEC-001: Login de usuários

**Slug**: valido
**Status**: Review
**Versão**: 0.1
**Autor**: Fernando
**Data**: 2026-08-01

## 1. Contexto e objetivo

### 1.1 Problema

Usuários não conseguem acessar a área autenticada.

### 1.2 Outcome esperado

Acesso autenticado disponível para toda a base.

### 1.3 Métrica de sucesso

Reduzir chamados de acesso em 30% até 2026-12-01.

**Fonte de medição**: instrumentação — evento de login emitido pelo produto

## 2. Personas e jobs-to-be-done

- Operador: entrar na conta para consultar pedidos.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| **Credencial** | Par identificador-senha do operador | esta SPEC |
| **Bloqueio (acesso)** | Suspensão temporária de acesso | esta SPEC |
| **Operador, Sessão** *(reutilizados, sem redefinição)* | Ver glossário consolidado do INDEX.md do slug | INDEX |

## 4. Escopo

### 4.1 In-scope

- Autenticação por credencial própria
- Bloqueio temporário por tentativas seguidas

### 4.2 Out-of-scope

- Login social
- Autenticação em duas etapas

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Autenticação

> Operador entra na conta com credencial própria e sessão criada.

- **FR-001-001** [MUST] Quando o operador submete a credencial, o sistema DEVE validar o par identificador-senha.
- **FR-001-002** [SHOULD] O sistema deve registrar cada tentativa de acesso, e NÃO DEVE registrar a senha em claro.

### FEAT-001-002: Bloqueio de acesso

> Conta é suspensa temporariamente após tentativas seguidas.

- **FR-001-003** [MUST] Se a credencial falha cinco vezes seguidas, então o sistema deve aplicar o bloqueio temporário.
- **FR-001-004** [MAY] Enquanto o bloqueio vigora, o sistema deve exibir o tempo restante.

## 6. Requisitos não-funcionais

- **NFR-001-001** [MUST] O sistema deve responder ao envio de credencial em até 500 ms.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** (cobre FR-001-001)
  **Dado** um operador cadastrado,
  **Quando** submete a credencial correta,
  **Então** a sessão é criada.
- **AC-001-002** (cobre FR-001-003) Dado um operador com quatro falhas, quando a quinta falha ocorre, então o bloqueio é aplicado.

## 8. Premissas e decisões prévias

- [assumido] [evidência: entrevistas] Operadores usam identificador corporativo.

## 9. Riscos e questões abertas

- **RISK-001-001** Bloqueio em massa por tentativa automatizada.

## 10. Fora deste documento

- Política de senha corporativa.
