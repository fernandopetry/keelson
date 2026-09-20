# Memo de exploração — slug pedidos

## Reconhecimento técnico (code-scout)
- `src/Pedidos/ConfirmacaoService.php:8` — `confirmar()` é a única transição; síncrona,
  sem chamada externa. `PedidoRepository::atualizarStatus` grava status/confirmado_em;
  `itens(pedidoId)` devolve os itens.
- `src/Integracoes/HttpGateway.php:5` — cliente HTTP compartilhado: `post(url, body,
  timeoutMs)` com timeout e retry; `src/Fiscal/NotaClient.php:4` é o modelo de cliente
  dedicado sobre ele.
- `src/Shared/Percentual.php:3` — VO canônico de percentual (`Percentual::de`,
  `Percentual::maior`, `valor()`), com validação de faixa; cupons e comissões o usam.
- `src/Pedidos/HistoricoRepository.php:3` — `registrar(pedidoId, evento, detalhe)` grava em
  `historico_pedido`.
- Testes: `tests/Support/PedidoFixture.php` (dados de pedido), `tests/Support/FakeHttpServer.php`
  (servidor HTTP falso, usado por `NotaClientTest`); PHPUnit 10.

## Decisões vigentes
- DEC-001-001: toda chamada ao parceiro passa por um cliente dedicado (`ParceiroFreteClient`) sobre o `HttpGateway`; nenhuma outra classe monta requisição HTTP ao parceiro.
- DEC-001-002: envio síncrono dentro da confirmação, timeout 5 s; falha não desfaz a confirmação.
