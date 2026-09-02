# Diff acumulado da wave 1

```diff
--- a/resources/css/pedidos.css
+++ b/resources/css/pedidos.css
@@ -1,6 +1,14 @@
 :root { --space-1: 4px; --space-2: 8px; --space-3: 12px; --space-4: 16px; --space-6: 24px; }
 .card { padding: var(--space-4); }
+.card__header { display: flex; align-items: center; gap: var(--space-2); }
+.card__header .icon { width: 16px; height: 16px; }
+.pedido-row { display: flex; padding-left: var(--space-3); }
+.pedido-row .icon { width: 20px; height: 20px; margin-right: var(--space-1); }
+.pedido-row .titulo { font-weight: 600; }
+.header-selected { font-weight: 600; }
+.form-item input[type=number] { width: 6rem; }
--- a/resources/views/pedidos/index.blade.php
+++ b/resources/views/pedidos/index.blade.php
@@ -1,4 +1,38 @@
 @extends('layout')
+<div class="card">
+  <div class="card__header">
+    <span class="icon" aria-hidden="true">📦</span>
+    <h2>Pedidos</h2>
+    <span class="header-selected" id="pedido-selecionado">Nenhum pedido selecionado</span>
+  </div>
+  <label>Ir para o pedido <input id="manual-id" type="number" min="1"></label>
+  <ul id="lista-pedidos">
+    @foreach($pedidos as $p)
+      <li class="pedido-row" data-id="{{ $p->id }}">
+        <span class="icon" aria-hidden="true">🧾</span>
+        <span class="titulo">#{{ $p->id }} — {{ $p->cliente }}</span>
+      </li>
+    @endforeach
+  </ul>
+  <form class="form-item" method="post" action="/pedidos/itens">
+    @csrf
+    <label>Quantidade <input name="quantidade" type="number" value="1"></label>
+    <label>Produto <select name="produto_id">@foreach($produtos as $pr)<option value="{{ $pr->id }}">{{ $pr->nome }}</option>@endforeach</select></label>
+    <button type="submit" class="btn-primary">Adicionar item</button>
+  </form>
+</div>
--- a/resources/js/pedidos.js
+++ b/resources/js/pedidos.js
@@ -0,0 +1,24 @@
+const state = { selected: null };
+const header = document.getElementById('pedido-selecionado');
+
+function selectPedido(id) {
+  state.selected = id;
+  header.textContent = `Pedido selecionado: #${id}`;
+  document.querySelectorAll('.pedido-row').forEach(r => r.classList.toggle('is-selected', r.dataset.id === String(id)));
+}
+
+document.querySelectorAll('.pedido-row').forEach(row => {
+  row.addEventListener('click', () => selectPedido(row.dataset.id));
+});
+
+document.getElementById('manual-id').addEventListener('change', (e) => {
+  state.selected = e.target.value;
+  document.querySelectorAll('.pedido-row').forEach(r => r.classList.toggle('is-selected', r.dataset.id === String(e.target.value)));
+});
--- a/app/Http/Controllers/ItemController.php
+++ b/app/Http/Controllers/ItemController.php
@@ -0,0 +1,18 @@
+<?php
+namespace App\Http\Controllers;
+
+use Illuminate\Http\Request;
+
+final class ItemController
+{
+    public function store(Request $request)
+    {
+        $data = $request->validate([
+            'quantidade' => ['required', 'integer', 'min:1'],   // 0 e negativos são recusados com 422 antes de qualquer gravação
+            'produto_id' => ['required', 'exists:produtos,id'],
+        ]);
+        $item = Item::create($data + ['pedido_id' => $request->session()->get('pedido')]);
+        return back()->with('ok', 'Item adicionado');
+    }
+}
```
