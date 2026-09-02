# Pacote de correção — SPEC-001.md

modo: edits

Dezenove ajustes localizados — perto do teto de ~20 do modo localizado. Nenhum muda numeração de ID nem estrutura de seções. Cada
ajuste traz o ID do elemento, o heading da seção e o trecho literal a localizar.

1. **FR-001-002** · `## 5. Requisitos funcionais (EARS)` · trecho: `o sistema deve exibir a área de pendências` → substituir por `o sistema DEVE exibir a área de pendências` (RFC 2119 em caixa alta).
2. **AC-001-003** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `Given um Profissional com uma Pendência em 2026-05, When ele aciona a Linha, Then a lista` → substituir por `Dado um Profissional com uma Pendência em 2026-05, quando ele aciona a Linha, então a lista` (palavras-chave em português).
3. **Glossário / Pendência** · `## 3. Glossário (Ubiquitous Language)` · trecho: `- **Pendência** — Solicitação de Confirmação ainda não confirmada.` → substituir por `- **Pendência** — Solicitação de Confirmação ainda não confirmada (termo canônico; "aviso" não é sinônimo aceito).`
4. **FR-001-004** · `## 5. Requisitos funcionais (EARS)` · trecho: `Quando o usuário clicar em uma Linha` → substituir por `Quando o Profissional aciona uma Linha` (sujeito do glossário, forma EARS).
5. **NFR-001-001** · `## 6. Requisitos não-funcionais` · trecho: `DEVE responder rápido.` → substituir por `DEVE responder em até 500 ms no p95, medido no servidor.`
6. **A-001-002** · `## 8. Premissas e decisões prévias` · trecho: `não só a anterior. [evidência: crença]` → substituir por `não só a anterior. [evidência: entrevistas — decisão do Diretor]`.
7. **§4.2 Out-of-scope** · `### 4.2 Out-of-scope` · trecho: `- Tela de histórico de Solicitações e Confirmações.` → acrescentar logo abaixo a linha `- Contador de pendências no menu lateral (uma gramática só; outra demanda).`
8. **AC-001-005** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `então a área mostra mensagem de falha` → substituir por `então a área exibe o texto "Não foi possível verificar suas pendências"`.
9. **FR-001-001** · `## 5. Requisitos funcionais (EARS)` · trecho: `consultar as Pendências dele em uma única chamada.` → substituir por `consultar as Pendências dele em uma única chamada, sem carregar a lista de lançamentos.`
10. **FR-001-003** · `## 5. Requisitos funcionais (EARS)` · trecho: `omitir a área de pendências por inteiro.` → substituir por `omitir a área de pendências por inteiro, sem estado vazio no lugar.`
11. **FR-001-005** · `## 5. Requisitos funcionais (EARS)` · trecho: `manter o mês corrente como padrão.` → substituir por `exibir o mês corrente, como já faz hoje.`
12. **FR-001-006** · `## 5. Requisitos funcionais (EARS)` · trecho: `informar que não foi possível verificar as pendências, em vez de omitir a área.` → substituir por `exibir a mensagem de falha na própria área, em vez de omitir a área.`
13. **NFR-001-002** · `## 6. Requisitos não-funcionais` · trecho: `bloquear a renderização do restante da tela inicial.` → substituir por `bloquear a renderização da saudação nem dos menus da tela inicial.`
14. **AC-001-001** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `então vê duas Linhas ordenadas da mais antiga para a mais recente.` → substituir por `então vê duas Linhas, a mais antiga primeiro.`
15. **AC-001-002** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `então a área de pendências não é renderizada.` → substituir por `então a área de pendências não existe no DOM.`
16. **AC-001-004** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `então o mês exibido é o corrente.` → substituir por `então o mês exibido é o corrente e nenhuma Competência-alvo é aplicada.`
17. **AC-001-006** · `## 7. Critérios de aceitação (Given-When-Then)` · trecho: `então vê as Linhas sem o controle de ação.` → substituir por `então vê as Linhas sem o controle de ação e com o rótulo "somente leitura".`
18. **RISK-001-001** · `## 9. Riscos e questões abertas` · trecho: `o primeiro fechamento com a funcionalidade ainda não ocorreu.` → substituir por `o primeiro fechamento com a funcionalidade ainda não ocorreu; a métrica só se lê após dois fechamentos.`
19. **Glossário / Competência** · `## 3. Glossário (Ubiquitous Language)` · trecho: `- **Competência** — mês de referência dos lançamentos, no formato `AAAA-MM`.` → substituir por `- **Competência** — mês de referência dos lançamentos, no formato `AAAA-MM` (nunca "mês" solto no texto).`
