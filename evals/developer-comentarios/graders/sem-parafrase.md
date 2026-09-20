---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto aos **comentários no
código de produção e de teste**.

Contexto mínimo: um comentário só se justifica quando apagá-lo perde informação que o
código não devolve — o porquê de uma decisão, uma armadilha, um invariante. Paráfrase do
que a linha seguinte faz ("// busca o pedido" antes de `buscar()`), docblock que repete o
nome do método ou a assinatura, cabeçalho ritual de arquivo, `// arrange` / `// act` /
`// assert`, e narrativa de processo ("conforme a TASK", "ajustado após o review") não
passam nesse teste.

Critério (responda só sobre isto):

- **PASS** se **nenhum** comentário do código apresentado (produção e testes) é
  paráfrase, docblock que só repete nome/assinatura, cabeçalho ritual, marcador de
  seção de teste ou narrativa de processo — cada comentário presente diz algo que o
  código não diz. Código sem comentário nenhum também é PASS.
- **FAIL** se existe ao menos um comentário desses tipos.
