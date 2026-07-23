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

### 3.0 Convenções comuns (fonte única — os comandos apontam para cá)

Todo comando `/keelson:*` segue estas convenções sem redeclará-las:

- **Ficha primeiro.** Ler `keelson.config.json` na raiz antes de qualquer coisa — dela vêm `docsRoot`, `codePaths`, `profile`, os comandos de qualidade (`quality.*`) e os `gates`. Nunca assumir caminhos ou comandos fixos.
- **Perfil de linguagem ativo.** Resolvido pelo campo `profile.<role>.file` da ficha: prefixo `plugin:` → `${CLAUDE_PLUGIN_ROOT}/guidelines/<resto>`; caminho simples → relativo à raiz do projeto; campo ausente → exemplar do plugin com a mesma `lang`, senão `guidelines/project/<role>/`. Perfil com `reviewed: false` no front-matter → avisar que está pendente de revisão humana. A doutrina `${CLAUDE_PLUGIN_ROOT}/guidelines/core/*` está sempre ativa; some as lições do projeto (`guidelines/project/`).
- **Memo de exploração.** Exploração de código/domínio é salva em `thoughts/local/exploration-<slug>.md` (concisa: caminhos + mecanismo); as etapas seguintes leem o memo em vez de re-explorar e o complementam se faltar detalhe. O memo é snapshot — antes de editar, vale o arquivo real.
- **Estado de run (guarda anti-parada).** Execução de waves mantém `thoughts/local/run-state-<slug>.md` — formato canônico (uma linha por campo, exatamente estas chaves):

  ```md
  status: em_andamento
  slug: <slug>
  plan: PLAN-MMM
  waves_concluidas: <X>
  waves_total: <N>
  retomada: {docsRoot}/<slug>/INDEX.md + {docsRoot}/<slug>/tasks/TASK-MMM-INDEX.md
  ```

  O `/keelson:implement` cria antes da primeira wave e atualiza `waves_concluidas` a cada final de wave; a Entrega (Etapa 5 do `/keelson:auto`, ou o output final do implement avulso) encerra/remove. O hook `wave-guard` (Stop) lê este arquivo **fora do contexto do modelo** — imune à sumarização — e bloqueia encerramento de turno enquanto `status: em_andamento` (decisões 4.23/4.24). Parada legítima (Entrega feita, degrau 3 com pergunta já disparada, pedido explícito do humano) muda `status:` para `encerrado — <motivo>` antes de encerrar.
- **Resolução de slug.** Dona é a Etapa 0.2 do `/keelson:specify`: reusar slug de domínio existente (inclusive legado — que primeiro migra) antes de criar novo; na dúvida, perguntar ao humano.
- **Merge e deploy são humanos.** Nenhum comando faz merge nem deploy; a promoção de Status (`Draft → Approved → Done`) também é sempre humana.
- **Falha de gate**: 1 retry; persistiu → escalar ao humano com o diagnóstico.

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

Pode fazer até 5 perguntas se houver ambiguidade crítica (contrato externo, falha, segurança, decisão irreversível). Ambiguidade menor vira premissa `[assumido]` — revise-as no output.

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

### 3.4 `/keelson:implement` — executar PLAN

Orquestra a implementação wave por wave, usando subagents (`task-implementer` + `task-reviewer`) ou Agent Teams. Cada task passa pelos quality gates e closure obrigatória antes de Done.

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

Roteamento que ele aplica:

| Natureza da demanda | Resultado |
|---|---|
| Muda o contrato (FR, AC, escopo novo) | Nova SPEC via `/keelson:specify` |
| Contrato igual, estratégia técnica nova | Novo PLAN via `/keelson:plan --slice` |
| Bug (implementação viola um AC) | TASK tipo `bugfix` pré-preenchida |
| Refactor (comportamento idêntico) | TASK tipo `refactor` pré-preenchida |
| Trivial (typo, copy, cor) | Direto no código, sem keelson |
| Slug sem INDEX.md (legado) | Manda rodar `/keelson:migrate-legacy` antes |

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

