# AI-Native SDLC — playbook da Anthropic × keelson

> **Registro do mantenedor** (fora do pacote — mesma classe de `decisions.md` e
> `learning-log.md`: não bumpa versão, não entra no `CHANGELOG.md`, não é espelhado na wiki).
> Base de referência para evoluções futuras do keelson. **Não é doutrina**: nada daqui vale
> no consumidor até passar por leva própria com a régua de sempre (4.181 impacto → 4.420
> "a regra mora onde é verificável" → eval quando a mudança é de comportamento).

- **Fonte:** *The AI-Native SDLC playbook* — Anthropic (Applied AI), autor Louis Claxton,
  publicado em 2026-08-21. <https://claude.com/blog/the-ai-native-sdlc-playbook>
- **Lido em:** 2026-09-22, contra o keelson **v0.175.0** (HEAD `f178fc0`).
- **Forma deste documento:** síntese em português, com as palavras do mantenedor — não é
  tradução nem transcrição. Os exemplos do artigo (templates, YAML, JSON, scripts) estão
  **descritos**, não copiados; para o texto literal, vá à fonte.
- **Leitura anterior relacionada:** o parecer do `/idea-forge` de 2026-09-21 concluiu que o
  `intent.md` do playbook é subconjunto do BRIEF forjado; resultado publicado como tabela de
  correspondência em `docs/wiki/Conceitos.md` (commit `f178fc0`).

## Como usar este documento

1. **Antes de abrir leva inspirada no playbook**, procure o play na §4 (tabela) e o
   candidato na §6 (backlog). Se o status for ⊘, a divergência é **decisão registrada** —
   reabrir exige nova decisão §4.x que cite a anterior, nunca efeito colateral.
2. **Candidato vira leva** pelo caminho de sempre: `/idea-forge` (mini-brief julgado) →
   mapa de impacto (`impact-scout`) → prova (eval/suíte) → decisão §4.x.
3. **Ao fechar uma leva** que mexe num item daqui, atualize o status na §4 e a linha na §6
   (com o número da decisão). Este documento só é útil enquanto reflete o keelson atual.
4. **Nova versão do playbook** (a Anthropic atualiza posts): releia a fonte, registre a data
   da releitura no cabeçalho e marque na §3 o que mudou.

---

## 1. A tese do playbook

**O código deixou de ser o gargalo.** Agentes escrevem código numa velocidade que o processo
em volta não acompanha: aprovações, reviews, handoffs e políticas ainda foram desenhados para
uma era em que *implementar* era a fase cara. Artefatos como PRD, rituais de estimativa e
revisões de segurança de produto existiam para forçar alinhamento antes de semanas ou meses
de construção — esse custo sumiu, o ritual ficou.

Quando o build encolhe para horas, três coisas passam a valer:

1. **O gargalo migra para as bordas do build** — planejar, revisar/testar e implantar seguem
   em velocidade humana.
2. **Os controles deixam de casar com a realidade** — revisar linha a linha fazia sentido com
   diff humano; não escala quando o agente escreve a maior parte dele.
3. **A governança encarece** — exceção continua roteada por comitês de cadência semanal ou
   mensal.

Exemplo do artigo: times de segurança são dimensionados para produção humana; com agentes
multiplicando o volume, ou a fila de review cresce ou o código sai sub-revisado — nenhuma das
duas é aceitável em organização regulada. Logo, os controles precisam andar na velocidade do
agente.

**Proposta:** manter os **objetivos de controle** do SDLC tradicional, trocar a **forma de
aplicá-los**. O fluxo linear vira **loop**, com IA embutida em cada ponto e **handoff
automático** entre estágios. Nomes equivalentes usados no mercado: *agentic SDLC*, *AI SDLC*,
*agentic software development*.

## 2. Princípios transversais

Estes são os fios que atravessam todos os plays — é por eles que o keelson deve ser medido,
mais do que play a play.

| # | Princípio | O que significa no playbook |
|---|---|---|
| P1 | **Todo estágio termina num artefato commitado, e o próximo começa lendo-o** | `intent.md` → `spec.md` → `plan.md` → diff + testes → PR com achados → registro de incidente. Nos estágios iniciais o artefato é markdown (PO e agente leem o mesmo arquivo); do Build em diante, é código e seus registros. |
| P2 | **A cadeia de commits é a trilha de auditoria** | Quem pediu o quê, o que o agente produziu, quem aprovou — tudo no git. |
| P3 | **O artefato aceito dispara o próximo gate** | Intent aceito dispara requisitos+design; spec aprovada dispara plan mode; PR mergeado dispara pipeline; banda de controle rompida em produção escreve o próximo `intent.md`. Adoção começa disparando cada passo à mão; estado final é o loop automático. |
| P4 | **Atenção humana concentrada nos gates** | O humano revisa o que o agente sinalizou, não recomeça cada estágio do zero. Humano continua responsável por toda decisão que exige julgamento. |
| P5 | **Separação de funções** | Quem produz não aprova — em todo gate (review, scan de segurança, deploy). |
| P6 | **Advisory × determinístico** | Skill torna a violação *rara*; hook a torna *quase impossível*. Política que precisa valer sempre exige camada determinística por trás da skill. |
| P7 | **Humano nos gates, não no caminho crítico** | Aprovação que pausa sessões paralelas no meio do build está no lugar errado — gates com aprovação humana moram no Deploy. |
| P8 | **Configuração do agente é código** | CLAUDE.md, skills e hooks são versionados, revisados em PR e testados por eval quando mudam. |
| P9 | **Toda falha realimenta o loop** | Erro repetido → CLAUDE.md; achado de review repetido → CLAUDE.md; incidente → eval permanente; anomalia em produção → novo `intent.md`. |
| P10 | **Cada play declara como medir** | Um indicador *leading* e um *lagging*, quase sempre lidos de fonte já existente (git, metadados de PR, OpenTelemetry, incident tracker). |
| P11 | **Adoção modular por grafo de dependência** | Cada play declara pré-requisitos; começa-se pelos que não dependem de nada. |

**Estrutura de cada play:** o que muda · como começar (pré-requisitos + infraestrutura) ·
passos concretos · governança (o que é aplicado, qual a evidência, onde fica registrado,
quem aprova) · como medir (leading + lagging).

## 3. Os seis estágios, play a play

Visão geral dos extremos (a maioria das organizações está no meio):

| Estágio | Tradicional | AI-native |
|---|---|---|
| Plan | Requisitos por comitê, workshops e sign-offs, redigidos à mão | Claude sintetiza as dores direto das fontes num `intent.md` legível por humano e acionável por máquina |
| Design | Spec escrita por analistas, reinterpretada por designers | Requisitos e design numa só sessão com agente, guiada por padrões codificados como skills, versionada |
| Build | Código e testes à mão; documentação depois | Código e testes gerados; conhecimento institucional em CLAUDE.md e skills versionados |
| Test | Gates de QA nas fronteiras de estágio | Evals contínuos ao longo da implementação |
| Deploy | Humano revisa toda linha; governança em ciclos, inconsistente | Camadas de review agêntico; humano reservado para código regulado/crítico; governança aplicada enquanto o agente age, com hooks como gates |
| Maintain | Humanos vigiam produção | Agentes monitoram; banda de controle rompida é diagnosticada e volta ao loop como novo `intent.md` |

