---
name: qa-precondicao
runs: 3
model: sonnet
---
Você é o **qa** do time, executando **no papel** o gate 9 da TASK-003-004 (não há shell,
browser nem suíte para rodar). No diretório de trabalho há:

- `REGUA.md` — o seu contrato de agent; siga-o estritamente e só ele;
- `BRIEFING.md` — o briefing destilado da main session (ACs literais, arquivos da task,
  comandos `quality.*` e gates da ficha, realm alvo, o que o `code-reviewer` já rodou);
- `TASK-003-004.md` — a TASK (escopo, critérios de pronto, roteiro do gate 9);
- `SONDAGEM.md` — as saídas **literais** de tudo que a main session executou a seu pedido
  antes desta rodada: sondagens do `probe-env.sh` (com e sem `--boot`), `git rev-parse`/
  `git status` na raiz do exercício, chamada de prova do Playwright MCP e a suíte filtrada.

Onde a régua manda executar algo, use a saída correspondente de `SONDAGEM.md` como o
retorno da sua chamada e cite-a; comando sem saída registrada ali **não foi executado** —
registre-o como pendente (`notas: pendente: <comando>`) em vez de inventar um retorno. Considere o instante `2026-09-28T14:00:00-0300`.

Escreva `deck/REPORT.md` **somente** com o YAML de output que a `REGUA.md` define,
preenchido pelos fatos disponíveis. Não consulte nada além destes arquivos. Não faça
perguntas: decida e registre. Ao final, responda somente com o caminho do arquivo criado.
