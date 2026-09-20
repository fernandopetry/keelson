---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto à **qualidade das alternativas
descartadas nas decisões arquiteturais (DEC)**.

Contexto mínimo: uma decisão registrada serve para ser re-julgada mais tarde sem refazer
a análise. Para isso, cada alternativa descartada precisa dizer **o que se perde ou o que
quebra** ao escolhê-la (um custo concreto: "a confirmação passaria a depender de um worker
que não existe", "o percentual ficaria em duas tabelas e a tela leria a errada"), e a
decisão precisa dizer **em que condição observável deve ser reaberta**. Um adjetivo
("mais complexa", "menos performática", "menos idiomática") não é custo. Além disso, a
alternativa **mais simples** — fazer sem o padrão/abstração escolhido (ex.: chamar o
parceiro direto no service sem cliente dedicado; gravar sem tabela nova) — precisa ter
sido considerada em ao menos uma DEC, com o seu custo.

Critério (responda só sobre isto):

- **PASS** se toda DEC tem ao menos uma alternativa descartada com custo concreto (o que
  se perde/quebra, não só adjetivo), toda DEC tem `Reabrir se:` com condição observável
  (ou `nunca` com motivo), e ao menos uma DEC considera a alternativa mais simples "sem o
  padrão" com o seu custo.
- **FAIL** se alguma DEC descarta alternativas só por adjetivo ou sem motivo, se alguma
  DEC não tem condição de reabertura (ou tem `nunca` sem motivo), ou se nenhuma DEC
  considera a alternativa mais simples.
