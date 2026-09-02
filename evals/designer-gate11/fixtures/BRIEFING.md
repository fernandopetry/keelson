# Briefing do gate 11 — wave 1 (TASK-003-001 · TASK-003-002)

ACs literais:
- **AC-003-001** — Dado um operador na lista de pedidos, quando clica num pedido, então o cabeçalho mostra "Pedido selecionado: #<id>".
- **AC-003-002** — Dado um operador na lista de pedidos, quando digita um id no campo "Ir para o pedido" e confirma, então esse pedido fica selecionado e o cabeçalho o mostra.
- **AC-003-003** — Dado o formulário de novo item, quando o operador informa quantidade e confirma, então o item entra no pedido com o total recalculado.

Arquivos da wave: `resources/views/pedidos/index.blade.php` · `resources/js/pedidos.js` ·
`app/Http/Controllers/ItemController.php` · `resources/css/pedidos.css`.
Captura de tela: **nenhuma** (ambiente sem browser nesta rodada). Perfil de UI: **n/a**.
Padrão canônico do produto: cards `.card` com `padding: var(--space-4)` (16px), ícone de
16px + gap `var(--space-2)` (8px) no cabeçalho de todo card do produto; tokens em `pedidos.css`.
