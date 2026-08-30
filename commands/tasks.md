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

## Etapa 0.5: redação delegada ao `scribe` (decisões 4.103, 4.310)

A decomposição e a redação das TASKs **não acontecem nesta janela** — e a rota do despacho
segue o tamanho **previsto** (fonte: seção `## Estimativa` do BRIEF quando existe; senão,
contagem de COMPs do PLAN — >10 COMPs indica decomposição grande). Previsão errada custa
pouco: as duas rotas produzem os mesmos arquivos e passam pelas mesmas provas da Etapa 5.

**Rota única (previsão ≤8 TASKs)** — despache **um** `scribe` com o pacote:

- **Contrato**: este arquivo (`${CLAUDE_PLUGIN_ROOT}/commands/tasks.md`), Etapas 1 a 4 — princípios
  de decomposição, ordenação, template da TASK **e** o `TASK-MMM-INDEX.md` (parte da autoria).
- **Alvo resolvido**: slug, MMM, próximo XXX, caminhos (Etapa 0.4); flags `--max-size`/`--only`.
- **Insumos** (caminhos): PLAN, SPEC (ACs e mapa FR→FEAT da 0.2), convenções extraídas na
  0.1 (resumo inline), memo de exploração e/ou `MAP.md` do slug, e `guidelines/project/lessons.md` se existir (cruzamento da Etapa 3).

**Rota fan-out (previsão >8 TASKs — decisão 4.310)**: uma janela serial que decide E
redige 12+ arquivos é o gargalo medido da forja; a rota divide em duas fases do **mesmo
agent** (briefings distintos do `scribe`, nunca agents novos):

1. **Decompositor**: um `scribe` com o pacote acima, Etapas 1 a 3 como régua de decisão,
   e a instrução de **não escrever arquivo nenhum**: o retorno é um **manifesto
   congelado** — por TASK: ID, título, tipo, tamanho, wave, `Depende de`/`Bloqueia`,
   FRs/FEATs/COMPs, distribuição AC×gate, bullets de Inclui/Não inclui e lições ativas
   aplicáveis. O manifesto é o produto intelectual da decomposição: ID e aresta ficam
   decididos aqui, e só aqui.
2. **Redatores**: 2–3 `scribe`s **em paralelo**, cada um com o manifesto + o contrato
   (Etapas 1 a 3, template da Etapa 3) + os insumos e uma **lista literal de arquivos**
   a redigir (fatia por wave; nunca "as TASKs da wave 2", que se sobrepõe). Redator
   **não cria nem renomeia ID e não toca aresta** — divergência com o manifesto volta
   em `duvidas`, nunca se corrige localmente (mesmo mecanismo da 4.114).
3. **`TASK-MMM-INDEX.md` é da main session nesta rota** (dono único — nenhum redator tem
   o todo): derive-o do manifesto (waves e tabelas de cobertura são projeção mecânica
   dele) **após o retorno de todos** os redatores; o commit do marco só então, por
   pathspec (4.163).

A consistência global não depende de disciplina dos redatores: o `graph.sh --check`
(Etapa 5) e o `task-validator` provam o resultado nas duas rotas.

Receba o(s) sumário(s) estruturado(s) (`agents/scribe.md`): `insumos_index.contagens` alimenta a
Etapa 6; `duvidas` não-vazias → resolva (pergunte; no modo autônomo, escada) e re-despache
só o delta. Agent indisponível → Etapas 1–4 inline como fallback, declarado no output.

## Etapa 1: princípios de decomposição (contrato — executado pelo `scribe`)

Colisão entre princípios resolve por precedência declarada (decisão 4.300): comportamento
que se prova no próprio fecho (4) > independência (2) > tamanho (7). A unidade governada do
ciclo é o **comportamento**; a decomposição técnica abaixo dela — arquivos, métodos, ordem
interna — é do developer na execução, nunca do plano.

