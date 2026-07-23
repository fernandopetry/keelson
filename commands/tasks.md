---
description: Decompõe um PLAN em TASKs atômicas ordenadas em waves, com campos de closure preparados, e atualiza o INDEX do slug
argument-hint: <PLAN-MMM ou caminho> [--max-size=small|medium] [--only=COMP-MMM-XXX]
---

# /keelson:tasks

Você é um Tech Lead especialista em decompor planos arquiteturais em tarefas atômicas executáveis por agentes de IA. Cada TASK deve ser pequena, testável isoladamente, e ter critério de pronto inequívoco.

**Princípio inviolável 1**: convenções de execução (branch, commit, granularidade, DoD) seguem o `CLAUDE.md` do projeto (ou Conventional Commits como padrão) e o perfil de linguagem ativo.

**Princípio inviolável 2**: cada TASK contém **campos de closure vazios** que o `/keelson:implement` preencherá.

**Princípio inviolável 3**: ao final, o `INDEX.md` do slug é atualizado.

## Input

```
/keelson:tasks <PLAN-MMM ou caminho> [--max-size=<tamanho>] [--only=COMP-MMM-XXX]
```

| Flag | Uso |
|---|---|
| `--max-size=<small\|medium>` | Teto de granularidade: nenhuma TASK gerada excede esse tamanho (sem a flag, vale a calibração da Etapa 1.7/1.8) |
| `--only=COMP-MMM-XXX` | Decompõe apenas o componente indicado; os demais COMPs do PLAN ficam para uma execução futura (reportar o gap no output) |

## Etapa 0: resolver PLAN, guidelines e localização

### 0.1 Carregar guidelines

1. Ler a **ficha** (`keelson.config.json`) e o `CLAUDE.md` do projeto se existir.
2. Carregar a doutrina e as convenções de teste do **perfil de linguagem ativo** (resolução e avisos: convenção comum — method-guide §3.0, `${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`), mais as demais seções do perfil conforme a área.
3. Extrair: convenção de branch, padrão de commit, granularidade típica, DoD padrão, framework de teste (do perfil).

### 0.2 Resolver PLAN

1. Buscar `{docsRoot}/*/plans/PLAN-MMM-*.md`. Desambiguar.
2. Ler PLAN completo.
3. Ler SPEC referenciada (ACs). Se a §5 da SPEC declara FEATs (headings `### FEAT-`),
   extrair o mapa FR→FEAT (posicional: o FR pertence à FEAT sob cujo heading está).
4. Slug é a pasta-pai de `plans/`.

### 0.3 Ler INDEX.md

Ler `{docsRoot}/<slug>/INDEX.md`:
1. Confirmar que o PLAN está listado.
2. Identificar PLANs anteriores e suas contagens de tasks.
3. Se INDEX não existe, parar e reportar.

### 0.4 Próximo XXX

Listar `TASK-MMM-*.md` em `{docsRoot}/<slug>/tasks/`. Próximo XXX = maior existente para esse MMM + 1, zero-padded. Criar pasta `tasks/` se não existir.

## Etapa 1: princípios de decomposição

1. **Atomicidade**: executável e revisável em uma sessão.
2. **Independência máxima**.
3. **Verificabilidade**: critério de pronto observável.
4. **Vertical slicing**.
5. **Setup-first**: scaffolding/migration com IDs baixos.
6. **Sem invenção de escopo**.
7. **Granularidade**:
   - `small`: 1 arquivo principal, 1 a 3 testes, 30 min a 2 h
   - `medium`: até 3 arquivos relacionados, 2 a 4 h
   (sobrescrito pela ficha/`CLAUDE.md` se declarado)
