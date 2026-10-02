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
3. Extrair: granularidade típica, DoD padrão e framework de teste (do perfil) — branch, commit e stack não se transcrevem na TASK (4.406): o developer os lê da ficha/perfil e o `code-reviewer` os cobra no diff (gate 6).

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
  de decomposição, ordenação, template da TASK **e** o `TASK-MMM-INDEX.md` (parte da autoria) —
  mais os templates canônicos (`${CLAUDE_PLUGIN_ROOT}/templates/artifacts/TASK.md` e
  `TASK-INDEX.md`, 4.405).
- **Alvo resolvido**: slug, MMM, próximo XXX, caminhos (Etapa 0.4); flags `--max-size`/`--only`.
- **Insumos** (caminhos): PLAN, SPEC (ACs e mapa FR→FEAT da 0.2), convenções extraídas na
  0.1 (resumo inline), memo de exploração e/ou `MAP.md` do slug, e o **recorte** do acervo de lições — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lessons.sh" . match --paths <arquivos dos componentes do PLAN/MAP, separados por vírgula> --max-bytes 120000` (leitura dupla de `guidelines/project/lessons/` e do `lessons.md` legado; lição sem `paths` entra sempre — decisão 4.376), nunca o acervo inteiro (cruzamento da Etapa 3).

**Rota fan-out (previsão >8 TASKs — decisão 4.310)**: uma janela serial que decide E
redige 12+ arquivos é o gargalo medido da forja; a rota divide em duas fases do **mesmo
agent** (briefings distintos do `scribe`, nunca agents novos):

