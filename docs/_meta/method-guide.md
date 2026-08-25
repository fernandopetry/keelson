# Guia de Uso: Comandos e Skills do keelson

> Guia prático de **como usar** o keelson (spec-driven development) num projeto.
> Para as decisões de governança do processo (o **porquê**), ver [decisions.md](decisions.md).
> Os caminhos e comandos concretos de cada projeto vivem na **ficha** (`keelson.config.json`);
> este guia fala do método, não de um stack específico.

---

## 1. Visão geral em 30 segundos

keelson: a especificação é a fonte da verdade. Todo desenvolvimento não-trivial segue o ciclo:

```
/keelson:specify  →  /keelson:plan  →  /keelson:tasks  →  /keelson:implement
      (SPEC)            (PLAN)            (TASKs)             (código)
```

Cada etapa gera artefatos em `<docsRoot>/<slug>/` (a raiz vem de `docsRoot` na ficha; `docs/` por padrão) e passa por um **gate de validação automático** (skills `*-validator`). O `INDEX.md` de cada slug é mantido automaticamente pelos comandos — **nunca edite manualmente**.

**Não sabe por onde começar?** Use `/keelson:triage "descrição da demanda"` — ele faz triagem e indica o comando certo.

**Modo padrão = autônomo.** No dia a dia você não roda etapa por etapa: peça a tarefa em linguagem natural (ou use `/keelson:auto`) e o ciclo corre de ponta a ponta — as dúvidas críticas são feitas de uma vez na largada (última chamada) e o restante segue até a entrega, com interrupção no meio só em último caso. Quer aprovar etapa a etapa? Use `/keelson:guided`. Ver 3.9 e 3.10 e as decisões 4.10/4.13 de `decisions.md`.

---

## 2. Fluxo típico (exemplo completo)

**O caminho do dia a dia é o autônomo** — você pede, o time conduz (contrato Diretor–PO, §3.9):

```bash
/keelson:auto "Exportação de relatórios em CSV com filtro de período"
# brief emitido (janela de veto) → SPEC → PLAN → TASKs → implement
# → entrega com relatório de aceitação do PO. Você revisa a branch e decide o merge.
```

Por dentro, o ciclo que o auto atravessa — e que você pode dirigir etapa a etapa quando quiser (`/keelson:guided`, ou os comandos avulsos):

```bash
# 1. Especificar o QUÊ (sem tecnologia)
/keelson:specify "Exportação de relatórios em CSV com filtro de período" --slug=relatorios

# 2. Planejar o COMO (arquitetura, componentes, decisões)
/keelson:plan SPEC-001

# 3. Decompor em tarefas atômicas
/keelson:tasks PLAN-001

# 4. Simular execução (recomendado antes de rodar de verdade)
/keelson:implement PLAN-001 --dry-run

# 5. Executar
/keelson:implement PLAN-001
```

Para consultar o estado a qualquer momento:

```bash
/keelson:status relatorios
```

---

## 3. Comandos

### 3.0 Convenções comuns

