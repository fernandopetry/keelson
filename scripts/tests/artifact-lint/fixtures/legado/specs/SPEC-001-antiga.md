# SPEC-001: Capacidade antiga

**Slug**: legado
**Status**: Done
**Versão**: 1.0
**Autor**: Fernando
**Data**: 2025-01-10

## 1. Contexto e objetivo

### 1.1 Problema

Fluxo manual.

### 1.2 Outcome esperado

Fluxo automatizado.

### 1.3 Métrica de sucesso

Reduzir o retrabalho em 10% até 2025-06-01.

## 2. Personas e jobs-to-be-done

- Operador: acompanhar o fluxo.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Fluxo | Sequência automatizada | esta SPEC |

## 4. Escopo

### 4.1 In-scope

- Automação do fluxo

### 4.2 Out-of-scope

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Fluxo automatizado

> Fluxo executa sem intervenção.

- **FR-001-001** [MUST] O sistema deve executar o fluxo sem intervenção.

## 6. Requisitos não-funcionais

- **NFR-001-001** [MUST] O fluxo deve terminar em até 10 minutos.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** (cobre FR-001-001) Dado um fluxo agendado, quando o horário chega, então a execução acontece sem intervenção.

## 8. Premissas e decisões prévias

- [confirmado] Agenda única por dia.

## 9. Riscos e questões abertas

- **RISK-001-001** Sobreposição de execuções.

## 10. Fora deste documento

- Operação do agendador.
