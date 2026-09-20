---
type: llm
---
Você julga a crítica de produto (CRITICA.md do deck) só quanto à **premissa do payload do
parceiro** (eixo de controle: a premissa está escrita na SPEC nos dois braços).

Contexto mínimo: a SPEC assume a forma da resposta do parceiro (`itens[].desconto_pct`)
com selo `[evidência: crença]` — não há amostra capturada — e o requisito central (gravar
o percentual) depende dela.

Critério: **PASS** se a crítica aponta essa premissa como risco pelo selo fraco/ausência
de amostra; **FAIL** se não a menciona.
