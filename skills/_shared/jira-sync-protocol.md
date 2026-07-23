# Protocolo de sincronização com Jira (opcional — conector MCP Atlassian)

> Fonte única da lógica de sync keelson↔Jira. Os comandos do ciclo (`/keelson:specify`,
> `:tasks`, `:implement`, `:integrate`, `:auto`) e o `/keelson:jira-sync` apontam para cá
> ("protocolo de sync Jira, §N") — **não** duplicam a lógica. Ativado só quando a ficha
> declara `jira.enabled: true`. Governança: decisão 4.22 de `decisions.md`.

## §0. Quando roda + degradação graciosa (best-effort inviolável)

- **Gatilho**: `jira.enabled == true` na ficha (`keelson.config.json`). Bloco ausente ou
  `enabled: false` → o protocolo **não faz nada** e o comando segue idêntico ao de hoje.
- **Nunca bloqueia**: ferramentas do conector Atlassian indisponíveis (não autorizado,
  ambiente headless) **ou** qualquer chamada MCP que falhe (permissão, campo obrigatório,
  transição inexistente) → **avisa em 1 linha no output e segue**. Mesma filosofia do
  fallback gracioso dos hooks (`sem jq → exit 0`). O ciclo SDD nunca trava por causa do Jira.
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
| `issueType.spec` / `issueType.task` | **IDs** do tipo da issue da SPEC e da sub-task da TASK |
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
  cada marco do ciclo a um status-alvo (§9). `Coluna` é só rótulo legível.

## §4. Idempotência (obrigatória)

Antes de **criar** qualquer issue, checar a key já persistida (§10): front-matter da SPEC
para a issue principal; bloco de closure da TASK para a sub-task. Se a key existe e resolve
(`getJiraIssue` ok) → **atualizar/no-op**, nunca recriar. Garante que re-runs (`tasks` duas
vezes, reconciliação) não duplicam issues.

## §5. Modos `create` e `link`

- **`create`**: se a SPEC não tem key (§10), **cria** a issue principal (§6) e grava a key;
  cada TASK vira sub-task (§7).
- **`link`**: **não cria** a issue principal — exige que o front-matter da SPEC já traga uma
  key (`Jira: <KEY>`, preenchida pelo humano). Valida com `getJiraIssue`; pendura sub-tasks
  e comentários nela. Sem key no modo `link` → avisa e pula (não inventa issue).

## §6. Criar/vincular a issue da SPEC

1. Idempotência (§4). 2. `create` + sem key → `createJiraIssue` (projectKey, `issueType.spec`,
`summary` = título da SPEC, `description` = resumo/outcome), aplicar campos `write` (§8),
gravar a key no front-matter (§10). 3. `link` → validar a key existente e aplicar campos
`write`/`read` conforme o mapa. PLAN **não** vira issue (fica implícito na descrição).

## §7. Criar sub-tasks das TASKs

Para cada TASK sem key: `createJiraIssue` com `issueType.task` e `parent` = key da issue da
SPEC; `summary` = título da TASK; aplicar campos `write`. Gravar a key na closure (§10).
**Robustez**: se `issueType.task` não for `subtask:true` no projeto (checar via
`getJiraProjectIssueTypesMetadata`), fazer fallback para issue normal + `createIssueLink`
("relates to") em vez de sub-task.

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

## §10. Persistência das keys

- **SPEC** → campo `Jira: <KEY>` no front-matter (`null`/ausente = ainda não sincronizada).
- **TASK** → campo `Jira: <KEY>` no bloco "Histórico de execução" da closure, ao lado de
  `Commit SHA`.
- **INDEX** → apenas 1 linha no "Histórico recente" (`issues Jira: <KEY> + N sub-tasks`); o
  contrato da tabela "PLANs" (method-guide §6) **não** muda.

## §11. Link do PR / push (integrate, auto)

Após o PR aberto (`/keelson:integrate`) ou o push (`/keelson:auto`): `addCommentToJiraIssue`
na issue principal com a URL do PR/branch (e, quando útil, `createIssueLink`/remote link).
Best-effort (§0).

## §12. Reconciliação (`/keelson:jira-sync`)

Reprocessa um slug de forma idempotente (§4): cria/vincula a issue da SPEC e as sub-tasks
faltantes, aplica campos, e — se `transition:auto` — alinha o status ao estado real das
TASKs (Done → status-alvo de "concluída"). É a rede de segurança do best-effort para o que
uma execução anterior pulou (conector offline, transição barrada).