1. **Atomicidade**: um comportamento por TASK, executável e revisável de uma vez.
2. **Costura só em contrato congelado** (decisão 4.300): interface que as duas metades
   ainda vão negociar **não se divide** entre TASKs — funda as metades ou congele o
   contrato antes (DEC do PLAN, schema decidido, API externa). Teste: dois developers
   independentes começariam atacando o mesmo problema? Então a fronteira ainda não
   existe. No **resíduo** inevitável (a fusão estoura o teto do princípio 7 e o contrato
   não congela), vale o protocolo da aresta (decisões 4.106/4.164, rebaixadas a exceção
   do resíduo): quem cria **nomeia** o símbolo (constante/enum, nunca grafia solta); quem
   fecha a ponta carrega o item no próprio "Escopo > Inclui", nunca deduzido — inclusive
   a camada **intermediária** quando o dado atravessa 3+ camadas (nó que nunca virou task
   não é aresta que algum gate alcance).
3. **Verificabilidade**: critério de pronto observável.
4. **Vertical slicing — a prova executa no próprio fecho** (decisões 4.157/4.300):
   concluída, a TASK entrega um comportamento verificável **sozinho** — o critério de
   gate 1 (e o roteiro de gate 9, quando houver) executa sem esperar TASK de outra
   camada, e o **ponto de entrada** do comportamento (rota, comando, tela) pertence à
   própria TASK, nunca a uma task de wiring posterior. Corte por **capacidade, nunca por
   camada** (`Componente` aceita lista; o mapa FR→COMP documenta arquitetura — **não dita
   granularidade**). Comportamento maior que o teto do princípio 7 divide-se em
   comportamentos menores, jamais em rodelas técnicas. Exceções com nome: fatia sensível
   (princípio 8) e **refactor largo** — mudança mecânica cujo raio de dano atravessa a
   base inteira segue **expand–contract**: expandir (a forma nova nasce ao lado da velha,
   nada quebra), migrar os call sites em lotes dimensionados pelo raio (cada lote uma
   TASK dependente do expand, suíte verde a cada lote), contrair (apagar a forma velha
   numa TASK que depende de todos os lotes).
5. **Setup-first**: scaffolding/migration com IDs baixos.
6. **Sem invenção de escopo — nem por dedução**: a TASK só afirma o que **verificou**.
   Caminho citado no "Inclui" foi confirmado pela **cadeia do dado** (*quem consome a
   consulta/endpoint alterado?*) — vizinhança de nome aponta a tela errada; sem confirmar, descreva o consumidor ("a view que lista X").
   **Nome também se verifica (decisão 4.229)**: arquivo **novo** citado no Inclui tem
   nome/prefixo conferido contra a convenção de nomenclatura do perfil ativo (prefixo
   reservado a design system, sufixo de camada) antes de escrito — prefixo que soa
   idiomático não dispensa a checagem (caso real: 2 componentes nasceram com o prefixo
   que o perfil reserva, únicos no repo). Perfil sem seção de nomenclatura → declare e
   siga.
7. **Granularidade** (sobrescrita pela ficha/`CLAUDE.md` se declarado): medida por
   **esforço e comportamento entregue, nunca por contagem de arquivos** — a fatia
   vertical típica toca 1 arquivo por camada e continua atômica. `small` = comportamento
   único e raso, ~30 min a 2 h · `medium` = comportamento fim-a-fim completo, ~2 a 8 h —
   o teto real é o **horizonte de execução confiável** do developer, não a janela de
   contexto; estourou → princípio 4: dividir por capacidade.
8. **Corte por risco, não por camada**. Cada TASK custa um ciclo developer + revisão —
   granularidade fina multiplica revisões, não qualidade. **Fatia sensível** (seed de
   permissão, autorização, endpoint novo, migração, regra de negócio central) → TASK
   **própria**, mesmo pequena, para receber `security-engineer`/revisão focada. **TRISK
   com incerteza numérica** (teto/volume/latência estimados, nunca medidos) → **task de
   medição** (tipo `chore`) antes das de implementação: o número medido corrige o PLAN, e
   TRISK medido deixa de forçar wave sequencial (implement, Etapa 1 — decisão 4.301).
   Heurística de fecho: duas tasks que só fazem sentido revisadas juntas são uma.

