# keelson — repo de desenvolvimento do plugin

Este repositório **é** o plugin (a raiz é o pacote). Não é um projeto consumidor — aqui se desenvolve
o keelson; a doutrina que os consumidores recebem vive em `guidelines/` e o bloco
injetado neles em `templates/CLAUDE.keelson-block.md`.

## Antes de qualquer alteração — análise de efeito colateral (decisão 4.181)

- Toda alteração solicitada — código, doutrina, comando, agent, skill, script, hook ou
  doc — começa **mapeando o raio de impacto antes de editar**: quem referencia ou
  consome o artefato (dono único da regra, comandos/agents que o citam, scripts e CI
  que o leem, consumidores via `/keelson:update`) e qual comportamento atual funciona
  e depende do que vai mudar. `grep` pelo nome/heading do artefato é o mínimo; mudança
  que toca mais de um artefato → delegue o mapa ao `impact-scout` (seção *Ferramentas
  do mantenedor*).
- O teste é falsificável: **nomeie o que poderia quebrar e prove por que não quebra** —
  "nada quebra" sem verificação não é resposta. Prova preferida é mecânica: rode a
  guarda que cobre a área tocada (`check-sync.sh`, `check-release.sh`, suíte do grafo,
  `bash -n`, suítes de `scripts/tests/`) em vez de argumentar.
- **Risco identificado viaja com mitigação sugerida** (decisão 4.188): como reduzir ou
  anular — guarda a rodar, ordem de aplicação, fallback, teste a acrescentar. "Sem
  mitigação conhecida" é resposta válida e obrigatória, com o porquê — omitir o risco
  por não ter solução é o defeito, não tê-la.
- Efeito colateral que muda resultado ou escopo do pedido → sinalize ao Diretor
  **antes** de aplicar, com proposta + default (mesmo contrato de escalação do PO) —
  a mitigação sugerida é a proposta. **Risco sem mitigação conhecida sobe sempre ao
  Diretor**, mude escopo ou não. Os demais entram na entrega: efeitos considerados,
  mitigação e por que foram descartados — descartar em silêncio é o mesmo defeito de
  contornar furo de plano em silêncio.

## Ferramentas do mantenedor (`.claude/` do repo — decisão 4.182)

- `.claude/agents/` e `.claude/skills/` **versionados** são tooling do desenvolvimento
  do keelson, fora do pacote: o loader do plugin e o `check-sync.sh` leem só a raiz
  (`agents/`, `commands/`, `skills/`). Mudança aqui não bumpa versão nem entra no
  `CHANGELOG.md` — mas ganha decisão §4.x quando muda o processo.
- Roteamento (o quê/como de cada ferramenta vive no frontmatter dela — não duplique aqui):
  **`impact-scout`** (agent) → mapa de impacto da 4.181; delegue quando a mudança tocar
  mais de um artefato ou o raio não for óbvio, lookup de um grep fica inline ·
  **`/field-intake`** (skill) → chegou insumo de campo de consumidor; o gatilho tem
  cutucada mecânica: hook `.claude/hooks/field-intake-nudge.sh` via `.claude/settings.json`
  (4.270 — lembrete 1×/sessão em prompt com marcador de campo, nunca gate) ·
  **`/idea-forge`** (skill, 4.222) → Diretor trouxe ideia crua de melhoria do keelson;
  refina por perguntas, conecta com decisões/doutrina existentes e devolve mini-brief
  julgado (report-only; insumo de consumidor continua indo ao `/field-intake`) ·
  **`/harness-audit`** (skill, 4.209) → Diretor pediu auditoria/poda da doutrina
  (fato mecânico: `scripts/check-refs.sh`; report-only, aplicar é leva própria com 4.181) ·
  **`/skill-standards`** (skill, 4.212) → skill/comando/agent criado ou editado, ou pedido
  de verificação de boas práticas de autoria (régua = digest re-buscável da doc Anthropic);
  o gatilho tem cutucada mecânica: hook `.claude/hooks/skill-standards-nudge.sh` via
  `.claude/settings.json` (4.213 — lembrete 1×/arquivo/sessão, nunca gate) ·
  **`/pr-review`** (skill, 4.267) → chegou PR no repositório; parecer com a régua de leva
  interna e veredito mergear direto (escada 4.268 completa) / absorver / parcial / recusar —
  default é absorção com crédito (4.263). O registro da chegada continua com o
  `/field-intake` (PR é insumo de campo com código junto); a face pública da rota para o
  contribuidor é o `CONTRIBUTING.md` ·
  **`evals/` + `scripts/eval-run.sh`** (camada de evals de comportamento, 4.304) → medir
  o efeito de mudança de doutrina em caso controlado A/B (braços `git:<ref>`/`file:`,
  n≥2, plant 4.186); veredito **consultivo** — HOLD em divergência, plant aprovado
  invalida a rodada; roda sob demanda do Diretor ou pré-leva de classe coberta, nunca em
  pre-commit/CI; casos no formato `claude plugin eval`, o runner só orquestra.
