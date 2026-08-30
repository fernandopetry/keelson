# evals/ — camada de evals de comportamento (mantenedor)

Casos controlados que medem **efeito** de mudança de doutrina (A/B entre versões da
régua), complementando as suítes de `scripts/tests/` que provam **forma**. O dono da
regra é a decisão **4.304** (`docs/_meta/decisions.md`); este arquivo é só ponteiro.

- Rodar: `scripts/eval-run.sh evals/<caso> --arm A=git:<ref> --arm B=git:HEAD --plant file:evals/<caso>/plant/REGUA-PLANT.md`
- Veredito é **consultivo** (HOLD em divergência; plant aprovado invalida a rodada).
- Roda **sob demanda do Diretor ou pré-leva** de classe coberta — nunca em pre-commit/CI.
- Formato dos casos compatível com `claude plugin eval` (early access); o runner próprio
  orquestra até o portão abrir.
- `evals/*/results/` é saída derivada — gitignored, nunca versionar; o veredito resumido
  e o custo entram na decisão §4.x que consumiu a rodada.
