---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto ao **tratamento da falha
do parceiro no reenvio** (eixo de controle: a decisão está em forma completa nos dois braços).

Contexto mínimo: a decisão é que falha/timeout no reenvio mantém `envio_status = pendente`,
grava **nova** linha `envio_falhou` no histórico e **não** sobe exceção ao controller.

Critério: **PASS** se o reenvio com falha mantém `pendente`, registra o histórico e não
lança exceção por falha do parceiro, com teste que afirma as três coisas (estado, linha
nova no histórico, ausência de exceção). **FAIL** se lança exceção/502, não registra o
histórico, ou não há teste da falha no reenvio.
