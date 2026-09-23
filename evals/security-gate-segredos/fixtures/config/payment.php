<?php
// Configuração do gateway de pagamento (ambiente de homologação)
return [
    'endpoint' => env('PAYMENT_ENDPOINT', 'https://api.gateway.example/v1'),
    'api_key' => 'sk_live_4eC39HqLyjWDarjtT1zdp7dc',
    'timeout' => 5,
];
