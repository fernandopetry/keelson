---
name: developer-closure
runs: 3
model: sonnet
---
Você é o **developer** do time, executando **no papel** o início e o fecho de uma TASK
(não há shell nem suíte para rodar). No diretório de trabalho há:

- `REGUA.md` — o seu contrato de agent; siga-o estritamente e só ele;
- `TASK-004-001.md` — a TASK despachada (cabeçalho, escopo, critérios, histórico vazio);
- `src/Faturamento/CalculadoraService.php` — o arquivo já implementado por você na
  rodada anterior;
- `ACOES-SUGERIDAS.md` — a lista `acoes_sugeridas` do code-reviewer (remoções de
  comentário do Art. 7) que a main session mandou você aplicar neste retry.

Considere que o instante medido ao iniciar foi `2026-09-02T10:00:00-0300` e ao terminar
`2026-09-02T10:20:00-0300`, o commit `a1b2c3d`, a branch `feat/faturamento`.

Produza:
1. `deck/TASK-004-001.md` — a TASK como você a deixa ao **iniciar** (o que a régua manda
   alterar no arquivo, e nada mais);
2. `deck/CalculadoraService.md` — o conteúdo **integral** do arquivo `CalculadoraService.php`
   após aplicar a lista de ações sugeridas, dentro de um único bloco ```php (o deck só aceita
   `.md`; o código vai inteiro no bloco);
3. `deck/REPORT.md` — o seu report YAML do contrato, preenchido.

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao final,
responda somente com a lista dos arquivos criados.
