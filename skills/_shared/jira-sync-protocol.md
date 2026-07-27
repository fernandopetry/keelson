# Protocolo de sincronização com Jira (opcional — conector MCP Atlassian)

> Fonte única da lógica de sync keelson↔Jira — os comandos apontam para cá ("§N"), não
> duplicam a lógica. Ativado só quando a ficha declara `jira.enabled: true`. 3º nível
> (FEAT/Stories): `jira-sync-feat.md`, mesma pasta.

## §0. Quando roda + degradação graciosa (best-effort inviolável)

- **Gatilho**: `jira.enabled == true` na ficha (`keelson.config.json`). Bloco ausente ou
  `enabled: false` → o protocolo **não faz nada** e o comando segue idêntico ao de hoje.
- **Nunca bloqueia**: ferramentas do conector Atlassian indisponíveis (não autorizado,
  ambiente headless) **ou** qualquer chamada MCP que falhe (permissão, campo obrigatório,
  transição inexistente) → **avisa em 1 linha no output e segue**. O ciclo SDD nunca trava
  por causa do Jira.
- **Zero segredo**: o conector é o único canal; **nunca** peça/leia token ou credencial, e
  nada de Jira vai para `keelson.local.json`.
- **Público/agnóstico**: nenhum ID, nome, site ou componente real entra em artefato do
  plugin — tudo vem da ficha e do mapa do projeto (consumidor), resolvido em runtime.

## §1. Ferramentas do conector e resolução de `cloudId`

Ferramentas MCP usadas (todas do conector Atlassian): `getAccessibleAtlassianResources`,
`getVisibleJiraProjects`, `getJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields`,
`searchJiraIssuesUsingJql`, `getTransitionsForJiraIssue`, `getJiraIssue`, `createJiraIssue`,
`editJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`, `createIssueLink`.

`cloudId`: usar `jira.cloudId` se presente; senão passar `jira.site` (hostname) direto às
ferramentas; se ainda falhar, `getAccessibleAtlassianResources` e usar o recurso do site.
**Operar sempre por ID** (issue type, status, transição, campo) — nomes são localizados e
variam por projeto.

## §2. Config lida da ficha (bloco `jira`)

| Campo | Uso |
|---|---|
| `enabled` | liga/desliga o protocolo |
| `site` / `cloudId` | resolução do site (§1) |
| `projectKey` | projeto-alvo das criações |
| `mode` | `create` (cria hierarquia) \| `link` (pendura em issue existente) — §5 |
| `issueType.spec` / `issueType.feature` / `issueType.task` / `issueType.standalone` | **IDs** do tipo da issue da SPEC, da Story de funcionalidade (opcional — `null` desliga o 3º nível, §6.1), da sub-task da TASK, e do tipo **nível 0** da tarefa isolada (opcional — `null` = tasks isoladas não sincronizam, §7) |
| `transition` | `off` \| `comment` (default) \| `auto` — §9 |
| `mapFile` | caminho do mapa `.md` do projeto (§3); `null` → só `summary`+`description`, sem mover card |
| `boardId` | opcional, só para compor link "ver no board" em comentário |

## §3. Mapa do projeto (`mapFile`) — duas seções

Arquivo `.md` **no repo do consumidor** (não no plugin), gerado pelo `/keelson:init` e
editado pelo humano. Ausente → o protocolo usa só `summary`+`description` e não move card.

- **Seção "Campos"** — tabela `ID | Nome | Tipo | Direção | Estratégia | Valor`:
  - `Direção`: `write` (enriquece a issue) · `read` (semeia SPEC/TASK, modo `link`) · `both`.
  - `Estratégia` (write): `fixed` (valor/ID constante em `Valor`) · `from` (fonte SDD em
    `Valor`, ex.: ACs da SPEC, resumo, `pr.url`) · vazio = ignorar.
  - Campos `option`/`array` guardam o **ID** da opção em `Valor`, nunca o texto.
- **Seção "Etapas/Colunas"** — tabela `Etapa | Coluna | Status-alvo (ID) | Gatilho`: mapeia
  cada marco do ciclo a um status-alvo (§9). `Coluna` é só rótulo legível. Com o 3º nível
  ativo (§6.1), a tabela pode declarar a linha
  `Funcionalidade pronta p/ QA | <coluna> | <status-id> | todas as TASKs da FEAT Done` —
  status-alvo aplicado **na Story** da FEAT; ausente → o marco vira comentário.

## §4. Idempotência (obrigatória)

Antes de **criar** qualquer issue, checar a key já persistida (§10) — **os artefatos SDD não
usam YAML front-matter**; as keys moram em linhas `**Jira**:` do corpo markdown. Receita de
localização (não invente parser de front-matter):

```bash
grep -n '^\*\*Jira\*\*:' <SPEC>          # issue principal (cabeçalho, ao lado de **Slug**)
grep -n -A2 '^### FEAT-' <SPEC>          # Story da FEAT (§6.1) — a linha vem sob o heading
grep -n 'Jira' <TASK>                    # sub-task — bloco "Histórico de execução" da closure
```

