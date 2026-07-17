# Decisões do processo (keelson)

> Memória institucional das decisões sobre como o keelson (spec-driven development) é praticado. Diferente da doutrina de código (QUALITY-CHARTER + perfil ativo, que regem o **código**), este arquivo rege o **processo de desenvolvimento**.

**Última revisão**: 2026-07-10
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
- Commands: `/keelson:specify`, `/keelson:plan`, `/keelson:tasks`, `/keelson:implement`, `/keelson:change`, `/keelson:rebuild-index`, `/keelson:migrate-legacy`, `/keelson:auto`, `/keelson:guiado`, `/keelson:refine`, `/keelson:integrate`
- Skills: `spec-validator`, `plan-validator`, `task-validator`, `state`
- Agents: `task-implementer`, `task-reviewer`, `security-reviewer`, `task-verifier`, `product-critic`, `process-tuner`

**Docs de governança**: `decisions.md`, `method-guide.md` e `learning-log.md` moram em `<docsRoot>/_meta/` (fora do plugin) e não são invocáveis.

---

## 4. Decisões de governança

### 4.1 SPECs são independentes e sequenciais

**Decisão**: SPEC-NNN é numeração sequencial pura, sem supersede automático nem versionamento semântico.

**Consequência**: cada SPEC vale por si. Conflito entre SPECs do mesmo slug é detectado pela leitura humana ou pela skill `state`. Não há resolução automática.

**Risco aceito**: rastreabilidade entre SPECs é responsabilidade do INDEX.md e da skill `state`.

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
- `bugfix`: criada via `/keelson:change` ou direto. Aponta para AC violado.
- `refactor`: criada via `/keelson:change` ou direto. Critério: zero mudança de comportamento observável.
- `chore`: criada manualmente. Sem vínculo obrigatório com FR.

### 4.5 Slugs legados migrados via comando dedicado

**Decisão**: slugs que existiam antes da adoção do keelson (com README.md mas sem INDEX.md) são migrados via comando dedicado `/keelson:migrate-legacy`, não como feature embutida em outro comando.

**Motivo da separação**: migração é concern temporário (vai parar de ser usado quando o legado acabar). Não deve poluir o `/keelson:change`, que é concern permanente.

**O que o comando faz**:
- Move arquivos `.md` da raiz do slug para `<docsRoot>/<slug>/legacy/`.
- Cria `INDEX.md` mínimo extraindo informações do README.
- Cria pastas vazias `specs/`, `plans/`, `tasks/`.
- **Não cria** SPECs, PLANs ou TASKs retroativas.

**Marcação no INDEX**:
- Campo `Origem: migrado de legado em <data>`.
- Capacidades implementadas marcadas com 📜 (origem: legacy).
- Decisões eventualmente extraídas marcadas com prefixo `LEGACY-DEC-`.

**Persistência dos achados**: como `/keelson:rebuild-index` deriva o INDEX só de specs/plans/tasks, os achados da migração (glossário, decisões, capacidades) vivem em `legacy/` — a fonte durável — e o INDEX é espelho. Ver LRN-012.

**Política**: aplicação **on-demand**, quando você decide mexer no slug. Não migramos preventivamente.

**Mudanças em slug migrado**: como não há SPEC anterior, qualquer mudança via `/keelson:change` gera **nova SPEC** (sem supersede). Construímos o histórico keelson daquele slug a partir do ponto da migração.

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

**Aplicação**: passo de resolução de slug do `/keelson:specify` e triagem do `/keelson:change`. Reforça a regra de ouro #6 e a decisão 4.5 (migração de legado).

**Garantia**: instrução explícita nos dois comandos, com o contraste "faceta de um domínio existente" vs "slug paralelo novo". Não há hook determinístico; a robustez vem do passo **obrigatório** de detecção de slug de domínio antes de criar qualquer slug novo.

### 4.10 Modo de execução padrão: ciclo autônomo (full-auto)

**Decisão**: o **modo padrão** de atender um pedido de mudança não-trivial é o **autônomo** (`/keelson:auto`): o agente conduz `specify → plan → tasks → implement → entrega` de ponta a ponta **sem aprovação humana de rotina entre etapas**, parando apenas nas exceções. O fluxo pausado (aprovar etapa a etapa) passa a ser **opt-in** via `/keelson:guiado`. O usuário não precisa digitar o comando — basta pedir a tarefa em linguagem natural; o bloco keelson do `CLAUDE.md` declara isso como default.

