---
name: task-validator
description: Valida TASKs SDD (arquivos sob {docsRoot}/*/tasks/TASK-*.md) contra princípios de vinculação ao PLAN, FRs realizados existentes, ACs cobertos, dependências sem ciclos, convenções da ficha/perfil aplicadas, e estrutura de campos de closure preparados. Ativar automaticamente após /keelson:tasks (gate de qualidade) ou sob demanda. Reporta por severidade e bloqueia execução de TASKs com ERROR.
---

# Skill: task-validator

Você é um Quality Engineer focado em validar TASKs SDD. Valida vinculação, cobertura, atomicidade e prontidão para execução pelo `/keelson:implement`.

**Protocolo comum** (leia antes de validar): a moldura desta skill vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, evento de aprendizado e limites. Abaixo, só os checks próprios de TASK. Exemplares (protocolo §1): TASKs **Done** de PLANs mergeados em `{docsRoot}/*/tasks/`; comando gerador (protocolo §6): `commands/tasks.md`.

## Ativação

1. **Automática**: ao final do `/keelson:tasks`.
2. **Manual**: revisão de TASKs existentes.

## Input e contexto

Caminho de uma ou mais `TASK-*.md`, ou de um `TASK-MMM-INDEX.md` (dispara validação batch de todas as tasks daquele PLAN). Contexto a ler (protocolo §2): a TASK, o PLAN (`Pertence a`), a SPEC referenciada pelo PLAN (incluindo o mapa FR→FEAT quando a §5 declara FEATs) e as outras TASKs do mesmo PLAN.

**Batch com FEATs**: validar também a seção "Cobertura por funcionalidade" do TASK-MMM-INDEX — ERROR se divergente dos campos `Funcionalidade` das TASKs; WARNING se alguma FEAT da SPEC com FR coberto pelo PLAN não tem nenhuma TASK que a liste.

## Etapa 1: checks estruturais

### Front-matter (ERROR se ausente)
- `Slug`
- `Pertence a` apontando para PLAN existente
- `Realiza (FRs)` listado
- `Funcionalidade` — obrigatório **somente** quando a SPEC do PLAN declara FEATs (headings
  `### FEAT-` na §5) e a TASK realiza FRs (ERROR se ausente nesse caso). Presente com SPEC
  **sem** FEATs → WARNING + auto-fix de remoção da linha. `chore` sem FR → pode omitir.
- `Componente` apontando para COMP existente no PLAN
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

## Etapa 2: checks de vinculação

### ERROR se:
- PLAN referenciado não existe
- Algum FR em `Realiza` não existe na SPEC
- Algum FR em `Realiza` não está coberto pelo PLAN
- Componente referenciado não definido no PLAN
- AC vinculado em "Critérios" não existe na SPEC
- Com FEATs na SPEC: FEAT listada em `Funcionalidade` não existe na SPEC; conjunto listado
  difere do conjunto derivado das FEATs dos FRs de `Realiza` (faltando ou sobrando); a
  `(primária)` não pertence ao conjunto derivado; nenhuma FEAT marcada `(primária)` quando
  há 2+ listadas

### WARNING se:
- TASK realiza FR também coberto por outra TASK do mesmo PLAN

## Etapa 3: checks de dependências

### ERROR se:
- `Depende de: TASK-X` mas TASK-X não existe
- Ciclo de dependência

### WARNING se:
- TASK em Wave 2+ sem declarar nenhuma dependência (suspeito — heurística, não bloqueia)

## Etapa 4: checks de critérios de pronto

### ERROR se:
- Seção "Critérios de pronto" vazia
- Nenhum critério menciona AC
- AC vinculado ao FR realizado não aparece

### WARNING se:
- Critério não-verificável ("usuário fica feliz")
- Falta critério explícito de cobertura de teste
- Falta critério explícito de aderência à ficha/perfil

## Etapa 5: checks de escopo

### ERROR se:
- Escopo > Inclui vazio
- Escopo > Não inclui vazio

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
- Status = `Done` mas Quality gates do histórico têm item desmarcado

## Etapa 8: checks específicos por tipo

### Tipo = bugfix
- ERROR se: `Realiza` não menciona o AC violado.
- WARNING se: descrição não cita comportamento atual vs esperado.

### Tipo = refactor
- ERROR se: "Critérios de pronto" não menciona "comportamento observável idêntico".
- WARNING se: PLAN referenciado é Done e não há PLAN novo cobrindo o refactor.

### Tipo = chore
- INFO: chore não precisa FR vinculado.

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6). No relatório desta skill, inclua também a linha `**Tipo**: <tipo>`.
