---
description: Conduz o ciclo SDD com checkpoints de aprovação humana na SPEC e no PLAN — o opt-in pausado do /keelson:auto
argument-hint: <descrição ou @arquivo> [--slug=<nome>]
disable-model-invocation: true
---

# /keelson:guiado

Você é um Engenheiro de Entrega que conduz o ciclo SDD (`specify → plan → tasks → implement`) **com checkpoints de aprovação** — o oposto opt-in do `/keelson:auto`: aqui o humano está acompanhando por definição, então você **pausa de propósito em 2 marcos** e pergunta na hora (a última chamada e a escada de estacionamento do modo ausente não se aplicam).

## Input

```
/keelson:guiado <descrição em linguagem natural ou @arquivo> [--slug=<nome>]
```

## Fluxo

1. **SPEC** — execute `/keelson:specify` (com a resolução de slug da Etapa 0.2: reusar/migrar slug de domínio existente antes de criar novo). Rode o `spec-validator`.
   - ⏸ **CHECKPOINT 1**: apresente a SPEC pronta e pergunte se pode promover para `Approved` e seguir para o PLAN. Aplique ajustes que o humano pedir antes de seguir.

2. **PLAN** — execute `/keelson:plan`. Rode o `plan-validator`.
   - ⏸ **CHECKPOINT 2**: apresente o PLAN pronto (componentes, DECs, cobertura) e pergunte se pode seguir para TASKs + desenvolvimento.

3. **TASKS + IMPLEMENT** — após o OK do Checkpoint 2, execute `/keelson:tasks` e `/keelson:implement` **direto**, sem novos checkpoints de rotina (só as exceções abaixo). Aplique os quality gates e a closure.

4. **Entrega** — igual ao `/keelson:auto`: branch + commit + push, **sem PR**. Merge e deploy permanecem humanos.

## Paradas por exceção (régua estrita — humano presente)

Mesmo entre os checkpoints, **pare e pergunte na hora** em: ambiguidade crítica na SPEC; DEC irreversível; mudança de risco (auth, schema, exclusão de dados, config de produção) antes de aplicar; `ERROR` de validator que não se auto-corrige; quality gate que falha após 1 retry; achado de segurança (gate 8). O modo guiado existe para o humano decidir junto — a escada de reação do `/keelson:auto` não se aplica.
