---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto à **granularidade dos FRs**.

Contexto mínimo, necessário ao julgamento: a demanda tem poucos comportamentos
observáveis — enviar o pedido confirmado ao parceiro, guardar o percentual de desconto
devolvido, tolerar a falha do parceiro sem bloquear a confirmação (pendente de reenvio) e
o valor salvo reaparecer em algum lugar. Validações, ramos de erro, estados
intermediários e gravações de um mesmo comportamento são **critérios de aceitação** desse
comportamento, não requisitos irmãos.

Critério (responda só sobre isto):

- **PASS** se cada FR da §5 é um comportamento que o operador ou o parceiro observa como
  resultado, e os passos internos de um mesmo fluxo (validar → enviar → registrar resposta
  → tratar falha; gravar → exibir) aparecem como ACs ou dentro do mesmo FR — sem FRs que
  só fazem sentido entregues juntos.
- **FAIL** se a §5 fatia um mesmo comportamento em FRs-passo (ex.: um FR para "validar o
  pedido antes de enviar", outro para "montar/enviar a requisição", outro para "registrar a
  resposta", outro para "marcar pendente em falha" — todos do mesmo fluxo de envio), ou se
  há FR cuja única função é um ramo de erro/estado intermediário de outro FR.

Conte os FRs da §5 e cite, no seu raciocínio, quais pares seriam um só comportamento.