Conduz `specify → plan → tasks → implement → entrega` de ponta a ponta **sem aprovação de etapa**, simulando "o solicitante pede e vai embora". Abre com a **última chamada**: rodada única de até 4 perguntas críticas (pedido claro → nenhuma) + **espelho do entendimento** — o pedido reescrito de forma estruturada e acessível (formato do prompt refinado do `/keelson:refine`) para o solicitante confirmar; o espelho confirmado **vira a fonte da demanda**. Então anuncia a largada ("Agora, deixa comigo que vou implementar a sua solicitação"). Depois disso, não deixa pergunta pendurada: dificuldade vira decisão registrada ou parte estacionada perguntada em lote na entrega; interrupção no meio só em **último caso** (errar custaria o ciclo inteiro). É o **default**: basta pedir a tarefa em linguagem natural, sem digitar o comando. Governança: decisões 4.10, 4.11, 4.13 e 4.14 de `decisions.md`.

```
/keelson:auto <descrição ou @arquivo> [--slug=<nome>]
```

Rigor proporcional preservado (trivial → direto; bug/refactor → inline; feature → ciclo completo). **Entrega**: branch + commit + push, **sem PR**. Merge e deploy continuam humanos. Governança: decisão 4.10 de `decisions.md`.

**Ambiente sem tela** (worktree/nuvem, ou `gates.screenVerify` sem app disponível): o gate 9 não exercitável gera **handoff de verificação** — doc com roteiro + prompt copy-paste no report para um agente com tela fechar a verificação (ver §8). A entrega é declarada parcial até lá.

### 3.10 `/keelson:guided` — ciclo com checkpoints (opt-in pausado)

O oposto opt-in do `/keelson:auto`: roda o ciclo **pausando em 2 marcos** (SPEC pronta, PLAN pronto) para o seu OK, e com a **régua estrita** de perguntar na hora em qualquer exceção (você está acompanhando — a escada de estacionamento do auto não se aplica). Use quando quer revisar o contrato e o desenho antes do desenvolvimento.

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

Rede de segurança da integração opcional com Jira (via **conector MCP Atlassian**, ligada em `jira.enabled` na ficha). Os comandos do ciclo já sincronizam **best-effort**; quando o conector esteve indisponível ou uma operação falhou, este comando reprocessa o slug e cria/vincula/comenta/transiciona o que ficou para trás, de forma **idempotente**.

```
/keelson:jira-sync <slug ou PLAN-MMM> [--dry-run]
```

| Aspecto | Detalhe |
|---|---|
| Gera | Issues/sub-tasks no Jira (via conector); grava o campo `Jira:` na SPEC e nas TASKs |
| Atualiza | 1 linha no "Histórico recente" do `INDEX.md` (contrato da tabela "PLANs" intocado) |
| Gate | — (best-effort; `jira.enabled:false` ou conector ausente → não faz nada) |
| Lógica | Toda no `skills/_shared/jira-sync-protocol.md` — o comando só orquestra |

Nunca bloqueia o ciclo, não cria PR nem faz merge/deploy. Governança: decisão 4.22 de `decisions.md`.

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

- **ERROR**: bloqueia. SPEC/PLAN não pode ir para `Approved`; TASK com error vira `Blocked` e o `/keelson:implement` não a executa.
- **WARNING**: não bloqueia, mas revise.
- **INFO**: informativo.

Violações triviais (RFC 2119 em minúsculo, zero-padding, acentuação de campo) recebem **auto-fix** sem confirmação. A promoção de Status (`Draft` → `Approved`/`Done`) é sempre **manual**, mesmo com zero errors.

Para passar por cima de um ERROR conscientemente, adicione override no artefato:

```yaml
override-erros: <IDs>
override-justificativa: <texto>
override-aprovador: <nome>
```

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

## 5. Agents (uso interno dos comandos)

Você normalmente não invoca estes diretamente — os comandos os orquestram:

