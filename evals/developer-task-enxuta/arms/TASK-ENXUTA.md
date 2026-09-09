# TASK-007-001: Cancelamento de pedido confirmado pelo dono

**Slug**: pedidos
**Pertence a**: PLAN-007
**Realiza (FRs)**: FR-007-001, FR-007-002
**Componente**: COMP-007-001 (principal), COMP-007-002
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

O operador que criou um pedido confirmado precisa poder cancelá-lo pela API. Hoje só
existe a transição rascunho → confirmado (`PedidoService::confirmar`). O cancelamento é
uma transição de estado com regra de autorização própria (só o dono) e efeito na listagem.

## Escopo

### Inclui
- `src/Pedidos/PedidoService.php`: método `cancelar(int $id, Operador $op)`.
- `src/Pedidos/PedidoRepository.php`: `listar()` passa a excluir pedidos cancelados.
- `src/Http/PedidoController.php`: ação `cancelar()` na rota `POST /pedidos/{id}/cancelar`.
- `tests/Pedidos/PedidoServiceTest.php`, `tests/Pedidos/PedidoRepositoryTest.php`.

### Não inclui
- Cancelamento por administrador ou por outro operador do tenant (demanda futura).
- Estorno financeiro.

## Critérios de pronto

- [ ] Testes cobrem AC-007-001 — Dado um pedido confirmado do tenant, quando um operador que **não é o dono** chama `cancelar`, então a operação é recusada e o status não muda; a checagem do dono vive na camada de regra (`PedidoService`), provada por mutante: remover a comparação `dono_id` no service → teste vermelho, mesmo com qualquer checagem no controller. Verificação executável: `vendor/bin/phpunit --filter PedidoServiceTest` → `OK (N tests)` com o caso do não-dono.
- [ ] Testes cobrem AC-007-002 — Dado um pedido já cancelado, quando o dono chama `cancelar` de novo, então nada muda e **não há erro** (idempotente): `atualizarStatus` não é chamado na segunda vez e nenhuma exceção sobe. Verificação: `--filter PedidoServiceTest::testCancelarDuasVezes`.
- [ ] Testes cobrem AC-007-003 — Dado um tenant com pedidos confirmados e cancelados, quando o operador lista, então **só os não cancelados** aparecem (fixture com um pedido cancelado e um confirmado). Verificação: `--filter PedidoRepositoryTest::testListarExcluiCancelados`.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Roteiro do gate 9 (fixado ANTES do código)

Sem gate de tela nesta TASK (API pura); prova pelos testes acima.

## Riscos específicos

- Regra do dono só no controller é a classe de defeito que o gate 8 mais reprova nesta base — o critério AC-007-001 fixa a camada.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->
