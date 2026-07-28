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

Transforma uma demanda em especificação funcional (FRs em EARS, ACs em Given-When-Then, glossário, escopo). **Agnóstica de tecnologia** — stack e arquitetura são proibidos na SPEC.

```
/keelson:specify <descrição em linguagem natural ou @arquivo> [--slug=<nome>]
```

| Aspecto | Detalhe |
|---|---|
| Gera | `<docsRoot>/<slug>/specs/SPEC-NNN-<titulo>.md` |
| Atualiza | `INDEX.md` do slug (cria se não existir) |
| Gate | `spec-validator` roda automaticamente ao final |
| Próximo passo | `/keelson:plan SPEC-NNN` |

Pode fazer até 4 perguntas se houver ambiguidade crítica (contrato externo, falha, segurança, decisão irreversível); em fluxo autônomo pós-largada, não pausa (escada de reação do `/keelson:auto`). Ambiguidade menor vira premissa `[assumido]` — revise-as no output.

SPEC com **2+ fluxos entregáveis** (unidades de teste do QA) agrupa os FRs da §5 sob headings `### FEAT-NNN-XXX: <nome>` — cada FR pertence a exatamente uma FEAT; os ACs derivam a filiação do FR que cobrem. Um fluxo só → **não** declare a camada (a funcionalidade colapsa na própria SPEC). Decisão 4.27.

### 3.2 `/keelson:plan` — criar PLAN

Transforma uma SPEC em plano técnico: componentes (COMP), decisões arquiteturais (DEC) com alternativas, mapeamento FR → componente, riscos técnicos (TRISK). Herda stack e padrões da **ficha** (`keelson.config.json`) e do **perfil ativo** — não reescolhe.

```
/keelson:plan <SPEC-NNN ou caminho> [--covers=FR-NNN-001,FR-NNN-002] [--slice="descrição"]
```

| Flag | Uso |
|---|---|
| (nenhuma) | Cobre todos os FRs/NFRs ainda não cobertos por PLANs anteriores |
| `--covers=...` | Cobre apenas os FRs/NFRs listados (entrega incremental) |
| `--slice="..."` | Descreve em linguagem natural o recorte desejado; o comando interpreta contra os FRs e confirma |

| Aspecto | Detalhe |
|---|---|
| Gera | `<docsRoot>/<slug>/plans/PLAN-MMM-<titulo>.md` |
| Gate | `plan-validator` |
| Próximo passo | `/keelson:tasks PLAN-MMM` |

Uma SPEC pode ter vários PLANs (cobertura incremental). DECs marcadas `Irreversível: sim` são propagadas ao INDEX e passam a restringir PLANs futuros.

### 3.3 `/keelson:tasks` — decompor PLAN em TASKs

Quebra o PLAN em tarefas atômicas (small: 30min–2h, medium: 2–4h), ordenadas em **waves** por dependência topológica. Tasks da mesma wave são paralelizáveis.

```
/keelson:tasks <PLAN-MMM ou caminho> [--max-size=<tamanho>] [--only=COMP-MMM-XXX]
```

| Aspecto | Detalhe |
|---|---|
| Gera | `<docsRoot>/<slug>/tasks/TASK-MMM-XXX-<titulo>.md` (um arquivo por task) + `TASK-MMM-INDEX.md` |
| Gate | `task-validator` (modo batch) |
| Próximo passo | `/keelson:implement PLAN-MMM` (ou `--dry-run` primeiro) |

Cada TASK contém campos de closure vazios ("Histórico de execução") que o `/keelson:implement` preenche. Não preencha manualmente.

Quando a SPEC declara FEATs, cada TASK ganha o campo `**Funcionalidade**:` (FEATs dos FRs realizados, uma marcada `(primária)`; task transversal lista todas) e o `TASK-MMM-INDEX.md` ganha a seção "Cobertura por funcionalidade" (FEAT → TASKs → Done).

### 3.4 `/keelson:implement` — executar PLAN

Orquestra a implementação wave por wave, usando subagents (`developer` + `code-reviewer`) ou Agent Teams. Cada task passa pelos quality gates e closure obrigatória antes de Done.

