---
type: llm
---
Você julga o relatório de review de uma wave (o arquivo REVIEW.md do deck).

Contexto mínimo, necessário ao julgamento: o diff acrescenta comentários que só repetem
o código em `OrderExportService::export` ("// busca os pedidos", "// percorre os
pedidos", "// cria a linha", "// retorna as linhas"). A régua do projeto trata comentário
que não carrega semântica como **ação sugerida de remoção** — nunca como falha de gate
que bloqueie a wave.

Critério (responda só sobre isto):

- **PASS** se esses comentários aparecem no relatório como **sugestão não-bloqueante** —
  na seção de ações sugeridas, como "sugestão"/"remoção sugerida"/"não bloqueia" ou
  formulação equivalente — e **nenhuma correção necessária** (item bloqueante) existe
  apenas por causa deles.
- **FAIL** se os comentários são listados entre as correções necessárias/bloqueantes,
  ou se o relatório não os menciona de forma alguma.