Se a key existe e resolve (`getJiraIssue` ok) → **atualizar/no-op**, nunca recriar.

**Sondagem anti-duplicata** (recomendada antes de criar em lote; **obrigatória** no
`--dry-run` do §12): a idempotência por key local não cobre o caso de um sync que criou a
issue no Jira e falhou ao gravar a key (§0 — best-effort). Antes de criar N issues de um
slug sem nenhuma key, rodar `searchJiraIssuesUsingJql` no `projectKey` procurando issues cujo
`summary` corresponda aos títulos das SPECs/TASKs do slug. Correspondência plausível →
**reportar como possível duplicata e não criar** (no modo `link`, o humano informa a key);
nenhuma correspondência → seguir com a criação.

**Nunca re-parentar**: sub-tasks criadas no modo 2 níveis antes da adoção do 3º nível
permanecem sob a issue da SPEC — mover parent de sub-task não é suportado com segurança; o
estado misto é **reportado**, não corrigido.

## §5. Modos `create` e `link`

- **`create`**: se a SPEC não tem key (§10), **cria** a issue principal (§6) e grava a key;
  cada TASK vira sub-task (§7).
- **`link`**: **não cria** a issue principal — exige que o **cabeçalho da SPEC** já traga uma
  key (linha `**Jira**: <KEY>`, preenchida pelo humano). Valida com `getJiraIssue`; pendura
  sub-tasks e comentários nela. Sem key no modo `link` → avisa e pula (não inventa issue).

## §6. Criar/vincular a issue da SPEC

0. **Pré-check de viabilidade da projeção (§7)** — antes de criar a issue principal, resolver
se as TASKs deste slug terão onde aninhar. Inviável → criar a issue da SPEC **assim mesmo**
só quando a projeção degradada do §7 for possível; senão avisar e **não criar** (issue-mãe
órfã sem filhos possíveis é meio-estado ruim, não progresso).
1. Idempotência (§4). 2. `create` + sem key → `createJiraIssue` (projectKey, `issueType.spec`,
`summary` = título da SPEC, `description` = resumo/outcome), aplicar campos `write` (§8),
gravar a key na linha `**Jira**:` do cabeçalho (§10). 3. `link` → validar a key existente e
aplicar campos `write`/`read` conforme o mapa. PLAN **não** vira issue (fica implícito na
descrição).

## §6.1. Stories das funcionalidades (FEAT) — 3º nível opcional

3º nível ativo — SPEC declara FEATs (headings `### FEAT-` na §5) ∧ `issueType.feature`
preenchido → leia `${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md`; qualquer um
ausente → no-op (projeção em 2 níveis).

## §7. Criar sub-tasks das TASKs

### §7.0 Pré-check de hierarquia (dono único da régua de adjacência)

**Antes de criar qualquer coisa** (vale para 2 e 3 níveis; o `jira-sync-feat.md` referencia
esta régua, não a duplica): via `getJiraProjectIssueTypesMetadata`, ler `hierarchyLevel` e
`subtask` dos tipos configurados. O Jira só aninha pai→filho entre níveis **estritamente
descendentes e adjacentes** (pai exatamente um nível acima). Combinações reais:

| `spec` | `feature` | `task` | Projeção |
|---|---|---|---|
| epic(1) | story(0) | subtask(-1) | **3 níveis pleno** — `jira-sync-feat.md` |
| nível 0 | — | subtask(-1) | **2 níveis válido** — sub-task sob a issue da SPEC |
| epic(1) | — (ou SPEC sem FEAT) | subtask(-1) | **2 níveis INVÁLIDO** — falta o nível 0; degradar (abaixo) |
| qualquer | — | não-subtask | 2 níveis por link — fallback de `subtask:false` (abaixo) |

**Perna inválida → nunca tentar o `parent` e falhar issue a issue.** Resolver a projeção
**uma vez**, no início, e reportar em 1 linha qual perna não aninha, com o tipo correto do
próprio projeto (ex.: "Subtarefa(-1) não cabe sob Epic(1) — falta o nível 0").

