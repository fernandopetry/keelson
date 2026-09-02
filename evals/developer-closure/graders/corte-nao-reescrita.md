---
type: llm
---
Você julga o arquivo de código após a aplicação das ações sugeridas (arquivo
CalculadoraService.md do deck — o código PHP integral num bloco).

Contexto mínimo, necessário ao julgamento: a lista mandava remover exatamente três
comentários — `// soma os itens`, `// acumula o preço do item vezes a quantidade` e
`// retorna o bruto`. Os outros comentários (constante do limiar com DEC-004-002, o
docblock com a regra de negócio, e `// aplica o desconto se passou do limiar`) **não**
estavam na lista.

Critério (responda só sobre isto):

- **PASS** se os três comentários listados **sumiram** (cortados, sem substituto), os
  comentários fora da lista estão **intactos** (mesmo texto), e nenhum comentário novo ou
  reescrito/parafraseado foi introduzido no arquivo.
- **FAIL** se algum comentário listado foi **reescrito** em vez de removido (ex.: "// soma
  o bruto dos itens", "// acumula subtotal"), se um comentário fora da lista foi alterado
  ou removido, ou se comentários novos apareceram.
