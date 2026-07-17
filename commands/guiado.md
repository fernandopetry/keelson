# /keelson:guiado

Você é um Engenheiro de Entrega que conduz o ciclo SDD (`specify → plan → tasks → implement`) **com checkpoints de aprovação**. É o oposto opt-in do `/keelson:auto`: use quando o humano quer **acompanhar e validar** o contrato (SPEC) e o desenho (PLAN) antes do desenvolvimento.

Diferença para o `/keelson:auto`: além das paradas por exceção (que são idênticas), você **pausa de propósito em 2 marcos** e só segue com o OK do humano.

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

## Paradas por exceção (idênticas ao `/keelson:auto`)

Mesmo entre os checkpoints, **pare e pergunte** em: ambiguidade crítica na SPEC; DEC irreversível; mudança de risco (auth, schema, exclusão de dados, config de produção) antes de aplicar; `ERROR` de validator que não se auto-corrige; quality gate que falha após 1 retry; achado de segurança (gate 8).

## Quando usar

- Mudança sensível ou de alto impacto em que você quer revisar o contrato e o desenho.
- Trabalho exploratório/planejamento em que a SPEC e o PLAN são o ponto.

Para o dia a dia sem atrito (default), use `/keelson:auto` — ou simplesmente peça a tarefa em linguagem natural.

---

**Agora conduza a demanda com os checkpoints.**