Conteúdo canônico: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`.

### 3.1 `/keelson:specify` — criar SPEC

Transforma uma demanda em especificação funcional (FRs em EARS, ACs em Given-When-Then, glossário, escopo), **agnóstica de tecnologia** — stack e arquitetura são proibidos na SPEC. O `spec-validator` roda automaticamente ao final; próximo passo: `/keelson:plan SPEC-NNN`.

Detalhe completo (flags, fluxo, regras): `commands/specify.md`.

### 3.2 `/keelson:plan` — criar PLAN

Transforma uma SPEC aprovada em plano técnico — componentes (COMP), decisões (DEC) com alternativas, mapeamento FR → componente, riscos (TRISK) — herdando stack e padrões da ficha e do perfil ativo, sem reescolher. Uma SPEC pode ter vários PLANs (cobertura incremental via `--covers`/`--slice`). Gate: `plan-validator`; próximo passo: `/keelson:tasks PLAN-MMM`.

Detalhe completo (flags, fluxo, regras): `commands/plan.md`.

### 3.3 `/keelson:tasks` — decompor PLAN em TASKs

Quebra o PLAN em tarefas atômicas ordenadas em **waves** por dependência topológica (tasks da mesma wave são paralelizáveis), com campos de closure preparados que o `/keelson:implement` preenche — não os preencha manualmente. Gate: `task-validator` (modo batch); próximo passo: `/keelson:implement PLAN-MMM` (ou `--dry-run` primeiro).

Detalhe completo (flags, fluxo, regras): `commands/tasks.md`.

### 3.4 `/keelson:implement` — executar PLAN

Orquestra a implementação wave por wave via subagents (`developer` + `code-reviewer` e gates dedicados): cada task passa pelos quality gates e closure obrigatória antes de Done; falha = 1 retry, depois escala para humano. Não promove Status do PLAN (apenas sugere), não faz deploy, não cria PR nem modifica SPEC/PLAN durante a implementação.

Detalhe completo (flags, fluxo, regras): `commands/implement.md`.

### 3.5 `/keelson:triage` — triagem de demanda nova

Classifica uma demanda e roteia para SPEC, PLAN, TASK, brief avulso ou ação direta — **não executa nada sem confirmação**. Use quando não sabe qual comando aplicar; a tabela e os critérios canônicos de roteamento são do próprio comando.

**Quando NÃO usar**: se você já sabe o que fazer (vá direto ao comando), para triviais óbvios, ou em emergências.

Detalhe completo (flags, fluxo, regras): `commands/triage.md`.

### 3.6 `/keelson:migrate-legacy` — migrar slug legado

Equaliza um slug pré-keelson (tem README mas não tem INDEX.md): move os `.md` para `legacy/`, grava o TRIAGE durável e gera INDEX mínimo — **não cria** SPECs/PLANs/TASKs retroativas. Política: migrar **on-demand**, quando for mexer no slug pela primeira vez; revise o INDEX gerado (extração é melhor esforço).

**Para onde foi cada coisa do antigo `README.md` por feature** (modelo descontinuado — decisão 4.6 de `decisions.md`):

| Antes (README da feature) | Agora (artefato keelson) |
|---|---|
| Visão de negócio, regras, permissões por papel | **SPEC** (`<docsRoot>/<slug>/specs/SPEC-NNN-*.md`) — contexto, FRs (EARS), glossário |
| Mapa técnico: arquivos por camada, endpoints, códigos de erro | **PLAN** (`<docsRoot>/<slug>/plans/PLAN-MMM-*.md`) — componentes, interface pública, fluxos, modelo de dados |
| Estado / o que existe / progresso | **INDEX.md** (`<docsRoot>/<slug>/INDEX.md`) — gerado pelos comandos `/keelson:*` |

Detalhe completo (flags, fluxo, regras): `commands/migrate-legacy.md`.

### 3.7 `/keelson:rebuild-index` — reconstruir INDEX

Regenera o `INDEX.md` de um slug a partir dos artefatos (SPECs, PLANs, TASKs e o TRIAGE legado, que é reespelhado), com backup do atual. Use quando o INDEX foi deletado, corrompido ou divergiu dos arquivos — não para mudança incremental (operação destrutiva; use os comandos próprios).

Detalhe completo (flags, fluxo, regras): `commands/rebuild-index.md`.

### 3.8 `/keelson:integrate` — preparar entrega (suíte + PR)

Após a implementação de um PLAN concluída (TASKs Done, DoD satisfeita): valida a DoD, roda a suíte completa — e a mutação opt-in da ficha, reaproveitando rodada verde registrada no mesmo estado de código —, gera a descrição e **abre o Pull Request**. Não faz merge nem deploy (decisão humana) e não promove o Status do PLAN.

Detalhe completo (flags, fluxo, regras): `commands/integrate.md`.

### 3.9 `/keelson:auto` — ciclo completo autônomo (modo padrão)

O **default**: conduz `specify → plan → tasks → implement → entrega` de ponta a ponta sem aprovação de etapa, sob o contrato Diretor–PO — brief com janela de veto na largada, decisões em nome do Diretor no meio (interrupção só em último caso), e entrega com relatório de aceitação do PO no esqueleto canônico do `report-contract.md`. A largada também **estima a demanda** (agent `estimator`, seção `## Estimativa` no BRIEF — 4.224, best-effort) e a entrega confronta estimado × realizado, alimentando a calibração do projeto. Entrega = branch + commit + push, **sem PR** — merge e deploy continuam humanos. Basta pedir a tarefa em linguagem natural, sem digitar o comando; ambiente sem tela gera handoff de verificação (§8).