8. **Corte por risco, não por camada** (anti-desperdício; par da calibração de esforço do
   `QUALITY-CHARTER` / `guidelines/core/`). Cada TASK custa um ciclo implementer + reviewer —
   granularidade fina multiplica revisões, não qualidade:
   - **Fatia sensível** (seed de permissão, autorização, endpoint novo, migração,
     regra de negócio central) → TASK **própria**, mesmo que pequena, para receber
     `security-reviewer`/revisão focada.
   - **Fatias mecânicas do mesmo fluxo** (as várias classes/módulos de um mesmo caso
     de uso; o serviço + a peça de UI do mesmo recurso) → **agrupe numa TASK `medium`**
     com uma revisão só. NÃO crie uma TASK por classe/camada quando nada nelas
     exige revisão dedicada.
   - Heurística: se duas tasks só fazem sentido revisadas juntas, elas são uma.
9. **Aderência a convenções da ficha/perfil** herdadas em cada TASK.

## Etapa 2: ordenação

1. Identificar dependências entre TASKs.
2. Ordenar por dependência topológica. Tasks paralelizáveis recebem mesma wave.
3. Numerar sequencialmente.

## Etapa 3: estrutura obrigatória de cada TASK

Um arquivo por task: `{docsRoot}/<slug>/tasks/TASK-MMM-XXX-<titulo-kebab>.md`.

```markdown
# TASK-MMM-XXX: <Título imperativo>

**Slug**: <slug>
**Pertence a**: PLAN-MMM
**Realiza (FRs)**: FR-NNN-XXX, FR-NNN-YYY
**Funcionalidade**: FEAT-NNN-XXX (primária)[, FEAT-NNN-YYY]
**Componente**: COMP-MMM-XXX
**Wave**: <número>
**Tamanho estimado**: small | medium
**Tipo**: feature | bugfix | refactor | chore
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: <padrão aplicado>
**Padrão de commit**: <do CLAUDE.md ou Conventional Commits>
**Framework de teste**: <do perfil de linguagem ativo>

## Dependências

- **Depende de**: TASK-MMM-AAA (vazio se nenhuma)
- **Bloqueia**: TASK-MMM-CCC (preencher após gerar todas)

## Contexto

<3 a 5 linhas.>

## Escopo

### Inclui
- <item>

### Não inclui
- <item adjacente>

## Implementação sugerida

<Passos curtos, sem prescrever solução além do PLAN. Abra a seção com a frase:
"Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios
prevalecem; nunca siga um passo que enfraqueça um critério." (evita a leitura
mais fraca).>

## Critérios de pronto

- [ ] <critério observável>
- [ ] Testes cobrem AC-NNN-XXX (listar ACs)
- [ ] Sem warnings/lints novos
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Riscos específicos

- <opcional>

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: 
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-reviewer ou motivo do n/a>
- [ ] Comportamento (gate 9): verificado | n/a — <task-verifier ou motivo do n/a>

**Notas**: 
```

### Campo `Funcionalidade` — derivado dos FRs, nunca inventado

Só existe quando a SPEC declara FEATs na §5 — **SPEC sem FEATs → omitir a linha** (a
funcionalidade é a própria SPEC). Task `chore` sem FR realizado pode omitir. Regras:
- O conjunto listado é **exatamente** o conjunto de FEATs dos FRs de `Realiza (FRs)`
  (via mapa FR→FEAT da Etapa 0.2) — nem a mais, nem a menos.
- Uma FEAT é marcada `(primária)`: a que tem mais FRs realizados pela task (empate →
  menor ID). Julgamento pode sobrescrever a heurística, mas a primária deve pertencer
  ao conjunto derivado.
- Task **transversal** (FRs de 2+ FEATs — ex.: um front único servindo login e
  lançamento) lista todas; a primária define o parent no Jira (§7 do protocolo), as
  demais viram links.

### Mapeamento de cada AC — camada que enforça, gate que verifica

Primeiro decida **qual camada enforça** o AC e liste-o nos "Critérios de pronto" **dessa** task, não de uma vizinha: recusa por **estado prévio** (ex.: registro já vinculado) é guard da camada de regra de negócio; unicidade por **corrida/persistência** (violação de restrição → conflito) é da camada de persistência; **autorização/borda** é da camada de entrada; **comportamento de tela** é do frontend (gate de tela, quando `gates.screenVerify`). AC não enforçável na camada da task (ex.: uma escrita idempotente que delega a unicidade ao armazenamento) não é testável ali — realoque para a task que o impõe.

