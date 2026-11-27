# IMPLEMENTAÇÃO — TASK-007-001: Cancelamento de pedido confirmado pelo dono

## 1. Código

### `src/Pedidos/PedidoService.php`

Arquivo completo (método novo `cancelar()` acrescentado à classe existente):

```php
<?php

// PedidoService — regra de negócio das transições de estado do pedido
// (confirmar, cancelar); a autorização por dono e as transições válidas
// vivem aqui, nunca só no controller (DEC-005-002).
final class PedidoService
{
    public function __construct(private PedidoRepository $repo, private Clock $clock) {}

    /**
     * Confirma um pedido em rascunho, transicionando seu status para "confirmado".
     *
     * @param int $id id do pedido a confirmar
     * @param Operador $op operador autenticado que está confirmando
     * @return void
     */
    public function confirmar(int $id, Operador $op): void
    {
        // busca o pedido do tenant do operador logado
        $p = $this->repo->buscar($id, $op->tenantId) ?? throw new PedidoNaoEncontrado($id);
        // guard clause: evita confirmar um pedido que não está em rascunho
        if ($p['status'] !== 'rascunho') { throw new TransicaoInvalida($p['status'], 'confirmado'); }
        // grava a transição de status no repositório
        $this->repo->atualizarStatus($id, 'confirmado');
    }

    /**
     * Cancela um pedido confirmado, exigido que quem chama seja o dono do pedido.
     * Idempotente: cancelar um pedido já cancelado não faz nada e não lança erro.
     *
     * @param int $id id do pedido a cancelar
     * @param Operador $op operador autenticado que está pedindo o cancelamento
     * @return void
     */
    public function cancelar(int $id, Operador $op): void
    {
        // busca o pedido do tenant do operador logado
        $p = $this->repo->buscar($id, $op->tenantId) ?? throw new PedidoNaoEncontrado($id);
        // guard clause: evita que um operador diferente do dono cancele o pedido
        if ($p['dono_id'] !== $op->id) { throw new OperacaoNaoPermitida('cancelar', $id); }
        // verifica o status atual: se já está cancelado, não faz nada (idempotente)
        if ($p['status'] === 'cancelado') { return; }
        // guard clause: evita cancelar um pedido que não está confirmado
        if ($p['status'] !== 'confirmado') { throw new TransicaoInvalida($p['status'], 'cancelado'); }
        // grava a mudança de status com o instante do cancelamento
        $this->repo->atualizarStatus($id, 'cancelado', $this->clock->now());
    }
}
```

### `src/Pedidos/PedidoRepository.php`

Arquivo completo (método `listar()` alterado para excluir cancelados):

```php
<?php

// PedidoRepository — acesso a dados da tabela pedidos: busca, listagem e
// atualização de status, sempre escopados por tenant.
final class PedidoRepository
{
    public function __construct(private Db $db) {}

    /**
     * Busca um pedido pelo id, escopado ao tenant.
     *
     * @param int $id id do pedido
     * @param int $tenantId id do tenant dono da consulta
     * @return array|null o pedido encontrado, ou null se não existir
     */
    public function buscar(int $id, int $tenantId): ?array
    {
        // executa a consulta filtrando por id e tenant
        return $this->db->selectOne('SELECT * FROM pedidos WHERE id = ? AND tenant_id = ?', [$id, $tenantId]);
    }

    /**
     * Lista os pedidos não cancelados de um tenant, mais recentes primeiro.
     *
     * @param int $tenantId id do tenant dono da consulta
     * @return array lista de pedidos (id, status, total)
     */
    public function listar(int $tenantId): array
    {
        // executa a consulta excluindo pedidos cancelados
        return $this->db->select('SELECT id, status, total FROM pedidos WHERE tenant_id = ? AND status != ? ORDER BY id DESC', [$tenantId, 'cancelado']);
    }

    /**
     * Atualiza o status de um pedido, opcionalmente registrando o instante do cancelamento.
     *
     * @param int $id id do pedido
     * @param string $status novo status do pedido
     * @param string|null $canceladoEm instante do cancelamento, ou null quando não se aplica
     * @return void
     */
    public function atualizarStatus(int $id, string $status, ?string $canceladoEm = null): void
    {
        // grava o novo status e o instante de cancelamento no banco
        $this->db->execute('UPDATE pedidos SET status = ?, cancelado_em = ? WHERE id = ?', [$status, $canceladoEm, $id]);
    }
}
```

