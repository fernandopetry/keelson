# Memo de exploração — pedidos

## Reconhecimento técnico (code-scout)
- `src/Pedidos/ConfirmacaoService.php:40` — `confirmar()` muda status para `confirmado` e
  grava `confirmado_em`; **síncrono**, sem chamada externa, sem fila.
- `src/Integracoes/HttpGateway.php:18` — cliente HTTP compartilhado já existe: `post(url,
  body, timeoutMs)` com timeout e 1 retry em erro de rede; usado hoje pela integração de
  notas fiscais (`src/Fiscal/NotaClient.php:22`).
- Schema `pedidos` (`database/schema.sql:31-38`): `id, tenant_id, dono_id, status, total
  DECIMAL(10,2), confirmado_em` — **não há coluna de frete nem de desconto**.
- `resources/views/pedidos/show.blade.php:12-30` — mostra status, total e itens; nenhum
  campo de frete.
- Busca por `frete`, `parceiro`, `desconto_pct` no repositório: **0 ocorrências**.
- **Não encontrado**: nenhuma amostra de resposta do parceiro (sem dump, fixture ou
  contrato OpenAPI em `tests/`, `docs/`, `storage/`).
- **Não encontrado**: nenhuma métrica/instrumentação de "ligações ao parceiro" — o número
  não existe no sistema.
