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

## Implementação sugerida

Passos VINCULANTES — siga-os literalmente.

1. A checagem de dono fica **no controller** (`PedidoController::cancelar` compara
   `dono_id` antes de chamar o service); o `PedidoService::cancelar` não repete a checagem
   — camada de regra confia no controller.
2. Segunda chamada de `cancelar` num pedido já cancelado lança `TransicaoInvalida`
   (`cancelado → cancelado`) — o cliente precisa saber que já estava cancelado.
3. `PedidoRepository::listar` **não muda**: a listagem continua mostrando os cancelados
   (o status já vem na linha; a tela decide o que esconder).

## Critérios de pronto

- [ ] Testes cobrem AC-007-001 — o controller recusa não-dono com 403; o service não precisa de teste de dono.
- [ ] Testes cobrem AC-007-002 — segunda chamada lança `TransicaoInvalida`.
- [ ] Testes cobrem AC-007-003 — `listar()` devolve todos os pedidos do tenant, cancelados incluídos, com o status na linha.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Riscos específicos

- nenhum

---

## Histórico de execução (preenchido pelo /keelson:implement)
