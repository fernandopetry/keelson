# Diff acumulado da wave 1 (`git diff main...HEAD`)

```diff
--- /dev/null
+++ b/src/Export/OrderExportService.php
@@ -0,0 +1,31 @@
+<?php
+declare(strict_types=1);
+
+namespace App\Export;
+
+use App\Order\OrderRepository;
+
+final class OrderExportService
+{
+    public function __construct(private OrderRepository $orders) {}
+
+    /** @return list<ExportRow> */
+    public function export(int $tenantId): array
+    {
+        // busca os pedidos
+        $orders = $this->orders->findByTenant($tenantId);
+        $rows = [];
+        // percorre os pedidos
+        foreach ($orders as $order) {
+            // cria a linha
+            $rows[] = new ExportRow($order);
+        }
+        // retorna as linhas
+        return $rows;
+    }
+}
--- /dev/null
+++ b/src/Export/ExportRow.php
@@ -0,0 +1,40 @@
+<?php
+declare(strict_types=1);
+
+namespace App\Export;
+
+use App\Order\Order;
+
+final class ExportRow
+{
+    private const MAX = 255;
+
+    public function __construct(private Order $order) {}
+
+    public function name(): string
+    {
+        return mb_substr($this->order->customerName(), 0, self::MAX);
+    }
+
+    public function address(): string
+    {
+        return mb_substr($this->order->shippingAddress(), 0, self::MAX);
+    }
+
+    public function notes(): string
+    {
+        return $this->order->notes();
+    }
+
+    public function customerEmail(): string
+    {
+        return $this->order->customerEmail();
+    }
+
+    public function total(): string
+    {
+        return number_format($this->order->total(), 2, '.', '');
+    }
+}
--- /dev/null
+++ b/tests/Export/OrderExportTest.php
@@ -0,0 +1,28 @@
+<?php
+declare(strict_types=1);
+
+namespace Tests\Export;
+
+use App\Export\OrderExportService;
+use Tests\TestCase;
+
+final class OrderExportTest extends TestCase
+{
+    public function testExportaPedidosDoTenant(): void
+    {
+        $this->seedOrders(tenantId: 1, count: 3);
+        $this->seedOrders(tenantId: 2, count: 2);
+        $rows = $this->app(OrderExportService::class)->export(1);
+        self::assertNotEmpty($rows);
+        self::assertGreaterThan(0, count($rows));
+    }
+
+    public function testLinhaTemTotalFormatado(): void
+    {
+        $this->seedOrders(tenantId: 1, count: 1, total: 10.5);
+        $rows = $this->app(OrderExportService::class)->export(1);
+        self::assertSame('10.50', $rows[0]->total());
+    }
+}
--- /dev/null
+++ b/tests/Security/OrderExportScopeTest.php
@@ -0,0 +1,22 @@
+<?php
+declare(strict_types=1);
+
+namespace Tests\Security;
+
+use App\Export\OrderExportService;
+use Tests\TestCase;
+
+/**
+ * @group security
+ */
+final class OrderExportScopeTest extends TestCase
+{
+    public function testPedidoDeOutroTenantNaoAparece(): void
+    {
+        $this->seedOrders(tenantId: 1, count: 2);
+        $this->seedOrders(tenantId: 2, count: 1);
+        $rows = $this->app(OrderExportService::class)->export(1);
+        self::assertCount(2, $rows);
+    }
+}
--- /dev/null
+++ b/tests/Export/ExportRowTest.php
@@ -0,0 +1,24 @@
+<?php
+declare(strict_types=1);
+
+namespace Tests\Export;
+
+use App\Export\ExportRow;
+use Tests\TestCase;
+
+final class ExportRowTest extends TestCase
+{
+    public function testNomeTruncaEm255(): void
+    {
+        $row = new ExportRow($this->orderWith(customerName: str_repeat('a', 300)));
+        self::assertSame(255, mb_strlen($row->name()));
+    }
+
+    public function testEnderecoTruncaEm255(): void
+    {
+        $row = new ExportRow($this->orderWith(shippingAddress: str_repeat('b', 300)));
+        self::assertSame(255, mb_strlen($row->address()));
+    }
+}
```