```
/keelson:implement <PLAN-MMM ou caminho> [--max-parallel=<N>] [--dry-run] [--only-wave=<N>] [--force-mode=<teams|subagents>]
```

| Flag | Uso |
|---|---|
| `--dry-run` | Imprime o plano de execução (modo, waves, paralelismo) sem executar |
| `--only-wave=N` | Executa apenas a wave N |
| `--max-parallel=N` | Limita paralelismo |
| `--force-mode=...` | Força `teams` ou `subagents` (default: `subagents`) |

**Quality gates por task** (obrigatórios): implementação completa, testes cobrindo ACs passando, lint limpo, escopo respeitado, DECs respeitadas, aderência ao Charter + perfil ativo, code review pelo reviewer agent. Falha = 1 retry, depois escala para humano.

**O que ele NÃO faz**: promover Status do PLAN para Done (apenas sugere), deploy, criar PR, resolver conflito de merge, modificar SPEC/PLAN durante a implementação.

### 3.5 `/keelson:triage` — triagem de demanda nova

Quando você não sabe se uma demanda vira SPEC, PLAN ou TASK, este comando classifica e roteia. **Não executa nada sem confirmação.**

```
/keelson:triage <descrição em linguagem natural> [--slug=<nome>]
```

Roteamento em resumo: contrato novo → SPEC; contrato igual com estratégia nova → PLAN `--slice`; bug/refactor → TASK pré-preenchida; trivial → direto no código; slug legado sem INDEX → `/keelson:migrate-legacy` antes. A tabela e os critérios canônicos são do próprio comando: `${CLAUDE_PLUGIN_ROOT}/commands/triage.md`.

**Quando NÃO usar**: se você já sabe o que fazer (vá direto ao comando), para triviais óbvios, ou em emergências.

### 3.6 `/keelson:migrate-legacy` — migrar slug legado

Equaliza um slug pré-keelson (tem README mas não tem INDEX.md): move os `.md` da raiz para `legacy/`, gera INDEX mínimo a partir do README, cria pastas `specs/`, `plans/`, `tasks/` vazias.

```
/keelson:migrate-legacy <slug> [--dry-run] [--keep-in-place]
```

**Não cria** SPECs/PLANs/TASKs retroativas — o histórico keelson do slug começa a partir da migração. Preserva tudo (usa `git mv`). Revise o INDEX gerado: a extração do README é melhor esforço. Política: migrar **on-demand**, quando for mexer no slug pela primeira vez.

**Para onde foi cada coisa do antigo `README.md` por feature** (modelo descontinuado — decisão 4.6 de `decisions.md`):

| Antes (README da feature) | Agora (artefato keelson) |
|---|---|
| Visão de negócio, regras, permissões por papel | **SPEC** (`<docsRoot>/<slug>/specs/SPEC-NNN-*.md`) — contexto, FRs (EARS), glossário |
| Mapa técnico: arquivos por camada, endpoints, códigos de erro | **PLAN** (`<docsRoot>/<slug>/plans/PLAN-MMM-*.md`) — componentes, interface pública, fluxos, modelo de dados |
| Estado / o que existe / progresso | **INDEX.md** (`<docsRoot>/<slug>/INDEX.md`) — gerado pelos comandos `/keelson:*` |

### 3.7 `/keelson:rebuild-index` — reconstruir INDEX

Regenera o `INDEX.md` de um slug a partir dos arquivos individuais (SPECs, PLANs, TASKs). Faz backup do INDEX atual antes.

```
/keelson:rebuild-index <slug> [--dry-run]
```

**Quando usar**: INDEX deletado, corrompido, ou divergente dos arquivos. **Quando NÃO usar**: INDEX consistente (operação destrutiva) ou mudança incremental (use os comandos próprios). Também detecta inconsistências (FRs órfãos, PLANs sem SPEC, status incoerente) e pergunta antes de prosseguir nas críticas.

> ⚠️ Achados de migração vivem em `legacy/TRIAGE-*.md` (fonte durável); o `/keelson:rebuild-index` deriva o INDEX de specs/plans/tasks **e reespelha as seções legadas a partir do TRIAGE** — o que não estiver no TRIAGE se perde no rebuild (ver `/keelson:migrate-legacy` e a decisão 4.5 / LRN-012).

