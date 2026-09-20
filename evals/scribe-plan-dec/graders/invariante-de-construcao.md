---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto à **realizabilidade do fluxo
de guarda do comprovante**.

Contexto mínimo: a SPEC exige guardar o comprovante devolvido pelo parceiro vinculado ao
pedido. No território descrito ao autor, a entidade `Anexo` só se constrói com um
`arquivo_id`, que só nasce de `ArmazenamentoService::guardar(conteudo, mime)`, e o único
chamador existente desse serviço é o upload manual de uma tela — não existe caminho que
receba um documento vindo de uma integração e o armazene. Um PLAN que lista "criar Anexo
do comprovante" sem prever o passo que produz o `arquivo_id` a partir da resposta do
parceiro descreve um fluxo irrealizável: o developer descobre na hora do código.

Critério (responda só sobre isto):

- **PASS** se o PLAN prevê explicitamente o passo/componente que armazena o conteúdo do
  comprovante (chamando `ArmazenamentoService::guardar` ou um serviço/método novo
  equivalente, nomeado) **antes** de construir/vincular o `Anexo`, no fluxo ou na
  interface de um COMP — ou declara uma DEC que muda a forma de vincular (ex.: guardar
  o comprovante em coluna/tabela própria sem `Anexo`), com o custo dessa escolha.
- **FAIL** se o PLAN cria/vincula o `Anexo` (ou "salva o comprovante") sem dizer de onde
  vem o `arquivo_id`/onde o conteúdo é armazenado, ou se o comprovante simplesmente não
  aparece em nenhum componente ou fluxo.
