---
name: caso-git
runs: 1
regua: regua-ancoras.md
regua_inicio: "## Regua"
regua_fim: "## Fim"
---
Caso sintético da suíte para a fonte `git:` (4.377): a régua vem de
`git show <ref>:regua-ancoras.md` do repositório corrente, recortada entre as âncoras
declaradas acima — cabeçalho e rodapé do arquivo carregam marcas que o fake-executor
leria como régua má/plant se a extração vazasse. (Este texto não é interpretado.)
