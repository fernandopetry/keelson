# SPEC-001: Aviso de pendência de confirmação na tela inicial

**Slug**: portal · **Status**: Draft · **Brief**: BRIEF-001

## 1. Contexto e objetivo
### 1.1 Problema
O único canal de descoberta da Solicitação de Confirmação é o e-mail.
### 1.2 Outcome esperado
O Profissional vê na tela inicial cada Competência com Solicitação aberta e chega à lista posicionada nela.
### 1.3 Métrica de sucesso
Mediana e p90 da latência entre `requested` e `confirmed`. **Fonte de medição**: `confirmation_event`, sem instrumentação nova.

## 2. Personas e jobs-to-be-done
- **Profissional** — saber, sem e-mail, que há valores a confirmar.

## 3. Glossário (Ubiquitous Language)
- **Solicitação de Confirmação** — pedido do administrador para confirmar os lançamentos de uma Competência.
- **Competência** — mês de referência, `AAAA-MM`.
- **Linha** — item da área de pendências que representa uma Competência aguardando.

## 4. Escopo
### 4.1 In-scope
- Área de pendências na tela inicial; deep link da Linha para a lista posicionada.
### 4.2 Out-of-scope
- Contador de pendências no menu lateral.
- E-mail de lembrete ou reenvio automático.

## 5. Requisitos funcionais (EARS)
### FEAT-001-001: Área de pendências
- **FR-001-001** — Quando o Profissional entra na tela inicial, o sistema DEVE consultar as Solicitações abertas dele em uma única chamada.
- **FR-001-002** — Enquanto houver ao menos uma Solicitação aberta, o sistema DEVE exibir uma Linha por Competência, **da mais recente para a mais antiga**.
- **FR-001-003** — Quando não houver Solicitação aberta, o sistema DEVE omitir a área por inteiro.
### FEAT-001-002: Chegada na Competência-alvo
- **FR-001-004** — Quando o Profissional aciona o controle "Conferir" de uma Linha, o sistema DEVE abrir a lista de lançamentos posicionada naquela Competência.
- **FR-001-005** — Quando a lista é aberta sem Competência-alvo, o sistema DEVE manter o mês corrente.
- **FR-001-006** — Se a consulta falhar, o sistema DEVE informar que não foi possível verificar as pendências.

## 6. Requisitos não-funcionais
- **NFR-001-001** — A consulta DEVE responder em até 500 ms no p95.
- **NFR-001-002** — A consulta NÃO DEVE bloquear a renderização do restante da tela.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-001-001** — Dado um Profissional com duas Competências aguardando, quando entra na tela inicial, então vê duas Linhas ordenadas da mais recente para a mais antiga.
- **AC-001-002** — Dado um Profissional sem Solicitação aberta, quando entra na tela inicial, então a área não é renderizada.
- **AC-001-003** — Dado um Profissional com Solicitação em 2026-05, quando aciona "Conferir", então a lista abre em 2026-05.
- **AC-001-004** — Dado um Profissional que entra direto na lista, quando a tela abre, então o mês exibido é o corrente.
- **AC-001-005** — Dado que a consulta falha, quando a tela renderiza, então a área exibe o texto "Não foi possível verificar suas pendências".

## 8. Premissas e decisões prévias
- **A-001-001** — A área é de pendências de qualquer funcionalidade. [evidência: entrevistas — Diretor]
- **A-001-002** — Sem pendência, a área não aparece. [evidência: entrevistas — Diretor]
- **A-001-003** — A métrica é lida do dado já gravado; "o e-mail não basta" é crença. [evidência: crença — decisão do Diretor de seguir]

## 9. Riscos e questões abertas
- **RISK-001-001** — Primeiro fechamento com a funcionalidade ainda não ocorreu; a aposta de valor é crença.

## 10. Fora deste documento
- Desenho da fonte de leitura (endpoint próprio × payload existente) — PLAN.
