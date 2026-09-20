# Memo de exploração — pedidos

## Reconhecimento técnico (code-scout)
- `src/Pedidos/ConfirmacaoService.php:40` — `confirmar(int $id, Operador $op)`: busca por
  id + tenant, checa `status === 'rascunho'`, grava `confirmado` e `confirmado_em` via
  `PedidoRepository::atualizarStatus`. Síncrono, sem chamada externa.
- `src/Integracoes/HttpGateway.php:18` — `post(string $url, array $body, int $timeoutMs):
  GatewayResponse` (status, json(), erro()); timeout e 1 retry em erro de rede; usado por
  `src/Fiscal/NotaClient.php:22`.
- `src/Anexos/Anexo.php:9` — entidade `Anexo` exige `arquivo_id` no construtor
  (`new Anexo(int $arquivoId, string $tipo, int $pedidoId)`); o `arquivo_id` vem de
  `src/Arquivos/ArmazenamentoService::guardar(string $conteudo, string $mime): int`
  (`src/Arquivos/ArmazenamentoService.php:14`). **Não existe** rota nem serviço que
  receba um documento vindo de integração externa — o único chamador de `guardar()` é o
  upload manual da tela de anexos (`src/Http/AnexoController.php:31`).
- Schema (`database/schema.sql`): `pedidos(id, tenant_id, dono_id, status VARCHAR(20),
  total DECIMAL(10,2), confirmado_em DATETIME)` (l.31-38); `cupons(id, tenant_id, codigo,
  percentual NUMERIC(5,2) NOT NULL)` (l.52-56) — percentuais existentes na base usam
  **`NUMERIC(5,2)`**; `historico_pedido(id, pedido_id, evento VARCHAR(40), detalhe TEXT,
  criado_em)` (l.60-65).
- Tela `resources/views/pedidos/show.blade.php:12-30` — status, total, itens.
- Busca por `frete`, `parceiro`, `desconto_pct`: 0 ocorrências. Nenhuma amostra de resposta
  do parceiro no repositório.

## Ficha (keelson.config.json, recorte)
- stack: PHP 8.2 · framework Laravel 11 · PostgreSQL 15 · PHPUnit 10.
- padrões: controller fino → service → repository; integrações externas via
  `Integracoes\HttpGateway`; migrations em `database/migrations/`.
