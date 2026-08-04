---
name: plan-validator
description: Valida PLANs SDD ({docsRoot}/*/plans/PLAN-*.md): cobertura explícita, DEC com alternativas, mapeamento FR-componente. Ativar após /keelson:plan (gate de qualidade) ou sob demanda quando pedirem validação, revisão ou lint de PLAN.
---

# Skill: plan-validator

Você é um Quality Engineer: valide o PLAN contra os checks abaixo.

**Protocolo comum** (leia antes de validar): a moldura desta skill vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, evento de aprendizado e limites. Abaixo, só os checks próprios de PLAN. Exemplares (protocolo §1): PLANs aprovados em `{docsRoot}/*/plans/`; comando gerador (protocolo §6): `commands/plan.md`.

## Input e contexto

Caminho de um ou mais `PLAN-*.md`. Contexto a ler (protocolo §2): o PLAN, a SPEC referenciada e o `INDEX.md` do slug.

## Etapa 1: checks estruturais

### Front-matter (ERROR se ausente)
- `Slug`, `Status` em `{Draft, Review, Approved, Done}`, `Versão`, `Autor`, `Data`
- Data em `YYYY-MM-DD` (auto-fix se formato comum)

### Seções obrigatórias (ERROR se ausente)
- Aderência a guidelines
- Cobertura
- 1. Visão técnica
- 2. Stack e dependências
- 3. Componentes
- 4. Fluxos principais
- 5. Modelo de dados (pode estar vazio se sem persistência)
- 6. Decisões arquiteturais
- 7. Mapeamento FR → componente
- 8. Riscos técnicos
- 9. Definition of Done
- 10. Não coberto por este PLAN

### IDs (ERROR)
- `DEC-MMM-XXX`, `COMP-MMM-XXX`, `TRISK-MMM-XXX` no formato correto
- MMM = número deste PLAN
- Auto-fix se zero-padding ausente

## Etapa 2: checks de cobertura

### ERROR se:
- Seção "Cobertura" não declara `SPEC referenciada`
- Lista `FRs cobertos` vazia
- "Cobertura agregada do slug" ausente ou inconsistente

(A **existência** da SPEC referenciada e dos FRs/NFRs cobertos chega como fato —
`ref-quebrada` em `spec-ref`/`plan-covers`, Etapa 4 — não a re-derive aqui.)

### WARNING se:
- Algum FR coberto também em PLAN anterior (overlap não justificado)
- Gap restante listado sem comentário sobre quando será coberto

## Etapa 3: checks de decisões arquiteturais (DEC)

### ERROR se:
- DEC sem `Contexto`, `Decisão`, `Alternativas consideradas`, `Consequências`, `Irreversível`
- DEC sem ao menos 1 alternativa
- DEC com `Irreversível: <valor diferente de sim ou não>`

### WARNING se:
- DEC com apenas 1 alternativa (caminho único?)
- DEC `Irreversível: sim` sem justificativa em "Consequências"
- DEC sem linha `**Reabrir se**:` (decisão 4.97) — **só em PLAN `Draft`/`Review`**; `Approved`/`Done` é acervo anterior à régua: silêncio
- `**Reabrir se**: nunca` sem motivo após o travessão ("nunca" sem justificativa é fé assinada)

### Auto-fix se:
- `Irreversível: SIM` → `Irreversível: sim`
- `Irreversivel:` → `Irreversível:`

## Etapa 4: checks do grafo de componentes (FR → COMP e COMP → COMP)

### Fato mecânico primeiro

A parte estrutural desta etapa tem **dono único e execução mecânica** — catálogo,
severidades e carência de legado em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`. Execute (num subagent
executor sem a env var, derive a raiz do plugin do caminho deste SKILL.md — o prefixo
antes de `/skills/`):

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh" {docsRoot}/<slug> --check --stage=plan --plan MMM
```

Chega como fato: SPEC referenciada ou FR/NFR coberto inexistente (`ref-quebrada` em
`spec-ref`/`plan-covers`), FR coberto sem linha na §7 (`fr-sem-comp`), §7 referenciando
COMP ou AC inexistente (`ref-quebrada`), FR mapeado fora da cobertura, COMP sem FR
(`comp-sem-fr`), divergência entre o `Realiza` dos COMPs e a §7, ciclo COMP → COMP e
ID duplicado. Cada achado entra no relatório como `**[graph.sh]** SEVERIDADE check —
detalhe`; a calibração final é sua (protocolo §1/§3). **Degradação por resultado** e
**cobertura mista**: réguas do §5 do graph-contract.md — sem saída válida, aplique os
mesmos checks por leitura e declare a degradação; artefato com `nao-parseavel`, não
ateste ausência de defeito para aquela aresta.

### ERROR se (seus):
- Tabela "Mapeamento FR -> componente" ausente

### WARNING se (seus):
- Muitos FRs no mesmo COMP (COMP doing too much)
- **Aresta de interface aberta** — toda aresta declarada na §3 fecha nas **duas** pontas. Aberta em qualquer uma delas, o PLAN é internamente contraditório e a TASK que decompõe o COMP herda a decisão que o PLAN não tomou: quem implementa escolhe sozinho. Checar as duas direções:
  - **Saída sem consumidor** (código morto decidido no PLAN): elemento da `Interface pública` que nenhum consumidor declarado invoca (COMP dependente, fluxo da §4, rota). Contra-exemplo: uma operação `Toggle<X>` exposta na `Interface pública` de um COMP enquanto nenhum COMP dependente, fluxo da §4 ou rota declarada a invoca. Exceção: superfície sem consumidor interno por natureza (testes, rotas HTTP, CLI, migration).
  - **Entrada sem fornecedor** (inobtenível): valor que a `Interface pública` exige — argumento **ou** placeholder (`:foo`) do SQL escrito no PLAN — sem origem declarada no mesmo PLAN. Origens válidas: path param da tabela de rotas, corpo/DTO, sessão (identidade, permissão), retorno de outro COMP. Contra-exemplo: uma operação cuja `Interface pública` exige o identificador do agrupamento pai (`:parent_id`) sem origem declarada, enquanto a rota que a aciona traz apenas o id do próprio recurso no path (`DELETE /recurso/{id}`) — a única origem seria um `SELECT` antes da escrita, o check-then-act que uma DEC **citada pelo próprio PLAN** fecha. "Só dá para obter consultando o banco antes" é o sinal.

## Etapa 5: checks de aderência à ficha/perfil (CLAUDE.md complementar)

### ERROR se:
- Seção "Aderência a guidelines" ausente
- Stack declarado contradiz o **perfil de linguagem ativo da ficha** (a fonte de que o `/keelson:plan` gera)
- Decisão irreversível tocada sem entrar em "Exceções aos guidelines"

### WARNING se:
- "Exceções" listadas sem justificativa ou aprovador
- Stack introduz lib não declarada sem mencionar
- Stack contradiz convenção que o `CLAUDE.md` **declara explicitamente** (complementar — nunca ERROR: o gerador não usa o CLAUDE.md como fonte primária de convenção)

## Etapa 6: checks de Definition of Done

### ERROR se:
- Seção 9 vazia ou com placeholders
- Itens não-verificáveis sem critério objetivo

### WARNING se:
- DoD não menciona cobertura de teste
- DoD não menciona aderência à ficha/perfil

## Etapa 7: checks de não-violação de SPEC

### ERROR se:
- PLAN propõe algo que contradiz FR da SPEC
- PLAN cobre FRs fora do scope da SPEC

### INFO se:
- Inconsistência genuína na SPEC identificada (não bloqueante: resolve criando nova SPEC).

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6).
