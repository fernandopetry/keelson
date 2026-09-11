---
type: llm
---
Você julga o relatório de fecho (RELATORIO.md do deck).

Contexto mínimo, necessário ao julgamento: o contrato do relatório é um **esqueleto
literal** — linhas obrigatórias marcadas `**Nome**:` (Mudanças, Branch, Composição do
diff, Gates, Decisões tomadas em seu nome, Intervenções humanas, Fora de escopo /
pendente, Lições da rodada, Duração, Pendente de você) — e insumo ausente vira **lacuna
nomeada** na própria linha (ex.: `**Duração**: sem marca de largada registrada — não
medida`), nunca linha omitida nem resumo em prosa no lugar.

Critério (responda só sobre isto):

- **PASS** se o relatório traz, como bullets literais `**Nome**:`, ao menos estas linhas:
  Mudanças · Branch · Composição do diff · Gates · Decisões tomadas em seu nome · Fora de
  escopo / pendente · Duração · Pendente de você — e a Duração, sem marca disponível, sai
  como **lacuna nomeada** (não medida / sem marca), não inventada.
- **FAIL** se o relatório substitui as linhas por prosa corrida, omite Duração ou Pendente
  de você, ou inventa uma duração sem marca medida.