## Etapa 2: ordenação (contrato — executado pelo `scribe`)

Identificar dependências entre TASKs; ordenar topologicamente (paralelizáveis = mesma
wave); numerar sequencialmente. As dependências declaradas são o DAG que o implement
executa; a composição das waves **ainda não iniciadas** é refinável no fecho de cada wave,
com os fatos da anterior (decisão 4.301 — o rito é do `/keelson:implement`, §3.6).

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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
```

### Campos de aresta — sintaxe canônica do grafo

`Realiza (FRs)`, `AC violado`, `Componente`, `Depende de` e `Bloqueia` são **campos de
aresta**: IDs separados por vírgula, ou `nenhuma` — prosa vai para Contexto/Escopo. ACs citados nas seções
"Critérios de pronto" e "Roteiro do gate 9" (qualquer linha da seção, continuação de item incluída — 4.254)
também viram aresta (cobertura); menção fora dessas seções não conta. Régua completa: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`.

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

Todo item de **gate 1** registra a **verificação executável** — comando + saída/efeito esperado — **antes** do código: o critério nasce do AC, nunca do diff (gerador ≠ avaliador); critério de teste sem comando+esperado → `task-validator` reprova (ERROR). O par tem de ser **falsificável** — pergunte "que estado faz este comando FALHAR?"; sem resposta, o critério aprova qualquer coisa — e falsificável no papel não basta: **o comando é executado na fixação** e a evidência de conjunto não-vazio entra no critério, junto do par comando+esperado (ex.: `OK (12 tests)` — nunca `No tests executed`). Ausência/vazio é o estado default de um comando mal ancorado — filtro que não casa classe nenhuma, grupo excluído da suíte, glob que não resolve, `git diff --name-only` sem a âncora `main...HEAD` (compara com o índice e devolve vazio depois do commit) — e comando verde sobre o vazio cumpre o critério à risca aprovando qualquer diff; corolário: predicado que **exclui** se fixa com um dado que ele **rejeita** (decisão 4.93). E o simétrico vale para critério de **ausência** (saída esperada vazia/0 — decisão 4.256): o comando roda **também contra o commit-pai** na fixação, e saída não-vazia ali é critério quebrado — a proibição nasceu mais larga que o escopo da TASK —, nunca código herdado a apagar; critério de ausência vermelho no pai induz o developer a "consertar" o legítimo (caso real: "nenhum ID SDD" nasceu com 10 âncoras legítimas por arquivo no estado herdado e, duas waves depois, custou a única âncora nova de um bloco com cinco vivas). Esperado do tipo "não piorou" (suíte, baseline de tipos) exige a baseline capturada **antes** de começar, dentro do próprio critério — capturada, ela também prova que o conjunto não é vazio. Critério de **não-regressão** nunca se escreve como "o teste não muda"/"sem alteração de asserção" (decisão 4.282) — isso congela o artefato, não a promessa: asserção por fragmento segue verde com o valor público reescrito; declare o **valor observável completo** e prove com o mutante (trocar o valor na produção → teste vermelho). E a âncora do diff acompanha a promessa: arquivo nascido na própria branch torna `git diff main...HEAD` inerte ("tudo inserido") — o diff de não-regressão se ancora no **commit que entregou o comportamento**, nunca na base da branch. E todo **exemplo literal** que ilustra um critério é conferido contra qualquer regra formal (regex, formato) já mandatória em **outra seção da mesma TASK** — nunca inventado à parte: se o Escopo fixa um padrão, o dado do exemplo tem de casá-lo (caso real: Escopo exigia regex de chave com prefixo de 2+ letras e o critério de dedupe ilustrava com `B-2, A-1` — chaves que o próprio regex nunca casa; custou uma rodada de correção na closure).

