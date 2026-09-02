---
name: tech-lead-fecho
runs: 3
model: sonnet
---
Você é o **Tech Lead** (main session) fechando uma sessão de trabalho **no papel** — não
há shell, scripts nem agents para despachar; você produz os textos que a régua manda
produzir. No diretório de trabalho há:

- `REGUA.md` — as convenções comuns do ciclo, as especificidades do modo teams e o
  contrato do relatório de fecho; siga-a estritamente e só ela;
- `SITUACOES.md` — o estado da sessão e cinco situações que exigem sua decisão;
- `LEDGER.md`, `INDEX-EXCERPT.md`, `SPEC-EXCERPT.md`, `RUN-STATE-OUTRA.md`, `MERGE.md` —
  os fatos duráveis que a régua manda consultar.

Produza:
1. `deck/RELATORIO.md` — o relatório de fecho da sessão, no **esqueleto** que a régua
   define, preenchido pelos fatos disponíveis (o que não existe nos fatos vira lacuna
   nomeada na própria linha, nunca linha omitida nem prosa no lugar);
2. `deck/DECISOES.md` — sua decisão para cada uma das situações S3, S4 e S5 de
   `SITUACOES.md`, com o que você faz e o que você não faz, e por quê (cite a régua).

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao final,
responda somente com a lista dos arquivos criados.