Detalhe completo (flags, fluxo, regras): `commands/auto.md`.

### 3.10 `/keelson:guided` — ciclo com checkpoints (opt-in pausado)

O oposto opt-in do `/keelson:auto`: roda o ciclo pausando em **2 marcos** (SPEC pronta, PLAN pronto) para o seu OK — o PO recomenda, você bate o martelo — e pergunta na hora em qualquer exceção. Use quando quer revisar o contrato e o desenho antes do desenvolvimento.

Detalhe completo (flags, fluxo, regras): `commands/guided.md`.

### 3.11 `/keelson:refine` — lapidar uma ideia crua (opt-in, pré-ciclo)

Refina um pedido vago **antes** de virar demanda: no máximo uma rodada de 2–4 perguntas decisivas e devolve um **prompt refinado** com oferta de disparar o `/keelson:auto`. Não cria artefato keelson nem inicia o ciclo sozinho; pedido claro não precisa dele — o auto absorve ambiguidade não-crítica via premissas `[assumido]`.

Detalhe completo (flags, fluxo, regras): `commands/refine.md`.

### 3.12 `/keelson:audit` — auditoria manual de dependências (CVE/NVD)

Roda a auditoria de vulnerabilidade conhecida sobre as dependências, **em momento oportuno escolhido por você** — cobre o cenário que os gates por diff não cobrem: CVE publicado depois de a dependência entrar. Achado vira **oferta de demanda** de upgrade pelo ciclo normal; o comando não atualiza nada. `full` inclui higiene (desatualizados, abandonados, licenças).

Detalhe completo (flags, fluxo, regras): `commands/audit.md`.

### 3.13 `/keelson:jira-sync` — reconciliar um slug com o Jira (opcional)

Rede de segurança da integração opcional com Jira (conector MCP Atlassian, `jira.enabled` na ficha): reprocessa um slug — ou só a árvore de uma SPEC — criando/vinculando/comentando/transicionando de forma **idempotente** o que os ganchos best-effort do ciclo deixaram para trás; com `--phase` move a árvore no quadro. Nunca bloqueia o ciclo, não cria PR nem faz merge/deploy. A lógica vive no `skills/_shared/jira-sync-protocol.md` — o comando só orquestra.

Detalhe completo (flags, fluxo, regras): `commands/jira-sync.md`.

### 3.14 `/keelson:review` — code review de um diff avulso (sem artefato SDD)

Porta de entrada da doutrina para código que **entrou fora do ciclo** (hotfix, herdado, contribuição externa): a main session despacha os gates aplicáveis **em paralelo** sobre o diff apontado, consolida os achados, pede **um** OK e despacha a correção com re-revisão obrigatória. Sem artefato SDD os gates degradam de forma **declarada**; achado estrutural vira demanda, nunca edição no ato — nada é commitado.

Detalhe completo (flags, fluxo, regras): `commands/review.md`.

### 3.15 `/keelson:specify-epic` — decompor um pedido grande (épico)

Quando o pedido é grande demais para uma demanda (2+ capacidades independentes), o **PM** decompõe em demandas independentes e priorizadas — cada uma segue depois o ciclo normal com o seu PO. Você confirma a decomposição e a estratégia de branch (a única parada, intencional); o comando grava o **BRIEF épico** com a fila viva e devolve a porta de retomada: `/keelson:continue <slug>` (§3.21). **Disparar cada ciclo é decisão sua.**

Detalhe completo (flags, fluxo, regras): `commands/specify-epic.md`.

### 3.16 `/keelson:update` — atualizar o plugin instalado

Atualiza o keelson para a última versão do marketplace, **quando você decidir** (humano-only), via `scripts/update.sh` + CLI do Claude Code. Reporta versão antes/depois, o veredito de re-init (marcadores `Re-init:` do CHANGELOG — exige · não exige · não determinável) e termina lembrando de **reiniciar a sessão**: o update não vale para a sessão corrente.