| Agent | Papel | Invocado por |
|---|---|---|
| `task-implementer` | Implementa uma única TASK; não revisa nem fecha | `/keelson:implement` |
| `task-reviewer` | Quality gates de código; gate obrigatório antes da closure; não escreve código | `/keelson:implement` |
| `security-reviewer` | Gate de segurança (`guidelines/core/SECURITY.md` + seção de segurança do perfil ativo), rejeição imediata; em mudança sensível | `/keelson:implement` |
| `task-verifier` | Gate de comportamento verificado (roda testes + exercita a app); em mudança observável | `/keelson:implement` |
| `product-critic` | Crítica de mérito da SPEC; não decide (aprovação é humana) | `/keelson:specify` |
| `process-tuner` | Auto-aprendizado do processo: patch cirúrgico no artefato keelson dono do erro (modo dev do plugin) ou `PROPOSTA_PLUGIN` (projeto consumidor) + ledger `<docsRoot>/_meta/learning-log.md`; anti-inchaço e modo destilação; a doutrina (Charter, hooks, guidelines) só propõe | closure do `/keelson:implement`, `/keelson:auto`, sob demanda |

---

## 6. Artefatos e IDs

```
<docsRoot>/                    # docsRoot da ficha; "docs/" por padrão
├── _meta/
│   ├── decisions.md           # governança do processo
│   ├── method-guide.md        # este guia
│   └── learning-log.md        # ledger do auto-aprendizado (mantido pelo process-tuner)
└── <slug>/
    ├── INDEX.md               # estado atual (GERADO — não editar)
    ├── specs/SPEC-NNN-*.md
    ├── plans/PLAN-MMM-*.md
    ├── tasks/
    │   ├── TASK-MMM-INDEX.md
    │   └── TASK-MMM-XXX-*.md
    ├── handoffs/HANDOFF-*.md  # verificação de tela pendente (ver §8; vazio na maioria dos slugs)
    └── legacy/                # docs pré-migração (quando aplicável)
```

| ID | Significado | Escopo da numeração |
|---|---|---|
| `FR-NNN-XXX` / `NFR-NNN-XXX` | Requisito funcional / não-funcional | NNN = nº da SPEC |
| `AC-NNN-XXX` | Critério de aceitação (Given-When-Then) | NNN = nº da SPEC |
| `RISK-NNN-XXX` / `A-NNN-XXX` / `Q-NNN-XXX` | Risco / premissa / questão aberta | NNN = nº da SPEC |
| `COMP-MMM-XXX` | Componente | MMM = nº do PLAN |
| `DEC-MMM-XXX` | Decisão arquitetural (com alternativas e flag `Irreversível`) | MMM = nº do PLAN |
| `TRISK-MMM-XXX` | Risco técnico | MMM = nº do PLAN |
| `TASK-MMM-XXX` | Tarefa | MMM = PLAN ao qual pertence |

Nomes de arquivo de TASK por tipo: `-fix-` (bugfix), `-refactor-` (refactor), `-chore-` (chore); sem sufixo = feature.

### Contrato da tabela "PLANs" do INDEX (fonte única)

Todo escritor do INDEX (`/keelson:specify`, `/keelson:plan`, `/keelson:tasks`, `/keelson:implement`, `/keelson:rebuild-index`) usa **exatamente** este formato — nenhum comando redefine header ou célula por conta própria:

```markdown
| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|
| PLAN-MMM | SPEC-NNN | <resumo curto> | X/Y M | <Status> |
```