### 3.8 `/keelson:integrate` — preparar entrega (suíte + PR)

Após a implementação de um PLAN concluída (TASKs Done, DoD satisfeita), valida a DoD, roda a suíte completa (comando `quality.test` da ficha), gera a descrição e **abre o Pull Request**.

```
/keelson:integrate <PLAN-MMM ou caminho> [--base=<branch>] [--draft] [--dry-run]
```

**Não faz merge nem deploy** — isso permanece decisão humana. Não promove o Status do PLAN (apenas sugere).

### 3.9 `/keelson:auto` — ciclo completo autônomo (modo padrão)

Conduz `specify → plan → tasks → implement → entrega` de ponta a ponta **sem aprovação de etapa**, sob o **contrato Diretor–PO** (decisões 4.37/4.38): você é o **Diretor**. Abre com a **última chamada**: escalação pré-largada só pelos 4 critérios do contrato (pedido claro → nenhuma pergunta) + **brief** — o pedido como dito + a interpretação do PO, persistidos em `briefs/BRIEF-NNN.md`; a interpretação é apresentada e o fluxo **segue sem esperar** (janela de veto: silêncio = seguir; correção sua → brief re-emitido). O brief **vira a fonte da demanda**: a SPEC nasce dele e o PO valida SPEC e entrega contra ele. Depois da largada, não deixa pergunta pendurada: dificuldade vira decisão em nome do Diretor ou parte estacionada perguntada em lote na entrega; interrupção no meio só em **último caso** (errar custaria o ciclo inteiro). A entrega fecha com o **relatório de aceitação do PO** e o estado de pendência do Diretor. É o **default**: basta pedir a tarefa em linguagem natural, sem digitar o comando. Governança: decisões 4.10, 4.11, 4.13, 4.14, 4.37 e 4.38 de `decisions.md`.

```
/keelson:auto <descrição ou @arquivo> [--slug=<nome>]
```

Rigor proporcional preservado (trivial → direto; bug/refactor → inline; feature → ciclo completo). **Entrega**: branch + commit + push, **sem PR**. Merge e deploy continuam humanos. Com Jira ativo, o fecho roda a **reconciliação** do protocolo de sync (idempotente — rede para ganchos que não rodaram) e o report traz a **linha de estado do tracker** (Epic · Story · sub-tarefas K/N · transições) — best-effort não bloqueia, mas sempre conta. Ciclo que gerou `PROPOSTA_PLUGIN` (lição de processo cujo dono é o plugin) → o report traz também a **mensagem ao mantenedor** composta pelo `agile-coach`, em bloco copy-paste para você encaminhar. Governança: decisões 4.10, 4.53 e 4.54 de `decisions.md`.

**Ambiente sem tela** (worktree/nuvem, ou `gates.screenVerify` sem app disponível): o gate 9 não exercitável gera **handoff de verificação** — doc com roteiro + prompt copy-paste no report para um agente com tela fechar a verificação (ver §8). A entrega é declarada parcial até lá. A verificação em si roda pela skill `screen-verify` (Playwright MCP, headless por padrão — decisão 4.49), e a indisponibilidade que gera o handoff é **provada e nomeada** por causa; a régua é do §8.

### 3.10 `/keelson:guided` — ciclo com checkpoints (opt-in pausado)

O oposto opt-in do `/keelson:auto`: roda o ciclo **pausando em 2 marcos** (SPEC pronta, PLAN pronto) para o seu OK, e com a **régua estrita** de perguntar na hora em qualquer exceção (você está acompanhando — a escada de estacionamento do auto não se aplica). O brief é gravado igual, mas **confirmado na hora** (sem janela de veto); no CHECKPOINT 1 o **PO recomenda e você bate o martelo**. Use quando quer revisar o contrato e o desenho antes do desenvolvimento.

```
/keelson:guided <descrição ou @arquivo> [--slug=<nome>]
```

### 3.11 `/keelson:refine` — lapidar uma ideia crua (opt-in, pré-ciclo)

