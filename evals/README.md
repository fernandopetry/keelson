# evals/ — camada de evals de comportamento (mantenedor)

Casos controlados que medem **efeito** de mudança de doutrina (A/B entre versões da
régua), complementando as suítes de `scripts/tests/` que provam **forma**. O dono da
regra é a decisão **4.304** (`docs/_meta/decisions.md`); este arquivo é só ponteiro.

- Rodar: `scripts/eval-run.sh evals/<caso> --arm A=<fonte> --arm B=<fonte> --plant file:evals/<caso>/plant/REGUA-PLANT.md`.
  Fonte `file:<path>` (o arquivo inteiro é a régua — é como 10 dos 11 casos rodam, com os
  braços em `arms/` ou montados à mão) ou `git:<ref>`, que só vale para caso cujo
  `prompt.md` declara `regua:` (caminho no repo) e, opcionalmente, `regua_inicio:`/
  `regua_fim:` (prefixos de linha) — sem a declaração o runner recusa `git:` (4.377);
  hoje só `decomposicao-comportamento` a declara.
- `--runs` mínimo 1; abaixo de 4 o sumário rotula a leitura como sinal (piso empírico da
  bancada, obs. 4.304 — não garantia). HOLD distingue variância intra-braço de juiz sem
  veredito válido (falha de infra).
- Veredito é **consultivo** (HOLD em divergência; plant aprovado invalida a rodada).
- Roda **sob demanda do Diretor ou pré-leva** de classe coberta — nunca em pre-commit/CI.
- Formato dos casos compatível com `claude plugin eval` (early access); o runner próprio
  orquestra até o portão abrir.
- `evals/*/results/` é saída derivada — gitignored, nunca versionar; o veredito resumido
  e o custo entram na decisão §4.x que consumiu a rodada.
