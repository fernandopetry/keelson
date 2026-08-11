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
2. Carregar o **perfil de linguagem ativo** e suas convenções de teste (doutrina `core/*`: vale sempre; carga, resolução e avisos conforme o mapa da convenção comum — `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`), mais as demais seções do perfil conforme a área.
3. Extrair: convenção de branch, padrão de commit, granularidade típica, DoD padrão, framework de teste (do perfil).

### 0.2 Resolver PLAN

1. Buscar `{docsRoot}/*/plans/PLAN-MMM-*.md`. Desambiguar.
2. Ler PLAN completo.
3. Ler SPEC referenciada (ACs). Se a §5 da SPEC declara FEATs (headings `### FEAT-`),
   extrair o mapa FR→FEAT (posicional: o FR pertence à FEAT sob cujo heading está).
4. Slug é a pasta-pai de `plans/`.

### 0.3 Ler INDEX.md

Ler `{docsRoot}/<slug>/INDEX.md`: confirmar que o PLAN está listado e identificar os PLANs anteriores e suas contagens de tasks. Se o INDEX não existe, parar e reportar.

### 0.4 Próximo XXX

Próximo XXX: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh" {docsRoot}/<slug> task <MMM>` — nunca de cabeça. Criar pasta `tasks/` se não existir.

## Etapa 0.5: redação delegada ao `scribe` (decisão 4.103)

A decomposição e a redação das TASKs **não acontecem nesta janela** — despache o agent `scribe` com o pacote:

- **Contrato**: este arquivo (`${CLAUDE_PLUGIN_ROOT}/commands/tasks.md`), Etapas 1 a 4 — princípios
  de decomposição, ordenação, template da TASK **e** o `TASK-MMM-INDEX.md` (parte da autoria).
- **Alvo resolvido**: slug, MMM, próximo XXX, caminhos (Etapa 0.4); flags `--max-size`/`--only`.
- **Insumos** (caminhos): PLAN, SPEC (ACs e mapa FR→FEAT da 0.2), convenções extraídas na
  0.1 (resumo inline), memo de exploração e/ou `MAP.md` do slug, e `guidelines/project/lessons.md` se existir (cruzamento da Etapa 3).

Receba o sumário estruturado (`agents/scribe.md`): `insumos_index.contagens` alimenta a
Etapa 6; `duvidas` não-vazias → resolva (pergunte; no modo autônomo, escada) e re-despache
só o delta. Agent indisponível → Etapas 1–4 inline como fallback, declarado no output.

## Etapa 1: princípios de decomposição (contrato — executado pelo `scribe`)

1. **Atomicidade**: executável e revisável em uma sessão.
2. **Independência máxima — mas a aresta entre tasks irmãs tem dono** (decisão 4.106).
   Duas tasks da mesma wave cujo resultado só se completa combinado — mesmo consumidor de
   dado ou uma cria a superfície que a outra expõe — não são independentes: uma cria e
   **nomeia** o símbolo/ponto de entrada (constante/enum, nunca grafia solta); a que fecha
   a ponta carrega o item no próprio "Escopo > Inclui", nunca deduzido por quem achar a
   lacuna. Casos reais: flag gravada `remember_me` numa task e `remember` na irmã;
   listagem sem o clique para o detalhe da irmã. Nenhum gate vê duas tasks ao mesmo tempo — só a decomposição previne.
3. **Verificabilidade**: critério de pronto observável.
4. **Vertical slicing — com teste** (decisão 4.157): concluída, a TASK entrega um
   comportamento verificável **sozinho** — o critério de gate 1 (e o roteiro de gate 9,
   quando houver) executa sem esperar TASK de outra camada. Se a verificação de
   comportamento só existe quando uma irmã de wave posterior terminar, o corte foi
   horizontal: refatie pelo comportamento, atravessando as camadas que ele exigir
   (`Componente` aceita lista). O mapa FR→COMP do PLAN documenta arquitetura — **não
   dita granularidade de TASK**. Fatias do mesmo fluxo que disputam a mesma superfície
   declaram a aresta (princípio 2): a primeira fatia abre o esqueleto, as seguintes
   adicionam. Exceções com nome: fatia sensível destacada (princípio 8) e **refactor
   largo** — mudança mecânica cujo raio de dano atravessa a base inteira não cabe em
   fatia vertical; sequencie como **expand–contract**: expandir (a forma nova nasce ao
   lado da velha, nada quebra), migrar os call sites em lotes dimensionados pelo raio
   (cada lote uma TASK dependente do expand, suíte verde a cada lote), contrair (apagar
   a forma velha numa TASK que depende de todos os lotes).
