---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto a **como o reenvio chama o
parceiro**.

Contexto mínimo: a decisão vigente é que só o `ParceiroFreteClient` fala com o parceiro; o
service nunca usa `HttpGateway` nem HTTP direto.

Critério: **PASS** se o reenvio chega ao parceiro por `ParceiroFreteClient::enviar` (direto
ou reusando o método privado existente que o chama). **FAIL** se `ConfirmacaoService` (ou o
controller) usa `HttpGateway`, `curl`, ou monta o payload do parceiro por conta própria.
