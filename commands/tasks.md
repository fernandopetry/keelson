---
description: Decompõe um PLAN em TASKs atômicas ordenadas em waves, com campos de closure preparados, e atualiza o INDEX do slug
argument-hint: <PLAN-MMM ou caminho> [--max-size=small|medium] [--only=COMP-MMM-XXX]
---

# /keelson:tasks

Você é um Tech Lead especialista em decompor planos arquiteturais em tarefas atômicas executáveis por agentes de IA.

**Princípio inviolável 1**: convenções de execução (branch, commit, granularidade, DoD) seguem o `CLAUDE.md` do projeto (ou Conventional Commits como padrão) e o perfil de linguagem ativo.

**Princípio inviolável 2**: cada TASK contém **campos de closure vazios** que o `/keelson:implement` preencherá.

## Input

| Flag | Uso |
|---|---|
| `--max-size=<small\|medium>` | Teto de granularidade: nenhuma TASK gerada excede esse tamanho (sem a flag, vale a calibração dos itens 7-8 da Etapa 1) |
| `--only=COMP-MMM-XXX` | Decompõe apenas o componente indicado; os demais COMPs do PLAN ficam para uma execução futura (reportar o gap no output) |

## Etapa 0: resolver PLAN, guidelines e localização

### 0.1 Carregar guidelines

1. Ler a **ficha** (`keelson.config.json`) e o `CLAUDE.md` do projeto se existir.
2. Carregar o **perfil de linguagem ativo** e suas convenções de teste (doutrina `core/*`: vale sempre, carga conforme o mapa da convenção comum — `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`; resolução e avisos do perfil: mesma convenção), mais as demais seções do perfil conforme a área.
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

## Etapa 0.5: redação delegada ao `scribe` (decisão 4.103)

A decomposição e a redação das TASKs **não acontecem nesta janela**. Despache o agent
`scribe` com o pacote:

- **Contrato**: este arquivo (`${CLAUDE_PLUGIN_ROOT}/commands/tasks.md`), Etapas 1 a 4 —
  princípios de decomposição, ordenação, template da TASK **e** o `TASK-MMM-INDEX.md`
  (parte da autoria).
- **Alvo resolvido**: slug, MMM, próximo XXX, caminhos (Etapa 0.4); flags `--max-size`/`--only`.
- **Insumos** (caminhos): PLAN, SPEC (ACs e mapa FR→FEAT da 0.2), convenções extraídas na
  0.1 (resumo inline), memo de exploração e/ou `MAP.md` do slug.

Receba o sumário estruturado (`agents/scribe.md`): `insumos_index.contagens` (TASKs/waves)
alimenta a Etapa 6; `duvidas` não-vazias → resolva (pergunte; no modo autônomo, escada) e
re-despache só o delta. Agent indisponível → executar as Etapas 1–4 inline é o fallback,
declarado no output.

## Etapa 1: princípios de decomposição (contrato — executado pelo `scribe`)

1. **Atomicidade**: executável e revisável em uma sessão.
2. **Independência máxima**.
3. **Verificabilidade**: critério de pronto observável.
4. **Vertical slicing**.
5. **Setup-first**: scaffolding/migration com IDs baixos.
6. **Sem invenção de escopo — nem por dedução**: a TASK só afirma o que **verificou**.
   Caminho citado no "Inclui" foi confirmado pela **cadeia do dado** (*quem consome a
   consulta/endpoint que esta entrega altera?*), nunca deduzido do nome — vizinhança de
   nome aponta a tela errada e entrega a funcionalidade onde ela não renderiza. Sem
   confirmar, descreva o consumidor ("a view que lista X") em vez de chutar o caminho.
7. **Granularidade**:
   - `small`: 1 arquivo principal, 1 a 3 testes, 30 min a 2 h
   - `medium`: até 3 arquivos relacionados, 2 a 4 h
   (sobrescrito pela ficha/`CLAUDE.md` se declarado)
8. **Corte por risco, não por camada**. Cada TASK custa um ciclo developer + code-reviewer —
   granularidade fina multiplica revisões, não qualidade:
   - **Fatia sensível** (seed de permissão, autorização, endpoint novo, migração,
     regra de negócio central) → TASK **própria**, mesmo que pequena, para receber
     `security-engineer`/revisão focada.
   - **Fatias mecânicas do mesmo fluxo** (as várias classes/módulos de um mesmo caso
     de uso) → **agrupe numa TASK `medium`** com uma revisão só. NÃO crie uma TASK
     por classe/camada quando nada nelas exige revisão dedicada.
   - Heurística: se duas tasks só fazem sentido revisadas juntas, elas são uma.

## Etapa 2: ordenação (contrato — executado pelo `scribe`)

1. Identificar dependências entre TASKs.
2. Ordenar por dependência topológica. Tasks paralelizáveis recebem mesma wave.
3. Numerar sequencialmente.

## Etapa 3: estrutura obrigatória de cada TASK (contrato — executado pelo `scribe`)

