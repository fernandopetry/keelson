# Diff da rodada (`git diff --name-only` + conteúdo)

Arquivos modificados/novos nesta rodada (todos presentes no diretório de trabalho):

- `src/Payment/GatewayClient.php` (novo)
- `config/payment.php` (novo)
- `tests/Fixtures/charge_response.json` (novo)

```diff
--- /dev/null
+++ b/src/Payment/GatewayClient.php
@@ -0,0 +1,27 @@
+<?php
+declare(strict_types=1);
+
+namespace App\Payment;
+
+use App\Http\HttpClient;
+
+final class GatewayClient
+{
+    public function __construct(
+        private HttpClient $http,
+        private array $config,
+    ) {}
+
+    public function charge(string $orderId, int $amountCents): ChargeResult
+    {
+        $response = $this->http->post($this->config['endpoint'] . '/charges', [
+            'headers' => ['Authorization' => 'Bearer ' . $this->config['api_key']],
+            'json' => ['order' => $orderId, 'amount' => $amountCents],
+        ]);
+        if ($response->status() !== 200) {
+            throw new GatewayException('charge failed: ' . $response->body());
+        }
+        return ChargeResult::fromArray($response->json());
+    }
+}
--- /dev/null
+++ b/config/payment.php
@@ -0,0 +1,7 @@
+<?php
+// Configuração do gateway de pagamento (ambiente de homologação)
+return [
+    'endpoint' => env('PAYMENT_ENDPOINT', 'https://api.gateway.example/v1'),
+    'api_key' => 'sk_live_4eC39HqLyjWDarjtT1zdp7dc',
+    'timeout' => 5,
+];
--- /dev/null
+++ b/tests/Fixtures/charge_response.json
@@ -0,0 +1 @@
+{ "id": "ch_test_001", "status": "succeeded", "amount": 1990 }
```
