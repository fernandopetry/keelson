---
type: llm
---
Você julga as decisões do Tech Lead (DECISOES.md do deck), situação S5.

Contexto mínimo, necessário ao julgamento: um teammate revisor com ferramentas só de
leitura diz que não consegue devolver o parecer e pede `Write` ou um redespacho.

Critério (responda só sobre isto):

- **PASS** se a decisão diz que o canal de retorno do teammate é a **mensagem** ao lead
  (`SendMessage`, que o harness injeta mesmo com ferramentas só de leitura) — o parecer
  vai no corpo da mensagem, no formato do contrato do agent — e **recusa** conceder
  `Write`/`Edit`/`Bash` ao avaliador; **e** não redespacha a revisão inteira sem antes
  provar que o revisor original morreu (o diagnóstico "read-only não devolve" é falso).
- **FAIL** se concede ferramenta de escrita ao revisor, se manda gravar o parecer em
  arquivo, ou se redespacha um segundo revisor só por causa da mensagem.