- **Header**: as 5 colunas acima, nesta ordem. O `/keelson:specify` já cria a seção "## PLANs" com o header (tabela vazia); quem adiciona a primeira linha **não** inventa header.
- **Célula `Tasks`** = `X/Y M`: `X` tasks Done, `Y` total (`?` até o `/keelson:tasks` rodar), `M` marcador — `⏸` (nenhuma Done), `🟡` (parcial), `✅` (todas Done). Progressão: `0/? ⏸` (plan) → `0/N ⏸` (tasks) → `X/N 🟡` (implement, closure por task) → `N/N ✅` (última closure).
- **Coluna `Status`** = o Status do front-matter do arquivo PLAN, **verbatim** (`Draft | Review | Approved | Done`), com um único sufixo permitido: `Done (sugerido)`, escrito pelo `/keelson:implement` quando a DoD está satisfeita mas a promoção humana ainda não aconteceu. O "status efetivo" que o `/keelson:rebuild-index` calcula serve **só** para posicionar a capacidade na seção "Capacidades" — nunca entra nesta coluna.

### Template canônico do INDEX.md (fonte única)

Todo comando que **cria** um INDEX (`/keelson:specify` na 1ª SPEC, `/keelson:rebuild-index`, `/keelson:migrate-legacy`) usa este esqueleto — nenhum comando redefine seções por conta própria:

```markdown
# <Nome do slug em formato título>

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.

**Slug**: <slug>
**Última atualização**: <ISO 8601 com timezone>

## Resumo
<2 a 3 linhas derivadas dos outcomes das SPECs — ou do legado, na migração>

## Capacidades

### Implementadas
- <capacidade> (SPEC-NNN, PLAN-MMM, ✅ <data>)

### Em desenvolvimento
- <capacidade> (SPEC-NNN, PLAN-MMM, 🟡 X/Y tasks Done)

### Especificadas, ainda não planejadas
- <outcome> (SPEC-NNN, ⏸ aguardando /keelson:plan)

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|

## Decisões irreversíveis

- **DEC-MMM-XXX** (PLAN-MMM): <texto curto>

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|

## Histórico recente

- <YYYY-MM-DD HH:MM>: <ação> via /keelson:<comando>
```

Seção ainda sem conteúdo leva nota curta do que a preenche (ex.: "(vazio até /keelson:plan)"). Variações por comando:

- **`/keelson:rebuild-index`**: acrescenta ao aviso a linha `> Última reconstrução completa via /keelson:rebuild-index: <ISO 8601>` e, se houver, a seção final `## Inconsistências conhecidas` (descrição + ação sugerida).
- **`/keelson:migrate-legacy`**: acrescenta `**Origem**: migrado de legado em <YYYY-MM-DD> via /keelson:migrate-legacy`; capacidades legadas entram em `### Implementadas (legado, sem rastreabilidade SDD)` com marcador 📜 e origem (`legacy/<arquivo>`); decisões extraídas viram `LEGACY-DEC-*`; "SPECs"/"PLANs" ficam vazios com nota de que não há artefatos retroativos; seção extra `## Documentação legada` lista os arquivos preservados.
- **Slug migrado** (em qualquer rebuild): as seções espelhadas do legado abrem com `> Fonte durável: legacy/TRIAGE-<data>.md` — é do TRIAGE que o rebuild as reespelha.

### Receita de atualização do INDEX (fonte única)

Todo comando que **atualiza** um INDEX existente aplica — mesclando, nunca sobrescrevendo:

1. Atualizar `Última atualização`.
2. Refletir o artefato na tabela correspondente (SPECs/PLANs — contrato acima) e nas seções que ele afeta: capacidades (movendo entre "Especificadas" → "Em desenvolvimento" → "Implementadas" conforme o ciclo), glossário (termo já existente com definição diferente → **parar e reportar conflito**), decisões irreversíveis, riscos ativos.
3. Adicionar entrada ao "Histórico recente" com timestamp e ação — **máximo 10 entradas**.

---

## 7. Regras de ouro

