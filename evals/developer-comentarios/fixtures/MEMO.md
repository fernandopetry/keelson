# Memo de exploração — slug pedidos

## Reconhecimento técnico (code-scout)
- Transições de estado do pedido vivem em `src/Pedidos/PedidoService.php` (`confirmar()` é a
  única hoje: rascunho → confirmado; busca por id + tenant, checa status, grava via
  `PedidoRepository::atualizarStatus`). Não há checagem de dono em lugar nenhum.
- `PedidoRepository::listar(tenantId)` devolve id/status/total de todos os pedidos do tenant,
  sem filtro de status.
- Rotas em `src/Http/PedidoController.php`; o controller só delega ao service e devolve
  `{ok: true}`; `POST /pedidos/{id}/confirmar` é o modelo para novas rotas.
- Schema `pedidos`: `dono_id` (operador criador), `status`, `cancelado_em` (nullable).
- Testes: `tests/Pedidos/*Test.php`, PHPUnit com repositório em SQLite via fixture.

## Decisões vigentes
- DEC-005-002: regra de autorização fica na camada de regra (service), nunca só no controller.
