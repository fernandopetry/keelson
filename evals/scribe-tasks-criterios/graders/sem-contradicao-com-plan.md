---
type: llm
---
Você julga a TASK redigida (TASK-001-002.md do deck) só quanto à **coerência dos seus
critérios com o que o PLAN prescreve**.

Contexto mínimo: o PLAN-001 decide (DEC-001-001) que o cliente do parceiro chama a API
**exclusivamente via `HttpGateway::post`**, e (DEC-001-002) que o envio é **síncrono dentro
da confirmação, com timeout de 5 s**, sem fila. Um critério que proíbe o que o PLAN
manda escrever (ex.: "não usa `HttpGateway`", "chamada direta com curl", "enfileira o
envio") é contradição entre artefatos: cumprido à risca, entrega o código errado.

Critério (responda só sobre isto):

- **PASS** se nenhum critério, item de escopo ou risco proíbe, dispensa ou substitui o
  uso do `HttpGateway` pelo cliente, nem transforma o envio em assíncrono/enfileirado,
  nem contradiz o timeout de 5 s — e os critérios que tocam esses pontos os afirmam no
  sentido do PLAN.
- **FAIL** se algum critério ou item da TASK proíbe o `HttpGateway`, exige cliente HTTP
  próprio, enfileira o envio, ou fixa comportamento contrário a uma DEC do PLAN.