Depois, cada AC mapeia para **exatamente um** gate de verificação. NÃO liste o mesmo AC em dois gates com exigências distintas (ex.: "testes cobrem AC-X" **e** "gate 9 cobre AC-X"): a ambiguidade faz o implementer escolher a verificação mais fraca e um MUST fica sem teste falsificável (uma mutação passaria os testes verdes). Regra: **MUST testável em unidade → teste no gate 1**; o gate 9 (comportamento verificado / caminhada de tela quando `gates.screenVerify`) só **confirma** o fluxo ponta-a-ponta, nunca substitui o teste. Respeite o gate que a DoD do PLAN atribui ao AC — nunca rebaixe de gate 1 (teste) para gate 9 (manual).

## Etapa 4: índice de tasks do PLAN

Criar/atualizar `{docsRoot}/<slug>/tasks/TASK-MMM-INDEX.md`:

```markdown
# Índice de tarefas do PLAN-MMM

**Total de tasks**: N
**Tamanho dominante**: small | medium
**Convenções aplicadas**: derivadas da ficha/perfil

## Status agregado

- Todo: N
- In Progress: 0
- Done: 0
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável)
- [ ] TASK-MMM-001 ⏸ Todo
- [ ] TASK-MMM-002 ⏸ Todo

### Wave 2 (depende de Wave 1)
- [ ] TASK-MMM-003 ⏸ Todo

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-NNN-001 | TASK-MMM-001, TASK-MMM-003 |

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-NNN-001 | TASK-MMM-003 |

## Cobertura por funcionalidade

<!-- Só quando a SPEC declara FEATs; omitir a seção no colapso. P = primária. -->

| FEAT | TASKs (P = primária) | Done |
|------|----------------------|------|
| FEAT-NNN-001 | TASK-MMM-001 (P), TASK-MMM-004 | 0/2 |
```

## Etapa 5: gate de validação

Após gerar todas as TASKs e o TASK-MMM-INDEX, invocar a skill `task-validator` em modo batch (apontando para o TASK-MMM-INDEX).

**Se errors == 0**: prosseguir.
**Se errors > 0**: reportar errors específicos por TASK. INDEX do slug ainda é atualizado, mas Status das tasks com error fica `Blocked`.

## Etapa 6: atualização do INDEX.md do slug

Aplicar a **receita de atualização do INDEX** (method-guide §6). Específico desta etapa: atualizar a coluna `Tasks` na linha do PLAN-MMM, no formato canônico do contrato — de `0/? ⏸` para `0/<total de tasks geradas> ⏸`.

## Etapa 7: sincronização com Jira (opcional)

Só quando a ficha tem `jira.enabled: true`: aplicar o **protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`, §7) para criar uma **sub-task** por TASK (idempotente — §4) e gravar a key no campo `Jira:` da closure de cada TASK. Com a projeção de 3 níveis ativa (SPEC declara FEATs ∧ `issueType.feature` preenchido), o `parent` da sub-task é a **Story da FEAT primária** — criar antes as Stories que faltarem (§6.1) — e as FEATs secundárias recebem link "relates to"; sem FEATs ou sem `issueType.feature`, parent = issue principal da SPEC, como sempre. Best-effort (§0): conector indisponível/falha → aviso, sem bloquear a geração das TASKs.

## Output final ao usuário

1. Quantidade de tasks geradas e tamanho dominante.
2. Convenções aplicadas (da ficha/perfil).
3. Caminho do TASK-MMM-INDEX.md.
4. Caminho do INDEX.md do slug atualizado.
5. Resultado da validação: errors, warnings.
6. Tasks da Wave 1 (por onde começar).
7. Gaps detectados (FRs sem TASK ou ACs sem verificação).
8. Cobertura por funcionalidade (FEAT → TASKs), se a SPEC declara FEATs.
9. Próximo comando: `/keelson:implement PLAN-MMM` ou `--dry-run` primeiro.
