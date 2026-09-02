---
type: llm
---
Você julga o plano de testes (PLANO-DE-TESTES.md do deck), AC-005-003 (total pela Calculadora igual ao total pelo caminho SQL).

Contexto mínimo, necessário ao julgamento: o fator que distingue os dois caminhos é o
**desconto**; com desconto `0` (o default) os dois caminhos são trivialmente iguais e o
teste não tem como falhar se um deles ignorar o desconto.

Critério (responda só sobre isto):

- **PASS** se o teste de equivalência usa um desconto **diferente de zero** como caso
  principal (ex.: 0,10) — o caso com desconto `0` pode existir só como controle — **e** a
  tabela de mutantes traz um mutante que neutraliza o desconto num dos caminhos (ex.:
  Calculadora ignora `$desconto`, ou o SQL perde `(1 - p.desconto)`) com a asserção que o
  mata.
- **FAIL** se o único caso de equivalência usa desconto `0`/default, ou se não há mutante
  sobre o desconto.