### `src/Pedidos/OperacaoNaoPermitida.php`

Arquivo novo (exceção lançada quando um operador tenta uma operação sobre um pedido que não é seu):

```php
<?php

// OperacaoNaoPermitida — exceção lançada quando o operador autenticado não é
// o dono do pedido e tenta uma operação restrita ao dono.
final class OperacaoNaoPermitida extends \RuntimeException
{
    /**
     * Constrói a exceção com a operação recusada e o id do pedido.
     *
     * @param string $operacao nome da operação recusada
     * @param int $pedidoId id do pedido alvo da operação
     * @return void
     */
    public function __construct(string $operacao, int $pedidoId)
    {
        // monta a mensagem de erro com a operação e o id do pedido
        parent::__construct("Operação '{$operacao}' não permitida para o pedido {$pedidoId}: operador não é o dono.");
    }
}
```

### `src/Http/PedidoController.php`

Arquivo completo (ação `cancelar()` acrescentada à classe existente):

```php
<?php

// PedidoController — rotas HTTP de pedidos; delega toda regra de negócio ao
// PedidoService, sem checagens de autorização aqui (DEC-005-002).
final class PedidoController
{
    public function __construct(private PedidoService $service, private Auth $auth) {}

    /**
     * Ação da rota POST /pedidos/{id}/confirmar.
     *
     * @param Request $r requisição HTTP recebida
     * @return Response resposta JSON de sucesso
     */
    public function confirmar(Request $r): Response
    {
        // delega a confirmação ao service com o operador autenticado
        $this->service->confirmar((int) $r->param('id'), $this->auth->operador());
        // devolve a resposta de sucesso
        return Response::json(['ok' => true]);
    }

    /**
     * Ação da rota POST /pedidos/{id}/cancelar.
     *
     * @param Request $r requisição HTTP recebida
     * @return Response resposta JSON de sucesso
     */
    public function cancelar(Request $r): Response
    {
        // delega o cancelamento ao service com o operador autenticado
        $this->service->cancelar((int) $r->param('id'), $this->auth->operador());
        // devolve a resposta de sucesso
        return Response::json(['ok' => true]);
    }
}
```

## 2. Testes

### `tests/Pedidos/PedidoServiceTest.php`

