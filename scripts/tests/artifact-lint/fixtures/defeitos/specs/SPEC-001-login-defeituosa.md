# SPEC-001: Login com defeitos

**Slug**: defeitos
**Status**: Draft
**Autor**: <preencher>
**Data**: 01/08/2026

## 1. Contexto e objetivo

### 1.1 Problema

Acesso indisponível.

### 1.3 Métrica de sucesso

Aumentar a conversão sem meta definida.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Widget | Termo que ninguém usa | aqui |
| Credencial | Par identificador-senha | aqui |

## 4. Escopo

### 4.2 Out-of-scope

- Login social

## 5. Requisitos funcionais (EARS)

- **FR-001-009** [MUST] O sistema deve exibir o aviso de manutenção programada para todos os usuários autenticados e não autenticados em todas as páginas públicas e privadas do produto durante toda a janela de manutenção agendada pela operação.

### FEAT-001-001: Autenticação

> Fluxo de entrada com credencial.

- **FR-001-001** [MUST] Quando o operador submete a credencial, o sistema deve validar o par identificador-senha.
- **FR-001-002** [must] O sistema deve registrar toda tentativa de acesso.
- **FR-001-003** [MUST] Sistema deve bloquear a conta na quinta falha.
- **FR-002-001** [MUST] O sistema valida o formato do identificador.

### FEAT-001-002: Recuperação de conta

## 6. Requisitos não-funcionais

- **NFR-001-001** [MUST] O sistema deve ser rápido e seguro.
- **NFR-001-002** [MUST] O sistema deve gravar os registros no PostgreSQL.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-1** O usuário consegue entrar sem atrito.

## 8. Premissas e decisões prévias

- Usuários possuem identificador corporativo.
- [assumido] O bloqueio dura quinze minutos.

## 9. Riscos e questões abertas