5. **Setup-first**: scaffolding/migration com IDs baixos.
6. **Sem invenção de escopo — nem por dedução**: a TASK só afirma o que **verificou**.
   Caminho citado no "Inclui" foi confirmado pela **cadeia do dado** (*quem consome a
   consulta/endpoint alterado?*) — vizinhança de nome aponta a tela errada; sem confirmar, descreva o consumidor ("a view que lista X").
7. **Granularidade** (sobrescrita pela ficha/`CLAUDE.md` se declarado): medida por
   **esforço e comportamento entregue, nunca por contagem de arquivos** — a fatia
   vertical típica toca 1 arquivo por camada e continua atômica. `small` = comportamento
   único e raso, 30 min a 2 h · `medium` = um caso de uso fim-a-fim, 2 a 4 h.
8. **Corte por risco, não por camada**. Cada TASK custa um ciclo developer + code-reviewer —
   granularidade fina multiplica revisões, não qualidade. **Fatia sensível** (seed de
   permissão, autorização, endpoint novo, migração, regra de negócio central) → TASK
   **própria**, mesmo pequena, para receber `security-engineer`/revisão focada. **Fatias
   mecânicas do mesmo fluxo** (as classes/módulos de um mesmo caso de uso) → agrupe numa
   TASK `medium` com uma revisão só; NÃO crie TASK por classe/camada quando nada exige
   revisão dedicada. Heurística: se duas tasks só fazem sentido revisadas juntas, elas são uma.

## Etapa 2: ordenação (contrato — executado pelo `scribe`)

Identificar dependências entre TASKs; ordenar topologicamente (paralelizáveis = mesma wave); numerar sequencialmente.

## Etapa 3: estrutura obrigatória de cada TASK (contrato — executado pelo `scribe`)

Um arquivo por task: `{docsRoot}/<slug>/tasks/TASK-MMM-XXX-<titulo-kebab>.md`.

```markdown
# TASK-MMM-XXX: <Título imperativo>

**Slug**: <slug>
**Pertence a**: PLAN-MMM
**Realiza (FRs)**: FR-NNN-XXX, FR-NNN-YYY <!-- lista de IDs ou `nenhuma` (chore sem FR) -->
**AC violado**: AC-NNN-XXX <!-- só Tipo=bugfix: o AC que o bug viola; omitir a linha nos demais tipos -->
**Funcionalidade**: FEAT-NNN-XXX (primária)[, FEAT-NNN-YYY]
**Componente**: COMP-MMM-XXX (principal)[, COMP-MMM-YYY] <!-- os COMPs que a fatia atravessa; principal = onde vive o núcleo da mudança -->
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
prevalecem; nunca siga um passo que enfraqueça um critério." (evita a leitura mais fraca).>

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

`Realiza (FRs)`, `AC violado`, `Componente`, `Depende de` e `Bloqueia` são **campos de
aresta**: IDs separados por vírgula, ou `nenhuma` — prosa vai para Contexto/Escopo. ACs citados em item
`- [ ]` dos "Critérios de pronto" e do "Roteiro do gate 9" também viram aresta (cobertura);
menção em prosa corrida não conta. Régua completa: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`.

### Campo `Funcionalidade` — derivado dos FRs, nunca inventado

Só existe quando a SPEC declara FEATs na §5 — **SPEC sem FEATs → omitir a linha** (a
funcionalidade é a própria SPEC); task `chore` sem FR realizado pode omitir. O conjunto
listado é **exatamente** o das FEATs dos FRs de `Realiza (FRs)` (mapa FR→FEAT da Etapa
0.2) — nem a mais, nem a menos. Uma FEAT é marcada `(primária)`: a com mais FRs
realizados (empate → menor ID); julgamento pode sobrescrever a heurística, mas a primária
pertence ao conjunto derivado. Task **transversal** (FRs de 2+ FEATs) lista todas; **sem
primária honesta** use `**Funcionalidade**: transversal (FEAT-NNN-XXX, FEAT-NNN-YYY)` — sem `(primária)` (projeção Jira: `jira-sync-feat.md`).

