---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto à **idempotência** do
cancelamento.

Contexto mínimo: cancelar um pedido já cancelado deve ser um no-op — sem escrita e sem
exceção.

Critério (responda só sobre isto):

- **PASS** se a segunda chamada de `cancelar` num pedido já cancelado retorna sem chamar
  `atualizarStatus` e sem lançar exceção, e há teste que prova as duas coisas (nenhuma
  escrita na segunda chamada; nenhuma exceção).
- **FAIL** se a segunda chamada lança exceção (`TransicaoInvalida` ou outra), ou grava de
  novo (sobrescreve `cancelado_em`), ou se não há teste da segunda chamada.
