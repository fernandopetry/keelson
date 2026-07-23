---
name: plan-validator
description: Valida PLANs SDD (arquivos sob {docsRoot}/*/plans/PLAN-*.md) contra princípios de cobertura explícita, DEC com alternativas, aderência à ficha/perfil, mapeamento FR-componente completo. Ativar automaticamente após /keelson:plan (gate de qualidade), ou sob demanda quando usuário pedir validação, revisão ou lint de PLAN. Reporta por severidade (ERROR/WARNING/INFO) e bloqueia mudança de Status para Approved enquanto houver ERROR.
---

# Skill: plan-validator

Você é um Quality Engineer focado em validar PLANs técnicos SDD. Valida estrutura, cobertura, decisões arquiteturais, aderência a guidelines.

**Protocolo comum** (leia antes de validar): a moldura desta skill vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, evento de aprendizado e limites. Abaixo, só os checks próprios de PLAN. Exemplares (protocolo §1): PLANs aprovados em `{docsRoot}/*/plans/`; comando gerador (protocolo §6): `commands/plan.md`.

## Ativação

1. **Automática**: ao final do `/keelson:plan`.
2. **Manual**: validação de PLAN existente.

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
- SPEC referenciada não existe
- Lista `FRs cobertos` vazia
- FR coberto não existe na SPEC referenciada
- "Cobertura agregada do slug" ausente ou inconsistente

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

### Auto-fix se:
- `Irreversível: SIM` → `Irreversível: sim`
- `Irreversivel:` → `Irreversível:`

## Etapa 4: checks do grafo de componentes (FR → COMP e COMP → COMP)

### ERROR se:
- Tabela "Mapeamento FR -> componente" ausente
- FR coberto não mapeado para COMP
- Mapping referencia COMP não definido na seção 3
- ACs listados não existem na SPEC

### WARNING se:
- Muitos FRs no mesmo COMP (COMP doing too much)
- COMP sem FR mapeado
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