### Mapeamento de cada AC — camada que enforça, gate que verifica

Primeiro decida **qual camada enforça** o AC e liste-o nos "Critérios de pronto" **dessa** task, não de uma vizinha: recusa por **estado prévio** (ex.: registro já vinculado) é guard da camada de regra de negócio; unicidade por **corrida/persistência** é da camada de persistência; **autorização/borda** é da camada de entrada; **comportamento de tela** é do frontend (gate de tela, quando `gates.screenVerify`). AC não enforçável na camada da task (ex.: uma escrita idempotente que delega a unicidade ao armazenamento) não é testável ali — realoque para a task que o impõe. Critério **herdado** por extenso (vem de requisito/NFR/lição citado por completo, não de um AC desta wave — decisão 4.138) segue a mesma exigência de **endereço**: nomeia o arquivo e a ação que o cumprem, e o "Escopo > Inclui" da task que o recebe **incorpora** esse arquivo — senão vira TASK própria na mesma wave. Teste: se a verificação do critério não aponta para arquivo que o Inclui autoriza tocar, o critério está mal endereçado — cumprido à risca, o requisito segue violado sem grep nenhum acusar (caso real: "1 gesto → no máximo 1 toast" endereçado a 2 views; o ponto real era o interceptor global de requisições, fora do Inclui de toda a wave).

Depois, cada AC mapeia para **exatamente um** gate de verificação. NÃO liste o mesmo AC em dois gates com exigências distintas (ex.: "testes cobrem AC-X" **e** "gate 9 cobre AC-X"): a ambiguidade faz o developer escolher a verificação mais fraca e um MUST fica sem teste falsificável. Regra: **MUST testável em unidade → teste no gate 1**; o gate 9 (comportamento verificado / caminhada de tela quando `gates.screenVerify`) só **confirma** o fluxo ponta-a-ponta, nunca substitui o teste. Respeite o gate que a DoD do PLAN atribui ao AC — nunca rebaixe de gate 1 (teste) para gate 9 (manual).

Todo item de **gate 1** registra a **verificação executável** — comando + saída/efeito esperado — **antes** do código: o critério nasce do AC, nunca do diff (gerador ≠ avaliador); critério de teste sem comando+esperado → `task-validator` reprova (ERROR). O par tem de ser **falsificável** — pergunte "que estado faz este comando FALHAR?"; sem resposta, o critério aprova qualquer coisa — e falsificável no papel não basta: **o comando é executado na fixação** e a evidência de conjunto não-vazio entra no critério, junto do par comando+esperado (ex.: `OK (12 tests)` — nunca `No tests executed`). Ausência/vazio é o estado default de um comando mal ancorado — filtro que não casa classe nenhuma, grupo excluído da suíte, glob que não resolve, `git diff --name-only` sem a âncora `main...HEAD` (compara com o índice e devolve vazio depois do commit) — e comando verde sobre o vazio cumpre o critério à risca aprovando qualquer diff; corolário: predicado que **exclui** se fixa com um dado que ele **rejeita** (decisão 4.93). Esperado do tipo "não piorou" (suíte, baseline de tipos) exige a baseline capturada **antes** de começar, dentro do próprio critério — capturada, ela também prova que o conjunto não é vazio. E todo **exemplo literal** que ilustra um critério é conferido contra qualquer regra formal (regex, formato) já mandatória em **outra seção da mesma TASK** — nunca inventado à parte: se o Escopo fixa um padrão, o dado do exemplo tem de casá-lo (caso real: Escopo exigia regex de chave com prefixo de 2+ letras e o critério de dedupe ilustrava com `B-2, A-1` — chaves que o próprio regex nunca casa; custou uma rodada de correção na closure).