Detalhe completo (flags, fluxo, regras): `commands/update.md`.

### 3.17 `/keelson:postmortem` — postmortem de fim de sessão

Rodado pelo Diretor no **fim da sessão** (humano-only), ou apontando um episódio passado: relê as interações como fonte primária de evidência, cruza com git e artefatos do ciclo, e monta a tabela dos fatos, os mecanismos por causa-raiz e o ponto de intervenção mais barato de cada um. Saídas: o doc durável em `<docsRoot>/_meta/postmortems/` e o **bloco copy-paste ao mantenedor**. Não corrige nada (defeito aberto → `/keelson:triage`).

Detalhe completo (flags, fluxo, regras): `commands/postmortem.md`.

### 3.18 `/keelson:report` — refazer o relatório de fecho

Rede de segurança, não caminho normal (humano-only): refaz o relatório de fecho a partir do **ledger de sessão** + diff da branch + INDEX, para quando o fecho automático não existe ou não serve mais (sessão retomada, contexto comprimido, report perdido no scroll). Gate sem evento registrado vira lacuna nomeada, nunca "aprovado". Não commita, não corrige, não move card.

Detalhe completo (flags, fluxo, regras): `commands/report.md`.

### 3.19 `/keelson:brief` — forjar documento de produto em BRIEF (opt-in, pré-ciclo)

O estágio profundo pré-ciclo (humano-only — é uma conversa com você): recebe o documento da área de produto, inventaria contra as seções que a SPEC vai exigir, responde pelo código o que o código responde (`code-scout`), pergunta uma coisa por vez só o que faltou e formaliza como **Q-ID** o que só produto responde. Sai por 3 portas: BRIEF `pronto` (+ handoff para o `/keelson:auto`) · continuar a conversa · `aguardando-produto`. Ideia crua e leve é o `/keelson:refine`; documento de produto e profundidade é aqui.

Detalhe completo (flags, fluxo, regras): `commands/brief.md`.

### 3.20 `/keelson:mutation-setup` — configurar o gate de mutação (humano-only)

Setup guiado do gate de mutação para quem não conhece a ferramenta: detecta a stack pela ficha, instala a ferramenta canônica **com a sua confirmação**, prova o pipeline com rodada-amostra e só então grava `quality.mutation` — sem threshold na primeira adoção (gate informativo; calibrar o score mínimo após 1–2 entregas é ato seu). Não roda a mutação completa nem commita o setup.

Detalhe completo (flags, fluxo, regras): `commands/mutation-setup.md`.

### 3.21 `/keelson:continue` — retomar um slug de onde parou (humano-only)

A porta única de retomada: você aponta um slug e o comando deriva **dos artefatos commitados** onde o trabalho parou, mostra o "você está aqui" e propõe **um** próximo passo com default — executa só após a sua confirmação. Depois de um fim de semana, ninguém precisa lembrar de nada: `continue` + o slug.

Detalhe completo (flags, fluxo, regras): `commands/continue.md`.

### 3.22 `/keelson:e2e-setup` — configurar a suíte E2E (humano-only)

Setup guiado da suíte E2E para quem não conhece a ferramenta: instala o Playwright **com a sua confirmação**, gera config, esqueleto de auth por realm e smoke spec a partir da ficha, prova com `--list`, roda o gate 8 sobre o diff quando ativo e só então grava `quality.e2e`. Os specs de AC não nascem aqui — são entregáveis do developer, task a task; não roda a regressão completa nem commita o setup.

Detalhe completo (flags, fluxo, regras): `commands/e2e-setup.md`.

### 3.23 `/keelson:lessons-audit` — auditar o acervo de lições do projeto

Audita `guidelines/project/lessons.md` sob o ciclo de vida da 4.221: retrofita o formato (Validade/Estado/Contadores) em acervo pré-existente (conservador: lição antiga entra `ativa`), mede a origem por git (pickaxe por bloco; imensurável degrada para `indeterminada`, nunca inventa), aplica direto os vereditos de **fato** (Validade testável e falsa) e propõe os de **juízo** (sedimento, no-op, duplicata — régua 4.160) só com a sua confirmação; na dúvida, mantém. Revogada vira tombstone de 1 linha na seção `## Revogadas` (conteúdo integral no histórico do git). Não cria lição, não aplica a escada de contestação (papel do fecho/closure) e não commita.