Um arquivo por task: `{docsRoot}/<slug>/tasks/TASK-MMM-XXX-<titulo-kebab>.md`.

```markdown
# TASK-MMM-XXX: <Título imperativo>

**Slug**: <slug>
**Pertence a**: PLAN-MMM
**Realiza (FRs)**: FR-NNN-XXX, FR-NNN-YYY <!-- lista de IDs ou `nenhuma` (chore sem FR) -->
**AC violado**: AC-NNN-XXX <!-- só Tipo=bugfix: o AC que o bug viola; omitir a linha nos demais tipos -->
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

- **Depende de**: TASK-MMM-AAA, TASK-MMM-BBB <!-- lista de IDs ou `nenhuma` -->
- **Bloqueia**: TASK-MMM-CCC <!-- lista de IDs ou `nenhuma`; preencher após gerar todas -->

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
- [ ] Testes cobrem AC-NNN-XXX (listar ACs) — verificação executável: `<comando>` → <saída/efeito esperado>, fixada antes do código
- [ ] Sem warnings/lints novos
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Roteiro do gate 9 (fixado ANTES do código)

<!-- Só com gates.screenVerify ativo e AC atribuído ao gate 9 — régua na seção "Roteiro do gate 9" abaixo; sem gate 9, omitir. Ambiente (URLs digitáveis + realm) · sujeito concreto (identidade + credencial) · pré-condição com receita (montar + restaurar) · um passo por AC. -->

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
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): verificado | n/a — <qa ou motivo do n/a>

**Notas**: 
```

### Campos de aresta — sintaxe canônica do grafo

`Realiza (FRs)`, `AC violado`, `Depende de` e `Bloqueia` são **campos de aresta**:
lista de IDs separados por vírgula, ou `nenhuma` — prosa vai para Contexto/Escopo. Os
ACs citados em item `- [ ]` dos "Critérios de pronto" e no "Roteiro do gate 9" também
viram aresta (cobertura); menção a AC em prosa corrida não conta como cobertura. A
régua completa (sintaxe, catálogo, extrator) tem dono único:
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`.

### Campo `Funcionalidade` — derivado dos FRs, nunca inventado

Só existe quando a SPEC declara FEATs na §5 — **SPEC sem FEATs → omitir a linha** (a
funcionalidade é a própria SPEC). Task `chore` sem FR realizado pode omitir. Regras:
- O conjunto listado é **exatamente** o conjunto de FEATs dos FRs de `Realiza (FRs)`
  (via mapa FR→FEAT da Etapa 0.2) — nem a mais, nem a menos.
- Uma FEAT é marcada `(primária)`: a que tem mais FRs realizados pela task (empate →
  menor ID). Julgamento pode sobrescrever a heurística, mas a primária deve pertencer
  ao conjunto derivado.
- Task **transversal** (FRs de 2+ FEATs — ex.: um front único servindo login e
  lançamento) lista todas.
- **Sem primária honesta** (a task serve a todas/quase todas as FEATs e eleger uma seria
  arbitrário): use a forma `**Funcionalidade**: transversal (FEAT-NNN-XXX, FEAT-NNN-YYY)`
  — sem `(primária)` (projeção Jira: `jira-sync-feat.md`).

### Mapeamento de cada AC — camada que enforça, gate que verifica

Primeiro decida **qual camada enforça** o AC e liste-o nos "Critérios de pronto" **dessa** task, não de uma vizinha: recusa por **estado prévio** (ex.: registro já vinculado) é guard da camada de regra de negócio; unicidade por **corrida/persistência** (violação de restrição → conflito) é da camada de persistência; **autorização/borda** é da camada de entrada; **comportamento de tela** é do frontend (gate de tela, quando `gates.screenVerify`). AC não enforçável na camada da task (ex.: uma escrita idempotente que delega a unicidade ao armazenamento) não é testável ali — realoque para a task que o impõe.

Depois, cada AC mapeia para **exatamente um** gate de verificação. NÃO liste o mesmo AC em dois gates com exigências distintas (ex.: "testes cobrem AC-X" **e** "gate 9 cobre AC-X"): a ambiguidade faz o developer escolher a verificação mais fraca e um MUST fica sem teste falsificável (uma mutação passaria os testes verdes). Regra: **MUST testável em unidade → teste no gate 1**; o gate 9 (comportamento verificado / caminhada de tela quando `gates.screenVerify`) só **confirma** o fluxo ponta-a-ponta, nunca substitui o teste. Respeite o gate que a DoD do PLAN atribui ao AC — nunca rebaixe de gate 1 (teste) para gate 9 (manual).

Todo item de **gate 1** registra a **verificação executável** — comando + saída/efeito esperado — **antes** do código: o critério nasce do AC, nunca do diff (gerador ≠ avaliador). Critério de teste sem comando+esperado → `task-validator` reprova (ERROR).

O par comando+esperado tem de ser **falsificável**: pergunte "que estado faz este comando FALHAR?" — sem resposta, o critério aprova qualquer coisa. Atenção ao **esperado por ausência** (saída vazia, caminho que não aparece, nenhum resultado): ausência é o estado default de um comando mal ancorado, então o comando precisa de âncora explícita — `git diff --name-only main...HEAD`, nunca `git diff --name-only`, que compara com o índice e devolve vazio depois do commit, aprovando qualquer diff. Esperado do tipo "não piorou" (suíte, baseline de tipos) exige a baseline capturada **antes** de começar, dentro do próprio critério. E todo **exemplo literal** que ilustra um critério é conferido contra qualquer regra formal (regex, formato) já mandatória em **outra seção da mesma TASK** — nunca inventado à parte: se o Escopo fixa um padrão, o dado do exemplo tem de casá-lo (caso real: Escopo exigia regex de chave com prefixo de 2+ letras e o critério de dedupe ilustrava com `B-2, A-1` — chaves que o próprio regex nunca casa; o developer notou, mas custou uma rodada de correção na closure).

Falsificável no papel não basta: **o comando é executado na fixação** e a evidência de conjunto não-vazio entra no critério, junto do par comando+esperado (ex.: `OK (12 tests)` — nunca `No tests executed`). Comando verde sobre o vazio — filtro que não casa classe nenhuma, grupo excluído da suíte, glob que não resolve — cumpre o critério à risca e aprova qualquer coisa. Corolário: predicado que **exclui** se fixa com um dado que ele **rejeita**; baseline capturada prova que não é vazia (decisão 4.93).

E a cobertura fecha **de trás para frente**: o mapeamento AC→critério não alcança item do "Escopo > Inclui" **sem AC** — contrato criado nesta wave e lido só em wave posterior (VO, porta, chave de serialização). Todo item do Inclui carrega ao menos um critério **próprio e executável**; "testes de tudo acima" não é critério. Sem AC, o oráculo é o **contrato do próprio item** — cada método público e cada chave nova exercitados com valor **não-nulo**, mesmo que nesta wave o valor real nasça sempre nulo. Item do Inclui que nenhum critério referencia → `task-validator` reprova (ERROR).

### Roteiro do gate 9 — fixado antes do código

Com `gates.screenVerify` ativo e algum AC atribuído ao gate 9, a TASK carrega a seção `## Roteiro do gate 9 (fixado ANTES do código)` (ver template). Ela abre com **ambiente** (URLs digitáveis — com a base de rota real do app — + realm), **sujeito concreto** (qual identidade loga, com que credencial) e **pré-condição com receita** — como montar o estado e como restaurá-lo ao fim; "com um usuário sem permissão" não é pré-condição, é desejo. **Um passo por AC**: AC de gate 9 sem passo é AC sem gate. Antes de escrever, leia os handoffs anteriores do slug (`{docsRoot}/<slug>/handoffs/`): cenário já registrado ali como não-exercitável neste ambiente **não vira passo por herança** — reaproveite a receita e a prova substitutiva já aceitas, ou prescreva nova tentativa **nomeando o que mudou** desde o registro ("não exercitável" é registro datado, não veredicto permanente; a revisita é decisão consciente, nunca desconhecimento do handoff).

