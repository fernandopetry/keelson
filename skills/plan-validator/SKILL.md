---
name: plan-validator
description: Valida PLANs SDD ({docsRoot}/*/plans/PLAN-*.md): cobertura explícita, DEC com alternativas, mapeamento FR-componente. Ativar após /keelson:plan (gate de qualidade) ou sob demanda quando pedirem validação, revisão ou lint de PLAN.
---

# Skill: plan-validator

Você é um Quality Engineer: valide o PLAN contra os checks abaixo.

**Protocolo comum** (leia antes de validar): a moldura desta skill vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, evento de aprendizado e limites. Abaixo, só os checks próprios de PLAN. Exemplares (protocolo §1): PLANs aprovados em `{docsRoot}/*/plans/`; comando gerador (protocolo §6): `commands/plan.md`.

## Input e contexto

Caminho de um ou mais `PLAN-*.md`. Contexto a ler (protocolo §2): o PLAN, a SPEC referenciada e o `INDEX.md` do slug.

## Etapa 1: fato mecânico primeiro — forma

A forma do PLAN tem **dono único e execução mecânica** — catálogo, severidades e régua
de rebaixamento em `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/lint-contract.md`.
Execute (num subagent executor sem a env var, derive a raiz do plugin do caminho deste
SKILL.md — o prefixo antes de `/skills/`):

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/artifact-lint.sh" <caminho-do-PLAN>
```

Chega como fato (`plan-*` do lint-contract §3): cabeçalho/enum de Status, seções
obrigatórias (Aderência, Cobertura, §1–§10), IDs fora do MMM e sem zero-padding,
Cobertura sem SPEC referenciada/FRs cobertos vazios/agregada ausente, anatomia dos
blocos DEC (campos obrigatórios, zero ou uma alternativa, enum e forma do
`Irreversível`, `Reabrir se` ausente — 4.97 — ou `nunca` sem motivo), §7 sem linhas,
DoD vazia/com placeholder/sem menção a teste ou ficha/perfil. Invocado com o
**diretório do slug**, acrescenta `plan-overlap-fr` (FR coberto por 2+ PLANs).
Auto-fixes que continuam seus (protocolo §3): `Irreversível: SIM` → `sim` ·
`Irreversivel:` → `Irreversível:` · zero-padding · formato de `Data`.

Cada achado entra como `**[artifact-lint]** SEVERIDADE check — detalhe`; degradação
por resultado e cobertura mista seguem o §5 do graph-contract.md.

## Etapa 2: checks de cobertura que permanecem seus

(A **existência** da SPEC referenciada e dos FRs/NFRs cobertos chega como fato —
`ref-quebrada` em `spec-ref`/`plan-covers`, Etapa 4 — não a re-derive aqui.)

### WARNING se:
- Overlap de FR apontado pelo fato sem justificativa no texto (o script mede; o "não justificado" é seu)
- Gap restante listado sem comentário sobre quando será coberto
- "Cobertura agregada do slug" presente porém **inconsistente** com o INDEX

## Etapa 3: checks de decisões arquiteturais (DEC) que permanecem seus

### WARNING se:
- DEC `Irreversível: sim` sem justificativa em "Consequências"
- Descarte de alternativa sem custo concreto — só adjetivo ("mais complexa", "pior"), sem nomear o que se perde ou quebra ao escolhê-la (decisão 4.136) — **só em PLAN `Draft`/`Review`**, mesma carência da régua do `Reabrir se`

## Etapa 4: checks do grafo de componentes (FR → COMP e COMP → COMP)

### Fato mecânico primeiro

A parte estrutural desta etapa tem **dono único e execução mecânica** — catálogo,
severidades e carência de legado em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`. Execute:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh" {docsRoot}/<slug> --check --stage=plan --plan MMM
```

Chega como fato: SPEC referenciada ou FR/NFR coberto inexistente (`ref-quebrada` em
`spec-ref`/`plan-covers`), FR coberto sem linha na §7 (`fr-sem-comp`), §7 referenciando
COMP ou AC inexistente (`ref-quebrada`), FR mapeado fora da cobertura, COMP sem FR
(`comp-sem-fr`), divergência entre o `Realiza` dos COMPs e a §7, ciclo COMP → COMP,
ID duplicado e FR da SPEC sem AC (`fr-sem-ac` — 4.153). Cada achado entra no relatório
como `**[graph.sh]** SEVERIDADE check — detalhe`; a calibração final é sua (protocolo
§1/§3). **Degradação por resultado** e **cobertura mista**: réguas do §5 do
graph-contract.md — sem saída válida, aplique os mesmos checks por leitura e declare a
degradação; artefato com `nao-parseavel`, não ateste ausência de defeito para aquela
aresta.

### WARNING se (seus):
- Muitos FRs no mesmo COMP (COMP doing too much)
- **Aresta de interface aberta** — toda aresta declarada na §3 fecha nas **duas** pontas. Aberta em qualquer uma delas, o PLAN é internamente contraditório e a TASK que decompõe o COMP herda a decisão que o PLAN não tomou: quem implementa escolhe sozinho. Checar as duas direções:
  - **Saída sem consumidor** (código morto decidido no PLAN): elemento da `Interface pública` que nenhum consumidor declarado invoca (COMP dependente, fluxo da §4, rota). Contra-exemplo: uma operação `Toggle<X>` exposta na `Interface pública` de um COMP enquanto nenhum COMP dependente, fluxo da §4 ou rota declarada a invoca. Exceção: superfície sem consumidor interno por natureza (testes, rotas HTTP, CLI, migration).
  - **Entrada sem fornecedor** (inobtenível): valor que a `Interface pública` exige — argumento **ou** placeholder (`:foo`) do SQL escrito no PLAN — sem origem declarada no mesmo PLAN. Origens válidas: path param da tabela de rotas, corpo/DTO, sessão (identidade, permissão), retorno de outro COMP. Contra-exemplo: uma operação cuja `Interface pública` exige o identificador do agrupamento pai (`:parent_id`) sem origem declarada, enquanto a rota que a aciona traz apenas o id do próprio recurso no path (`DELETE /recurso/{id}`) — a única origem seria um `SELECT` antes da escrita, o check-then-act que uma DEC **citada pelo próprio PLAN** fecha. "Só dá para obter consultando o banco antes" é o sinal.

## Etapa 5: checks de aderência à ficha/perfil (CLAUDE.md complementar)

### ERROR se:
- Stack declarado contradiz o **perfil de linguagem ativo da ficha** (a fonte de que o `/keelson:plan` gera)
- Decisão irreversível tocada sem entrar em "Exceções aos guidelines"

### WARNING se:
- "Exceções" listadas sem justificativa ou aprovador
- Stack introduz lib não declarada sem mencionar
- Stack contradiz convenção que o `CLAUDE.md` **declara explicitamente** (complementar — nunca ERROR: o gerador não usa o CLAUDE.md como fonte primária de convenção)

## Etapa 6: checks de Definition of Done que permanecem seus

### ERROR se:
- Itens não-verificáveis sem critério objetivo

### WARNING se:
- SPEC referenciada declara `**Fonte de medição**:` na §1.3 e a DoD não tem o item de métrica operacional (decisão 4.99) — **só em PLAN `Draft`/`Review`**; `Approved`/`Done` é acervo: silêncio

## Etapa 7: checks de não-violação de SPEC

### ERROR se:
- PLAN propõe algo que contradiz FR da SPEC
- PLAN cobre FRs fora do scope da SPEC

### INFO se:
- Inconsistência genuína na SPEC identificada (não bloqueante: resolve criando nova SPEC).

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6).
