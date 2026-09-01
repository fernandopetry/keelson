# Diff da wave 1 (TASK-001-001)

```diff
--- /dev/null
+++ b/src/OrderRepository.php
@@ -0,0 +1,22 @@
+<?php
+
+final class OrderRepository
+{
+    public function __construct(private Db $db) {}
+
+    /** @return Order[] */
+    public function listForTenant(string $tenantId): array
+    {
+        return $this->db->query(
+            'SELECT * FROM orders WHERE tenant_id = :tenant ORDER BY created_at DESC',
+            [':tenant' => $tenantId]
+        );
+    }
+
+    public function getById(string $id): ?Order
+    {
+        return $this->db->queryOne(
+            'SELECT * FROM orders WHERE id = :id',
+            [':id' => $id]
+        );
+    }
+}
--- /dev/null
+++ b/src/OrderController.php
@@ -0,0 +1,24 @@
+<?php
+
+final class OrderController
+{
+    public function __construct(private OrderRepository $repo) {}
+
+    public function index(Request $request): Response
+    {
+        $orders = $this->repo->listForTenant($request->session()->tenantId());
+        return Response::json($orders);
+    }
+
+    public function show(Request $request, string $id): Response
+    {
+        $order = $this->repo->getById($id);
+        if ($order === null) {
+            return Response::notFound();
+        }
+        return Response::json($order->toArray());
+    }
+}
--- /dev/null
+++ b/tests/OrderTest.php
@@ -0,0 +1,58 @@
+<?php
+
+final class OrderTest extends ApiTestCase
+{
+    public function test_index_requires_authentication(): void
+    {
+        $this->getAnonymous('/orders')->assertStatus(401);
+    }
+
+    public function test_index_returns_only_own_tenant_orders(): void
+    {
+        $this->seedOrder('tenant-a', 'o-a1');
+        $this->seedOrder('tenant-a', 'o-a2');
+        $this->seedOrder('tenant-b', 'o-b1');
+        $res = $this->getAs('tenant-a', '/orders');
+        $res->assertStatus(200);
+        $res->assertJsonIds(['o-a2', 'o-a1']);
+    }
+
+    public function test_index_orders_newest_first(): void
+    {
+        $this->seedOrder('tenant-a', 'o-1', at: '2026-01-01');
+        $this->seedOrder('tenant-a', 'o-2', at: '2026-02-01');
+        $this->getAs('tenant-a', '/orders')->assertJsonIds(['o-2', 'o-1']);
+    }
+
+    public function test_show_requires_authentication(): void
+    {
+        $this->getAnonymous('/orders/o-a1')->assertStatus(401);
+    }
+
+    public function test_show_returns_own_order(): void
+    {
+        $this->seedOrder('tenant-a', 'o-a1');
+        $res = $this->getAs('tenant-a', '/orders/o-a1');
+        $res->assertStatus(200);
+        $res->assertJsonPath('id', 'o-a1');
+    }
+
+    public function test_show_returns_404_for_unknown_id(): void
+    {
+        $res = $this->getAs('tenant-a', '/orders/018f3b1e-0000-7000-8000-c0ffee000000');
+        $res->assertStatus(404);
+    }
+
+    public function test_show_returns_json_shape(): void
+    {
+        $this->seedOrder('tenant-a', 'o-a1');
+        $this->getAs('tenant-a', '/orders/o-a1')
+            ->assertJsonStructure(['id', 'tenant_id', 'total', 'created_at']);
+    }
+}
```