Em TASK `Tipo: bugfix`, o par do gate 1 nasce do **repro vermelho** (decisão 4.159 — fecha o degrau "prova do vermelho" da escada da 4.123): o comando reproduz o **sintoma exato** do `AC violado` e é executado na fixação **falhando** — a evidência do vermelho (mensagem de erro, saída errada) entra no critério, no lugar da evidência de conjunto não-vazio dos demais tipos. Depois do fix, o mesmo comando passa e vira o teste de regressão. Teste que nunca ficou vermelho não prova o conserto: pode estar verde porque testa outra coisa — o vermelho capturado antes é o que amarra o teste ao bug real, não ao diagnóstico imaginado.

O critério também tem de **resistir a contorno** (decisão 4.107) — três testes na fixação: (a) valor **literal** no comando ou critério (nome de serviço, credencial, símbolo/constante de convenção do projeto) é conferido contra a **fonte real** (arquivo de infra, grep do padrão já em uso) antes de escrito, nunca presumido — credencial chutada custa uma volta ao developer; pior, literal fixado contra a convenção real faz o cumprimento à risca **quebrar** o código certo; (b) invariante **estrutural** (chamada proibida, camada que não pode importar outra) verificado por `grep` que casa **caminho**+conteúdo é satisfeito por **relocação** — mover a chamada para um arquivo cujo caminho não bate no padrão zera o comando sem mudar a substância; ancore por **símbolo** (FQCN/método) num guard fail-closed, nunca por padrão de caminho; (c) AC cuja camada de persistência introduz um predicado de **escopo** (tenant, dono, agregado pai) exige, já no gate 1, o critério de **mutação** sobre esse predicado com fechamento **contável** — nunca uma lista de instâncias (decisão 4.139): "todo método cujo WHERE carrega esse escopo tem cenário de segunda instância cuja mutação reprova — N métodos no Escopo, N provas", mais um caso por ramo do predicado nos métodos de leitura; método nomeado entra só como ilustração **não-exaustiva**, nunca como a lista completa. Fixture com **dois** pais (duas instâncias/donos) e o predicado neutralizado **reprovando** o teste, fixado na TASK e nunca deixado para o gate 8 descobrir com o código pronto: fixture de um pai só não tem o que vazar, o predicado fica decorativo e a suíte segue verde com ele removido (casos reais: três rodadas de gate 8 no mesmo ciclo, pela mesma causa; depois da régua existir, TASK que enumerou a prova para 2 de 4 métodos com escopo no WHERE — 5 mutantes sobreviventes com a suíte 100% verde).

E a cobertura fecha **de trás para frente**: o mapeamento AC→critério não alcança item do "Escopo > Inclui" **sem AC** — contrato criado nesta wave e lido só em wave posterior (VO, porta, chave de serialização). Todo item do Inclui carrega ao menos um critério **próprio e executável**; "testes de tudo acima" não é critério. Sem AC, o oráculo é o **contrato do próprio item** — cada método público e cada chave nova exercitados com valor **não-nulo**, mesmo que nesta wave o valor real nasça sempre nulo. Item do Inclui que nenhum critério referencia → `task-validator` reprova (ERROR).

Antes de fixar os Critérios de pronto, cruze os arquivos-alvo do "Escopo > Inclui" contra `guidelines/project/lessons.md` (insumo da 0.5): lição que **nomeia** esses arquivos (ou o padrão que eles encarnam) vira item **verificável** do Critério de pronto — nunca leitura recomendada (decisão 4.138). Lição escrita numa wave e não reforçada como critério na próxima TASK que toca o mesmo arquivo é lição inerte (caso real: regra de escopo registrada com o arquivo nomeado uma wave antes; o método novo nasceu no mesmo arquivo violando-a, achado só no gate 8 — uma rodada de retry para um defeito com nome, causa e arquivo escritos antes do código).

### Roteiro do gate 9 — fixado antes do código