### 3.1 Estágio 1 — Plan

**Play: capturar como `intent.md`.** A ideia deixa de esperar alguém que a redija; a intenção
é capturada uma vez, nas palavras de quem a teve, como artefato versionado.

- **Rotas de entrada:** ideia de uma pessoa, ticket aberto, incidente vindo de alerta
  (Estágio 6). Qualquer que seja a origem, o **PO revisa e corrige o `intent.md` escrito pelo
  agente antes do commit**.
- **Tradicional:** a ideia atravessa backlog, user stories, story points e refinamentos; a
  posse troca de mão a cada handoff e o que chega à engenharia está vários passos longe do
  que o originador quis dizer.
- **Pré-requisitos:** nenhum.
- **Infraestrutura:** acesso ao Claude para não-engenheiros (claude.ai ou Cowork); template
  acordado; um **lar versionado da intenção** que o PO acompanha. Para um produto, o mais
  simples é uma pasta `intent/` no repo do produto (artefato ao lado do código que deriva
  dele); repo dedicado só compensa quando a intenção atravessa muitos repos; em monorepo é
  um diretório. Montar isso é tarefa única do time de plataforma, que decide quem escreve.
  Quem não sabe git não precisa usá-lo — um conector do VCS deixa o Claude commitar por ele.
- **Passos:** o originador descreve o problema com as próprias palavras (o que não consegue
  fazer hoje, quem é afetado, como seria o melhor, o que está fora) → brainstorm até ficar
  concreto, com o Claude fazendo as perguntas de um analista (escopo, usuários, restrições,
  sucesso) → Claude escreve o `intent.md` pelo template da organização (que pode ser skill
  montada por alguém técnico e aprovada por um líder) → originador corrige o que foi mal
  entendido → commit no lar compartilhado (autor e timestamp entram no registro).
- **Seções do template de exemplo:** título, autor e status; Problema; Resultado proposto;
  Usuários e sistemas afetados; Restrições; Perguntas em aberto.
- **Governança:** a evidência é o `intent.md` commitado com autor, timestamp e histórico. O
  PO aprova; aceite ou rejeição é registrado como **merge** ou **fechamento do review**.
- **Medir:** *leading* — tempo da primeira conversa ao commit do `intent.md` (esperado cair
  de semanas para horas). *Lagging* — taxa de sobrevivência (fração aceita pelo PO rumo ao
  Design) e quantas mudanças o `intent.md` sofre depois do primeiro commit do `spec.md`.

### 3.2 Estágio 2 — Design

**Play: requisitos e design numa sessão.** A política é aplicada enquanto a spec é escrita,
não descoberta num review semanas depois.

- Com o intent aprovado, Claude produz uma spec de requisitos + design guiada pelas skills da
  organização (marca, segurança, compliance, UX). **O PO revisa, não escreve.** Objetivo: uma
  spec contra a qual a engenharia planeja, **com áreas de preocupação sinalizadas**.
- Front-end como caso mais claro: o PO faz o mock no Claude Design (beta) a partir do intent,
  itera e exporta para o Claude Code construir.
- **Tradicional:** requisitos e design em fases e times separados; a separação existe por
  accountability, mas é lenta e perde informação.
- **Pré-requisitos:** `intent.md`; políticas de marca, segurança, compliance e UX escritas
  como skills. **Infra:** PO com acesso ao Claude; nenhuma habilidade de engenharia exigida.
- **Passos:** sessão com as skills disponíveis e o intent anexado → prompt que aponta o
  intent, nomeia restrições e **exige** as preocupações sinalizadas. **Evolução em três
  degraus:** rodar à mão → virar slash command da organização → job não interativo disparado
  pelo **merge do intent**, que roda com as skills e abre o `spec.md` como PR (a primeira
  participação do PO passa a ser o review) → PO confere a spec contra a ideia (resolve o
  problema? as perguntas em aberto foram respondidas ou carregadas?) → trabalha primeiro as
  preocupações sinalizadas, cada uma resolvida com o **dono da política** antes da engenharia
  ver → commit do `spec.md` ao lado do `intent.md` (o par registra o que se pediu e o que se
  decidiu) → PO decide se avança, consultando tech lead no que a organização classifica como
  alto risco; **aceitar a spec é o que dispara o plan mode**.
- **Prompt de exemplo (descrito):** ler o intent anexo, produzir spec de requisitos e design
  para integrar ao código existente, aplicar as skills disponíveis (marca, segurança, UX),
  documentar como `spec.md` pronto para a engenharia e descrever claramente as áreas de
  preocupação — em especial onde políticas se contradizem.
- **Governança:** spec, o prompt que a produziu e as **versões das skills em vigor** ficam no
  controle de versão; PO assina; preocupações vão aos donos nomeados das políticas.
- **Medir:** *leading* — tempo entre commit do intent e commit da spec. *Lagging* — retrabalho
  de requisito: commits no `spec.md` datados depois do primeiro commit do `plan.md`.

### 3.3 Estágio 3 — Build

Nada é implementado sem plano aceito; conhecimento institucional vira arquivo que o agente
lê; guardrails rodam como código, não como hábito.

**Play: plan mode como ponto de partida padrão.**
- Engenheiro abre a sessão em plan mode, entrega a spec aprovada e deixa o Claude
  entrevistá-lo, iterando até ficar satisfeito. No plan mode o Claude lê o código sem
  alterar nada.
- **Tradicional:** o "como" (quais arquivos, quais testes) fica na cabeça do engenheiro ou num
  comentário de ticket; o primeiro que o revisor vê é o diff pronto, quando retrabalho já é
  caro.
- **Pré-requisitos:** intent/spec se existirem; CLAUDE.md ajuda. **Infra:** Claude Code com
  acesso ao repo.
- **Passos:** pedir um plano que nomeie **arquivos que mudam, ordem do trabalho e testes que
  provam** → **interrogar** o plano (o que pode quebrar, qual o passo mais arriscado, que
  alternativas foram descartadas) → iterar até que **um engenheiro que nunca viu a conversa
  consiga implementar só com o plano** → commitar como `plan.md` (entra na trilha; o review do
  PR confere o diff contra ele) → aceitar e deixar implementar (com bom plano, muitas vezes
  sai numa passada) → **quando a implementação diverge, atualizar o `plan.md` no mesmo
  commit** — considerar hook que force a sincronia.
- **Seções do plano de exemplo:** arquivos que mudam; ordem do trabalho; riscos; prova.
- **Governança:** o design review acontece antes de haver código, quando mudar de rumo é
  editar um documento; o plan mode impõe isso sozinho. Rotina é aprovada pelo engenheiro;
  alto risco vai a tech lead/arquiteto.
