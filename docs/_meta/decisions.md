# Decisões do processo (keelson)

> Memória institucional das decisões sobre como o keelson (spec-driven development) é praticado. Diferente da doutrina de código (QUALITY-CHARTER + perfil ativo, que regem o **código**), este arquivo rege o **processo de desenvolvimento**.

**Última revisão**: 2026-07-30
**Status do documento**: vivo, atualizado conforme decisões evoluem

> **Nota de rename (decisão 4.40, 2026-07-26)**: entradas anteriores à 0.21.0 citam agents pelos IDs antigos (`task-implementer`, `task-reviewer`, `task-verifier`, `security-reviewer`, `product-critic`, `process-tuner`, `profile-writer`). Histórico não se reescreve — o de-para completo está na decisão 4.40.

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
├── commands/                   # /keelson:* (specify, plan, tasks, implement, auto, review, specify-epic, ...)
├── skills/                     # spec-validator, plan-validator, task-validator, status, screen-verify
├── agents/                     # o time: po, pm, developer, code-reviewer, qa, security-engineer, ...
├── hooks/                      # doc-guard.sh, security-guard.sh, review-guard.sh, wave-guard.sh, ... (leem a ficha)
└── guidelines/
    ├── _meta/                  # QUALITY-CHARTER.md, PROFILE-OUTLINE.md
    ├── core/                   # doutrina agnóstica (SECURITY.md, ...)
    ├── backend/                # perfis de linguagem (php.md, ...)
    └── frontend/
