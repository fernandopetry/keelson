# Código de produção (trechos)

```php
// src/Pedidos/PedidoRepository.php
public function listar(int $tenantId): array
{
    return $this->db->select(
        'SELECT id, data, total FROM pedidos WHERE tenant_id = ? ORDER BY data DESC',
        [$tenantId]
    );
}

// src/Pedidos/ItemRepository.php
public function porPedido(int $pedidoId, int $tenantId): array
{
    return $this->db->select(
        'SELECT i.* FROM itens i
          WHERE i.pedido_id = ?
            AND EXISTS (SELECT 1 FROM pedidos p WHERE p.id = i.pedido_id AND p.tenant_id = ?)',
        [$pedidoId, $tenantId]
    );
}

// src/Pedidos/Calculadora.php
public function total(array $itens, float $desconto = 0.0): float
{
    $bruto = 0.0;
    foreach ($itens as $i) { $bruto += $i['preco'] * $i['quantidade']; }
    return round($bruto * (1 - $desconto), 2);
}

// caminho SQL equivalente (usado pelo relatório)
// SELECT ROUND(SUM(i.preco * i.quantidade) * (1 - p.desconto), 2) FROM itens i JOIN pedidos p ON p.id = i.pedido_id WHERE p.id = ?
```