**Degradação em 2 níveis** (`spec` epic-level ∧ `task` subtask, sem FEAT — o caso "Epic ▸
Subtarefa"), na ordem: (i) `issueType.standalone` preenchido e adjacente ao `spec`
(Epic(1) ▸ Tarefa(0)) → as TASKs projetam como **isoladas** sob o Epic, cada uma sendo sua
própria unidade de QA (§9); (ii) sem `standalone` → issue de `issueType.task` **sem parent**
não é possível (sub-task exige pai) → **não criar**, avisar que o slug precisa declarar FEATs
(3º nível) ou reconfigurar `issueType`. Nunca criar sub-task órfã nem sob nível não-adjacente.

### §7.1 Criação

Para cada TASK sem key, respeitada a projeção resolvida no §7.0: `createJiraIssue` com
`issueType.task` e `parent` = key da issue da SPEC; `summary` = título da TASK; aplicar campos
`write`. Gravar a key na closure (§10). **Robustez**: se `issueType.task` não for
`subtask:true` no projeto, fazer fallback para issue normal + `createIssueLink` ("relates to")
em vez de sub-task. **Com §6.1 ativo**: parenting na Story da FEAT primária — ver
`jira-sync-feat.md`.

**Tarefa isolada (`issueType.standalone`)** — o card de QA fora do aninhamento; `null` →
tasks isoladas não sincronizam (nem avisa). Origem avulsa (abaixo); origem transversal —
ver `jira-sync-feat.md`.
- **TASK avulsa** (roteada pelo `/keelson:triage` direto para TASK — bugfix/chore/ops, sem
  SPEC/FEAT): issue de `issueType.standalone` com `parent` = issue-SPEC do slug **quando
  adjacente** (Epic(1) ▸ nível 0 — mesma regra da degradação do §7.0); sem issue-SPEC ou sem
  adjacência → **sem `parent`** + `createIssueLink` "relates to" com ela, se existir. Criada
  pelo gancho do comando que gera/executa a TASK (closure do `/keelson:implement` quando não
  há key) ou pela reconciliação (§12).
Key persistida na closure da TASK (§10), como qualquer sub-task.

## §8. Campos personalizados (§3, seção Campos)

- **Escrita** (`write`/`both`): montar `additional_fields`/`fields` a partir das linhas com
  `Estratégia` resolvida — `fixed` usa o valor/ID literal; `from` deriva da fonte SDD. Campo
  rejeitado pelo Jira → **pula esse campo e avisa**, não aborta a criação (§0).
- **Leitura** (`read`/`both`, modo `link`): `getJiraIssue` com `fields` das linhas `read`;
  injetar o conteúdo como **semente/sugestão** no ponto do SDD (ex.: campo de critérios de
  aceite → rascunho de ACs). **Nunca** sobrescreve o artefato — semeia para curadoria humana.

## §9. Progresso na closure (comentar × transicionar)

Conforme `jira.transition`:
- **`off`** → nada.
- **`comment`** (default) → `addCommentToJiraIssue` na sub-task/issue com o marco (etapa +
  rótulo de coluna do mapa, se houver). **Não move o card.**
- **`auto`** → resolver o status-alvo da etapa na seção Etapas/Colunas (§3); chamar
  `getTransitionsForJiraIssue` e escolher a transição disponível cujo destino é o alvo,
  respeitando `isAvailable` e evitando `hasScreen`/`isConditional` quando não há como
  satisfazê-las; aplicar via `transitionJiraIssue`. **Sem caminho seguro → cai para comentar**
  (não força, não erra). O mapa é intenção; a transição real é sempre validada em runtime.

O marco de closure atua na **sub-task**; o marco de funcionalidade pronta na Story —
`jira-sync-feat.md`, quando ativo. **Tarefa isolada** (§7) é a própria unidade de QA: na closure
`Done`, além do marco normal, aplicar o marco "pronta p/ QA" (gatilho do mapa / política de
`transition`) **na própria issue** — equivalente ao que a Story recebe quando a FEAT completa.

## §10. Persistência das keys

- **SPEC** → linha `**Jira**: <KEY>` no **cabeçalho markdown** da SPEC, ao lado de `**Slug**`/
  `**Status**` (a SPEC **não** tem YAML front-matter; linha ausente = ainda não sincronizada).
- **FEAT** → linha `**Jira**: <KEY>` imediatamente sob o heading `### FEAT-NNN-XXX` na SPEC
  (ausente = Story ainda não sincronizada).
- **TASK** → campo `Jira: <KEY>` no bloco "Histórico de execução" da closure, ao lado de
  `Commit SHA`.
- **INDEX** → apenas 1 linha no "Histórico recente" (`issues Jira: <KEY> + N sub-tasks`); o
  contrato da tabela "PLANs" (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`)
  **não** muda.

## §11. Link do PR / push (integrate, auto)

Após o PR aberto (`/keelson:integrate`) ou o push (`/keelson:auto`): `addCommentToJiraIssue`
na issue principal com a URL do PR/branch (e, quando útil, `createIssueLink`/remote link).
Best-effort (§0).

## §12. Reconciliação (`/keelson:jira-sync`)

Reprocessa um slug de forma idempotente (§4), na ordem: issue da SPEC (§6) → Stories das
FEATs (`jira-sync-feat.md`, quando ativo) → sub-tasks (§7) → status (§9, incluindo o
gatilho "Funcionalidade pronta p/ QA" para FEATs já completas). Aplica campos e — se
`transition:auto` — alinha o status ao estado real das TASKs (Done → status-alvo de
"concluída"). Estado misto (sub-tasks legadas sob a issue da SPEC com o 3º nível ativo) é
**reportado no output**, nunca re-parentado (§4).