- Adiado com gatilho (4.182): `doctrine-reviewer` (reincidência de defeito de conteúdo
  de doutrina que os checks de sincronia não pegam).

## Versionamento

- **Versão do plugin** vive em **3 lugares, sempre sincronizados**:
  `.claude-plugin/plugin.json` · `.claude-plugin/marketplace.json` (`metadata.version`) ·
  seção *Status* do `README.md`.
- Regra (0.x): capacidade nova ou quebra (comando novo, rename, doutrina nova) → **minor**;
  correção/ajuste fino → **patch**. Bump uma vez por leva de release, não por commit.
- **Bump sem entrada no `CHANGELOG.md` é release incompleto** (decisão 4.48 — provado
  mecanicamente por `scripts/check-release.sh` no pre-commit e no CI, 4.83): a mesma leva
  que mexe nos 3 lugares escreve a entrada. Formato: `## [X.Y.Z] — AAAA-MM-DD`, linha
  `Re-init: required|none` logo abaixo do heading (4.189: `required` = a entrada mudou o
  bloco injetado ou o contrato da ficha; é o que `scripts/update.sh` lê para avisar o
  consumidor — provado por `check-release.sh` na entrada corrente), linha de
  âncora (`Decisão 4.x · <hash do commit de bump>`; `Charter A.B.C` quando ele mudou) e
  bullets sob `Added` / `Changed` / `Fixed` / `Removed`, em **inglês** (é a face pública do
  pacote, como o `README.md`). Escreva pelo efeito no consumidor — o *porquê* fica na
  decisão, a uma referência de distância. O `Status` do README traz só a manchete atual e
  aponta para o CHANGELOG; não volta a acumular prosa histórica.
- **A leva de release passa pela wiki** (4.81): junto com a entrada do `CHANGELOG.md`,
  aplique o gatilho de página própria da seção *Wiki*. Publicar é automático — o que a
  leva revisa é o **conteúdo**, não o ato de subir.
- **Charter é versionado à parte** (`guidelines/_meta/QUALITY-CHARTER.md`): só muda quando
  os artigos mudam; cada perfil referencia a versão no frontmatter `charter:`.
- **O critério de pacote é quem lê, não onde mora** (decisão 4.194): arquivo que
  comandos/agents/skills leem em runtime no consumidor — todo o `docs/_meta/conventions/`,
  via `${CLAUDE_PLUGIN_ROOT}` — é conteúdo embarcado: mudança nele entra no `CHANGELOG.md`
  e conta para o bump. `decisions.md`, `learning-log.md`, `proposal-inbox.md` e
  `method-guide.md` continuam registro do mantenedor, sem bump.
- **Sessões paralelas colidem em §4.x e versão** (caso real: duas "4.60" no mesmo dia —
  decisão 4.63): antes de numerar decisão ou bumpar, `git fetch` e confira o topo da main.
  O hook `scripts/git-hooks/pre-commit` bloqueia commit na `main` atrás do `origin/main`
  **e roda a guarda de qualidade** (4.83: `bash -n` nos scripts staged; suíte do grafo
  quando o motor muda; `check-release.sh` quando versão/CHANGELOG/wiki mudam;
  `check-sync.sh` quando comando/agent/README/method-guide mudam, 4.147) — ative
  uma vez por clone: `git config core.hooksPath scripts/git-hooks`. O CI (`test.yml`)
  repete o conjunto em Linux a cada push/PR.

## Ao mudar comando ou doutrina

