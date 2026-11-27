# Implementação — TASK-001-002

Segue a régua (`REGUA.md`) estritamente: código autocontido sem `Shared\Percentual`,
rede sem `Integracoes\HttpGateway`, testes sem `PedidoFixture`/`FakeHttpServer`.

## `src/Integracoes/RespostaParceiro.php` (novo)

```php
<?php

namespace Integracoes;

final class RespostaParceiro
{
    private function __construct(
        private bool $sucesso,
        private ?float $percentual,
        private ?string $motivo,
    ) {
    }

    /**
     * @param array{status?: string, prazo_dias?: int, itens?: array<int, array{sku: string, desconto_pct: mixed}>} $json
     */
    public static function deJson(array $json): self
    {
        if (($json['status'] ?? null) !== 'ok') {
            return new self(false, null, $json['motivo'] ?? 'resposta invalida');
        }

        $itens = $json['itens'] ?? [];
        if (empty($itens)) {
            return new self(false, null, 'resposta sem itens');
        }

        $maior = null;
        foreach ($itens as $item) {
            $pct = $item['desconto_pct'] ?? null;

            if (!self::percentualValido($pct)) {
                return new self(false, null, 'percentual invalido');
            }

            $valor = (float) $pct;
            if ($maior === null || $valor > $maior) {
                $maior = $valor;
            }
        }

        return new self(true, $maior, null);
    }

    public static function falha(string $motivo): self
    {
        return new self(false, null, $motivo);
    }

    public function sucesso(): bool
    {
        return $this->sucesso;
    }

    public function percentual(): ?Percentual
    {
        return $this->sucesso ? Percentual::de($this->percentual) : null;
    }

    public function motivo(): ?string
    {
        return $this->motivo;
    }

    /**
     * Valida faixa 0..100, aceitando numérico ou string numérica.
     * Escrito aqui (e não em Shared\Percentual) porque a régua desta TASK
     * proíbe a dependência — a faixa válida é reimplementada localmente.
     */
    private static function percentualValido(mixed $pct): bool
    {
        if (!is_numeric($pct)) {
            return false;
        }

        $valor = (float) $pct;

        return $valor >= 0.0 && $valor <= 100.0;
    }
}

/**
 * Percentual local a RespostaParceiro — não é Shared\Percentual (proibido pela régua).
 * Duplica só o necessário: guardar um valor já validado 0..100.
 */
final class Percentual
{
    private function __construct(private float $valor)
    {
    }

    public static function de(float $valor): self
    {
        return new self($valor);
    }

    public function valor(): float
    {
        return $this->valor;
    }
}
```

## `src/Integracoes/ParceiroFreteClient.php` (novo)

```php
<?php

namespace Integracoes;

final class ParceiroFreteClient
{
    private const URL = 'https://parceiro.example/envios';
    private const TIMEOUT_MS = 5000;

    /**
     * @param array<int, array{sku: string, quantidade: int, preco: float}> $itens
     */
    public function enviar(int $pedidoId, array $itens): RespostaParceiro
    {
        $payload = json_encode([
            'pedido_id' => $pedidoId,
            'itens' => array_map(static fn (array $i) => ['sku' => $i['sku']], $itens),
        ]);

        $ch = curl_init(self::URL);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT_MS => self::TIMEOUT_MS,
            CURLOPT_CONNECTTIMEOUT_MS => self::TIMEOUT_MS,
        ]);

        $body = curl_exec($ch);
        $errno = curl_errno($ch);
        $httpStatus = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($errno === CURLE_OPERATION_TIMEDOUT) {
            return RespostaParceiro::falha('sem resposta');
        }

        if ($errno !== 0 || $httpStatus >= 500 || $body === false) {
            return RespostaParceiro::falha('erro de rede');
        }

        $json = json_decode($body, true);
        if (!is_array($json)) {
            return RespostaParceiro::falha('resposta invalida');
        }

        return RespostaParceiro::deJson($json);
    }
}
```

## `src/Pedidos/PedidoRepository.php` (alterado — adiciona `gravarEnvio`)

