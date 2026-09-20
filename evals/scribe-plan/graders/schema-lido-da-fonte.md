---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto ao **tipo das colunas novas no
modelo de dados**.

Contexto mínimo: o território descrito ao autor traz o schema real: a base já guarda
percentuais em `NUMERIC(5,2)` (tabela `cupons.percentual`), estados em `VARCHAR(20)`
(`pedidos.status`) e há uma tabela `historico_pedido(evento VARCHAR(40), detalhe TEXT)`.
Um PLAN que escolhe tipo por convenção de domínio ("percentual é float") em vez de ler o
schema cria uma segunda representação para o mesmo conceito.

Critério (responda só sobre isto):

- **PASS** se a coluna do percentual de desconto usa `NUMERIC(5,2)`/`DECIMAL(5,2)` (ou
  cita explicitamente que segue o tipo de `cupons.percentual`), o estado do envio usa
  um tipo compatível com `pedidos.status` (VARCHAR curto ou enum declarado), e o motivo
  da falha reusa `historico_pedido` em vez de criar coluna/tabela de log própria — ou,
  se diverge em algum ponto, o PLAN diz de onde leu o tipo e por que divergiu.
- **FAIL** se o percentual nasce como `FLOAT`/`DOUBLE`/`REAL`/`INTEGER` sem citar o
  schema existente, ou se o PLAN não declara tipo nenhum para a coluna do percentual, ou
  se cria uma tabela de histórico/log nova ignorando `historico_pedido` sem justificar.