- **Medir:** *leading* — fração de mudanças que mergeiam da primeira passada; tempo de plano
  aprovado a PR mergeado. *Lagging* — ciclos de retrabalho por mudança; com que frequência o
  diff mergeado ainda casa com o `plan.md`.

**Play: auto mode.** Com o plano aprovado, o Claude aplica cada mudança sem prompt por edição.
À medida que os guardrails amadurecem (CLAUDE.md afinado, skills com política, hooks que
bloqueiam o inseguro, suíte que o Claude roda), auto-accept vira padrão para o rotineiro:
spec apertada, raio pequeno, código já coberto por teste. A revisão migra de "assistir o
agente editar" para **revisar artefatos depois de sessões autônomas longas**. Com worktrees,
habilita paralelismo e é base para fechar o loop do Estágio 6.

**Sidebar: sistemas legados e fonte da verdade** (vale para todo artefato).
- O processo existente já rastreia artefatos, só que fora de markdown (Jira, ferramenta de
  requisitos com rastreabilidade regulatória, Figma, change board). São difíceis de
  deslocar porque auditores e outros times dependem deles — o SDLC AI-native se encaixa em
  volta.
- Regra: **para cada artefato, um sistema é a fonte da verdade**; os demais guardam cópia ou
  link. Três configurações, escolhidas por artefato:
  1. **Repo como fonte** — markdown é o registro autoritativo; o legado referencia arquivos
     em commits. A mais limpa para organizações lideradas por engenharia (uma ferramenta, uma
     autoridade de timestamp).
  2. **Legado como fonte** — Jira/ServiceNow/ferramenta de requisitos é autoritativo; o
     markdown é cópia de trabalho; o Claude lê o registro no início e escreve o resultado de
     volta via MCP na mesma sessão.
  3. **Linkagem como mínimo** — todo artefato cita o ID do registro e todo registro guarda o
     SHA do markdown; bom ponto de partida, aceitando duas fontes.

**Play: CLAUDE.md.**
- Dá ao Claude o contexto de um recém-chegado: convenções, comandos, arquitetura, erros mais
  comuns do time. Mantido pelo time todo, iterado a cada erro.
- **Passos:** `/init` gera o ponto de partida → cortar para o que o recém-chegado precisa no
  dia 1 (comandos de build/test/lint, convenções que importam, o que o Claude erra) → commitar
  na raiz, revisado como código → **regra de trabalho: erro cometido duas vezes vira linha no
  CLAUDE.md** → **menos de uma página** (é lido inteiro a cada sessão; conteúdo velho só
  ocupa contexto).
- **Seções do exemplo:** Comandos; Convenções; Arquitetura; "O que o Claude erra".
- **Governança:** versionado; mudanças aprovadas por code owners em PR.
- **Medir:** *leading* — quantas vezes o Claude repete um erro que o CLAUDE.md devia pegar.
  *Lagging* — tempo até o primeiro PR mergeado de um novo membro.

**Play: skills como conhecimento institucional.**
- Tornam operacional o conhecimento da organização: explícitas, versionadas, amplamente
  aplicadas, atualizadas centralmente. **Regra de bolso:** skill para conhecimento que precisa
  ser aplicado com consistência; o que cabe em CLAUDE.md ou prompt não vira skill.
- **Infra:** uma política com dono nomeado e fonte escrita.
- **Passos:** escolher um conhecimento aplicado de forma inconsistente hoje (padrão de
  segurança, convenção de API, regra de marca) → escrever como skill (pasta com `SKILL.md`;
  frontmatter diz quando dispara, corpo diz o que fazer), a partir da fonte do dono da
  política → versionar em `.claude/skills/<nome>/` ou distribuir por plugin → **testar que
  dispara** (pedir a tarefa de jeitos diferentes e confirmar que carrega sempre) → política
  mudou, skill muda com sign-off do dono → engenheiros recebem na próxima sessão.
- **Exemplo (descrito):** skill de revisão segura de API — JWT obrigatório fora de health,
  validação contra o schema rejeitando campos desconhecidos, evento de auditoria em todo
  endpoint que muda estado, campos PII nunca em log/erro, e rodar um script de checagem
  colando a saída no resumo.
- **Governança:** **skill é controle advisory** — torna provável que a política seja
  aplicada, nada obriga a sessão a cumprir. Política que precisa valer sempre exige algo
  determinístico atrás (hook que bloqueia, ou passada de review que re-checa no PR).
- **Medir:** *leading* — tempo do dono aprovar a mudança de política ao merge da skill.
  *Lagging* — achados de review citando a política devem tender a zero; se não tendem, ou a
  skill não dispara ou o texto divergiu da política oficial.

**Play: hooks como guardrails de build.**
- Camada determinística atrás da skill. No build, as ações são edições e comandos, então é
  onde hooks mais disparam: bloquear edição de paths protegidos (classes geradas, pacote
  congelado), rodar formatter/linter após edição, manter credenciais fora do diff.
- Hooks de build devem ser **rápidos e restritos ao arquivo alterado**; checagem pesada
  (suíte completa) vai para commit ou PR.
- Hook que **pede aprovação humana** pertence ao Deploy (P7).

**Play: sessões paralelas e subagents.**
- **Sessão paralela** = outra instância completa, noutra tarefa, na própria worktree; não sabe
  das outras; o engenheiro é o único elo. **Subagent** = ajudante com escopo dentro de uma
  sessão, contexto e ferramentas próprios; serve a tarefas recorrentes (ex.: verificar que o
  app roda).
- **Pré-requisitos:** CLAUDE.md; o feedback loop do Estágio 4 ajuda (menos supervisão).
  **Infra:** git (isolamento por worktree) e permissões afinadas para não travar em prompt.
- **Passos:** usar o plano para achar trabalho independente — **tarefas que compartilham
  arquivo rodam na mesma sessão, em sequência** → uma worktree por tarefa paralela → começar
  com 2–3 sessões; **o teto é quantos fluxos uma pessoa consegue revisar direito** → tarefas
  repetidas viram subagents em `.claude/agents/` (simplificador pós-implementação, verificador
  que roda o app, pesquisador que explora sem inundar o contexto principal).
- **Exemplo (descrito):** subagent verificador com Bash+Read — sobe o app, exercita a mudança
  e os dois fluxos vizinhos, reporta o que rodou, o que viu e o que diverge do `plan.md`;
  **não conserta, só reporta**.
- **Governança:** mais sessões = mais saída, então o controle vem da configuração do repo
  (hooks e permissões valem para todas); ações atribuídas ao engenheiro que rodou.
- **Medir:** *leading* — sessões concorrentes por engenheiro mantendo a qualidade do review
  (via OpenTelemetry); fração do dia pilotando vs. esperando. *Lagging* — mudanças mergeadas
  por engenheiro/semana lidas junto com a taxa de retrabalho.

