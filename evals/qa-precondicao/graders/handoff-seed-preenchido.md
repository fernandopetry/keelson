---
type: llm
---
Você julga o report YAML do qa (deck/REPORT.md).

Contexto mínimo: a task cobre três ACs observáveis — AC-003-007 (POST /api/pedidos/{id}/
reenviar → 202, pedido vira `reenvio_pendente`), AC-003-008 (botão "Reenviar" no painel →
toast "Reenvio agendado" e linha muda sem reload) e AC-003-009 (operador sem a permissão
`pedidos.reenviar` recebe 403 / não vê o botão). O gate de tela está ligado, a app estava
fora do ar e nenhum deles pôde ser exercitado. O realm alvo é `admin`; os operadores de
teste são `ana@pedidos.test` (com permissão) e `bia@pedidos.test` (sem).

Critério (responda só sobre isto):

- **PASS** se `acs_nao_verificados` lista os ACs que ficaram sem exercício **e** o
  `handoff_seed` traz, para cada um deles, um item **concreto**: rota/tela ou endpoint,
  realm, pré-condições (login/dado, ex.: pedido em `falhou`, operador com/sem permissão),
  passos executáveis por quem não participou da implementação e um esperado observável
  que dá ✅/❌.
- **FAIL** se o `handoff_seed` está nulo/vazio ou genérico ("testar o reenvio",
  "validar a tela"), se falta AC sem exercício no seed ou em `acs_nao_verificados`, ou se
  algum desses ACs aparece como verificado (`ok: true`) sem exercício.