- Comando novo/renomeado → sincronizar **3 lugares**: `commands/*.md` · tabela *Commands*
  do `README.md` · §3.x do `docs/_meta/method-guide.md`. Comando humano-only
  (`disable-model-invocation`) → também a nota do `templates/CLAUDE.keelson-block.md`.
  Continuam **3** — a página da wiki é derivada do method-guide (4.81); não escreva a
  quarta cópia. **Provado mecanicamente** por `scripts/check-sync.sh` (pre-commit + CI,
  decisão 4.147): linha do README, marcador `†` ⇔ flag, nota do bloco e (AVISO) seção
  do method-guide.
- Agent novo/renomeado → sincronizar: `agents/*.md` (arquivo + `name:` + `# Subagent:`) ·
  tabela §5 do `method-guide.md` · comentário de `agents/` no `README.md` · §2/§3 do
  `decisions.md` (convenção de nomes) — e a description declara **todos** os invocadores.
  A parte mecânica (arquivo/`name:`/heading/tabela §5, ambos os sentidos) também é
  provada pelo `check-sync.sh`; comentário do README e decisions.md seguem humanos.
- **Um dono por regra**: o core (`guidelines/core/`) diz *o quê* (agnóstico); o perfil diz
  *como* na linguagem. Não duplicar regra entre eles. Blocos compartilhados dos comandos
  têm dono único em `docs/_meta/conventions/` (13 arquivos; o cabeçalho de cada um
  declara o dono): `sdd-conventions.md` (convenções comuns, ex-§3.0),
  `index-contract.md` (artefatos/IDs + contrato/template/receita do INDEX, ex-§6),
  `handoff-protocol.md` (handoff de verificação de tela, ex-§8), `commit-convention.md`
  (tipo/escopo/quebra da mensagem de commit no consumidor — o bloco de keys do tracker
  continua no §15 do protocolo Jira), `graph-contract.md` (sintaxe canônica de aresta,
  catálogo de arestas/checks do grafo e contrato do `scripts/graph.sh` — decisão 4.82),
  `report-contract.md` (esqueleto canônico do relatório de fecho — Entrega do auto,
  modo sob demanda e `/keelson:report` — decisão 4.130), `lint-contract.md` (checks,
  regex e severidades do `scripts/artifact-lint.sh`), `map-contract.md` (MAP do slug —
  decisão 4.104), `estimate-contract.md` (contrato da estimativa — decisão 4.223),
  `production-intake-protocol.md` (entrada de bug/incidente de produção — decisão 4.101),
  `value-test-protocol.md` (menor teste de valor — decisão 4.100), `agent-teams.md`
  (especificidades do modo teams — decisão 4.292) e `warroom-contract.md` (janela sem
  gate bloqueante + contrato do `DEBT.md` — decisão 4.372);
  o `method-guide.md`
  segue guia humano, com os headings §3.0/§6/§8 preservados como ponteiros. A moldura dos
  validators vive em `skills/_shared/validator-protocol.md`; a **régua dos gates 1–7**
  (o que cada gate exige, degradação sem artefato SDD, calibração de severidade) tem dono
  único em `guidelines/core/CODE-REVIEW.md`, executada sempre pelo `code-reviewer` —
  no ciclo (`/keelson:implement`) e em diff avulso (`/keelson:review`, decisão 4.36); o `security-engineer` **lê** o
  checklist de `guidelines/core/SECURITY.md` em runtime, não o replica (decisão 4.20) —
  mudou a regra, mude no dono, nunca copie no consumidor.
- Perfil com `reviewed: true` (ex.: `backend/php.md`) é revisado por humano: edição nele
  deve ser sinalizada na entrega para re-olhada humana.

## Modelo de time e contrato do Diretor (decisões 4.37–4.41 — dono do detalhe: `docs/_meta/decisions.md`)

- O keelson simula um **time real** — desde a 4.40, os IDs dos agents **são** os nomes
  dos papéis. Elenco: **Diretor** = humano · **Tech Lead** = main session · agents
  `po` (dono da demanda) · `pm` (decompõe épico — nunca abaixo do PO; 4.39) ·
  `developer` · `code-reviewer` · `qa` · `security-engineer` · `performance-engineer`
  (gate 10, 4.155) · `product-designer` (gate 11, 4.218) · `product-analyst` (sob o PO) ·
  `agile-coach` · `staff-engineer`. Ficam **fora da metáfora** (ferramentas do time, não
  pessoas): os validators, `scribe` e `tracker-sync` (4.103), `code-scout` (4.73) e
  `estimator` (4.223). Histórico (decisions.md, learning-log.md) e
  `generated-by:` de perfis gerados mantêm os IDs antigos — de-para na 4.40.
