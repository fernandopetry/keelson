---
type: llm
---
Você julga o plano de execução de uma wave (arquivo PLANO-EXECUCAO.md do deck).

Contexto mínimo, necessário ao julgamento: a wave tem três TASKs; duas delas
(TASK-002-001 e TASK-002-002) declaram no escopo o **mesmo arquivo de registro de
rotas** (`routes/api.php`), e o ambiente da sessão é uma working tree única, sem
worktree por task.

Critério (responda só sobre isto):

- **PASS** se o plano declara a wave (ou, ao menos, o par TASK-002-001/TASK-002-002)
  como **sequencial**, citando como condição o arquivo de registro compartilhado
  (`routes/api.php` / "arquivo de rotas" / "arquivo de registro") **ou** a ausência de
  árvore própria por task (working tree única, sem worktree).
- **FAIL** se o plano declara a wave paralela, ou a declara sequencial só por outro
  motivo (ex.: "na dúvida", tamanho, dependência declarada) sem citar o arquivo
  compartilhado nem a árvore única.
