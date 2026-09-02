# SPEC-001: Aviso de pendência de confirmação na tela inicial

**Slug**: portal
**Status**: Draft
**Versão**: 0.1
**Brief**: BRIEF-001

## 1. Contexto e objetivo

### 1.1 Problema

O único canal de descoberta de uma Solicitação de Confirmação é o e-mail. Quem não o lê
nunca sabe que precisa confirmar; quem lê precisa navegar até a lista e voltar um mês.

### 1.2 Outcome esperado

Ao entrar na tela inicial, o Profissional vê cada competência com Solicitação aberta e
chega à lista já posicionada nela.

### 1.3 Métrica de sucesso

Mediana e p90 da latência entre `requested` e `confirmed`, comparando dois fechamentos.
**Fonte de medição**: a métrica lê o dado já gravado em `confirmation_event`, sem
instrumentação nova — leitura trimestral, nunca semanal.

## 2. Personas e jobs-to-be-done

- **Profissional** — quer saber, sem ler e-mail, que há valores a confirmar.
- **Administrador em Navegação Simulada** — quer ver o que o Profissional vê, sem agir.

## 3. Glossário (Ubiquitous Language)

- **Solicitação de Confirmação** — pedido do administrador para que o Profissional confirme os lançamentos de uma competência.
- **Competência** — mês de referência dos lançamentos, no formato `AAAA-MM`.
- **Pendência** — Solicitação de Confirmação ainda não confirmada.
- **Linha** — item da área de pendências que representa uma Competência aguardando.

## 4. Escopo

### 4.1 In-scope

- Área de pendências na tela inicial, com uma Linha por Competência aguardando.
- Deep link da Linha para a lista de lançamentos posicionada na Competência.

### 4.2 Out-of-scope

- E-mail de lembrete ou reenvio automático da Solicitação.
- Tela de histórico de Solicitações e Confirmações.

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Área de pendências na tela inicial

- **FR-001-001** — Quando o Profissional entra na tela inicial, o sistema DEVE consultar as Pendências dele em uma única chamada.
- **FR-001-002** — Enquanto houver ao menos uma Pendência, o sistema deve exibir a área de pendências com uma Linha por Competência, da mais antiga para a mais recente.
- **FR-001-003** — Quando não houver Pendência, o sistema DEVE omitir a área de pendências por inteiro.

### FEAT-001-002: Chegada na Competência-alvo

- **FR-001-004** — Quando o usuário clicar em uma Linha, o sistema DEVE abrir a lista de lançamentos posicionada na Competência daquela Linha.
- **FR-001-005** — Quando a lista de lançamentos é aberta sem Competência-alvo, o sistema DEVE manter o mês corrente como padrão.
- **FR-001-006** — Se a consulta de Pendências falhar, o sistema DEVE informar que não foi possível verificar as pendências, em vez de omitir a área.

## 6. Requisitos não-funcionais

- **NFR-001-001** — A consulta de Pendências DEVE responder rápido.
- **NFR-001-002** — A consulta de Pendências NÃO DEVE bloquear a renderização do restante da tela inicial.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** — Dado um Profissional com duas Competências aguardando, quando ele entra na tela inicial, então vê duas Linhas ordenadas da mais antiga para a mais recente.
- **AC-001-002** — Dado um Profissional sem Pendência, quando ele entra na tela inicial, então a área de pendências não é renderizada.
- **AC-001-003** — Given um Profissional com uma Pendência em 2026-05, When ele aciona a Linha, Then a lista de lançamentos abre posicionada em 2026-05.
- **AC-001-004** — Dado um Profissional que entra diretamente na lista de lançamentos, quando a tela abre, então o mês exibido é o corrente.
- **AC-001-005** — Dado que a consulta de Pendências falha, quando a tela inicial renderiza, então a área mostra mensagem de falha e o restante da tela permanece utilizável.
- **AC-001-006** — Dado um Administrador em Navegação Simulada, quando ele entra na tela inicial, então vê as Linhas sem o controle de ação.

## 8. Premissas e decisões prévias

- **A-001-001** — A tela inicial é a casa das pendências acionáveis de qualquer funcionalidade; a Confirmação é a primeira ocupante. [evidência: entrevistas — Diretor]
- **A-001-002** — O aviso cobre qualquer Competência com Solicitação aberta, não só a anterior. [evidência: crença]
- **A-001-003** — Sem Pendência, a área simplesmente não aparece; não há estado permanente de "tudo confirmado". [evidência: crença — assumida pelo Tech Lead]

## 9. Riscos e questões abertas

- **RISK-001-001** — A hipótese de que o e-mail não basta é crença, não medição; o primeiro fechamento com a funcionalidade ainda não ocorreu.
- **RISK-001-002** — Duas gramáticas de pendência convivem no produto (área na casa e contador no menu); o escopo escolhe uma, e a coexistência é registrada como dívida de produto, não como defeito.

## 10. Fora deste documento

- Desenho técnico da fonte de leitura (endpoint próprio ou campo em payload existente) — decisão de PLAN.
