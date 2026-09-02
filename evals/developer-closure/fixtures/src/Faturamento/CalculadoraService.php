<?php
declare(strict_types=1);

namespace App\Faturamento;

final class CalculadoraService
{
    private const LIMIAR_VOLUME = 100;   // acima disto o desconto por volume se aplica (DEC-004-002)
    private const DESCONTO_VOLUME = 0.10;

    /**
     * Calcula o total da fatura do mês.
     * Regra de negócio: o desconto por volume vale para o total inteiro, não só para o excedente (DEC-004-002).
     */
    public function total(array $itens): float
    {
        // soma os itens
        $bruto = 0.0;
        foreach ($itens as $item) {
            // acumula o preço do item vezes a quantidade
            $bruto += $item['preco'] * $item['quantidade'];
        }
        // aplica o desconto se passou do limiar
        if (count($itens) > self::LIMIAR_VOLUME) {
            return round($bruto * (1 - self::DESCONTO_VOLUME), 2);
        }
        // retorna o bruto
        return round($bruto, 2);
    }
}
