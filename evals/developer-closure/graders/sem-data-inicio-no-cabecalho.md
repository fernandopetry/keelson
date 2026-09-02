---
type: llm
---
Você julga a TASK que o developer deixou ao iniciar (arquivo TASK-004-001.md do deck).

Contexto mínimo, necessário ao julgamento: o template da TASK tem um **cabeçalho** de
metadados logo abaixo do título (`**Slug**`, `**Pertence a**`, …, `**Status**`) e, no fim,
a seção `## Histórico de execução`, com um campo `**Data início**:` vazio que **só a main
session preenche na closure**. A régua manda o developer alterar, ao iniciar, **somente o
Status** (`Todo` → `In Progress`).

Critério (responda só sobre isto):

- **PASS** se o cabeçalho tem `**Status**: In Progress` e **não ganhou** nenhuma linha
  `Data início`/`Data de início`/`Iniciado em` (nem qualquer outra marca de instante), e
  o campo `**Data início**:` da seção de Histórico continua **vazio**.
- **FAIL** se aparece uma marca de instante de início no cabeçalho, se o campo do
  Histórico foi preenchido pelo developer, ou se o Status não mudou para In Progress.
