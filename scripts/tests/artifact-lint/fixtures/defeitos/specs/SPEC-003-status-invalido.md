# SPEC-003: Status fora do enum

**Slug**: defeitos
**Status**: Obsoleta
**Versão**: 0.1
**Autor**: Fernando
**Data**: 2026-08-04

## 1. Contexto e objetivo

### 1.1 Problema

Relatório manual.

### 1.2 Outcome esperado

Relatório automático.

### 1.3 Métrica de sucesso

Reduzir o tempo de geração em 50% até 2026-11-01.

**Fonte de medição**: instrumentação — evento de geração

## 2. Personas e jobs-to-be-done

- Gestor: consultar o relatório do dia.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Relatório | Consolidado diário de operações | esta SPEC |

## 4. Escopo

### 4.1 In-scope

- Geração diária do relatório
- Consulta ao relatório do dia

### 4.2 Out-of-scope

- Exportação para planilha
- Relatórios sob demanda

## 5. Requisitos funcionais (EARS)

- **FR-003-001** [MUST] Quando o dia encerra, o sistema deve gerar o relatório consolidado.
- **FR-003-002** [SHOULD] O sistema deve manter o relatório disponível por trinta dias.

## 6. Requisitos não-funcionais

- **NFR-003-001** [MUST] O relatório deve ficar disponível em até 5 minutos após o fechamento.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-003-001** (cobre FR-003-001) Dado um dia encerrado, quando a geração roda, então o relatório fica disponível.

## 8. Premissas e decisões prévias

- [confirmado] Fechamento único por dia.

## 9. Riscos e questões abertas

- **RISK-003-001** Fechamento atrasado empurra a geração.

## 10. Fora deste documento

- Distribuição do relatório.
