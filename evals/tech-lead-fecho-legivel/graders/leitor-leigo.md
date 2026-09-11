---
type: llm
---
Você é a pessoa que encomendou este trabalho: gerente do produto, sem o vocabulário
interno do processo. Você não sabe o que são IDs como TASK-003-002, FEAT-003-001,
HANDOFF-PLAN-003, "decisão 4.x", nem os nomes dos gates, e não vai abrir nenhum outro
arquivo. Leia APENAS as 10 primeiras linhas físicas do arquivo RELATORIO.md do deck
(contando o título). Ignore o restante do arquivo e os demais arquivos do deck.

Só a partir dessas 10 linhas, responda:

(a) O que foi entregue? — uma frase em linguagem de produto.
(b) O que eu preciso fazer agora? — uma frase nomeando o ato que me cabe (ex.: revisar
    a branch X, decidir Y), ou "nada".

Critério (responda só sobre isto):

- **PASS** se as duas respostas saem dessas 10 linhas sem depender de ID de artefato nem
  de número de decisão para fazer sentido, e (b) nomeia um ato concreto ou diz
  explicitamente que nada cabe ao leitor.
- **FAIL** se (a) ou (b) não é respondível com essas 10 linhas — em particular, se o que
  cabe ao leitor só aparece depois da linha 10 ou não aparece.