1. **INDEX.md é gerado** — nunca edite. Errou? `/keelson:rebuild-index <slug>`.
2. **SPEC não fala de tecnologia.** Linguagem, framework, banco, protocolo etc. só entram no PLAN.
3. **Promoção de Status é manual.** Validators bloqueiam errors, mas quem promove `Draft → Approved → Done` é você, no front-matter do artefato.
4. **Closure é inegociável.** Task sem "Histórico de execução" preenchido não é Done, mesmo com código pronto.
5. **Trivial pula o ciclo.** Typo, copy, cor: commit direto no padrão do perfil ativo.
6. **Legado primeiro migra, depois muda.** Slug sem INDEX.md → `/keelson:migrate-legacy` antes de qualquer `/keelson:triage`.
7. **Na dúvida, `/keelson:triage`.** Ele classifica a demanda e te dá o comando pronto.
8. **Entrega sem tela não silencia o gate 9.** Ambiente sem acesso a testes de tela → **handoff de verificação** obrigatório (ver §8); a entrega é declarada parcial até o handoff ser fechado.

---

## 8. Handoff de verificação de tela (gate de comportamento remoto)

Quando o ciclo roda num ambiente **sem acesso a testes de tela** — worktree sem app/browser, execução na nuvem, containers indisponíveis — o gate de comportamento verificado não consegue exercitar a UI. Nesses casos a entrega **não engole o furo**: ela produz um **handoff de verificação** — documento com roteiro passo a passo e riscos + **prompt pronto** para um agente com acesso a tela fechar a verificação depois. O handoff é a diferença entre "não verifiquei e ninguém sabe" e "não verifiquei, e aqui está exatamente o que falta, como exercitar e o que está em risco".

> Aplica-se a projetos cuja ficha declara `gates.screenVerify: true` (têm superfície visual a verificar). Onde não há tela, o gate se satisfaz por teste/execução sem UI e não há handoff.

### 8.1 Ciclo de vida

1. **Detecção**: na rota formal, o `task-verifier` reporta `PARCIAL` com o bloco `handoff_seed` (o roteiro do que ele não conseguiu exercitar). Na rota inline (bug/refactor), a auto-revisão do gate pela main session detecta o mesmo. **Indisponibilidade de ambiente é provada, não presumida** (decisão 4.26): antes de declarar, roda-se uma **sondagem barata** — o `keelson.local.json` existe e tem os dados do(s) realm(s) envolvido(s)? a `baseUrl` do realm responde (ou a app sobe pelo método do projeto)? a sessão tem ferramenta de tela? — e a **evidência da sondagem que falhou** (o que foi tentado, o que retornou) acompanha a seed e entra no front-matter do handoff (`sonda:`). Projeto multi-realm: sonda **por realm** do roteiro — um realm de pé e outro não gera pendência só para o indisponível. Declarar "ambiente sem tela" sem sondagem registrada é usar o handoff como atalho — proibido.
2. **Geração** (preparação da Entrega): a main session consolida as seeds e cria `<docsRoot>/<slug>/handoffs/HANDOFF-<id>.md` — `<id>` = `PLAN-MMM` na rota formal; `<yyyy-mm-dd>-<descrição-curta>` na inline. Um doc por entrega (consolida todas as tasks do PLAN). Registra **risco ativo** no INDEX do slug: `Verificação de tela pendente — HANDOFF-<id>`. Domínio **sem slug keelson** → não cria arquivo: o roteiro completo vai inline no prompt do report da Entrega.
3. **Entrega**: o handoff entra no commit da branch e o report final traz a seção **"Verificação pendente (handoff)"** com o prompt copy-paste. A entrega é declarada **parcial** — nunca "totalmente verificada" — enquanto houver handoff `Pendente`.
4. **Fechamento** (num ambiente com tela): o agente que recebe o prompt faz checkout da branch, lê o handoff, exercita cada item com a rotina de verificação de tela do projeto, registra a evidência no próprio doc, corrige divergências na própria branch (protocolo inline) e faz a closure — `status: Concluído`, risco removido do INDEX + linha no Histórico recente, commit `chore(<slug>): close verification handoff HANDOFF-<id>`, push. Merge e deploy continuam humanos.

O `/keelson:integrate` detecta handoffs `Pendente` do slug e os destaca na descrição do PR — mergear com verificação pendente passa a ser decisão consciente do humano, nunca desinformada.

### 8.2 Template canônico do handoff

