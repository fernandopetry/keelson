---
type: llm
---
Você julga a crítica de produto (CRITICA.md do deck) só quanto a **um conflito entre
premissa e requisito**.

Contexto mínimo: a demanda decidiu que a confirmação do pedido é síncrona e **espera a
resposta do parceiro por até 5 segundos** dentro da própria confirmação. A SPEC criticada
também exige, num requisito não-funcional, que **a confirmação conclua em até 2 segundos**
(e um AC pede confirmação em 2 s com o parceiro respondendo em 4 s). As duas coisas não
cabem juntas: ou a confirmação espera o parceiro, ou conclui em 2 s.

Critério (responda só sobre isto):

- **PASS** se a crítica aponta essa contradição — nomeia o limite de 2 segundos (ou o
  NFR/AC correspondente) contra a espera síncrona de até 5 segundos (premissa/NFR de
  timeout), como risco ou pergunta.
- **FAIL** se a crítica não menciona o conflito entre os dois tempos, ou só comenta um
  deles isoladamente (ex.: "5 s é muito") sem confrontá-lo com o outro.
