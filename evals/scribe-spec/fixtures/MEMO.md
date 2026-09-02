# Memo de exploração — pedidos

- `src/Pedidos/ConfirmacaoService.php:40` — `confirmar()` muda status e grava `confirmado_em`; sem chamada externa.
- `resources/views/pedidos/show.blade.php:12-30` — mostra status, total, itens; nenhum campo de frete.
- Busca por `frete`, `parceiro`, `desconto_pct` no repositório: **0 ocorrências**. Nenhuma amostra de resposta do parceiro em `tests/`, `docs/` ou `storage/`.