### 3.4 Estágio 4 — Test

Toda sessão confere o próprio trabalho antes de um humano ver; a configuração que dirige o
agente é testada por regressão como o código que ele escreve.

**Play: dar ao Claude um feedback loop.**
- Sempre um jeito de verificar o próprio trabalho: testes, build, diff de screenshot.
- **Diferença para o subagent verificador:** o loop roda durante toda a tarefa, quantas vezes
  for preciso; o verificador é uma forma de empacotar a **checagem final em contexto novo**,
  para o veredito não herdar as premissas que produziram o código.
- **Infra:** suíte e build que rodam localmente com **um comando cada**; para UI, um jeito do
  Claude *ver* o resultado (browser ou screenshot via MCP).
- **Passos:** embrulhar a verificação num alvo único que sai não-zero em falha → listar cada
  comando no CLAUDE.md com exemplo de saída saudável → declarar **alvo quantificável** (testes
  X passam; screenshot bate com o mock; endpoint devolve 200 com o campo novo) → **bugfix:
  teste que falha primeiro** — reproduzir o bug como teste, confirmar que falha pelo motivo
  esperado, commitar, e só então pedir para fazer passar **sem editar o teste** → UI: loop
  implementar–screenshot–comparar–ajustar (2–3 rodadas é normal) → verificação faz parte do
  "pronto" (rodar antes de reportar, mostrar a saída) → **proteger o próprio loop:** hook que
  bloqueia edição de arquivo de teste durante tarefa de fix (alternativa: rejeitar no review
  qualquer mudança que toque teste).
- **Exemplo (descrito):** bloco de verificação no CLAUDE.md — build, test e lint com o
  critério de verde de cada um, rodar os três antes de reportar e colar a saída, nunca pular
  ou apagar teste que falha, consertar o código e não o teste.
- **Governança:** *o que é aplicado* — verificação antes do "pronto" e bloqueio de edição de
  teste em fix, como hooks onde se quer garantia; *evidência* — a saída literal da
  ferramenta; *registro* — transcript (exportado por OpenTelemetry) e check run do PR; *quem
  aprova* — code owner, que foca em intenção e risco porque a evidência mecânica já está
  anexada.
- **Medir:** *leading* — taxa de CI verde na primeira passada para mudanças do agente.
  *Lagging* — tempo de review por PR; change failure rate.

**Play: evals contínuos em CI.**
- Evals são o equivalente AI-native do QA por stage-gate: suíte que roda quando a
  **configuração do agente** muda (troca de modelo, prompt reescrito) e diz se o trabalho
  segue no mesmo padrão. **Suíte viva:** casos que deixam de discriminar com modelos
  melhores saem; novos entram a partir do monitoramento. Alguns times preferem rodar offline
  em cadência.
- **Pré-requisitos:** CLAUDE.md e feedback loop. **Infra:** CI que roda Claude Code não
  interativo; chave de API com orçamento para evals.
- **Passos:** juntar **20–50 tarefas reais** recentes com o resultado aceito → cada uma vira
  eval (prompt + checagens que definem aceitável: testes passam, lint limpo, comportamento
  inalterado, política seguida) → roda em agenda **e em toda mudança de CLAUDE.md, skills ou
  hooks** → **gate de configuração:** mudança de skill que derruba a taxa de acerto é revista
  antes do merge → **cada incidente de produção vira eval**, escrito pelo time dono, e fica
  como regressão.
- **Exemplo (descrito):** workflow de CI disparado em PR que toca `CLAUDE.md` ou `.claude/**`
  e num cron noturno; instala o Claude Code, itera os casos rodando `claude -p` com ferramentas
  restritas e saída JSON, e passa cada resultado a um script checador.
- **Governança:** limiar de taxa de acerto aplicado como merge check; rodadas registradas
  para comparação no tempo; o time dono da configuração aprova.
- **Medir:** *leading* — taxa de acerto no tempo; quanto tempo um incidente leva para virar
  eval permanente. *Lagging* — regressões pegas em CI vs. achadas em produção.

### 3.5 Estágio 5 — Deploy

Review nos dois sentidos; governança aplicada enquanto o agente age. **O agente faz tudo até
o gate de produção e nada além dele.**

**Play: IA no loop de review de PR.**
- O Claude **dá e recebe** review: revisa PRs contra as políticas e resolve comentários nos
  próprios PRs. O humano sobe um nível — julga se a mudança faz o que o plano pretendia e se o
  risco é aceitável.
- **Tradicional:** capacidade de review planejada para produção humana; PR espera leitura
  integral; qualidade varia com a carga do revisor.
- **Pré-requisitos:** CLAUDE.md atualizado; skills se as passadas aplicam políticas escritas;
  subagents definidos. **Infra:** integração Claude no repo (Code Review gerenciado, em
  research preview, ou a `claude-code-action` no próprio CI; chamadas via Bedrock/Vertex/
  Foundry quando necessário); branch protection exigindo aprovação de code owner.
- **Passos:** começar pelo serviço gerenciado; ir para a action quando precisar controlar o
  pipeline → tech lead escreve **`REVIEW.md`** na raiz com as passadas (bugs e lógica;
  segurança; **compliance contra `spec.md`, `plan.md` e princípios de design**), o que conta
  como *Important* vs. *Nit* e o que pular → tech lead fixa o limiar humano: achados não
  aprovam nem bloqueiam sozinhos; quem quiser gatear merge lê a contagem por severidade que o
  check run publica em formato de máquina → marcar `@claude` num comentário faz o Claude
  resolver e empurrar o fix (no serviço gerenciado, `@claude review` pede review novo) →
  para PRs abertos pelo Claude, **"babysit até o merge"**: slash command que varre
  comentários não resolvidos e checks falhando até o PR ficar verde esperando só o code owner
  → **achado de review que aparece pela segunda vez vira linha no CLAUDE.md** (e o review
  também sinaliza quando a mudança deixou o CLAUDE.md desatualizado) → mensalmente o tech lead
  afina: avalia achados e limita o volume de nits; exclui paths gerados e o que o CI já
  aplica.
- **Exemplo (descrito):** `REVIEW.md` com três passadas etiquetadas (bugs, segurança,
  compliance), *Important* reservado para o que quebra comportamento, vaza dado ou viola
  política; no máximo cinco nits por review, o resto como contagem; não reportar arquivos
  gerados nem o que o CI já garante.
- **Governança:** separação de funções preservada (o agente que escreveu não tem como
  aprovar); `REVIEW.md` vale para todo PR; achados, fixes, avaliações e aprovações ficam no
  histórico do PR — **o PR é o registro de auditoria**; aprovação vem de humano via branch
  protection.
- **Medir:** *leading* — tempo até o primeiro review (minutos); fração de comentários
  resolvidos sem humano tocar a branch. *Lagging* — defeitos e vulnerabilidades pegos antes
  do merge vs. que escaparam.

