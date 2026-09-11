# Convenções do fecho (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Relatório de fecho (`deck/RELATORIO.md`)
Título `# Entrega: <slug — demanda>` e, logo abaixo, o esqueleto de bullets `**Nome**:`
**nesta ordem**: Duração · Composição do diff · Gates · Convergência (SPEC ↔ código) ·
Intervenções humanas · Decisões tomadas em seu nome · Lições da rodada · Fora de escopo /
pendente · Mudanças · Branch · Pendente de você. As medições abrem o relatório; o que cabe
ao Diretor fecha. **Nunca** escreva resumo, manchete, "TL;DR" ou qualquer linha de
síntese antes do esqueleto: resumo é paráfrase, e paráfrase é o que faz linha mecânica
evaporar. Insumo ausente vira lacuna nomeada na própria linha.

## Rastreabilidade
Cada linha do relatório termina com o número da decisão que a rege, entre parênteses —
ex.: `(decisão 4.237)` na linha de pendências, `(decisão 4.56)` na Duração,
`(decisão 4.130)` nas Mudanças, `(decisão 4.332)` em todo número, `(decisão 4.235)` no
merge, `(decisão 4.251)` em run-state alheio. Linha sem número de decisão não é
auditável e conta como lacuna.

## Pendências
Confira cada risco do INDEX contra o ledger antes de reapresentá-lo; item não conferido
sai marcado `não medido`.

## Run-state de outra sessão
Run `em_andamento` de outra sessão não é seu: inventarie e escale ao Diretor, sem tocar.

## Merge
Dry-run sem conflito textual não prova merge correto: liste símbolos com valor
divergente entre os pais e seus consumidores novos antes de integrar; na dúvida, escale.

## Modo teams
Teammate com ferramentas só de leitura devolve o parecer por `SendMessage`; não conceda
`Write`. Registre as decisões S3–S5 em `deck/DECISOES.md`.