Em TASK `Tipo: bugfix`, o par do gate 1 nasce do **repro vermelho** (decisão 4.159 — fecha o degrau "prova do vermelho" da escada da 4.123): o comando reproduz o **sintoma exato** do `AC violado` e é executado na fixação **falhando** — a evidência do vermelho (mensagem de erro, saída errada) entra no critério, no lugar da evidência de conjunto não-vazio dos demais tipos. Depois do fix, o mesmo comando passa e vira o teste de regressão. Teste que nunca ficou vermelho não prova o conserto: pode estar verde porque testa outra coisa — o vermelho capturado antes é o que amarra o teste ao bug real, não ao diagnóstico imaginado. O **gesto relatado é parte do sintoma** (decisão 4.277): sintoma que nomeia um gesto se reproduz — e se re-verifica após o fix — por aquele gesto literal, somando o gesto irmão quando o caminho de evento diverge por gesto (blur por Tab × por clique); estado forçado (classe/valor injetado) nunca substitui o mecanismo real da UI.

O critério também tem de **resistir a contorno** (decisão 4.107) — oito testes na fixação: (a) valor **literal** no comando ou critério (nome de serviço, credencial, símbolo/constante de convenção do projeto) — e a **forma de payload de sistema externo** que um fixture reproduz (decisão 4.285) — é conferido contra a **fonte real** antes de escrito, nunca presumido: para literal interno, arquivo de infra ou grep do padrão já em uso; para payload externo, **amostra realmente capturada** (resposta salva, dump de integração, captura do gate 9), nunca a prosa da SPEC/PLAN que o descreve — fixture montado do texto faz gerador e avaliador partirem da mesma crença e o gate fica verde sobre o engano (caso real: forma afirmada 3× na SPEC virou constante no PLAN e fixture no teste; a tela cujo produto é evidência apontava 3 dos 9 descartes reais com o gate 1 verde, e a amostra que desmentia já existia no repositório); credencial chutada custa uma volta ao developer; pior, literal fixado contra a convenção real faz o cumprimento à risca **quebrar** o código certo; (b) condição **estrutural** (chamada proibida, assinatura, campo, projeção) verificada por `grep` de texto falha nos dois sentidos (decisão 4.161): padrão de caminho+conteúdo é satisfeito por **relocação**, e grep de palavra sobre o arquivo inteiro casa **prosa/docblock** — forçando o developer a empobrecer a documentação para não disparar — ou fixa o nome do símbolo da **camada errada** (campo do VO em camelCase onde o payload usa snake_case: cumprir à risca reproduz o bug); ancore na **estrutura executável** (FQCN/método num guard fail-closed, Reflection sobre a assinatura) ou exclua o comentário do universo buscado (`grep -v` de docblock, padrão ancorado em início de linha) — fronteira `\b`/`::` limita a palavra mas segue casando o símbolo citado em docblock, e deixou de contar como âncora (decisão 4.255, 2ª reincidência da classe); o lint sinaliza (`task-criterio-grep-nao-ancorado`), o validator escala; (c) AC cuja camada de persistência introduz um predicado de **escopo** (tenant, dono, agregado pai) exige, já no gate 1, o critério de **mutação** sobre esse predicado com fechamento **contável** — nunca uma lista de instâncias (decisão 4.139): "todo método que **toca** a tabela/recurso escopado — leitura ou escrita, **com ou sem predicado hoje** — tem cenário de segunda instância cuja mutação reprova — N métodos no Escopo, N provas" (decisão 4.232: o denominador é *quem toca a tabela*, nunca *quem já carrega o predicado* — método de escrita sem predicado nenhum é prova **faltando**, não prova fora de escopo; caso real: upsert/delete sem escopo saíram da contagem "2 de 2" por construção, e o IDOR de escrita chegou ao gate 8), mais um caso por ramo do predicado nos métodos de leitura; método nomeado entra só como ilustração **não-exaustiva**, nunca como a lista completa; o par contável declarado tem forma que o lint reconhece (`task-mutacao-sem-contagem`) e o confronto número×código é do gate 8, que tem o código na mão. Fixture com **dois** pais (duas instâncias/donos) e o predicado neutralizado **reprovando** o teste, fixado na TASK e nunca deixado para o gate 8 descobrir com o código pronto: fixture de um pai só não tem o que vazar, o predicado fica decorativo e a suíte segue verde com ele removido (casos reais: três rodadas de gate 8 no mesmo ciclo, pela mesma causa; depois da régua existir, TASK que enumerou a prova para 2 de 4 métodos com escopo no WHERE — 5 mutantes sobreviventes com a suíte 100% verde); (d) AC que altera arquivo/símbolo **compartilhado** (SQL/schema, trait, builder consumido por mais de um caso de uso) exige que o comando de verificação **alcance os outros consumidores conhecidos** — `--filter` da própria classe é insuficiente sozinho (decisão 4.162; caso real: 4 TASKs do mesmo ciclo alteraram SQL compartilhado com filtro estreito, e as 4 quebraram a suíte de outro consumidor pós-merge, achado fora do critério); (e) dois critérios da mesma TASK nunca se **contradizem** sobre o mesmo arquivo — `git diff` vazio esperado e asserção nova exigida nos mesmos arquivos não coexistem (decisão 4.162) — e a mesma régua sobe um nível (decisão 4.257, 4ª forma da família 4.162/4.215/4.233): critério com **proibição** (chamada, símbolo ou padrão vetado) é confrontado com o que o **PLAN-pai prescreve** antes de fixado — critério que proíbe o que o PLAN manda escrever é a contradição entre artefatos, e o `task-validator` a acusa com o PLAN em mãos; (f) critério de **round-trip/transporte** (canal que uma metade grava e a outra lê — cookie, token, sessão — decisão 4.284) nunca instala no **preparo** a primitiva sob prova: o arrange restaura só o canal (o identificador capturado), nunca chama o mecanismo que a metade em teste deveria acionar sozinha — instalada no arrange, a garantia idempotente faz o mutante que a remove do sujeito **sobreviver** (caso real: teste start→callback de OAuth com a primitiva de sessão no arrange, mascarando a ausência do guard no callback); e requisito MUST que nomeia **N sujeitos** para a mesma obrigação exige o mutante que morre **por sujeito** — remover de A reprova numa asserção, de B noutra — nunca um round-trip único cujo preparo cobre metade de quem deveria provar a si mesma (a 4.109 cobre o fechamento de achado multi-sujeito; este item cobre a geração, antes de achado existir); (g) requisito cujo texto combina dois predicados por **comparativo de unicidade** ("distinta de", "própria", "única") sobre 2+ valores nomeia, para o predicado de distinção, asserção de **valor literal** (comparar os valores um a um) ou de **contagem** sobre o conjunto deduplicado (decisão 4.284) — "contém"/"não vazio" prova o outro predicado (não-vazamento), nunca a distinção: colapsar os ramos num único default, ou trocar dois valores entre si, mantém essa asserção verde (a detecção "unicidade com contém" já é check do gate 1; este item previne na fixação, antes do código); (h) arquivo mergeado citado como **molde/exemplar** ("molde de X", "mesmo padrão de Y") que sustenta um trecho da TASK **fora do Critério** — Escopo, Convenções, Implementação sugerida — segue a mesma régua do item (a) (decisão 4.307): o literal prescrito é conferido contra o **conteúdo real do molde** no eixo em pauta antes de escrito, nunca contra a lembrança do nome (caso real: binding prescrito citando, na mesma frase, o molde cujo guard real é global — o binding certo estava a uma linha de distância, nunca lido; o developer seguiu a letra e herdou o defeito), e o **próprio molde** é confrontado com toda lição `Estado: ativa` de `lessons.md` cujo padrão ele possa encarnar antes de virar instrução de cópia — molde que já carrega o defeito documentado o propaga por cópia literal ao arquivo novo, mesmo com a lição corretamente citada em prosa alhures na mesma TASK (caso real: dois guards de teste citados como molde já continham no docblock a prosa que a lição ativa nomeia como vetor, e a contagem de grupos do runner subiu ao copiar; o cruzamento da 4.138/4.233 só alcança os arquivos-alvo do Inclui, nunca o arquivo citado como fonte).
A régua exata dos fatos de lint citados acima (nomes, regex e severidades) vive em `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/lint-contract.md` — cite-os por nome, não os re-derive.

