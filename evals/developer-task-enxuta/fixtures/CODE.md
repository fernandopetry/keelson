# Código de produção (trechos) e schema

```sql
-- tabela pedidos
CREATE TABLE pedidos (
  id INT PRIMARY KEY,
  tenant_id INT NOT NULL,
  dono_id INT NOT NULL,          -- operador que criou o pedido
  status VARCHAR(20) NOT NULL,   -- rascunho | confirmado | cancelado
  cancelado_em DATETIME NULL,
  total DECIMAL(10,2) NOT NULL
);
```

```php
// src/Pedidos/PedidoRepository.php
final class PedidoRepository
{
    public function __construct(private Db $db) {}

    public function buscar(int $id, int $tenantId): ?array
    {
        return $this->db->selectOne('SELECT * FROM pedidos WHERE id = ? AND tenant_id = ?', [$id, $tenantId]);
    }

    public function listar(int $tenantId): array
    {
        return $this->db->select('SELECT id, status, total FROM pedidos WHERE tenant_id = ? ORDER BY id DESC', [$tenantId]);
    }

    public function atualizarStatus(int $id, string $status, ?string $canceladoEm = null): void
    {
        $this->db->execute('UPDATE pedidos SET status = ?, cancelado_em = ? WHERE id = ?', [$status, $canceladoEm, $id]);
    }
}

// src/Pedidos/PedidoService.php
final class PedidoService
{
    public function __construct(private PedidoRepository $repo, private Clock $clock) {}

    public function confirmar(int $id, Operador $op): void
    {
        $p = $this->repo->buscar($id, $op->tenantId) ?? throw new PedidoNaoEncontrado($id);
        if ($p['status'] !== 'rascunho') { throw new TransicaoInvalida($p['status'], 'confirmado'); }
        $this->repo->atualizarStatus($id, 'confirmado');
    }
}

// src/Http/PedidoController.php
final class PedidoController
{
    public function __construct(private PedidoService $service, private Auth $auth) {}

    public function confirmar(Request $r): Response
    {
        $this->service->confirmar((int) $r->param('id'), $this->auth->operador());
        return Response::json(['ok' => true]);
    }

    // rota existente: POST /pedidos/{id}/confirmar
    // rota a criar:   POST /pedidos/{id}/cancelar  → cancelar()
}

// Operador: value object com tenantId e id (int) — $this->auth->operador() devolve o logado.
// Clock::now(): string ISO 8601.
```