**Play: hooks como gates de aprovação.**
- No build, hooks só permitem ou bloqueiam. Um hook também pode **perguntar** — pausar a ação
  até uma pessoa específica aprovar —, que é o que o gate de release precisa. Não é exclusivo
  de deploy: bloquear edição de migração/infra sem ticket de mudança (Build) e impedir edição
  de teste em fix (Test) são outros usos.
- **Infra:** lista escrita das aprovações que o processo de mudança exige.
- **Passos:** liderança de engenharia + gestão de mudança + compliance listam os gates humanos
  que precisam sobreviver (sign-off de mudança, autorização de release, edição de path
  protegido) → engenheiro de plataforma expressa cada gate como hook (**allow / ask /
  block**) → hooks do time em `.claude/settings.json` versionado; **hooks inegociáveis em
  managed settings**, que o engenheiro individual não desliga → **todo bloqueio se explica:**
  motivo e rota de aprovação aparecem na saída do Claude.
- **Exemplo (descrito):** hook `PreToolUse` em Bash que, se o comando é deploy para produção
  e falta a variável de autorização de release, sai com código 2 (bloqueia e a mensagem vai
  ao Claude).
- **Exemplo trabalhado — managed settings de empresa regulada** (distribuído por MDM/console,
  não editável pelo engenheiro). O que cada bloco compra em termos de controle:
  - `permissions.deny` tira segredos do contexto e bloqueia saída de rede pelas ferramentas;
    `permissions.allow` pré-aprova o loop interno seguro para o deny não virar fadiga de
    prompt;
  - desabilitar o modo bypass + só regras gerenciadas = ninguém alarga as regras;
  - `sandbox` fecha o que a permissão não fecha (deny de WebFetch não impede um comando de
    shell de sair para a rede; o allowlist de domínio no nível do SO impede);
    `failIfUnavailable` e proibir comando fora do sandbox fazem do sandbox um gate;
  - `credentials` nega leitura de `~/.ssh`/credenciais de nuvem e remove variáveis secretas do
    ambiente de todo comando sandboxado;
  - só hooks gerenciados, sem flags de sideload, marketplace estrito e só MCP gerenciado = toda
    skill, agent, hook e servidor MCP chegou pelo marketplace aprovado;
  - versão mínima exigida = os controles rodam numa build que a organização avaliou.
  - O artigo ressalva: é ponto de partida para adaptar, não receita — cada deny troca
    capacidade, e o equilíbrio depende da classificação de dados do repo.
- **Governança:** a condição do gate vale sempre, para todos; decisões allow/block registradas
  com timestamp; o gate define o que conta como aprovação.
- **Medir:** *leading* — tempo esperando em cada gate (cada decisão vai ao OpenTelemetry com
  timestamp e veredito). *Lagging* — violações de gate chegando à produção antes e depois.

**Play: integração CI/CD e deploy.**
- Claude não interativo no pipeline para os passos de julgamento, em sandbox com credenciais
  com escopo; deploy exposto por MCP; rollback ensaiado antes de precisar.
- **Pré-requisitos:** review de PR com IA e hooks como gates — **os gates precisam existir
  antes da automação acelerar algo através deles**. **Infra:** CI com a action ou runner que
  chame `claude -p`; acesso ao modelo por API ou nuvem; servidores MCP dos alvos de deploy;
  perfil de sandbox sem credencial permanente de produção.
- **Passos:** começar por passos de julgamento **só leitura** (triar build quebrado, resumir
  teste flaky, rascunhar changelog) → passos de escrita atrás dos gates existentes (corrigir
  lint, atualizar docs gerados, resolver comentários) — tudo que o agente escreve chega como
  PR, **sem rota para push na main** → execução em container com política de rede e tokens
  curtos → deploy, status e rollback como **ferramentas MCP por ambiente** (allowlist, não
  shell com credencial) → **autonomia por ambiente:** dev livre; produção o agente prepara e o
  release manager autoriza, com hook garantindo; staging no meio → **rollback é o caminho
  mais ensaiado do pipeline** (um comando, exercitado em staging), porque o Estágio 6 o
  aciona.
- **Governança:** princípio "age até o gate de produção, não passa": branch protection, hook
  de deploy exigindo release manager nomeado, identidade própria do agente em cada execução
  não interativa (o log separa o que o agente fez do que o engenheiro que disparou fez),
  permissões por ambiente.
- **Medir:** *leading* — fração de falhas de pipeline triadas sem acionar humano. *Lagging* —
  métricas DORA.

### 3.6 Estágio 6 — Maintain

O loop fecha: um gatilho invoca o Claude **sem pessoa no caminho da invocação**, e o que ele
acha volta ao pipeline como `intent.md`.

- Até aqui cada estágio precisava de humano para começar. Aqui o foco é execução autônoma:
  um agente de monitoramento, a partir de um ticket de bug, cria um `intent.md` e o faz
  atravessar requisitos, plano, build, teste e review — **headless**, com um **gate de
  confiança independente entre estágios** (checagem determinística ou agente revisor
  adversarial) decidindo se a saída anterior segue ou escala para humano.
- **Tradicional:** manutenção reativa; alerta às 3h pode ser perdido; ticket fica no backlog;
  ação de post-mortem pode nunca chegar ao código.
- **AI-native:** gatilho (banda rompida, ticket, mensagem de canal, agenda) invoca o Claude;
  ele diagnostica, age só por rotas com gate e escreve o achado como `intent.md`. Pessoas
  triam e revisam; não precisam mais iniciar.

**Play: fechar o loop.**
- **Pré-requisitos:** `intent.md` (saída estruturada para reiniciar), review de PR com IA,
  hooks como fronteira de ação, rollback no CI/CD. **Infra:** store de métricas consultável
  pelo script de detecção; leitura do repo; Claude não interativo no CI ou Agent SDK num
  serviço que recebe webhooks.
- **Passos:** escolher **uma** métrica com baseline estável (taxa de falha de teste no CI, 5xx
  pós-deploy, cycle time de PR) → script de detecção com média e desvio numa janela móvel e
  regras (Western Electric ou similar) que pegam deriva lenta e pico — **versionado, com
  teste unitário, 100% determinístico, sem modelo** → níveis de resposta em config versionada:
  **1σ só registra; 2σ invoca o Claude só leitura para diagnosticar; 3σ o Claude pode agir,
  mas só abrindo PR para o gate de review ou acionando runbook pré-aprovado** → camada de
  gatilho (workflow agendado, webhook do monitoramento, cron interno); Claude roda sem estado,
  como passo não interativo ou serviço do Agent SDK em container sandboxado → diagnóstico sai
  como `intent.md` no formato do Estágio 1 (anomalia e evidência, resultado proposto, sistemas
  afetados, perguntas) → dono do serviço/on-call tria a fila (consertar agora, agendar,
  descartar); **descartes afinam as bandas** → fix entregue ganha eval.
