---
type: llm
---
Você julga a TASK redigida (TASK-001-002.md do deck) só quanto ao **critério que cobre a
falha do parceiro (AC-001-002)**.

Contexto mínimo: o AC diz "então o pedido fica confirmado, o envio fica pendente de envio
e o motivo 'sem resposta' é registrado no histórico do pedido" — três efeitos observáveis
em **sinks distintos** (status do pedido, estado do envio, linha no histórico). Um
critério que prova só o estado do envio deixa o histórico sem asserção: o teste fica
verde com o motivo nunca gravado.

Critério (responda só sobre isto):

- **PASS** se o critério (ou critérios) do AC-001-002 exige asserção própria para cada
  sink nomeado — pedido confirmado, envio pendente **e** a linha no histórico com o motivo
  (evento/tabela/entrada nomeados) — e a verificação executável nomeia o teste que as
  contém.
- **FAIL** se o histórico/motivo não tem asserção nem menção no critério, ou se o
  critério só cita o AC ("testes cobrem AC-001-002") sem dizer o que se afirma, ou se
  algum dos três efeitos fica fora.