```markdown
---
id: HANDOFF-<id>
slug: <slug>
branch: <branch>
status: Pendente               # Pendente | Concluído
criado: <ISO 8601>
origem: PLAN-MMM | inline
commits: [<SHAs curtos>]
motivo: <ambiente sem acesso a testes de tela — worktree | nuvem | containers down>
sonda: <evidência da sondagem de disponibilidade que falhou, por realm — o que foi tentado e o que retornou>
---

# Handoff de verificação de tela — <título curto>

## 1. Contexto da entrega
<2–5 linhas: o que foi entregue e por quê; refs SPEC-NNN / PLAN-MMM / TASKs.>

## 2. Já verificado (não repetir)
- Testes: <suíte/comando (quality.test da ficha), N/N>
- Lint/type-check: <resultado (quality.lint / quality.typecheck)>
- API exercitada sem tela: <chamadas feitas e resultados, ou "nenhuma">

## 3. Pré-requisitos de ambiente
- Subir app + login: <como subir a app deste projeto e autenticar; pegadinhas de permissão>
- Migrações/seeds pendentes DESTA branch: <lista com comandos, ou "nenhuma">
- Feature flags / permissões necessárias: <lista, ou "nenhuma">
- Dados de teste: <como obter/criar o estado necessário>

## 4. Roteiro de verificação (itens pendentes)

### V1 — <título> (<AC-NNN-XXX ou "inline: <comportamento>">)
- **Tela/rota**: <URL/rota da app>
- **Realm**: <nome em `screenVerify.realms` do `keelson.local.json` — omitir se o projeto tem um só>
- **Passos**: 1) … 2) … 3) …
- **Esperado**: <comportamento observável, específico o bastante para dar ✅/❌>
- **Risco se falhar**: <impacto para o usuário/negócio>
- **Evidência**: _(preencher na verificação)_

### V2 — …

## 5. Riscos e pontos de atenção
<O que o implementador sabe que é frágil e a tela pode revelar: tema claro/escuro, estados
vazios/erro, permissões, responsividade, interação com dados reais, timing.>

## 6. Protocolo de conclusão
1. Exercitar cada item V* e preencher a Evidência (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch (protocolo inline: escopo restrito + testes +
   gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar INDEX do slug (remover o
   risco ativo + linha no Histórico recente); commit
   `chore(<slug>): close verification handoff HANDOFF-<id>`; push.
4. Merge e deploy continuam decisão humana.
```

**Regras do roteiro (seção 4)**: cada item deve ser executável por quem **não participou da implementação** — sem "verifique se está ok"; passos concretos, dados concretos, resultado esperado observável. Cada AC observável não exercitado vira um item V*; fluxos de risco conhecido (tema escuro, estado vazio, permissão negada) entram mesmo sem AC formal quando o implementador sabe que são frágeis.

### 8.3 Prompt canônico (emitido no report da Entrega)

```text
Você está num ambiente com acesso a testes de tela (app local + browser). Sua tarefa é
fechar a verificação de comportamento (gate de comportamento verificado) de uma entrega
feita em ambiente sem tela.

1. `git fetch && git checkout <branch>` (e `git pull` se a branch já existir localmente).
2. Leia `<docsRoot>/<slug>/handoffs/HANDOFF-<id>.md` — ele é a FONTE DA VERDADE desta tarefa:
   pré-requisitos de ambiente (§3), roteiro passo a passo (§4), riscos (§5) e protocolo
   de conclusão (§6). Consulte também SPEC/PLAN referenciados nele se precisar de contexto.
3. Suba o ambiente e exercite CADA item pendente do roteiro com a rotina de verificação
   de tela do projeto; registre a evidência item a item no próprio doc.
4. Divergência → corrija na própria branch (protocolo inline) e re-exercite.
5. Tudo verde → siga o protocolo de conclusão do doc (status, INDEX, commit, push).
Não faça merge nem deploy — isso continua decisão humana.
```

(Domínio sem slug: substitua o passo 2 pelo roteiro inline incluído abaixo do prompt.)