Com `gates.screenVerify` ativo e algum AC atribuído ao gate 9, a TASK carrega a seção `## Roteiro do gate 9 (fixado ANTES do código)` (ver template). Ela abre com **ambiente** (URLs digitáveis — com a base de rota real do app — + realm), **sujeito concreto** (qual identidade loga, com que credencial) e **pré-condição com receita** — como montar o estado e como restaurá-lo ao fim; "com um usuário sem permissão" não é pré-condição, é desejo. **Um passo por AC**: AC de gate 9 sem passo é AC sem gate. Antes de escrever, leia os handoffs anteriores do slug (`{docsRoot}/<slug>/handoffs/`): cenário já registrado ali como não-exercitável neste ambiente **não vira passo por herança** — reaproveite a receita e a prova substitutiva já aceitas, ou prescreva nova tentativa **nomeando o que mudou** desde o registro ("não exercitável" é registro datado, não veredicto permanente; a revisita é decisão consciente, nunca desconhecimento do handoff). AC de interação **hierárquica** (arrastar/reordenar itens dentro de um agrupamento — contêiner, pasta, grupo) inclui, além do passo interno, um passo que **cruza a fronteira** do agrupamento — mover o item para outro contêiner (decisão 4.107): o código que reordena "dentro" raramente é o que resolve "entre", é a classe de defeito mais provável da estrutura, e um roteiro que só exercita o reordenar interno não a alcança.

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
(contrato: `graph-contract.md`). Defeito de geração (ciclo, wave incoerente, referência quebrada) → corrija antes do gate; script indisponível/falhou → siga declarando a degradação.

**Correção** (decisão 4.114): delta ao `scribe`, **aguardado**, com a lista literal de
ERRORs; buraco de numeração não é defeito, arquivo existente nunca se renumera — protocolo do invocador: `graph-contract.md` §4.1.

Com o grafo limpo (e o scribe encerrado), invocar a skill `task-validator` em modo batch
(apontando para o TASK-MMM-INDEX) — em paralelo com o `tracker-sync` da Etapa 7 quando o
sync está ativo (4.113: o validator só lê; o sync só escreve linhas `Jira:`) e, no ciclo
formal, com o `qa` pré-código na mesma rodada (Etapa 3.5 do auto — 4.116): **errors == 0**
→ prosseguir; **errors > 0** → reportar por TASK — INDEX atualizado mesmo assim, Status
`Blocked` nas tasks com error; no ciclo, o achado desagua na **rodada consolidada do
invocador** (4.116), sem volta de correção própria deste comando.

## Etapa 6: atualização do INDEX.md do slug

Aplicar a **receita de atualização do INDEX** (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`). Específico desta etapa: atualizar a coluna `Tasks` na linha do PLAN-MMM, no formato canônico do contrato — de `0/? ⏸` para `0/<total de tasks geradas> ⏸`.

## Etapa 7: sincronização com Jira (opcional)

Só quando a ficha tem `jira.enabled: true`: **despache o agent `tracker-sync`** (decisão 4.103) — na rodada paralela com o `task-validator` da Etapa 5 (decisão 4.113); nunca com o scribe ainda editando as TASKs — com o gancho **`tasks`**: caminhos do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; §§ do gancho: §6.2, §7, §8, §10; mais `jira-sync-feat.md` quando a projeção de 3 níveis está ativa), da ficha, da SPEC e das TASKs geradas. Ele cria uma **sub-task por TASK**, grava a key no campo `Jira:` da closure de cada uma e devolve o resumo canônico. Best-effort (§0): `eventos_tracker` no retorno → evento `tracker` no ledger + **seção de reconexão da §14** no fecho deste comando; num `/keelson:auto`, desagua no item 7.4 da Entrega. Agent indisponível → aplicar o protocolo inline (mesmos §§) é o fallback, declarado no output.

## Output final ao usuário

1. Quantidade de tasks geradas, tamanho dominante e convenções aplicadas (da ficha/perfil).
2. Caminhos: TASK-MMM-INDEX.md e INDEX.md do slug atualizado.
3. Resultado da validação (errors, warnings) e gaps detectados (FRs sem TASK, ACs sem verificação).
4. Tasks da Wave 1 (por onde começar); cobertura por funcionalidade (FEAT → TASKs), se a SPEC declara FEATs.
5. Próximo comando, com o **caminho** do PLAN (4.124): `/keelson:implement {docsRoot}/<slug>/plans/PLAN-MMM-<nome>.md` ou `--dry-run` primeiro.