- **Contrato Diretor–PO**: o Diretor emite intenção (**brief**, artefato-âncora), não
  aprova artefatos de rotina. O PO valida tudo **contra o brief** (nunca contra a própria
  opinião), devolve a interpretação em ~5 linhas e segue **sem esperar** (janela de veto);
  escala por exceção (ambiguidade que muda o resultado · expansão/conflito de escopo ·
  ação irreversível/externa · conflito com diretriz anterior), sempre com proposta +
  default; registra **decisões tomadas em nome do Diretor**; entrega **relatório de
  aceitação** (alinhamento ao brief ≠ QA, que prova que funciona).
- **A autonomia termina nos commits**: PR, merge para a branch principal e deploy são
  atos do Diretor (pode haver outras sessões na mesma base). Exceção declarada (4.263):
  `/keelson:merge`, humano-only, mescla branches para dentro da branch de trabalho
  corrente — o dono da regra é o `sdd-conventions.md`.
- **Sinais laterais com contrato** (gatilho + rota + registro): furo no plano
  (Developer → Tech Lead; contornar em silêncio é violação de gate) · cenário ambíguo
  pré-código (QA → PO) · achado fora de escopo (Reviewer/QA → Tech Lead) · escalação e
  aceitação (PO → Diretor). Boletim entre waves narrado em linguagem de time, fechando
  com o estado de pendência do Diretor.

## Wiki (documentação de usuário — decisão 4.81)

- A **wiki do GitHub é artefato gerado, nunca fonte**. Fonte = `docs/wiki/` (páginas
  próprias de onboarding) + os **espelhos** listados no manifesto `MIRRORS` de
  `scripts/publish-wiki.sh` (method-guide, Charter, convenções). Regra de corte:
  **texto que já tem dono é espelhado, nunca reescrito** — página própria só para o que
  não existe em lugar nenhum. A wiki **não** é um 4º lugar a sincronizar: comando novo
  continua em `commands/*.md` + `README.md` + `method-guide.md`, e a página é derivada.