```

---

## 3. Convenção de nomes

**Decisão**: os comandos do keelson são expostos sob o namespace do plugin — `/keelson:<cmd>` — e as skills e agents que acompanham o plugin **não** levam prefixo redundante (o próprio plugin já os agrupa).

**Motivo**: `/keelson:*` agrupa visualmente no tab completion, comunica o intent (é o keelson agindo) e separa dos demais comandos do projeto, sem precisar inventar prefixo. Dentro do plugin, skills e agents ficam com nomes curtos (`spec-validator`, `developer`, `security-engineer`) porque o pacote já dá o escopo.

**Aplicação** *(elenco de agents atualizado pela 4.40 — IDs = nomes dos papéis)*:
- Commands: `/keelson:specify`, `/keelson:plan`, `/keelson:tasks`, `/keelson:implement`, `/keelson:triage`, `/keelson:rebuild-index`, `/keelson:migrate-legacy`, `/keelson:auto`, `/keelson:guided`, `/keelson:refine`, `/keelson:integrate`, `/keelson:jira-sync`, `/keelson:verify-handoff`, `/keelson:audit`, `/keelson:review`, `/keelson:specify-epic`
- Skills: `spec-validator`, `plan-validator`, `task-validator`, `status`, `screen-verify`
- Agents: `po`, `pm`, `developer`, `code-reviewer`, `qa`, `security-engineer`, `product-analyst`, `agile-coach`, `staff-engineer` — e `code-scout` (ferramenta fora do elenco, como os validators; decisão 4.73)

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

*(Emendada pelas decisões 4.10 e 4.38: a promoção de Status foi delegada ao agente — 4.10 — e a aprovação de produto passou ao `po`, contra o BRIEF, no ciclo autônomo — 4.38. Permanecem humanos: merge, deploy e config de produção; o Diretor mantém veto e escalação. IDs dos agents citados abaixo são pré-4.40.)*

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

*(Recalibrada pela 4.38: no modo autônomo, a confirmação do espelho foi substituída pela **janela de veto** — o contrato passa a ser o BRIEF **emitido**, validado pelo `po`; a confirmação na hora permanece só no `/keelson:guided`. O formato canônico e a calibração por rota seguem válidos, com o contrato do BRIEF morando no `index-contract.md`.)*

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

### 4.29 Teto de 250 caracteres na `description` de comandos e skills + hook `desc-guard`

**Problema**: dado real do repo. O `/keelson:verify-handoff` sumiu da lista de comandos onde o plugin está instalado — os outros 14 apareciam, só ele não. Causa: o Claude Code (>= v2.1.86) impõe um limite de **250 caracteres** na `description` de frontmatter de comandos e skills; acima disso o **comando é ocultado da lista sem erro** (ocultação silenciosa) e a **skill tem a description truncada** na tela `/skills`. A description do `verify-handoff` tinha 396 caracteres; cinco skills passavam de 250 (screen-verify chegava a 894). Nada no plugin guardava esse invariante, e o sintoma (comando invisível) aparece longe da causa (uma frase longa demais).

**Decisão (do humano, com recomendação da sessão)**:
- **Encurtar toda `description` para ≤ 250**, com os termos-gatilho no início (o que sobra é truncado de qualquer forma) e o detalhe completo no **corpo** do artefato. Para skills isso preserva a função de auto-ativação da description sem perder regra — as regras críticas (ex.: "nunca produção", multi-realm da `screen-verify`) já vivem no corpo.
- **Guard mecânico** `hooks/desc-guard.sh` (Stop hook, mesma moldura dos demais: `set -euo pipefail`, parse via python3, `stop_hook_active` anti-loop, fallback gracioso). Mede em **code points** (igual ao `.length` de JS que o harness usa) e bloqueia o encerramento listando cada comando/skill acima de 250.
- **Escopo do guard**: age **só no repo de desenvolvimento do keelson** (marcado por `.claude-plugin/plugin.json` com `name: keelson` + `commands/`). Em projeto consumidor o plugin é read-only e não vive no cwd → `exit 0`, nunca atrapalha o fluxo — coerente com o princípio de fallback gracioso dos hooks.

**Custo assumido**: descriptions de skill ficam mais enxutas (menos prosa explicativa no gatilho), e o array de Stop hooks ganha um sexto membro. Aceito em troca de tornar impossível a regressão silenciosa de um comando invisível.

**Aplicação**: `commands/verify-handoff.md` + `skills/{spec,plan,task}-validator/SKILL.md`, `skills/screen-verify/SKILL.md`, `skills/status/SKILL.md` (descriptions ≤ 250); `hooks/desc-guard.sh` (novo) + `hooks/hooks.json` (registro). Capacidade nova → minor: plugin 0.11.0 → 0.12.0.

---

### 4.30 Gate 8 inescapável na Entrega + identidade do código provada (lições da 1ª rodada real do /auto)

**Problema**: análise da cadeia de pensamento de uma rodada real do `/keelson:auto` (feature de 2FA — caso maximamente sensível). Quatro falhas de processo, duas estruturais: (a) o **gate 8 só rodou depois da Entrega**, por cobrança do humano — e reprovou com bypass crítico real (`/2fa/verify` gravava o fator sem a guarda que o `/2fa/setup` ganhou). A orquestração colapsou silenciosamente para "main session implementa e se auto-revisa": nenhuma menção a `task-implementer`/`task-reviewer` nas 5 waves, e nada detectou o desvio. A válvula do hook `security-guard` ("se você JÁ revisou a segurança, pode encerrar") aceitava a auto-certificação do gerador. (b) O ambiente de verificação executava **código diferente do diff** duas vezes na mesma sessão (dev server servindo a `main`; container do backend montando o repo principal) — produzindo um falso "bug de segurança" e ciclos perdidos; houve ainda o quase-acidente de editar o repo principal em vez da worktree. A decisão 4.26 prova *disponibilidade* do ambiente, mas nada provava *identidade* do código. Menores: (c) verificação de recusa enumerada pela superfície da UI, não pelos writers do dado (a raiz do bypass passar verde no gate 9); (d) três falsos bugs de UI por aba oculta pausando transições CSS (`document.hidden`) + viewport degenerado.

**Decisão (do humano, com recomendação da sessão)**:
- **Entrega exige evidência de gate, não lembrança de gate**: pré-check determinístico na Etapa 5 do `/keelson:auto` (antes do push) — diff sensível com `gates.security` ativo exige veredito do `security-reviewer` sobre o diff final, com `revisado_por ≠ implementado_por`; "verifiquei ao construir" não satisfaz (gerador ≠ avaliador). Vale para todas as rotas, inclusive a inline (auto-revisão cobre gates 1–7, nunca o 8 sensível).
- **SINGLE_THREAD dispensa orquestração, não independência**: os gates de 3.3 do `/keelson:implement` continuam via subagents; o output final ganha **atribuição por task** (implementado_por/revisado_por/gate 8/gate 9) para tornar visível qualquer colapso.
- **Hook `security-guard` sem válvula de auto-certificação**: a saída limpa passa a exigir que o `security-reviewer` tenha rodado (ou prova de que a mudança está fora dos gatilhos), não "já revisei".
- **Identidade do código se prova, não se presume** (espelho da 4.26): antes de confiar em exercício funcional, provar que o processo de pé executa a worktree/branch do diff (path raiz do server, SHA/marcador, efeito de mudança já commitada). No `task-verifier` (passo 2) e na skill `screen-verify` (§1).
- **Guarda no sink, não na superfície** (`core/SECURITY.md` + checklist): step-up mora no ponto que escreve o dado; enumerar **todos os writers** e provar a recusa em cada um — espelho de escrita do padrão "Acesso por registro". O `task-verifier` exercita AC de recusa por todos os writers, não só pelo endpoint da tela.
- **Hook novo `worktree-guard`** (PreToolUse em Edit/Write/NotebookEdit): sessão numa worktree vinculada + alvo dentro do working tree principal → deny com instrução de usar o path da worktree. Repo normal, scratchpad e a própria worktree passam sem ruído; fallback gracioso padrão.
- **Armadilhas do browser embutido** documentadas na `screen-verify`: aba oculta pausa transições/rAF (modal "presa", screenshot preto), viewport degenerado invalida medidas; sintoma só vira bug re-medido com aba visível e viewport são.

**Custo assumido**: a Entrega ganha um passo de conferência e o array de hooks um sétimo membro (PreToolUse, o primeiro não-Stop); o output do implement fica mais longo (tabela de atribuição). Aceito em troca de fechar o buraco mais caro observado até agora: uma entrega "verde" com bypass crítico que só o avaliador independente pegou — e pegou **depois** do push.

**Aplicação**: `commands/auto.md` (Etapa 5, pré-check de gates), `commands/implement.md` (0.1 SINGLE_THREAD; Etapa 5, atribuição por task), `hooks/security-guard.sh` (mensagem sem auto-certificação), `hooks/worktree-guard.sh` (novo) + `hooks/hooks.json` (bloco PreToolUse), `agents/task-verifier.md` (passo 2 identidade; passo 3 writers), `guidelines/core/SECURITY.md` (padrão "Guarda no sink" + item de checklist), `skills/screen-verify/SKILL.md` (identidade em §1; armadilhas do browser em §3). Capacidade nova (hook) → minor: plugin 0.12.0 → 0.13.0.

---

### 4.31 Comentário tem piso e teto; densidade não se herda do vizinho (Charter 0.4.0)

**Problema**: dado real de uma entrega do `/keelson:auto` (marcar migrations como concluídas). O humano provocou: "3899 linhas só para isso?". A medição mostrou ~800 linhas de produção — mas mostrou também gordura real e **induzida pela própria doutrina**: 25–40% das linhas dos arquivos PHP novos eram comentário (`MigrationMarkService`: 95 linhas, 51 de código) e a migration trazia **98 linhas de cabeçalho comentado para 45 de SQL**. A justificativa do implementer foi citação literal do Art. 5 — *"mesma densidade de comentário"* do código vizinho. Em base legada verbosa, esse artigo **é** a fábrica de gordura: manda copiar o passivo. E os freios não existiam: o Art. 7 dava direção ("comentário explica o porquê") sem régua falsificável, e o `task-reviewer` tinha isenção explícita — *"comentário excessivo → não bloqueia"*. Faltava também o **piso**: comentário só era tratado como risco de excesso, nunca como obrigação — mas o que um leitor futuro (humano ou agente sem a conversa) não reconstrói lendo o diff é justamente a decisão e a armadilha.

**Decisão (do humano, com recomendação da sessão)**:
- **Art. 7 ganha piso e teto falsificáveis**. Piso: DEVE haver comentário onde o contexto é *irrecuperável pela leitura* — decisão não óbvia (com **âncora** ao artefato: `DEC-03`, `FR-07`, `AC-12`), workaround (porquê + **condição de remoção**), invariante que tipo/nome não expressam, efeito colateral não anunciado pelo nome. Teto: NÃO DEVE haver paráfrase do código, repetição de assinatura, narração do óbvio nem template ritual. Régua: **apagar o comentário perde informação** — se não perde, ele não deveria existir; nenhum bloco maior que o trecho que explica.
- **Art. 5 para de herdar densidade**: código novo lê como o vizinho em **convenção e idioma**; densidade segue o Art. 7. Base antiga verbosa não é licença para verbosidade nova — nem motivo para reescrever a que já está lá (Art. 6).
- **O gate 7 deixa de dar isenção**: comentário redundante sai de "não bloqueia" e vira **ação sugerida de remoção** com trechos apontados; passam a **bloquear** as três violações duras do Art. 7 (bloco maior que o código, workaround sem porquê/condição de remoção, DEC sem âncora no ponto do código).
- **Exceção idiomática mora no perfil** (um dono por regra): onde a linguagem faz o comentário *carregar* informação que a sintaxe não tem — docblock como única declaração de tipo em PHP 5.6/7.0 — ele é **piso**, não teto. O `PROFILE-OUTLINE` §3 passa a pedir essa distinção explicitamente.
- **A Entrega mede antes de perguntarem**: o report do `/keelson:auto` decompõe o diff em produção · teste · documentação · migration/config e declara o que entrou **fora do escopo do PLAN** (no caso real, 456 linhas de um guard de rotas promovido por achado de segurança — legítimo, mas invisível no total bruto). Total sem composição faz entrega correta parecer inchada e esconde inchaço quando ele é real.

**Custo assumido**: o Charter sobe para 0.4.0 e os 7 perfis passam a referenciar a versão nova (o texto deles já era compatível — "comentadas com o porquê"); o `php.md` é `reviewed: true` e não foi tocado no corpo, só no `charter:`. O reviewer ganha três motivos novos de bloqueio, com risco de atrito em base legada — mitigado por só valerem sobre o **código novo do diff**.

**Aplicação**: `guidelines/_meta/QUALITY-CHARTER.md` (versão 0.4.0; Art. 5 e Art. 7), `guidelines/_meta/PROFILE-OUTLINE.md` (§3), `guidelines/core/CODE-REVIEW.md` (tabela), `agents/task-reviewer.md` (calibração de severidade), `commands/auto.md` (Etapa 5, item 6.1), bump `charter:` nos 7 perfis. Doutrina nova → minor: plugin 0.13.0 → 0.14.0.

---

### 4.32 Regra do escoteiro sancionada e declarada (Charter 0.5.0)

**Problema**: a §4.31 criou o teto de comentário para código **novo**, mas deixou a base legada intocável — o Art. 5 dizia explicitamente "nem motivo para reescrever a que já está lá", e o gate 4 do reviewer reprovava **qualquer** mudança colateral como violação de escopo. Resultado: o implementer que edita uma função cercada de paráfrase ritual, comentário mentiroso ou código morto é obrigado a **preservar o passivo** que está lendo naquele momento — e a limpeza fica adiada para uma task que nunca nasce. Pior caso: comentário que **mente** sobre o código atual, que um agente futuro lê como garantia e usa de fundação. O humano pediu a regra do escoteiro: quem toca, deixa melhor.

**Decisão (do humano, com recomendação da sessão)**:
- **Art. 6 ganha a regra do escoteiro**: o trecho que a mudança já toca fica melhor do que foi encontrado (comentário que reprova no teste do Art. 7, comentário mentiroso, código morto, nome enganoso barato de corrigir — exemplos-âncora, não enumeração). O alinhamento vem de **três condições falsificáveis**, que distinguem limpeza de desvio: distância de leitura, comportamento preservado, declarada item a item. Faltou uma → é escopo novo, vira pendência.
- **Declarar é o que legitima**: report do `task-implementer` ganha o campo `escoteiro:` (lista `arquivo:linha — o quê e por quê`, ou null). O gate 4 do reviewer passa a distinguir três casos: escoteiro declarado e dentro da régua → **não é** violação de escopo; mudança colateral **não declarada** → FALHA (continua sendo desvio); "escoteiro" que muda comportamento ou esconde escopo novo sob o rótulo de limpeza → FALHA.
- **Art. 5 reconciliado**: a frase "nem motivo para reescrever a que já está lá" virou "a verbosidade que já está lá segue a regra do escoteiro: no trecho que a mudança toca, limpe; no resto da base, deixe" — as duas doutrinas param de se contradizer.
- **Revisão do Art. 7 com o olhar "o que ajuda um agente em código antigo"**: o piso ganhou o item **caminho já tentado que falhou** ("sem cache aqui: estourava X sob carga") — sem esse registro, o próximo implementer (humano ou agente) repropõe a solução descartada, com confiança. Era o único gap da lista da §4.31.
- **Gate 7 fecha o ciclo**: trecho vizinho tocado que permaneceu sujo (escoteiro não aplicado) entra em `acoes_sugeridas` — mesma severidade do comentário redundante novo (sugestão, não bloqueio).

**Custo assumido**: o gate 4 fica mais caro (distinguir limpeza de desvio exige julgamento, não só diff de paths) e há risco de o implementer esticar o rótulo "escoteiro" — mitigado pelas três condições e pela declaração item a item. Charter 0.4.0 → 0.5.0; a 0.4.0 não chegou a ser commitada, mas os artigos mudaram — versão é do conteúdo, não do release. **Forma das regras** (pedido do humano nesta mesma leva): instrução escrita como **teste falsificável + exemplos-âncora**, nunca enumeração defensiva nem prosa motivacional — enumeração convida pattern-matching e litígio de borda; o teste dá autonomia alinhada. O Art. 7 inteiro colapsou para um teste ("apagar perde informação?") e o dono da regra é único (Charter); implementer e reviewer apenas referenciam.

**Aplicação**: `guidelines/_meta/QUALITY-CHARTER.md` (0.5.0; Art. 5, 6 e 7), `agents/task-implementer.md` (princípio 1, etapa 3.4, campo `escoteiro` do report), `agents/task-reviewer.md` (gate 4, calibração do gate 7), `guidelines/core/CODE-REVIEW.md` (tabela), bump `charter:` nos 7 perfis. Doutrina nova → minor: plugin 0.14.0 → 0.15.0.

---

### 4.33 Revisão de coerência: contradições de autonomia eliminadas + dedup por dono

**Problema**: sweep de coerência pedido pelo humano encontrou três contradições ativas e duplicação de regra com dono errado. (a) `guidelines/core/WORKFLOW.md` §6 mandava "**sempre** pergunte antes de alterar schema/auth/config/exclusão" — congelado de antes do `/keelson:auto`; contradizia frontalmente a escada de reação e a calibração por reversibilidade (o auto manda seguir com coluna nullable registrada; o WORKFLOW mandava parar). (b) `specify.md`/`plan.md` — os primitivos que o auto executa — ordenavam "pare e faça até 5 perguntas" e "confirme com o humano" (slug novo, slice) sem cláusula de modo: pós-largada, com o humano ausente, isso ou trava o ciclo ou é ignorado por improviso; e "até 5" excede o limite de 4 do AskUserQuestion. (c) O gatilho do gate 9 divergia entre donos: WORKFLOW e template do CLAUDE diziam "quando `gates.screenVerify` e efeito observável"; o dono real (`implement`/`task-verifier`) diz "quando efeito observável — `screenVerify` condiciona só a parte de tela". (d) A mecânica do `process-tuner` (ledger, dedup, modo dev × consumidor) estava copiada por extenso em `auto.md` e `implement.md` — o agent é o dono.

**Decisão (do humano: "revise contradições, alinhamento, autonomia; reduza caracteres")**:
- **WORKFLOW §6 reescrito pela régua de reversibilidade** (Charter Art. 6): destrutivo/difícil reversão → sempre resposta humana; reversível simples em área sensível → decisão registrada + gates; *quando* perguntar depende do modo (presente → na hora; autônomo → escada do auto).
- **Primitivos com consciência de modo**: `specify` (Etapa 1/0.2) e `plan` (Etapa 2/slice) ganham uma linha — pós-largada não pausa, aplica a escada; "até 5 perguntas" → "até 4".
- **Gate 9 alinhado ao dono** em WORKFLOW e template: dispara por efeito observável; tela exige `screenVerify`.
- **Dedup por dono**: auto/implement passam a referenciar a mecânica do `process-tuner` em vez de reproduzi-la; rota "Risco" do auto referencia a tabela de rigor do WORKFLOW; prosa motivacional dos blocos "Fôlego não é gatilho" e Etapa 4.5 comprimida (regra + referência às decisões, sem retórica).

**Custo assumido**: nenhum comportamento novo — só remoção de conflito e de duplicata; o risco é alguma nuance da prosa longa ter carregado regra implícita não percebida (mitigado: cada corte manteve regra, exemplos-âncora e referência de decisão). Correção de coerência → sem bump (a leva 0.15.0 ainda não foi commitada).

**Aplicação**: `guidelines/core/WORKFLOW.md` (§4, §6, gate 9), `templates/CLAUDE.keelson-block.md` (gate 9), `commands/specify.md` (Etapa 1), `commands/plan.md` (Etapa 2), `commands/auto.md` (Etapa 0 rota Risco, 4.5, "Fôlego"), `commands/implement.md` (3.4.2 item 5).

---

### 4.34 Verificação executável pré-código + migração de schema faseada

**Problema**: avaliação de uma carta externa sobre instrução de IA (workflow de cobertura: 7 leitores por área + crítico adversarial) mostrou 13 de 15 recomendações já cobertas com dono no keelson — e confirmou dois gaps parciais. (a) O keelson fixa ACs antes do código (Given-When-Then na SPEC) e verifica depois (verifier independente), mas **nenhum artefato exige que o critério exista em forma executável — comando + saída/efeito esperado — antes de o implementer começar**: o formato "esperado observável para dar ✅/❌" só aparece pós-código, e os testes nascem durante a implementação, olhando o diff — a mitigação era só o avaliador independente. (b) O WORKFLOW §6 gateia `DROP`/`ALTER` destrutivo com humano, mas decide *se* aplica — nada ensinava *como* fasear: a receita expand→migrate→contract não existia em nenhum vocabulário no repo.

**Decisão (do humano, sobre proposta da sessão)**:
- **Verificação executável na TASK** (último artefato pré-código; a SPEC segue agnóstica de tecnologia): cada critério de teste do template de "Critérios de pronto" **anexa** a verificação executável — `<comando> → <saída/efeito esperado>` — e o §Mapeamento a regra: todo item de gate 1 registra comando+esperado **antes** do código; o critério nasce do AC, nunca do diff (gerador ≠ avaliador). Check pareado no `task-validator` (ERROR; só TASK `Todo`/`In Progress` — `Done` legada não reprova retroativamente) — gerador e validator em par e com a mesma cardinalidade, lições do LRN-004 (critério fantasma) e LRN-007 (leitura mais fraca). "Testes pré-existentes seguem verdes" **não** entra no template: já tem dono (gate 2 do reviewer, escopado ao domínio tocado).
- **Migração de schema faseada no WORKFLOW §6**, estendendo a régua de reversibilidade que já mora ali: adicionar → migrar dados → mudar consumo → remover em deploy posterior. Teste falsificável: mesmo PR/deploy com a remoção do legado **e** o código que parou de consumi-lo → reprova (Charter Art. 6).
- **Não adotado da carta** (registro para não relitigar): esqueleto de prompt e "pare antes de implementar" já são o ciclo SDD; "não ensinar engenharia genérica" atacaria o Charter — que existe justamente para ser o árbitro, com orçamento gerido por 4.20/4.32/destilação.

**Custo assumido**: TASK fica ~1 linha mais cara de gerar e o validator mais estrito (critério de teste sem comando+esperado agora é ERROR, acima do WARNING de cobertura genérica — intencional: o comando é o oráculo, a cobertura é o desejo). A receita de schema é agnóstica; perfis instanciam a ferramenta de migration se precisarem, sem duplicar a regra.

**Aplicação**: `commands/tasks.md` (template Critérios de pronto + §Mapeamento), `skills/task-validator/SKILL.md` (Etapa 4, ERROR), `guidelines/core/WORKFLOW.md` (§6). Charter inalterado (0.5.0 — nenhum artigo mudou). Doutrina nova → minor: plugin 0.15.0 → 0.16.0.

---

### 4.35 — Compressão de instruções e modelo de carga

**Problema**: auditoria de 14 agentes (modelo de carga por fluxo + varredura cruzada de duplicação + verificação adversarial das propostas) mediu o custo real das instruções: a main session do `/keelson:auto` paga ~166–233k chars de material do plugin antes de qualquer artefato SDD, e um PLAN de 6 tasks re-paga ~932k chars de doutrina nos spawns. Os maiores ofensores não eram regra ruim, e sim **modelo de carga**: o method-guide (35k) lido integral para usar §3.0/§6/§8 (~16k); o perfil de linguagem integral (38–41k) relido em cada spawn de implementer/reviewer quando §6/§8/§10/§12 só valem sob gatilho; a frase blanket "doutrina core/* está sempre ativa" induzindo ~40k de carga onde o fluxo usa ~2,5k; e consumidores re-narrando donos (jira-sync-protocol, sondagem §8.1, validator-protocol).

**Decisão**:
- **Donos de runtime saem do method-guide para `docs/_meta/conventions/`**: `sdd-conventions.md` (ex-§3.0), `index-contract.md` (ex-§6), `handoff-protocol.md` (ex-§8, com §8.1/§8.2/§8.3) e `agent-teams.md` (modo teams do implement). O method-guide segue guia humano, com os headings §3.0/§6/§8 preservados como ponteiros de 1 linha (numeração do contrato dos 4 lugares intacta); comandos e hooks apontam para os arquivos novos via `${CLAUDE_PLUGIN_ROOT}`.
- **Jira em dois níveis**: `jira-sync-protocol.md` segue dono único do core; a camada FEAT (§6.1 + variantes do §7/§9) vira `skills/_shared/jira-sync-feat.md`, carregada só com o 3º nível ativo. Ganchos dos comandos ganham lista de leitura transitiva por § e leitura parcial via `grep -n "^## §"`; o `/keelson:jira-sync` continua lendo o arquivo inteiro (reconciliação §12).
- **Validade ≠ carga no core/***: a doutrina core **vale sempre** (aderência é gate), mas a **carga** segue mapa explícito por consumidor (dono: `sdd-conventions.md`); `PERFORMANCE.md` ganha gatilho nomeado (consulta, laço sobre volume variável, renderização pesada).
- **Leitura do perfil por seção nos spawns**: implementer/reviewer leem §§1–5, 7, 9 e 11 incondicionais; §6 (área sensível — lista canônica: description do `security-reviewer`), §8 (manifesto/lockfile), §10 (query/dataset pesado) e §12 (quality.* da ficha não basta) sob gatilho; perfil sem espinha 0–12 → ler inteiro. Perfis não são editados.
- **Perfis gerados**: logística de revisão humana dos marcadores CONFIRMAR migra para companheiros `guidelines/backend/_review/php-<versão>.md`; a afirmação acionável fica inline com tag curto "⚠️ não confirmado".
- **Charter 0.5.1**: passada de compressão nos "Por quês" redundantes (estilo regra = teste + âncora, §4.32), preservando Réguas e os contraintuitivos dos Arts. 6/7/8; perfis apontam `charter: 0.5.1`.
- **Higiene**: descriptions de agents com teto 350 no `desc-guard`; `disable-model-invocation` em `/keelson:audit` e `/keelson:verify-handoff`; lista de área sensível do gate 8 com dono único na description do `security-reviewer`; formato canônico de lição com dono em `guidelines/core/WORKFLOW.md`; template de TASK tipo bugfix passa a incluir o AC violado no Realiza.
- **Rejeitadas** (registro para não relitigar): digest do Charter para spawns (o gate 6 relê o Charter integral de qualquer forma — custo dobraria; a constituição tem dono único) e base+delta dos perfis PHP.

**Custo assumido**: mais arquivos pequenos para navegar (conventions/ + jira-sync-feat + companheiros `_review/`) e disciplina de leitura parcial que depende de obediência — mitigada por ponteiro no ponto de uso e fallback "na dúvida, leia inteiro". Seção de perfil pulada pode esconder anti-padrão da área — observar na 1ª rodada real, como os gates 4/7 do Charter 0.5.0.

**Aplicação**: `docs/_meta/conventions/*` (novos), `docs/_meta/method-guide.md` (§3.0/§6/§8 viram ponteiros; §4 severidades e roteamento da triagem viram resumo + ponteiro ao dono), `CLAUDE.md` (donos únicos), `skills/_shared/jira-sync-feat.md` (novo) + `jira-sync-protocol.md` + ganchos Jira dos comandos, `agents/task-implementer.md`/`task-reviewer.md` (leitura por seção), `guidelines/_meta/QUALITY-CHARTER.md` (0.5.0 → 0.5.1) + frontmatter `charter:` dos perfis, `guidelines/backend/_review/*` (novos), `hooks/desc-guard.sh` e `hooks/wave-guard.sh` (comentário), `commands/audit.md`/`verify-handoff.md` (`disable-model-invocation`), `commands/tasks.md` (template bugfix). Nota de roadmap preservada de `ARCHITECTURE.md`: quando houver doutrina de resiliência (retry/backoff, idempotência, timeout), nasce `core/RESILIENCE.md`.

---

### 4.36 — Code review de diff avulso: `/keelson:review` + régua dos gates 1–7 com dono único

**Problema**: código que entrou **fora do ciclo** — hotfix, código herdado, contribuição externa, mudança feita à mão — não tinha porta de entrada para a doutrina. A régua existia, mas só era alcançável dentro do ciclo: o `task-reviewer` exige TASK/PLAN/SPEC + report do implementer; o `/keelson:audit` cobre só CVE de dependência; o `/keelson:integrate` só valida DoD de PLAN concluído. O hook `review-guard` cutucava ("rode o task-reviewer OU aplique o checklist") sem existir comando que fizesse isso. Resultado prático: revisão avulsa acabava feita pela própria sessão que escreveu o código — colapso de gerador ≠ avaliador, exatamente o que a 4.30 fechou na Entrega.

**Decisão**:
- **`/keelson:review [alvo]`** (humano-only): revisa um diff resolvido de working tree, `staged`, `last`, `-N` commits, `<sha>`, range `<a>..<b>` ou `branch`. Diff vazio → para; par (alvo resolvido, SHA) registrado no report (identidade do código — 4.30).
- **Coreografia de tech lead, não de revisor**: a main session **não revisa e não corrige**. Despacha `task-reviewer` (gates 1–7) e `security-reviewer` (gate 8, área sensível + `gates.security`) **em paralelo**; consolida, deduplica e classifica; despacha a correção ao `task-implementer` com **briefing efêmero** (cada achado é um AC: deixa de existir sem quebrar teste); **re-revisa** obrigatoriamente o código corrigido, mais `task-verifier` (gate 9) quando a correção tem efeito observável. Report anterior nunca aprova código novo.
- **Classificação binária do achado**: *corrigível agora* (localizado, sem decisão de produto/arquitetura) → correção no ato; *estrutural* (arquitetura, contrato público, modelo de dados, comportamento observável, decisão de produto) → **demanda** (`/keelson:triage` ou TASK de bugfix), nunca edição no ato — mesma régua do `/keelson:audit`. Na dúvida, estrutural. Achado de segurança crítica/alta com correção estrutural é bloqueio explícito no output, não adiamento silencioso.
- **Autonomia**: reporta, pede **um** OK para a leva de correções e depois não para mais (4.23/4.24). `--fix` dispensa até esse OK.
- **Régua dos gates 1–7 com dono único em `guidelines/core/CODE-REVIEW.md`**: o que cada gate exige, o que o faz falhar, a mecânica escopada de teste/lint e a **calibração de severidade** (migrada do `task-reviewer`). O `task-reviewer` fica só com o protocolo (input, fluxo, output YAML, retry, limites) + o que é específico de revisar uma TASK; o novo comando consome a mesma régua. Sem isso, os gates existiriam em dois arquivos e divergiriam.
- **Degradação declarada**: sem artefato SDD, o gate 1 exige prova para toda lógica de negócio nova/alterada (a exigência não depende de AC escrito), o gate 4 vira coerência do diff + Art. 6, e o gate 5 se ancora nas decisões irreversíveis do INDEX quando o slug é inferível (senão `n/a`). Gates 2, 3, 6 e 7 valem integralmente. **Gate degradado ou `n/a` é sempre declarado** — silêncio sobre um gate lê-se como aprovação.
- **Sem rastro durável**: não commita (o commit é do humano), não gera artefato em `{docsRoot}` e não promove Status. Revisão avulsa não é etapa do ciclo.

**Custo assumido**: um comando novo com coreografia própria (mais um lugar onde a independência dos papéis pode colapsar se a main session tomar atalho) e a régua dos gates passando a exigir uma leitura a mais no caminho quente do `task-reviewer` — mitigado por ele já referenciar o `CODE-REVIEW.md` no gate 7. Correção sem TASK também significa mudança sem rastro em `{docsRoot}`: aceito porque o alvo é justamente código que já estava fora do ciclo, e o achado estrutural continua obrigado a virar demanda.

**Aplicação**: `commands/review.md` (novo) + os 4 lugares de comando (README tabela *Commands*, method-guide §3.14, `templates/CLAUDE.keelson-block.md` — humano-only, este arquivo), `guidelines/core/CODE-REVIEW.md` (dono único da régua 1–7 + degradação sem artefato + calibração de severidade), `agents/task-reviewer.md` (gates viram ponteiro; calibração removida; modo revisão avulsa), `agents/task-implementer.md` (modo revisão avulsa: sem TASK, sem commit), descriptions de `task-reviewer`/`task-implementer`/`task-verifier`/`security-reviewer` (citam o novo invocador), `hooks/review-guard.sh` (mensagem passa a citar o comando). Capacidade nova → minor: plugin 0.17.0 → 0.18.0.

---

### 4.37 — Modelo de time: elenco com nomes da vida real + contrato Diretor–PO + sinais laterais

**Problema**: os papéis do keelson já formam estruturalmente um time (implementer, reviewer, verifier, gates com donos distintos), mas a nomenclatura técnica esconde isso — o modelo mental de quem usa não conversa com o de um time real. Além disso, o humano ocupava o papel de PO (aprovação de produto na SPEC, aceitação da entrega), o que o mantém como aprovador de artefatos em vez de emissor de intenção; e a comunicação entre agentes era só vertical (implementer → reviewer → gates) — as interações que fazem um time parecer time (QA apontando ambiguidade antes do código, dev sinalizando furo no plano em vez de contornar) não tinham nome, rota nem registro.

**Decisão (do humano, em conversa de design)**:
- **Elenco com nomes da vida real** — fase 1: a metáfora entra na linguagem (doutrina, narração dos comandos, descriptions), **IDs técnicos mantidos**; rename duro dos agents só numa fase 2, se a linguagem colar. Mapeamento: **Diretor** = humano; **PO** = agente novo (dono da demanda); **Tech Lead** = main session (`/keelson:implement`, `/keelson:review`, `/keelson:auto` — formaliza o que a 4.36 já dizia); **Developer** = `task-implementer`; **Code Reviewer** = `task-reviewer`; **QA** = `task-verifier`; **Security Engineer** = `security-reviewer`; **Agile Coach** = `process-tuner`; **Staff Engineer** = `profile-writer`. Os validators (`spec-validator`, `plan-validator`, `task-validator`) ficam **deliberadamente fora da metáfora**: são ferramentas do time, não pessoas — vestir crachá em linter enfraquece a metáfora onde ela funciona.
- **PM (Product Manager) — cadeira reservada, não instanciada**: na empresa do humano o PM fica **acima** do PO; no keelson o espaço acima do PO pertence ao Diretor (intenção). O que caberia a um PM é a camada de **portfólio**: brief que abrange várias demandas (épico, roadmap, FEATs da 4.27) sendo decomposto e priorizado em demandas individuais, cada uma entregue ao PO. Essa camada ainda não existe no fluxo (`/keelson:specify-epic` é decisão em aberto, §8) — criar o agente agora seria cadeira vazia. **Gatilho de instanciação**: quando a camada épico/roadmap entrar, o PM nasce como dono da decomposição do brief multi-demanda. Registrado também o porquê de o `product-critic` **não** virar PM: o critic prepara crítica que o PO resolve — batizá-lo de PM colocaria um PM hierarquicamente abaixo do PO, invertendo o modelo mental da vida real que a metáfora quer aproveitar.
- **Contrato Diretor–PO**: o humano deixa de aprovar artefatos de rotina e passa a emitir intenção. (a) O pedido do Diretor vira **brief**, artefato-âncora da demanda: pedido capturado como dito + interpretação do PO. O PO **nunca valida contra a própria opinião; valida contra o brief** — mitigação de o sistema aprovar a si mesmo. (b) **Checkpoint único e barato**: o PO devolve a interpretação do brief em ~5 linhas e segue **sem esperar resposta** — janela de veto, não aprovação (coerente com 4.23/4.24: fôlego não é gatilho). (c) **Escalação por exceção**, sempre com proposta + default ("sigo com A a menos que diga o contrário"), só em 4 casos: ambiguidade que muda o resultado; expansão/conflito de escopo; ação irreversível/externa; conflito com diretriz anterior do Diretor. (d) Decisão do PO não derivável do brief entra no registro de **decisões tomadas em nome do Diretor**, auditável na entrega. (e) Na entrega, o PO produz **relatório de aceitação** (pedido vs entregue, evidência de alinhamento ao brief — distinto do QA, que prova que *funciona* —, decisões em nome do Diretor, o que ficou de fora e por quê). O `product-critic` passa a operar sob o PO: o analyst critica, o PO resolve pelas lentes do brief e escala só o que não consegue resolver (fazedor ≠ aprovador preservado).
- **Merge e deploy permanecem do Diretor** — motivo registrado: pode haver outras sessões trabalhando na mesma base de código, e nem sempre o merge imediato é o melhor caminho. A autonomia termina nos **commits** da demanda (comportamento que já existe); abrir PR, merge e deploy são atos do Diretor (PR sob demanda via `/keelson:integrate`, que segue humano-only). *(Emenda 4.41: leia-se "termina no **push da branch de trabalho**, sem PR" — o comportamento que já existia, fixado na 4.10, inclui o push.)*
- **Sinais laterais com contrato** (gatilho, rota e registro definidos — sem contrato, comunicação lateral é ruído): **escalação** (PO → Diretor, critérios acima); **furo no plano** (Developer → Tech Lead: task revelou premissa errada do PLAN — sinalizar é o comportamento premiado, contornar em silêncio é violação de gate; quem decide o destino do furo é o Tech Lead, nunca o dev); **cenário ambíguo** (QA → PO, *antes* do código: AC não verificável ou borda sem resposta — completa a 4.34; a rota é o PO, que responde pelo brief e só sobe pelos critérios de escalação); **achado fora de escopo** (Reviewer/QA → Tech Lead: registro para triagem sem inchar a task); **alerta de segurança** (já existe: rejeição imediata); **aceitação** (PO → Diretor). O boletim entre waves passa a ser narrado em linguagem de time, endereçado ao Diretor, fechando com o estado de pendência ("nada pendente de você" é a experiência-alvo).

**Custo assumido**: um agente novo (PO) no caminho quente de toda demanda; a aprovação de produto deixa de ser humana por rotina — o preço é confiar o alinhamento ao par brief + auditoria na aceitação, com o veto como rede. A metáfora cria expectativa de continuidade/memória que agentes por-invocação não têm — a doutrina deve ser honesta sobre isso. Fase 1 sem rename evita a sincronização cara (commands, README, method-guide, template, consumidores re-rodando init), mas convive com dois vocabulários (nome de papel na narração, ID técnico nos artefatos) até a fase 2.

**Aplicação**: nesta leva, registro do contrato — este arquivo + `CLAUDE.md` do repo (seção "Modelo de time e contrato do Diretor"). Implementação na doutrina é trabalho subsequente (candidatos: agente PO novo, brief como artefato, ganchos dos sinais laterais em `commands/*`, narração dos boletins, `product-critic` sob o PO); cada peça implementada referencia esta decisão.

---

### 4.38 — Operacionalização do contrato Diretor–PO (fase 1 do modelo de time)

**Problema**: a 4.37 ratificou o contrato (brief, PO, sinais laterais, boletim), mas nada o implementava: o espelho do entendimento (4.14) era confirmado por AskUserQuestion e morria na conversa; a aprovação de produto era declarada "gate humano" no `product-critic`; os embriões dos sinais laterais (o parar-e-reportar do implementer, o campo `notas` livre) não tinham nome, rota nem registro durável; e nenhum artefato ancorava a aceitação da entrega.

**Decisão**:
- **BRIEF artefato durável**, dono único no `index-contract.md` (template, ciclo de vida `Emitido → Aceito`, veto → re-emissão, nunca apagar): `{docsRoot}/<slug>/briefs/BRIEF-NNN.md`, NNN pareado 1:1 com a SPEC que nasce dele. Só no **ciclo formal** (feature/risco); bug/refactor usam espelho inline sem arquivo; trivial sem brief. SPEC ganha front-matter `Brief:`; `rebuild-index` lê `briefs/` e alerta par brief↔SPEC órfão (alerta, não bloqueio).
- **Janela de veto substitui a confirmação do espelho** no autônomo (opção B escolhida pelo Diretor): a interpretação é apresentada no corpo da conversa e o fluxo segue sem esperar; silêncio = seguir. Perguntas pré-largada só pelos **4 critérios de escalação** (régua no `agents/po.md`), com proposta + default. Guided: brief confirmado na hora; CHECKPOINT 1 = PO recomenda, Diretor decide (cláusulas de modo explícitas nos dois lados — 4.33).
- **Agente `po`** (read-only; modos aprovação/aceitação/resolução): resolve a crítica do `product-critic` contra o brief; `APROVAR` → a main session promove a SPEC no autônomo; `ESCALAR` → escada com a proposta+default do PO. Quem **redige** a interpretação na largada é a main session (Tech Lead): a independência do PO é exigida na **validação**, não na redação — o corretor da redação é a janela de veto. `product-critic` vira **Product Analyst** sob o PO; `/keelson:specify` avulso (sem BRIEF) mantém a promoção com o humano.
- **Sinais laterais nomeados**: **furo no plano** (`falhas[].categoria: furo_no_plano` no report do implementer; contornar em silêncio = violação de gate; destino decidido pelo Tech Lead — ajuste de TASK, mudança de PLAN ou PO/humano quando é produto; registro no Histórico do INDEX); **fora de escopo** (campo estruturado `fora_de_escopo[]` nos reports de implementer/reviewer/verifier, roteado ao Tech Lead — estaciona, não infla a task); **cenário ambíguo pré-código** (modo pré-código do `task-verifier` na Etapa 3.5 do auto, só feature/risco — completa a 4.34; quem resolve pelo brief é o `po`).
- **Entrega**: relatório de aceitação do PO como seção obrigatória (`RECUSADA` = gate reprovado antes do report final; `ACEITA` → BRIEF marcado `Aceito`); "Caminho tomado" reintitulado **"decisões em nome do Diretor"**; boletim de wave em linguagem de time, emitido inline com o início da wave seguinte (nunca parada — 4.23/4.24, `wave-guard`).

**Custo assumido**: 1–3 spawns novos por ciclo formal (po nas aprovações/aceitação + verifier pré-código em feature/risco). A promoção de SPEC deixa de ter confirmação humana no autônomo — a rede é o trio brief + janela de veto + auditoria na aceitação, com o veto do Diretor como corte final. Bug/refactor sem arquivo de brief: aceitação contra o espelho inline, menos auditável — aceito pelo custo.

**Aplicação**: `agents/po.md` (novo), `agents/{product-critic,task-implementer,task-reviewer,task-verifier}.md`, `commands/{auto,specify,guided,implement,rebuild-index}.md`, `docs/_meta/conventions/index-contract.md` (contrato do BRIEF), `docs/_meta/method-guide.md` (§3.9, §3.10, §5 com o elenco do time), `CLAUDE.md`, `README.md`. Capacidade nova → minor: plugin 0.18.0 → 0.19.0.

---

### 4.39 — PM instanciado + `/keelson:specify-epic` (fase 2 do modelo de time)

**Problema**: a 4.37 reservou a cadeira do PM com gatilho definido ("quando a camada épico/roadmap entrar"), e o Diretor disparou o gatilho: um pedido grande pode chegar a qualquer momento e não tinha rota — a triagem não conhecia "épico" (a categoria mais próxima, Inconclusivo, trata mistura de naturezas, não tamanho), a camada FEAT (4.27) agrupa **dentro** de uma SPEC, e nada decompunha um pedido multi-demanda em ciclos.

**Decisão**:
- **Agente `pm`** (read-only): decompõe o pedido épico em demandas **independentes, priorizadas e roteáveis** (título, resumo, slug de destino pela regra canônica de slug, prioridade, dependências, riscos) + `perguntas_ao_diretor` com proposta + default. Não conduz ciclos nem decide produto de demanda individual (isso é do PO de cada ciclo).
- **`/keelson:specify-epic`** (modo humano presente): resolve o slug-âncora (iniciativa que merece épico merece slug — sem "slug portfólio"), invoca o `pm`, apresenta a decomposição **no corpo da conversa** e confirma com o Diretor via AskUserQuestion binária (a tabela nunca embutida na pergunta — lição do espelho, 4.14). A confirmação é a **única parada, e é intencional**: decomposição errada contamina N ciclos ("ambiguidade que muda o resultado" em escala). Persiste o **BRIEF épico** e devolve a fila com o comando pronto para a demanda 1; **disparar cada ciclo é ato do Diretor** — o comando nunca invoca `/keelson:auto`.
- **BRIEF épico com id por data** — `briefs/BRIEF-<yyyy-mm-dd>-<descricao>-epic.md` (variação no `index-contract.md`): desvio deliberado do `BRIEF-NNN` planejado, porque o épico **não pareia com SPEC** e a numeração NNN é definida como "nº da SPEC pareada" — usar NNN colidiria com o par 1:1 das filhas; o precedente de id por data é o dos handoffs. Cada filha ganha seu `BRIEF-NNN` normal no slug de destino quando o ciclo dela começa, com `**Epico**:` apontando ao pai; `rebuild-index` confere filhas cross-slug **best-effort** (nunca falha o rebuild do slug).
- **Rotas de chegada**: categoria **7. Épico / multi-demanda** na tabela do `/keelson:triage` (2+ capacidades independentes, 2+ slugs prováveis, roadmap numa frase) e proposta na triagem de rigor do `/keelson:auto` — **só pré-largada**; pós-largada, expansão de escopo é escalação do PO (4.38), jamais decomposição silenciosa (sem loop auto → specify-epic → auto automático).

**Custo assumido**: mais um comando e um agente no elenco; a fila de demandas depende do Diretor para avançar (deliberado — evita sessão-monstro multi-ciclo e preserva "1 demanda = 1 ciclo"). Qualidade da decomposição do PM só se prova em rodada real.

**Aplicação**: `agents/pm.md` (novo), `commands/specify-epic.md` (novo), `commands/{triage,auto,rebuild-index}.md`, `docs/_meta/conventions/index-contract.md` (variação épico + campo `Epico:`), `docs/_meta/method-guide.md` (§3.15 novo + linha `pm` no §5), `README.md` (tabela *Commands* + Status). Comando novo → minor: plugin 0.19.0 → 0.20.0.

---

### 4.40 — Rename dos IDs dos agents para os nomes dos papéis (fase 3 do modelo de time)

**Problema**: com o elenco da 4.37 em vigor, conviviam dois vocabulários — a narração falava por papel ("Developer", "QA") enquanto artefatos e invocações usavam os IDs técnicos (`task-implementer`, `task-verifier`). A 4.37 condicionara o rename a "se a linguagem colar" numa rodada real; **o Diretor revogou a condição explicitamente** e mandou executar as 3 fases do modelo de time na mesma leva.

**Decisão**:
- **De-para**: `task-implementer→developer` · `task-reviewer→code-reviewer` · `task-verifier→qa` · `security-reviewer→security-engineer` · `product-critic→product-analyst` · `process-tuner→agile-coach` · `profile-writer→staff-engineer` (`po` e `pm` já nasceram como papéis, 4.38/4.39).
- **Rename atômico**: `git mv` + frontmatter `name:` + heading `# Subagent:` + todas as referências vivas num único commit — commands, skills, hooks (comentários **e** textos de nudge), `guidelines/core/`, `PROFILE-OUTLINE.md`, conventions, method-guide, `CLAUDE.md`, `README.md`. Rename parcial deixaria command invocando agent inexistente.
- **Histórico não se reescreve**: `decisions.md` e `learning-log.md` mantêm os IDs antigos nas entradas, com nota de rename no topo de cada — esta entrada é a fonte do de-para. Referência viva em cabeçalho de doc (ex.: "mantido pelo agent X") **é** atualizada: viva ≠ histórica.
- **`generated-by:` é fato histórico, não referência viva**: os perfis gerados `guidelines/backend/php-*.md` mantêm `generated-by: profile-writer` (carimbo de proveniência da geração passada); gerações futuras carimbam `staff-engineer`.
- **Template do consumidor**: zero IDs de agent → **sem re-init**; o bump minor no marketplace cobre a atualização do plugin.

**Custo assumido**: leitor de histórico precisa do de-para para ligar entradas antigas aos agents atuais; risco residual de invocação por nome antigo vinda de prompt/contexto externo ao repo — a observar na 1ª rodada real com o plugin recarregado.

**Aplicação**: `agents/*` (7 renomeados; elenco final com 9), referências vivas em `commands/`, `skills/`, `hooks/`, `guidelines/`, `docs/_meta/`, `CLAUDE.md`, `README.md`; notas de topo em `decisions.md` e `learning-log.md`. Rename → minor: plugin 0.20.0 → 0.21.0.

---

### 4.41 — Varredura de coerência do modelo de time: promoção com cláusula de modo, aceitação pré-commit, rota risco, bloco do consumidor

**Problema**: revisão de coerência pós-4.37–4.40 (3 lentes independentes: espinha do `/auto`, papéis, conflitos de decisão — mesmo espírito da 4.33) achou 7 conflitos reais e um rastro de seções/frases pré-modelo: (a) "promoção de Status é sempre humana/manual" sobrevivia em 6 donos vivos (sdd-conventions, WORKFLOW, validator-protocol, method-guide ×2, product-analyst), contradizendo a 4.38; (b) o `specify` não tinha canal de entrada do BRIEF (front-matter `Brief:` sem preenchedor; NNN renumerado em vez de reutilizado); (c) o relatório de aceitação estava posicionado **depois** do commit/push — `RECUSADA` chegava tarde; (d) a aceitação bug/refactor era inexecutável (po exigia arquivo de BRIEF); (e) a rota risco gerava BRIEF órfão (pareamento 1:1 exige SPEC) e a Etapa 3.5 a incluía sem ela ter TASKs do `/keelson:tasks`; (f) a resposta do PO virava "nota na TASK" no único campo proibido (closure) — ERROR de task-validator; (g) contratos de input incompletos (po modo resolução × furo de produto; qa pré-código sem input declarado). Mais: guided sem a correção de slug/NNN do f639fec, fronteira "termina nos commits" contradita pelo push da Etapa 5, seções normativas do próprio decisions.md (§2/§3/§5.4/§6.1/§7/§8) com elenco antigo, 4.8/4.14 sem nota de emenda, bloco do consumidor ensinando o fluxo pré-modelo (garantia da 4.10 furada), e ~30 resíduos cosméticos de vocabulário/persona.

**Decisão (o Diretor mandou aplicar tudo)**:
- **Promoção com cláusula de modo** em todos os donos: nunca é do validator; ciclo com BRIEF (autônomo) → main session promove pelo veredito `APROVAR` do `po`; sem brief ou guided → humana.
- **Aceitação do PO vira item 2.5 da Entrega** (antes do commit/push): composição do diff montada ali e reusada no report; `RECUSADA` reprova antes de commitar. 6.1/6.2 passam a referenciar o 2.5.
- **Espelho inline vale como brief para o po** (rotas bug/refactor e TASK avulsa de risco) — input do agent relaxado; **rota risco sem SPEC usa espelho inline** (arquivo de BRIEF só com SPEC, preservando o pareamento 1:1) e fica **fora** da Etapa 3.5 (restrita a TASKs geradas pelo `/keelson:tasks`).
- **Resposta do PO pré-código reescreve o critério/AC ambíguo na TASK** (nunca campo de closure) — o critério fica verificável, o task-validator fica verde.
- **Contratos fechados**: `specify` Etapa 0.2 ganha o passo 7 (reutilizar slug/NNN da largada + preencher `Brief:`); guided resolve slug/NNN antes de gravar o brief; po modo resolução aceita furo de produto do developer (devolve resolução de produto; o como técnico é do Tech Lead); qa pré-código declara input (TASKs + ACs literais + BRIEF) e output YAML `achados[]`; degrau 3 encerra o `run-state` antes de terminar turno sem resposta; Etapa 4.6 não regenera handoff da rota formal; refine preserva o pedido cru (`> Pedido original:`) para o "Pedido como dito" e cede o dono do artefato ao index-contract (mantendo o das 4 seções).
- **Fronteira reescrita**: "a autonomia termina no **push da branch de trabalho**, sem PR" (emenda registrada na 4.37; CLAUDE.md, WORKFLOW, sdd-conventions alinhados).
- **decisions.md normativo atualizado**: §2/§3 (elenco novo + commands/skills completos), §5.4 (IDs novos + os 2 bloqueios da 4.38 fora da numeração), §6.1, §7 (rota épico), §8 (specify-epic/PM e request-mirror resolvidos); notas de emenda em 4.8 e 4.14.
- **Bloco do consumidor ensina o modelo real** (o uso principal do plugin é o autônomo — diretriz do Diretor): modo padrão autônomo, contrato Diretor–PO em 1 parágrafo, aceitação do PO na definição de pronto. Repara a garantia da 4.10. **Exige re-rodar `/keelson:init` nos consumidores.**
- **Personas alinhadas ao elenco**: main session abre como Tech Lead em implement/guided/triage/review; agents abrem com o papel (Code Reviewer, QA, Product Analyst, Agile Coach); `plan.md` vira "Arquiteto de Software" (colisão com o crachá `staff-engineer`); regra nova de sincronização de **agent** no CLAUDE.md (o buraco pelo qual os resíduos passaram).

**Custo assumido**: o bloco novo do consumidor só vale após re-init; a promoção condicionada ao veredito do po depende de os donos serem lidos com a cláusula completa (frase mais longa em 6 lugares — preço de não ter duas verdades). Cosméticos de vocabulário varridos por grep com allowlist de histórico.

**Aplicação**: `guidelines/core/WORKFLOW.md`, `docs/_meta/conventions/{sdd-conventions,agent-teams}.md`, `skills/_shared/validator-protocol.md`, `commands/{auto,specify,guided,implement,tasks,plan,triage,review,refine}.md`, `agents/{po,qa,product-analyst,code-reviewer,agile-coach}.md`, `docs/_meta/method-guide.md` (§2/§4/§5/§7/3.9/3.14), este arquivo (§2/§3/§5.4/§6.1/§7/§8 + notas 4.8/4.14/4.37), `templates/CLAUDE.keelson-block.md`, `CLAUDE.md`, `README.md`. Doutrina + bloco novo → minor: plugin 0.21.1 → 0.22.0.

---

### 4.42 — agent-guard: trabalho do ciclo só com o elenco + regra de execução dos validators

**Problema**: transcript de rodada real (consumidor `aav-backoffice`) mostrou a validação de SPEC despachada a um subagent `general-purpose` com prompt improvisado. A escolha do `subagent_type` é do modelo a cada spawn e nada a corrigia: um agent genérico não carrega a doutrina do papel (input esperado, gates, formato de report), e um validator executado "de memória" usa outra régua. No mesmo transcript o elenco funcionou onde há agent (crítica via `keelson:product-critic` confirmada) — o furo era a ausência de garantia mecânica e de regra para onde a *skill* de validação roda.

**Decisão**:
- **Regra de execução das skills validator** (dono: `validator-protocol.md` §2): a skill roda na main session **ou** num subagent executor cujo briefing **cita o caminho do SKILL.md canônico**, com instrução de aplicá-lo integralmente e devolver o output no formato do protocolo. Subagent genérico validando sem ler o SKILL.md é desvio.
- **Hook novo `hooks/agent-guard.sh`** (PreToolUse, matcher `Task|Agent`): `keelson:*` passa sempre; spawn genérico cujo prompt tem **fingerprint de trabalho de papel** (verbos de papel — gates, crítica de mérito, modos do po/qa, implementar TASK —, nunca a mera menção a um artefato: exploração/pesquisa passam) → `deny` único com instrução de refazer a chamada com o agent do elenco; validator genérico **sem** a citação de SKILL.md → `deny` único com a regra do §2. Anti-renudge por fingerprint (`git hash-object` de tipo+texto; a **segunda tentativa idêntica passa** — válvula para uso genérico intencional). Gate de contexto: só age em projeto com ficha ou no repo dev do plugin. Fallback gracioso (sem `jq`/input parseável → `exit 0`).

**Custo assumido**: heurística por regex — falso positivo custa 1 deny + retry (a segunda passa); falso negativo deixa o desvio passar. O guard **reduz** o desvio deterministicamente, não o elimina: garantia absoluta não existe, o `subagent_type` é escolha do modelo. Validado com teste sintético de 8 casos (elenco, trabalho de papel, anti-renudge, validator sem/com SKILL.md, exploração, fora de projeto keelson, input lixo) + `bash -n`.

**Aplicação**: `hooks/agent-guard.sh` (novo), `hooks/hooks.json` (matcher `Task|Agent`), `skills/_shared/validator-protocol.md` (§2), `README.md` (linha de hooks). Capacidade nova → minor: plugin 0.22.1 → 0.23.0.

---

### 4.43 — Sync Jira: viabilidade antes da criação, régua de hierarquia no core e fim do "front-matter" fantasma

**Problema**: transcript de um `/keelson:jira-sync <slug> --dry-run` real (consumidor `aav-backoffice`, projeto OPS) mostrou o agente tateando por quatro furos da própria doutrina, todos convergindo no mesmo meio-estado ruim. (a) **"front-matter" fantasma**: o protocolo mandava gravar/ler a key da SPEC "no front-matter" (§4, §5, §6, §10 + 2 pontos do comando), mas a SPEC do keelson **não tem YAML front-matter** — a key mora na linha `**Jira**:` do cabeçalho markdown (template do `specify`); o agente rodou um `awk` de front-matter, voltou vazio e teve que descobrir a estrutura por inspeção. (b) **Régua de adjacência no arquivo errado**: o pré-check de `hierarchyLevel` (4.28) vivia só no `jira-sync-feat.md`, que é **no-op quando o 3º nível está inativo** — exatamente o cenário do slug (7 SPECs sem FEAT); o core §7 só cobria o caso `subtask:false`, e a combinação `spec`=Epic(1) + `task`=Subtarefa(-1) **sem** nível 0 no meio não existia em lugar nenhum. Resultado de um sync real: 7 Epics órfãos criados e 70 sub-tasks rejeitadas uma a uma pelo Jira. (c) **Sem pré-condição de viabilidade**: a Etapa 0 do comando validava ficha, slug e conector, mas não se a projeção era possível — o bloqueio só apareceu depois do panorama das 70 TASKs montado. (d) **Idempotência ancorada só em key local**: o agente improvisou uma sondagem JQL anti-duplicata (passo sensato, que cobre o sync que criou a issue e falhou ao gravar a key) sem nenhum respaldo no protocolo — cada sessão inventaria a sua.

**Decisão**:
- **Nomear o lugar certo**: some "front-matter" da doutrina de Jira; a key da SPEC é a **linha `**Jira**:` do cabeçalho markdown**, com **receita de localização** explícita (`grep -n '^\*\*Jira\*\*:'`, `grep -n -A2 '^### FEAT-'`) no §4 — mesma filosofia do `grep -n "^## §"` que os ganchos já usam para navegar o protocolo.
- **Régua de adjacência promovida ao core** (§7.0, dono único): tabela das combinações reais (3 níveis pleno · 2 níveis válido · 2 níveis inviável · fallback `subtask:false`), resolvida **uma vez no início**, nunca issue a issue. O `jira-sync-feat.md` passa a **referenciar** o §7.0 em vez de duplicar a régua (decisão 4.20).
- **Degradação em 2 níveis** para o caso Epic(1) ▸ Subtarefa(-1): (i) `issueType.standalone` adjacente ao `spec` → as TASKs projetam como isoladas sob o Epic, cada uma sua própria unidade de QA (é a mesma saída do degrau (iii) da 4.28, agora disponível **sem** o 3º nível); (ii) sem `standalone` → **não criar** e avisar que o slug precisa declarar FEATs ou reconfigurar `issueType`. Sub-task órfã ou sob nível não-adjacente nunca é tentada. Corolário no §6: issue-mãe **não** é criada quando nenhuma projeção de filhos é possível — Epic órfão não é progresso.
- **Viabilidade é pré-condição**, não descoberta: nova Etapa 0.4 do `/keelson:jira-sync` cruza `hierarchyLevel` × declaração de FEATs e classifica a projeção em 1 linha (também no Output); inviável → o plano vira diagnóstico + recomendação, sem listar criações que o Jira rejeitaria. O gancho do `specify` passa a ler o §7.0 pelo mesmo motivo (avisar na primeira SPEC, não na centésima TASK).
- **Sondagem anti-duplicata** documentada no §4: recomendada antes de criar em lote sem nenhuma key local, **obrigatória** no `--dry-run` — `searchJiraIssuesUsingJql` por `summary` correspondente; correspondência plausível → reportar e não criar.
- **Ficha ausente ≠ desligada**: a Etapa 0 do comando separa os dois casos e manda rodar de dentro do consumidor, em vez de deixar a sessão procurar o projeto pelo disco.

**Custo assumido**: o §7 ganha um sub-heading (§7.0/§7.1) — primeira subdivisão do protocolo core, aceita porque a régua precisa ser alcançável por quem lê só o §7; o pré-check custa uma chamada `getJiraProjectIssueTypesMetadata` por execução (já era feita, agora mais cedo) e a sondagem JQL custa uma busca por slug no dry-run, em troca de não criar duplicata nem meio-estado.

- **Generalização do furo (a)**: "front-matter" virou jargão interno para dois formatos diferentes — YAML real (HANDOFF, perfis, frontmatter de commands/agents/skills) e cabeçalho markdown `**Chave**: valor` (SPEC, PLAN, TASK). A distinção ganha dono único em `sdd-conventions.md`, com a receita de `grep`; as menções remanescentes nos demais comandos passam a ser lidas por ela em vez de exigirem varredura textual.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§4 receita + sondagem, §5, §6 item 0, §7.0 novo + §7.1, §10), `skills/_shared/jira-sync-feat.md` (item 2 → referência ao §7.0), `commands/jira-sync.md` (Etapa 0 passos 1 e 4, Etapa 1 item 1, Output, Limites), `commands/specify.md` (Etapa 5.3), `docs/_meta/conventions/sdd-conventions.md` (bullet "Cabeçalho ≠ front-matter"), `docs/_meta/method-guide.md` (§3.13), os 5 ganchos (receita `grep -n "^#\+ §"`, que agora alcança sub-headings), `README.md` (Jira integration + Status). Doutrina nova → minor: plugin 0.23.0 → 0.24.0.

---

### 4.44 — Story implícita da SPEC sem FEAT + backfill de slug já concluído

**Problema**: segundo dry-run real do mesmo slug (`professional-portal`/OPS), já com a 4.43 aplicada. O comando executou limpo — projeção classificada na largada, sondagem anti-duplicata, zero tateio — e **por isso** expôs dois problemas de mérito que o tateio anterior escondia. (a) O degrau (i) da 4.43 (tarefas isoladas) resolve a *hierarquia* mas erra a *semântica*: projetou 70 Tarefas de nível 0 soltas sob 7 Epics, quando o mapa do próprio projeto declara que **a História é a unidade de QA** e a Subtarefa é quebra de dev. O QA ganharia 70 cards com granularidade de dev em vez de cards de fluxo — e a 4.27 já dizia a resposta certa sem que ninguém a tivesse ligado ao degrau: *SPEC que não declara FEAT é uma funcionalidade única (a funcionalidade é a própria SPEC)*. (b) O aviso mais útil do output foi **improvisado** pelo agente: as 77 issues nasceriam em "a fazer" sobre trabalho já mergeado na `main`, porque `transition: comment` não move card. O §12 assumia trabalho em andamento e não tinha regra para o caso mais comum da reconciliação — o slug que já terminou.

**Decisão (do humano, escolhendo entre 3 opções apresentadas)**:
- **Degrau (0) "Story implícita"**, antes do standalone: `spec` epic-level ∧ `task` subtask ∧ SPEC sem FEAT ∧ `issueType.feature` preenchido → criar **uma Story espelhando a SPEC** sob o Epic (`summary` = título da SPEC), com as TASKs como sub-tasks **dela**. Preserva a Story como unidade de QA e a hierarquia desenhada, sem exigir retrabalho de produto nas SPECs. A escada do §7.0 fica: **(0)** Story implícita → **(i)** `standalone` sob o Epic (sem `feature`, ou Story falhou) → **(ii)** parar com diagnóstico.
- **Não é substituto de declarar FEATs**: numa SPEC com vários fluxos a Story implícita é um card grosso demais para o QA. O sync **reporta isso em 1 linha e segue** — declarar FEAT é decisão de produto do humano, nunca do tracker.
- **Key própria**: `**Jira Story**:` no cabeçalho da SPEC, abaixo do `**Jira**:` do Epic — as duas issues coexistem e representam camadas diferentes (roadmap × unidade de QA). Tolerada e ignorada pelo `spec-validator`, como as demais linhas de tracker.
- **Marco de QA**: a Story implícita recebe "pronta p/ QA" quando **todas** as TASKs da SPEC estão `Done` (mesma semântica da FEAT completa).
- **Backfill de slug concluído** (§12): antes de criar em lote, medir o estado real das TASKs; maioria `Done` com `transition: comment`/`off` → **reportar antes do plano** que o quadro nasceria mentindo, com as duas saídas (mudar para `auto` na ficha × alinhar manualmente). O sync **nunca** altera a ficha nem força transição por conta própria — política de transição é decisão do projeto (§0/§9).
- **Panorama pelo INDEX**: a Etapa 0 do comando manda ler o `INDEX.md` do slug e coletar o resto em uma passada; varrer `{docsRoot}/` inteiro ou `ls -R` do slug é desperdício (o dry-run listou 37 pastas antes de abrir o artefato que já tinha o panorama).

**Custo assumido**: a projeção degradada passa a criar 1 issue a mais por SPEC (Epic + Story com títulos espelhados), aceito porque a alternativa é o QA perder o card de fluxo; o cabeçalho da SPEC ganha uma quarta linha possível de tracker.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§6.1, §7.0 escada (0)/(i)/(ii), §9, §10, §12 backfill), `commands/jira-sync.md` (Etapa 0 passos 2/4/5, Etapa 1 item 2, Output), `commands/specify.md` (template do cabeçalho + Etapa 5.3), `skills/spec-validator/SKILL.md` (tolerância), `docs/_meta/method-guide.md` (§3.13), `README.md` (Jira integration + Status). Doutrina nova → minor: plugin 0.24.0 → 0.25.0.

---

### 4.45 — Pré-check de campos obrigatórios + formas canônicas de contar IDs SDD

**Problema**: terceiro dry-run do mesmo slug (`professional-portal`/OPS), com 4.43+4.44 aplicadas. O comando produziu o plano certo (84 issues: 7 Epics + 7 Histórias implícitas + 70 sub-tasks), com o backfill na frente e dois achados de artefato do consumidor levantados por conta própria. Sobraram três defeitos, dois deles no *modo de contar*: (a) **nenhum pré-check de campos obrigatórios** — o plano autoriza 84 criações sem nunca ter perguntado ao createmeta se algum campo `required` fica descoberto; um obrigatório faltando não é "campo pulado" (§0/§8, que trata rejeição de campo), o Jira **recusa a issue inteira**, e a descoberta chegaria na enésima criação, deixando o slug pela metade; (b) o glob `tasks/TASK-*.md` contou os `TASK-NNN-INDEX.md` como tarefas e inflou a distribuição por SPEC (77 em vez de 70) — reconciliado depois na tabela final, mas por sorte, não por regra; (c) a contagem de FRs por SPEC usou `grep -c '^\*\*FR-'`, que devolve **zero** porque a lista da SPEC é bullet (`- **FR-...**`), e o fallback contou ocorrências em vez de requisitos — os números do output vieram do INDEX, não do comando que ele mesmo rodou.

**Decisão**:
- **Pré-check de obrigatórios (§8)**: antes de criar em lote, uma `getJiraIssueTypeMetaWithFields` **por tipo que o plano usa**; campo `required: true` não coberto por `summary`/`description`/`parent` nem por linha `write` do mapa entra nos avisos **antes** da primeira criação. Best-effort como o resto (§0) — a chamada falha, avisa e segue.
- **Fonte de verdade do conjunto de TASKs (§4)**: os **arquivos** `tasks/TASK-*.md` menos `*-INDEX.md`. O `TASK-NNN-INDEX` é panorama; divergência entre a contagem dele e os arquivos (tasks acrescentadas depois da geração) é **aviso**, não bloqueio, e o sync segue pelos arquivos.
- **Formas canônicas de contar/localizar IDs** (dono: `sdd-conventions.md`, ao lado de "Cabeçalho ≠ front-matter"): FR/NFR/AC são bullets (`^- \*\*FR-`), FEAT é heading (`^### FEAT-`), TASKs vêm do glob sem INDEX — com a regra de leitura que faltava: **contagem `0` num artefato notoriamente populado é sinal de padrão errado, não de artefato vazio**.

**Custo assumido**: uma chamada MCP a mais por tipo usado (4 no pior caso), paga uma vez por execução e só quando há criação planejada.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§4 conjunto de TASKs + receita do `**Jira Story**`, §8 pré-check), `commands/jira-sync.md` (Etapa 0 passo 6, Output), `docs/_meta/conventions/sdd-conventions.md` (bullet das formas canônicas), `README.md` (Status). Capacidade nova → minor: plugin 0.25.0 → 0.26.0.

---

### 4.46 — Indisponibilidade do conector é provada, e o pulo do sync deixa rastro durável

**Problema**: caso real, e o mais caro de todos porque passou meses sem ser notado. O consumidor `aav-backoffice` rodou o ciclo com `jira.enabled: true` desde 2026-07-23 e **nenhuma** das 7 SPECs recebeu key — três delas criadas depois da configuração. Investigando, duas coisas ficaram claras: (a) o conector **estava ativo e funcionando** (há chamadas Jira reais nos transcripts das mesmas datas) — a primeira hipótese da sessão, "conector ausente", nasceu de evidência ruim: procurou-se `mcp__*Atlassian*` nos transcripts e concluiu-se ausência, mas ferramentas MCP chegam **deferred** e só aparecem quando buscadas; **"não vi as ferramentas na lista" não é evidência de indisponibilidade**, e um agente aplicando o §0 pode cometer exatamente o mesmo erro de inferência; (b) a causa concreta do pulo **não é mais recuperável** — o §0 mandava "avisar em 1 linha e seguir", e um aviso volátil no meio do output de um `/keelson:auto` é indistinguível de nunca ter acontecido; fechada a sessão, não sobra nada no repositório. O best-effort funcionou como projetado (nunca travou o ciclo) e, justamente por isso, degradou em silêncio por semanas.

**Decisão** — transplantar para o Jira a régua que a 4.26 já estabeleceu para a verificação de tela:
- **Indisponibilidade é provada, não presumida** (§0): antes de concluir que o conector não está disponível, **carregar as ferramentas** (deferred não aparecem até serem buscadas) e fazer **uma** chamada barata de prova (`atlassianUserInfo` / `getAccessibleAtlassianResources`). Só o retorno autoriza a conclusão; o resultado vale para a execução inteira (não se repete a prova por gancho). Corolário no §1: nome de servidor MCP varia por instalação — resolver a ferramenta pelo **sufixo**, nunca por prefixo fixo.
- **Rastro durável do pulo** (§0 + §10): sync pulado ou falho grava **1 linha no "Histórico recente" do INDEX do slug** — data, o que seria sincronizado, motivo e **a evidência da prova** (o que foi tentado, o que retornou). O INDEX passa a registrar as duas pontas (sucesso e pulo), uma linha por execução; o contrato da tabela "PLANs" segue intocado. Sem slug resolvido, a linha vai no relatório final do comando.
- **A reconciliação lê o rastro**: se o "Histórico recente" traz pulos anteriores, o `/keelson:jira-sync` os lista no output — vira o histórico do que ficou para trás e por quê.
- **O `init` prova também**: o self-check da Etapa 6 só pode reportar "sync Jira pulado até autorizar o conector" com a evidência da prova junto.

**Custo assumido**: uma chamada MCP de prova por execução em que há sync a fazer, e uma linha a mais no INDEX quando o sync falha — preço baixo diante de um modo de falha que custou semanas de silêncio. O rastro é **por execução**, não por artefato: não polui o INDEX com uma linha por TASK.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§0 prova + rastro, §1 resolução por sufixo, §10 registro do pulo), `commands/jira-sync.md` (Etapa 0 passo 3), `commands/init.md` (self-check da Etapa 6), `README.md` (Jira integration + Status). Doutrina nova → minor: plugin 0.26.0 → 0.27.0.

---

### 4.47 — `jira-guard`: o gancho de sync deixa de depender de o modelo lembrar

**Problema**: diagnóstico definitivo do silêncio que as 4.43–4.46 vinham perseguindo, obtido lendo **uma sessão em execução** do consumidor (2026-07-26, `aav-backoffice`). Todas as hipóteses anteriores caíram por evidência direta: plugin carregado **0.27.0** (não versão velha), corpo do `/keelson:specify` **com** a Etapa 5.3, corpo do `/keelson:tasks` **com** a Etapa 7, ferramentas Atlassian **presentes no toolset** (nem deferred), `jira.enabled` lido — e **zero** chamadas reais a qualquer ferramenta do Jira, com a SPEC já criada. Nada estava quebrado: **o agente simplesmente não executou o passo**. É o comportamento esperado de um gancho que é a *última* sub-etapa, é *condicional* (`só quando jira.enabled`), custa reler a ficha + abrir um protocolo longo + fazer chamadas MCP, e roda no meio de um `/keelson:auto` cuja missão é entregar código. Texto mandando fazer já existia em dois comandos e foi ignorado; **nada verificava depois** — os gates têm validators, o sync não tinha nada. A 4.46 não cobre este caso: o rastro durável só é escrito por quem **entra** no protocolo; quem nunca o abre não deixa rastro nenhum — que é exatamente o que aconteceu durante semanas.

**Decisão** — a correção precisa ser **mecânica**, no padrão que o keelson já usa para instrução que não sobrevive ao contexto (`wave-guard` 4.23, `agent-guard` 4.42): hook **`jira-guard`** (Stop), que bloqueia o encerramento do turno quando a ficha tem `jira.enabled: true` e há artefato SDD **sem key** do Jira. Regras que o definem:
- **Escopo estreito por branch**: só artefatos **tocados nesta branch** (working tree + diff contra a base). Passivo histórico já mergeado não é problema deste turno e transformaria o guard em renudge perpétuo — no consumidor real seriam 7 SPECs e 70 TASKs legadas cutucando para sempre.
- **Duas saídas, nunca uma só**: sincronizar **ou** registrar o pulo com a prova (§0/§10). O registro no INDEX **dispensa** o guard nas próximas vezes — é o par que fecha a 4.46: quem não abre o protocolo agora é obrigado a abrir ou a declarar por escrito por que não abriu.
- **Moldura dos hooks do keelson**: bash 3.2, `set -euo pipefail`, fallback gracioso (sem `python3`, sem ficha, `enabled:false`, input não parseável → `exit 0`), `stop_hook_active` anti-loop e anti-renudge por fingerprint do conjunto pendente.

**Custo assumido**: um hook a mais no Stop (7 no total) e o risco de falso positivo quando a SPEC nasce numa sessão e o sync acontece na seguinte — mitigado pelo fingerprint (cutuca 1×) e pela saída de registro. Validado com `bash -n` + **12 casos sintéticos** (bloqueio por SPEC, por TASK, anti-renudge, keys presentes, pulo registrado no INDEX, `enabled:false`, sem ficha, input lixo, cwd inexistente, `stop_hook_active`, `TASK-*-INDEX` ignorado, artefato antigo fora da branch). Dois bugs reais morreram no teste: o padrão `[ cond ] && exit 0` **aborta o script** sob `set -e` quando a condição é falsa (o `wave-guard` já usava `if/fi` por isso), e `git status --porcelain` **resume diretório novo numa linha** (`?? docs/slug/tasks/`) — sem `-uall`, as TASKs recém-criadas pelo `/keelson:tasks` passariam inteiras despercebidas.

**Aplicação**: `hooks/jira-guard.sh` (novo), `hooks/hooks.json` (Stop), `README.md` (linha de hooks + Status). Capacidade nova → minor: plugin 0.27.0 → 0.28.0.

---

### 4.48 — `CHANGELOG.md`: o histórico de releases sai da prosa do README e vira artefato

**Problema**: o keelson chegou a 28 versões sem changelog. O histórico existia em três formas, todas ruins para quem consome o plugin: (a) o `git log`, que registra *commits*, não releases — a fronteira de versão só é recuperável rodando `git log -p` no `plugin.json` (não há tags: `git tag -l` volta vazio); (b) a seção *Status* do `README.md`, que virou changelog acidental em prosa acumulativa ("New in this release… Previously… Recent…") — 45 linhas para 3 releases, sem data, sem versão nos parágrafos antigos e sempre reescrita por cima, de modo que o texto da versão anterior é **perdido**, não arquivado; (c) `decisions.md`, que é dono do *porquê* e não do *o quê mudou por versão* — a linha "plugin 0.27.0 → 0.28.0" no fim de cada decisão é o único mapeamento versão↔mudança, e não existe caminho inverso (dada a versão, o que entrou nela). Consequência prática: quem roda `/plugin update keelson` não tem como saber o que mudou, e a §*Status* pagava um custo crescente de manutenção para fazer mal um trabalho que um arquivo dedicado faz bem.

**Decisão**:
- **`CHANGELOG.md` na raiz**, no formato Keep a Changelog, **retroativo até a 0.1.0** — 38 entradas reconstruídas a partir dos bumps do `plugin.json`, das mensagens de commit e das decisões correspondentes. Detalhe proporcional à idade: releases recentes com os bullets completos, releases antigas em 1–3 linhas. Anomalias ficam registradas em vez de corrigidas (a **0.14.0 nunca existiu** — a leva 4.31–4.33 pulou de 0.13.0 para 0.15.0 acompanhando o Charter).
- **Bump exige entrada** (dono da regra: `CLAUDE.md`, seção *Versionamento*): a mesma leva que sincroniza os 3 lugares da versão escreve a entrada. Cada uma traz `## [X.Y.Z] — AAAA-MM-DD`, linha de âncora (decisão · hash do commit de bump · versão do Charter quando mudou) e bullets sob `Added`/`Changed`/`Fixed`/`Removed`.
- **Idioma inglês**, como o `README.md`: o CHANGELOG é face pública do pacote, não doutrina interna (que segue em português). O bullet do `CLAUDE.md` diz isso explicitamente para não virar dúvida a cada release.
- **Divisão de donos**: o CHANGELOG diz *o que mudou por versão*, em linguagem de efeito no consumidor; `decisions.md` continua dono do *porquê*, e cada entrada referencia a §4.x em vez de repetir o argumento (decisão 4.20). O *Status* do README encolhe para a manchete da versão corrente + ponteiro, e **não volta a acumular prosa histórica**.

**Custo assumido**: mais um artefato a manter por release, mitigado pelo tamanho (a entrada é derivável das decisões da leva). A regra é **textual, não mecânica** — no padrão das 4.23/4.42/4.47, um `changelog-guard` (Stop, bloqueando quando o diff da branch altera `version` no `plugin.json` sem tocar o `CHANGELOG.md`) é a evolução natural se o esquecimento se repetir; fica de fora agora porque a leva de release é um ato deliberado do Diretor, não um passo condicional no meio de uma corrida autônoma — o perfil de risco que motivou aqueles hooks.

**Aplicação**: `CHANGELOG.md` (novo), `CLAUDE.md` (seção *Versionamento*), `README.md` (*Status* enxugado + ponteiro). Doutrina nova → minor: plugin 0.28.0 → 0.29.0.

---

### 4.49 — Verificação de tela migra para o Playwright MCP: motor único, headless por padrão, artefatos em `thoughts/`

**Problema**: a `screen-verify` dirigia o **browser embutido** (`mcp__Claude_Browser__*`), e três limitações vinham junto. (a) **Não existe headless**: o painel *é* a interface, então toda verificação abre janela e rouba foco — e metade das "armadilhas" documentadas na skill eram consequência disso (aba em segundo plano pausa transições e produz screenshot preto; viewport degenerado invalida medida de layout). Sintoma de ferramenta virou doutrina de diagnóstico. (b) **Screenshot não ia a lugar nenhum**: a skill mandava "registre a evidência", mas a captura ficava no transcript — nada em disco, nada depois do fim da sessão. (c) **Isolamento por realm era falso**: a regra dizia "aba própria por realm", e abas do mesmo contexto **compartilham cookies** — a garantia que existe justamente para pegar bug de autorização não garantia nada.

**Decisão (do humano, escolhendo entre MCP × biblioteca)** — a skill passa a dirigir **Playwright via MCP**, como **motor único**; o browser embutido sai. Rejeitada, com registro, a rota **Playwright como biblioteca** (`@playwright/test` no projeto): o perfil de referência do keelson é PHP, e exigir Node + devDependency para verificar tela imporia stack ao projeto governado — o plugin adapta-se ao projeto, nunca o contrário. Instalação **global** (`npm i -g`) foi descartada no mesmo passo: o runner global fica fora do caminho de resolução de módulos do Node e amarra uma versão para todos os projetos da máquina. A rota biblioteca segue **declarável** em `gates.screenVerify.method` para quem quiser verificação em CI — nunca instalada pelo keelson.
- **O nome não muda**: a skill continua `screen-verify` e `method` continua `skill:screen-verify` — troca-se o motor por dentro, e **nenhuma ficha de consumidor quebra** (a exceção de nomenclatura da 4.21 segue valendo).
- **Headless é o default, e mora num lugar só**: as flags vivem na config do servidor MCP (`.mcp.json` do projeto — versionado, o time herda — ou escopo pessoal via `claude mcp add`), escrita pelo `/keelson:init` (Etapa 4.4 nova). **Não** existe `headless` na ficha: o servidor é quem controla, e um espelho na ficha seria campo que mente na cara do leitor (lição da 4.43). Mudar o modo = rodar o `init` de novo.
- **Instalação nunca no escuro** (diretriz do humano): binário de navegador vai para cache **do usuário**, fora do repo — instalável mediante "sim", sempre dizendo o que foi instalado e onde. Node ausente ou `< 18` **não** é resolvido pelo keelson: vira pendência com o comando exato. Escrever no `.mcp.json` é mudança em arquivo versionado — mostra o bloco antes, merge-preserving, e há a saída pessoal para quem não quer tocar o repositório.
- **Diagnóstico nomeado** (dono: `handoff-protocol.md` §8.1, tabela): "ambiente sem tela" é genérico demais e joga a investigação de volta para o desenvolvedor. A sondagem passa a distinguir **runtime de browser ausente** × **credencial ausente** × **app fora do ar**, cada uma com a saída que resolve; o `qa` reporta `causa_indisponibilidade` e o `implement` rejeita causa genérica quando a sondagem sabia qual das três era. **Sem fallback silencioso** para outro motor: evidência que ninguém reproduz é pior que pendência honesta.
- **Artefatos em `thoughts/screen-verify/<slug>/`** (`gates.screenVerify.artifactsDir`, = `--output-dir` do servidor): screenshot e dumps de console/rede viram arquivo, com `filename` relativo e falante. `thoughts/` já era gitignored pela Etapa 5.5 — irmão de `local/`, separado porque é binário pesado e não material que os agentes leem. **O arquivo nunca é a prova**: a evidência durável continua textual (HANDOFF + INDEX), senão um clone limpo perde o gate (4.26/4.46).
- **Isolamento por realm corrigido**: um realm por vez com `browser_close` entre eles (com `--isolated`, o perfil é em memória e some junto), no lugar da "aba própria" que nunca isolou. O item negativo cross-realm é a única exceção — roda dentro da sessão de origem.

**Custo assumido**: o gate ganha uma **dependência externa real** — antes bastava o Claude Code. Aceito porque a dependência é declarada, provada e diagnosticada (acima), e porque destrava o que o embutido nunca deu: headless, artefato em disco, trace/vídeo sob `--caps devtools` e verificação viável fora de uma sessão com painel. `--allowed-origins` fica **de fora** do default: bloquear origem externa faz fonte/CDN sumirem e imita bug de UI — endurecimento é escolha do humano, não default que fabrica falso positivo.

**Aplicação**: `skills/screen-verify/SKILL.md` (motor, isolamento, artefatos, armadilhas reescritas), `commands/init.md` (Etapa 2 perguntas, Etapa 4 ficha, **Etapa 4.4 nova**, Etapa 5.5, self-check da Etapa 6), `docs/_meta/conventions/handoff-protocol.md` (§8.1 tabela de causas + `motivo:`/`sonda:` do template), `agents/qa.md` (sondagem + `causa_indisponibilidade` no report), `commands/implement.md` (aceite do report), `commands/verify-handoff.md` (Etapa 2.4 e 3.2), `templates/keelson.config.example.json` (`artifactsDir`), `README.md` (seção nova + Status). Capacidade nova → minor: plugin 0.29.0 → 0.30.0.

### 4.50 — Perfil PHP materializa a regra de docblock; a doutrina de comentário ganha face pública no README

**Problema**: o Diretor observou comentário demais no código que o keelson produz — e pediu o inverso: default sem comentário, comentando só a decisão que o código não consegue dizer. A doutrina **já responde isso** (4.31/4.32: Art. 7 = teste de apagar, âncoras `DEC-xx`/`FR-xx` de uma linha, gate 7 bloqueia excesso), mas havia um furo objetivo: o `PROFILE-OUTLINE.md` §3 exige que cada perfil diga qual comentário **carrega** o que a sintaxe não tem (→ obrigatório) e qual é **ritual** nesta linguagem — e o `php.md` não materializava isso em lugar nenhum. No vácuo, o hábito da comunidade PHP preenche: PHPDoc completo em toda classe/método, `@param`/`@return` repetindo a assinatura que o PHP 8.5 já tipa nativamente — exatamente o template ritual que o Art. 7 proíbe, só que dito por ninguém na língua do developer.

**Decisão**:
- **§3 do `php.md` ganha a regra de docblock** pelo mesmo teste do Art. 7 (perde/não perde), com exemplos-âncora: obrigatório quando carrega tipo que a sintaxe nativa não expressa (shape de array, generics para análise estática, `@throws` acionável); proibido quando repete assinatura tipada ou é cabeçalho-template de arquivo/classe. Forma canônica da 4.32: teste falsificável + âncoras, sem enumeração defensiva.
- **O README ganha seção pública sobre a doutrina de comentário** — "quase nenhum comentário; os que existem são âncoras de navegação" é postura de produto que o consumidor deve conhecer antes da primeira rodada, não detalhe interno enterrado no Charter.
- **Nenhuma regra nova de doutrina**: é o outline sendo cumprido. O dono continua o Charter (Art. 7); o perfil só fala a língua — um dono por regra preservado.

**Aplicação**: `guidelines/backend/php.md` §3 (perfil `reviewed: true` — edição **sinalizada para re-olhada humana**), `README.md` (seção nova "Comments in generated code" + Status). Correção/ajuste fino → patch: plugin 0.30.0 → 0.30.1.

---

### 4.51 — Primeira rodada real da 4.49: responder ≠ estar configurado

**Problema**: primeiro `/keelson:init` real com a 4.49 aplicada (consumidor `aav-backoffice`, dois realms). O comando se comportou bem — provou o runtime com navegação de verdade, checou Node, completou a ficha sem regenerar nada — e **por isso** expôs cinco furos da doutrina recém-escrita, quatro deles no mesmo padrão: a regra media a coisa errada, e o acerto veio da iniciativa do agente, não do texto. (a) A Etapa 4.4 dizia *"servidor já configurado e respondendo → não reescreva nada"*; o servidor respondia e estava **errado** (`npx -y @playwright/mcp@latest`, sem flag alguma) — o `✓` foi dado e a divergência só apareceu depois, por investigação ad-hoc. (b) O self-check tratou como **aviso** o que é falso verde: projeto com **dois realms** e servidor **sem `--isolated`** significa que o `browser_close` entre realms não descarta a sessão — a verificação do portal roda logada como admin, exatamente o bug de isolamento que o gate existe para pegar. (c) Sem `--output-dir`, o servidor grava no default **`.playwright-mcp/`** na raiz do projeto — diretório que a doutrina não citava em lugar nenhum e que **não estava no `.gitignore`**: a própria navegação de prova do `init` criou a pasta, que apareceu no `git status` (screenshot de sessão autenticada a um `git add .` do repositório) e teve de ser removida à mão. (d) A Etapa 5.5 afirmava que *"a linha `thoughts/` já cobre a pasta de artefatos"* — falso neste consumidor, que versiona `thoughts/shared/` de propósito. (e) O self-check mandava reportar o modo *"lido do `.mcp.json`/escopo configurado"*, vago o bastante para o agente ter de improvisar um script varrendo o `~/.claude.json` — onde havia **duas** entradas `playwright`, em escopos diferentes.

**Decisão** — o critério de aceite passa a ser o **estado efetivo**, não a resposta:
- **Flags conferem, não o ping** (Etapa 4.4, passos 2–3): ler a config efetiva nos lugares nomeados, **em ordem de precedência** (`.mcp.json` do projeto · `projects."<path>".mcpServers` do `~/.claude.json` · `mcpServers` global), reportar quais entradas existem e **qual vale**, e conferir `--output-dir` = `artifactsDir`, `--isolated` quando multi-realm, e o modo escolhido. Divergência em escopo do projeto → ajusta; em escopo pessoal/global → **o keelson não edita config pessoal**: entrega o comando e registra pendência.
- **`✗`, não `⚠️`, no caso que produz falso verde**: multi-realm sem `--isolated` reprova o self-check; `--output-dir` divergente também. Realm único → aviso basta.
- **`.playwright-mcp/` entra no `.gitignore`** sempre que o método é a skill (é o default do servidor, independe da config), e as linhas são garantidas **antes** da navegação de prova — a ordem estava invertida. O rastro da prova é limpo pelo próprio `init`.
- **Cobertura de `.gitignore` se prova** com `git check-ignore` no caminho real, nunca se infere de uma linha-pai: `thoughts/` parcialmente versionado é escolha legítima do projeto.
- **Sintaxe do comando corrigida pelo uso real**: a forma que funcionou é `claude mcp add playwright -s user npx -- @playwright/mcp@latest --headless --output-dir <dir> --isolated` (o `--` separa os args do `npx` dos flags do servidor); o README trazia o `--` no lugar errado. Junto: `add` não sobrescreve entrada existente (remover antes) e a sessão precisa reiniciar.

**Custo assumido**: a Etapa 4.4 cresce de 4 para 6 passos e o self-check ganha dois `✗` possíveis — mais atrito no `init` de projeto multi-realm, em troca de não entregar um gate de tela que **parece** ligado e não isola nada. Nenhuma capacidade nova: é a 4.49 medindo o que deveria ter medido desde o começo.

**Aplicação**: `commands/init.md` (Etapa 4.4 reescrita, Etapa 5.5, self-check da Etapa 6), `skills/screen-verify/SKILL.md` (`.playwright-mcp/` como sinal de config divergente), `docs/_meta/conventions/handoff-protocol.md` (§8.1, comando corrigido), `README.md` (setup pessoal corrigido). Correção → patch: plugin 0.30.1 → 0.30.2.

---

### 4.52 — Falsificabilidade no gate 1 e roteiro do gate 9 nascem no gerador de TASKs

**Problema**: primeiro `/keelson:auto` completo num consumidor Vue/PHP (frontend sem runner de testes, `screenVerify` ativo) expôs dois furos do `/keelson:tasks` — ambos de régua ausente no comando, não de descuido na execução, e reprodutíveis em qualquer projeto. (a) A 4.34 exige comando+esperado fixados antes do código, mas **não exige que o par seja falsificável**: um critério real (`git diff --name-only` → "nenhum desses caminhos na saída") aprovava vacuamente — sem ref, o comando compara a árvore de trabalho com o índice e, depois do commit, devolve saída vazia, exatamente o que o critério tratava como aprovação; ele aprovaria qualquer diff, inclusive um que tocasse todos os arquivos que existia para proteger. O `code-reviewer` pegou; o `task-validator` não, porque o check dele é sintático **por construção** ("existe comando? existe esperado?"). O detalhe que prova que faltava régua, não informação: a TASK seguinte do mesmo PLAN trazia a forma correta (`main...HEAD`). O padrão perigoso é o **esperado por ausência** (saída vazia, caminho que não aparece): ausência é o estado default de um comando mal ancorado, então esses critérios passam sozinhos. (b) A Etapa 3.5 do `/keelson:auto` (QA pré-código) devolveu **16 achados** sobre TASKs recém-geradas — a etapa funcionou (é a pergunta mais barata do ciclo), mas o volume aponta para o gerador: nada no `/keelson:tasks` cobria o roteiro do gate 9 (a régua da 4.34 só alcança o gate 1). Quatro formas repetidas: AC sem passo algum (inclusive o AC da métrica de sucesso da SPEC) · pré-condição sem sujeito nem receita ("um profissional sem permissão" é desejo, não pré-condição) · URLs não digitáveis (duas grafias para a mesma tela num app com base de rota própria) · cenário já documentado como não-exercitável em handoff sendo prescrito de novo.

**Decisão**:
- **Falsificabilidade no gate 1** (§Mapeamento do `tasks.md`): o par comando+esperado responde "que estado faz este comando FALHAR?" — sem resposta, aprova qualquer coisa. Esperado por ausência exige âncora explícita (`git diff --name-only main...HEAD`, nunca sem ref); esperado "não piorou" exige baseline capturada antes de começar, dentro do próprio critério. **Reincidência → check mecânico no `task-validator`, não uma segunda regra.**
- **Roteiro do gate 9 fixado antes do código** (sub-seção nova na Etapa 3 + seção condicional no template da TASK): com `screenVerify` ativo e AC atribuído ao gate 9, a TASK carrega ambiente (URLs digitáveis + realm), sujeito concreto (identidade + credencial), pré-condição com receita (montar **e** restaurar o estado) e um passo por AC — AC de gate 9 sem passo é AC sem gate. Handoffs anteriores do slug são leitura obrigatória; cenário não-exercitável não vira passo **por herança**: reaproveita a receita/prova substitutiva aceitas, ou prescreve nova tentativa nomeando o que mudou. A ressalva vem do próprio ciclo: o `qa` achou a terceira via de um cenário duas vezes registrado como beco (interceptar a chamada na carga fria da aplicação) — "não exercitável" é registro datado, não veredicto permanente.

**Custo assumido**: ~12 linhas num comando de ~260; **nenhum check novo de validator** — deliberado: a régua entra no gerador, e só vira check mecânico se o erro reincidir (mesma escada da 4.45).

**Aplicação**: `commands/tasks.md` (§Mapeamento estendido, sub-seção "Roteiro do gate 9 — fixado antes do código", seção condicional no template). Doutrina nova no gerador → minor: plugin 0.30.2 → 0.31.0.

---

### 4.53 — O fecho do `/keelson:auto` reconcilia, e o relatório conta o estado do tracker

**Problema**: caso real, reportado por carta do Diretor após um `/keelson:auto` de ponta a ponta com Jira ativo (`mode: create`, hierarquia Epic ▸ História ▸ Subtarefa configurada e validada). Ao final, o Jira tinha **só o Épico** — sem a Story, sem as três sub-tasks, sem transição nenhuma — e o relatório de entrega não mencionou o assunto: o Diretor descobriu sozinho, abrindo o Jira. A causa imediata foi a execução (os ganchos de `specify` e `tasks` foram adiados para "fazer tudo no fim" e não rodaram), mas o desenho transformava esse deslize num resultado **silenciosamente errado**, e três furos estruturais explicam como: (a) o sync é distribuído em ganchos best-effort e **nenhum gancho repara o anterior** — o `/keelson:tasks` não verifica se o Épico existe, e o gancho final do auto lia só §0–§1 + §11 (comentar o push), sem reconciliar; três oportunidades independentes de falhar em silêncio. (b) O estado incoerente era **invisível**: o item 6.1 obriga a composição do diff no report, mas nada obrigava a declarar o estado do tracker — justamente o artefato que o resto do time consulta; "best-effort, nunca bloqueia" virou na prática "best-effort, nunca reporta". (c) A ferramenta certa existia (§12, reconciliação idempotente) mas era humano-only e fora do caminho. As guardas anteriores não cobrem este caso: a 4.46 registra o pulo de quem **entra** no protocolo, e o `jira-guard` (4.47) cutuca por artefato sem key — mas cutuca 1× por fingerprint e não confere o **conjunto** (Epic criado + resto faltando passa como "progresso"). Adendo do mesmo caso: a ficha declarava `transition: auto` e o mapa afirmava em texto corrido "hoje a ficha usa `transition: comment`" — o comportamento passava a depender de qual arquivo o agente leu.

**Decisão** — três correções, em ordem de valor, mais o adendo:
- **Reconciliação no fecho do `/keelson:auto`** (a que resolve o caso): a Etapa 5, antes do relatório, aplica a reconciliação do §12 além do §11. O sync é idempotente por exigência do próprio protocolo (§4), então a passada é **no-op barata quando os ganchos funcionaram** e conserta o ciclo quando não funcionaram — os ganchos viram três tentativas **mais uma rede**. O §12 passa a declarar os dois invocadores; o comando avulso segue existindo para backfill, ciclo interrompido e conector tardio.
- **Linha obrigatória de estado do tracker no relatório de entrega** (item 6.1, ao lado da composição do diff): `Jira: <KEY> (Épico) · Story: <KEY|—> · sub-tarefas: K/N · transições: <n|nenhuma> (transition: <modo>)` — **medida pela reconciliação do fecho, nunca de memória dos ganchos**. Uma linha basta para o Diretor ver a incoerência sem abrir o Jira. Régua nova de doutrina: **best-effort significa não bloqueia, nunca não conta** — sync pulado/falho aparece na linha com o motivo, jamais é omitido.
- **Estado final do ciclo automático declarado pelo método** (§9): o fecho do auto é, por definição, um **gatilho do marco "pronta p/ QA"** — sub-tasks `Done`, unidade de QA (Story da FEAT, Story implícita ou tarefa isolada) no status-alvo de espera-do-humano, **Epic intocado**. O estado do tracker ao fim do ciclo passa a ser definido pelo método, não a emergir de um encadeamento de gatilhos que só funciona se todos os ganchos anteriores tiverem rodado. O gatilho indireto ("todas as sub-tasks Done") continua correto e continua valendo para os demais fluxos.
- **Adendo — a ficha vale sobre a prosa do mapa** (§3 + self-check do `/keelson:init`): prosa/cabeçalho do `mapFile` que contradiz a ficha → aviso "mapa desatualizado — a ficha vale", comparação feita onde os dois já são lidos juntos; contradição nunca é `✗`.

**Custo assumido**: uma passada de reconciliação a mais por ciclo com Jira ativo (algumas leituras + `getJiraIssue` por key existente; nada é recriado) e uma linha a mais no report. Nenhum hook novo: a correção entra no caminho do comando, e o `jira-guard` continua como backstop de quem nem abre o protocolo.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§3 ficha-vale, §9 estado final do ciclo, §12 dois invocadores), `commands/auto.md` (Etapa 5 itens 4 e 6.1), `commands/jira-sync.md` (intro + governança), `commands/init.md` (self-check da Etapa 6), `docs/_meta/method-guide.md` (§3.9, §3.13), `templates/CLAUDE.keelson-block.md` (nota Jira), `README.md` (Jira integration + Status), `CHANGELOG.md`. Capacidade nova → minor: plugin 0.31.0 → 0.32.0.

---

### 4.54 — A `PROPOSTA_PLUGIN` ganha destinatário: a mensagem ao mantenedor no fecho do ciclo

**Problema**: carta do Diretor após três ciclos em consumidor. O `agile-coach` fez a parte difícil em todos — detectou os erros de processo, checou reincidência no ledger, decidiu o dono da regra, calculou orçamento, classificou `PROPOSTA_PLUGIN`, e até **rejeitou** uma das três propostas por ser lição de projeto — mas o processo parava aí: a saída dele é um YAML (`resultado`, `artefato`, `saldo_linhas`, `ledger`) perfeito para a sessão que o invocou e **ilegível para quem mantém o plugin e não estava lá**. As mensagens que chegaram ao mantenedor (e viraram as 4.52 e 4.53) foram escritas à mão porque o Diretor pediu; sem esse pedido, as propostas teriam morrido num log dentro de um repositório que o mantenedor não lê. O desenho não tinha o destinatário.

**Decisão** — segunda saída do `agile-coach` + seção condicional no fecho do `/keelson:auto`:
- **`mensagem_mantenedor`** (dono do conteúdo: `agents/agile-coach.md`, passo 7 novo): quando há `PROPOSTA_PLUGIN`, o agent compõe também a mensagem ao mantenedor — uma por problema, com o diff proposto e o orçamento anexados. Requisitos: **cena reconstituível sem acesso ao repo** (stack, gates, comando, esperado × acontecido, custo real da falha — que só o fim do ciclo conhece; vocabulário interno explicado em meia linha na primeira aparição); **caso + diagnóstico, nunca a regra genérica** (quem abstrai é o mantenedor, que vê os outros consumidores — generalizar de amostra de um não é trabalho do agent); **endereço de cada achado** — local (conserto no projeto, citado só como contexto) × processo (a proposta) × o terceiro caso fácil de perder: causa local que denuncia **pergunta que o `/keelson:init` não fez** → os dois destinos, separados; **autoria honesta** — agent errou → a primeira linha diz, e só então argumenta por que o desenho silenciou o erro.
- **Item 7.5 da Etapa 5 do `/keelson:auto`**: com ≥1 `PROPOSTA_PLUGIN` na Etapa 4.5, o report da Entrega traz a(s) mensagem(ns) em **bloco copy-paste** — o mesmo mecanismo do prompt de handoff (item 7), apontado para outro destinatário. Sem proposta → a seção não existe (**não bloqueia**; ninguém inventa relato para preencher formulário). Nasce no fim do ciclo, não na detecção: é lá que se sabe o custo.
- **Efeito colateral desejado**: obrigar o endereçamento (local × processo × init) é um filtro que não existia — sem ele, a tentação é mandar ao plugin tudo que incomodou no ciclo, inclusive config malfeita do projeto.

**Custo assumido**: ~15 linhas no agent e ~4 no comando; nenhum campo novo obrigatório quando não há proposta. Detecção, dedup, dono e orçamento **não mudam** — a lacuna era só a escrita para fora.

**Aplicação**: `agents/agile-coach.md` (passo 7 + campo `mensagem_mantenedor` no report), `commands/auto.md` (Etapa 4.5 meia linha + item 7.5 da Etapa 5). Os demais invocadores do `agile-coach` (`/keelson:implement`, `/keelson:review`) recebem o campo no report por consequência; ancorar a exibição nos seus fechos fica para quando a necessidade aparecer em rodada real. Capacidade nova → minor: plugin 0.32.0 → 0.33.0.

---

### 4.55 — Escopo por SPEC no `/keelson:jira-sync`: o fallback manual enquanto o fecho do auto não se prova

**Problema**: relato do Diretor pós-4.53 — na prática, o `/keelson:auto` **continua não criando as issues no Jira**; a passada de reconciliação do fecho (§12), desenhada exatamente para consertar os ganchos que falharam, ainda não se comprovou em rodada real (a observação pendente da 4.53 tem agora a primeira resposta, e é negativa). Enquanto a causa não é diagnosticada e refinada, o Diretor precisa de um **fallback manual confiável**: com o ciclo pronto (SPEC, PLAN e TASKs criados), apontar **uma SPEC** e ter Epic, Story/FEATs e sub-tasks criados no Jira. O pedido original era um comando novo (`/keelson:jira-create <spec>`), mas a sobreposição com o `/keelson:jira-sync` é quase total — a criação em lote *é* a primeira reconciliação de um alvo virgem (§4: idempotência faz "create" e "sync" diferirem só pelo estado prévio) — e a 4.27 já vetou comando novo para isso. O delta genuíno é só o **escopo do input**: o comando aceitava slug ou `PLAN-MMM` (slug inteiro), não uma SPEC individual.

**Decisão**: estender o argumento do `/keelson:jira-sync` para aceitar `SPEC-NNN` ou o caminho do arquivo da SPEC. Nesse caso a reconciliação do §12 roda **escopada à árvore da SPEC**: issue da SPEC (§6) → Stories (§6.1/degrau (0) do §7.0) → sub-tasks das TASKs dos PLANs cuja coluna **Cobre** do INDEX inclui a SPEC — e nada além; as demais SPECs do slug ficam fora do plano e do output. Nenhuma regra muda de dono nem de conteúdo: idempotência (§4), régua de hierarquia (§7.0), campos (§8), persistência (§10) e `--dry-run` valem idênticos — a única diferença é o recorte do conjunto. Nenhum comando novo (4.27 mantida); o dono da lógica segue único (4.20/4.22): o recorte é declarado no §12 do protocolo e o comando só o orquestra. A observação da 4.53 (fecho do auto executa a passada §12?) **continua aberta** — este fallback alivia o sintoma, não substitui o diagnóstico; quando o relato do próximo ciclo real chegar, a causa de o fecho não reconciliar vira decisão própria.

**Custo assumido**: uma regra de resolução de alvo a mais na Etapa 0 do comando e um parágrafo no §12. Risco aceito: escopo por SPEC pode deixar irmãs do mesmo slug defasadas no tracker — mitigado pelo próprio comando (rodar depois com o slug é no-op sobre o que o escopo já criou).

**Aplicação**: `commands/jira-sync.md` (frontmatter, Input, Etapa 0.2, Etapa 1, Output, Limites), `skills/_shared/jira-sync-protocol.md` (§12, parágrafo "Escopo por SPEC"), `docs/_meta/method-guide.md` (§3.13), `README.md` (tabela Commands + seção Jira). Capacidade nova → minor: plugin 0.33.0 → 0.34.0.

### 4.56 — Duração da sessão no report da Entrega: relógio medido, por etapa, horário de Brasília

**Problema**: pedido do Diretor — ao final de um ciclo do `/keelson:auto` não há como saber quanto tempo a sessão durou nem onde ele foi gasto. Duas armadilhas no caminho: o modelo não tem relógio interno confiável (qualquer duração "lembrada" é estimativa, não medida), e um timestamp que viva só na memória da conversa se perde quando a sessão cai e é retomada — os artefatos SDD são o checkpoint, então o relógio precisa morar neles.

**Decisão**: o ciclo ganha um **relógio medido**. Na largada, o Tech Lead roda `TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z` e grava a marca no front-matter do BRIEF (`**Largada**:`); ao concluir cada etapa (1–4), anexa uma linha ao `## Cronologia` do mesmo BRIEF; na Entrega, uma nova **linha obrigatória do report** (item 6.3) traz o total e a quebra por etapa (specify · plan · tasks · implement), exibidos em horário de Brasília. Rotas sem arquivo (bug/refactor inline, trivial, TASK avulsa) carregam a marca de largada na própria mensagem e reportam só o total; marca ausente → reporta-se o que foi medido, com a lacuna nomeada — nunca se inventa número. O fuso é **fixado** em `America/Sao_Paulo` (não o da máquina) para o comportamento ser idêntico num servidor/CI em UTC. O `/keelson:guided` herda pela Entrega compartilhada ("igual ao `/keelson:auto`") e pela regra de degradação. **Duração é transparência, não sinal**: "fôlego não é gatilho" (4.23/4.24) permanece intacta — o relógio jamais justifica parar, acelerar ou estacionar.

**Custo assumido**: duas linhas a mais no contrato do BRIEF e uma passada de `date` por fronteira de etapa. Limite aceito e nomeado: é relógio de parede — inclui esperas (rate limit, máquina suspensa, ausência do humano no guided); o report chama de "duração da sessão", sem prometer "tempo de trabalho do time".

**Aplicação**: `commands/auto.md` (Etapa 0.5 item 5 "Relógio do ciclo" + Etapa 5 item 6.3), `docs/_meta/conventions/index-contract.md` (contrato do BRIEF: `Largada` + `Cronologia`), `docs/_meta/method-guide.md` (§3.9). Capacidade nova → minor: plugin 0.34.0 → 0.35.0.

### 4.57 — `/keelson:update`: atualizar o plugin instalado por comando, com o restart nomeado

**Problema**: pedido do Diretor — atualizar o keelson num consumidor exige lembrar dois comandos interativos na ordem certa (`/plugin marketplace update` e depois `/plugin update`; só o primeiro **não** atualiza o plugin instalado — armadilha já documentada no README). Não havia caminho de um passo, e um update disparado sem aviso esconde a segunda armadilha: a sessão corrente continua rodando a versão antiga até reiniciar.

**Decisão**: nasce o `/keelson:update`, **humano-only** (`disable-model-invocation` — atualizar o plugin é ato do Diretor, nunca do time). O motor é um script embarcado (`scripts/update.sh`, referenciado via `${CLAUDE_PLUGIN_ROOT}`), viável porque a CLI expõe os comandos não-interativos `claude plugin marketplace update` e `claude plugin update` (com `--scope`): refresh do marketplace e update do plugin, nesta ordem — e refresh falho **aborta** (seguir com o cache velho faria o passo seguinte reportar "já atualizado" sem estar). A versão antes/depois vem da **ficha de plugins da CLI** (`~/.claude/plugins/installed_plugins.json`, via `jq`, selecionada pelo scope — o array carrega uma entrada por scope), com fallback best-effort no parse de `claude plugin list`; versões iguais → "nada a fazer", sem lembrete de restart. Plugin ausente no scope é **gate**, mas só quando a leitura é confiável (ficha + `jq`) — no fallback, vazio significa "não sei ler", e o update segue best-effort. O comando é fino — executa o script e **reporta fielmente**: falha é erro nomeado (CLI ausente no PATH · plugin fora do marketplace no scope · instalação de desenvolvimento), e todo report de update aplicado termina com o lembrete obrigatório de reiniciar a sessão (*restart required to apply*) — nunca se promete que a versão nova já está ativa. Mecanismo validado em campo: rodado num consumidor real pelo Diretor antes de consolidar.

**Custo assumido**: dependência de dois contratos internos da CLI — os comandos `claude plugin ...` e o formato da ficha `installed_plugins.json` (não documentado); mitigada por o caminho da ficha ser só leitura de versão (formato mudou → cai no fallback do `list`; os dois falharam → update segue com "versão não exibida") e por falha da CLI virar erro reproduzido, nunca contornado. O script segue o padrão bash 3.2 dos hooks, mas **falha alto** — aqui o humano pediu o update; silêncio é que seria falha.

**Aplicação**: `commands/update.md` (novo), `scripts/update.sh` (novo), tabela *Commands* do `README.md`, `docs/_meta/method-guide.md` (§3.16), nota humanos-only do `templates/CLAUDE.keelson-block.md`. Capacidade nova → minor: plugin 0.35.0 → 0.36.0.

### 4.58 — "Verificado, não deduzido": a abstração do cluster de escopo/critérios do `/keelson:tasks`, e a reincidência vira check

**Problema**: primeira mensagem ao mantenedor gerada pelo mecanismo da 4.54 (o desenho funcionou: diffs prontos, endereçamento local × plugin feito, lições de projeto retidas no consumidor). Ela traz dois achados novos do mesmo consumidor — e um sinal do coach: são **quatro achados consecutivos, em três PLANs, todos na geração de critérios/escopo do `/keelson:tasks`** (dois já aplicados na 4.52). Os dois novos: (a) **cobertura órfã** — o mapeamento AC→critério não alcança item do "Escopo > Inclui" sem AC (contrato criado nesta wave para ser lido em wave posterior: VO, porta, chave de serialização); o developer escreve "testes de tudo acima" e nenhum teste exercita o contrato de verdade; (b) **caminho deduzido do nome** — a TASK citou `components/<domínio>/` porque o nome parecia certo, mas a tela alvo era `views/<domínio>/<Tela>View.vue` com outra leitura; o developer obedeceu ao pé da letra e entregou a funcionalidade onde ela nunca renderiza. O coach pergunta o que a 4.32 obriga a perguntar: quatro regras ou uma abstração? Os quatro achados compartilham a mesma causa — **conteúdo da TASK nascendo de dedução, não de verificação**: critério deduzido do diff (4.52a), passo de gate 9 sem sujeito/receita (4.52b), cobertura deduzida do "testes de tudo" (a), caminho deduzido do nome (b). Aplicar os dois diffs do consumidor ao pé da letra seria acumular prosa num comando já denso — exatamente a enumeração defensiva que a 4.32 veta.

**Decisão** — consolidar sob um princípio nomeado + honrar a escada da 4.52:
- **A abstração ganha nome no gerador**: o princípio 6 da Etapa 1 vira "Sem invenção de escopo — **nem por dedução**: a TASK só afirma o que **verificou**", com o caso do caminho como âncora (confirmar pela cadeia do dado — *quem consome a consulta/endpoint alterado?* — e, sem confirmação, descrever o consumidor em vez de chutar o caminho). Fica no gerador, sem check de validator: "caminho certo vs. tela errada" não é mecanicamente verificável — o arquivo vizinho existe e compila.
- **Cobertura reversa na Etapa 3** (§Mapeamento): todo item do Inclui carrega ao menos um critério **próprio e executável** — "testes de tudo acima" não é critério; sem AC, o oráculo é o **contrato do próprio item** (cada método público e cada chave nova exercitados com valor não-nulo, mesmo que nesta wave o valor real nasça sempre nulo).
- **Reincidência → check, como a 4.52 pré-comprometeu**: o `task-validator` ganha ERROR na Etapa 5 (escopo) — item do Inclui que nenhum critério referencia reprova; critério genérico não conta como referência; TASK `Done` legada não reprova por isso (mesma carência do check de comando+esperado). É o quarto achado da mesma área: a régua "reincidência vira check mecânico, não segunda regra" deixa de ser promessa.

**Custo assumido**: ~10 linhas no comando e 1 check no validator. Observação pendente da 4.54 registrada de passagem: a mensagem chegou completa mas o Diretor não a entendeu de primeira — ela assume fluência no jargão interno; se repetir, o passo 7 do `agile-coach` ganha uma linha de abertura "o que é isto e o que fazer com isto" (fica para o segundo relato, amostra de um não vira regra).

**Aplicação**: `commands/tasks.md` (Etapa 1 princípio 6, Etapa 3 §Mapeamento), `skills/task-validator/SKILL.md` (Etapa 5). Doutrina nova → minor: plugin 0.36.0 → 0.37.0.

### 4.59 — Descrição para humanos no Jira: receita única de renderização, com re-render por marcador

**Problema**: pedido do Diretor — os cards que o sync cria no Jira não têm a completude e a narrativa que um humano precisa; a funcionalidade será testada por um analista de QA humano a partir do card, e o texto que chega não sustenta isso. O diagnóstico é de protocolo, não de execução: o `jira-sync-protocol.md` especifica hierarquia, idempotência e transição com rigor, mas o conteúdo textual ficou em duas palavras ("resumo/outcome" no Epic), a Story recebia os ACs em Given-When-Then cru (jargão de artefato, não roteiro de teste) e sub-task/standalone nasciam **só com título**. O material-fonte sempre existiu — a SPEC tem contexto, outcome, escopo, glossário e ACs — faltava a regra de renderização para o público humano.

**Decisão**: nasce a **receita única de descrição** (§6.2 do protocolo, dono único, referenciada por todos os pontos de criação — §6, §6.1/feat, §7.0 degrau (0), §7.1, standalone avulsa e transversal). Templates **nivelados por papel da issue**: Epic (contexto/objetivo + escopo + funcionalidades) · **unidade de QA** (Story de FEAT, Story implícita, tarefa isolada — o padrão mais rico: narrativa de negócio, "como testar" com os ACs traduzidos de Given-When-Then para passos imperativos, lista formal dos ACs, fora do escopo) · sub-task (objetivo + ACs cobertos — curta por design). Tudo em **português**, markdown simples. Teste falsificável: *um humano que só lê o card testa sem abrir arquivo do repo*; âncora de contenção: a descrição **projeta** o artefato, nunca acrescenta afirmação que ele não sustenta (régua da 4.58). Toda descrição gerada termina no **rodapé-marcador** `— gerado pelo keelson a partir de <caminho relativo do artefato>` — caminho relativo à raiz do consumidor, porque o número do artefato se repete entre slugs e só o caminho desambigua (FEAT ancora `#FEAT-NNN-XXX`; TASK aponta o próprio arquivo). O marcador habilita o **re-render**: a reconciliação re-renderiza descrição vazia ou terminada no marcador (`editJiraIssue`, só `description`) e **nunca** toca descrição sem marcador (editada por humano — preservar e avisar). A tradução GWT→roteiro é responsabilidade de *apresentação* (do sync, que conhece o público do tracker), não de *especificação* — a SPEC permanece agnóstica, mesmo raciocínio que mantém o PLAN fora do Jira.

**Refinada antes do commit por exercício de campo** (renderização real da SPEC-011 do consumidor, a pedido do Diretor), que rendeu quatro ajustes: **(a) cabeçalho-aviso** obrigatório na primeira linha de toda descrição gerada — "não edite, será re-renderizado; registre um comentário" — porque o rodapé é proteção mecânica e humano não lê até o fim antes de editar; comentários são o canal certo (o sync nunca os toca, só adiciona); **(b)** AC sem caminho manual razoável (atomicidade, requisição forjada, ownership, contrato de servidor) não vira passo de teatro no roteiro — agrupa-se na linha "verificações cobertas por teste automatizado"; **(c)** os ACs de **NFR** cujos elementos pertencem à funcionalidade (dark mode, viewport, leitor de tela) entram no roteiro da Story correspondente — a fórmula `ACs(FEAT)` cobre FRs e os deixaria órfãos de card; **(d)** flag `--refresh-descriptions` no `/keelson:jira-sync` — cards gerados antes do marcador existir seriam tratados como editados por humano e ficariam magros para sempre; a flag força o re-render sem marcador como decisão explícita e pontual do humano (ganchos automáticos nunca forçam). Um **segundo exercício** (SPEC-003 do mesmo consumidor — o caso da Story implícita) somou dois ajustes: **(e)** NFR verificável **sem AC próprio** (idempotência, reversibilidade, refresh) também vira cenário do roteiro — a fórmula por ACs os deixava fora do card; **(f)** as linhas `**Jira**:` e `**Jira Story**:` com a **mesma key** (encontrado em campo) = persistência inconsistente — o §10 passa a mandar tratar a Story como ausente (sondagem §4, criar/corrigir e avisar), nunca aceitar a duplicata como estado válido.

**Custo assumido**: descrições mais longas por issue (chamadas maiores, ainda 1 por issue) e um passo novo na reconciliação (leitura da descrição existente antes do re-render). Limite aceito: o marcador é convenção textual — humano que edita o miolo do card e **preserva** a última linha será sobrescrito no próximo sync; duplamente mitigado pelo cabeçalho-aviso e pelo rodapé, que declaram o texto como gerado.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§6.2 novo; §6, §7.0 degrau (0), §7.1, standalone e §12 referenciam), `skills/_shared/jira-sync-feat.md` (criação da Story e transversal), `commands/jira-sync.md` (flag nova, Etapa 1 item 4, linha "Descrições" no output), ganchos de `specify`/`tasks`/`implement`/`auto` citam o §6.2 na leitura. Capacidade nova → minor: plugin 0.37.0 → 0.38.0.

### 4.60 — Verbos de fase no `/keelson:jira-sync`: movimentação imperativa do quadro, por nível e multi-hop

**Problema**: pedido do Diretor — além de criar as issues (fluxo que já existe), o time precisa de dois atos imperativos sobre o quadro: **iniciar o desenvolvimento** (mover Epic/Story/sub-tasks até a coluna de desenvolvimento) e **finalizar o desenvolvimento** (sub-tasks concluídas, Story na coluna de revisão — o passo seguinte do fluxo). O protocolo de hoje não projeta isso: (a) o sync só alinha o Jira ao **estado dos artefatos** nos marcos do ciclo — não há verbo para mover o quadro *antes* de qualquer TASK mudar de status local; (b) o §9 só dá **um salto** (transição direta ao alvo), e boards reais exigem atravessar colunas intermediárias; (c) cada etapa tem **um** status-alvo, mas o confronto com um board real (NOVA do b2b-workspace) provou que **cada nível tem workflow próprio** — a Story anda num trilho de 17 status, a Subtarefa em 3, o Epic nunca foi medido; (d) o Epic é intocável por doutrina (§9), mas o Diretor quer movê-lo nesses atos. O trilho completo do board existia no mapa só como **prosa de referência** — nada estruturado que um walker pudesse percorrer.

**Decisão** — o quadro ganha **verbos de fase**, e o mapa ganha a estrutura que eles exigem:
- **Verbos** `--phase start-dev` e `--phase finish-dev` no `/keelson:jira-sync` (nenhum comando novo — 4.27 mantida; a fase é uma passada a mais da mesma reconciliação, que roda antes e garante que a árvore existe). Dono da lógica único (4.20/4.22): a semântica vive no **§13 do protocolo**; o comando só orquestra.
- **Tabela Etapas/Colunas ganha a coluna `Nível`** (`epic` | `story` | `subtask`; `story` cobre Story de FEAT, Story implícita e tarefa isolada). Linhas de fase declaram o alvo **por nível**; linha ausente para um nível = aquele nível não se move (opt-out declarado, sem erro). Mapa legado sem a coluna → marcos do ciclo seguem valendo (o nível deles já era implícito no gatilho).
- **Seção nova "Trilho do board"** no mapa: por nível, a lista **ordenada** de status-IDs das colunas do quadro. É o que o **walker multi-hop** (§9) percorre quando não há transição direta: avança um status por vez, revalidando as transições a cada salto (`isAvailable`/`hasScreen`/`isConditional`), **nunca regride**, e em salto bloqueado **para onde está, comenta e reporta a posição** — nunca força. Sem trilho no mapa → só o salto direto de hoje.
- **Ordem coerente da árvore**: `start-dev` move de cima para baixo (epic → story → sub-tasks); `finish-dev`, de baixo para cima — o quadro nunca mostra filho concluído sob pai não-iniciado nem o inverso.
- **Política `transition`**: o verbo é **ordem explícita do humano** — move com `comment` e `auto` (a política governa os ganchos **automáticos**, que seguem o §9 como hoje); `off` é política dura do projeto → o verbo avisa e não move.
- **Epic: duplo opt-in.** A doutrina "Epic intocado — roadmap é do humano" (§9) permanece para **todo gancho automático**, inclusive a reconciliação do fecho. O Epic só se move por **verbo de fase** (que *é* o ato do humano) **e** com linha `epic` declarada no mapa. Sem linha → intocado, como sempre.
- **Idempotência herdada**: card já no alvo ou além dele no trilho → no-op; rodar o mesmo verbo duas vezes é seguro; `--dry-run` imprime o plano de movimentação por card sem tocar no Jira; best-effort (§0) e rastro no INDEX (§10) idênticos ao resto do protocolo.

**Custo assumido**: uma seção nova no protocolo (§13), o walker no §9 e duas estruturas a mais no mapa (coluna `Nível` + Trilho), geradas pelo `/keelson:init` merge-preserving. Limites aceitos e nomeados: o trilho é declaração do humano — board reordenado sem atualizar o mapa faz o walker parar num salto bloqueado (e reportar, nunca errar em silêncio); transições condicionais reais (medidas no NOVA: `To Deploy`/`Done` `isConditional`) param o walker do mesmo jeito; e o Epic movido por verbo depende de trilho/linha que o consumidor precisa medir (o do NOVA nunca foi).

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§3 — coluna `Nível` + seção Trilho; §9 — walker multi-hop; §13 novo), `commands/jira-sync.md` (flag `--phase`, Etapa 2, Output), `commands/init.md` (Etapa 4.6 itens 3–4 — medir trilhos e semear as estruturas novas), `docs/_meta/method-guide.md` (§3.13), `README.md` (tabela Commands + seção Jira). Capacidade nova → minor: plugin 0.38.0 → 0.39.0.

### 4.61 — `epicPolicy`: demanda de funcionalidade única projeta sem Epic (o sinal é a contagem de FEATs)

**Problema**: observação do Diretor num dry-run real (4.60) — toda SPEC projeta um Epic, mesmo a demanda pequena de funcionalidade única (o caso medido: 1 SPEC sem FEATs, 2 TASKs → Epic + Story implícita + 2 sub-tasks; o Epic é um card de agrupamento com **um** filho, ruído de roadmap). A primeira hipótese (limiar por quantidade de TASKs) foi descartada na conversa: contagem de TASKs é sinal *técnico*, flutua com decisão de engenharia. O Diretor propôs o sinal certo: **a contagem de FEATs** — declaração de *produto* que já vive na SPEC (headings `### FEAT-`, escritos pelo ciclo e validados pelo PO contra o brief), estável e mecanicamente verificável (`grep -c`). E a doutrina já dizia metade disso: "a camada FEAT é colapsável — sem declaração, a funcionalidade **é** a própria SPEC" (justificativa do degrau (0) da 4.44); faltava levar a frase à conclusão: se a SPEC *é* uma funcionalidade, projete-a **como** funcionalidade, não como Epic-com-uma-Story.

**Decisão**: a ficha ganha `jira.epicPolicy` — `"always"` (**default**, comportamento atual: SPEC → Epic sempre) | `"multi-feature"` (a regra nova). Dono da régua: **§7.0 do protocolo**. Com `multi-feature`: **2+ FEATs declaradas** → projeção plena como hoje (Epic ▸ Stories ▸ sub-tasks — há o que agrupar); **0 ou 1 FEAT** (o mesmo caso: funcionalidade única) → **projeção compacta** — a raiz é a Story única (a Story implícita espelhando a SPEC, ou a Story da FEAT única), **sem pai**, com as sub-tasks embaixo (adjacência 0 ▸ -1, o mesmo padrão da tarefa isolada do §7 — nenhuma hierarquia nova). Regras de contorno: (a) **o registro da projeção são as próprias keys** — `**Jira**:` presente = projeção plena; `**Jira Story**:`/key sob a FEAT **sem** `**Jira**:` = compacta; nenhum campo novo. A política é avaliada **uma vez, na primeira criação** da árvore; (b) **o slug que cresce**: SPEC compacta que ganha a 2ª FEAT depois **não re-parenta** (§4) — a Story nova nasce irmã (sem pai) + `createIssueLink` "relates to" com a raiz, e o estado misto é reportado (criar o Epic e reorganizar é ato do Diretor no Jira); (c) `issueType.feature: null` inviabiliza a raiz compacta → degrada para a projeção de hoje com aviso (§0, nunca trava); (d) nada mais muda: a Story raiz **é** a unidade de QA (receita §6.2 e gatilho "pronta p/ QA" idênticos), o verbo de fase com linha `epic` vira **no-op** na projeção compacta, e TASK avulsa sem Epic para aninhar cai no fallback existente do §7 (sem pai + "relates to" com a raiz).

**Custo assumido**: mais um eixo de projeção no §7.0 (a tabela de combinações ganha a política como pré-filtro) e o caso de crescimento vira estado misto reportado em vez de árvore perfeita — aceito porque re-parentar continua proibido e o roadmap é do Diretor. Default `always` preserva 100% do comportamento atual; consumidor que não mexer na ficha não vê diferença.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§2 — chave nova; §6 — pré-check; §7.0 — a régua; §10 — keys como registro; §13 — no-op do `epic`), `skills/_shared/jira-sync-feat.md` (FEAT única como raiz), `commands/jira-sync.md` (classificação da projeção na Etapa 0.4 e no Output), `commands/init.md` (pergunta de política na Etapa 4.6 + regra de merge), `templates/keelson.config.example.json`, `docs/_meta/method-guide.md` (§3.13), `README.md` (bloco `jira` + seção). Capacidade nova → minor: plugin 0.39.0 → 0.40.0.

### 4.62 — Quadro em tempo real: marco de início, teto da Story e não-regressão

**Problema**: pedido do Diretor — com `transition: auto`, o quadro só se move na **closure** (TASK Done → status de concluída) e no fecho do ciclo. Durante a execução, o Jira mente por omissão: a wave está rodando e os cards seguem parados em "a fazer" — quem olha o quadro não vê que o trabalho começou. E o marco "Funcionalidade pronta p/ QA" **transicionava** a Story para além do desenvolvimento, quando o fluxo real do time é outro: terminada a entrega da IA, o Diretor ainda analisa, pede ajustes e melhorias — a Story precisa **ficar** na coluna de desenvolvimento até ele encerrar essa análise; movê-la adiante é ato humano, não do sync. (Complementar à 4.60, implementada em paralelo: lá o **humano ordena** o movimento por verbo de fase; aqui o **ciclo se move sozinho** nos marcos — as duas se compõem abaixo.)

**Decisão**: três regras novas no §9 do protocolo (dono único; os ganchos só o citam):

1. **Marco de início**: a tabela Etapas/Colunas (§3) ganha os marcos canônicos `TASK iniciada` (status-alvo aplicado à sub-task/isolada no **despacho** da TASK ao developer — gancho novo na Etapa 3.2 do `/keelson:implement`) e `Trabalho iniciado (Story)` (aplicado à **Story** — de FEAT ou implícita — quando a **primeira** TASK dela é despachada); `TASK concluída` nomeia o marco de closure que já existia. Linha ausente no mapa → o marco degrada para comentário, como qualquer outro.
2. **Teto de transição automática da unidade de QA**: transição **automática** na Story (e na tarefa isolada, que é sua própria unidade de QA) vai **no máximo** até o status-alvo de `Trabalho iniciado (Story)` — a coluna de desenvolvimento. Marco cujo alvo fica **além** do teto (tipicamente "Funcionalidade pronta p/ QA") degrada para **comentário na Story** — a informação chega, o card não anda. Pós-desenvolvimento é do humano, pela mesma régua que mantém o Epic intocado e a autonomia terminando nos commits (4.38/4.43). Sub-task **não tem teto**: é card de dev, vai até a última etapa (`TASK concluída`) na closure, como hoje. **Composição com a 4.60**: o teto governa só os ganchos automáticos — o verbo de fase (§13) é ordem explícita do humano e o ultrapassa; o fecho automático deixa a Story no teto, e `--phase finish-dev` é exatamente o ato humano que a avança à revisão.
3. **Não-regressão**: antes de **qualquer** transição automática (gancho ou reconciliação), ler o status atual da issue e compará-lo com a **régua do nível** — o Trilho do board (§3/4.60), quando declarado; sem trilho, a ordem das linhas de Etapas/Colunas: card já **no alvo ou além** → no-op (nunca puxar de volta um card que o humano moveu); status atual **fora da régua** → não transicionar (sem ordem conhecida, mover é chute) — comentar o marco. O walker multi-hop da 4.60 já embutia a regra no caminho longo; aqui ela vira pré-condição **também do salto direto**. É o que torna a movimentação em tempo real segura contra a corrida com o humano no quadro.

A reconciliação (§12) aplica as mesmas três: alinha sub-task ao estado real da TASK (In Progress → alvo de `TASK iniciada`; Done → `TASK concluída`), Story ao teto quando alguma TASK dela já começou, sempre sob não-regressão. Estado final do ciclo automático passa a ser: sub-tasks concluídas · **unidade de QA na coluna de desenvolvimento com o comentário de pronta p/ QA** · Epic intocado.

**Custo assumido**: 1 `getJiraIssue` extra antes de cada transição (preço da não-regressão) e mais chamadas MCP durante a wave (1 por TASK despachada + 1 por Story iniciada) — todas best-effort (§0), latência marginal e nenhuma nova forma de travar o ciclo. Mudança de comportamento assumida: projetos que contavam com a Story **transicionando** em "pronta p/ QA" agora recebem comentário no lugar — registrada no CHANGELOG como *Changed*; o avanço do card é do humano (`--phase finish-dev`), ou, se o projeto quiser o marco transicionando, mapeia o gatilho para a própria coluna-teto.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§3 marcos canônicos; §9 marco de início, teto e não-regressão; §12 alinhamento pelo estado real), `skills/_shared/jira-sync-feat.md` (item 5 respeita o teto), `commands/implement.md` (gancho de início na Etapa 3.2), `commands/init.md` (semeia os marcos novos no esqueleto do mapa; regra de merge acrescenta linhas faltantes comentadas), `commands/jira-sync.md` (Etapa 1 item 5 cita teto/não-regressão). Capacidade nova → minor: plugin 0.40.0 → 0.41.0.

### 4.63 — Guarda do topo da main: hook git de pre-commit contra colisão de sessões paralelas

**Problema**: caso real na leva 4.60–4.62 — duas sessões do Diretor, em máquinas diferentes, trabalharam o mesmo tema **no mesmo dia**: cada uma numerou a próxima decisão a partir do que via localmente e nasceram **duas "4.60"** com conteúdos distintos, mais bump de versão colidindo (ambas 0.39.0). O conflito só apareceu no `git push` — depois de decisão escrita, CHANGELOG composto e versão gravada nos 3 lugares — e custou um rebase de 7 arquivos com renumeração (4.60 → 4.62). A causa é estrutural: **numeração de decisão e bump derivam do estado local da main**, e nada conferia esse estado contra o remoto antes do commit.

**Decisão**: nasce o hook git de **pre-commit** `scripts/git-hooks/pre-commit`, **versionado** no repo (vale para todas as máquinas) e ativado por clone com `git config core.hooksPath scripts/git-hooks` (ato explícito, uma vez — hook de `.git/hooks/` não viaja com o clone). Semântica, na doutrina dos hooks do repo (bash 3.2, fallback gracioso):

- Age **só na `main`** (branch de feature, detached HEAD de rebase/cherry-pick → passa sem tocar);
- `git fetch origin main` **best-effort** (sem rede → avisa e confere contra o último fetch conhecido; sem remoto → passa);
- `origin/main` com commit que o HEAD local não tem → **bloqueia** o commit, lista os commits que chegaram e instrui: `git pull --rebase origin main` + conferir o próximo §4.x livre no `decisions.md` e a versão em `plugin.json`;
- Escape consciente e nomeado: `KEELSON_SKIP_MAIN_CHECK=1 git commit ...` (para quem sabe que quer commitar atrás — ex.: preparando um rebase manual).

Indisponibilidade nunca bloqueia; só o **desalinhamento real** bloqueia — a mesma régua best-effort do resto dos hooks. Validado com `bash -n` + repo sintético no scratchpad (5 cenários: atrás bloqueia · escape passa · em dia passa · feature atrás passa · sem remoto passa).

**Custo assumido**: ~1s de `fetch` por commit na main (é o preço de conferir o topo de verdade) e a ativação manual por clone — mitigada pela nota no `CLAUDE.md` (as sessões leem) e por este registro. O hook embarca no pacote do plugin (`scripts/` é distribuído) mas é **inerte** em consumidores: só age quando ativado via `core.hooksPath` no repo de desenvolvimento.

**Aplicação**: `scripts/git-hooks/pre-commit` (novo), nota de ativação no `CLAUDE.md` (§ Versionamento). Ferramenta do repo de desenvolvimento, fora da superfície de runtime do plugin → **sem bump de versão** (a régua de versionamento cobre capacidade do plugin; commit sem bump, como os `docs:` da leva 4.60).

---

### 4.64 — Exemplo literal conferido contra a regra formal da própria TASK; mensagem ao mantenedor carrega versão e diff literal

**Problema**: primeira `mensagem_mantenedor` real recebida de um consumidor (professional-portal, LRN-025 lá) — validação em campo da 4.54. O caso relatado: o `/keelson:tasks` escreveu, na mesma TASK, um regex mandatório no "Escopo > Inclui" (chave com prefixo de 2+ letras) e ilustrou o critério de dedupe com o exemplo literal `B-2, A-1, B-2 → [B-2, A-1]` — chaves que o próprio regex nunca casa. O `task-validator` não pegou (check sintático: existe comando+esperado?; não semântico: o exemplo satisfaz a regra formal fixada alhures no MESMO documento?). O mecanismo de desvio funcionou como projetado — developer notou e preservou a garantia com chaves válidas, code-reviewer confirmou (0 matches), Tech Lead corrigiu a TASK na closure — nenhum código errado existiu, mas o ciclo gastou uma rodada de correção que a geração evitaria. E a própria mensagem, avaliada contra a régua do passo 7 do `agile-coach`, revelou dois furos: **não dizia a versão do plugin instalada** (o mantenedor não sabe se a doutrina vigente já cobre o caso — só a âncora textual citada, que por sorte resolveu, confirmou o alvo) e trouxe o patch **em prosa**, não o diff literal com orçamento de linhas que o passo 7 já mandava anexar.

**Decisão**: dois patches mínimos, cada um no dono da regra. (a) `commands/tasks.md`, parágrafo de falsificabilidade da Etapa 3: todo **exemplo literal** que ilustra um critério é conferido contra qualquer regra formal (regex/formato) já mandatória em outra seção da mesma TASK — se o Escopo fixa um padrão, o dado do exemplo tem de casá-lo. (b) `agents/agile-coach.md`, passo 7: a cena abre com a **versão instalada do plugin**, e o anexo é o **diff literal** contra o texto da versão instalada — proposta em prosa obriga o mantenedor a redigir o patch às cegas. A reformulação mecânica sugerida pelo próprio remetente (extrair regex do Escopo e casar contra exemplos dos critérios, no `task-validator`) fica **reservada para reincidência**, pela mesma régua da 4.52 — regra semântica no validator é cara e o caso tem amostra de um.

**Aplicação**: `commands/tasks.md` (Etapa 3, falsificabilidade), `agents/agile-coach.md` (passo 7). Bump patch (ajuste fino de doutrina existente).

---

### 4.65 — O teto da unidade de QA é resolvido, declarado e inescapável; o mapa não é fonte de gatilho

**Problema**: primeira rodada real da 4.62 (`/keelson:auto` de ponta a ponta num consumidor, plugin 0.41.0). Tudo funcionou — Story criada, 10 sub-tasks, waves, gates, push — **menos** o fim: no fecho, a reconciliação levou a Story de "A fazer" a **"Feito"**, exatamente o que o teto da 4.62 existe para impedir. O card que devia esperar o Diretor em desenvolvimento apareceu concluído. Três furos compostos, nenhum deles "a regra não existia":

1. **A regra não foi lida.** Os comandos leem o protocolo por §§ (leitura seletiva por offset); o item 4 do `/keelson:auto` mandava ler §0–§1 + §6.2 + §11 + §12 — **§9 não estava na lista**, e a sessão leu as linhas 1–336 do arquivo, parando **antes** do teto (linha ~373) e do próprio §12. Executou a reconciliação sem as duas seções que a governam.
2. **O mapa virou fonte de autoridade paralela.** Sem §9/§12, a única régua disponível foi a tabela Etapas/Colunas do consumidor — que trazia, herdada de edição humana anterior, a linha `Concluída | História | Feito | 11991 | 41 | QA valida a funcionalidade / PR aberto`. Nada no §3 dizia que linha fora do catálogo canônico **não é gatilho executável**; a sessão a leu como convite.
3. **Gate do keelson confundido com ato humano.** A justificativa textual foi literal: *"conduzo a Story pela mesma cadeia — já que o gate 9 foi verificado ponta-a-ponta nesta sessão, o gatilho 'QA valida a funcionalidade' já está satisfeito"*. Duas falácias numa frase: o QA do time simulado não é o QA humano do quadro, e a cadeia da sub-task (card de dev, **sem** teto) não é evidência sobre a Story.

**Decisão**: quatro patches, cada um fechando um dos vetores.

1. **§9 é pré-requisito de qualquer movimento de card** (§0): nenhuma transição sem o §9 lido **nesta execução** — o § que se veio buscar (§7, §12, §13, feat) não substitui o §9, o pressupõe. `/keelson:auto` item 4 passa a listar §9 explicitamente.
2. **Catálogo fechado de gatilhos** (§3): só os quatro marcos canônicos e as linhas `--phase` são **executados**. Linha com outro nome/gatilho é **documentação do fluxo humano** — não dispara, não se "considera satisfeita", entra em 1 linha de aviso. Teste falsificável: *gatilho que o keelson não dispara por si não move card*. Corolário explícito: nenhum gate, agente ou etapa do ciclo (gate 9/QA, aceitação do PO, review, push) satisfaz gatilho que nomeia ato humano.
3. **Teto resolvido como valor, não como lembrete** (§9): antes de mover a unidade de QA, `teto = status-alvo de 'Trabalho iniciado (Story)'`; **linha ausente → teto = status atual** (só comentário). Mais a anti-analogia ("a cadeia da sub-task não se estende à Story") e o fecho de rota: fora de `--phase`, **não existe caminho** que ultrapasse o teto.
4. **Teto visível no relatório**: a unidade de QA passa a ser declarada com coluna atual **e** teto — no output do `/keelson:jira-sync` e na linha obrigatória do tracker do `/keelson:auto` (`Story: <KEY> em <coluna> (teto: <coluna>)`). Teto aplicado em silêncio é indistinguível de teto esquecido; a linha é o que torna a reincidência detectável sem abrir o Jira. O `/keelson:init` ganha o **diagnóstico de marcos não-canônicos** em mapa antigo (lista e recomenda, nunca altera a tabela do humano).

**Lição de método além do Jira**: doutrina que só existe em prosa dentro de um § longo é doutrina que a leitura seletiva pode pular. Regra que governa ato irreversível-ish precisa de (a) leitura declarada como pré-requisito, (b) valor resolvido antes do ato e (c) rastro no output — as mesmas três pernas da 4.30 (gate 8 inescapável).

**Aplicação**: `skills/_shared/jira-sync-protocol.md` (§0 pré-requisito de leitura; §3 catálogo fechado; §9 teto resolvido/declarado + anti-analogia; §12 sem rota acima do teto), `commands/auto.md` (item 4 lê §9; item 6.1 declara coluna e teto), `commands/jira-sync.md` (linha "Unidade de QA" no output + aviso de marco não-canônico), `commands/init.md` (diagnóstico de marcos não-canônicos). Doutrina nova + mudança no contrato de output → minor: plugin 0.41.1 → 0.42.0.

---

### 4.66 — Verificação que falha não se contorna: baseline obrigatório, bypass proibido e gate 2 por regressão

**Problema**: caso real em sessão de consumidor — a sessão encontrou **erro pré-existente** na main (suíte Jest vermelha antes de qualquer mudança), não conseguiu rodar os testes, e a saída escolhida foi o **silêncio**: commitou com `--no-verify`, não rodou nem os testes próprios nem os do domínio, e não reportou nada. A doutrina já previa o caso — "testes pré-existentes vermelhos antes de você começar" era item da lista de furo no plano do `developer` (4.38) — mas previa **no lugar errado e com incentivo invertido**, por três furos compostos:

1. **Sem passo de baseline no fluxo.** O developer só rodava testes na etapa final, *depois* de implementar. Descobrir o vermelho pré-existente com código já investido convida a racionalização "não fui eu que quebrei" — e a regra existia como item de lista dentro de uma seção, não como passo do fluxo (a mesma lição da 4.65: doutrina que a leitura seletiva pode pular).
2. **Nenhum dono proibia os mecanismos de contorno.** `--no-verify`, filtro do runner estreitado para excluir a suíte vermelha, flag de "passa sem testes", skip/deleção do teste, ou simplesmente não rodar — nada nomeava esses atos como violação, e o report (`testes: total/passando`) aceitava uma rodada estreitada sem que ninguém percebesse: não havia campo que forçasse declarar **qual comando de verificação rodou de fato**.
3. **O gate 2 punia a honestidade.** "Pré-existentes do domínio tocado seguem verdes" significava que **declarar** o vermelho pré-existente garantia reprovação, enquanto o silêncio tinha chance de passar — o incentivo apontava para esconder.

**Decisão**: quatro patches, cada um no dono da regra, mais um cinto de segurança mecânico.

1. **Doutrina agnóstica** (`core/TESTING.md`, seção nova "Verificação que falha não se contorna"): verificação que falha ou não roda tem **duas saídas** — corrigir (se no escopo) ou parar e reportar; erro pré-existente explica a origem do vermelho, **não autoriza entregar sem prova**. Baseline antes de mudar; lista nomeada dos contornos (todos = a violação de gate da 4.38); e a régua de silêncio: *"silêncio sobre verificação lê-se como verificação aprovada — e essa é a falha que esta regra existe para impedir"*. "Não rodei: motivo" é estado válido; omissão nunca é.
2. **Baseline como etapa do fluxo** (`agents/developer.md`, etapa 2 nova): rodar a verificação escopada **uma vez antes de tocar no código** e registrar comando + resultado. Vermelho → parar ali (`Blocked`/`furo_no_plano`), quando reportar ainda é barato; o Tech Lead pode corrigir, estacionar ou **sancionar prosseguir** com o vermelho declarado. A rodada final compara contra o baseline: nenhum vermelho novo.
3. **Verificação declarada no report** (`agents/developer.md`): campo obrigatório `verificacao:` com `baseline` e `final` — o comando **literal** executado e o resultado, espelhando para a verificação o princípio que o CODE-REVIEW já tinha para gates.
4. **Gate 2 mede regressão, não o passado** (`core/CODE-REVIEW.md`): vermelho pré-existente **declarado e sancionado** não reprova por si — reprova vermelho **novo** vs. baseline, vermelho pré-existente **omitido** (REPROVADO por omissão) e evidência produzida por contorno. Declarar passa, esconder reprova — o incentivo passa a apontar para a honestidade.
5. **Guard mecânico** (`hooks/noverify-guard.sh`, PreToolUse em Bash): bloqueia `git commit/push --no-verify` no mesmo comando simples (sem atravessar `| ; &&` — zero falso positivo de pipeline). Escape consciente e nomeado, mesma régua da 4.63: `KEELSON_ALLOW_NO_VERIFY=1` prefixado no comando — o pulo vira ato declarado com rastro no transcript. A doutrina cobre o agente que a lê; o guard cobre o que não leu. Validado com `bash -n` + 8 cenários sintéticos no scratchpad (commit/push bloqueiam · escape passa · commit normal passa · `--no-verify` noutro comando do pipeline passa · grep passa · input vazio/quebrado passa).

**Aplicação**: `guidelines/core/TESTING.md` (seção nova), `agents/developer.md` (etapa 2 de baseline, renumeração 2→3…7→8, campo `verificacao`, caso de furo atualizado), `guidelines/core/CODE-REVIEW.md` (gate 2), `commands/implement.md` (destino "baseline vermelho" no sinal de furo da 3.5), `hooks/noverify-guard.sh` (novo) + registro em `hooks/hooks.json`. Doutrina nova + hook novo → minor: plugin 0.42.0 → 0.43.0.

---

### 4.67 — Três estados da ação de UI: a FR especifica o comportamento observável; efeito invisível não é feedback

**Problema**: caso real em consumidor — a demanda pedia um botão que envia e-mail ao clicar; o e-mail saiu, **nenhum feedback visual apareceu**, e o ciclo inteiro aprovou: o time entregou *exatamente* o que a SPEC pedia. O furo não foi do developer nem dos gates — foi da **SPEC**, que definiu o efeito (e-mail enviado) e calou sobre o comportamento observável (o que a tela mostra). A pergunta de projeto: onde colocar a regra genérica "ação em tela precisa de feedback"? Diretriz de implementação ("todo botão dá feedback") seria prosa dependente de alguém lembrar na hora de codar — o padrão de falha que a 4.65 nomeou (doutrina que a leitura seletiva pula) — e não teria dono claro: não existe perfil frontend além do `none.md`, e o core não tem doutrina de UX.

**Decisão**: a regra sobe de altitude — vira regra de **escrita de FR**, onde ela gera ACs e os gates existentes a aplicam sem máquina nova. Dois patches, cada um no dono:

1. **`commands/specify.md`** (Etapa 2, princípio 9 novo — o dono da regra): FR de ação iniciada pelo usuário na interface DEVE especificar o comportamento **observável** dos três estados — *em andamento*, *sucesso* e *falha*. **Efeito invisível (e-mail enviado, registro gravado, job disparado) não é feedback** — feedback é o que a tela mostra. FR de ação sem os três estados está incompleta; cada estado vira AC verificável, e daí o enforcement é herdado: gate 1 exige teste por AC, gate 9 (QA) prova o comportamento na tela. A regra fica falsificável em vez de aspiracional.
2. **`agents/product-analyst.md`** (eixo 3, cobertura de cenários — o cinto): feedback/erro/loading esquecidos são *o* cenário faltante clássico; a crítica de mérito pergunta explicitamente se o usuário **percebe** o sucesso, **vê** a falha e **sabe** que está em andamento.

Check mecânico no `spec-validator` (detectar FR de ação de UI sem os três estados) **não entra**: é regra semântica, cara, com amostra de um — **reservada para reincidência**, pela mesma régua das 4.52/4.64.

**Aplicação**: `commands/specify.md` (Etapa 2, princípio 9), `agents/product-analyst.md` (eixo 3). Doutrina nova → minor: plugin 0.43.0 → 0.44.0.

---

### 4.68 — Asserções que provam: anti-tautologia mecânica, dado criável não vira handoff, artefato renderizado como evidência

**Problema**: postmortem real de consumidor — entrega de e-mail multi-locale com **quatro defeitos visíveis em segundos no artefato renderizado** (foto ausente, frase de destaque duplicada, moeda errada em 5 de 7 países, link `file://`), mais uma **regressão que derrubou o boot da aplicação** introduzida durante a correção. Todos os gates verdes; o code review aprovou. Cinco mecanismos, cada um com um furo de doutrina próprio:

1. **Os testes eram tautológicos ou fracos — e o gate 1 não tinha régua mecânica para vê-los.** O valor esperado do teste de link era calculado chamando o próprio código de produção (`new AdUrl(...).handle()`) — o teste passa para qualquer URL que o gerador devolva. A frase duplicada foi *renderizada pelo teste e aprovada*: asserção de "contém" passa com 1 ou N ocorrências. O fixture sempre-preenchido tornava o ramo de fallback da foto invisível por construção. E o NFR "todos os locales" foi coberto testando só o default. O Charter já dizia "gerador ≠ avaliador" e o gate 1 já exigia "teste falsificável" — como **filosofia**. Quem escreveu os testes foi quem escreveu o código, na mesma sessão, com a mesma premissa errada; a filosofia não sobrevive a isso, um check mecânico sobrevive (o mesmo padrão da 4.58: reincidência de princípio ignorado vira check).
2. **O gate que pegaria tudo não rodou — e a pendência se auto-concedeu.** Os 4 defeitos eram óbvios no e-mail renderizado (gate 9); o QA declarou "não há anúncio 'Em Oferta' no dataset" e a verificação virou `pendente_handoff`. Mas **o dado era criável** — o banco estava de pé. O protocolo de handoff nomeia 3 causas de indisponibilidade (runtime, credencial, app fora do ar — 4.49) e nenhuma cobre dado ausente; "não encontrei" foi aceito como "não é possível" sem tentativa de criação nem escalação, e o handoff virou papelada em vez de bloqueio.
3. **Ninguém olhou o artefato.** O relatório de gates tinha 20 itens; o HTML renderizado revelava os 4 defeitos numa olhada de 30 segundos. A evidência do QA era só asserção e checklist — o artefato renderizado não era exigido como evidência nem chegava à revisão humana.
4. **Runner e runtime com toolchains distintos**: Jest transpilava com Babel moderno; o runtime carregava via `babel-register` com parser antigo que não entende `??`. 6137 testes verdes, aplicação morta no boot. "O dublê não é produção" já existia no TESTING.md — mas falava de banco/serviço, não do **toolchain do próprio runner** como dublê.
5. **A correção do dado compartilhado (locale) só revelou 2 specs quebradas de outra feature na suíte completa** — o filtro escopado do gate 2, mesmo ampliado "para os consumidores", não alcança consumidor que não é enumerável por grep/imports.

**Decisão**: cinco patches, cada um no dono da regra.

1. **`guidelines/core/TESTING.md`** (seção nova "Asserções que provam (anti-tautologia)"): quatro regras mecânicas — esperado com **origem independente** do gerador (nunca calculado chamando produção) · unicidade se prova **contando**, não com "contém" · **um caso por ramo** de fallback, com fixture na forma real do dado · requisito quantificado ("todos os X") vira **tabela de casos**, um por elemento ou classe de equivalência demonstrada.
2. **`guidelines/core/CODE-REVIEW.md`**: gate 1 ganha os quatro checks como **achado bloqueante** (teste tautológico = AC sem teste); gate 2 ganha a **exceção sancionada da suíte completa** — dado compartilhado de amplo alcance (locale, config global, fixture central) cujos consumidores não são enumeráveis com confiança → a rodada escopada é insuficiente. `agents/developer.md` (etapa 5) aponta a régua para quem escreve o teste antes do reviewer aplicá-la.
3. **Dado criável não é indisponibilidade** (`docs/_meta/conventions/handoff-protocol.md` §8.1 + `agents/qa.md` etapa 2): "não encontrei" ≠ "não é possível". Com o ambiente de pé, o dado que o AC exige se **cria** (seed, factory, API, rotina do projeto); criação que exige decisão/acesso fora da sessão **escala** (proposta + default) antes de declarar pendência. Item pendente por falta de dado só existe com a tentativa de criação ou a escalação **registrada** — sem registro é handoff-atalho, a mesma régua da sondagem (4.26).
4. **Artefato renderizado é evidência** (`agents/qa.md` etapa 3): saída renderizável (e-mail HTML, template, documento) → renderizar com dado representativo, **inspecionar o artefato** (elementos do AC, duplicação, links, fallbacks de campo vazio), **salvar** e citar o caminho na evidência, que segue no report da Entrega — a revisão humana vê numa olhada o que o checklist esconde.
5. **O toolchain do runner também é dublê** (`guidelines/core/TESTING.md`, "O dublê não é produção"): runtime que carrega o código por caminho diferente do runner (transpilador, versão de interpretador, loader) → suíte verde não prova que a aplicação sobe; mudança em código carregado pelo runtime real exige prova de carga/boot nele (comando concreto no perfil/ficha).

A proibição concreta de `??`/`?.` no consumidor ficou no **perfil do projeto dele** (é regra de stack, não de doutrina) — o core carrega só o princípio generalizável do item 5.

**Aplicação**: `guidelines/core/TESTING.md` (seção nova + dublê), `guidelines/core/CODE-REVIEW.md` (gates 1 e 2), `agents/qa.md` (etapas 2 e 3), `agents/developer.md` (etapa 5), `docs/_meta/conventions/handoff-protocol.md` (§8.1). Doutrina nova → minor: plugin 0.44.0 → 0.45.0.

---

### 4.69 — `/keelson:postmortem`: o postmortem de fim de sessão como comando, alimentando a evolução do plugin

**Problema**: os dois postmortems de consumidor que mais moveram a doutrina (4.67, 4.68) foram escritos **à mão**, porque o Diretor pediu — o mesmo padrão que a 4.54 corrigiu para a proposta pontual: a análise valiosa existia, mas não havia desenho que a produzisse sem pedido ad-hoc. A máquina atual cobre o achado **pontual no fecho do ciclo** (`agile-coach` → `PROPOSTA_PLUGIN` → `mensagem_mantenedor`); o que não tem dono é o **episódio inteiro**: a sessão que acumulou correções do Diretor, retries, gates reprovados e defeitos achados depois da entrega — cuja análise exige reconstruir a linha do tempo, separar defeito de escopo novo, agrupar sintomas por causa-raiz e nomear as intervenções baratas perdidas (inclusive as do próprio Diretor). O postmortem manual da 4.68 demonstrou também as disciplinas que fazem a análise prestar: contar a conta honesta ("6 erros meus, não 5 — o #5 foi escopo novo"), citar a asserção literal do teste fraco, e **não** atribuir a causa à capacidade do modelo de dentro da sessão.

**Decisão**: comando novo **`/keelson:postmortem`**, humano-only (`disable-model-invocation`), rodado pelo Diretor no fim da sessão (default: a sessão corrente é o alvo e as interações são o input — nada a perguntar) ou apontando episódio passado (aí a lista do que doeu é o insumo que só o Diretor tem; pergunta-se uma vez). Cinco princípios invioláveis destilados do caso real: **fatos antes de teses** (releitura ativa das interações + git + artefatos + o teste aberto com a asserção citada — nunca impressão residual) · **defeito ≠ escopo novo** ("esqueci de falar" não é defeito; inflar a conta produz regra para problema que não existiu) · **autoria honesta** (régua da 4.54, estendida ao Diretor: o ponto de intervenção mais barato se nomeia sem culpa — é material de contrato) · **não atribua ao modelo** (falha de **verificação** — regra mecânica fecharia o furo — vira proposta; falha de **raciocínio** não vira regra) · **um dono por achado** (projeto × processo × pergunta do init × contrato do Diretor). Fluxo: tabela dos fatos com naturezas (defeito original · regressão na correção · correção incompleta · retrabalho de processo · requisito novo · dívida pré-existente) → mecanismos **por causa-raiz** (qual gate viu e aprovou, não rodou ou não tinha como ver) → endereçamento: lição de projeto **aplicada na hora**; achado de processo despachado ao **`agile-coach`** (uma invocação por causa-raiz), que mantém o monopólio do formato da proposta (dedup no ledger, diff literal, orçamento — 4.54/4.64); `DESCARTADO` declarado é saída legítima. Saídas: doc durável `<docsRoot>/_meta/postmortems/PM-<data>-<alvo>.md` + **bloco copy-paste ao mantenedor** fechando o output (o mecanismo do prompt de handoff, outro destinatário). O comando **não corrige** — defeito aberto vira demanda via `/keelson:triage`. Nenhum agent novo: a composição é do Tech Lead, a proposta é do `agile-coach`.

**Aplicação**: `commands/postmortem.md` (novo), tabela *Commands* do `README.md`, §3.17 do `docs/_meta/method-guide.md`, nota humano-only do `templates/CLAUDE.keelson-block.md`. Comando novo → minor: plugin 0.45.0 → 0.46.0.

### 4.70 — Modelo por papel: geração barata, julgamento caro

**Problema**: nenhum agent declarava `model:` no frontmatter — todos herdavam o modelo da sessão. Rodando o ciclo com um modelo de topo, cada token do ciclo custa o preço máximo, e o maior volume de tokens está justamente no papel que menos depende dele: o `developer` (lê codebase, escreve código, roda testes — transcripts longos), que no desenho SDD recebe uma TASK atômica cujo pensamento já aconteceu a montante (SPEC → PLAN → TASK). Relato de campo: consumo alto de cota nas rodadas reais do fluxo.

**Decisão**: cada agent declara `model:` explícito no frontmatter, seguindo o princípio **geração barata, julgamento caro** — o mesmo eixo do "gerador ≠ avaliador" do Charter. Execução de alto volume roda em `sonnet`: `developer`, `qa` (executa e compara com ACs literais), `agile-coach` (patches pequenos de processo). Julgamento e decisão rodam em `opus`: `code-reviewer` (a rede que segura a qualidade quando a geração barateia), `security-engineer` (falso-negativo caro, volume baixo), `po`/`pm`/`product-analyst` (decidem em nome do Diretor / crítica de mérito), `staff-engineer` (gera doutrina, roda raro). A assimetria é deliberada: baratear o gerador é seguro **porque** os avaliadores continuam fortes — rebaixar um avaliador exige nova decisão, não ajuste fino. Validators (skills) ficam fora: rodam no contexto do invocador e seguem o modelo da sessão. Trocar modelo reduz o custo por token, não o volume — a dieta de contexto (briefing destilado, 4.35) segue sendo a alavanca do volume e deve ser observada nas rodadas reais.

**Aplicação**: frontmatter `model:` nos 9 `agents/*.md`. Muda o comportamento nos consumidores → minor: plugin 0.46.0 → 0.47.0.

### 4.71 — Quem concede o waiver não o avalia: enum fechado no aceite, `quality.boot`, pendência não é licença para Done

**Problema**: o primeiro postmortem rodado pelo `/keelson:postmortem` (episódio real de consumidor, sob plugin 0.40.0) devolveu seis resíduos de processo que as releases 4.66–4.68 — nascidas do mesmo episódio — não haviam fechado. Padrão comum a quase todos: a 4.68 endureceu o **gerador** da evidência (o `qa` que sonda, o teste que afirma) e deixou o **avaliador** com régua de texto livre — no caso medido, o gate 9 foi dispensado com `causa: dados_de_teste_indisponiveis`, valor que **nem existe** no enum do §8.1, e o aceite passou porque a régua pedia só causa "nomeada"; noutro caso, um `curl` que retornou 404 foi documentado com capricho e a task declarada Done — a pendência bem-narrada funcionou como licença. Ao lado disso: o princípio "o toolchain do runner é dublê" ficou sem operação (nenhum campo diz **como subir a app**, então `app_fora_do_ar` é waiver barato); o self-check do init prova a cobertura do segredo **do keelson** (`keelson.local.json`) e nada dos segredos **do projeto** — efeito medido: `sensitiveGlobs` cobria os `.env*` de subdiretórios e não o `.env` da raiz, que vazou; e lição registrada na branch da wave foi relatada como "em vigor" sem nunca ter chegado à main.

**Decisão**: fechar o **lado avaliador** de cada mecanismo, em cinco frentes: (a) o aceite do gate 9 no `/keelson:implement` exige `causa_indisponibilidade` **do enum fechado** do §8.1 — valor fora do enum é rejeição, porque quem concede o waiver não amplia o catálogo de causas; (b) o report do `code-reviewer` declara os **4 checks mecânicos de falsificabilidade** do gate 1 como sub-campo estruturado (`falsificabilidade:`), no mesmo padrão do gate 6 — aplicado, não presumido; (c) campo novo **`quality.boot`** na ficha (como se sobe a app para exercício local; `null` é resposta válida, mas escolhida): o `qa` só reporta `app_fora_do_ar` com a tentativa de boot registrada quando o campo está declarado, e campo ausente é lacuna da ficha, não presunção; (d) **pendência documentada não é licença para Done** no contrato do `developer` — AC não realizado ou verificação que não rodou impõe `Blocked`/`Failed` com a pendência em `falhas`, por mais caprichada que seja a narrativa; (e) o self-check do init prova **por matching real** que os `sensitiveGlobs` cobrem os arquivos de segredo que existem no projeto (mesma régua da 4.51), e a Entrega declara lição gravada em branch como **pendente de merge** até a main recebê-la. O sexto resíduo do postmortem — hook governando a **forma de acesso** a arquivo de segredo (`grep` que ecoa valor onde `cut -d= -f1` bastava) — fica **adiado para decisão própria**: exige desenho de falso-positivo que não cabe no saldo desta leva.

**Aplicação**: `commands/implement.md` (aceite do gate 9, lição pendente de merge no item 5 da closure + seção "Lições registradas" na Etapa 5), `agents/code-reviewer.md` (sub-campo `falsificabilidade` no report), `agents/developer.md` (regra "pendência não é licença"), `agents/qa.md` + `docs/_meta/conventions/handoff-protocol.md` §8.1/§8.2 (tentativa de boot como evidência), `templates/keelson.config.example.json` + `commands/init.md` (campo `boot`: detecção, pergunta, self-check; self-check de `sensitiveGlobs`). Capacidade nova na ficha → minor: plugin 0.47.0 → 0.48.0.

### 4.72 — Insumo de consumidor real se abstrai antes de virar registro

**Problema**: a leva da 4.71 absorveu o primeiro postmortem de um projeto real de consumidor — e o glob literal da ficha daquele projeto atravessou intacto até o `CHANGELOG.md` (face pública do pacote), a doutrina do `commands/init.md` e esta própria seção de decisões, junto com o slug do episódio. O Diretor apontou na revisão: o postmortem entrega o fato com o identificador do projeto porque é assim que ele nasce, mas o registro do keelson deve carregar só o que é útil **genericamente** — o específico pertence à configuração e aos docs do próprio consumidor. Com o `/keelson:postmortem` operacional, esse insumo passa a ser rotina, e sem regra o vazamento se repete a cada leva.

**Decisão**: abstração como etapa obrigatória da absorção. Identificadores de consumidor (nome do projeto, slug de demanda/episódio, paths, globs, URLs, nomes de chave) **não entram** em doutrina, `decisions.md` nem `CHANGELOG.md` — registra-se o **padrão** que o caso ensina, formulado de modo que sirva a qualquer projeto; o literal fica no consumidor. Teste de aceitação: se a frase só faz sentido conhecendo aquele consumidor, ainda está específica demais. O dono da regra é o `CLAUDE.md` deste repo (é disciplina do mantenedor ao absorver, não do comando que gera o postmortem — o doc do consumidor **deve** citar seus próprios literais).

**Aplicação**: bullet em "Registro e governança" do `CLAUDE.md`; retroativa na leva 4.71 (CHANGELOG `0.48.0`, `commands/init.md`, §4.71). Correção → patch: plugin 0.48.0 → 0.48.1.

### 4.73 — code-scout: reconhecimento delegado devolve conclusão ancorada, não arquivos

**Problema**: as fases exploratórias do ciclo rodam no contexto da main session — triage, specify, plan, status e review avulso abrem com varredura de codebase, e cada `grep`/`Read` exploratório fica residente no transcript do Tech Lead até o fim da sessão, pago de novo em cada turno seguinte, no modelo mais caro da casa. A 4.70 barateou o custo por token dos papéis de execução e a 4.35 atacou o volume via briefing destilado — mas a exploração do próprio Tech Lead seguia sem alavanca: ele lê dezenas de arquivos para responder uma pergunta e carrega todos dali em diante, sendo que só a resposta importava.

**Decisão**: agent `code-scout` — ferramenta de reconhecimento **fora do elenco do time** (como os validators, 4.37): o Tech Lead delega a varredura ampla e recebe **conclusão ancorada** — síntese curta em que toda afirmação estrutural cita `arquivo:linha`, no eixo do "verificado, não deduzido" (4.58). Afirmação sem âncora não vira fato; lacuna vira `nao_encontrado`, nunca suposição plausível. Roda em `sonnet`: reconhecimento é pré-geração, não avaliação — o eixo da 4.70 (julgamento caro) fica intacto e nenhum avaliador foi rebaixado. Dois limites deliberados: (a) **gatilho com guardrail** — delega-se varredura ampla, onde a viagem de ida e volta compensa; lookup pontual o Tech Lead faz inline; (b) **exaustividade não é prometida** — censo completo (todos os usos de X antes de rename/migração) exige conferência do invocador, e o campo `confianca` do report declara a cobertura. O alcance é deliberadamente o Tech Lead: subagent não invoca subagent, então developer/reviewer não têm acesso — e pelo desenho SDD nem deveriam precisar (a TASK já chega com os arquivos apontados; developer varrendo codebase é sintoma de PLAN/TASK magro, não de falta de pesquisador).

**Aplicação**: `agents/code-scout.md` novo (sonnet, tools read-only); sincronizações de agent novo — tabela §5 do `method-guide.md`, comentário de `agents/` no `README.md`, elenco do §3 deste arquivo. Capacidade nova → minor: plugin 0.48.1 → 0.49.0. Observar na 1ª rodada real se o Tech Lead o adota organicamente nas fases exploratórias ou se os commands precisarão de gatilho explícito (decisão futura, se necessário). *(Observação colhida no mesmo dia — desdobrada na 4.75.)*

### 4.74 — dry-run de merge antes de integrar worktrees no final da wave (modo teams)

**Problema**: no modo AGENT_TEAMS, o final da wave (Etapa 3.6) faz merge das worktrees na branch principal da wave, e a regra para conflito era "pausar, reportar, resolução manual" — mas o conflito só aparecia **durante** o merge real. Numa wave com N worktrees, o conflito na worktree K deixa a branch da wave suja no meio da integração (merges 1..K-1 aplicados, K parado em estado conflitado), e o reporte ao Diretor sai com o repositório em estado intermediário — pior ponto de partida para a resolução manual. Insumo externo (relato de campo sobre orquestração multi-agente) apontou o padrão: merge de trabalho paralelo só roda depois de um dry-run limpo.

**Decisão**: o merge de cada worktree na branch da wave é precedido de um **dry-run que não toca a branch**: `git merge-tree --write-tree <branch-da-wave> <branch-da-task>` (git ≥ 2.38; exit ≠ 0 sinaliza conflito sem alterar índice ou working tree). Fallback para git antigo: `git merge --no-commit --no-ff` seguido de `git merge --abort`. Teste falsificável: **nenhum merge real inicia com dry-run conflitado na fila** — detectado conflito em qualquer worktree, nada é integrado; reporta-se ao Diretor com a branch da wave **limpa**, listando quais worktrees conflitam e em quais paths. Dry-runs limpos em todas → merges reais em sequência. A regra pós-conflito não muda (pausar, reportar, resolução manual — o dry-run antecipa a detecção, não a decisão); nenhum critério SEQUENTIAL_FORCED da Etapa 1 relaxa por causa disso.

**Aplicação**: bullet "Final da wave" do `docs/_meta/conventions/agent-teams.md` (dono único das especificidades do modo teams — `implement.md` segue intacto). Ajuste fino → patch: plugin 0.49.0 → 0.49.1. Sem rodada real em modo teams até aqui; observar na primeira.

### 4.75 — Modo sob demanda: o time atende a sessão livre sem o ritual do ciclo

**Problema**: primeira rodada real pós-4.73 num consumidor, em sessão livre (nenhum comando keelson invocado), com pedido de mudança pontual de código: a main session varreu a codebase inline — exatamente o trabalho que o `code-scout` existia para absorver — e implementou ela mesma, sem `developer`, sem `code-reviewer`, sem gates. Dois furos com a mesma causa-raiz: a doutrina de sessão livre conhecia só dois estados — ciclo completo ("pedido não-trivial entra no `/keelson:auto`") ou nada — e a adoção dos agents dependia apenas da `description` de cada um, que sozinha não vence o hábito da main session de fazer tudo inline. Resultado perverso: justamente na sessão informal, onde não há validator nem gate de comando, o trabalho corre sem **nenhuma** das proteções do plugin.

**Decisão**: **modo sob demanda** — o terceiro estado da sessão livre, entre o ciclo e o inline. (a) Mudança pontual de código (localizada, sem decisão de produto) não entra no ciclo, mas **não é a main session quem escreve**: o Tech Lead destila um briefing curto (o quê, onde, critério de aceite), delega ao `developer`, e o diff passa pelo `code-reviewer` com a régua avulsa da 4.36; `security-engineer` e `qa` entram pelos mesmos gatilhos do ciclo (mudança sensível · comportamento observável). Sem commit automático — precedente do modo avulso do `/keelson:review`; commit é a pedido do Diretor. (b) **Invocar um agent não puxa o ciclo**: cada agent devolve sua tarefa e para; a orquestração é sempre do Tech Lead — o receio de "chamou um, entra em tudo" não tem fundamento técnico, e a doutrina agora o declara. (c) Trivial não-comportamental (typo de comentário/doc) pode ser inline, declarado. (d) Varredura ampla em sessão livre → `code-scout` — fecha a observação da 4.73: adoção orgânica só por description **não aconteceu** na primeira rodada; o gatilho passa a viver no bloco do consumidor (a única superfície keelson sempre presente numa sessão livre) e como deixa nos commands exploratórios. As descriptions dos executores declaram o novo invocador (regra de sincronização do repo).

**Aplicação**: `templates/CLAUDE.keelson-block.md` (bullets "modo sob demanda" e "varredura ampla" em *Como trabalhar*); descriptions de `developer`, `code-reviewer`, `qa`, `security-engineer` e `code-scout`; tabela §5 do `method-guide.md` (invocadores + parágrafo do modo); deixa do `code-scout` em `commands/triage.md`, `specify.md`, `plan.md` e `review.md`. Doutrina nova → minor: plugin 0.49.1 → 0.50.0. **Re-rodar `/keelson:init` nos consumidores** (bloco novo). Observar na próxima sessão livre real se o roteamento acontece.

### 4.76 — Ledger de sessão: o relatório é escrito enquanto acontece, e o tracker degradado ensina a recuperação

**Problema**: dois relatos do mesmo dia, com a mesma causa-raiz — **o que o ciclo sabe não chega a quem opera**. (a) Consumidor com conector MCP do tracker configurado e funcionando; o conector caiu no meio da sessão, e o ciclo seguiu sem mover nenhum card. A doutrina cobria o caso "indisponível desde a largada" (§0: prova, rastro no INDEX, `jira-guard`), mas não o **conector provado disponível que cai depois**: a prova "vale para a execução inteira" e cada gancho seguinte falhou sozinho, engolido como best-effort. Pior: mesmo onde o aviso saía, ele era prosa solta — o operador não tinha como saber que existe um comando de reconciliação para rodar depois de reconectar, e só descobriria o desalinho abrindo o quadro dias depois. E fora do `/keelson:auto` (item 6.1) **nenhum** comando levava estado de tracker ao report. (b) Modo sob demanda (4.75) entregava mudança sem nenhum fecho: sem composição de diff, sem quem revisou o quê, sem decisões tomadas em nome do Diretor. Rodar um relatório sob demanda relendo a sessão inteira resolveria com o custo errado — e o detalhe que o contexto comprimiu já não está lá para ser relido.

**Decisão**: **o relatório final não se reconstrói de memória — ele se acumula.** (a) **Ledger de sessão** (`thoughts/local/session-ledger/`, dono único em `sdd-conventions.md`): cada evento de um **catálogo fechado** (`gate` · `decisao` · `fora_de_escopo` · `pendencia` · `tracker` · `marco`) é escrito **no instante em que acontece**, um arquivo por evento — nunca append num arquivo compartilhado, porque waves rodam em worktrees paralelos e o `thoughts/local/` do worktree não é o do working tree principal. **O escriba é o Tech Lead**: os avaliadores são read-only por desenho e não ganham `Write` para isso. Fato que sobrevive à sessão continua indo para o INDEX/BRIEF/learning-log — a régua é *sobrevive à sessão → INDEX; serve ao report desta sessão → ledger*. O ledger **nunca é gate**: ausente ou incompleto → report com lacuna nomeada. (b) **Fecho automático**: toda mudança termina com relatório exibido sem que o Diretor peça — inclusive no modo sob demanda; o comando **`/keelson:report`** existe como rede de segurança (sessão retomada, report perdido), não como caminho normal. Ele lê o ledger + o diff + o INDEX, e **não relê a sessão** (releitura ativa é do `/keelson:postmortem`, que responde outra pergunta e tem outro destinatário). (c) **Disponibilidade do conector é estado da execução, simétrico**: a prova positiva já valia para a execução inteira; a **queda passa a valer também** — falha por indisponibilidade marca o conector como caído, os ganchos seguintes acumulam em vez de reprovar um a um. Falha de *uma operação* com o conector respondendo continua sendo aviso, não queda. (d) **Saída degradada tem formato** (§14 do protocolo, dono único): sync degradado produz **seção de report acionável** com o comando literal de reconciliação em copy-paste — mesmo padrão do prompt de handoff (4.30) e da mensagem ao mantenedor (4.54) —, com `--phase` sugerida **só** quando havia movimento pendente e nunca sob `transition: off`. Best-effort permanece inviolável: nada disso bloqueia; é saída, não gate.

**Aplicação**: bullet "Ledger de sessão" em `docs/_meta/conventions/sdd-conventions.md` (dono único do mecanismo); `skills/_shared/jira-sync-protocol.md` §0 (estado do conector) + §14 nova; `commands/auto.md` (Etapa 0.5 item 5, Etapa 4, Entrega itens 4/6.3/7.4/10), `commands/implement.md` (Etapa 3, sinais laterais 3.5, closure item 4, Etapa 5 + seção no output), `commands/specify.md`, `commands/tasks.md`, `commands/integrate.md` (ganchos apontando a §14); `commands/report.md` novo (humano-only) com as três sincronizações de comando — tabela *Commands* do `README.md`, §3.18 do `method-guide.md`, nota do `templates/CLAUDE.keelson-block.md`; bullet "toda mudança fecha com relatório" no mesmo bloco. Capacidade nova → minor: plugin 0.50.0 → 0.51.0. **Re-rodar `/keelson:init` nos consumidores** (bloco novo). *Insumo de consumidor real abstraído conforme 4.72 — o padrão que ensina, não o projeto que o revelou.* Observar na 1ª rodada real: se o ledger é alimentado de fato durante as waves (o risco é lembrar dele só no fecho, que é exatamente o que ele existe para evitar) e se a seção de reconexão sai com o comando certo quando o conector cai.

### 4.77 — Forma da descrição é esqueleto literal, não prosa sobre a forma

**Problema**: card de unidade de QA gerado num consumidor real saiu com a estrutura "Requisitos / Critérios de aceitação / Pontos centrais" — nenhuma das três existe na doutrina (`grep` por "Pontos centrais" no repo: zero ocorrências). Faltava **Como testar**, a única seção que justifica o card existir; os requisitos eram uma faixa de IDs remetendo à SPEC, os ACs vinham só como IDs, e uma premissa era citada pelo identificador. O conteúdo estava correto e até bom — inclusive o cenário-limite de borda —, mas em forma de **nota de decisão de produto**, não de roteiro de teste: o QA que só lê o card não consegue testar sem abrir o repo, exatamente o teste falsificável que a §6.2 declara. Duas causas: (a) a §6.2 **descrevia** os templates em prosa densa, um parágrafo por seção com as regras encaixadas — e prosa sobre a forma é parafraseável, ao contrário do esqueleto literal que o `commands/specify.md` exibe para a SPEC; (b) **nenhum gate olha a descrição gerada** — os validators cobrem artefatos do repo, a projeção no tracker é best-effort (§0), e essa tolerância, pensada para *o conector cair*, acabou cobrindo também *a descrição sair errada*. Não é caso de seção não lida: todos os ganchos listam a §6.2 na leitura seletiva.

**Decisão**: (a) **esqueleto literal para os três papéis** (Epic · unidade de QA · sub-task) — blocos markdown copiáveis com os headings exatos, na ordem, a preencher; a prosa remanescente vira **regras de preenchimento** ao lado, não a definição da forma. (b) **Check de forma antes de enviar**, no próprio §6.2 (dono único): headings todos presentes na ordem e nenhum extra · **Como testar** com ao menos um cenário de passos numerados · cada AC com **texto**, não só ID · nenhuma linha remetendo a artefato do repo. Falhou → **re-renderiza uma vez**; falhou de novo → **cria a issue assim mesmo** com a lacuna nomeada no aviso. Auto-corretivo, nunca bloqueante: card magro é ruim, card ausente é pior (quebra o parenting das sub-tasks e a idempotência do §4), e o §0 é inviolável. É gate de **forma** — não julga se o roteiro testa bem, só se o card é autossuficiente. (c) Duas regras que nomeiam os erros observados: **referência a artefato não substitui conteúdo** (ID sempre com texto; conteúdo de FR/premissa que importa ao teste vira frase da narrativa ou passo do roteiro) e **cenário-limite conhecido é passo, não observação** — regra de borda que a SPEC nomeia entra em *Como testar* com o valor concreto na preparação; o que não vira passo, o QA não testa.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` §6.2 (dono único da receita — os ganchos de `specify`, `tasks`, `implement` e `auto` já a leem e herdam sem alteração; `jira-sync-feat.md` referencia o mesmo template). Doutrina nova → minor: plugin 0.51.0 → 0.52.0. Não exige re-rodar `/keelson:init` (nada muda no bloco do consumidor). *Insumo de consumidor real abstraído conforme 4.72.* Observar na 1ª rodada real: se o card nasce com as quatro seções e se o check pega a paráfrase antes do envio — a hipótese a falsificar é que o esqueleto literal baste e o check só registre exceção.

### 4.78 — O Given-When-Then do AC é preservado no card; o que falta é como chegar ao estado

**Problema**: pergunta do Diretor, com objetivo declarado — *o analista de QA humano precisa se resolver sozinho, sem perguntar*. A receita mandava traduzir o jargão Given-When-Then em prosa imperativa "em linguagem de usuário", e isso custa duas vezes: (a) descarta uma forma que o QA **já domina** — times acostumados a BDD leem `Dado/Quando/Então` como vocabulário nativo, e substituí-lo por passos numerados troca clareza por paráfrase; (b) obriga o card a repetir o mesmo conteúdo em duas seções (o roteiro traduzido **e** a lista formal de ACs), inflando sem informar. Pior, nenhuma das duas resolve o que de fato trava o testador: o AC é **declarativo por desenho** — "Dado uma competência cujo primeiro dia cai numa quarta-feira" diz o que provar e **não** diz como chegar lá. É nessa lacuna que ele para e pergunta ao Diretor. Evidência colateral do formato antigo: um card real listava os ACs como IDs soltos e **omitia dois** deles, sem que a omissão fosse detectável na leitura.

**Decisão**: o cenário passa a ser **AC literal + reprodução concreta** — o Gherkin dá o contrato, os passos dão o caminho. (a) As três linhas `Dado/Quando/Então` são **copiadas** da SPEC, não reescritas (reescrever abriria espaço para afirmação que o artefato não sustenta — mesma âncora de contenção da 4.58); o que se traduz para narrativa de negócio é o **EARS dos FRs**, nunca o AC. (b) Cada cenário traz uma linha `Como reproduzir` com **valor concreto** — a data literal a posicionar, o registro a criar, o perfil com que entrar —, e repetir a condição abstrata do `Dado` como se fosse passo é o furo nomeado, não uma variação aceitável. Dado inexistente no ambiente vem com **como criá-lo**. (c) A seção "Critérios de aceitação" separada **desaparece**: o AC mora dentro do cenário. O card **encolhe** em relação ao formato anterior — a mesclagem funde duas seções, não soma uma terceira. (d) **Um cenário por AC da funcionalidade** torna a cobertura visível: AC sem cenário nem lugar na linha dos automatizados salta aos olhos, ao contrário da lista de IDs que escondia a omissão — e o check de forma da 4.77 ganha o item correspondente (todo AC com destino) e o item que pega reprodução sem valor concreto. (e) **Risco aceito que se manifesta na tela vira linha do fora do escopo**: é exatamente o que um QA de boa-fé abre como bug, e a §9 da SPEC passa a ser fonte do card tão legítima quanto o out-of-scope da §4.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` §6.2 — abertura (o que se traduz e o que se preserva), esqueleto da unidade de QA, regras de preenchimento e check de forma; `skills/_shared/jira-sync-feat.md` (item 3, "um cenário por AC" no lugar de "roteiro e lista formal"). O esqueleto da sub-task não muda — o card do dev continua com a lista curta. Doutrina nova → minor: plugin 0.52.0 → 0.53.0. Não exige re-rodar `/keelson:init`. *Insumo de consumidor real abstraído conforme 4.72.* Observar na 1ª rodada real: se a linha `Como reproduzir` nasce com valor concreto ou recai na paráfrase do `Dado` — é o único item do formato que depende de julgamento e não de estrutura, e portanto o candidato natural a reincidir.

### 4.79 — As keys do tracker abrem o título do commit

**Problema**: pedido do Diretor. O ciclo grava as keys nos artefatos (§10) e move os cards, mas o **histórico do repositório** não sabe nada do tracker: quem olha `git log` não vê a que demanda cada commit pertence, e quem olha o card não chega ao código a não ser pelo PR — que só existe no fim. O elo que falta é o mais barato de todos: o título do commit, que o Jira já lê nativamente para vincular desenvolvimento à issue.

**Decisão**: com `jira.enabled`, o título do commit carrega as **keys envolvidas**, do mais amplo ao mais específico, abrindo a **descrição** — `feat(<slug>): PROJ-12 PROJ-34 PROJ-56 …` —, **depois** do `tipo(escopo):` do padrão de commit do projeto, que não é substituído nem deslocado. Regras: (a) as três fontes são as do §10 — Epic no cabeçalho da SPEC, Story sob o heading da FEAT primária (ou `**Jira Story**:`), sub-task na closure da TASK; (b) **teto** — FEAT secundária de TASK transversal não entra (o vínculo dela é o link "relates to"), e commit de wave/entrega com mais de 3 Stories leva só o Epic; (c) **commit que não é de demanda não leva key** — patch de doutrina/tooling nasce limpo, key ali é ruído; (d) **ausência nunca bloqueia** (§0): key não persistida sai da lista, nenhuma resolvida → commit sem key alguma, sem aviso — e **nunca inventar key**. Um commit não espera o Jira.

**Aplicação**: `skills/_shared/jira-sync-protocol.md` §15 nova (dono único da régua); ponteiros nos pontos que geram commit — `agents/developer.md` §7 (o principal: commit por TASK, com as três fontes inline para não obrigar a abrir o protocolo), `commands/implement.md` (closure em modo paralelo) e `commands/auto.md` (commit da Entrega + o `chore(keelson)` sem prefixo). `/keelson:review` não é afetado (não commita) e o modo sob demanda cai na regra (d) quando não há artefato com key. Capacidade nova → minor: plugin 0.53.0 → 0.54.0. Não exige re-rodar `/keelson:init` (nenhum campo novo na ficha — o gatilho é o `jira.enabled` que já existe; nada muda no bloco do consumidor). Observar na 1ª rodada real: se o developer resolve as três keys sem ler o protocolo inteiro, e se o teto de 3 Stories da entrega se mostra bem calibrado.

**Revisão da posição (0.54.1, mesma leva)**: a primeira forma publicada abria o título com as keys, **antes** do `tipo(escopo):`. O Diretor reabriu perguntando se a posição do padrão de commit habilita algo que ele não conhecia — e habilita: a primeira posição é âncora de **tooling do consumidor** (geradores de release/changelog que derivam a versão do tipo, linters de mensagem, filtros de log ancorados no início), enquanto o tracker casa a key em **qualquer posição** da mensagem. Ou seja, o lado que a forma original privilegiava não ganhava nada, e o outro podia quebrar — **silenciosamente**, num plugin distribuído, no consumidor que usasse release automation. Invertido para `tipo(escopo): KEYS descrição`; perde-se o alinhamento das keys na coluna 1 do `git log --oneline`, troca aceita. *Lição transferível: antes de deslocar um formato consagrado, pergunte o que ancora nele — a resposta costuma estar fora do problema que motivou a mudança.*

### 4.80 — O keelson alimenta a release automation; não a opera (e o tipo de commit vira lista fechada)

**Problema**: a 4.79 expôs que a régua de commit do keelson era uma frase — *"padrão do projeto; default: Conventional Commits"* em `agents/developer.md` — sem lista de tipos, sem tratamento de quebra de compatibilidade, sem dono. O histórico de um consumidor real mostrou o efeito: tipos fora do vocabulário canônico (`harden:`) convivendo com os canônicos. Hoje isso não custa nada; num projeto que **deriva versão e changelog dos commits**, custa duas coisas caras: o commit some do release notes (tipo desconhecido é ignorado pelo gerador) e a versão sai errada (`feat` × `fix` decide minor × patch; quebra não declarada publica minor onde era major, e o estrago aparece no consumidor do consumidor). O Diretor perguntou como **incorporar** `semantic-release` ao keelson — e se valia um agent novo.

**Decisão**: **não** vale agent novo, e o keelson **não opera** a release automation. (a) Agent é papel do time (4.37–4.41) — carga permanente de contexto para trabalho que é *regra de escrita* (permanente, mas de doutrina) mais *setup de projeto* (uma vez). O precedente é o runtime de browser da 4.49: virou etapa do `/keelson:init`, não um agent. (b) **Publicar release é ato do Diretor**, da mesma classe de PR, merge e deploy (4.41): envolve credencial, proteção de branch e tag — efeitos fora do repositório. O plugin **detecta e registra** a ferramenta (`commit.releaseAutomation` na ficha, Etapa 4.7 do init) e **respeita** a convenção que a casa já usa; configurá-la é decisão de engenharia do consumidor, documentada no README por stack. Instalar tooling de publicação em repo alheio seria invasivo por natureza, e a stack certa varia. (c) O que o keelson passa a garantir é o que só ele pode garantir: **os commits que ele escreve alimentam qualquer automação** — `docs/_meta/conventions/commit-convention.md` novo, dono único, com **lista fechada de tipos** (tipo inventado é defeito, não criatividade), o teste de escolha (*quem usa percebe a diferença?*), a distinção `fix` × `refactor`, e **quebra de compatibilidade declarada, nunca inferida**. Na dúvida entre `feat` e `fix`, o developer aciona o sinal **furo no plano** em vez de escolher no escuro — a escolha tem efeito de publicação, não é preferência de estilo.

**Aplicação**: `docs/_meta/conventions/commit-convention.md` (novo — dono único; o bloco de keys do tracker permanece no §15 do protocolo Jira, referenciado); `agents/developer.md` §7 (aponta para o dono, perde a régua solta); `commands/init.md` Etapa 4.7 nova (detecção da ferramenta e da convenção em uso, amostragem dos tipos do histórico, tipos não-canônicos como observação — **nunca** reescrita de histórico); `templates/keelson.config.example.json` (bloco `commit`); `README.md` (seção *Commits and release automation* + layout); `CLAUDE.md` (dono novo na lista de convenções). Capacidade nova → minor: plugin 0.54.1 → 0.55.0. **Re-rodar `/keelson:init` nos consumidores** (campo novo na ficha; merge-preserving). Observar na 1ª rodada real: se a detecção acerta a convenção da casa em projeto com padrão próprio, e se o developer de fato escala a dúvida `feat`/`fix` em vez de decidir sozinho — é a única parte da régua que depende de julgamento.

### 4.81 — A wiki é artefato gerado: documentação de usuário com fonte no repositório

**Problema**: quem **instala** o keelson não tinha porta de entrada. A documentação existente serve a dois outros leitores: o `README.md` é a face pública do pacote (inglês, vitrine) e o `docs/_meta/method-guide.md` é a referência de quem já está dentro do repositório — nenhum dos dois responde "instalei, e agora?", "o que é um slug?", "o gate reprovou, o que faço?". A superfície natural para isso é o wiki do GitHub, mas wiki tem dois defeitos estruturais que o próprio keelson existe para combater: **não tem Pull Request** (o conteúdo não passa por review nem viaja junto da mudança de comportamento que o motivou) e **não versiona com o código** (envelhece em silêncio — exatamente o "padrão de qualidade numa página de wiki que ninguém lê" que o README cita como o problema a resolver).

**Decisão**: o wiki é **artefato gerado, nunca fonte**. (a) A fonte vive no repositório e passa por PR: páginas próprias em `docs/wiki/` (onboarding — início, instalação, primeiros passos, conceitos, ficha, solução de problemas, FAQ) mais **espelhos** dos donos únicos que já existem (method-guide, Charter, contrato do INDEX, convenção de commits, protocolo de handoff). Regra que decide o que é qual: **texto que já tem dono é espelhado, nunca reescrito** — página própria só para o que não existia. (b) A publicação é mecânica: `scripts/publish-wiki.sh` (bash 3.2) copia, reescreve os links (destino publicado → página da wiki; o resto → blob no GitHub) e dá push; uma Action faz isso no push da `main`, e todo espelho abre com o banner que diz onde a página se altera de verdade. (c) **Idioma: português** — é o idioma da doutrina e do method-guide; traduzir para inglês criaria um segundo dono para a mesma regra, e o README continua sendo a face em inglês. (d) O script só remove páginas **que ele mesmo gerou** (lista `.keelson-wiki-pages` no destino): página criada à mão sobrevive, porque apagar conteúdo alheio em silêncio é pior que deixar uma órfã. (e) O `.wiki.git` só nasce depois da primeira página criada pela UI — o script **detecta e ensina**, nunca contorna. Consequência importante: a wiki **não** vira um 4º lugar a sincronizar — comando novo continua em `commands/*.md` + `README.md` + `method-guide.md`, e a página é derivada.

**Complemento (mesma leva, sem novo bump)**: publicada a primeira versão, o Diretor perguntou o que garante que a wiki seja *atualizada* e que suba junto com a versão. A resposta separa duas coisas que a decisão original misturava: **publicar** já é mecânico (Action no push da `main` — "subir a wiki" não é passo de release, e a leva que esquecer disso não quebra nada), mas **o que documentar** não tinha gatilho. Espelho anda sozinho; página própria, não. Gatilho declarado no `CLAUDE.md` com um teste único — *o que o consumidor faz mudou?* — e as rotas óbvias (campo novo na ficha → `Ficha-do-projeto.md`; comando/gate com efeito no uso → `Primeiros-passos`/`Conceitos`/`Perguntas-frequentes`; falha reconhecível nova → `Solucao-de-problemas`). "Nada a mudar" é resposta válida; não olhar, não. A régua entra também no bullet de versionamento (a leva do `CHANGELOG` passa pela wiki) e o bullet dos 3 lugares diz explicitamente que continuam 3 — a página é derivada, não a quarta cópia.

**Aplicação**: `docs/wiki/` (9 páginas próprias, incluindo `_Sidebar`/`_Footer`); `scripts/publish-wiki.sh` (`--dry-run`, `--check` para CI, `--remote`, `--wiki-dir`); `.github/workflows/publish-wiki.yml` (primeiro workflow do repo; `GITHUB_TOKEN` com `contents: write`, com fallback para o secret `WIKI_TOKEN`); `.gitignore` (`.wiki/`, o clone de trabalho); `CLAUDE.md` (seção nova, com o manifesto como dono da lista de páginas); `README.md` (ponteiro + layout). Capacidade nova → minor: plugin 0.55.0 → 0.56.0. **Não** exige re-rodar `/keelson:init` (nada muda na ficha nem no bloco do consumidor). Pendência do Diretor antes da primeira publicação: criar a página inicial do wiki pela interface web. Observar: se alguma página própria começa a repetir regra que tem dono (sinal de que deveria virar espelho), e se o banner de página gerada de fato inibe a edição pela UI.

### 4.82 — O grafo dos artefatos vira fato mecânico: sintaxe canônica de aresta, extrator determinístico e validators que citam em vez de deduzir

**Problema**: os artefatos SDD sempre formaram um grafo — TASK depende de TASK, COMP depende de COMP, PLAN cobre FR, critério cobre AC — mas todas as arestas viviam em markdown interpretado por agente. Os checks estruturais dos validators (ciclo de dependência, referência quebrada, cobertura, waves) eram **raciocínio re-derivado a cada rodada**: exatamente a classe de verificação que a 4.58 mandou converter em fato, custando tokens de avaliador e sujeita a falso-positivo/negativo silencioso. Parte das arestas (`Dependências` do COMP) nem sintaxe parseável tinha, e não existia visualização nenhuma do estado de um slug.

**Decisão**: o grafo é **derivado, nunca fonte** (o mesmo princípio da wiki, 4.81 — o markdown continua sendo a verdade). (a) Campos de aresta ganham **sintaxe canônica** (lista de IDs ou `nenhuma`) nos templates geradores; bugfix declara o AC violado em campo próprio (`**AC violado**:`); o "(cobre …)" do AC vira lista de IDs completos, restrita a uma FEAT quando a SPEC as declara. (b) Um extrator determinístico (`scripts/graph.sh`, bash 3.2 + awk POSIX, zero dependências novas, read-only) computa o catálogo de checks — ciclos, referências quebradas, IDs duplicados (precedente 4.63), waves incoerentes, cobertura FR/AC por TASK, FR sem componente na §7, conjunto FEAT derivado, simetria Depende/Bloqueia, TASK-INDEX desatualizado — e emite Mermaid (TASKs por wave; FR→COMP). (c) task-validator e plan-validator **citam a saída como fato** e mantêm só os checks semânticos: o fato substitui a derivação, nunca o julgamento — a calibração continua do validator (protocolo §1/§3). Guard-rails de rollout, todos provados por fixture: **campo vazio ≡ `nenhuma`** (acervo antigo não vira enxurrada de aviso); prosa irreconhecível → `WARNING nao-parseavel`, **nunca ERROR, nunca aborta** — e, quando o campo ilegível alimenta um check de ausência, o achado degrada junto (`[parse]`), para a promessa valer de ponta a ponta; **carência de legado** (achado de wave/cobertura sobre artefato `Done` → `WARNING [legacy]`); **degradação por resultado** no validator (qualquer execução sem saída válida → raciocínio próprio, declarado com causa); **cobertura mista** (aresta não parseada → o validator não atesta ausência de defeito por ela). A régua inteira tem dono único novo — `docs/_meta/conventions/graph-contract.md` — com fronteira explícita: formatos de ID e árvore de artefatos seguem do `index-contract.md`, referenciados e nunca redefinidos. A prova é **suíte durável** (`scripts/tests/graph/`): slugs sintéticos com defeitos plantados, saídas esperadas versionadas e runner que re-prova a métrica (zero falso-positivo no válido; todo defeito acusado) a cada mudança no parser — check novo não entra no catálogo sem fixture.

**Aplicação**: `docs/_meta/conventions/graph-contract.md` (novo dono; espelho novo no `MIRRORS` da wiki) · `scripts/graph.sh` + `scripts/tests/graph/` (novos; 21 casos) · templates `commands/plan.md`, `commands/tasks.md` (+ conferência mecânica antes do gate na Etapa 5), `commands/specify.md` · `skills/task-validator/SKILL.md` (Etapas 2/3 reescritas como ponteiro+fato; bugfix usa `AC violado`) · `skills/plan-validator/SKILL.md` (Etapa 4 idem; Etapa 2 perde os checks de existência) · `skills/status/SKILL.md` (diagrama sob demanda) · `CLAUDE.md` + `README.md` + `method-guide.md`. Capacidade nova → minor: plugin 0.56.0 → 0.57.0. **Não** exige re-rodar `/keelson:init` (nenhum campo de ficha, nenhuma mudança no bloco do consumidor — a mudança chega pelo update do plugin; artefato antigo degrada com aviso, nunca reprova por forma). O spec-validator não muda nesta leva: o template do specify canoniza o "(cobre …)", endurecer o validator é leva futura, se o campo provar valor. A leva foi construída com crítica multi-agente na SPEC (31 findings resolvidos) e revisão adversarial no diff (17 findings, todos reproduzidos antes de reportados — inclusive falso auto-ciclo no Kahn e bugfix legado reprovado, corrigidos com fixture de regressão). Observar na 1ª rodada real: (1) se os validators executam o script em vez de "validar de memória"; (2) se a carência `[legacy]`/`[parse]` segura acervo real de consumidor sem ERROR espúrio; (3) se o Mermaid do `/keelson:status` é usado pelo Diretor.

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
7. Code review por reviewer agent (`code-reviewer`)
8. Segurança (`security-engineer`, REJEIÇÃO IMEDIATA) — em mudança sensível
9. Comportamento verificado (`qa`) — em mudança com efeito observável

A 4.38 acrescenta dois bloqueios fora desta numeração, no ciclo com BRIEF: a **verificabilidade pré-código** (Etapa 3.5 do `/keelson:auto` — achados do `qa` resolvidos pelo `po`) e o **relatório de aceitação do PO** (`RECUSADA` reprova a entrega antes do commit).

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
- Usa `developer` e `code-reviewer` por referência

### 6.2 Modo AGENT_TEAMS (opt-in via `--force-mode=teams`)

- Requer o recurso experimental Agent Teams habilitado (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` no env/settings); **sem detecção programática** — tenta e degrada para SUBAGENTS, declarando no output
- Teammates independentes, coordenados por task list compartilhado + mensagens diretas
- Worktrees por task e branches separadas (isolamento criado pelo setup do keelson — não é nativo do Agent Teams)
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
| Épico / multi-demanda (2+ capacidades independentes, 2+ slugs, roadmap) | `/keelson:specify-epic` (o `pm` decompõe; cada demanda volta ao ciclo normal) |
| Mexer em slug legado pela primeira vez | `/keelson:migrate-legacy` antes, depois `/keelson:triage` |

---

## 8. Decisões em aberto (por resolver)

- Variante `/keelson:specify-small` para tarefas micro. *(A variante `specify-epic` e o papel de PM foram implementados pela 4.39 — não estão mais em aberto.)*
- Hook de pre-commit bloqueando merge sem closure.
- Convenção de UX-FRs (como escrever requisito de comportamento de interface em EARS).
- Como integrar com ferramentas de wireframe externas referenciadas pelo PLAN.
- Skill validadora do próprio bloco keelson do `CLAUDE.md`.
- ~~Agente dedicado `request-mirror` para o espelho do entendimento~~ — resolvido pela 4.38: a redação ficou com o Tech Lead, a validação independente com o `po`, e o corretor é a janela de veto do Diretor; a pendência perdeu a premissa (o espelho não é mais confirmado).
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