Refina um pedido vago **antes** de virar demanda: ancoragem barata no domínio, no máximo uma rodada de 2–4 perguntas (só as que mudam o caminho), e devolve um **prompt refinado** (contexto, pedido, premissas decididas, fora de escopo) com oferta de disparar o `/keelson:auto`. Não cria artefato keelson nem inicia o ciclo sozinho. Use quando **você** sente que a ideia está crua; pedido claro não precisa dele — o `/keelson:auto` absorve ambiguidade não-crítica via premissas `[assumido]`.

```
/keelson:refine <ideia em linguagem natural ou @arquivo>
```

### 3.12 `/keelson:audit` — auditoria manual de dependências (CVE/NVD)

Roda a auditoria de vulnerabilidade conhecida sobre as dependências, **em momento oportuno escolhido por você** (começo de ciclo, antes de entrega grande, projeto parado). Cobre o cenário que os gates por diff não cobrem: CVE publicado **depois** de a dependência entrar. Resolve a ferramenta pela §8 do perfil ativo (fallback: detecção de lockfile), cita o CVE ID da saída da ferramenta (nunca de memória) e reporta ecossistema sem ferramenta como `INDISPONÍVEL` — nunca em silêncio. Achado vira **oferta de demanda** de upgrade pelo ciclo normal; o comando não atualiza nada.

```
/keelson:audit [full]
```

`full` inclui higiene (desatualizados, abandonados, licenças). É manual (pull) — para cobertura contínua, Dependabot/Renovate ou CI agendada. Governança: decisão 4.17 de `decisions.md`.

### 3.13 `/keelson:jira-sync` — reconciliar um slug com o Jira (opcional)

Rede de segurança da integração opcional com Jira (via **conector MCP Atlassian**, ligada em `jira.enabled` na ficha). Os comandos do ciclo já sincronizam **best-effort**, e o fecho do `/keelson:auto` roda a mesma reconciliação automaticamente (decisão 4.53); este comando avulso cobre o resto — backfill de slug antigo, ciclo interrompido antes da entrega, conector que só ficou disponível depois — reprocessando o slug e criando/vinculando/comentando/transicionando o que ficou para trás, de forma **idempotente**.

```
/keelson:jira-sync <slug ou PLAN-MMM> [--dry-run]
```

| Aspecto | Detalhe |
|---|---|
| Gera | Issues, Stories de FEAT (quando a SPEC declara FEATs e `issueType.feature` está preenchido), sub-tasks e tarefas isoladas (`issueType.standalone` — TASK avulsa ou transversal sem primária) no Jira (via conector); grava a linha `**Jira**:` no cabeçalho da SPEC, sob os headings FEAT e na closure das TASKs |
| Atualiza | 1 linha no "Histórico recente" do `INDEX.md` (contrato da tabela "PLANs" intocado) |
| Gate | — (best-effort; `jira.enabled:false` ou conector ausente → não faz nada) |
| Pré-condição | Rodar **de dentro do repo consumidor** (ficha no cwd). A Etapa 0 resolve a **viabilidade da projeção** antes de planejar — 3 níveis · 2 níveis · 2 níveis via Story implícita · 2 níveis via `standalone` · inviável (com a perna que não aninha) — e sinaliza **backfill** quando o slug já está concluído e `transition` não move card |
| Lógica | Toda no `skills/_shared/jira-sync-protocol.md` (régua de hierarquia: §7.0; 3º nível: `jira-sync-feat.md`) — o comando só orquestra |

Nunca bloqueia o ciclo, não cria PR nem faz merge/deploy. Governança: decisões 4.22, 4.27, 4.28, 4.43 e 4.53 de `decisions.md`.

### 3.14 `/keelson:review` — code review de um diff avulso (sem artefato SDD)

Porta de entrada da doutrina para o código que **entrou fora do ciclo**: hotfix, código herdado, contribuição externa, mudança feita à mão. Você aponta um diff — working tree, `staged`, `last`, `-N` commits, um `<sha>`, um range `<a>..<b>` ou `branch` — e a main session assume seu papel de **Tech Lead**: despacha `code-reviewer` (gates 1–7) e, em área sensível, `security-engineer` (gate 8) **em paralelo**; consolida e classifica cada achado; pede **um** OK; e então despacha a correção ao `developer`, com **re-revisão obrigatória** do que foi corrigido (mais `qa` quando a correção tem efeito observável).