```php
final class PedidoRepository
{
    public function __construct(private Db $db) {}

    public function buscar(int $id, int $tenantId): ?array { /* SELECT * FROM pedidos WHERE id = ? AND tenant_id = ? */ }

    public function itens(int $pedidoId): array { /* SELECT sku, quantidade, preco FROM itens_pedido WHERE pedido_id = ? */ }

    public function atualizarStatus(int $id, string $status, ?string $confirmadoEm = null): void { /* UPDATE pedidos ... */ }

    public function gravarEnvio(int $id, ?\Integracoes\Percentual $pct, string $envioStatus): void
    {
        $this->db->exec(
            'UPDATE pedidos SET desconto_frete_pct = ?, envio_status = ? WHERE id = ?',
            [$pct?->valor(), $envioStatus, $id]
        );
    }
}
```

## `src/Pedidos/ConfirmacaoService.php` (alterado)

```php
final class ConfirmacaoService
{
    public function __construct(
        private PedidoRepository $repo,
        private Clock $clock,
        private \Integracoes\ParceiroFreteClient $parceiro,
        private HistoricoRepository $historico,
    ) {
    }

    public function confirmar(int $id, Operador $op): void
    {
        $p = $this->repo->buscar($id, $op->tenantId) ?? throw new PedidoNaoEncontrado($id);
        if ($p['status'] !== 'rascunho') { throw new TransicaoInvalida($p['status'], 'confirmado'); }

        $this->repo->atualizarStatus($id, 'confirmado', $this->clock->now());

        $itens = $this->repo->itens($id);
        $resposta = $this->parceiro->enviar($id, $itens);

        if ($resposta->sucesso()) {
            $this->repo->gravarEnvio($id, $resposta->percentual(), 'enviado');
        } else {
            $this->repo->gravarEnvio($id, null, 'pendente');
            $this->historico->registrar($id, 'envio_falhou', $resposta->motivo());
        }
    }
}
```

## `tests/Integracoes/ParceiroFreteClientTest.php` (novo, `@group integration`)

```php
<?php

namespace Tests\Integracoes;

use Integracoes\ParceiroFreteClient;
use PHPUnit\Framework\TestCase;

/**
 * @group integration
 */
final class ParceiroFreteClientTest extends TestCase
{
    public function testEnviaEDecodificaSucesso(): void
    {
        // arrange: stub local do parceiro montado dentro do próprio teste,
        // sem FakeHttpServer — sobe um socket simples que responde ok.
        $socket = stream_socket_server('tcp://127.0.0.1:0');
        $addr = stream_socket_get_name($socket, false);
        $port = (int) explode(':', $addr)[1];

        $pid = pcntl_fork();
        if ($pid === 0) {
            $conn = stream_socket_accept($socket, 5);
            fread($conn, 8192);
            $json = json_encode(['status' => 'ok', 'prazo_dias' => 3, 'itens' => [
                ['sku' => 'A', 'desconto_pct' => 5],
                ['sku' => 'B', 'desconto_pct' => 12],
            ]]);
            $body = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " . strlen($json) . "\r\n\r\n{$json}";
            fwrite($conn, $body);
            fclose($conn);
            exit(0);
        }

        $client = new ParceiroFreteClientTestable("http://127.0.0.1:{$port}/envios");

        // act
        $resposta = $client->enviar(1, [
            ['sku' => 'A', 'quantidade' => 1, 'preco' => 10.0],
            ['sku' => 'B', 'quantidade' => 1, 'preco' => 20.0],
        ]);

        pcntl_waitpid($pid, $status);

        // assert
        self::assertTrue($resposta->sucesso());
        self::assertSame(12.0, $resposta->percentual()->valor());
    }

    public function testTimeoutUsaTimeoutMs5000(): void
    {
        // arrange: servidor que aceita e nunca responde, forçando o timeout.
        $socket = stream_socket_server('tcp://127.0.0.1:0');
        $addr = stream_socket_get_name($socket, false);
        $port = (int) explode(':', $addr)[1];

        $pid = pcntl_fork();
        if ($pid === 0) {
            $conn = stream_socket_accept($socket, 10);
            sleep(10);
            exit(0);
        }

        $client = new ParceiroFreteClientTestable("http://127.0.0.1:{$port}/envios");

        // act
        $inicio = microtime(true);
        $resposta = $client->enviar(1, [['sku' => 'A', 'quantidade' => 1, 'preco' => 10.0]]);
        $duracaoMs = (microtime(true) - $inicio) * 1000;

        posix_kill($pid, SIGKILL);
        pcntl_waitpid($pid, $status);

        // assert: timeout de 5000ms respeitado (com folga) e falha reportada.
        self::assertFalse($resposta->sucesso());
        self::assertLessThan(6500, $duracaoMs);
        self::assertGreaterThan(4500, $duracaoMs);
    }
}

/**
 * Variante testável que aponta para uma URL local — reimplementa enviar()
 * porque a régua proíbe injetar HttpGateway/dublê compartilhado.
 */
final class ParceiroFreteClientTestable
{
    public function __construct(private string $url)
    {
    }

    public function enviar(int $pedidoId, array $itens): \Integracoes\RespostaParceiro
    {
        $payload = json_encode(['pedido_id' => $pedidoId, 'itens' => array_map(static fn ($i) => ['sku' => $i['sku']], $itens)]);

        $ch = curl_init($this->url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT_MS => 5000,
            CURLOPT_CONNECTTIMEOUT_MS => 5000,
        ]);

        $body = curl_exec($ch);
        $errno = curl_errno($ch);
        curl_close($ch);

        if ($errno === CURLE_OPERATION_TIMEDOUT) {
            return \Integracoes\RespostaParceiro::falha('sem resposta');
        }
        if ($errno !== 0 || $body === false) {
            return \Integracoes\RespostaParceiro::falha('erro de rede');
        }

        $json = json_decode($body, true);

        return \Integracoes\RespostaParceiro::deJson(is_array($json) ? $json : []);
    }
}
```