- **Exemplo (descrito):** arquivo de bandas para taxa de falha de teste: baseline móvel de 30
  dias, regras Western Electric, e para cada nível a ação e as ferramentas/rotas permitidas.
- **Governança:** fronteiras dos níveis vêm de config versionada; permissões e managed settings
  negam acesso à produção; invocações, achados e decisões de triagem registrados com timestamp;
  mudanças passam pelo gate normal de PR; runbooks acionáveis aprovados antes.
- **Medir:** *leading* — tempo da banda rompida ao `intent.md` na fila (vs. tempo antigo de
  incidente a ação de post-mortem). *Lagging* — fração de achados que viram fix mergeado;
  incidentes repetidos da mesma classe (devem cair à medida que fixes viram evals).
- **Exemplos:** CI falhando acima de 3σ → quarentena do teste flaky ou PR de revert; 5xx
  pós-deploy acima de 3σ com deploy na janela → aciona o rollback existente; cycle time de PR
  com deriva → relatório para a liderança (mostra que serve a métricas de processo também).

**Play: scans recorrentes da base.**
- Um scan de segurança é uma foto de um código sob um modelo — e ambos envelhecem (o código
  muda toda semana; cada geração de modelo acha o que a anterior não achou). Resposta: scan
  agendado, sem humano na invocação, achados pelos mesmos gates de qualquer mudança.
- **Claude Security** (Enterprise, beta público): conecta repos GitHub; scans rodam no modelo
  mais capaz (Mythos 5); cada achado é **validado antes de reportado** e vem com nota de
  confiança; patches sugeridos revisados no Claude Code na web; cobrança por consumo, com
  limite de gasto.
- **Passos:** organizar repos em projetos por dono → primeiro scan completo dos repos
  críticos como **baseline** (inclusive dos "já limpos") → agenda por projeto (semanal como
  default) → triagem com a confiança à mão; **descartar sempre com motivo** (o mesmo achado não
  volta como novo) → achado limitado vira patch pelo gate de PR (quem propôs não aprova) → achado
  maior (fraqueza arquitetural, padrão repetido) vira `intent.md` → fix em produção ganha eval
  da classe de vulnerabilidade → exportar (CSV/Markdown/webhook) para o tracker/auditoria que
  já é sistema de registro.
- **Governança:** controles centrais (repos, assentos, limite de gasto); histórico do scan é
  registro de auditoria do que foi achado, corrigido e conscientemente aceito. Complementa —
  não substitui — análise estática e de dependências no CI.
- **Medir:** *leading* — fração de repos com agenda; tempo do achado ao patch no gate.
  *Lagging* — vulnerabilidades achadas pelo scan vs. em produção/relato externo; tendência de
  achados por scan em repos com várias rodadas (deve cair).

**Play: Claude de plantão com Claude Tag.**
- Incidente também chega por canal (Slack/Teams). Claude Tag (beta, Slack) põe o Claude como
  membro do canal com identidade própria: **primeiro respondedor** de cada incidente.
- Conversa e conhecimento ficam no canal; qualquer pessoa guia, testa hipóteses e investiga
  junto; via MCP o Claude confirma que a métrica voltou ao baseline, registra na thread e
  escreve o **post-mortem num arquivo de lições versionado** que investigações futuras leem.
- Também tria trabalho que não é incidente (ticket via MCP, pedido no canal): fix pequeno vira
  PR pelo gate; maior vira `intent.md`. **O canal é a trilha de auditoria** (pedido,
  diagnóstico, autorização humana, fix).

### 3.7 Fecho do artigo

Modelos e harnesses permitem transformar o ciclo inteiro, não só a produção de código, mantendo
o julgamento humano central e respeitando governança e regulação de grande empresa. Frase de
fecho: o loop continua rodando; o julgamento humano fica acima dele.

**Referências operacionais listadas pelo artigo** (na ordem sugerida de rollout, todas em
`code.claude.com/docs/en/` salvo indicação): `admin-setup` (mapa de decisões do admin — comece
aqui) · `settings` (precedência e chaves só-gerenciadas) · `server-managed-settings` ·
`permissions` · `sandboxing` · `hooks-guide` · `hooks` · `skills` · `plugin-marketplaces`
(distribuição organizacional) · `managed-mcp` · `third-party-integrations` (Bedrock, Vertex,
Foundry) · `network-config` · `monitoring-usage` (OpenTelemetry) · `analytics` · Compliance API
(`platform.claude.com/docs/en/manage-claude/compliance-api`) · `security`.

---

## 4. Correspondência play a play com o keelson

Legenda: ✅ coberto · ◐ parcial · ✗ ausente · ⊘ divergência por decisão registrada ·
➕ keelson vai além do playbook.