Detalhe completo (flags, fluxo, regras): `commands/lessons-audit.md`.

### 3.24 `/keelson:estimate` — dimensionar uma demanda antes do ciclo

Devolve a dimensão prevista de uma demanda — `~N waves · ~N tasks` (mix small/medium) + faixa de tempo por fase (entrevista, artefatos, implementação, gates) — via agent `estimator`, calibrado pelo histórico estimado × realizado do projeto (`guidelines/project/estimates.md`). Read-only: não cria artefato SDD e não roteia. Pedido vago → `não estimável` com as lacunas nomeadas, nunca número inventado. A dimensão informa a priorização do Diretor; **a rota continua do `/keelson:triage`** (4.137: tamanho nunca decide rota) e a estimativa nunca entra em campo medido (worklog/Duração — 4.56). Dono da régua: `docs/_meta/conventions/estimate-contract.md` (decisão 4.223).

Detalhe completo (flags, fluxo, regras): `commands/estimate.md`.

### 3.25 `/keelson:merge` — mesclar branches na corrente (humano-only)

Mescla uma ou mais branches na branch de trabalho corrente, **uma de cada vez**: para
cada branch, roda o dry-run de conflito textual (4.74) e a reconciliação semântica
(4.235). Branch limpa (sem conflito, sem achado, suíte verde) fecha o commit direto,
sem despachar ninguém; havendo conflito, achado de reconciliação ou teste quebrado, o
`developer` resolve **só os pontos tocados** e o `code-reviewer` audita **só esse
diff** (gates 1–7) — e então fecha **um commit de merge próprio** para aquela branch,
antes de seguir para a próxima. Falha de suíte ou de gate após 1 retry
interrompe a fila naquele ponto (branches anteriores ficam commitadas, as seguintes não
são tentadas) e escala ao humano. Exceção declarada à regra "nenhum comando faz merge"
(`docs/_meta/conventions/sdd-conventions.md`, decisão 4.251): nunca dá push, nunca
mergeia para a branch principal remota, nunca abre PR, nunca faz deploy.

Detalhe completo (flags, fluxo, regras): `commands/merge.md`.

---

## 4. Skills

Skills não geram artefatos novos — validam ou consultam. As três validators rodam **automaticamente** ao final do comando correspondente, mas podem ser invocadas sob demanda ("valide a SPEC-002", "lint no PLAN-001").

| Skill | Valida/Faz | Disparo automático |
|---|---|---|
| `spec-validator` | EARS, RFC 2119, IDs, verificabilidade FR↔AC, domínio vs tecnologia, glossário, escopo simétrico | Final do `/keelson:specify` |
| `plan-validator` | Estrutura, cobertura declarada, DECs com alternativas, grafo de componentes (fato mecânico via `graph.sh`), aderência ao Charter + perfil, DoD | Final do `/keelson:plan` |
| `task-validator` | Vinculação, dependências, ciclos, waves e cobertura FR/AC (fato mecânico via `graph.sh`), convenções, campos de closure preparados | Final do `/keelson:tasks` |
| `status` | **Consulta** (read-only): resumo executivo do estado de um slug | Perguntas sobre estado/progresso |