E a cobertura fecha **de trás para frente**: o mapeamento AC→critério não alcança item do "Escopo > Inclui" **sem AC** — contrato criado nesta wave e lido só em wave posterior (VO, porta, chave de serialização). Todo item do Inclui carrega ao menos um critério **próprio e executável**; "testes de tudo acima" não é critério. Sem AC, o oráculo é o **contrato do próprio item** — cada método público e cada chave nova exercitados com valor **não-nulo**, mesmo que nesta wave o valor real nasça sempre nulo. Item do Inclui que nenhum critério referencia → `task-validator` reprova (ERROR). E fecha de **frente** para trás (decisão 4.286): FR listado em "Realiza (FRs)" tem o conjunto de ACs que a SPEC lhe associa **derivado do texto dela** e confrontado com a distribuição da wave — nunca enumerado de memória; AC do conjunto sem critério em TASK nenhuma entra como exclusão explícita (AC + motivo + onde será provado). A **existência** da menção já é mecânica (`ac-sem-task`, ERROR na geração); o que só o gerador vê é a **camada**: menção em TASK irmã só conta se a camada dela é a que enforça o AC (régua acima) — AC de comportamento de tela citado só nas TASKs de backend é buraco com o grafo verde (caso real: 13 dos 14 ACs enumerados à mão, pulando a faceta "falhou" do FR; as irmãs de backend citavam o AC, o check ficou verde, achado só no gate 7 com código pronto).

