# Memo de exploração — devolucoes

- `src/Pedidos/Pedido.php:18` — enum de status inclui `entregue`; coluna `entregue_em` na tabela `pedidos`.
- `resources/views/painel/pedidos/show.blade.php` e `resources/views/conta/pedidos/show.blade.php` — detalhe do pedido para operador e para cliente; nenhum bloco de devolução.
- Busca por `devolucao`, `reembolso`, `refund` no repositório: **0 ocorrências** fora do adaptador do gateway (`src/Pagamentos/Gateway.php:77`, método `refund(total)` existente, não chamado por fluxo nenhum).