**Por quê**: reduzir atrito. Analogia do solicitante: "a área de negócio pede e depois vem ver o resultado." Pedir aprovação a cada etapa é caro quando a demanda é clara.

**Fronteira de disparo**:
- Pergunta / análise / leitura de código → resposta normal, **sem** keelson.
- Pedido de modificar/editar/implementar não-trivial → modo autônomo.
- Trivial (typo, copy, cor) → direto, sem keelson.

**Delegação consciente (reinterpreta a regra de ouro #3 / decisão 4.2)**: no modo autônomo, a **promoção de Status** (`Draft → Approved → Done`) é **delegada ao agente** para aquele ciclo. Continua valendo a invariante de que o INDEX é gerado (não editado à mão); o que muda é que o "Approved/Done" deixa de exigir clique humano por etapa quando o usuário optou pelo modo autônomo (o default). No `/keelson:guiado`, a promoção volta a depender do OK humano nos checkpoints.

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

**O que não muda**: rigor e gates (decisão 4.10), gate de segurança com rejeição imediata, merge/deploy humanos (4.8), e o `/keelson:guiado` — que mantém a régua estrita por ser o modo opt-in de acompanhamento.

**Aplicação**: `commands/auto.md` (fonte de verdade) e o bloco keelson do `CLAUDE.md` (rede de proteção). Recalibra a "Rede de proteção" da decisão 4.10.

### 4.12 Rota inline: prova externa falsificável (gerador ≠ avaliador)

**Decisão (do humano)**: na rota inline (bug/refactor pequeno), a auto-revisão pelos gates **não é prova de pronto**. A prova é **externa e falsificável** — teste cobrindo o comportamento. Mudança qualitativa sem teste possível (ex.: refactor de legibilidade) → 1 passada de revisão independente com contexto limpo (ex.: `/code-review` em effort baixo) em vez do auto-checklist.

**Por quê**: autoavaliação infla o resultado (gerador = avaliador na mesma sessão); os gates de julgamento (escopo, aderência, review qualitativo) auto-aplicados eram o ponto fraco da rota barata. Os gates de teste já eram avaliador independente por natureza — a decisão explicita que **eles** são a prova, e cobre o caso sem teste possível. Não reintroduz subagent obrigatório na rota inline (Calibração de Esforço preservada).

**Origem**: confronto do fluxo com material externo sobre trabalho orientado a objetivos (separação gerador/avaliador). No mesmo pacote, dois ajustes de processo registrados no ledger: calibração por exemplares nos avaliadores qualitativos (LRN-010) e não-vinculância da "Implementação sugerida" nas TASKs (LRN-011).

**Aplicação**: bloco keelson do `CLAUDE.md` (Execução de Código) e o QUALITY-CHARTER (régua "gerador ≠ avaliador").

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

### 6.1 Modo AGENT_TEAMS (preferido)

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` habilitado
- Teammates independentes, peer-to-peer
- Worktrees por task, branches separadas
- Custo: 3-5x tokens, ganho: até 2x mais rápido

### 6.2 Modo SUBAGENTS (fallback)

- Subagents na mesma sessão, sem peer-to-peer
- Branch única por wave
- Custo: 1.5-2x tokens
- Coordenação via main session
- Usa `task-implementer` e `task-reviewer` por referência

### 6.3 Modo SINGLE_THREAD (último recurso)

- Tudo sequencial
- Sem paralelismo
- Closure obrigatória do mesmo jeito

---

## 7. Roteamento de mudanças

Quando aparece uma demanda nova, usar `/keelson:change` (triagem) ou decidir manualmente:

| Tipo de mudança | Artefato |
|---|---|
| Contrato muda (FR, AC, escopo) | Nova SPEC via `/keelson:specify` |
| Estratégia técnica nova, contrato igual | Novo PLAN da mesma SPEC via `/keelson:plan` |
| Bug (implementação ≠ AC) | TASK do tipo bugfix |
| Refactor sem mudança de comportamento | TASK do tipo refactor |
| Trivial (typo, copy, cor) | Direto no código |
| Mexer em slug legado pela primeira vez | `/keelson:migrate-legacy` antes, depois `/keelson:change` |

---

## 8. Decisões em aberto (por resolver)

- Variantes `/keelson:specify-small` e `/keelson:specify-epic` para tarefas micro e roadmap.
- Hook de pre-commit bloqueando merge sem closure.
- Convenção de UX-FRs (como escrever requisito de comportamento de interface em EARS).
- Como integrar com ferramentas de wireframe externas referenciadas pelo PLAN.
- Skill validadora do próprio bloco keelson do `CLAUDE.md`.
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
