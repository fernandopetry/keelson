# Decisões do processo (keelson)

> Memória institucional das decisões sobre como o keelson (spec-driven development) é praticado. Diferente da doutrina de código (QUALITY-CHARTER + perfil ativo, que regem o **código**), este arquivo rege o **processo de desenvolvimento**.

**Última revisão**: 2026-07-23
**Status do documento**: vivo, atualizado conforme decisões evoluem

---

## 1. Visão geral

keelson adota SDD (Spec-Driven Development): a especificação é a fonte da verdade do que deve ser construído. Implementação deriva de SPEC → PLAN → TASKs → código, com gates de qualidade e validação automatizada.

### Por que SDD

- Time multi-pessoa (vários devs via TLs e managers)
- Código com vida útil longa
- Necessidade de rastreabilidade (do requisito ao commit)
- Uso intensivo de IA em geração de código (Claude Code, Agent Teams)

### O que SDD não é

- Não é cascata. SPEC pode evoluir entre ciclos.
- Não é burocracia. Mudanças triviais pulam o ciclo.
- Não é só documentação. Cada artefato é executado por um comando.

---

## 2. Estrutura de pastas

**Lado do projeto** (quem usa o keelson):

```
projeto/
├── keelson.config.json         # a ficha: paths de código, comandos de qualidade, perfil, gates
├── CLAUDE.md                   # contém o bloco gerenciado do keelson (aponta para a ficha)
└── <docsRoot>/                 # docsRoot da ficha; "docs/" por padrão
    ├── _meta/
    │   ├── decisions.md         # este arquivo
    │   ├── method-guide.md      # guia prático de uso dos comandos e skills
    │   └── learning-log.md      # ledger do auto-aprendizado
    └── <slug>/
        ├── INDEX.md             # estado atual do slug (gerado)
        ├── specs/SPEC-NNN-*.md
        ├── plans/PLAN-MMM-*.md
        ├── tasks/
        │   ├── TASK-MMM-INDEX.md
        │   └── TASK-MMM-XXX-*.md
        └── legacy/              # documentação anterior à migração (quando aplicável)
```

**Lado do plugin** (o keelson em si, portável):

```
keelson/
├── commands/                   # /keelson:* (specify, plan, tasks, implement, ...)
├── skills/                     # spec-validator, plan-validator, task-validator, state
├── agents/                     # task-implementer, task-reviewer, security-reviewer, ...
├── hooks/                      # doc-guard.sh, security-guard.sh (leem a ficha)
└── guidelines/
    ├── _meta/                  # QUALITY-CHARTER.md, PROFILE-OUTLINE.md
    ├── core/                   # doutrina agnóstica (SECURITY.md, ...)
    ├── backend/                # perfis de linguagem (php.md, ...)
    └── frontend/
```

---

## 3. Convenção de nomes

**Decisão**: os comandos do keelson são expostos sob o namespace do plugin — `/keelson:<cmd>` — e as skills e agents que acompanham o plugin **não** levam prefixo redundante (o próprio plugin já os agrupa).

**Motivo**: `/keelson:*` agrupa visualmente no tab completion, comunica o intent (é o keelson agindo) e separa dos demais comandos do projeto, sem precisar inventar prefixo. Dentro do plugin, skills e agents ficam com nomes curtos (`spec-validator`, `task-implementer`, `security-reviewer`) porque o pacote já dá o escopo.

**Aplicação**:
- Commands: `/keelson:specify`, `/keelson:plan`, `/keelson:tasks`, `/keelson:implement`, `/keelson:triage`, `/keelson:rebuild-index`, `/keelson:migrate-legacy`, `/keelson:auto`, `/keelson:guided`, `/keelson:refine`, `/keelson:integrate`, `/keelson:jira-sync`, `/keelson:verify-handoff`, `/keelson:audit`
- Skills: `spec-validator`, `plan-validator`, `task-validator`, `status`
- Agents: `task-implementer`, `task-reviewer`, `security-reviewer`, `task-verifier`, `product-critic`, `process-tuner`

**Docs de governança**: `decisions.md`, `method-guide.md` e `learning-log.md` moram em `<docsRoot>/_meta/` (fora do plugin) e não são invocáveis.

---

## 4. Decisões de governança

### 4.1 SPECs são independentes e sequenciais

**Decisão**: SPEC-NNN é numeração sequencial pura, sem supersede automático nem versionamento semântico.

**Consequência**: cada SPEC vale por si. Conflito entre SPECs do mesmo slug é detectado pela leitura humana ou pela skill `status`. Não há resolução automática.

**Risco aceito**: rastreabilidade entre SPECs é responsabilidade do INDEX.md e da skill `status`.

### 4.2 README manual abandonado, INDEX.md automático

**Decisão**: cada slug tem `INDEX.md` mantido **automaticamente** pelos comandos `/keelson:specify`, `/keelson:plan`, `/keelson:tasks` e `/keelson:implement`. Humano não edita.

**Consequência**: INDEX.md é fonte única de "estado atual do slug". Edições manuais são sobrescritas na próxima execução.

**Mitigação para erros**: comando `/keelson:rebuild-index` reconstrói INDEX do zero a partir dos arquivos individuais.

### 4.3 Numeração escopada por nível

- `FR-NNN-XXX`, `NFR-NNN-XXX`, `AC-NNN-XXX`, `RISK-NNN-XXX`: NNN é o número da SPEC.
- `DEC-MMM-XXX`, `COMP-MMM-XXX`, `TRISK-MMM-XXX`: MMM é o número do PLAN.
- `TASK-MMM-XXX`: MMM é o PLAN ao qual pertence, XXX é sequencial dentro do PLAN.

**Consequência**: zero colisão entre IDs do mesmo slug. Trade-off: nomes ficam mais verbosos.

### 4.4 Tipo de TASK declarado no front-matter

**Decisão**: cada TASK tem campo `**Tipo**: feature | bugfix | refactor | chore` no front-matter.

**Convenção de nome de arquivo**:
- `TASK-MMM-XXX-<descricao-kebab>.md` (default: feature)
- `TASK-MMM-XXX-fix-<descricao>.md` (bugfix)
- `TASK-MMM-XXX-refactor-<descricao>.md` (refactor)
- `TASK-MMM-XXX-chore-<descricao>.md` (chore: build, CI, lint)

**Roteamento por tipo**:
- `feature`: vem de PLAN, sai do `/keelson:tasks`.
- `bugfix`: criada via `/keelson:triage` ou direto. Aponta para AC violado.
- `refactor`: criada via `/keelson:triage` ou direto. Critério: zero mudança de comportamento observável.
- `chore`: criada manualmente. Sem vínculo obrigatório com FR.

### 4.5 Slugs legados migrados via comando dedicado

**Decisão**: slugs que existiam antes da adoção do keelson (com README.md mas sem INDEX.md) são migrados via comando dedicado `/keelson:migrate-legacy`, não como feature embutida em outro comando.

**Motivo da separação**: migração é concern temporário (vai parar de ser usado quando o legado acabar). Não deve poluir o `/keelson:triage`, que é concern permanente.

**O que o comando faz**:
- Move arquivos `.md` da raiz do slug para `<docsRoot>/<slug>/legacy/`.
- Cria `INDEX.md` mínimo extraindo informações do README.
- Cria pastas vazias `specs/`, `plans/`, `tasks/`.
- **Não cria** SPECs, PLANs ou TASKs retroativas.

**Marcação no INDEX**:
- Campo `Origem: migrado de legado em <data>`.
- Capacidades implementadas marcadas com 📜 (origem: legacy).
- Decisões eventualmente extraídas marcadas com prefixo `LEGACY-DEC-`.

**Persistência dos achados**: os achados da migração (glossário, decisões, capacidades) vivem em `legacy/TRIAGE-*.md` — a fonte durável — e o INDEX é espelho; o `/keelson:rebuild-index` reespelha as seções legadas a partir do TRIAGE ao reconstruir. Ver LRN-012.

**Política**: aplicação **on-demand**, quando você decide mexer no slug. Não migramos preventivamente.

**Mudanças em slug migrado**: como não há SPEC anterior, qualquer mudança via `/keelson:triage` gera **nova SPEC** (sem supersede). Construímos o histórico keelson daquele slug a partir do ponto da migração.

### 4.6 Documentação autônoma; README por feature descontinuado

**Decisão**: a documentação de uma feature **são** os próprios artefatos keelson (SPEC + PLAN + INDEX). O `README.md` por feature do modelo antigo foi **descontinuado**.

**Distribuição do conteúdo do antigo README**:
- Visão de negócio, regras, permissões por papel → **SPEC**.
- Mapa técnico (arquivos, endpoints, erros) → **PLAN**.
- Estado / progresso → **INDEX** (gerado).