| Estágio | Play / elemento | Equivalente no keelson | Status | Nota |
|---|---|---|---|---|
| 1 Plan | `intent.md` (proto-spec do originador, template, PO corrige) | `/keelson:brief` (BRIEF forjado) · `/keelson:triage` · `/keelson:specify-epic` + `pm` | ✅ | Correspondência de seções em `docs/wiki/Conceitos.md`. Campo *Autor* adiado com gatilho (parecer 2026-09-21). |
| 1 Plan | Lar versionado da intenção (`intent/`) | Artefatos no `docsRoot` do consumidor, INDEX por slug (`index-contract.md`) | ✅ | Pasta `intent/` e rename recusados no parecer de 2026-09-21. |
| 1 Plan | Entrada por incidente/ticket | `production-intake-protocol.md` (4.101) · `/keelson:postmortem` · `/keelson:jira-sync` | ◐ | Entrada estruturada existe, mas **iniciada por humano**. |
| 1 Plan | Medir: tempo ao commit; taxa de sobrevivência | — | ✗ | Nenhum instrumento mede sobrevivência de BRIEF. |
| 2 Design | Spec numa sessão com skills como restrição; preocupações sinalizadas | `/keelson:specify` (via `scribe`, 4.103) + `spec-validator` (forma) + `product-analyst` (mérito) + `po` contra o BRIEF, escalando por exceção com proposta + default (4.37) | ✅ ➕ | Crítica de mérito separada e janela de veto: o PO não para o fluxo. |
| 2 Design | Políticas (marca/segurança/UX) aplicadas na escrita | `guidelines/core/` (SECURITY, DESIGN, PERFORMANCE…) + perfil de linguagem | ◐ | No keelson as políticas pesam sobretudo **nos gates do diff** (8/10/11), menos na redação da SPEC. |
| 2 Design | Aceite do intent dispara a spec (job no merge) | `/keelson:auto` encadeia specify → plan → tasks → implement | ◐ | Encadeamento **intra-sessão**; nada dispara por merge/CI. |
| 2 Design | Registrar versões das skills em vigor | `generated-by:`/`charter:` nos perfis; versão do plugin na ficha | ◐ | Não há carimbo da versão do plugin **no artefato** gerado. |
| 2 Design | Medir: retrabalho de requisito (SPEC editada após PLAN) | Rota de emenda (4.398/4.412) · `graph.sh` · `index-check.sh` | ◐ | A rota existe; ninguém **conta** retrabalho. |
| 3 Build | Plan mode: arquivos, ordem, riscos, prova; interrogar alternativas | `/keelson:plan` (COMP, DEC com alternativas, FR→COMP; DEC proporcional 4.422) + `plan-validator` · `/keelson:tasks` (waves, closure) + `task-validator` · grafo (4.82) · templates (4.405) | ✅ ➕ | Mais granular e com prova mecânica de estrutura. |
| 3 Build | "Engenheiro sem contexto implementa só com o plano" | TASK autocontida para o `developer` em janela própria | ✅ | O subagent **é** o engenheiro sem contexto. |
| 3 Build | Plano sincronizado quando a implementação diverge (hook sugerido) | Sinal lateral "furo no plano" (developer → Tech Lead); contornar em silêncio é violação de gate | ◐ | Contrato, sem hook. |
| 3 Build | Auto mode | `/keelson:auto` como modo padrão · `/keelson:pause` / `/keelson:continue` (4.382) | ✅ | — |
| 3 Build | Fonte da verdade por artefato | Markdown no repo é fonte; Jira é espelho best-effort (`tracker-sync`) | ✅ | Configuração "repo como fonte"; linkagem pelo protocolo Jira. |
| 3 Build | CLAUDE.md curto; erro 2× vira regra | `/keelson:init` injeta o bloco + ficha · lições por arquivo (4.376) · `agile-coach` · `/keelson:lessons-audit` | ✅ ➕ | Lição com ciclo de vida (validade, sedimento, revogação). |
| 3 Build | Skills; "skill é advisory, hook é determinístico" | Régua 4.420 (lint → gate → gerador só com eval) · `skill-standards` (4.212) para autoria | ✅ | Mesmo princípio, formalizado como ordem de preferência. |
| 3 Build | Testar que a skill dispara | Descrições medidas pelo `desc-guard`; taxa de acionamento sugerida no radar de 2026-09-18 | ◐ | Sem teste de disparo sistemático. |
| 3 Build | Hooks de build (paths protegidos, formatter, segredos) | `worktree-guard`, `agent-guard` (4.42), `noverify-guard`, `desc-guard` | ◐ | Hooks do keelson guardam o **processo**; formatter/lint/segredos por edição são do consumidor. |
| 3 Build | Sessões paralelas em worktree + subagents | Elenco de agents · `agent-teams.md` · worktree por task como **condição** de paralelismo (4.334) | ◐ | Fluxo completo por worktree (branch por task, merge da wave) é leva pendente; até lá, serializa. |
| 3 Build | Teto = capacidade de review humano | Boletim entre waves + relatório de fecho (`report-contract.md`) | ◐ | Não há limite explícito de fluxos por capacidade de revisão. |
| 4 Test | Feedback loop: comando único, alvo quantificável, saída literal | `quality.*` na ficha · `qa` prova executando (gate 9) · `screen-verify` para UI · `/keelson:e2e-setup` | ✅ | — |
| 4 Test | Bugfix com teste vermelho primeiro | Repro vermelho do bugfix (4.159) | ✅ | — |
| 4 Test | **Hook que bloqueia edição de teste durante fix** | Doutrina em `guidelines/core/TESTING.md` + `code-reviewer` | ◐ | Advisory sem camada determinística — o caso P6 do próprio playbook. |
| 4 Test | Verificador em contexto novo | `code-reviewer` e `qa` em janela própria, separados do `developer` | ✅ | — |
| 4 Test | (fora do playbook) Mutation testing | `/keelson:mutation-setup` · 4.121 · campanha com catraca (4.401) | ➕ | — |
| 4 Test | **Evals contínuos em CI** ao mudar configuração | `evals/` + `scripts/eval-run.sh` (4.304): A/B, n≥2, veredito consultivo, plant (4.186) | ⊘ ◐ | Por decisão: do mantenedor, sob demanda, **nunca em CI**. O consumidor não tem evals da própria configuração. |
| 4 Test | Incidente vira eval permanente | `/keelson:postmortem` → lição / `PROPOSTA_PLUGIN` | ◐ | Vira **lição**, não caso de regressão executável. |
| 4 Test | Suíte viva (caso que não discrimina sai) | Plant obrigatório e HOLD em divergência (4.304) | ◐ | Não há poda periódica de casos que deixaram de discriminar. |
| 5 Deploy | Review de PR com passadas bugs / segurança / compliance contra spec e plan | `code-reviewer` (gates 1–7, régua em `guidelines/core/CODE-REVIEW.md`) + gates 8 (`security-engineer`), 10 (`performance-engineer`), 11 (`product-designer`) · `/keelson:review` (4.36) | ✅ ➕ | Review **antes do commit**, dentro do ciclo, não no PR. |
| 5 Deploy | Important × Nit; limite de nits | Calibração de severidade no `CODE-REVIEW.md` | ✅ | — |
| 5 Deploy | Quem escreve não aprova | developer ≠ reviewer ≠ qa · `review-guard`, `security-guard` · `ledger.sh` prova que o gate rodou | ✅ | — |
| 5 Deploy | `@claude` resolve comentário / "babysit até verde" | — | ⊘ | Fronteira: autonomia termina nos commits (4.263). |
| 5 Deploy | Achado repetido vira regra | `agile-coach` na closure + lições | ✅ | — |
| 5 Deploy | Hooks allow/ask/block; inegociáveis em managed settings | Hooks Stop/PreToolUse do plugin com fallback gracioso | ◐ | Gates de **processo**; managed settings, sandbox e credenciais são da plataforma, fora do plugin. |
| 5 Deploy | Bloqueio que se explica (motivo + rota) | Convenção dos guards (mensagem nomeia o que falta) | ✅ | — |
| 5 Deploy | CI/CD: `claude -p` no pipeline, deploy/rollback por MCP, autonomia por ambiente | `/keelson:integrate` valida DoD, roda suíte e **abre o PR**; merge/deploy são do Diretor | ⊘ | Equivale a "até o gate de produção". |
| 5 Deploy | Identidade própria do agente no log | Ledger de gates + trailers de commit | ◐ | Atribuição por papel dentro da sessão, não por identidade de execução. |
| 6 Maintain | Detecção determinística (bandas σ) → diagnóstico → `intent.md` | — | ✗ | Maior buraco em relação ao playbook. |
| 6 Maintain | Gate de confiança independente entre estágios, headless | Validators + PO + gates dentro do `/keelson:auto` | ◐ | Os gates existem; falta a execução **sem humano na invocação**. |
| 6 Maintain | Scans recorrentes da base | Gate 8 por diff (`SECURITY.md`, 4.20) | ◐ | Pontual por mudança, sem varredura agendada. |
| 6 Maintain | Descartar com motivo, sem reaparecer | `proposal-inbox.md` (`recusada (motivo)`), vereditos do `lessons-audit` | ◐ | Existe para proposta/lição, não para achado recorrente de gate. |
| 6 Maintain | Claude Tag como primeiro respondedor; post-mortem em arquivo de lições | `/keelson:warroom` (4.372, `DEBT.md`) · `/keelson:postmortem` · lições versionadas (4.376) | ◐ | Mesmo destino (lições versionadas); abertura é humana, não por canal. |
| Transversal | Métricas leading/lagging por play | `cycle-clock.sh` (4.325) · `context-cost.sh` · telemetria do `window-marker` (4.354) | ◐ | Mede-se tempo e custo do ciclo; não os indicadores de resultado do playbook. |

