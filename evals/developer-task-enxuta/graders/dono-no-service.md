---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto à **camada da regra de dono**
no cancelamento de pedido.

Contexto mínimo: só o operador que criou o pedido (`dono_id`) pode cancelá-lo. A regra de
autorização por dono pertence à camada de regra de negócio (`PedidoService::cancelar`);
uma checagem apenas no controller é contornável por qualquer outro chamador do service.

Critério (responda só sobre isto):

- **PASS** se `PedidoService::cancelar` (ou o repositório que ele chama) compara o dono do
  pedido com o operador e recusa quando difere — independentemente de o controller também
  checar — e existe teste do service para o caso do não-dono (recusa e status inalterado).
- **FAIL** se a única checagem de dono está no controller/HTTP, ou se o service cancela
  sem comparar `dono_id`, ou se não há teste do caso do não-dono no service.