1. **Decompositor**: um `scribe` com o pacote acima, Etapas 1 a 3 como régua de decisão,
   e a instrução de **não escrever arquivo nenhum**: o retorno é um **manifesto
   congelado** — por TASK: ID, título, tipo, tamanho, wave, `Depende de`/`Bloqueia`
   (**as duas pontas de cada aresta escritas nos dois IDs** — o redator de uma fatia não vê
   a outra, e a assimetria `dep-bloqueia-assimetrica` nasce daí; decisão 4.432), os
   símbolos/campos que a TASK **declara** e que outra TASK poderá citar ("declarado na
   TASK-X" sem dono no manifesto é referência inventada), FRs/FEATs/COMPs, distribuição
   AC×gate, bullets de Inclui/Não inclui e lições ativas aplicáveis. O manifesto é o produto intelectual da decomposição: ID e aresta ficam
   decididos aqui, e só aqui.
2. **Redatores**: 2–3 `scribe`s **em paralelo**, cada um com o manifesto + o contrato
   (Etapas 1 a 3, template canônico da Etapa 3) + os insumos e uma **lista literal de arquivos**
   a redigir (fatia por wave; nunca "as TASKs da wave 2", que se sobrepõe). Redator
   **não cria nem renomeia ID e não toca aresta** — divergência com o manifesto volta
   em `duvidas`, nunca se corrige localmente (mesmo mecanismo da 4.114).
3. **`TASK-MMM-INDEX.md` é da main session nesta rota** (dono único — nenhum redator tem
   o todo): derive-o do manifesto (o checklist de waves é projeção dele; cobertura e
   status **não se escrevem** — `graph.sh --format=tables --plan MMM`, 4.409) **após o
   retorno de todos** os redatores; o commit do marco só então, por
   pathspec (4.163).

A consistência global não depende de disciplina dos redatores: o `graph.sh --check`
(Etapa 5) e o `task-validator` provam o resultado nas duas rotas.

Receba o(s) sumário(s) estruturado(s) (`agents/scribe.md`): `insumos_index.contagens` alimenta a
Etapa 6; `duvidas` não-vazias → resolva (pergunte; no modo autônomo, escada) e re-despache
só o delta (em correção, `modo_aplicado` divergente do declarado sem motivo é lição
candidata de processo — 4.349). Agent indisponível → Etapas 1–4 inline como fallback, declarado no output.

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
   idiomático não dispensa a checagem. Perfil sem seção de nomenclatura → declare e
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

Template canônico: `${CLAUDE_PLUGIN_ROOT}/templates/artifacts/TASK.md` — o scribe o lê na
fonte e reproduz a estrutura à risca; comentários `<!-- -->` são régua, nunca conteúdo
(decisão 4.405).

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

Primeiro decida **qual camada enforça** o AC e liste-o nos "Critérios de pronto" **dessa** task, não de uma vizinha: recusa por **estado prévio** (ex.: registro já vinculado) é guard da camada de regra de negócio; unicidade por **corrida/persistência** é da camada de persistência; **autorização/borda** é da camada de entrada; **comportamento de tela** é do frontend (gate de tela, quando `gates.screenVerify`). AC não enforçável na camada da task (ex.: uma escrita idempotente que delega a unicidade ao armazenamento) não é testável ali — realoque para a task que o impõe. Critério **herdado** por extenso (vem de requisito/NFR/lição citado por completo, não de um AC desta wave — decisão 4.138) segue a mesma exigência de **endereço**: nomeia o arquivo e a ação que o cumprem, e o "Escopo > Inclui" da task que o recebe **incorpora** esse arquivo — senão vira TASK própria na mesma wave. Teste: se a verificação do critério não aponta para arquivo que o Inclui autoriza tocar, o critério está mal endereçado — cumprido à risca, o requisito segue violado sem grep nenhum acusar.

Depois, cada AC mapeia para **exatamente um** gate de verificação. NÃO liste o mesmo AC em dois gates com exigências distintas (ex.: "testes cobrem AC-X" **e** "gate 9 cobre AC-X"): a ambiguidade faz o developer escolher a verificação mais fraca e um MUST fica sem teste falsificável. Regra: **MUST testável em unidade → teste no gate 1**; o gate 9 (comportamento verificado / caminhada de tela quando `gates.screenVerify`) só **confirma** o fluxo ponta-a-ponta, nunca substitui o teste. Respeite o gate que a DoD do PLAN atribui ao AC — nunca rebaixe de gate 1 (teste) para gate 9 (manual).

**Princípio do critério de gate 1**: todo item registra a verificação executável — comando + saída/efeito esperado — **antes** do código (o critério nasce do AC, nunca do diff: gerador ≠ avaliador; sem comando+esperado o `task-validator` reprova, ERROR), e o par é **falsificável e conferido na fixação** (4.447): pergunte "que estado faz este comando FALHAR?" — sem resposta, o critério aprova qualquer coisa — e confira por Grep o que o comando pressupõe (alvo e filiação reais, flags da ferramenta na config real); quem **executa** é o developer, no baseline antes de começar: o esperado nasce com a forma do oráculo e placeholder honesto onde só a execução dá o número (`OK (N tests)`, `N > 0`), que o baseline do developer preenche (`verificacao.baseline` do report) — o lint `task-criterio-esperado-placeholder` conta esses itens, sem reprovar. A fixação confere três coisas sobre o comando, cada uma com a armadilha que a nega:

1. **Ele acha o alvo** — evidência de conjunto não-vazio (`OK (12 tests)`, nunca `No tests executed`). Vazio é o estado default de comando mal ancorado: filtro que não casa classe nenhuma, grupo excluído da suíte, glob que não resolve, `git diff --name-only` sem a âncora `main...HEAD` (compara com o índice e devolve vazio depois do commit) — verde sobre o vazio cumpre o critério aprovando qualquer diff; corolário: predicado que **exclui** se fixa com um dado que ele **rejeita** (4.93).
   - Alvo em código **pré-existente** que a TASK não vai tocar (convenção do arquivo, propriedade já declarada, invariante que o "Não inclui" proíbe alterar — 4.318): o match é **lido**, não só contado — código novo tem a checagem natural do developer, código intocável não; critério que presume ordem/posição ("o primeiro", "a única ocorrência") ou sintaxe que o arquivo real não usa reprova a implementação correta ou aprova o alvo errado com não-vazio verde.
   - Arquivo-alvo que **ainda não existe** (a própria TASK vai criá-lo — 4.342): o análogo do commit-pai é o arquivo-molde citado como convenção/exemplar (item h); o comando é conferido contra ele na fixação — flags, `--standard`, `--config` e versão lidos da config real por Grep — e roda no baseline do developer contra um arquivo real, antes do código novo; ferramenta ausente ou sem a configuração real aparece aí, nunca depois do código escrito.
2. **Ele acha só o alvo** — o simétrico do vazio (4.368): comando amplo da ficha (`quality.test`) com arquivo/classe nomeado prova o agregado, nunca o alvo — executor que exclui por grupo/tag/config (`@group`, `--exclude-group`) deixa o alvo fora de um `OK (N tests)` não-vazio; o critério traz a confirmação **isolada** (`--filter`/`--group` do próprio alvo com contagem > 0, ou o nome do alvo no relatório de execução) — lint `task-criterio-alvo-nao-isolado`, validator escala. E o valor do filtro bate com a **filiação real** do alvo (4.428): `--group X` sobre arquivo sem a anotação, `--testsuite Y` fora do diretório da suíte rodam zero ou um subconjunto de outro arquivo com "N > 0" verde — confira por Grep a anotação e o diretório reais do alvo (e o mapa de suítes da config do runner) antes de fixar, nunca pelo nome do arquivo; filiação heterogênea → um comando por filiação; a conferência é fato mecânico de `scripts/suite-filter-check.sh` (Etapa 5; o `task-validator` cita a saída na Etapa 3 — 4.429).
3. **Ele distingue o antes do depois**:
   - Critério de **ausência** (saída esperada vazia/0 — 4.256) é conferido contra o commit-pai na fixação (Grep do padrão na árvore atual) e roda lá no baseline do developer; ocorrência ali é critério quebrado (a proibição nasceu mais larga que o escopo), nunca código herdado a apagar — vermelho no pai induz o developer a "consertar" o legítimo.
   - Esperado "não piorou" (suíte, baseline de tipos) nomeia a baseline que o developer captura **antes** de começar (etapa 2 do `developer`) — capturada, ela também prova que o conjunto não é vazio.
   - **Não-regressão** nunca se escreve "o teste não muda"/"sem alteração de asserção" (4.282) — isso congela o artefato, não a promessa (asserção por fragmento segue verde com o valor público reescrito): declare o valor observável completo e prove com o mutante (trocar o valor na produção → teste vermelho); e ancore o diff no **commit que entregou o comportamento**, nunca na base da branch — arquivo nascido na branch torna `git diff main...HEAD` inerte ("tudo inserido").

Exemplo literal que ilustra um critério casa a regra formal (regex, formato) já mandatória em outra seção da mesma TASK — nunca inventado à parte: se o Escopo fixa um padrão, o dado do exemplo tem de casá-lo (4.64).

Em TASK `Tipo: bugfix`, o par do gate 1 nasce do **repro vermelho** (decisão 4.159 — fecha o degrau "prova do vermelho" da escada da 4.123): o comando reproduz o **sintoma exato** do `AC violado` e é executado na fixação **falhando** — a evidência do vermelho (mensagem de erro, saída errada) entra no critério, no lugar da evidência de conjunto não-vazio dos demais tipos. Depois do fix, o mesmo comando passa e vira o teste de regressão. Teste que nunca ficou vermelho não prova o conserto: pode estar verde porque testa outra coisa — o vermelho capturado antes é o que amarra o teste ao bug real, não ao diagnóstico imaginado. O **gesto relatado é parte do sintoma** (decisão 4.277): sintoma que nomeia um gesto se reproduz — e se re-verifica após o fix — por aquele gesto literal, somando o gesto irmão quando o caminho de evento diverge por gesto (blur por Tab × por clique); estado forçado (classe/valor injetado) nunca substitui o mecanismo real da UI.

O critério também tem de **resistir a contorno** (decisão 4.107). Princípio único: **tudo que o critério afirma sobre o mundo é conferido contra a fonte real antes de escrito, e a prova que ele prescreve morre se a promessa for violada em qualquer ponto** — literal, estrutura, escopo, sujeito e molde são os eixos em que a crença do redator costuma substituir o fato. Oito testes na fixação:

(a) **Literal contra a fonte**: nome de serviço, credencial, símbolo/constante de convenção — e a forma de payload de sistema externo que um fixture reproduz (4.285) — vêm de arquivo de infra ou grep do padrão em uso (literal interno) e de **amostra realmente capturada** — resposta salva, dump de integração, captura do gate 9 — (payload externo), nunca da prosa da SPEC/PLAN: fixture montado do texto põe gerador e avaliador na mesma crença e o gate fica verde sobre o engano; credencial chutada custa uma volta ao developer, e literal fixado contra a convenção real faz o cumprimento à risca **quebrar** o código certo.
(b) **Estrutura, não grep de texto** (4.161): condição estrutural (chamada proibida, assinatura, campo, projeção) por grep falha nos dois sentidos — padrão caminho+conteúdo é satisfeito por relocação; grep de palavra sobre o arquivo inteiro casa prosa/docblock (forçando o developer a empobrecer a documentação) ou fixa o símbolo da camada errada (campo do VO em camelCase onde o payload usa snake_case: cumprir à risca reproduz o bug). Ancore na estrutura executável (FQCN/método num guard fail-closed, Reflection sobre a assinatura) ou exclua o comentário do universo buscado (`grep -v` de docblock, padrão ancorado em início de linha); fronteira `\b`/`::` não é âncora — limita a palavra mas segue casando o símbolo em docblock (4.255). Lint `task-criterio-grep-nao-ancorado`, validator escala.
(c) **Predicado de escopo com fechamento contável** (4.139): AC cuja camada de persistência introduz predicado de escopo (tenant, dono, agregado pai) exige, já no gate 1, critério de mutação sobre esse predicado com contagem — nunca lista de instâncias: "todo método que **toca** a tabela/recurso escopado — leitura ou escrita, **com ou sem predicado hoje** — tem cenário de segunda instância cuja mutação reprova: N métodos no Escopo, N provas" — `N` é o número contado por Grep na fixação (os métodos que tocam a tabela), nunca a letra (4.447) — (4.232: o denominador é quem toca a tabela, nunca quem já carrega o predicado — escrita sem predicado é prova **faltando**, não fora de escopo), mais um caso por ramo do predicado nas leituras; método nomeado é ilustração não-exaustiva. O par contável tem a forma que o lint reconhece (`task-mutacao-sem-contagem`); o confronto número×código é do gate 8, que tem o código na mão. Fixture com **dois** pais e o predicado neutralizado **reprovando**, fixado na TASK e nunca deixado ao gate 8 — com um pai só não há o que vazar, o predicado fica decorativo e a suíte segue verde com ele removido.
(d) **Consumidores por varredura** (4.162): AC que altera arquivo/símbolo compartilhado (SQL/schema, trait, builder consumido por mais de um caso de uso) exige comando que alcance os outros consumidores conhecidos — `--filter` da própria classe é insuficiente sozinho — e "conhecidos" fecha por **varredura** (grep do símbolo, contagem confrontada) ou é rotulado não-exaustivo (mesma régua do item c e da régua-mãe 4.321; 4.369).
(e) **Sem contradição interna** (4.162): dois critérios da mesma TASK nunca se contradizem sobre o mesmo arquivo — `git diff` vazio esperado e asserção nova exigida nos mesmos arquivos não coexistem.
(f) **Um mutante por sujeito** (4.284): critério de round-trip/transporte (canal que uma metade grava e a outra lê — cookie, token, sessão) restaura no arrange só o canal — o identificador capturado — e nunca instala a primitiva sob prova (instalada no arrange, a garantia idempotente faz o mutante que a remove do sujeito **sobreviver**). MUST que nomeia N sujeitos para a mesma obrigação exige mutante que morre **por sujeito** — remover de A reprova numa asserção, de B noutra — nunca round-trip único cujo preparo cobre metade de quem deveria provar a si mesma (a 4.109 cobre o fechamento de achado multi-sujeito; este item cobre a geração); o mesmo mutante por parte vale para 2+ predicados unidos por **conjunção** ("endereço e nome corretos"): trocar só X reprova numa asserção, só Y noutra (4.369 — eixo distinto do item g).
(g) **Distinção se afirma por valor ou contagem** (4.284): requisito que combina dois predicados por comparativo de unicidade ("distinta de", "própria", "única") sobre 2+ valores nomeia, para o predicado de distinção, asserção de **valor literal** (um a um) ou de **contagem** sobre o conjunto deduplicado — "contém"/"não vazio" prova o outro predicado (não-vazamento), nunca a distinção: colapsar os ramos num default ou trocar dois valores entre si mantém verde (a detecção "unicidade com contém" já é check do gate 1; este item previne na fixação).
(h) **Molde e prova herdada lidos no eixo em pauta** (4.307): arquivo mergeado citado como molde/exemplar ("molde de X", "mesmo padrão de Y") fora do Critério — Escopo, Contexto — segue o item (a): o literal prescrito é conferido contra o **conteúdo real do molde** no eixo em pauta, nunca contra a lembrança do nome; e o próprio molde é confrontado com toda lição `estado: ativa` do recorte (`lessons.sh . match --paths <molde>` — caminhos separados por **vírgula**: com espaço o script honra só o primeiro, em silêncio; lição sem `paths` entra sempre, 4.376) cujo padrão ele possa encarnar, antes de virar instrução de cópia — molde que já carrega o defeito documentado o propaga por cópia literal, mesmo com a lição citada em prosa alhures na mesma TASK. **Prova pré-existente** citada como evidência de um AC ("já existe cobertura em X", nome de teste) é lida no **eixo do predicado** antes de citada — qual campo/condição a asserção de fato compara — porque nome de teste não prova o campo (4.342).
- **Extrair ou duplicar é decisão escrita na fixação, nunca do developer sob pressão** (4.446): citação de molde no Escopo ou no Contexto ("mesmo mecanismo de X", "como em Y") vem com a decisão — `extrair para <símbolo ou local compartilhado>` ou `duplicar — <motivo>` — tomada depois de um Grep do canônico: já existe lugar compartilhado (trait, helper, classe base) que faz isso? então é reuso, não escolha. Helper ou dublê que 2+ TASKs da mesma wave vão usar segue o protocolo da aresta (4.106): uma TASK o cria e o carrega no `Escopo > Inclui`, as irmãs o citam em `Depende de`.
(i) **Escrita composta prova a falha da segunda** (4.449): item do Escopo ou AC cujo efeito são 2+ escritas dependentes — a segunda usa o resultado da primeira, ou só as duas juntas realizam o AC (criar o agregado e copiar os filhos, gravar e publicar) — exige critério com falha **injetada na segunda escrita** e asserção de que nenhum efeito da primeira persiste (ou que a compensação deixa rastro observável); "dentro de transação" em prosa não é prova: o mutante é remover a fronteira transacional e o teste tem de reprovar.
(j) **Estado de interface nomeado no FR vira elemento verificável** (4.450): FR ou AC que nomeia um estado de tela (vazio, erro, carregando, sem permissão) ganha critério que nomeia o que a tela mostra nesse estado — texto literal ou chave de i18n, ação disponível, o que fica oculto — conferido contra a régua de estados do `core/DESIGN.md` (o vazio orienta o próximo passo); "exibe estado vazio" é a frase do FR repetida, cumprida por qualquer placeholder, e o gate 11 só a pega depois do código.

Mutante que qualquer desses testes manda aplicar ao **arquivo real** (itens c e f; a não-regressão da 4.282) nasce no critério já apontando `git worktree add` — a árvore de trabalho principal nunca é editada destrutivamente (4.134, no ponto de uso): o classificador de ações destrutivas do harness bloqueia a edição in-place, o developer cai para fixture e a prova fica mais fraca que o critério fixado.
A régua exata dos fatos de lint citados acima (nomes, regex e severidades) vive em `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/lint-contract.md` — cite-os por nome, não os re-derive.

E a cobertura fecha **de trás para frente**: o mapeamento AC→critério não alcança item do "Escopo > Inclui" **sem AC** — contrato criado nesta wave e lido só em wave posterior (VO, porta, chave de serialização). Todo item do Inclui carrega ao menos um critério **próprio e executável**; "testes de tudo acima" não é critério. Sem AC, o oráculo é o **contrato do próprio item** — cada método público e cada chave nova exercitados com valor **não-nulo**, mesmo que nesta wave o valor real nasça sempre nulo. Item do Inclui que nenhum critério referencia → `task-validator` reprova (ERROR). E fecha de **frente** para trás (decisão 4.286): FR listado em "Realiza (FRs)" tem o conjunto de ACs que a SPEC lhe associa **derivado do texto dela** e confrontado com a distribuição da wave — nunca enumerado de memória; AC do conjunto sem critério em TASK nenhuma entra como exclusão explícita (AC + motivo + onde será provado). O critério que recebe o AC reproduz o **Given** dele — o arrange monta o estado que o Given descreve, nunca o oposto; critério que cita o AC certo sobre o cenário contrário prova outra coisa — e dá asserção própria a cada **sink** que o Então nomeia por escrito (log, tabela, fila, e-mail): sink nomeado sem asserção é AC meio provado com teste verde (decisão 4.369). A exclusão mora em **"Escopo > Não inclui"**, nunca nos Critérios de pronto (decisão 4.345): a aresta `covers-ac` conta qualquer linha dos Critérios e do Roteiro como cobertura (graph-contract §2) e fabricaria exatamente o que a nota nega (`index-desatualizado` acusa). Cobertura **parcial** desta TASK é outro caso — o AC **fica** nos Critérios, qualificado inline ("AC-NNN-XXX (parte X — a faceta Y é do gate Z da TASK-MMM-ZZZ)"); só o AC que esta TASK não prova em nada migra para o Não inclui, e a linha lá não é aresta: AC de FR coberto sem critério em TASK nenhuma continua `ac-sem-task` (ERROR), resolvido pela régua da Etapa 5 — tolerado só em decomposição parcial `--only`, com o destino declarado — nunca silenciado pela nota. A **existência** da menção já é mecânica (`ac-sem-task`, ERROR na geração); o que só o gerador vê é a **camada**: menção em TASK irmã só conta se a camada dela é a que enforça o AC (régua acima) — AC de comportamento de tela citado só nas TASKs de backend é buraco com o grafo verde. E a camada certa tem **profundidade** (decisão 4.428 — eixo distinto da 4.162: não *quem mais* consome o símbolo, mas *até onde* a cadeia do AC vai): AC que promete efeito visível ao usuário tem o critério de gate 1 alcançando o **leitor real** que monta o que chega à tela (caso de uso/serviço de leitura, controller), nunca parando no objeto de domínio intermediário nem no mock que só prova que o campo existe — suíte verde com o dado nunca chegando à tela; só a faceta de **renderização** fica parcial, na forma inline acima, nomeando o carregador (spec E2E com `quality.e2e`, senão o passo do Roteiro do gate 9 da TASK de tela); o `task-validator` sinaliza por leitura AC visível sem carregador nomeado.

Antes de fixar os Critérios de pronto, cruze os arquivos-alvo do "Escopo > Inclui" contra o recorte do acervo de lições (`lessons.sh . match --paths <Inclui da TASK, separados por vírgula>` — o insumo da 0.5 re-cortado por TASK, decisão 4.376): lição **com `estado: ativa`** (só ela — `em-observacao` é contexto de leitura, `revogada` não entra; ciclo de vida no dono `core/WORKFLOW.md`, decisão 4.221) que **nomeia** esses arquivos (ou o padrão que eles encarnam) vira item **verificável** do Critério de pronto, citando a lição pelo `id` (nome do arquivo) ou heading — nunca leitura recomendada (decisão 4.138). Lição escrita numa wave e não reforçada como critério na próxima TASK que toca o mesmo arquivo é lição inerte. O cruzamento vale também para lição que classifica um **tipo/classe** de teste ou comando sem nomear arquivo (ex.: "prova de segurança nunca leva `@group skip-migration`" — é a lição sem `paths`, que o recorte inclui sempre): confira que o **comando literal** de cada critério a obedece, não só a prosa da TASK que a cita — comando e prosa contraditórios na mesma TASK são a contradição interna da 4.161, agora entre comando×lição, e o comando é o que o developer executa: ele vence em silêncio. **E a ausência de citação não absolve (decisão 4.233)**: arquivo de teste de **segurança** no Inclui (por nome — guard de permissão, teste de tenant/escopo) com comando associado usando grupo/tag de suíte é a mesma classe **sem** as duas frases se contradizendo — boilerplate herdado não tem o que o lint da 4.215 grifar; o lint sinaliza por nome de arquivo (`task-prova-seguranca-com-grupo`), e rota nova que **estende** guard pré-existente soma ao Inclui a obrigação de destravar a rede se ele cobre superfície de autorização — estender a lista sem destravar a rede fixa cobertura nova numa rede que já não roda.

### Roteiro do gate 9 — fixado antes do código

Com `gates.screenVerify` ativo e algum AC atribuído ao gate 9, a TASK carrega a seção `## Roteiro do gate 9 (fixado ANTES do código)` (ver template). Ela abre com **ambiente** (URLs digitáveis — com a base de rota real do app — + realm), **sujeito concreto** (qual identidade loga, com que credencial) e **pré-condição com receita** — como montar o estado e como restaurá-lo ao fim; "com um usuário sem permissão" não é pré-condição, é desejo. **Um passo por AC**: AC de gate 9 sem passo é AC sem gate. Antes de escrever, leia os handoffs anteriores do slug (`{docsRoot}/<slug>/handoffs/`): cenário já registrado ali como não-exercitável neste ambiente **não vira passo por herança** — reaproveite a receita e a prova substitutiva já aceitas, ou prescreva nova tentativa **nomeando o que mudou** desde o registro ("não exercitável" é registro datado, não veredicto permanente; a revisita é decisão consciente, nunca desconhecimento do handoff). AC de interação **hierárquica** (arrastar/reordenar itens dentro de um agrupamento — contêiner, pasta, grupo) inclui, além do passo interno, um passo que **cruza a fronteira** do agrupamento — mover o item para outro contêiner (decisão 4.107): o código que reordena "dentro" raramente é o que resolve "entre", é a classe de defeito mais provável da estrutura, e um roteiro que só exercita o reordenar interno não a alcança. AC de **corrida/resposta fora de ordem** numa tela de disparo único mira a chamada assíncrona **sem gate de UI** — fire-and-forget, disparada por efeito colateral de outra (decisão 4.287) — nunca a chamada que o guard de loading exigido por outro AC da mesma TASK já serializa: roteiro que dispara duas primárias em sequência é estruturalmente inatingível, a 2ª não começa com a 1ª em voo. Roteiro que pede falsificar um **estado transitório** (item em voo, controle desabilitado durante a requisição, indicador de carregamento) prescreve **interceptação de rede** — segurar/atrasar a resposta da chamada relevante — como a técnica do passo (decisão 4.319): a latência real do ambiente nunca é a garantia da janela — API rápida torna o estado inobservável por clique+snapshot e o passo morre por técnica, não por AC inválido. E passo que pede confirmar **AUSÊNCIA de um efeito EXTERNO** (chamada de rede, evento, side-effect) nomeia um observador que estruturalmente **alcança** esse efeito (decisão 4.319): confirme em que processo/camada o efeito ocorre antes de escrever o passo — efeito que o backend produz contra uma API externa não aparece no painel de rede do browser, que só vê as chamadas do próprio cliente; observador errado torna o passo garantido por construção — nunca pode falhar — e o AC atravessa a wave sem prova real.

**Receita de pré-condição grava o que o produto gravaria** (4.451): estado montado fora do produto — SQL direto, seed, fixture — reproduz o invariante que o fluxo real deixa ao chegar nesse estado (toda coluna, registro ou snapshot que o produto grava ao fechar, publicar, aprovar), conferido na fonte real do fluxo (item a do bloco "resiste a contorno"), e a receita cita a TASK dona desse invariante; invariante que nasce em TASK posterior do mesmo PLAN entra na reconciliação do pacote do gate 9 (4.140). Receita envelhecida monta estado que o produto nunca produz, e o passo morre por erro do servidor, não por AC.

## Etapa 4: índice de tasks do PLAN (contrato — executado pelo `scribe`)

Criar/atualizar `{docsRoot}/<slug>/tasks/TASK-MMM-INDEX.md`:

Template canônico: `${CLAUDE_PLUGIN_ROOT}/templates/artifacts/TASK-INDEX.md` (decisão 4.405).

## Etapa 5: gate de validação

Após gerar todas as TASKs e o TASK-MMM-INDEX, **conferir o grafo mecanicamente**:
`${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh {docsRoot}/<slug> --check --stage=tasks --plan MMM`
(contrato: `graph-contract.md`). Defeito de geração (ciclo, wave incoerente, referência quebrada) → corrija antes do gate; script indisponível/falhou → siga declarando a degradação.
**Decomposição parcial declarada** (`--only`): ERRORs `fr-sem-task`/`ac-sem-task` de COMPs
fora do recorte são o gap que o Input manda reportar — liste-os no output como estado
conhecido; qualquer outro ERROR bloqueia normalmente (decisão 4.301).
**E a filiação dos filtros de suíte é conferida no código real** (decisão 4.429):
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/suite-filter-check.sh" <raiz-do-projeto> {docsRoot}/<slug>/tasks/TASK-MMM-INDEX.md`
(contrato no cabeçalho do script — PHPUnit; outro runner é silêncio, não fato). Cada
WARNING — `--group` sobre arquivo sem a anotação, arquivo em grupo excluído por padrão
citado sem `--group`, `--testsuite` fora da suíte ou inexistente — entra no mesmo delta
ao `scribe`, com a linha da TASK como âncora. Script indisponível → declare, como no grafo.
**E a forma das TASKs passa pelo lint antes de gastar a rodada** (decisão 4.432):
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/artifact-lint.sh" {docsRoot}/<slug>` em modo diretório
(os checks cruzados só existem nele; catálogo e severidades: `lint-contract.md`). Entram no
mesmo delta ao `scribe`: todo achado que **não** é `(W)` no catálogo (fato — `task-tipo-enum`,
seção ou campo ausente, id divergente) e os WARNING do grafo que atravessam fatias
(`dep-bloqueia-assimetrica`, `wave-incoerente`); os `(W)` de padrão desta classe
(`task-nome-tipo`, `task-criterio-grep-nao-ancorado`, `task-wave-overlap-arquivo`) vão como
"corrija ou justifique em `duvidas`" — `task-overlap-fr` fica fora (saturado no acervo real —
sinal sem valor de triagem), e `task-criterio-esperado-placeholder` também: o placeholder é a forma
honesta sem shell, e quem o preenche é o baseline do developer (4.447). **Um ajuste por (check × TASK)**, nunca por ocorrência, para o
pacote caber no `modo: edits`; a volta conta em `correções` da telemetria da forja e `classes`
transcreve os ids do lint. O lint custa segundos; o mesmo achado na rodada única (4.116) custa
validator + `qa` + PO e uma volta de scribes.

**Correção** (decisão 4.114): delta ao `scribe`, **aguardado**, com a lista literal de
ERRORs e âncora por ajuste — com `modo:` declarado pela régua do pacote (4.309/4.349, `graph-contract.md` §4.1; só `edits` ou `reescrita` — fatos × julgamento é o eixo da revalidação, não do `modo:`, 4.445) e revalidação pela régua do protocolo (`validator-protocol.md` §4.5, 4.350); buraco de numeração não é defeito, arquivo existente nunca se renumera — protocolo do invocador: `graph-contract.md` §4.1.

Com o grafo e o lint limpos (e o scribe encerrado), invocar a skill `task-validator` em modo batch
(apontando para o TASK-MMM-INDEX) — em paralelo com o `tracker-sync` da Etapa 7 quando o
sync está ativo (4.113: o validator só lê; o sync só escreve linhas `Jira:`) e, no ciclo
formal, com o `qa` pré-código na mesma rodada (Etapa 3.5 do auto — 4.116): **errors == 0**
→ prosseguir; **errors > 0** → reportar por TASK — INDEX atualizado mesmo assim, Status
`Blocked` nas tasks com error; no ciclo, o achado desagua na **rodada consolidada do
invocador** (4.116), sem volta de correção própria deste comando.

## Etapa 6: atualização do INDEX.md do slug

Aplicar a **receita de atualização do INDEX** (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`). Específico desta etapa: atualizar a coluna `Tasks` na linha do PLAN-MMM, no formato canônico do contrato — de `0/? ⏸` para `0/<total de tasks geradas> ⏸`.

## Etapa 7: sincronização com Jira (opcional)

Só quando a ficha tem `jira.enabled: true`: **despache o agent `tracker-sync`** (decisão 4.103) — na rodada paralela com o `task-validator` da Etapa 5 (decisão 4.113); nunca com o scribe ainda editando as TASKs — com `teto:` lido do mapa (4.437) e o gancho **`tasks`**: caminhos do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; §§ do gancho: §6.2, §7, §8, §10 — e §17 quando `jira.telemetry` (worklog + contadores da etapa); mais `jira-sync-feat.md` quando a projeção de 3 níveis está ativa), da ficha, da SPEC e das TASKs geradas. Ele cria uma **sub-task por TASK**, grava a key no campo `Jira:` da closure de cada uma e devolve o resumo canônico. Best-effort (§0): `eventos_tracker` no retorno → evento `tracker` no ledger + **seção de reconexão da §14** no fecho deste comando; num `/keelson:auto`, desagua no item 7.4 da Entrega. Agent indisponível → aplicar o protocolo inline (mesmos §§) é o fallback, declarado no output.

## Output final ao usuário

1. Quantidade de tasks geradas e tamanho dominante.
2. Caminhos: TASK-MMM-INDEX.md e INDEX.md do slug atualizado.
3. Resultado da validação (errors, warnings) e gaps detectados (FRs sem TASK, ACs sem verificação).
4. Tasks da Wave 1 (por onde começar); cobertura por funcionalidade (FEAT → TASKs), se a SPEC declara FEATs.
5. Próximo comando, com o **caminho** do PLAN (4.124): `/keelson:implement {docsRoot}/<slug>/plans/PLAN-MMM-<nome>.md` ou `--dry-run` primeiro.
