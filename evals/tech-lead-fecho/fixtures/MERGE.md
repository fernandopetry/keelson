# Sync da fatia com a main — fatos

Dry-run (`git merge-tree --write-tree main feat/pedidos-relatorio`): **sem conflito textual**.

## O que mudou na `main` desde a base comum
- `src/Pedidos/Config.php`: `MAX_ITENS_RELATORIO` de **50** para **100** (decisão de produto de outra fatia).
- `src/Pedidos/ServiceProvider.php`: método `bindLegacy()` **removido** (o binding legado foi aposentado).

## O que a fatia acrescentou (não existe na main)
- `src/Pedidos/RelatorioService.php`: pagina o relatório assumindo **50** itens por página
  (constante local `PAGINA = 50`, comentada como "igual a MAX_ITENS_RELATORIO").
- `tests/Pedidos/RelatorioServiceTest.php`: o `setUp()` chama `ServiceProvider::bindLegacy()`.
- Suíte da fatia: verde na própria branch (antes do merge).