Antes de fixar os Critérios de pronto, cruze os arquivos-alvo do "Escopo > Inclui" contra `guidelines/project/lessons.md` (insumo da 0.5): lição **com `Estado: ativa`** (só ela — `em-observacao` é contexto de leitura, `revogada` não entra; ciclo de vida no dono `core/WORKFLOW.md`, decisão 4.221) que **nomeia** esses arquivos (ou o padrão que eles encarnam) vira item **verificável** do Critério de pronto — nunca leitura recomendada (decisão 4.138). Lição escrita numa wave e não reforçada como critério na próxima TASK que toca o mesmo arquivo é lição inerte (caso real: regra de escopo registrada com o arquivo nomeado uma wave antes; o método novo nasceu no mesmo arquivo violando-a, achado só no gate 8 — uma rodada de retry para um defeito com nome, causa e arquivo escritos antes do código). O cruzamento vale também para lição que classifica um **tipo/classe** de teste ou comando sem nomear arquivo (ex.: "prova de segurança nunca leva `@group skip-migration`"): confira que o **comando literal** de cada critério a obedece, não só a prosa da TASK que a cita — comando e prosa contraditórios na mesma TASK são a contradição interna da 4.161, agora entre comando×lição, e o comando é o que o developer executa: ele vence em silêncio (caso real: prosa citava a lição e o comando do mesmo critério prescrevia `--group skip-migration` — 2 rodadas de retry; 3ª ocorrência da classe, que por isso também virou fato de lint `task-comando-contradiz-criterio`, decisão 4.215). **E a ausência de citação não absolve (decisão 4.233)**: arquivo de teste de **segurança** no Inclui (por nome — guard de permissão, teste de tenant/escopo) com comando associado usando grupo/tag de suíte é a mesma classe **sem** as duas frases se contradizendo — boilerplate herdado não tem o que o lint da 4.215 grifar (caso real: 12 TASKs herdaram o grupo excluído como padrão do projeto, 3 ocorrências na mesma sessão); o lint sinaliza por nome de arquivo (`task-prova-seguranca-com-grupo`), e rota nova que **estende** guard pré-existente soma ao Inclui a obrigação de destravar a rede se ele cobre superfície de autorização — estender a lista sem destravar a rede fixa cobertura nova numa rede que já não roda.

### Roteiro do gate 9 — fixado antes do código

