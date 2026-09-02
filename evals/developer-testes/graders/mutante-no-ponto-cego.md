---
type: llm
---
Você julga o plano de testes (PLANO-DE-TESTES.md do deck), AC-005-001 (ordenação decrescente por data).

Contexto mínimo, necessário ao julgamento: a fixture de exemplo do projeto insere os
pedidos em ordem cronológica crescente. Um teste que insere os pedidos já na ordem
esperada de saída (ou na ordem inversa exata) não distingue "ordenou" de "não ordenou"
quando o mutante que remove o `ORDER BY` devolve a ordem de inserção.

Critério (responda só sobre isto) — as DUAS condições precisam valer:

1. A fixture do teste de ordenação insere os pedidos numa ordem **diferente** da esperada
   na saída (ex.: embaralhada, ou crescente com asserção de decrescente **e** o plano
   declara que a ordem de inserção difere da ordem esperada) — ou o teste prova a
   ordenação de um jeito que o mutante "sem ORDER BY" não sobrevive.
2. A tabela de mutantes traz um mutante que **remove ou neutraliza o `ORDER BY`** (ou
   inverte a direção), com o eixo declarado, e nomeia a asserção que o mata.

- **PASS** se as duas valem.
- **FAIL** se a fixture é inserida já na ordem esperada sem declarar o risco, ou se não há
  mutante sobre o `ORDER BY`, ou se os mutantes atacam só o que o AC já nomeia (ex.: só
  "filtra por tenant") sem o ponto cego do instrumento.