**Documentar é autônomo e inegociável** — em domínio **já coberto** por keelson (tem `<docsRoot>/<slug>/INDEX.md`), nenhum agente pergunta se deve documentar; faz:
- Não-trivial / bugfix / refactor: os comandos `/keelson:*` atualizam o INDEX e fazem closure.
- Trivial (commit direto): o agente registra 1 linha em `## Histórico recente` do INDEX do slug afetado.

**Domínio sem cobertura keelson** (sem `INDEX.md`) — calibrar por natureza da mudança, para evitar atrito e SPEC retroativa (decisão 4.5). **Não** concluir silenciosamente "nada a documentar":
- **Trivial**: seguir sem bloquear e **mencionar** em 1 linha que o domínio não tem slug (sem pergunta).
- **Não-trivial / capacidade nova**: **oferecer** ao humano (decisão dele, não automática) — criar slug via `/keelson:specify`, seguir registrando o débito, ou adiar.
- **Slug legado** (pasta `<docsRoot>/<slug>/` com `.md` mas sem `INDEX.md`): rodar `/keelson:migrate-legacy` antes (regra de ouro #6 / decisão 4.5).

A distinção-chave: "esta *mudança* precisa de doc?" (trivial → não) ≠ "este *domínio* merece cobertura keelson?" (decisão do humano, oferecida quando a mudança é relevante). O hook cutuca; o julgamento de trivialidade e a oferta são do agente/humano.

**Reinterpretação da invariante 4.2**: "INDEX não é editado manualmente" passa a significar *humano não edita*; manutenção pelo comando ou pelo agente (no formato canônico) é o esperado.

**Garantia**: hook `Stop` `hooks/doc-guard.sh` bloqueia o encerramento, uma vez, quando há código de feature alterado (nos `codePaths` da ficha) sem nenhuma atualização na pasta de docs (`docsRoot`). Só o código listado na ficha conta — o que estiver fora dela é ignorado.

**README legado**: `README.md` na raiz de um slug é tratado como legado e migrado por `/keelson:migrate-legacy`.

### 4.7 Execução de código pelo protocolo `/keelson:implement` (rigor proporcional)

**Decisão**: o modo padrão de produzir código é o **protocolo do `/keelson:implement`** (escopo restrito, testes, quality gates, closure), não a edição ad hoc. Aplicado em rigor proporcional ao risco:
- **Feature nova / contrato**: ciclo completo `specify → plan → tasks → implement`.
- **Risco** (auth, segurança, migração/schema, breaking, multi-arquivo) ou que toque slug com PLAN: protocolo formal com TASK avulsa + subagents (`task-implementer` → `task-reviewer`) + closure.
- **Bug / refactor pequeno**: protocolo inline (sem subagent nem arquivo TASK) — implementação focada + testes + auto-revisão pelos gates + registro no INDEX.
- **Trivial**: direto, sem keelson.

**Sem specify/plan/tasks para bug/refactor**: o protocolo aqui é o *modo de executar*, não a criação de SPEC/PLAN/TASK formais.

**Garantia**: regra no bloco keelson do `CLAUDE.md` (sempre em contexto) + reviewer como gate quando aplicável + hook de documentação autônoma. Nenhum hook força o *início* pelo protocolo; a regra do bloco é o mecanismo.

### 4.8 Papéis adicionais no fluxo: segurança, verificação, integração e crítica de produto

**Decisão**: o fluxo ganha quatro papéis para fechar gaps de qualidade, todos em rigor proporcional ao risco:
- **Revisor de Segurança** (`security-reviewer`): gate de segurança, **REJEIÇÃO IMEDIATA**, checklist de `guidelines/core/SECURITY.md` + a seção de segurança do perfil ativo. Gate dedicado em mudança sensível (auth, SQL, upload, dados pessoais, crypto, endpoints, deps); embutido no code review no restante.
- **Verificador Funcional** (`task-verifier`): gate "comportamento verificado" — roda testes e exercita a app quando há efeito observável e ambiente disponível.
- **Integrador** (`/keelson:integrate`): após a DoD, roda a suíte completa e abre o PR. **Não** faz merge nem deploy.
- **Crítico de Produto** (`product-critic`): crítica de **mérito** da SPEC após o `spec-validator` (forma). Não decide.

**Separação de poderes**: quem implementa ≠ revisa código ≠ revisa segurança ≠ verifica ≠ aprova produto ≠ integra/deploya.

**Fronteira IA/humano**: merge, deploy, mudança de configuração de produção, aprovação de produto e promoção de Status permanecem **humanos**.

**Garantia determinística do gate de segurança**: hook `Stop` `hooks/security-guard.sh` detecta mudança sensível (conteúdo/path) nos `sensitiveGlobs` da ficha — comparando o diff da branch contra a base — e bloqueia o encerramento uma vez até a revisão. Respeita `gates.security` da ficha (se `false`, não cutuca). Heurístico (não prova a revisão; cutuca). Par do `doc-guard`.

### 4.9 Slug por domínio: reusar/migrar antes de criar slug novo

**Problema observado**: ao resolver o slug de uma demanda nova (uma faceta financeira de um domínio de pessoas), o `/keelson:specify` criou um slug paralelo (ex.: `people-financials-visibility`) em vez de reconhecer que a demanda é uma **faceta** de um domínio que já existia como slug **legado** (com `.md` na raiz, sem `INDEX.md`). O passo "resolver slug" não tinha detecção de slug de domínio existente, então a regra de ouro #6 ("legado primeiro migra, depois muda") e a leitura do INDEX (que só olha o slug **já escolhido**) nunca dispararam. O agente racionalizou com "capacidades delimitadas viram slugs próprios", confundindo **domínio próprio** com **faceta de domínio existente**.

**Decisão**: a unidade de slug é o **domínio/capacidade de alto nível**, não cada feature incremental. Antes de criar um slug novo, o comando deve varrer `<docsRoot>/` por um slug de domínio relacionado — **inclusive legados** — e:
- slug relacionado com `INDEX.md` → usá-lo;
- slug relacionado **legado** → **migrar primeiro** (`/keelson:migrate-legacy`) e adicionar a SPEC nele; nunca criar slug paralelo para contornar o legado;
- nenhum slug relacionado (domínio genuinamente novo) → propor slug novo e **confirmar com o humano**.

Slug próprio só se justifica para domínio distinto; faceta/regra de um domínio já existente entra no slug do domínio.

**Aplicação**: passo de resolução de slug do `/keelson:specify` e triagem do `/keelson:triage`. Reforça a regra de ouro #6 e a decisão 4.5 (migração de legado).

**Garantia**: instrução explícita nos dois comandos, com o contraste "faceta de um domínio existente" vs "slug paralelo novo". Não há hook determinístico; a robustez vem do passo **obrigatório** de detecção de slug de domínio antes de criar qualquer slug novo.

### 4.10 Modo de execução padrão: ciclo autônomo (full-auto)

**Decisão**: o **modo padrão** de atender um pedido de mudança não-trivial é o **autônomo** (`/keelson:auto`): o agente conduz `specify → plan → tasks → implement → entrega` de ponta a ponta **sem aprovação humana de rotina entre etapas**, parando apenas nas exceções. O fluxo pausado (aprovar etapa a etapa) passa a ser **opt-in** via `/keelson:guided`. O usuário não precisa digitar o comando — basta pedir a tarefa em linguagem natural; o bloco keelson do `CLAUDE.md` declara isso como default.

**Por quê**: reduzir atrito. Analogia do solicitante: "a área de negócio pede e depois vem ver o resultado." Pedir aprovação a cada etapa é caro quando a demanda é clara.

**Fronteira de disparo**:
- Pergunta / análise / leitura de código → resposta normal, **sem** keelson.
- Pedido de modificar/editar/implementar não-trivial → modo autônomo.
- Trivial (typo, copy, cor) → direto, sem keelson.

**Delegação consciente (reinterpreta a regra de ouro #3 / decisão 4.2)**: no modo autônomo, a **promoção de Status** (`Draft → Approved → Done`) é **delegada ao agente** para aquele ciclo. Continua valendo a invariante de que o INDEX é gerado (não editado à mão); o que muda é que o "Approved/Done" deixa de exigir clique humano por etapa quando o usuário optou pelo modo autônomo (o default). No `/keelson:guided`, a promoção volta a depender do OK humano nos checkpoints.

**Rede de proteção preservada (nunca desligada)**: ambiguidade crítica na SPEC, decisão arquitetural **irreversível** (DEC), mudança de **risco** (auth/autorização, schema de banco, exclusão de dados, config de produção), `ERROR` de validator não auto-corrigível, quality gate que falha após 1 retry e achado de **segurança** **sempre param e perguntam**. **Merge e deploy permanecem humanos** — a fronteira IA/humano da decisão 4.8 não muda. *(Recalibrada pela decisão 4.11: a régua de pausa passou a ser reversibilidade × divergência, com perguntas adiáveis em lote.)*

**Entrega**: o modo autônomo cria/usa uma **branch** (`feat/<slug>-<curto>`, nunca direto na `main`), commita e faz **push** para revisão — **sem abrir PR** (perfil dev-solo). `/keelson:integrate` (com PR) continua disponível quando se quiser PR.

**Garantia**: comportamento descrito em `commands/auto.md` (fonte de verdade) e tornado default pela regra no bloco keelson do `CLAUDE.md`. Sem hook determinístico; a robustez vem da regra sempre em contexto + os quality gates e validators já existentes, que não foram afrouxados.

### 4.11 Régua de interrupção do autônomo: reversibilidade × divergência, com pergunta adiável

**Decisão (do humano)**: no modo autônomo, a régua de "parar e perguntar" deixa de ser a **categoria** da mudança (qualquer coisa que toque auth/schema/produção) e passa a ser **reversibilidade × divergência de caminhos**:

- **Depende de resposta humana antes de aplicar**: ação **destrutiva ou de difícil reversão** (exclusão/alteração de dados existentes, `DROP`/`ALTER` destrutivo, config de produção, DEC irreversível), ambiguidade cujas opções levam a **caminhos muito distintos**, e achado de **segurança** (este pergunta na hora, sempre).
- **Pergunta adiável**: quando a parte que exige resposta **não bloqueia** os próximos passos, ela fica **estacionada** (não aplicada) e a pergunta é feita **em lote na Entrega** — o fluxo não para. **Estacionar = não aplicar**; nada estacionado entra no código sem resposta.
- **Decide sozinho**: mudança sensível porém **simples e reversível** (auth/schema de rotina — coluna nullable, permissão nova no padrão do catálogo), riscos do critic que não mudam a direção do produto, DEC reversível — sempre **registrando** (premissa `[assumido]`, DEC) e **destacando no relatório final**.

**Caminho tomado (novo, obrigatório)**: o report da Entrega ganha a seção **"Caminho tomado"** — 1 linha por decisão tomada em autonomia (decisão + por quê) — e a etapa de **perguntas estacionadas em lote**. É a contrapartida da autonomia maior: o humano revisa o caminho no final e pede ajuste no que discordar.

**Por quê**: a régua por categoria pausava em escolhas óbvias e reversíveis (ex.: coluna nullable), gastando interrupção humana sem risco real; e as decisões autônomas ficavam enterradas na SPEC/PLAN, sem visão consolidada para revisão.

**O que não muda**: rigor e gates (decisão 4.10), gate de segurança com rejeição imediata, merge/deploy humanos (4.8), e o `/keelson:guided` — que mantém a régua estrita por ser o modo opt-in de acompanhamento.

**Aplicação**: `commands/auto.md` (fonte de verdade) e o bloco keelson do `CLAUDE.md` (rede de proteção). Recalibra a "Rede de proteção" da decisão 4.10. *(Recalibrada pela decisão 4.13: as perguntas do auto concentram-se na última chamada e no lote da Entrega; interrupção no meio do fluxo virou último caso.)*

### 4.12 Rota inline: prova externa falsificável (gerador ≠ avaliador)

**Decisão (do humano)**: na rota inline (bug/refactor pequeno), a auto-revisão pelos gates **não é prova de pronto**. A prova é **externa e falsificável** — teste cobrindo o comportamento. Mudança qualitativa sem teste possível (ex.: refactor de legibilidade) → 1 passada de revisão independente com contexto limpo (ex.: `/code-review` em effort baixo) em vez do auto-checklist.

**Por quê**: autoavaliação infla o resultado (gerador = avaliador na mesma sessão); os gates de julgamento (escopo, aderência, review qualitativo) auto-aplicados eram o ponto fraco da rota barata. Os gates de teste já eram avaliador independente por natureza — a decisão explicita que **eles** são a prova, e cobre o caso sem teste possível. Não reintroduz subagent obrigatório na rota inline (Calibração de Esforço preservada).

**Origem**: confronto do fluxo com material externo sobre trabalho orientado a objetivos (separação gerador/avaliador). No mesmo pacote, dois ajustes de processo registrados no ledger: calibração por exemplares nos avaliadores qualitativos (LRN-010) e não-vinculância da "Implementação sugerida" nas TASKs (LRN-011).

**Aplicação**: bloco keelson do `CLAUDE.md` (Execução de Código) e o QUALITY-CHARTER (régua "gerador ≠ avaliador").

### 4.13 Modo ausente no autônomo: última chamada + escada de reação (recalibra 4.11)

**Decisão (do humano)**: o `/keelson:auto` simula o cenário real "o solicitante pede, tira as dúvidas, vai embora e volta para ver a entrega". Duas mudanças:

1. **Última chamada (Etapa 0.5)**: antes da largada, uma **rodada única** de até 4 perguntas críticas (disciplina do `/keelson:refine`: pedido claro → zero perguntas; demanda vinda do refine não repergunta). Encerrada a rodada, o agente **anuncia** que segue sozinho até a Entrega ("pode deixar comigo").
2. **Escada de reação pós-largada** (substitui o "na hora" da 4.11 dentro do auto): (1º) **decidir** a opção segura e reversível, registrando no "Caminho tomado"; (2º) **estacionar** a parte — até a feature inteira, se não for isolável — e perguntar em lote na Entrega (generalização do padrão de handoff do gate 9: entrega parcial estruturada vence pergunta pendurada); (3º) **interromper só em último caso**, quando errar contaminaria o ciclo inteiro, não há premissa reversível defensável e nada é entregável sem a resposta.

**Por quê**: pergunta no meio do fluxo com o humano ausente não protege — pendura o trabalho (nem entrega, nem avança), e o solicitante volta para encontrar uma pergunta parada em vez de uma entrega (ainda que parcial).

**O que não muda**: nada destrutivo/irreversível é aplicado sem resposta (estaciona — nunca "decide"); vulnerabilidade nunca entra na branch; merge/deploy humanos (4.8); os gates não são afrouxados (4.10); o `/keelson:guided` mantém a régua estrita de perguntar na hora (humano presente por definição).

**Trade-off aceito**: menos paradas = mais risco de premissa errada custar retrabalho; a contrapartida é a prova por teste falsificável, o "Caminho tomado" consolidado e a entrega em branch (errar custa um ajuste de revisão, não um rollback de produção).

**Aplicação**: `commands/auto.md` (Etapa 0.5 + escada em Exceções — fonte de verdade) e `commands/guided.md` (explicita a régua estrita própria).

### 4.14 Espelho do entendimento: o prompt confirmado é o contrato (complementa 4.13)

**Decisão (do humano)**: na largada do `/keelson:auto`, além das perguntas da última chamada, o agente **reescreve o pedido** de forma organizada e acessível — formato canônico do prompt refinado do `/keelson:refine` (Contexto / Pedido / Premissas decididas / Fora de escopo), na linguagem do solicitante, legível em ~30 segundos — e **valida o entendimento** antes de seguir. O espelho confirmado **substitui o pedido original** como fonte da demanda: a SPEC nasce dele.

**Por quê**: o pedido chega desordenado, e o erro mais caro não é a dúvida não perguntada — é o detalhe entendido *diferente* sem que ninguém perceba a ambiguidade. O espelho custa ~30 segundos do solicitante (que ainda está presente) contra um ciclo perdido por interpretação errada; é a oportunidade de ele verificar se transferiu o que estava na cabeça.

**Calibração anti-atrito** (para não recriar o atrito que o 4.10 eliminou): feature/risco → espelho completo com confirmação, no máximo **1 rodada de ajuste**; bug/refactor pequeno → espelho de 1–2 linhas na mensagem de largada, sem confirmação; trivial → sem espelho; demanda vinda do `/keelson:refine` → pula (já confirmada lá).

**Um dono por regra**: o formato do prompt refinado pertence ao `/keelson:refine` (passo 4); o auto o referencia, não o duplica.

**Aplicação**: `commands/auto.md` (Etapa 0.5) e `commands/refine.md` (formato canônico). Relacionada: decisão em aberto sobre um agente dedicado `request-mirror` (§8).

### 4.15 Code review forçado fora do fluxo SDD: review-guard com limiar

**Problema**: quando o desenvolvedor trabalha sem os comandos `/keelson:*` (edição ad hoc via Claude Code), os gates de review do `/keelson:implement` nunca disparam — só docs (doc-guard) e segurança (security-guard) tinham garantia determinística. Code review geral (gate 7) dependia de disciplina.

**Decisão**: hook `Stop` `hooks/review-guard.sh` detecta mudança de código na branch (diff contra merge-base, filtrado pelos `codePaths` da ficha) **acima de um limiar** e bloqueia o encerramento uma vez, exigindo o code review (`task-reviewer` sobre o diff OU checklist de `guidelines/core/CODE-REVIEW.md` + perfil ativo).

**Limiar (Charter Art. 6 — rigor proporcional)**: dispara com ≥ 2 arquivos de código alterados OU ≥ 30 linhas adicionadas; abaixo disso a mudança é trivial e passa sem cutucar. Configurável na ficha via `gates.reviewThreshold: { files, lines }`; o gate inteiro desliga com `gates.review: false` (default: ligado).

**Natureza**: como os irmãos — heurístico no sentido de que não *prova* que a revisão rodou (cutuca para forçá-la); anti-renudge por fingerprint em `.git/` (mesma mudança não re-bloqueia); fallback gracioso sem `jq`/ficha. Terceiro da família doc-guard (4.6) / security-guard (4.8).

### 4.16 Gate de segurança: superset OWASP multi-edição + CVE por ferramenta

**Problema**: o checklist de `guidelines/core/SECURITY.md` usava a taxonomia OWASP 2021 de facto, sem citar edição; categorias que mudam entre edições ficavam sem dono nomeado (Supply Chain promovida a A03 em 2025, Mishandling of Exceptional Conditions criada em 2025, CSRF extinta como categoria desde 2013 mas ainda relevante). E não havia noção de vulnerabilidade **conhecida** (CVE/NVD): a única auditoria concreta era `composer audit` no perfil PHP; projeto sem perfil ficava sem auditoria **em silêncio**. (Origem: sugestão externa avaliada — "OWASP Top 10 de todos os anos" + "procurar CVEs no NVD".)

**Decisão (do humano)**:
- **Superset consolidado, não N listas por ano**: tabela única ano-agnóstica com a **união** das categorias de todas as edições (2003→2025) e coluna de mapeamento (`A06:2021 · A03:2025`), com link para o repositório oficial das edições. Colar as listas por ano duplicaria ~80% do conteúdo (parcimônia do Charter).
- **CVE por ferramenta local, nunca de memória**: o `security-reviewer` roda a auditoria do ecossistema via Bash (advisory databases sincronizam com o CVE/NVD) e **cita o CVE/advisory ID vindo da saída da ferramenta** (campo `cve` no report). LLM não afirma nem descarta CVE de memória (alucinação). Nenhuma ferramenta disponível → achado `media` "auditoria indisponível" (**fail-visible**, não bloqueante sozinho). Consulta online ao NVD dentro do gate foi descartada (lento/sujeito a falha de rede).
- **Dependência é sensível por definição**: o `security-guard.sh` passa a disparar também quando o diff da branch toca manifesto/lockfile de dependência, independente dos `sensitiveGlobs` — "mudança de dependências" já era gatilho declarado do gate 8, mas sem garantia determinística.

**Sincronia**: CSRF e `samesite` estavam no checklist do agente mas não nomeados no core (dessincronia corrigida — CSRF agora é linha do superset, dona única da regra); `PROFILE-OUTLINE.md` §8 passa a exigir que todo perfil nomeie a ferramenta de auditoria e o advisory database que ela consulta.

**Aplicação**: `guidelines/core/SECURITY.md` (superset + seção *Dependências & CVE (NVD)*), `agents/security-reviewer.md` (checklist sincronizado + seção *Auditoria de dependências*), `guidelines/_meta/PROFILE-OUTLINE.md` §8, `guidelines/backend/php.md` §8, `hooks/security-guard.sh`. Charter **intocado** (Art. 2 não muda; a doutrina o instancia melhor). Plugin 0.3.1 → 0.4.0.

### 4.17 `/keelson:audit`: auditoria de dependências fora do ciclo de task (complementa 4.16)

**Problema**: a auditoria de CVE da decisão 4.16 é disparada por **diff** (mudança de dependências no gate 8; uma rodada na entrega via `/keelson:integrate`). Isso cobre a *introdução* de pacote vulnerável, mas nunca o *envelhecimento*: CVE publicado **depois** de a dependência entrar não aparece em diff nenhum — o lockfile não mudou. Cobrir isso apertando o gate por task seria desperdício (auditar a cada geração de código sem mudança de pacote) com cobertura ruim.

**Decisão (do humano)**: novo comando **`/keelson:audit [full]`** — auditoria manual de dependências em **momento oportuno escolhido pelo humano** (começo de ciclo, antes de entrega grande, projeto parado). Por padrão só vulnerabilidade conhecida (CVE); `full` inclui higiene (desatualizados, abandonados, licenças), reportada em bloco separado sem inflar severidade. Herda a doutrina da 4.16: resolve a ferramenta pela §8 do perfil ativo (fallback: detecção de lockfile, multi-ecossistema), CVE citado **da saída da ferramenta** (nunca de memória), ecossistema sem ferramenta → `INDISPONÍVEL` fail-visible (não instala nada sozinho).

**Fronteiras**: o comando **não atualiza dependência** — achado vira **oferta de demanda** de upgrade pelo ciclo normal (upgrade toca lockfile → gate 8 dispara). E não substitui cobertura contínua: é pull-based (só roda se alguém rodar); o próprio report lembra que Dependabot/Renovate ou CI agendada são o instrumento de calendário — divisão de trabalho: **o gate cobre a introdução (evento de diff), a plataforma cobre o envelhecimento (evento de calendário), o `/keelson:audit` é o instrumento manual entre os dois**.

**Aplicação**: `commands/audit.md` (novo), nota "Quando roda" em `guidelines/core/SECURITY.md`, §3.12 do `method-guide.md`, lista de comandos do `templates/CLAUDE.keelson-block.md`. Entra na 0.4.0 junto com a 4.16.

### 4.18 Rename: `/keelson:change` → `/keelson:triage`

**Problema**: todos os comandos são verbos que descrevem **a ação do comando** (`specify` especifica, `plan` planeja, `audit` audita) — mas `change` não muda nada: ele classifica e roteia. O nome descrevia o *input* ("tenho uma mudança") em vez da *ação*, sugerindo o oposto do princípio do comando ("classifica, não executa"). A própria doutrina já usava o vocabulário certo em toda parte: a description dizia "faz **triagem**", o output se chamava `# Triagem:`, o §3.5 do method-guide se chamava "triagem de demanda nova" — só o nome do comando tinha ficado para trás.

**Decisão (do humano)**: renomear para **`/keelson:triage`** — descreve a ação, mantém o padrão verbo-inglês e é cognato de "triagem", o termo consagrado na doutrina. **Corte limpo**, sem stub de depreciação: o plugin está em 0.x declarado "early" e o custo de renomear nunca será menor; um stub seria inchaço com data de remoção que alguém precisaria lembrar.

**Alternativas descartadas**: `route` (descreve o resultado, não a análise), `classify` (correto porém burocrático), `intake` (menos óbvio), manter `change` (perpetua o desalinhamento).

**Aplicação**: `commands/change.md` → `commands/triage.md` (git mv) + atualização de todas as referências (README, method-guide, CLAUDE.keelson-block, WORKFLOW.md, skills/status, commands que o citam, este arquivo). Entra na 0.4.0.

### 4.19 Perfis PHP legados embarcados + resolução de versão pelo mais próximo abaixo

**Problema**: o plugin embarca um único perfil PHP (8.5, exemplar). Projeto consumidor em versão legada (5.6, 7.x, 8.0 — onde o legado real estaciona) recebia perfil gerado na hora pelo `profile-writer`, `reviewed: false`, com as inferências de segurança por confirmar — justamente nas versões EOL, onde doutrina de segurança refinada mais importa (sem patch de segurança, `mcrypt`, sem `strict_types` em 5.6). E não havia regra explícita de **qual base usar** quando a versão detectada não tem perfil exato.

**Decisão (do humano)**: embarcar uma **escada de perfis PHP legados** curados — **5.6, 7.0, 7.4 e 8.0** (`guidelines/backend/php-<versão>.md`) — escolhidos por "onde o mundo legado parou", não por intervalo regular: 5.6 fecha a linha 5.x; 7.0 é o piso da era 7; 7.4 é onde a maioria do legado 7.x estacionou; 8.0 é o divisor da era 8 (entre 8.0 e o exemplar 8.5 o delta é incremental). Rascunhos nascem do `profile-writer` com o exemplar como referência de rigor e cada um é promovido a `reviewed: true` por revisão humana individual.

**Regra de resolução (a base vem sempre POR BAIXO)**: no `/keelson:init`: (1) perfil embarcado exato → ativa direto; (2) sem exato → a base é o perfil embarcado **mais próximo abaixo** da versão do projeto, e o `profile-writer` escreve só o **delta** (o que a versão do projeto adiciona); (3) sem nenhum abaixo → gerar do zero, usando o mais próximo acima apenas como referência de formato/rigor, nunca como fonte de recomendação de recurso. Motivo: perfil **recomenda recursos**; base de versão maior recomenda o que não existe no projeto (código que passa no lint e quebra em runtime — aviso do próprio exemplar); base de versão menor só recomenda o que existe, e o delta é trabalho aditivo seguro.

**Custo assumido**: cada perfil replica a espinha do charter (seções 0–12) e carrega `charter:` no frontmatter — mudança de charter passa a reconciliar ~6 perfis, não 1. Aceito: o refino centralizado (sobretudo a §6 de segurança em versão EOL) paga o custo. O exemplar permanece `php.md`, sem rename — fichas de consumidores já referenciam `plugin:backend/php.md`.

**Aplicação**: `guidelines/backend/php-{5.6,7.0,7.4,8.0}.md` (novos, `reviewed: false` até revisão), Etapa 3 de `commands/init.md` (regra de resolução), `agents/profile-writer.md` (modo derivação com base embarcada), `README.md` (conceito de perfis, layout, status). Plugin 0.4.0 → 0.5.0.

### 4.20 Enxugamento anti-redundância: capacidade nativa do harness não se re-instrui

**Problema**: o corpus de instrução do plugin (~10k linhas) acumulou dois tipos de gordura à medida que o harness do Claude Code ficou mais capaz: (1) **duplicação entre artefatos** — o template do INDEX copiado em 3 comandos, a resolução de perfil em 5–6, a receita de atualização do INDEX em 4, a moldura dos 3 validators (~metade de cada SKILL.md), o checklist de `SECURITY.md` reimpresso no `security-reviewer`; (2) **defensividade que o modelo moderno dispensa** — checklists de "validação manual final" que só reafirmam o corpo, passos "reler para confirmar que gravou", micro-instruções de ferramenta ("use Bash/Glob/Read"), roteiros literais de mensagens, closers rituais ("Agora processe…") e seções `Limites` que recapitulam princípios já declarados (caso extremo: a mesma regra 8× no `auto.md`). Redundância não é neutra: dilui a doutrina real e cria N lugares para dessincronizar.

**Decisão (do humano)**: princípio de escrita dos artefatos — **instrução só onde há doutrina ou limiar próprio; capacidade nativa do harness não se re-instrui**. Aplicações estruturais:
- **Donos canônicos no method-guide**: §3.0 (convenções comuns dos comandos — ficha primeiro, resolução de perfil, memo de exploração, resolução de slug, merge/deploy humanos, protocolo 1-retry) e §6 (template canônico do INDEX + receita de atualização); os comandos apontam com 1 linha em vez de copiar.
- **Validators**: moldura comum (calibração por exemplares, setup, severidades/auto-fix, gate de status/override, relatório, `evento_aprendizado`, limites) extraída para `skills/_shared/validator-protocol.md`; cada SKILL.md fica só com os checks do seu artefato.
- **`security-reviewer` lê o gabarito em runtime** (`Read` em `core/SECURITY.md` + seção 6 do perfil ativo) em vez de replicar o checklist — **revoga a regra de sincronia manual** que vivia no `CLAUDE.md` do repo. Custo: um Read por invocação do gate; ganho: zero risco de dessincronia.
- **Entre agents, dedup só quando compensa o Read**: schema pequeno (ex.: `licao_candidata`, ~8 linhas) permanece inline nos 3 agents — extrair para arquivo externo trocaria 8 linhas por um Read em runtime.
- **Fora do corte, por decisão do humano**: os 4 hooks ficam (o gatilho determinístico no Stop não tem equivalente nativo) e `guidelines/` inteiro fica intacto por enquanto (doutrina distribuída aos consumidores).

**Aplicação**: `commands/*` (14 arquivos), `agents/*` (6 de 7 — `profile-writer` já enxuto, intocado), `skills/*` (5 SKILL.md + `skills/_shared/validator-protocol.md` novo), `templates/CLAUDE.keelson-block.md`, `docs/_meta/method-guide.md` (§3.0 novo, §6 ampliado), `CLAUDE.md` do repo. Redução líquida ≈ 780 linhas. Ajuste fino sem capacidade nova → patch: plugin 0.5.0 → 0.5.1.

### 4.21 Doutrina de nomenclatura do namespace + renames `guiado` → `guided` e `state` → `status`

**Problema**: a decisão 4.18 fixou o princípio de nomenclatura ("o nome descreve a ação do comando, verbo em inglês") apenas implicitamente, ao renomear um comando; a convenção completa nunca foi registrada. Uma auditoria dos 26 nomes do namespace (14 comandos, 5 skills, 7 agents) encontrou uma incoerência real — `/keelson:guiado`, único nome em português de todo o namespace — e um desvio idiomático — a skill `state`, quando `status` é o consagrado de CLI para "mostrar o estado" (`git status`).

**Decisão (do humano)** — convenção de nomenclatura do namespace:
- **Comandos de ação**: verbo em inglês que descreve a ação (`specify`, `plan`, `implement`, `init`, `refine`, `triage`, `integrate`, `audit`); com objeto quando a precisão pedir (`migrate-legacy`, `rebuild-index`, `verify-handoff`).
- **Etapas do ciclo** podem nomear o artefato que produzem — exceção consciente: `tasks` (substantivo) preserva o mnemônico `specify → plan → tasks → implement`.
- **Modos de condução** são nomeados pelo modo, não pela ação: `auto` / `guided` — o eixo autônomo × acompanhado é a informação que os distingue.
- **Skills e agents**: `<objeto>-<papel>` (`spec-validator`, `task-implementer`, `security-reviewer`, `process-tuner`, `profile-writer`). Exceção deliberada: `screen-verify` espelha o nome do gate `gates.screenVerify` da ficha — renomeá-la quebraria fichas de consumidores (`"method": "skill:screen-verify"`).
- **Renames aplicados** (corte limpo sem stub, padrão 0.x da 4.18): `/keelson:guiado` → **`/keelson:guided`** e skill `state` → **`status`**.
- **Auditados e mantidos**: `tasks` (simetria do ciclo vence a pureza do verbo), `auto` (par de modos), `integrate` (não faz merge, mas a fronteira é documentada em voz alta no comando e no PR; `submit` descartado — ganho não paga o churn), `audit` (nome curto; o escopo de dependências está na description e no argumento `full`).

**Aplicação**: `commands/guiado.md` → `commands/guided.md` e `skills/state/` → `skills/status/` (git mv) + atualização de todas as referências (README, method-guide, CLAUDE.keelson-block, WORKFLOW.md, commands que os citam, este arquivo). Rename = quebra → plugin 0.5.1 → 0.6.0.

### 4.22 Integração opcional com Jira via conector MCP Atlassian

**Problema**: times que já usam o Jira como quadro de trabalho não têm ponte entre os artefatos SDD do keelson (SPEC, TASKs) e as issues do Jira — o rastreio é manual e duplicado. O keelson não tem hoje onde guardar um ID externo (o closure da TASK só carrega `Commit SHA` e `Notas`), nem qualquer efeito colateral externo de escrita além de `git push`/`gh pr create`.

**Decisão (do humano)** — integração **opcional, best-effort**, com estas regras:
- **Mecanismo**: conector **MCP Atlassian**, nunca API/token direto. O keelson emite instruções e o agente usa as ferramentas do conector (`createJiraIssue`, `transitionJiraIssue`, `addCommentToJiraIssue`, `createIssueLink`, `getJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields`, `getTransitionsForJiraIssue`…). **Zero segredo** no repositório (nem na ficha nem em `keelson.local.json`); nenhum SDK no consumidor.
- **Best-effort inviolável**: a sincronização **nunca bloqueia** o ciclo SDD. Bloco ausente/`enabled:false`, conector indisponível (não autorizado, headless), ou operação Jira que falha (permissão, campo obrigatório, transição inexistente) → **avisa e segue**, mesma filosofia do fallback gracioso dos hooks (`sem jq → exit 0`). Essencial porque o `/keelson:auto` roda de ponta a ponta e não pode travar por serviço externo.
- **Público e agnóstico**: nenhum artefato versionado do plugin (templates, README, este arquivo, protocolo, exemplos) embarca dado de empresa (site, `projectKey`, `cloudId`, IDs de tipo/status/campo, componentes, nomes). Tudo específico de um projeto é **descoberto em runtime** (createmeta / amostragem de status) e gravado **no repo do consumidor** (ficha + mapa `.md`); templates e exemplos usam placeholders neutros (`PROJ`, `your-site.atlassian.net`, `customfield_XXXXX`, `<PROJECT>`, `<id>`).
- **Config por ID, não por nome**: o bloco `jira` da ficha guarda **IDs** de issue type e status (nomes são localizados e ambíguos, variam por projeto), resolvidos pelo `init` via `getJiraProjectIssueTypesMetadata`. Sem defaults hardcoded (`"Story"`/`"Sub-task"`/`"Done"` não são universais).
- **Dois modos**: `create` (cria a issue da SPEC + uma sub-task por TASK — ideal para projeto limpo/team-managed) e `link` (pendura numa issue existente informada no front-matter da SPEC — ideal para projeto governado/company-managed).
- **Persistência das keys**: front-matter da SPEC (`Jira:`) e novo campo no bloco de closure da TASK; o INDEX registra só no "Histórico recente" — o contrato da tabela "PLANs" (§6 do method-guide) fica intocado.
- **Não mover o card por padrão**: transição de status é frágil em company-managed (transições condicionais, com tela, sem "Done" real). Default `transition:comment` (comenta progresso, não move o card); `auto` é opt-in por projeto, resolvido em runtime via `getTransitionsForJiraIssue`. As **colunas do board não são legíveis** pelo conector (Agile API fora do escopo) → o humano declara um mapa acionável (etapa keelson → coluna + status-alvo por ID) no `.md` do projeto, semeado pelo `init` a partir da `statusCategory` (new/indeterminate/done); atua só em `auto`, com o alvo validado em runtime.
- **Campos personalizados**: descobertos por `getJiraIssueTypeMetaWithFields` (nunca hardcode de `customfield_*`); enriquecimento **opt-in** e **bidirecional** via mapa `.md` por projeto gerado pelo `init` (escrita: `fixed`/`from`; leitura: semeia SPEC/TASK no modo `link`). Custom fields tipicamente não são obrigatórios na criação → `summary`+`description` bastam como mínimo.
- **Um dono por regra** (decisão 4.20): a lógica de sync vive em `skills/_shared/jira-sync-protocol.md`; os comandos do ciclo apenas a referenciam. `guidelines/` não muda (integração externa é capacidade do motor, não doutrina de qualidade de código).

**Custo assumido**: primeira integração externa de **escrita** do keelson além do git/GitHub — passa a existir efeito externo em 4 comandos do ciclo + 1 comando novo (`jira-sync`). Mitigado pelo best-effort e pela idempotência (checar a key gravada antes de criar). A superfície de dessincronia cresce (bloco de ficha novo, mapa `.md` por projeto, ganchos em 5 comandos), aceita em troca da rastreabilidade SDD→Jira automática para quem opta.

**Aplicação**: `templates/keelson.config.example.json` (bloco `jira`), `commands/init.md` (Etapa 4.6 — resolução via createmeta + amostragem de status + geração do esqueleto do mapa `.md`), `skills/_shared/jira-sync-protocol.md` (novo, dono único da lógica), `commands/{specify,tasks,implement,integrate,auto}.md` (ganchos + campo `Jira:`), `commands/jira-sync.md` (novo) + os 4 lugares de comando (README tabela *Commands*, method-guide §3.13, `templates/CLAUDE.keelson-block.md`, este arquivo §3), nova subseção "Jira integration (optional)" no `README.md`. Capacidade nova → minor: plugin 0.6.0 → 0.7.0.

### 4.23 Fôlego não é gatilho: o /keelson:auto corre até a Entrega, sem "ponto limpo" entre waves

**Problema**: em execuções longas (overnight), o `/keelson:auto` parava entre waves (ex.: 2 de 6 concluídas) declarando "ponto limpo autorizado porque o build ficou longo" e encerrando o turno com a pergunta "continuo na próxima wave ou você revisa primeiro?" — que ficava pendurada a noite inteira, exatamente o anti-padrão que a escada de reação existe para impedir. Duas brechas textuais permitiam a racionalização: a escada enumerava os gatilhos legítimos mas **não negava os ilegítimos** (duração da sessão, contexto, tokens, "ponto limpo"), e o degrau 2 ("estacionar a feature inteira também vale") dava álibi para entrega parcial voluntária. O `/keelson:implement` tampouco dizia que o loop de waves só termina na última wave ou em falha.

**Decisão (do humano, ao reportar o comportamento)**: **fôlego nunca é gatilho da escada.** Duração da sessão, número de waves restantes, tamanho do contexto/custo de tokens e "ponto limpo para parar" não são dificuldade nem risco; terminada uma wave, a próxima começa imediatamente, e perguntar "continuo?" entre waves é aprovação de rotina (proibida no modo auto). Parada antecipada exige pedido **explícito do humano na execução corrente** ("pare depois da wave N") — comentário genérico de conversa anterior não é autorização permanente. O degrau 2 fica restrito aos gatilhos da própria linha (irreversibilidade, vulnerabilidade persistente, ambiguidade divergente), nunca a fôlego.

**Aplicação**: `commands/auto.md` (parágrafo "Fôlego não é gatilho" nas Exceções + emenda no degrau 2), `commands/implement.md` (§3.6 item 5 — o loop de waves só termina na última wave ou em falha listada), `learning-log.md` LRN-018. Entra na leva 0.8.0, junto com a 4.24.

### 4.24 Guarda mecânica de waves: run-state em disco + hook Stop `wave-guard`

**Problema**: a decisão 4.23 corrige por instrução, mas instrução mora no contexto do modelo — numa execução overnight o contexto é sumarizado e a regra "não pare entre waves" pode se perder do resumo, reabrindo a reincidência da LRN-018. Os artefatos SDD já guardam *o que* retomar; faltava um sinal **fora do contexto** dizendo que há um run em andamento.

**Decisão (ideia do humano)**: estado de run em disco + verificação determinística no encerramento do turno. O `/keelson:implement` mantém `thoughts/local/run-state-<slug>.md` (formato canônico no method-guide §3.0, dono único): criado antes da primeira wave, `waves_concluidas` atualizado a cada final de wave, encerrado na Entrega (removido pelo `/keelson:auto` após o push; marcado `encerrado` pelo implement avulso). O hook Stop `wave-guard` lê o arquivo — imune à sumarização — e **bloqueia o encerramento** enquanto `status: em_andamento`, devolvendo a instrução de retomada (INDEX + TASK-INDEX) ou de registro de parada legítima (`status: encerrado — <motivo>`). O guard não julga mérito da parada: garante que parar seja ato deliberado e registrado, nunca esquecimento ou "ponto limpo" inventado. Fallback gracioso (sem python3/cwd/arquivo → `exit 0`) e `stop_hook_active` anti-loop, no padrão dos demais hooks.

**Aplicação**: `hooks/wave-guard.sh` (novo) + registro em `hooks/hooks.json`; convenção do run-state no method-guide §3.0; ganchos em `commands/implement.md` (criação na Etapa 3, atualização no §3.6, encerramento na Etapa 5) e `commands/auto.md` (remoção na Entrega após o push + referência no "Fôlego não é gatilho"). Validado com `bash -n` + 5 cenários sintéticos no scratchpad (bloqueia em `em_andamento`; passa com `stop_hook_active`, `encerrado`, sem arquivo, sem `cwd`). Resolve a pendência "wave-guard" da §8. Hook novo = capacidade nova → minor: plugin 0.7.0 → 0.8.0.

### 4.25 Verificação de tela multi-realm: realms nomeados no `keelson.local.json`

**Problema**: o `keelson.local.json` modelava um único acesso (`baseUrl` + `login` direto), mas surgiu projeto consumidor com **duas áreas logadas** — a administrativa e um portal de usuários não-admin, com URL e usuário distintos. Sem noção de realm, a verificação de tela não sabe qual credencial usar em qual tela; e o atalho tentador (logar como admin para olhar o portal) **mascara exatamente os bugs de autorização/isolamento** que o gate existe para pegar.

**Decisão**: `screenVerify.realms` nomeados no `keelson.local.json` — cada realm com `description` (do que se trata o acesso), `baseUrl` e `login` próprios, mais `defaultRealm`; o formato flat legado segue aceito como realm único implícito (nenhum consumidor quebra; o `/keelson:init` migra merge-preserving). Regras: **seleção** pelo campo `Realm` do item do roteiro/pedido do humano, ou casamento da rota alvo com a `baseUrl` mais específica — sem casamento, pergunta, nunca chuta credencial; **isolamento** não-negociável (credencial do realm X só no login do realm X; aba própria por realm; nunca reusar sessão de um realm noutro); itens **negativos cross-realm** ("sessão do portal em rota admin → negado") viram itens V* legítimos. A ficha versionada não muda (`gates.screenVerify.{enabled, method}`): o que cada acesso é fica no local.json, junto das credenciais, fora do git.

**Aplicação**: `templates/keelson.local.example.json` (formato realms), `skills/screen-verify/SKILL.md` (schema + seleção + isolamento), `commands/init.md` (pergunta de realms na Etapa 2; Etapa 4.5 com migração flat→realms), method-guide §8.2 (campo Realm no item V*), `agents/task-verifier.md` (`handoff_seed.itens[].realm`), `commands/implement.md` (consolidação preserva realm; dedup por fluxo+realm), `commands/verify-handoff.md` (exercício por realm do item). Capacidade nova → minor: plugin 0.8.0 → 0.9.0, na mesma leva da 4.26.

### 4.26 Prova de indisponibilidade: gate 9 só vira handoff com sondagem falhada e registrada

**Problema**: execução real do `/keelson:auto` declarou "não dá para exercitar o SPA nesta sessão" e converteu o gate 9 em handoff **sem nenhuma tentativa** — o `keelson.local.json` estava presente e o browser disponível; o humano precisou apontar o arquivo manualmente (LRN-019). A doutrina proibia o atalho ("handoff é fallback, não atalho") mas sem dente: nenhum artefato exigia **prova** da indisponibilidade, o `ambiente_indisponivel` do verifier era auto-declarável, e o conhecimento de que as credenciais vivem no `keelson.local.json` estava enterrado na skill `screen-verify` — carregada só **depois** da decisão de verificar (circularidade).

**Decisão (do humano, ao reportar o comportamento)**: indisponibilidade de tela é **afirmação que se prova**, no mesmo padrão do check determinístico de pendência de deploy. Antes de `pendente_handoff`, sondagem barata obrigatória: o `keelson.local.json` existe com os dados do realm alvo? a `baseUrl` do realm responde (ou a app sobe pelo método do projeto)? a sessão tem ferramenta de tela? Só a sondagem **falhando, com evidência registrada** (report do verifier `evidencia_indisponibilidade`; front-matter `sonda:` do handoff) autoriza o handoff — seed sem evidência é report rejeitado. Multi-realm (4.25): sonda por realm envolvido no roteiro, e um realm de pé com outro caído gera pendência só do indisponível.

**Aplicação**: method-guide §8.1 (dono do ciclo de vida — sondagem na Detecção) e §8.2 (`sonda:` no front-matter), `agents/task-verifier.md` (fluxo 2 + campo `evidencia_indisponibilidade` obrigatório), `commands/implement.md` (gate 9 rejeita seed sem sondagem), `commands/auto.md` (Etapa 4.6 — sondagem antes do gatilho; item 4 sem sondagem não vale). Origem: LRN-019. Mesma leva 0.9.0 da 4.25.

### 4.27 Camada de funcionalidade (FEAT): unidade de teste do QA, opcional e colapsável

**Problema**: entre a SPEC e a TASK falta o nível em que o QA opera — a **funcionalidade** (fluxo entregável: "login no portal", "lançamento de horas"). Caso real de consumidor: 1 SPEC com 30 FRs / 29 ACs / 17 TASKs continha ~4 funcionalidades que o QA testaria em separado. A SPEC é grande demais como unidade de teste, a TASK é unidade de dev; a projeção Jira de 2 níveis (SPEC→issue, TASK→sub-task) não dá ao QA um card operável por fluxo, e Epic ▸ Sub-tarefa é estruturalmente inválido no Jira — qualquer mapeamento 1:1 força um compromisso ruim.

**Decisão (do humano, com recomendação da sessão)** — camada **FEAT opcional e colapsável**, declarada na SPEC:
- **Declaração estrutural, não paralela**: as FEATs (`FEAT-NNN-XXX`, NNN = nº da SPEC) são headings de agrupamento dos FRs dentro da §5 da SPEC — cada FR pertence a **exatamente uma** FEAT por posição (partição total, impossível de violar por drift). Cada FEAT traz nome de fluxo, 1–2 linhas de descrição na voz do QA e, quando sincronizada, a key da Story numa linha `**Jira**:` sob o heading.
- **ACs derivam, não redeclaram**: o conjunto de ACs de uma FEAT é mecânico — `ACs(FEAT) = { AC | AC cobre FR ∈ FEAT }` via o vínculo `(cobre FR-...)` já existente. Sem segunda fonte de verdade; a §7 da SPEC não muda de sintaxe. Preserva **gerador ≠ avaliador**: o "pronto" da FEAT são os ACs dela verificados pelos gates, nunca autochecklist.
- **Colapso (rigor proporcional)**: SPEC com um único fluxo entregável **não declara** a camada — §5 continua lista plana, a funcionalidade é a própria SPEC e a projeção Jira segue em 2 níveis, byte a byte como hoje. Declarar exatamente 1 FEAT é WARNING do validator (sugerir colapso), nunca ERROR. Retrocompatibilidade estrutural: nenhum caminho novo roda sem a declaração.
- **TASK sabe a quem serve**: campo `**Funcionalidade**:` no front-matter — o conjunto deve ser exatamente o das FEATs dos FRs de `Realiza (FRs)`, com uma marcada `(primária)` (heurística do `/keelson:tasks`: mais FRs realizados; empate → menor ID). Task transversal (ex.: front SPA servindo 2 fluxos) lista todas; **FEAT pronta p/ QA** ⇔ FRs cobertos por PLAN(s) **e** todas as TASKs que a listam (primária ou secundária, em qualquer PLAN do slug) Done — a transversal inacabada bloqueia corretamente todos os fluxos que serve.
- **Projeção Jira de 3 níveis, duplo opt-in**: `issueType` ganha `feature` (ID do tipo Story, nullable). Ativa ⇔ SPEC declara FEATs ∧ `issueType.feature != null`. Cadeia: SPEC→Epic, FEAT→Story (`parent` = Epic), TASK→sub-task (`parent` = Story da FEAT primária; secundárias via `createIssueLink` "relates to"). Hierarquia validada por `hierarchyLevel` (operar por ID); escada de degradação best-effort (parent rejeitado → Story solta + link; Story falhou → sub-task cai no parent da SPEC); **nunca re-parentar** sub-tasks legadas (estado misto é reportado, não corrigido). Gatilho novo "Funcionalidade pronta p/ QA" na tabela Etapas/Colunas do mapa do consumidor.
- **Alternativa descartada** — "1 SPEC = 1 funcionalidade + iniciativa acima" (Iniciativa→Epic, SPEC→Story): hierarquia Jira mais natural e SPECs menores, porém a granularidade "1 SPEC = 1 fluxo" é julgamento não-enforçável por validator, fatiaria o corpus real (glossário/escopo/NFRs fragmentados), exigiria artefato novo com ciclo de vida próprio e duplicaria o papel do slug como agrupamento de domínio (4.9); `specify-epic` já havia sido descartado (§8).
- **O que não muda**: waves continuam topológicas por dependência (wave é unidade de execução; FEAT, de entrega/teste); PLAN não vira issue nem ganha estrutura FEAT (tabela FR→COMP sem coluna nova — dado derivado é duplicação, 4.20); contrato da tabela "PLANs" do INDEX intocado; nenhum comando novo (`/keelson:jira-sync` já é a reconciliação); nenhuma seção do protocolo de sync renumerada.

**Custo assumido**: a §5 da SPEC deixa de ser uma lista homogênea quando a camada é declarada (parsers/validators passam a entender headings FEAT); o INDEX ganha granularidade por FEAT nas Capacidades; superfície nova de dessincronia (campo da TASK × FEATs da SPEC), mitigada por regra mecânica de derivação validada pelo `task-validator`.

**Aplicação**: `commands/specify.md` (princípio + template §5 + Etapa 5.3), `skills/spec-validator/SKILL.md` (IDs + Etapa 4.5 nova), `commands/tasks.md` (campo `Funcionalidade`, tabela "Cobertura por funcionalidade" no TASK-INDEX, Etapa 7), `skills/task-validator/SKILL.md` (obrigatoriedade condicional + vinculação + batch), `skills/_shared/jira-sync-protocol.md` (§2, §3, §4, novo §6.1, §7, §9, §10, §12), `commands/init.md` (Etapa 4.6 + merge + self-check), `templates/keelson.config.example.json` (`issueType.feature`), `commands/jira-sync.md` (passo de Stories), `commands/implement.md` (closure move capacidade por FEAT + marco "pronta p/ QA"), `commands/rebuild-index.md` (capacidade por FEAT), method-guide (§3.1, §3.3, §3.13, §6), `README.md` (Jira integration + Status), `templates/CLAUDE.keelson-block.md` (1 palavra). Capacidade nova → minor: plugin 0.9.0 → 0.10.0.

### 4.28 Guardrail de hierarquia Jira + tarefa isolada (`issueType.standalone`)

**Problema**: complemento da 4.27, com dado real de consumidor. (a) O Jira só aninha pai→filho entre níveis de hierarquia **adjacentes** — e o createmeta do projeto real mostrou a armadilha: `Epic(1) ▸ História(0) ▸ Subtarefa(-1)` aninha, mas `História(0) ▸ Tarefa(0)` são irmãos (só "relates to", não contém), e `Epic(1) ▸ Subtarefa(-1)` é inválido. Nada validava o mapeamento `spec ▸ feature ▸ task` na hora de escrever a ficha; pior, o degrau (iii) da escada da 4.27 ("Story falhou → sub-task cai no parent da SPEC") é estruturalmente inválido quando `spec` é epic-level e `task` é subtask. (b) Nem toda TASK nasce sob uma funcionalidade: bugfix/chore pontual roteado pelo `/keelson:triage` direto para TASK (sem SPEC/FEAT) também precisa virar **um card que o QA testa** — e sub-tarefa exige pai, então essas tasks precisam de um tipo nível 0 próprio.

**Decisão (do humano, com recomendação da sessão)**:
- **Guardrail de hierarquia no init — aviso, nunca bloqueio** (coerente com o best-effort §0): ao resolver os tipos na Etapa 4.6, validar via `hierarchyLevel`/`subtask` do createmeta que (1) cada perna pai→filho do mapeamento é **estritamente descendente e adjacente** (pai exatamente um nível acima); (2) se `issueType.task` é `subtask:true`, toda sub-task terá um pai nível 0 (com 3 níveis, a Story da FEAT; com 2 níveis, `issueType.spec` deve ser nível 0 — Epic ▸ Subtarefa não existe); (3) combinação inválida → aviso claro dizendo **qual perna não aninha** e sugerindo o tipo correto do próprio projeto (ex.: "História(0) não cabe sob Tarefa(0); o tipo epic-level deste projeto é Epic(11169)"). O self-check da Etapa 6 repete a checagem como aviso. Nenhum validator de artefato bloqueia por config de Jira (tracker é best-effort; validators guardam artefatos SDD).
- **`issueType.standalone`** (nullable): ID de um tipo **nível 0** (Tarefa/Bug) para a **tarefa isolada** — o card de QA fora do aninhamento de funcionalidade. `null` → tasks isoladas não sincronizam (comportamento atual). Distinto de `issueType.task` (o tipo aninhado sob a feature).
- **De onde vêm as isoladas**: (1) TASK roteada direto pelo `/keelson:triage` (bugfix, chore, ops, dívida) — sem SPEC/FEAT; (2) TASK **transversal sem primária honesta**: o default da 4.27 continua (aninha na Story da FEAT primária + links nas secundárias — o QA vê a task dentro do card do fluxo), mas quando servir a todas/quase todas as FEATs sem primária defensável, o `/keelson:tasks` declara `**Funcionalidade**: transversal (FEAT-A, FEAT-B)` e ela projeta como standalone. Nunca replicada — ou aninha com links, ou é uma issue só.
- **Onde a isolada se pendura**: slug com issue-SPEC epic-level → `parent` = o Epic (`Epic(1) ▸ Tarefa(0)` é adjacente e válido); issue-SPEC nível 0 ou TASK avulsa sem SPEC → **sem pai** (+ `createIssueLink` "relates to" com a issue do slug, se existir).
- **A isolada é a própria unidade de QA**: na closure `Done`, aplicar o marco "pronta p/ QA" (gatilho do mapa / política de `transition`) **na própria issue** — equivalente ao que a Story recebe quando a FEAT completa.
- **Correção do degrau (iii)** da 4.27: Story da FEAT falhou → a task projeta via `issueType.standalone` sob o Epic (se preenchido e adjacente); senão issue normal + link "relates to" (padrão de robustez do §7). Sub-task órfã **nunca** é tentada.
- **Retrocompat**: projeção de 2 níveis (`feature: null`) e projetos sem Jira seguem intocados; `standalone: null` no merge da ficha preserva o comportamento atual byte a byte.

**Custo assumido**: o bloco `issueType` passa de 3 para 4 chaves e o init ganha lógica de validação de níveis; o campo `Funcionalidade` da TASK ganha uma segunda forma (`transversal (...)`) que o `task-validator` precisa aceitar. Aceito em troca de impedir a armadilha silenciosa de hierarquia (falha só na criação, longe da causa) e de dar ao QA o card da tarefa pontual.

**Aplicação**: `templates/keelson.config.example.json` (`issueType.standalone`), `commands/init.md` (Etapa 4.6 — descoberta do standalone + guardrail de adjacência com sugestão; merge; self-check), `skills/_shared/jira-sync-protocol.md` (§2, §6.1 pré-check por adjacência + degrau iii corrigido, §7 tarefa isolada, §9 marco na isolada), `commands/tasks.md` (forma `transversal (...)`), `skills/task-validator/SKILL.md` (aceitar a forma), `commands/implement.md` (closure cria a isolada de TASK avulsa sem key), method-guide §3.13, `README.md`. Capacidade nova → minor: plugin 0.10.0 → 0.11.0.

---

## 5. Quality gates inegociáveis

### 5.1 SPEC: gate ao final do /keelson:specify

Skill `spec-validator` executa automaticamente. Errors bloqueiam Status `Approved`. Categoria de auto-fix limitada a violações triviais (RFC 2119 em minúsculo, zero-padding, etc).

### 5.2 PLAN: gate ao final do /keelson:plan

Skill `plan-validator` valida estrutura, cobertura declarada, DEC com alternativas, aderência ao Charter + perfil ativo.

### 5.3 TASK: gate ao final do /keelson:tasks

Skill `task-validator` valida vinculação ao PLAN, FRs realizados, ACs cobertos, dependências topológicas sem ciclos.

### 5.4 Implementação: gates por task no /keelson:implement

Gates por task antes de Done — sempre + proporcionais ao risco:
1. Implementação completa
2. Testes cobrindo ACs, todos passando
3. Lint limpo
4. Escopo respeitado
5. Decisões DEC respeitadas
6. Aderência ao Charter + perfil ativo (e `guidelines/project/`)
7. Code review por reviewer agent (`task-reviewer`)
8. Segurança (`security-reviewer`, REJEIÇÃO IMEDIATA) — em mudança sensível
9. Comportamento verificado (`task-verifier`) — em mudança com efeito observável

### 5.5 Closure: gate independente

Mesmo com os gates de código aprovados, task não é Done sem closure: arquivo da task atualizado com Status, evidência, branch, commit SHA, arquivos modificados, quality gates marcados.

---

## 6. Modos de orquestração no /keelson:implement

*(Recalibrado em 2026-07-17: SUBAGENTS passou a ser o padrão — sem detecção automática de alternativas; AGENT_TEAMS virou opt-in explícito. Fonte de verdade: `commands/implement.md`, Etapa 0.1.)*

### 6.1 Modo SUBAGENTS (padrão)

- Subagents na mesma sessão, sem peer-to-peer
- Branch única por wave
- Custo: 1.5-2x tokens
- Coordenação via main session
- Usa `task-implementer` e `task-reviewer` por referência

### 6.2 Modo AGENT_TEAMS (opt-in via `--force-mode=teams`)

- Requer ambiente com suporte (ex.: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Teammates independentes, peer-to-peer
- Worktrees por task, branches separadas
- Custo: 3-5x tokens, ganho: até 2x mais rápido

### 6.3 Modo SINGLE_THREAD (wave única e sequencial de tasks pequenas)

- Tudo sequencial, na main session
- Sem paralelismo
- Closure obrigatória do mesmo jeito

---

## 7. Roteamento de mudanças

Quando aparece uma demanda nova, usar `/keelson:triage` (triagem) ou decidir manualmente:

| Tipo de mudança | Artefato |
|---|---|
| Contrato muda (FR, AC, escopo) | Nova SPEC via `/keelson:specify` |
| Estratégia técnica nova, contrato igual | Novo PLAN da mesma SPEC via `/keelson:plan` |
| Bug (implementação ≠ AC) | TASK do tipo bugfix |
| Refactor sem mudança de comportamento | TASK do tipo refactor |
| Trivial (typo, copy, cor) | Direto no código |
| Mexer em slug legado pela primeira vez | `/keelson:migrate-legacy` antes, depois `/keelson:triage` |

---

## 8. Decisões em aberto (por resolver)

- Variantes `/keelson:specify-small` e `/keelson:specify-epic` para tarefas micro e roadmap.
- Hook de pre-commit bloqueando merge sem closure.
- Convenção de UX-FRs (como escrever requisito de comportamento de interface em EARS).
- Como integrar com ferramentas de wireframe externas referenciadas pelo PLAN.
- Skill validadora do próprio bloco keelson do `CLAUDE.md`.
- Agente dedicado `request-mirror` para o espelho do entendimento (decisão 4.14), caso a qualidade do espelho inline se mostre inconsistente na prática.
- Política de arquivamento de slugs concluídos.
- Política de aposentadoria do `/keelson:migrate-legacy` quando não houver mais slug legado no projeto.

---

## 9. Como evoluir este documento

- Toda nova decisão estrutural sobre o processo keelson é registrada aqui.
- Decisão revogada não é deletada: é marcada como `[REVOGADA em YYYY-MM-DD: motivo]`.
- Atualizar a data de revisão no topo a cada mudança.

---

## 10. Origem destas decisões

Estas decisões nasceram na afinação do fluxo spec-driven do projeto que deu origem ao keelson e foram destiladas para o plugin como base portável. Este documento é a fonte canônica do processo daqui pra frente; cada novo projeto que adota o keelson pode estendê-lo com suas próprias decisões.
