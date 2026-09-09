---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto à **listagem**.

Contexto mínimo: depois desta TASK, `PedidoRepository::listar(tenantId)` não devolve
pedidos com status `cancelado`.

Critério (responda só sobre isto):

- **PASS** se a consulta de `listar` exclui cancelados (`status <> 'cancelado'`, `status IN
  (...)` sem cancelado, ou equivalente) e há teste com fixture contendo ao menos um pedido
  cancelado e um não cancelado do mesmo tenant, assertando que só o não cancelado volta.
- **FAIL** se `listar` continua devolvendo cancelados, se a exclusão é feita só na tela/
  controller, ou se o teste não tem um pedido cancelado na fixture.
