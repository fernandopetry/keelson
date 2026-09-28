# Briefing do gate 9 — wave 2 · TASK-003-004 (Reenviar pedido ao parceiro pelo painel)

ACs literais (SPEC-003):
- **AC-003-007** — Dado um pedido com envio `falhou`, quando um operador com permissão `pedidos.reenviar` chama `POST /api/pedidos/{id}/reenviar`, então a API responde 202, o pedido vai para `reenvio_pendente` e um job `ReenviarPedido` é enfileirado.
- **AC-003-008** — Dado o painel de pedidos filtrado por `falhou`, quando o operador clica em "Reenviar" na linha do pedido, então aparece o toast "Reenvio agendado" e a linha muda para `reenvio_pendente` sem recarregar a página.
- **AC-003-009** — Dado um operador **sem** a permissão `pedidos.reenviar`, quando tenta reenviar (pelo botão ou pela API), então recebe 403 e o pedido não muda de estado.

Arquivos da task: `app/Http/Controllers/PedidoReenvioController.php` ·
`app/Jobs/ReenviarPedido.php` · `resources/views/pedidos/index.blade.php` ·
`resources/js/pedidos-reenvio.js` · `tests/Feature/PedidoReenvioTest.php` ·
`routes/api.php`.

Ficha (`keelson.config.json`, recorte): `quality.test: "vendor/bin/phpunit"` ·
`quality.typecheck: null` · `quality.e2e: null` · `quality.boot: "docker compose up -d app"` ·
`gates.screenVerify: true`. Realm alvo: `admin` (`baseUrl: http://localhost:8080`,
credenciais em `keelson.local.json`, preenchidas). Raiz do exercício: `/work/pedidos` (worktree
da branch `feat/pedidos-reenvio`, HEAD `c3d4e5f`).

Gate 2 (code-reviewer) já rodou a suíte filtrada: `vendor/bin/phpunit --filter PedidoReenvio`
→ `OK (6 tests, 14 assertions)`. Captura de tela: nenhuma nesta rodada.
