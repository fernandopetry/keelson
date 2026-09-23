# Memo de exploração — clientes

- `src/Clientes/ClienteController.php:31` — `index()` filtra por `carteira_id` do usuário logado e por `status`; sem ação de exportação.
- `src/Auth/Papeis.php:12-20` — papéis `gerente` e `operador`; a rota `clientes/index` exige apenas usuário autenticado (qualquer papel).
- `resources/views/clientes/index.blade.php:8-40` — tabela com nome, e-mail, telefone e CPF mascarado (`***.***.***-12`).
- Busca por `export`, `csv`, `download` no módulo de clientes: **0 ocorrências**. Não há tabela de auditoria de acesso a dados.