Os checks **estruturais** do plan/task-validator chegam como **fato mecânico**:
`scripts/graph.sh` extrai o grafo dos artefatos (nós e arestas tipadas) e computa
ciclos, referências quebradas, cobertura e waves — o validator cita e calibra, nunca
re-deriva. Régua e contrato: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md`
(decisão 4.82). O `/keelson:status` desenha o grafo em Mermaid quando a pergunta é
sobre dependências ou ordem.

### Severidades e gate de status

ERROR bloqueia a promoção (SPEC/PLAN não vai a `Approved`; TASK vira `Blocked`); WARNING não bloqueia; violação trivial recebe auto-fix. A promoção de Status (`Draft` → `Approved`/`Done`) **nunca é do validator**, mesmo com zero errors — no ciclo com brief a main session promove pelo veredito do `po` (4.38); sem brief ou no guided, é humana. Override consciente de ERROR: bloco declarado no próprio artefato — formato e regras no dono da moldura, `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md` (§3–§4).

### `/keelson:status` — consultar estado

```
/keelson:status <slug>                      # visão geral
/keelson:status <slug> --focus=risks        # apenas riscos ativos
/keelson:status <slug> --focus=glossary     # apenas glossário
/keelson:status <slug> --focus=in-progress  # apenas o que está em desenvolvimento
/keelson:status <slug> --focus=decisions    # apenas decisões irreversíveis
```

Nunca modifica arquivos. Se detectar divergência entre INDEX e arquivos, sugere `/keelson:rebuild-index`.

---

## 5. Agents (o time — uso interno dos comandos)

Os agents formam o **time** do keelson (modelo de time e contrato Diretor–PO — decisões 4.37/4.38): a main session atua como **Tech Lead** e o humano é o **Diretor** (emite o brief, mantém o veto; PR, merge e deploy são dele). Você normalmente não invoca estes diretamente — os comandos os orquestram. O papel completo de cada um é a `description` do frontmatter do próprio agent (fonte única):

| Agent | Papel no time | Invocado por |
|---|---|---|
| `po` | **PO** — dono da demanda; valida SPEC e entrega contra o brief | `/keelson:specify`, `/keelson:auto`, `/keelson:implement` |
| `pm` | **PM** — decompõe brief épico em demandas priorizadas | `/keelson:specify-epic` |
| `developer` | **Developer** — implementa uma única TASK | `/keelson:implement`, `/keelson:review`, `/keelson:merge` |
| `code-reviewer` | **Code Reviewer** — quality gates 1–7 antes da closure; convergência de fecho (4.143) | `/keelson:implement`, `/keelson:review`, `/keelson:merge`, fecho do ciclo (`/keelson:auto` · `/keelson:integrate`) |
| `security-engineer` | **Security Engineer** — gate 8, em mudança sensível | `/keelson:implement`, `/keelson:review`, `/keelson:merge` |
| `performance-engineer` | **Performance Engineer** — gate 10, quando o diff toca superfície de custo (4.155) | `/keelson:implement`, `/keelson:review` |
| `product-designer` | **Product Designer** — gate 11, quando o diff toca superfície de interface (4.218) | `/keelson:implement`, `/keelson:review` |
| `qa` | **QA** — gate 9 + verificabilidade pré-código | `/keelson:implement`, `/keelson:auto`, `/keelson:review` |
| `product-analyst` | **Product Analyst** — crítica de mérito da SPEC (o PO a resolve) | `/keelson:specify` |
| `agile-coach` | **Agile Coach** — auto-aprendizado do processo | closure do `/keelson:implement`, `/keelson:auto`, `/keelson:review`, sob demanda |
| `staff-engineer` | **Staff Engineer** — gera perfis de linguagem | `/keelson:init`, sob demanda |
| `code-scout` | *(ferramenta, fora do elenco)* — reconhecimento de codebase, devolve conclusão ancorada em `arquivo:linha` | Tech Lead (main session), fases exploratórias e sessão livre |
| `scribe` | *(ferramenta, fora do elenco)* — redige SPEC/PLAN/TASKs pelo contrato do comando; devolve sumário, não o conteúdo (4.103) | `/keelson:specify`, `/keelson:plan`, `/keelson:tasks` |
| `tracker-sync` | *(ferramenta, fora do elenco)* — executa os ganchos do protocolo Jira; devolve o resumo canônico do tracker (4.103) | ganchos de `/keelson:specify`, `/keelson:tasks`, `/keelson:implement`, `/keelson:auto`; `/keelson:jira-sync` |
| `estimator` | *(ferramenta, fora do elenco)* — dimensiona demanda antes do ciclo: waves/tasks previstos + faixa por fase, com calibração histórica; recusa estimar sem base (4.223) | `/keelson:estimate`, Tech Lead sob demanda |

Os validators (`spec-validator`, `plan-validator`, `task-validator`) e o `code-scout` ficam **fora do elenco de propósito**: são ferramentas do time, não papéis (decisões 4.37/4.73).

**Modo sob demanda** (decisão 4.75): em sessão livre, mudança pontual de código não entra no ciclo — mas tampouco é feita pela main session. **Declaração de intenção pontual do Diretor** ("ajuste pontual", "sem ciclo", "mudança direta") **escolhe este modo como default de porta, sem re-julgar** (decisão 4.246; vale **fora de comando em execução** — inclusive logo após a entrega de um ciclo na mesma sessão, quando a sessão volta a ser livre; comando `/keelson:*` invocado segue o contrato do comando, 4.129): a promoção ao ciclo continua existindo só pela régua falsificável (4.86/4.205) e é **declarada com motivo antes de seguir, nunca arbitrada em silêncio** (família 4.85). O Tech Lead destila um briefing curto — que desde a 4.86 **nasce em arquivo**, como brief avulso (`briefs/BRIEF-MMM-*-avulso.md`; mudança que cruza slugs → um brief só, no slug dominante, com rastro no INDEX dos demais — decisão 4.87, regra no `index-contract.md`), e com `jira.enabled` + `issueType.standalone` vira Story no quadro **antes do código** (key existente citada pelo Diretor → nenhum card novo) —, delega ao `developer`, revisa com `code-reviewer` (régua avulsa da 4.36) e aciona `security-engineer`/`qa`/`performance-engineer`/`product-designer` pelos gatilhos usuais (mudança sensível · comportamento observável · superfície de custo · superfície de interface) — os gates aplicáveis **em paralelo, no mesmo turno**, sobre um **pacote de contexto único e factual** (decisão 4.89, dono: `core/CODE-REVIEW.md` §Orquestração). Correção pós-gate segue a **régua de convergência** (decisão 4.88, dono: `core/CODE-REVIEW.md`): re-review sobre o delta, 1 retry e depois escala ao Diretor, achado só-texto não reabre o ciclo, narrativa de correção no report — nunca em comentário. Invocar um agent **não puxa o ciclo** — cada um devolve sua tarefa e para; commit é a pedido do Diretor. Só o trivial não-comportamental (typo de comentário/doc) pode ser inline, declarado — sem brief e sem card — e trivial tem teste pré-despacho (decisão 4.205, dono: `index-contract.md`): diff que introduz ou propaga campo/contrato através de fronteira de camada **não é trivial**, por menor que pareça. O fecho da rodada roteia toda `licao_candidata` devolvida pelos gates antes de se declarar completo (decisão 4.204, forma no `report-contract.md`). Conflito entre este contrato e a política da sessão/harness (restrição de subagents, permissões, modo) **escala ao Diretor com proposta + default** — nunca se resolve em silêncio (4.85).

---

## 6. Artefatos e IDs

Conteúdo canônico (árvore de artefatos, IDs, contrato da tabela "PLANs", template e receita do INDEX): `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`.

---

## 7. Regras de ouro

1. **INDEX.md é gerado** — nunca edite. Errou? `/keelson:rebuild-index <slug>`.
2. **SPEC não fala de tecnologia.** Linguagem, framework, banco, protocolo etc. só entram no PLAN.
3. **Promoção de Status nunca é do validator.** Ele bloqueia errors; quem promove `Draft → Approved → Done` é o PO/main session no ciclo com brief (modo autônomo, 4.38), ou **você** no fluxo avulso e no `/keelson:guided`.
4. **Closure é inegociável.** Task sem "Histórico de execução" preenchido não é Done, mesmo com código pronto.
5. **Trivial pula o ciclo.** Typo, copy, cor: commit direto no padrão do perfil ativo.
6. **Legado primeiro migra, depois muda.** Slug sem INDEX.md → `/keelson:migrate-legacy` antes de qualquer `/keelson:triage`.
7. **Na dúvida, `/keelson:triage`.** Ele classifica a demanda e te dá o comando pronto.
8. **Entrega sem tela não silencia o gate 9.** Ambiente sem acesso a testes de tela → **handoff de verificação** obrigatório (ver §8); a entrega é declarada parcial até o handoff ser fechado.

---

## 8. Handoff de verificação de tela (gate de comportamento remoto)

Conteúdo canônico (ciclo de vida §8.1, template canônico §8.2, prompt canônico §8.3): `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/handoff-protocol.md`.
