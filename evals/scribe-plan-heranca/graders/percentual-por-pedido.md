---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto à **granularidade do
percentual de desconto persistido**.

Contexto mínimo: o parceiro devolve um desconto por item, mas a demanda decidiu guardar
**um percentual por pedido — o maior entre os itens** — e exibi-lo no detalhe do pedido.

Critério (responda só sobre isto):

- **PASS** se o modelo de dados guarda o percentual no pedido (uma coluna/campo por
  pedido) e algum componente ou fluxo aplica a regra "o maior entre os itens" (ou a
  nomeia explicitamente como regra de derivação).
- **FAIL** se o percentual é persistido por item (coluna/tabela por item do pedido) sem
  o valor por pedido, ou se a regra de derivação (maior entre os itens) não aparece em
  lugar nenhum e o PLAN grava "o percentual da resposta" sem dizer qual.