- **Página própria fala com quem chegou agora** (decisão 4.247): o leitor-alvo é quem
  começou a usar o keelson recentemente — linguagem simples, sem pressupor vocabulário
  interno (número de decisão §4.x fica fora do texto; conceito citado linka a página
  que o explica). Fluxo ou decisão com ramificação ganha diagrama ` ```mermaid ` junto
  do texto quando facilitar o entendimento — o GitHub renderiza mermaid na wiki.
  Aspas dentro de rótulo mermaid → aspas simples (`'…'`) — entidade `&quot;` quebra o
  parser do GitHub (caso real, 784ba51). Todo bloco da superfície publicada é provado
  por `scripts/check-mermaid.sh` (4.248) no pre-commit e no CI — lint offline da
  classe + render real; sem rede degrada com aviso e o CI é o veredito.
  A régua vale para página própria; espelho segue o texto do dono, intocado.
- **Espelho anda sozinho; página própria tem gatilho.** Mexeu em `method-guide`, Charter
  ou convenção → a wiki acompanha no push, sem ação nenhuma. O que exige olhar é a página
  própria, e o teste é um só: **o que o consumidor faz mudou?** — campo novo na ficha →
  `Ficha-do-projeto.md` · comando ou gate com efeito no uso → `Primeiros-passos.md`,
  `Conceitos.md`, `Perguntas-frequentes.md` · falha nova que dá para reconhecer →
  `Solucao-de-problemas.md`. *Nada a mudar* é resposta válida; não olhar, não.
- **Publicar não é passo de release.** A Action republica sozinha no push da `main` que
  toca as fontes — não existe "subir a wiki" na leva. Action vermelha (ou pressa) →
  `scripts/publish-wiki.sh` à mão; `--dry-run` mostra antes, `--check` sai 1 se a wiki
  publicada está atrasada.
- Publicação: `scripts/publish-wiki.sh` (bash 3.2) e a Action
  `.github/workflows/publish-wiki.yml`. Página nova → só criar o `.md`
  em `docs/wiki/` e linkar no `_Sidebar.md`; espelho novo → uma linha em `MIRRORS`.
- Wiki em **português** (é o idioma da doutrina); o `README.md` segue a face em inglês.
  Edição pela UI do GitHub é sobrescrita — o script só remove páginas que ele gerou
  (`.keelson-wiki-pages`), então página feita à mão sobrevive.

## Grafo dos artefatos (fato mecânico — decisão 4.82)

- **O markdown é a fonte; o grafo é derivado** (mesmo princípio da wiki). As relações
  entre artefatos SDD (dependências, cobertura, waves, FEATs) são extraídas e
  verificadas por `scripts/graph.sh` (bash 3.2 + awk POSIX, read-only); a régua —
  sintaxe canônica de aresta, catálogo de checks com severidades e carências
  `[legacy]`/`[parse]`, contrato de invocação/saída — tem dono único em
  `docs/_meta/conventions/graph-contract.md`. Validators **citam a saída como fato**
  e não re-derivam estrutura; a calibração continua deles.
- **Mexeu no parser ou no catálogo → a suíte roda sozinha** no pre-commit e no CI
  (4.83); durante o desenvolvimento, itere com `scripts/tests/graph/run.sh` (fixtures
  sintéticas com defeitos plantados + saídas esperadas congeladas). Check novo não
  entra no catálogo sem fixture; mudança de severidade é decisão explícita (§4.x),
  nunca efeito colateral do script.
- Falso-positivo num artefato legítimo é o pior defeito desta camada: na dúvida, o
  extrator degrada com `WARNING nao-parseavel` (e os checks de ausência degradam
  junto) — nunca inventa ERROR.

## Registro e governança

- Decisão de processo/governança → entrada numerada em `docs/_meta/decisions.md` (§4.x,
  formato Problema/Decisão/Aplicação). Lição de processo → `learning-log.md` via
  `agile-coach`.
- **Insumo de consumidor real se abstrai antes de virar registro** (decisão 4.72):
  postmortems, propostas e relatos de campo chegam com identificadores do projeto —
  nome, slug de demanda, paths, globs, URLs, nomes de chave. Nada disso entra em
  doutrina, `decisions.md` ou `CHANGELOG.md`: extraia o **padrão genérico** que ensina
  (ex.: "globs cobriam os `.env*` de subdiretórios, não o `.env` da raiz") e deixe o
  literal no consumidor (ficha/docs dele). Teste antes de registrar: a frase funciona
  para qualquer projeto? Se só faz sentido conhecendo aquele consumidor, ainda é
  específica demais.
- **Proposta de consumidor tem fila no mantenedor** (decisão 4.111): `PROPOSTA_PLUGIN`
  que chega (postmortem, ledger, mensagem) é registrada em `docs/_meta/proposal-inbox.md`
  **antes do parecer** e fechada na leva que a aplica/recusa/adia (`aplicada (4.x)` /
  `recusada (motivo)` / `adiada (gatilho)` — esta é o **default** da proposta só-de-texto em
  1ª ocorrência sem prova, decisão 4.371; contrato no cabeçalho da fila). Nada entra em
  doutrina sem passar pela fila; reincidência
  referencia a linha anterior.
- **Poda de doutrina tem régua** (decisão 4.160): em leva de destilação/refino de
  comando, agent ou skill, cada frase passa por três testes — **no-op** (muda o
  comportamento vs. o default do modelo? não → deletar a frase inteira, nunca só
  encurtá-la), **sedimento** (ainda corresponde ao comportamento/mundo atual?) e
  **leading word** (definição de três frases que um conceito do pretraining carrega num
  token colapsa nele). Proibição que couber como alvo positivo é reescrita positiva.
- Hooks são bash 3.2-compatível com **fallback gracioso** (sem `jq`/ficha → `exit 0`,
  nunca travar o fluxo) e anti-renudge por fingerprint. Validar com `bash -n` + teste
  sintético (repo temporário no scratchpad).

## Convenções

- Commits: conventional commits **em inglês** (`feat(scope): …`), referenciando a
  decisão quando houver (ex.: `(4.16)`).
- Docs e doutrina em **português**; a face pública do repo — `README.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md` — em **inglês** (4.267).
