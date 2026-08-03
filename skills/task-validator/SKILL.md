---
name: task-validator
description: Valida TASKs SDD ({docsRoot}/*/tasks/TASK-*.md): vínculo ao PLAN (ou brief avulso), FRs realizados, ACs cobertos, dependências sem ciclos, campos de closure. Ativar após /keelson:tasks (gate de qualidade) ou sob demanda. Reporta por severidade.
---

# Skill: task-validator

Você é um Quality Engineer: valide a TASK contra os checks abaixo.

**Protocolo comum** (leia antes de validar): a moldura desta skill vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, evento de aprendizado e limites. Abaixo, só os checks próprios de TASK. Exemplares (protocolo §1): TASKs **Done** de PLANs mergeados em `{docsRoot}/*/tasks/`; comando gerador (protocolo §6): `commands/tasks.md`.

## Input e contexto

Caminho de uma ou mais `TASK-*.md`, ou de um `TASK-MMM-INDEX.md` (dispara validação batch de todas as tasks daquele PLAN). Contexto a ler (protocolo §2): a TASK, o PLAN (`Pertence a`), a SPEC referenciada pelo PLAN (incluindo o mapa FR→FEAT quando a §5 declara FEATs) e as outras TASKs do mesmo PLAN.

**Modo avulso (decisão 4.86)** — TASK com `**Brief**:` no lugar de `**Pertence a**:` é
ancorada num brief avulso (`briefs/BRIEF-MMM-*-avulso.md`), fora do ciclo SPEC/PLAN.
Substituições, válidas para todas as etapas abaixo: o **contexto** é o brief (não há
PLAN/SPEC); não existem FR, AC, FEAT nem COMP — checks que os exigem são **n/a**
(`Realiza (FRs)`, `Funcionalidade`, `Componente`, vínculo a AC); no lugar deles, os
critérios de pronto devem ancorar no **critério de aceite do brief** — ERROR se nenhum
critério o referencia. Âncora dupla, referência quebrada e MMM divergente chegam como
fato (`task-ancora-dupla`, `ref-quebrada`, `pertence-vs-arquivo` — Etapa 2). O resto da
régua (escopo, verificação executável, closure, convenções, tipo) vale **idêntico**.

**Batch com FEATs**: validar também a seção "Cobertura por funcionalidade" do TASK-MMM-INDEX — ERROR se divergente dos campos `Funcionalidade` das TASKs; WARNING se alguma FEAT da SPEC com FR coberto pelo PLAN não tem nenhuma TASK que a liste. (As divergências de **waves** e das tabelas de **FR/AC** do TASK-MMM-INDEX já chegam como fato — check `index-desatualizado` da Etapa 2; a seção de funcionalidade permanece sua.)

## Etapa 1: checks estruturais

### Front-matter (ERROR se ausente)
- `Slug`
- Âncora presente: `Pertence a` (ciclo) **ou** `Brief` (modo avulso) — exatamente um dos dois (existência e exclusividade chegam como fato — `ref-quebrada`/`task-ancora-dupla`, Etapa 2)
- `Realiza (FRs)` listado (ciclo; n/a no modo avulso)
- `Funcionalidade` — obrigatório **somente** quando a SPEC do PLAN declara FEATs (headings
  `### FEAT-` na §5) e a TASK realiza FRs (ERROR se ausente nesse caso). Presente com SPEC
  **sem** FEATs → WARNING + auto-fix de remoção da linha. `chore` sem FR → pode omitir.
- `Componente` presente (a existência do COMP apontado chega como fato — `ref-quebrada`, Etapa 2)
- `Wave` declarada
- `Tamanho estimado` em `{small, medium}`
- `Status` em `{Todo, In Progress, Done, Blocked}`
- `Tipo` em `{feature, bugfix, refactor, chore}` (auto-fix para `feature` se ausente)

### Seções obrigatórias
- Convenções (do projeto) — o nome que o template do `/keelson:tasks` gera
- Dependências
- Contexto
- Escopo (com Inclui e Não inclui)
- Implementação sugerida
- Critérios de pronto
- Riscos específicos (pode estar vazio)
- Histórico de execução (mesmo vazio, para /keelson:implement preencher)

### Nome do arquivo (WARNING)
- Convenção: `TASK-MMM-XXX-<titulo-kebab>.md`
- Bugfix: `-fix-` no nome se Tipo=bugfix
- Refactor: `-refactor-` no nome se Tipo=refactor

## Etapa 2: fato mecânico do grafo (vinculação, dependências, cobertura)

Os checks estruturais desta etapa têm **dono único e execução mecânica** — catálogo de
checks, severidades e carência de legado em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`. Execute (diretório do
slug já resolvido via `docsRoot`; num subagent executor sem a env var, derive a raiz do
plugin do caminho deste SKILL.md — o prefixo antes de `/skills/`):

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh" {docsRoot}/<slug> --check --stage=tasks --plan MMM
```

Chega como fato: referência quebrada (PLAN, FR, COMP, AC, FEAT ou TASK inexistente), FR
de `Realiza` fora da cobertura do PLAN, conjunto/primária de `Funcionalidade` divergente
do derivado, ciclo de dependência, wave incoerente, ID duplicado, `Pertence a` vs
arquivo, FR/AC coberto sem TASK e assimetria Depende de/Bloqueia.

- Cada achado entra no relatório como **fato** — `**[graph.sh]** SEVERIDADE check —
  detalhe` — somado à lista da severidade correspondente. A calibração final é sua
  (protocolo §1/§3): o fato substitui a derivação, nunca o julgamento.
- **Degradação por resultado**: execução sem saída válida no contrato (script ausente,
  exit 2, crash, saída malformada) → aplique os mesmos checks por leitura, seguindo o
  catálogo do graph-contract.md, e **declare** a degradação com a causa nomeada.
- **Cobertura mista**: artefato com achado `nao-parseavel` → não cite ausência de
  defeito como fato para os checks que dependem daquela aresta — para esse artefato
  valem seus próprios olhos, declarado no relatório.

## Etapa 3: checks de vinculação que permanecem seus (o script não computa)

### ERROR se:
- Com FEATs na SPEC: com 2+ FEATs listadas, nem uma marcada `(primária)` nem a forma
  `transversal (FEAT-..., FEAT-...)` — uma das duas é obrigatória; forma
  `transversal (...)` com apenas 1 FEAT (transversal exige 2+)

### WARNING se:
- TASK realiza FR também coberto por outra TASK do mesmo PLAN (overlap)
- TASK em Wave 2+ sem declarar nenhuma dependência (suspeito — heurística, não bloqueia)

## Etapa 4: checks de critérios de pronto

### ERROR se:
- Seção "Critérios de pronto" vazia
- Nenhum critério menciona AC
- AC vinculado ao FR realizado não aparece
- Critério de teste (gate 1) sem verificação executável anexada — comando + saída/efeito esperado (só TASK em `Todo`/`In Progress`; `Done` legada não reprova por isso)

### WARNING se:
- Critério não-verificável ("usuário fica feliz")
- Falta critério explícito de cobertura de teste
- Falta critério explícito de aderência à ficha/perfil

## Etapa 5: checks de escopo

### ERROR se:
- Escopo > Inclui vazio
- Escopo > Não inclui vazio
- **Cobertura reversa**: item do Inclui que nenhum critério de pronto referencia — critério genérico ("testes de tudo acima", "tudo coberto") não conta como referência; item sem AC exige critério ancorado no contrato do próprio item (só TASK em `Todo`/`In Progress`; `Done` legada não reprova por isso)

### WARNING se:
- Inclui menciona conceitos não mapeados no PLAN
- Não inclui menciona trivial/óbvio

## Etapa 6: checks de convenções

A fonte primária de convenções é a **ficha/perfil** (o que o `/keelson:tasks` usa para gerar); o CLAUDE.md só conta quando **declara** a convenção explicitamente.

### ERROR se:
- Seção "Convenções" ausente
- Padrão de commit declarado contradiz convenção **explícita** do perfil ou do CLAUDE.md (nenhuma declaração → vale o default do gerador, Conventional Commits, sem ERROR)

### WARNING se:
- Branch sugerida foge do padrão declarado (perfil ou CLAUDE.md); sem padrão declarado, não avaliar

### Auto-fix se:
- Convenções vazias mas ficha/perfil/CLAUDE.md têm dados: preencher

## Etapa 7: checks do histórico de execução

### ERROR se:
- Seção "Histórico de execução" ausente
- Status = `Done` mas campos do histórico vazios (closure não foi feita)
- Status ≠ `Done` mas histórico preenchido (inconsistente)

### WARNING se:
- Status = `Done` mas Quality gates do histórico têm item desmarcado — **exceto** gate com consolidação declarada (decisão 4.90): `aprovado (wave N)`, `consolidado (FEAT-...)` ou `consolidado (DoD, Etapa 4)` são estados válidos, não pendência

## Etapa 8: checks específicos por tipo

### Tipo = bugfix
- ERROR se: campo `**AC violado**:` ausente ou vazio (a existência do AC citado já
  chega como fato — `ref-quebrada` da Etapa 2). Acervo legado que ainda traz o AC
  dentro de `Realiza (FRs)` (forma antiga `FR-X / AC-n`) não reprova: registre INFO.
- WARNING se: descrição não cita comportamento atual vs esperado.

### Tipo = refactor
- ERROR se: "Critérios de pronto" não menciona "comportamento observável idêntico".
- WARNING se: PLAN referenciado é Done e não há PLAN novo cobrindo o refactor.

### Tipo = chore
- INFO: chore não precisa FR vinculado.

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6). No relatório desta skill, inclua também a linha `**Tipo**: <tipo>`.