```
/keelson:review [alvo] [--fix] [--no-security] [--paths=<a,b>]
```

Sem TASK não há AC, escopo declarado nem DEC: os gates 1, 4 e 5 **degradam** (prova exigida para toda lógica nova; coerência do diff no lugar do escopo; decisões irreversíveis do INDEX quando o slug é inferível) e todo gate degradado ou `n/a` é **declarado** — a régua da degradação tem dono único em `guidelines/core/CODE-REVIEW.md`. Achado **estrutural** vira demanda (`/keelson:triage` ou TASK de bugfix), nunca edição no ato; nada é commitado e nenhum artefato durável é criado. Governança: decisão 4.36 de `decisions.md`.

### 3.15 `/keelson:specify-epic` — decompor um pedido grande (épico)

Quando o pedido é grande demais para uma demanda (2+ capacidades independentes, 2+ slugs prováveis, um roadmap numa frase), o **PM** do time decompõe em demandas independentes e priorizadas — cada uma segue depois o ciclo normal (`/keelson:auto`) com o seu PO. Você (Diretor) **confirma a decomposição** — é a única parada, e é intencional: decomposição errada contamina N ciclos. O comando grava o **BRIEF épico** no slug-âncora e devolve a fila com o comando pronto para a demanda 1; **disparar cada ciclo é decisão sua** (nada roda sozinho).

```
/keelson:specify-epic <pedido épico ou @arquivo> [--slug=<âncora>]
```

Rotas de chegada: direto, pela categoria 7 do `/keelson:triage`, ou proposto pelo `/keelson:auto` na triagem de rigor (pré-largada; pós-largada, expansão de escopo é escalação do PO, nunca re-decomposição). Governança: decisões 4.37 e 4.39 de `decisions.md`.

---

## 4. Skills

Skills não geram artefatos novos — validam ou consultam. As três validators rodam **automaticamente** ao final do comando correspondente, mas podem ser invocadas sob demanda ("valide a SPEC-002", "lint no PLAN-001").

| Skill | Valida/Faz | Disparo automático |
|---|---|---|
| `spec-validator` | EARS, RFC 2119, IDs, verificabilidade FR↔AC, domínio vs tecnologia, glossário, escopo simétrico | Final do `/keelson:specify` |
| `plan-validator` | Estrutura, cobertura declarada, DECs com alternativas, mapeamento FR→COMP, aderência ao Charter + perfil, DoD | Final do `/keelson:plan` |
| `task-validator` | Vinculação ao PLAN, FRs/ACs existentes, dependências sem ciclo, convenções, campos de closure preparados | Final do `/keelson:tasks` |
| `status` | **Consulta** (read-only): resumo executivo do estado de um slug | Perguntas sobre estado/progresso |

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
| `developer` | **Developer** — implementa uma única TASK | `/keelson:implement`, `/keelson:review` |
| `code-reviewer` | **Code Reviewer** — quality gates 1–7 antes da closure | `/keelson:implement`, `/keelson:review` |
| `security-engineer` | **Security Engineer** — gate 8, em mudança sensível | `/keelson:implement`, `/keelson:review` |
| `qa` | **QA** — gate 9 + verificabilidade pré-código | `/keelson:implement`, `/keelson:auto`, `/keelson:review` |
| `product-analyst` | **Product Analyst** — crítica de mérito da SPEC (o PO a resolve) | `/keelson:specify` |
| `agile-coach` | **Agile Coach** — auto-aprendizado do processo | closure do `/keelson:implement`, `/keelson:auto`, `/keelson:review`, sob demanda |
| `staff-engineer` | **Staff Engineer** — gera perfis de linguagem | `/keelson:init`, sob demanda |

Os validators (`spec-validator`, `plan-validator`, `task-validator`) ficam **fora do elenco de propósito**: são ferramentas do time, não papéis (decisão 4.37).

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
