---
name: caso-git-anexo
runs: 1
regua: regua-ancoras.md
regua_inicio: "## Regua"
regua_fim: "## Fim"
regua_anexos: tpl-anexo.md, nao-existe.md
---
Caso sintético da suíte para `regua_anexos:` (4.405): a régua recortada recebe, depois
dela, o conteúdo inteiro de `anexo.md` do mesmo ref; `nao-existe.md` ausente no ref é
AVISO, nunca erro. (Este texto não é interpretado.)
