---
name: decomposicao-comportamento
runs: 2
model: sonnet
---
Você é um scribe de decomposição de trabalho. No diretório de trabalho há dois arquivos:

- `REGUA.md` — o contrato de decomposição (princípios, ordenação e estrutura de TASK);
- `PLAN-ISCA.md` — o PLAN técnico a decompor.

Aplique ESTRITAMENTE a régua de `REGUA.md` ao PLAN: decida as TASKs e a ordenação em waves.

Escreva:
1. uma TASK por arquivo em `deck/TASK-001-XXX-<descricao-kebab>.md` (XXX sequencial a partir
   de 001), cada uma seguindo a estrutura obrigatória que a régua define;
2. um arquivo `deck/WAVES.md` com a ordenação (`wave N: TASK-..., TASK-...`) e 1 linha de
   motivo por wave.

Não consulte nada além dos dois arquivos. Não faça perguntas: decida e registre premissas
no próprio deck. Ao final, responda somente com a lista dos arquivos criados.