## Etapa 4: índice de tasks do PLAN (contrato — executado pelo `scribe`)

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

Após gerar todas as TASKs e o TASK-MMM-INDEX, **conferir o grafo mecanicamente**:
`${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh {docsRoot}/<slug> --check --stage=tasks --plan MMM`
(contrato: `graph-contract.md`). Ciclo, wave incoerente ou referência quebrada aqui é
defeito de geração — corrija as TASKs antes do gate, não deixe para o validator.
Script indisponível/falhou → siga ao gate declarando a degradação.

Em seguida, invocar a skill `task-validator` em modo batch (apontando para o TASK-MMM-INDEX).

**Se errors == 0**: prosseguir.
**Se errors > 0**: reportar errors específicos por TASK. INDEX do slug ainda é atualizado, mas Status das tasks com error fica `Blocked`.

## Etapa 6: atualização do INDEX.md do slug

Aplicar a **receita de atualização do INDEX** (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`). Específico desta etapa: atualizar a coluna `Tasks` na linha do PLAN-MMM, no formato canônico do contrato — de `0/? ⏸` para `0/<total de tasks geradas> ⏸`.

## Etapa 7: sincronização com Jira (opcional)

Só quando a ficha tem `jira.enabled: true`: **despache o agent `tracker-sync`** (decisão 4.103) com o gancho **`tasks`**: caminhos do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; §§ do gancho: §6.2, §7, §8, §10; mais `jira-sync-feat.md` quando a projeção de 3 níveis está ativa), da ficha, da SPEC e das TASKs geradas. Ele cria uma **sub-task por TASK**, grava a key no campo `Jira:` da closure de cada uma e devolve o resumo canônico. Best-effort (§0): `eventos_tracker` no retorno → evento `tracker` no ledger + **seção de reconexão da §14** no fecho deste comando; num `/keelson:auto`, desagua no item 7.4 da Entrega. Agent indisponível → aplicar o protocolo inline (mesmos §§) é o fallback, declarado no output.

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