Com `gates.screenVerify` ativo e algum AC atribuído ao gate 9, a TASK carrega a seção `## Roteiro do gate 9 (fixado ANTES do código)` (ver template). Ela abre com **ambiente** (URLs digitáveis — com a base de rota real do app — + realm), **sujeito concreto** (qual identidade loga, com que credencial) e **pré-condição com receita** — como montar o estado e como restaurá-lo ao fim; "com um usuário sem permissão" não é pré-condição, é desejo. **Um passo por AC**: AC de gate 9 sem passo é AC sem gate. Antes de escrever, leia os handoffs anteriores do slug (`{docsRoot}/<slug>/handoffs/`): cenário já registrado ali como não-exercitável neste ambiente **não vira passo por herança** — reaproveite a receita e a prova substitutiva já aceitas, ou prescreva nova tentativa **nomeando o que mudou** desde o registro ("não exercitável" é registro datado, não veredicto permanente; a revisita é decisão consciente, nunca desconhecimento do handoff). AC de interação **hierárquica** (arrastar/reordenar itens dentro de um agrupamento — contêiner, pasta, grupo) inclui, além do passo interno, um passo que **cruza a fronteira** do agrupamento — mover o item para outro contêiner (decisão 4.107): o código que reordena "dentro" raramente é o que resolve "entre", é a classe de defeito mais provável da estrutura, e um roteiro que só exercita o reordenar interno não a alcança. AC de **corrida/resposta fora de ordem** numa tela de disparo único mira a chamada assíncrona **sem gate de UI** — fire-and-forget, disparada por efeito colateral de outra (decisão 4.287) — nunca a chamada que o guard de loading exigido por outro AC da mesma TASK já serializa: roteiro que dispara duas primárias em sequência é estruturalmente inatingível, a 2ª não começa com a 1ª em voo (caso real: o qa só salvou o gate ao perceber a impossibilidade na execução, não por régua escrita).

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
**Decomposição parcial declarada** (`--only`): ERRORs `fr-sem-task`/`ac-sem-task` de COMPs
fora do recorte são o gap que o Input manda reportar — liste-os no output como estado
conhecido; qualquer outro ERROR bloqueia normalmente (decisão 4.301).

**Correção** (decisão 4.114): delta ao `scribe`, **aguardado**, com a lista literal de
ERRORs e âncora por ajuste — modo de aplicação pela régua do pacote (4.309); buraco de numeração não é defeito, arquivo existente nunca se renumera — protocolo do invocador: `graph-contract.md` §4.1.

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

Só quando a ficha tem `jira.enabled: true`: **despache o agent `tracker-sync`** (decisão 4.103) — na rodada paralela com o `task-validator` da Etapa 5 (decisão 4.113); nunca com o scribe ainda editando as TASKs — com o gancho **`tasks`**: caminhos do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; §§ do gancho: §6.2, §7, §8, §10 — e §17 quando `jira.telemetry` (worklog + contadores da etapa); mais `jira-sync-feat.md` quando a projeção de 3 níveis está ativa), da ficha, da SPEC e das TASKs geradas. Ele cria uma **sub-task por TASK**, grava a key no campo `Jira:` da closure de cada uma e devolve o resumo canônico. Best-effort (§0): `eventos_tracker` no retorno → evento `tracker` no ledger + **seção de reconexão da §14** no fecho deste comando; num `/keelson:auto`, desagua no item 7.4 da Entrega. Agent indisponível → aplicar o protocolo inline (mesmos §§) é o fallback, declarado no output.

## Output final ao usuário

1. Quantidade de tasks geradas, tamanho dominante e convenções aplicadas (da ficha/perfil).
2. Caminhos: TASK-MMM-INDEX.md e INDEX.md do slug atualizado.
3. Resultado da validação (errors, warnings) e gaps detectados (FRs sem TASK, ACs sem verificação).
4. Tasks da Wave 1 (por onde começar); cobertura por funcionalidade (FEAT → TASKs), se a SPEC declara FEATs.
5. Próximo comando, com o **caminho** do PLAN (4.124): `/keelson:implement {docsRoot}/<slug>/plans/PLAN-MMM-<nome>.md` ou `--dry-run` primeiro.
