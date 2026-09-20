---
type: llm
---
Você julga a crítica de produto (CRITICA.md do deck) só quanto a **um requisito que serve
a persona errada**.

Contexto mínimo: a demanda declara que o **gerente da parceria não usa o painel** — ele
recebe o relatório de descontos por e-mail, e o relatório está fora do escopo. A SPEC
criticada traz um requisito em que **o gerente da parceria abre o painel de pedidos e vê a
lista de descontos do mês** (com AC). Isso contradiz a persona declarada e reintroduz pelo
lado o relatório que está fora do escopo.

Critério (responda só sobre isto):

- **PASS** se a crítica aponta que o requisito do gerente no painel contradiz a persona
  declarada (não usa o painel) e/ou o out-of-scope do relatório de descontos, como risco
  ou pergunta.
- **FAIL** se a crítica não menciona esse requisito, ou o trata como normal (ex.: só pede
  mais detalhes da lista) sem apontar a contradição com a persona/escopo.