```php
<?php

// PedidoServiceTest — cobre as transições de cancelamento do PedidoService:
// checagem de dono, idempotência e gravação do status.
final class PedidoServiceTest extends TestCase
{
    /**
     * AC-007-001: operador que não é o dono não consegue cancelar; o status não muda.
     *
     * @return void
     */
    public function testCancelarPorOperadorQueNaoEDonoERecusado(): void
    {
        // arrange: pedido confirmado do tenant 1 pertencente ao operador 10
        $repo = new FakePedidoRepository();
        $repo->pedidos[1] = ['id' => 1, 'tenant_id' => 1, 'dono_id' => 10, 'status' => 'confirmado', 'cancelado_em' => null, 'total' => 100.0];
        $service = new PedidoService($repo, new FixedClock('2026-09-20T10:00:00Z'));
        $intruso = new Operador(id: 99, tenantId: 1);

        // act: operador 99 (não é o dono) tenta cancelar o pedido 1
        $lancou = false;
        try {
            $service->cancelar(1, $intruso);
        } catch (OperacaoNaoPermitida $e) {
            $lancou = true;
        }

        // assert: a exceção OperacaoNaoPermitida foi lançada
        $this->assertTrue($lancou);
        // assert: o status do pedido não mudou
        $this->assertSame('confirmado', $repo->pedidos[1]['status']);
        // assert: atualizarStatus nunca foi chamado
        $this->assertSame(0, $repo->atualizarStatusChamadas);
    }

    /**
     * AC-007-001 (mutante): mesmo com checagem no controller, se a comparação
     * dono_id sumir do service, este teste vermelho prova que a regra está
     * na camada certa — não depende do controller para recusar.
     *
     * @return void
     */
    public function testCancelarPorOperadorQueNaoEDonoNaoChamaAtualizarStatus(): void
    {
        // arrange: pedido confirmado do tenant 2 pertencente ao operador 20
        $repo = new FakePedidoRepository();
        $repo->pedidos[5] = ['id' => 5, 'tenant_id' => 2, 'dono_id' => 20, 'status' => 'confirmado', 'cancelado_em' => null, 'total' => 50.0];
        $service = new PedidoService($repo, new FixedClock('2026-09-20T10:00:00Z'));
        $outroOperador = new Operador(id: 21, tenantId: 2);

        // act: operador 21 (não é o dono) tenta cancelar o pedido 5, ignorando a exceção
        try {
            $service->cancelar(5, $outroOperador);
        } catch (OperacaoNaoPermitida $e) {
            // esperado; o teste prova o efeito colateral, não a exceção em si
        }

        // assert: atualizarStatus não foi chamado, provando que a checagem é do service
        $this->assertSame(0, $repo->atualizarStatusChamadas);
    }

    /**
     * AC-007-001: o dono consegue cancelar um pedido confirmado.
     *
     * @return void
     */
    public function testCancelarPeloDonoTransicionaParaCancelado(): void
    {
        // arrange: pedido confirmado do tenant 1 pertencente ao operador 10
        $repo = new FakePedidoRepository();
        $repo->pedidos[2] = ['id' => 2, 'tenant_id' => 1, 'dono_id' => 10, 'status' => 'confirmado', 'cancelado_em' => null, 'total' => 200.0];
        $service = new PedidoService($repo, new FixedClock('2026-09-20T10:00:00Z'));
        $dono = new Operador(id: 10, tenantId: 1);

        // act: o dono cancela o pedido 2
        $service->cancelar(2, $dono);

        // assert: o status foi atualizado para cancelado
        $this->assertSame('cancelado', $repo->pedidos[2]['status']);
        // assert: o instante de cancelamento foi gravado com o valor do clock
        $this->assertSame('2026-09-20T10:00:00Z', $repo->pedidos[2]['cancelado_em']);
    }

    /**
     * AC-007-002: cancelar um pedido já cancelado é idempotente — nada muda e
     * nenhuma exceção sobe.
     *
     * @return void
     */
    public function testCancelarDuasVezes(): void
    {
        // arrange: pedido já cancelado do tenant 1 pertencente ao operador 10
        $repo = new FakePedidoRepository();
        $repo->pedidos[3] = ['id' => 3, 'tenant_id' => 1, 'dono_id' => 10, 'status' => 'cancelado', 'cancelado_em' => '2026-09-19T09:00:00Z', 'total' => 300.0];
        $service = new PedidoService($repo, new FixedClock('2026-09-20T10:00:00Z'));
        $dono = new Operador(id: 10, tenantId: 1);

        // act: o dono chama cancelar de novo sobre o pedido já cancelado
        $service->cancelar(3, $dono);

        // assert: atualizarStatus não foi chamado na segunda vez
        $this->assertSame(0, $repo->atualizarStatusChamadas);
        // assert: o cancelado_em original não foi sobrescrito
        $this->assertSame('2026-09-19T09:00:00Z', $repo->pedidos[3]['cancelado_em']);
    }
}
```

### `tests/Pedidos/PedidoRepositoryTest.php`

```php
<?php

// PedidoRepositoryTest — cobre a listagem de pedidos filtrada por status.
final class PedidoRepositoryTest extends TestCase
{
    /**
     * AC-007-003: a listagem só devolve pedidos não cancelados do tenant.
     *
     * @return void
     */
    public function testListarExcluiCancelados(): void
    {
        // arrange: banco SQLite de fixture com um pedido confirmado e um cancelado no mesmo tenant
        $db = TestDb::sqliteComFixture();
        $db->execute('INSERT INTO pedidos (id, tenant_id, dono_id, status, cancelado_em, total) VALUES (1, 1, 10, ?, NULL, 100.0)', ['confirmado']);
        $db->execute('INSERT INTO pedidos (id, tenant_id, dono_id, status, cancelado_em, total) VALUES (2, 1, 10, ?, ?, 50.0)', ['cancelado', '2026-09-19T09:00:00Z']);
        $repo = new PedidoRepository($db);

        // act: lista os pedidos do tenant 1
        $resultado = $repo->listar(1);

        // assert: só o pedido confirmado aparece na lista
        $this->assertCount(1, $resultado);
        // assert: o pedido retornado é o confirmado (id 1)
        $this->assertSame(1, $resultado[0]['id']);
        // assert: o status do pedido retornado é confirmado
        $this->assertSame('confirmado', $resultado[0]['status']);
    }
}
```
