<?php
declare(strict_types=1);

namespace App\Payment;

use App\Http\HttpClient;

final class GatewayClient
{
    public function __construct(
        private HttpClient $http,
        private array $config,
    ) {}

    public function charge(string $orderId, int $amountCents): ChargeResult
    {
        $response = $this->http->post($this->config['endpoint'] . '/charges', [
            'headers' => ['Authorization' => 'Bearer ' . $this->config['api_key']],
            'json' => ['order' => $orderId, 'amount' => $amountCents],
        ]);
        if ($response->status() !== 200) {
            throw new GatewayException('charge failed: ' . $response->body());
        }
        return ChargeResult::fromArray($response->json());
    }
}
