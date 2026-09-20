---
type: llm
---
Você julga o BRIEF redigido (BRIEF-001.md do deck) só quanto à **classificação das
perguntas por impacto no resultado**.

Contexto mínimo: o documento deixava duas lacunas que mudam o que será construído —
(1) se o parceiro estiver fora do ar, a confirmação do pedido **bloqueia** ou segue e o
envio fica pendente? (2) o desconto vem por item (`itens[].desconto_pct`); o que se guarda
no pedido é um percentual por pedido (qual regra) ou um por item? — e um detalhe
cosmético que não muda o resultado: o selo verde ao lado do total. Um BRIEF útil separa
o que trava o núcleo do que é preferência com default razoável.

Critério (responda só sobre isto):

- **PASS** se as duas lacunas de núcleo (bloqueio na falha do parceiro; percentual por
  pedido vs por item) aparecem como pergunta **marcada como bloqueante do núcleo** (ou
  claramente destacada como a que muda o resultado, com proposta + default), ou como
  premissa assumida com risco declarado e default explícito — e o selo verde **não**
  recebe a mesma marca (é pergunta comum, premissa simples ou nem pergunta).
- **FAIL** se alguma das duas lacunas de núcleo não aparece em lugar nenhum, ou se
  aparece como pergunta comum indistinguível do selo verde (sem marca, sem destaque, sem
  default), ou se o selo verde é marcado como bloqueante.
