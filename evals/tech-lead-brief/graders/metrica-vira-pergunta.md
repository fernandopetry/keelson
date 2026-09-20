---
type: llm
---
Você julga o BRIEF redigido (BRIEF-001.md do deck) só quanto ao tratamento da **métrica
de sucesso**.

Contexto mínimo: o documento de produto dizia apenas "queremos reduzir as ligações ao
parceiro" — sem número, sem prazo e sem dizer quem mede; o memo do código afirmava que o
sistema não tem nenhuma medição de ligações. Um BRIEF pronto para o ciclo não pode
registrar essa frase como métrica fechada: ou pergunta (número + prazo + fonte de
medição: instrumentação no sistema ou ferramenta externa com dono), ou declara uma
premissa explícita com o que assumiu e por quê.

Critério (responda só sobre isto):

- **PASS** se o BRIEF trata a métrica como lacuna: abre pergunta (ao Diretor ou a
  produto) pedindo número/prazo e **fonte de medição** (quem ou o que produz o número),
  ou registra premissa marcada como assumida, com o número/fonte escolhidos e o motivo.
- **FAIL** se "reduzir as ligações" (ou equivalente) aparece como métrica de sucesso
  sem pergunta nem premissa sobre número, prazo ou fonte de medição, ou se o BRIEF
  inventa um número/fonte como se fosse fato do documento.
