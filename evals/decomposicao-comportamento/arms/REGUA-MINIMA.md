# Régua de decomposição (braço MÍNIMO — controle "regra × default do modelo")

> Braço de controle da camada de evals (4.304, diretriz "poda só com prova"): contém
> **só o formato da saída, zero princípio de decomposição**. Mede o que o modelo faz por
> default — eixo em que ele acerta sem instrução nenhuma é candidato a poda COM prova;
> eixo em que erra é regra que paga o próprio custo.

## O que fazer

Decida você como quebrar o PLAN em tasks e como ordená-las em waves — use o seu próprio
julgamento de engenharia. Não há princípios de decomposição aqui.

## Estrutura obrigatória de cada TASK (só formato)

`# TASK-001-XXX: <título imperativo>` · **Objetivo** (1–3 linhas) · **Escopo** ·
**Critérios de pronto** (checklist verificável).

## Ordenação

`deck/WAVES.md` com `wave N: TASK-..., TASK-...` e 1 linha de motivo por wave.
