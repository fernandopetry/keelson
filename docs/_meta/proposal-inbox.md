# Fila de propostas de consumidores (decisão 4.111)

Consumidores do keelson produzem propostas de melhoria do plugin (`PROPOSTA_PLUGIN`, via
`agile-coach` em modo consumidor) nos próprios ledgers — com diff literal, contra a versão
instalada. Esta fila é o **lado do mantenedor**: cada proposta que chega ao Diretor é
registrada aqui **antes do parecer**, e nenhuma entra em doutrina sem passar por esta fila.

**Contrato**:

- **Registrar na chegada**: a sessão que recebe postmortem/ledger/mensagem com propostas
  escreve a linha **antes** de emitir parecer — origem abstraída (4.72: só o id do
  registro no ledger de origem, ex. `LRN-031`, sem nome/paths do consumidor), 1 linha do
  padrão genérico, alvo no plugin.
- **Fechar na leva**: a leva que aplica/recusa atualiza o Estado — `aplicada (4.x)` com a
  decisão que a absorveu, ou `recusada (motivo curto)`. `recebida` que atravessa uma leva
  é pendência visível, não backlog silencioso.
- **Reincidência referencia a linha anterior** — é o sinal de que o elo falhou uma vez.
- A fila carrega **ponteiros, nunca texto de doutrina** — o dono da regra é o arquivo dela.

| Data | Origem | Padrão proposto | Alvo | Estado |
|---|---|---|---|---|
| 2026-08-04 | LRN-014 (reincidente ×1 — 1ª proposta de 2026-07-23 nunca aplicada) | Aresta entre TASKs irmãs da mesma wave tem dono declarado no Escopo | commands/tasks.md | aplicada (4.106) |
| 2026-08-04 | LRN-031 | Literal de comando/critério conferido na fonte real; invariante estrutural por símbolo, nunca por caminho | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-032 | Roteiro de gate 9 hierárquico inclui passo que cruza a fronteira do agrupamento | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-034 | Predicado de escopo nasce com fixture de dois pais e critério de mutação no gate 1 | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-035 | Superfície de API e schema do PLAN verificados contra a fonte real, nunca deduzidos | commands/plan.md | aplicada (4.108) |
| 2026-08-04 | LRN-036 | Fechamento de achado multi-sujeito re-lê o FR/AC de origem e cobre todos os sujeitos nomeados | guidelines/core/CODE-REVIEW.md | aplicada (4.109) |
| 2026-08-04 | LRN-037 | Ausência de prova conta para o teto de retry; "mecânico" vai na proposta da escalação | guidelines/core/CODE-REVIEW.md | aplicada (4.110) |
| 2026-08-04 | LRN-038 (2ª ocorrência — a 1ª virou workaround de projeto e nunca escalou) | `qa` recebe o grant `mcp__playwright__*` que a própria doutrina manda usar; a classe vira check mecânico | agents/qa.md · scripts/check-agents.sh | aplicada (4.105) |