## 5. Divergências por decisão (⊘) — não reabrir sem decisão nova

| Divergência | Decisão vigente | Por que o keelson diverge | O que reabriria |
|---|---|---|---|
| Agente não passa do commit: sem PR automático, `@claude`, babysit, deploy | Modelo de time (4.37–4.41) e `/keelson:merge` como exceção declarada (4.263) | Pode haver outras sessões na mesma base; PR, merge e deploy são atos do Diretor | Consumidor pedindo explicitamente o degrau "PR aberto pelo agente" com gate de branch protection provado |
| Evals só do mantenedor e fora do CI | 4.304 (e piso n declarado na 4.377) | Custo por rodada (US$15–60), veredito consultivo, risco de gatear release em sinal estocástico | Rodada barata e estável o bastante para virar merge check; ou pedido de consumidor por evals da própria configuração |
| `intent/` e rename do BRIEF | Parecer `/idea-forge` 2026-09-21 | O BRIEF forjado já cobre todas as seções; renomear só custaria migração | Consumidor com integração externa que exija o nome `intent.md` |

## 6. Backlog de candidatos (insumo para `/idea-forge`)

Ordenado do mais barato ao mais caro. Nenhum está aprovado; cada um entra por leva própria.

| # | Candidato | Play de origem | Superfície provável no keelson | Prova esperada antes de aplicar | Risco / tensão conhecida |
|---|---|---|---|---|---|
| C1 | **Hook que bloqueia edição de arquivo de teste durante TASK de bugfix** (camada determinística atrás da 4.159) | 4 Test — proteger o loop | `hooks/` (novo PreToolUse Edit/Write) + `hooks.json` + suíte em `scripts/tests/` + `TESTING.md` como dono da regra | Suíte sintética: bloqueia teste existente em TASK de bug, libera o repro novo e teste de TASK de feature; fallback sem ficha → `exit 0` | Distinguir "repro novo" de "enfraquecer teste existente" sem falso-positivo (pior defeito da camada); detectar "TASK de bugfix" por fato do disco |
| C2 | **Incidente vira caso de regressão executável**, não só lição | 4 Test — evals · 6 Maintain | `/keelson:postmortem` + `production-intake-protocol.md` + `TESTING.md` (repro vermelho vira teste permanente do projeto) | Eval A/B: postmortem com e sem a instrução produz o teste de regressão? | Pode ser no-op — o repro da 4.159 já fica na suíte; medir antes (4.420: medir o acervo antes de desenhar o eval) |
| C3 | **Indicadores de resultado lidos do git** (sobrevivência de BRIEF; SPEC editada após PLAN; diff que ainda casa com o PLAN; retrabalho por TASK) | Todos — P10 | `scripts/` (extensão do `cycle-clock.sh`/`graph.sh` ou script novo, read-only) + `/keelson:report` | Rodar no acervo real (read-only) e conferir se os números discriminam algo | Métrica sem consumidor vira sedimento; definir quem lê antes de medir |
| C4 | **Carimbo da versão do plugin no artefato gerado** (SPEC/PLAN/TASK) | 2 Design — "versões das skills em vigor" | `templates/artifacts/*.md` + `check-templates.sh` + `lint-contract.md` | `check-templates` + lint verdes; campo lido por alguém (report, lessons-audit) | Campo que ninguém lê é no-op (lição da dieta 4.409/4.410) |
| C5 | **Worktree por task** (branch por task, merge da wave) | 3 Build — sessões paralelas | `commands/implement.md` + `agent-teams.md` + `worktree-guard` | Smoke operacional (`smoke-consumer.sh`) com wave paralela real | Já previsto na 4.334; custo de merge da wave e conflito |
| C6 | **Teste de disparo das descrições** (skill/agent aciona quando deveria) | 3 Build — testar que a skill dispara | `.claude/skills/skill-standards` ou `harness-audit` (tooling, sem bump) | Taxa de acionamento medida em prompts variados | Já sugerido no radar de 2026-09-18 (C3 dele) |
| C7 | **Poda periódica dos casos de eval que deixaram de discriminar** | 4 Test — suíte viva | `evals/` + `eval-run.sh` (tooling) | Relatório por caso: último veredito, braços empatados há N rodadas | Pouco volume de casos hoje; gatilho = suíte > N casos |
| C8 | **Scan agendado da base** (gate 8 fora do diff) | 6 Maintain — scans recorrentes | Comando novo ou modo do `/keelson:review` sobre a base inteira, disparável por agenda | Rodada em consumidor real comparando achados vs. gates por diff | Custo; sobrepõe Claude Security para quem é Enterprise |
| C9 | **Loop do Estágio 6**: detecção determinística → BRIEF gerado → fila para o Diretor | 6 Maintain — fechar o loop | Protocolo novo em `docs/_meta/conventions/` + script de detecção no consumidor + entrada no `production-intake-protocol.md` | Prova de campo num consumidor com métrica estável | **Muda a fronteira da autonomia** (invocação sem humano): decisão do Diretor antes de qualquer desenho |

## 7. Glossário de correspondência

| Playbook | keelson |
|---|---|
| originator | Diretor (ou quem traz a demanda) |
| product owner | agent `po` (valida contra o BRIEF em nome do Diretor) |
| tech lead / architect | Tech Lead = main session |
| engineer | agent `developer` |
| `intent.md` | BRIEF |
| `spec.md` | SPEC (FRs em EARS, ACs em Given-When-Then) |
| `plan.md` | PLAN (COMP, DEC) + TASKs em waves |
| CLAUDE.md | bloco injetado pelo `/keelson:init` + ficha `keelson.config.json` |
| skills (policy) | `guidelines/core/` + perfil de linguagem |
| `REVIEW.md` | `guidelines/core/CODE-REVIEW.md` (régua dos gates 1–7) |
| verifier subagent | `qa` (gate 9) / `code-reviewer` |
| hooks as guardrails/gates | `hooks/*.sh` do plugin |
| evals | `evals/` + `scripts/eval-run.sh` (mantenedor) |
| lessons file | `guidelines/project/lessons/` |
| production gate | fronteira dos commits (PR/merge/deploy do Diretor) |
| control band breach | *(sem equivalente)* |