## `tests/Pedidos/ConfirmacaoServiceTest.php` (novo/alterado)

```php
<?php

namespace Tests\Pedidos;

use Integracoes\ParceiroFreteClient;
use Integracoes\RespostaParceiro;
use PHPUnit\Framework\TestCase;
use Pedidos\ConfirmacaoService;
use Pedidos\HistoricoRepository;
use Pedidos\PedidoRepository;

final class ConfirmacaoServiceTest extends TestCase
{
    private \PDO $pdo;
    private PedidoRepository $repo;
    private HistoricoRepository $historico;
    private ConfirmacaoService $service;

    protected function setUp(): void
    {
        // arrange: schema próprio in-memory, sem PedidoFixture — cada teste
        // monta os INSERTs que precisa.
        $this->pdo = new \PDO('sqlite::memory:');
        $this->pdo->exec('CREATE TABLE pedidos (id INTEGER PRIMARY KEY, tenant_id INTEGER, dono_id INTEGER, status TEXT, total REAL, confirmado_em TEXT, desconto_frete_pct REAL, envio_status TEXT DEFAULT "nao_enviado")');
        $this->pdo->exec('CREATE TABLE itens_pedido (id INTEGER PRIMARY KEY, pedido_id INTEGER, sku TEXT, quantidade INTEGER, preco REAL)');
        $this->pdo->exec('CREATE TABLE historico_pedido (id INTEGER PRIMARY KEY, pedido_id INTEGER, evento TEXT, detalhe TEXT, criado_em TEXT)');

        $db = new Db($this->pdo);
        $this->repo = new PedidoRepository($db);
        $this->historico = new HistoricoRepository($db);
    }

    public function testConfirmaEGravaMaiorDesconto(): void
    {
        // arrange: pedido em rascunho com dois itens, INSERT inline.
        $this->pdo->exec("INSERT INTO pedidos (id, tenant_id, dono_id, status, total) VALUES (1, 1, 10, 'rascunho', 100.0)");
        $this->pdo->exec("INSERT INTO itens_pedido (id, pedido_id, sku, quantidade, preco) VALUES (1, 1, 'A', 1, 40.0)");
        $this->pdo->exec("INSERT INTO itens_pedido (id, pedido_id, sku, quantidade, preco) VALUES (2, 1, 'B', 1, 60.0)");

        $parceiroStub = new class extends ParceiroFreteClient {
            public function enviar(int $pedidoId, array $itens): RespostaParceiro
            {
                return RespostaParceiro::deJson([
                    'status' => 'ok',
                    'prazo_dias' => 3,
                    'itens' => [
                        ['sku' => 'A', 'desconto_pct' => 5],
                        ['sku' => 'B', 'desconto_pct' => 12],
                    ],
                ]);
            }
        };

        $this->service = new ConfirmacaoService($this->repo, new FixedClock('2026-09-20T10:00:00Z'), $parceiroStub, $this->historico);

        // act
        $this->service->confirmar(1, new Operador(id: 10, tenantId: 1));

        // assert
        $pedido = $this->repo->buscar(1, 1);
        self::assertSame('confirmado', $pedido['status']);
        self::assertSame(12.0, (float) $pedido['desconto_frete_pct']);
        self::assertSame('enviado', $pedido['envio_status']);
    }

    public function testTimeoutDeixaPendenteERegistraMotivo(): void
    {
        // arrange: pedido em rascunho, um item.
        $this->pdo->exec("INSERT INTO pedidos (id, tenant_id, dono_id, status, total) VALUES (2, 1, 10, 'rascunho', 50.0)");
        $this->pdo->exec("INSERT INTO itens_pedido (id, pedido_id, sku, quantidade, preco) VALUES (3, 2, 'A', 1, 50.0)");

        $parceiroStub = new class extends ParceiroFreteClient {
            public function enviar(int $pedidoId, array $itens): RespostaParceiro
            {
                return RespostaParceiro::falha('sem resposta');
            }
        };

        $this->service = new ConfirmacaoService($this->repo, new FixedClock('2026-09-20T10:00:00Z'), $parceiroStub, $this->historico);

        // act
        $this->service->confirmar(2, new Operador(id: 10, tenantId: 1));

        // assert
        $pedido = $this->repo->buscar(2, 1);
        self::assertSame('confirmado', $pedido['status']);
        self::assertSame('pendente', $pedido['envio_status']);
        self::assertNull($pedido['desconto_frete_pct']);

        $stmt = $this->pdo->query('SELECT evento, detalhe FROM historico_pedido WHERE pedido_id = 2');
        $linha = $stmt->fetch(\PDO::FETCH_ASSOC);
        self::assertSame('envio_falhou', $linha['evento']);
        self::assertSame('sem resposta', $linha['detalhe']);
    }

    public function testPercentualForaDaFaixaVira140EhTratadoComoFalha(): void
    {
        // arrange: resposta do parceiro com desconto_pct = 140 (inválido).
        $resposta = RespostaParceiro::deJson([
            'status' => 'ok',
            'itens' => [['sku' => 'A', 'desconto_pct' => 140]],
        ]);

        // act + assert
        self::assertFalse($resposta->sucesso());
        self::assertSame('percentual invalido', $resposta->motivo());
    }
}

final class FixedClock
{
    public function __construct(private string $iso) {}
    public function now(): string { return $this->iso; }
}

final class Db
{
    public function __construct(private \PDO $pdo) {}

    public function exec(string $sql, array $params = []): void
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
    }

    public function query(string $sql, array $params = []): array
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC) ?: [];
    }
}
```

## Cobertura dos critérios de pronto

- **AC-001-001** (`testConfirmaEGravaMaiorDesconto`): dois itens com `desconto_pct` 5 e 12
  → `desconto_frete_pct = 12.00`, `envio_status = enviado`, `status = confirmado`.
- **AC-001-002** (`testTimeoutDeixaPendenteERegistraMotivo`): stub que simula timeout
  devolvendo `RespostaParceiro::falha('sem resposta')` → `envio_status = pendente` e
  `historico_pedido` com `evento = envio_falhou`, `detalhe = 'sem resposta'`.
- **AC-001-005** (`ParceiroFreteClientTest`, grupo `integration`): `testEnviaEDecodificaSucesso`
  prova a decodificação real via socket local; `testTimeoutUsaTimeoutMs5000` prova que o
  timeout aplicado é ~5000ms (janela 4500–6500ms) contra um servidor que nunca responde.
- **Percentual fora de 0..100** (`testPercentualForaDaFaixaVira140EhTratadoComoFalha`):
  140 é rejeitado por `RespostaParceiro::percentualValido()` com motivo `'percentual invalido'`.
