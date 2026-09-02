---
type: llm
---
Você julga a TASK re-emitida (arquivo TASK-002-001.md do deck).

Contexto mínimo, necessário ao julgamento: a wave anterior deixou uma pendência para esta
TASK — a gravação por item dentro do laço de importação precisa ser **idempotente por
SKU (upsert)** para **toda** escrita que o laço faz; o laço grava quatro entidades por
linha (produto, preço, estoque inicial, vínculo de fornecedor).

Critério (responda só sobre isto):

- **PASS** se a pendência entrou como item **explícito da seção "Critérios de pronto"**
  (checklist verificável), prescrevendo a **condição com fechamento contável** — "toda
  escrita por item dentro do laço é idempotente; N escritas no laço → N provas de
  reprocessamento sem duplicação" ou formulação equivalente (uma prova por escrita,
  contagem que fecha; instância citada é ilustração) — e não apenas como prosa no
  Contexto ou na Implementação sugerida.
- **FAIL** se a pendência aparece só em Contexto/Implementação sugerida/nota, se o critério
  cita só uma das escritas (ex.: só "preço") sem a condição nem a contagem, ou se a
  pendência não foi incorporada.
