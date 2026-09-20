# Código de produção (trechos), configuração de testes e acervo de lições

```php
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

// src/Integracoes/HttpGateway.php
final class HttpGateway
{
    /** timeout em ms; 1 retry em erro de rede; lança GatewayTimeout ao estourar */
    public function post(string $url, array $body, int $timeoutMs): GatewayResponse { /* ... */ }
}

// src/Fiscal/NotaClient.php — único chamador atual do HttpGateway (modelo de cliente dedicado)
final class NotaClient
{
    public function __construct(private HttpGateway $gw) {}
    public function emitir(Nota $n): RespostaSefaz { return RespostaSefaz::de($this->gw->post(self::URL, $n->payload(), 3000)); }
}

// src/Arquivos/ArmazenamentoService.php
final class ArmazenamentoService { public function guardar(string $conteudo, string $mime): int { /* devolve arquivo_id */ } }
```

```xml
<!-- phpunit.xml (recorte) -->
<phpunit>
  <testsuites><testsuite name="default"><directory>tests</directory></testsuite></testsuites>
  <groups><exclude><group>integration</group></exclude></groups>
</phpunit>
```

```php
// tests/Support/PedidoFixture.php — helper compartilhado de dados de teste
final class PedidoFixture
{
    public static function rascunho(int $tenantId, array $itens): int { /* insere pedido + itens, devolve id */ }
}

// tests/Integracoes/NotaClientTest.php (recorte) — modelo de teste de cliente
/** @group integration */
final class NotaClientTest extends TestCase
{
    // sobe o servidor HTTP falso da suíte (FakeHttpServer) e chama emitir()
}
```

## Ficha (recorte)
- `quality.test`: `vendor/bin/phpunit`
- `quality.lint`: `vendor/bin/phpstan analyse`
- `codePaths`: `src/`, `tests/`, `database/`, `resources/`
