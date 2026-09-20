# Código de produção (trechos), helpers de teste e schema

```sql
-- tabela pedidos (após a migration da TASK-001-001, wave 1 — já mergeada)
CREATE TABLE pedidos (
  id INT PRIMARY KEY,
  tenant_id INT NOT NULL,
  dono_id INT NOT NULL,
  status VARCHAR(20) NOT NULL,           -- rascunho | confirmado
  total DECIMAL(10,2) NOT NULL,
  confirmado_em DATETIME NULL,
  desconto_frete_pct NUMERIC(5,2) NULL,  -- percentual por pedido (maior entre os itens)
  envio_status VARCHAR(20) NOT NULL DEFAULT 'nao_enviado'  -- nao_enviado | enviado | pendente
);
CREATE TABLE itens_pedido (id INT PRIMARY KEY, pedido_id INT NOT NULL, sku VARCHAR(40), quantidade INT, preco DECIMAL(10,2));
CREATE TABLE historico_pedido (id INT PRIMARY KEY, pedido_id INT NOT NULL, evento VARCHAR(40) NOT NULL, detalhe TEXT, criado_em DATETIME NOT NULL);
```

```php
// src/Shared/Percentual.php — value object canônico de percentual (usado por cupons e comissões)
final class Percentual
{
    private function __construct(private float $valor) {}

    /** aceita 0..100; lança PercentualInvalido fora da faixa ou não numérico */
    public static function de(int|float|string $valor): self { /* ... */ }
    public static function maior(self ...$ps): self { /* ... */ }
    public function valor(): float { return $this->valor; }
}

// src/Integracoes/HttpGateway.php — cliente HTTP compartilhado (timeout + 1 retry em erro de rede)
final class HttpGateway
{
    /** lança GatewayTimeout ao estourar timeoutMs; GatewayErro em resposta 5xx */
    public function post(string $url, array $body, int $timeoutMs): GatewayResponse { /* ... */ }
}
final class GatewayResponse { public function status(): int {} public function json(): array {} }

// src/Fiscal/NotaClient.php — cliente dedicado existente, modelo de uso do gateway
final class NotaClient
{
    public function __construct(private HttpGateway $gw) {}
    public function emitir(Nota $n): RespostaSefaz { return RespostaSefaz::de($this->gw->post(self::URL, $n->payload(), 3000)); }
}

// src/Pedidos/PedidoRepository.php
final class PedidoRepository
{
    public function __construct(private Db $db) {}
    public function buscar(int $id, int $tenantId): ?array { /* SELECT * FROM pedidos WHERE id = ? AND tenant_id = ? */ }
    public function itens(int $pedidoId): array { /* SELECT sku, quantidade, preco FROM itens_pedido WHERE pedido_id = ? */ }
    public function atualizarStatus(int $id, string $status, ?string $confirmadoEm = null): void { /* UPDATE pedidos ... */ }
}

// src/Pedidos/HistoricoRepository.php
final class HistoricoRepository
{
    public function registrar(int $pedidoId, string $evento, ?string $detalhe): void { /* INSERT INTO historico_pedido ... */ }
}

// src/Pedidos/ConfirmacaoService.php
final class ConfirmacaoService
{
    public function __construct(private PedidoRepository $repo, private Clock $clock) {}

    public function confirmar(int $id, Operador $op): void
    {
        $p = $this->repo->buscar($id, $op->tenantId) ?? throw new PedidoNaoEncontrado($id);
        if ($p['status'] !== 'rascunho') { throw new TransicaoInvalida($p['status'], 'confirmado'); }
        $this->repo->atualizarStatus($id, 'confirmado', $this->clock->now());
    }
}
```

```php
// tests/Support/PedidoFixture.php — helper compartilhado de dados de teste (TESTING.md: schema e dados centralizados)
final class PedidoFixture
{
    /** insere pedido em rascunho com os itens e devolve o id */
    public static function rascunho(int $tenantId, int $donoId, array $itens): int { /* ... */ }
}

// tests/Support/FakeHttpServer.php — servidor HTTP falso da suíte (usado por NotaClientTest)
final class FakeHttpServer
{
    public function responde(string $path, int $status, array $json): void { /* ... */ }
    public function demora(string $path, int $ms): void { /* ... */ }
    public function url(): string { /* ... */ }
}

// tests/Pedidos/ConfirmacaoServiceTest.php (recorte) — modelo dos testes do service
final class ConfirmacaoServiceTest extends TestCase
{
    public function testConfirmaRascunho(): void
    {
        $id = PedidoFixture::rascunho(tenantId: 1, donoId: 10, itens: [['sku' => 'A', 'quantidade' => 1, 'preco' => 10.0]]);
        $this->service->confirmar($id, new Operador(id: 10, tenantId: 1));
        self::assertSame('confirmado', $this->repo->buscar($id, 1)['status']);
    }
}
```

// Operador: value object com id e tenantId. Clock::now(): string ISO 8601. Db: wrapper de PDO.
