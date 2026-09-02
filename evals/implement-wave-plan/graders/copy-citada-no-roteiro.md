---
type: llm
---
Você julga o texto de um despacho de retry (arquivo DESPACHO-RETRY-002-002.md do deck)
e, se existir, o plano de execução (PLANO-EXECUCAO.md).

Contexto mínimo, necessário ao julgamento: um achado de gate 11 trocou a copy visível de
um botão de **"Salvar rascunho"** para **"Guardar rascunho"** (a copy antiga não existe
mais no código). O roteiro de gate 9 de **outra** TASK da wave (TASK-002-003) cita
literalmente "Salvar rascunho" em dois passos ainda não executados.

Critério (responda só sobre isto):

- **PASS** se o despacho (ou o plano) determina que os artefatos de prova que citam a
  copy antiga sejam **reescritos junto** — nomeando o roteiro de gate 9 da TASK-002-003
  (ou "todo roteiro/critério que cite 'Salvar rascunho'", com varredura pela string
  antiga nos artefatos) — para que o QA não reprove código correto procurando um texto
  que a tela não produz mais.
- **FAIL** se a troca de copy é tratada só como mudança de código, se o roteiro da
  TASK-002-003 não é mencionado (nem por varredura pela string antiga), ou se o texto
  deixa a reconciliação para "o qa ver na execução".
