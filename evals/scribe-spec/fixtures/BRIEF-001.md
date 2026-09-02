# BRIEF-001: Integração com o parceiro de frete na confirmação do pedido

**Status**: Emitido · **Slug**: pedidos

## Pedido como dito
"Quando o operador confirmar um pedido, o sistema tem de enviar o pedido ao parceiro de
frete e guardar o percentual de desconto de frete que o parceiro aplicou. O gerente da
parceria disse que a resposta deles vem como `{status, prazo_dias, itens[]}` e que o
percentual vem em `itens[].desconto_pct`."

## Interpretação do PO
- **Contexto**: hoje o frete é combinado por telefone; o parceiro tem API.
- **Pedido**: enviar o pedido confirmado ao parceiro e persistir o percentual de desconto de frete devolvido.
- **Premissas decididas**: a confirmação continua síncrona; falha do parceiro não bloqueia a confirmação (fica pendente de reenvio).
- **Fora de escopo**: cotação prévia; múltiplos parceiros.

## Fatos do código
- Não existe integração com o parceiro; **nenhuma resposta real do parceiro foi capturada**
  (sem dump, sem fixture, sem contrato OpenAPI no repositório).
- A tabela `pedidos` tem colunas `status`, `total`, `confirmado_em`; não há coluna de frete.
- A tela de detalhe do pedido (`pedidos/show`) mostra status, total e itens.

## Perguntas
### Respondidas
- Q1 O percentual é por pedido ou por item? → **por pedido** (o Diretor decidiu: o maior entre os itens, se vierem vários).
### Pendentes a produto
- nenhuma
