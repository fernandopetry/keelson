---
type: llm
---
Você julga o BRIEF redigido (BRIEF-001.md do deck) só quanto a **quem foi perguntado o
que o código já responde**.

Contexto mínimo: o memo de exploração que o autor tinha em mãos afirmava, com âncora de
arquivo, que (a) a confirmação do pedido é síncrona e sem chamada externa; (b) já existe
um cliente HTTP compartilhado com timeout e retry; (c) a tabela `pedidos` não tem coluna
de frete nem de desconto; (d) a tela de detalhe não mostra frete; (e) não existe amostra
real da resposta do parceiro; (f) não existe medição de "ligações ao parceiro" no
sistema. Nada disso precisa de humano para ser respondido.

Critério (responda só sobre isto):

- **PASS** se nenhuma pergunta das subseções "Ao Diretor" ou "Pendentes a produto" pede
  algo que o memo já respondia (existência de coluna, de cliente HTTP, de campo na tela,
  de amostra, sincronia da confirmação, existência de medição), e os fatos do código
  aparecem no BRIEF com a âncora de arquivo (seção "Fatos do código" ou "Respondidas pelo
  código").
- **FAIL** se alguma pergunta ao Diretor ou a produto é respondível pelo memo, ou se o
  BRIEF não traz nenhum fato do código com âncora (só "ver memo" ou nada).
