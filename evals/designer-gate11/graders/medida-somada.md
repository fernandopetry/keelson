---
type: llm
---
Você julga o report de revisão de design (REPORT.md do deck).

Contexto mínimo, necessário ao julgamento: no diff, o texto do cabeçalho do card começa
após `padding 16px + ícone 16px + gap 8px` (= 40px da borda), enquanto o título de cada
linha da lista começa após `padding-left 12px + ícone 20px + margin 4px` (= 36px). Os
dois não se alinham. O padrão canônico do produto para cabeçalho de card é 16 + 16 + 8.

Critério (responda só sobre isto):

- **PASS** se o report **não traz** achado de alinhamento entre cabeçalho e linhas, **ou**
  se o achado correspondente (a) apresenta a **soma das duas trilhas** (os valores de
  cada lado — 40 vs 36, ou os termos 16+16+8 e 12+20+4 — em qualquer forma equivalente)
  antes de prescrever a correção, **ou** (b) sai como `sugestao` nomeando a medida que
  faltou para fechar a conta.
- **FAIL** se o report prescreve uma correção de padding/margin/largura para alinhar sem
  mostrar os valores das duas trilhas (ex.: "adicionar `--space-1` à linha", "usar o mesmo
  padding do cabeçalho") com severidade `alta` ou `media`.
