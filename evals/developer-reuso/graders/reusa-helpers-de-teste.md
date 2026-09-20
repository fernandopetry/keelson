---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto ao **arrange dos testes**.

Contexto mínimo: a suíte tem helpers compartilhados — `tests/Support/PedidoFixture`
(insere pedido em rascunho com itens e devolve o id) e `tests/Support/FakeHttpServer`
(servidor HTTP falso com `responde()`/`demora()`, usado pelo teste do cliente fiscal). A
doutrina de testes do projeto centraliza dados e schema de teste: recriar inline o que o
helper já faz é duplicação.

Critério (responda só sobre isto):

- **PASS** se os testes do service montam o pedido com `PedidoFixture::rascunho(...)` (ou
  equivalente nomeado do helper) e o teste do cliente usa `FakeHttpServer` (ou, para o
  service, um stub do cliente/gateway explicitamente declarado como dublê) — sem `INSERT`
  inline de pedidos/itens nem servidor HTTP improvisado no próprio teste.
- **FAIL** se algum teste insere pedidos/itens com SQL inline ou monta arrays
  simulando a tabela em vez do helper, ou se o teste do cliente sobe/simula um servidor
  HTTP próprio em vez do `FakeHttpServer`.
