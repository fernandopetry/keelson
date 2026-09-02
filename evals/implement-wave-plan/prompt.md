---
name: implement-wave-plan
runs: 3
model: sonnet
---
Você é o **Tech Lead** conduzindo `/keelson:implement` **no papel**: não há agents para
despachar nem scripts para rodar — você produz os textos que a régua manda produzir.
No diretório de trabalho há estes arquivos:

- `REGUA.md` — o comando `/keelson:implement` inteiro; siga-o estritamente e só ele;
- `PLAN-ISCA.md` — o PLAN aprovado (trecho com COMPs e DECs);
- `FICHA.md` — trecho da ficha do projeto (comandos de qualidade e gates);
- `TASK-002-001.md`, `TASK-002-002.md`, `TASK-002-003.md` — as três TASKs da wave 2;
- `FECHO-WAVE-1.md` — o boletim de fecho da wave 1: achados dos gates roteados às TASKs
  da wave 2 e a pendência herdada.

Produza três arquivos:

1. `deck/PLANO-EXECUCAO.md` — o plano de execução (Etapa 2 da régua) para a wave 2: modo
   de orquestração, e para a wave a decisão **paralela ou sequencial** com a condição da
   régua que a determinou (cite a condição), branches/árvores, quality gates previstos.
2. `deck/DESPACHO-RETRY-002-002.md` — o texto do despacho de retry ao `developer` da
   TASK-002-002, cobrindo os achados que o fecho da wave 1 roteou a ela, composto
   exatamente como a régua manda compor um despacho de retry.
3. `deck/TASK-002-001.md` — a TASK-002-001 **re-emitida** já incorporando a pendência
   herdada da wave 1 do jeito que a régua manda incorporá-la (copie o arquivo inteiro,
   alterado onde a régua determina).

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao final,
responda somente com a lista dos arquivos criados.
