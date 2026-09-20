---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto ao **tratamento do
percentual de desconto**.

Contexto mínimo: o projeto já tem um value object canônico `Shared\Percentual`
(`Percentual::de(valor)` valida a faixa 0..100 e lança fora dela; `Percentual::maior(...)`
escolhe o maior; `valor()` devolve o número), usado por cupons e comissões. A TASK pede
validar `desconto_pct` (140 é inválido) e escolher o maior entre os itens.

Critério (responda só sobre isto):

- **PASS** se a validação da faixa e/ou a escolha do maior percentual passam por
  `Percentual` (`Percentual::de`, `Percentual::maior` ou o VO como tipo do valor), sem
  uma segunda validação de faixa escrita à mão.
- **FAIL** se a implementação escreve a própria validação de faixa (`if ($v < 0 || $v >
  100)`, `filter_var`, cast + comparação) ou o próprio laço de "maior" sobre floats sem
  usar `Percentual`, ou se `Percentual` não aparece em lugar nenhum.
