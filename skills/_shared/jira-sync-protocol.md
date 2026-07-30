# Protocolo de sincronização com Jira (opcional — conector MCP Atlassian)

> Fonte única da lógica de sync keelson↔Jira — os comandos apontam para cá ("§N"), não
> duplicam a lógica. Ativado só quando a ficha declara `jira.enabled: true`. 3º nível
> (FEAT/Stories): `jira-sync-feat.md`, mesma pasta.

## §0. Quando roda + degradação graciosa (best-effort inviolável)

- **Gatilho**: `jira.enabled == true` na ficha (`keelson.config.json`). Bloco ausente ou
  `enabled: false` → o protocolo **não faz nada** e o comando segue idêntico ao de hoje.
- **Nunca bloqueia**: ferramentas do conector Atlassian indisponíveis (não autorizado,
  ambiente headless) **ou** qualquer chamada MCP que falhe (permissão, campo obrigatório,
  transição inexistente) → **avisa e segue** (com o rastro abaixo). O ciclo SDD nunca trava
  por causa do Jira.
- **Indisponibilidade é provada, não presumida** (mesma régua da verificação de tela,
  decisão 4.26). Antes de concluir que o conector não está disponível: **carregue as
  ferramentas** — num harness que as entrega *deferred*, elas não aparecem na lista até serem
  buscadas, e "não vi as ferramentas" **não é evidência** — e faça **uma** chamada barata de
  prova (`atlassianUserInfo`, ou `getAccessibleAtlassianResources`). Só o retorno dessa
  tentativa autoriza a conclusão; o resultado vale para a execução inteira (não repita a
  prova a cada gancho).
- **Rastro durável do pulo**: sync pulado ou falho **não** pode viver só no output da sessão —
  num ciclo longo isso é indistinguível de nunca ter acontecido, e some quando a sessão fecha.
  Registre **1 linha no "Histórico recente" do `INDEX.md` do slug** (§10): data, o que seria
  sincronizado, o motivo e **a evidência da prova** (o que foi tentado e o que retornou). Ex.:
  `2026-07-26: sync Jira pulado (SPEC-005 + 8 TASKs) — atlassianUserInfo: not authorized`.
  Sem slug resolvido, a linha vai no relatório final do comando. É esse rastro que responde,
  semanas depois, "por que o Jira não recebeu nada?".
- **Zero segredo**: o conector é o único canal; **nunca** peça/leia token ou credencial, e
  nada de Jira vai para `keelson.local.json`.
- **§9 é pré-requisito de qualquer movimento de card**: os comandos leem este protocolo por
  §§ (leitura seletiva por offset), e é fácil executar um passo que move card sem ter lido a
  seção que governa **até onde** ele pode ir — foi assim que uma Story foi parar em concluído
  (4.65). Regra: **nenhuma transição sem o §9 lido nesta execução**; o § que você veio buscar
  (§7, §12, §13, `jira-sync-feat.md`) não substitui o §9, ele o pressupõe. Só comentar
  (`transition: comment`) dispensa.
- **Público/agnóstico**: nenhum ID, nome, site ou componente real entra em artefato do
  plugin — tudo vem da ficha e do mapa do projeto (consumidor), resolvido em runtime.

## §1. Ferramentas do conector e resolução de `cloudId`

Ferramentas MCP usadas (todas do conector Atlassian): `atlassianUserInfo` (prova de
disponibilidade, §0), `getAccessibleAtlassianResources`, `getVisibleJiraProjects`,
`getJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields`,
`searchJiraIssuesUsingJql`, `getTransitionsForJiraIssue`, `getJiraIssue`, `createJiraIssue`,
`editJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`, `createIssueLink`.
Nomes de servidor variam por instalação (`mcp__<servidor>__<ferramenta>`) — resolva pelo
**sufixo** da ferramenta, nunca por um prefixo fixo.

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
| `epicPolicy` | `always` (default — SPEC → Epic sempre) \| `multi-feature` (0–1 FEAT → projeção **compacta**, sem Epic — §7.0) |
| `transition` | `off` \| `comment` (default) \| `auto` — §9 |
| `mapFile` | caminho do mapa `.md` do projeto (§3); `null` → só `summary`+`description`, sem mover card |
| `boardId` | opcional, só para compor link "ver no board" em comentário |

## §3. Mapa do projeto (`mapFile`) — três seções

Arquivo `.md` **no repo do consumidor** (não no plugin), gerado pelo `/keelson:init` e
editado pelo humano. Ausente → o protocolo usa só `summary`+`description` e não move card.

- **Seção "Campos"** — tabela `ID | Nome | Tipo | Direção | Estratégia | Valor`:
  - `Direção`: `write` (enriquece a issue) · `read` (semeia SPEC/TASK, modo `link`) · `both`.
  - `Estratégia` (write): `fixed` (valor/ID constante em `Valor`) · `from` (fonte SDD em
    `Valor`, ex.: ACs da SPEC, resumo, `pr.url`) · vazio = ignorar.
  - Campos `option`/`array` guardam o **ID** da opção em `Valor`, nunca o texto.
- **Seção "Etapas/Colunas"** — tabela `Etapa | Nível | Coluna | Status-alvo (ID) | Gatilho`:
  mapeia cada marco do ciclo — e cada fase (§13) — a um status-alvo (§9). `Coluna` é só rótulo
  legível. `Nível` ∈ `epic` | `story` | `subtask` (`story` cobre Story de FEAT, Story implícita
  e tarefa isolada) e diz **em qual issue da árvore** o alvo atua; nas linhas de **fase**
  (`Gatilho` = `--phase <verbo>`, §13) a coluna é obrigatória — linha ausente para um nível =
  aquele nível não se move (opt-out declarado). Mapa legado sem a coluna → os marcos do ciclo
  seguem valendo (o nível deles já era implícito no gatilho). A **ordem das linhas** (de cima
  para baixo) espelha a progressão do quadro — é a régua que a não-regressão do §9 usa quando
  o nível não tem Trilho declarado (com Trilho, vale ele). Marcos canônicos do ciclo (linha
  ausente → aquele marco degrada para comentário, sem erro):
  - `TASK iniciada | subtask | <coluna> | <status-id> | despacho da TASK ao developer` —
    alvo aplicado à **sub-task/isolada** (§9);
  - `TASK concluída | subtask | <coluna> | <status-id> | closure da TASK (Done)` — alvo
    aplicado à **sub-task/isolada**;
  - `Trabalho iniciado (Story) | story | <coluna> | <status-id> | primeira TASK da Story
    despachada` — alvo aplicado à **Story** (de FEAT ou implícita); é também o **teto de
    transição automática da unidade de QA** (§9);
  - `Funcionalidade pronta p/ QA | story | <coluna> | <status-id> | todas as TASKs da FEAT
    Done` (com o 3º nível ativo, §6.1; Story implícita/isolada: mesma semântica com a
    SPEC/TASK no lugar da FEAT) — marco informado **na Story**; por ficar tipicamente além
    do teto, na prática vira comentário (§9).

  **O catálogo de gatilhos é fechado**: as únicas linhas que o sync **executa** são os quatro
  marcos canônicos acima e as linhas de fase (§13). O mapa é editado por humano e acumula o
  fluxo real do time em prosa — linha com outro nome ou outro gatilho (ex.:
  `Concluída | História | Feito | … | QA valida a funcionalidade / PR aberto`) é
  **documentação do fluxo humano, nunca gatilho de sync**: não dispara, não se "considera
  satisfeita", não move card — e entra em 1 linha de aviso do output (`marcos não-canônicos
  no mapa: N — documentação, não executados`). Teste falsificável: *linha cujo gatilho o
  keelson não dispara por si — um ato de pessoa, um evento do quadro — não move card nenhum.*
  Rótulo próprio é permitido, **equivalência não é inferida**: linha com nome local (`Pronto
  p/ QA`) só conta como o marco canônico se o mapa **declarar** a equivalência em texto; sem
  declaração, é documentação. Renomear não cria marco novo — o catálogo é o do protocolo.
  **Nenhum gate, agente ou etapa do ciclo satisfaz gatilho que nomeia ato humano**: gate 9/QA,
  aceitação do PO, code review, push e entrega são atos do time simulado, não do Diretor — quem
  satisfaz "QA validou", "PR aberto", "aprovado" é ele, movendo o card ou ordenando `--phase`
  (§13). Confundir o QA do keelson com o QA humano do quadro é o erro concreto que fechou uma
  Story indevidamente (4.65).
- **Seção "Trilho do board"** (opcional; exigida pelo walker multi-hop do §9) — por nível, a
  lista **ordenada** de status-IDs das colunas do quadro, do início ao fim do fluxo (ex.:
  `story: 1 → 11606 → 10599 → … → 10001`). Workflows diferem por tipo — um trilho por nível,
  só dos níveis que se movem. É declaração do humano (o `/keelson:init` semeia pela amostragem
  do workflow); board reordenado sem atualizar o trilho → o walker para num salto bloqueado e
  reporta (§9), nunca erra em silêncio. Seção ausente → só transição direta (sem walk).

**A ficha é a fonte da política.** Prosa ou cabeçalho do mapa que afirmar o contrário da
ficha (ex.: o mapa diz em texto corrido "a ficha usa `transition: comment`" e a ficha declara
`auto`) → **aviso de mapa desatualizado, e a ficha vale** — o comportamento nunca pode depender
de qual dos dois arquivos o agente leu. A comparação é barata e acontece onde os dois já são
lidos juntos: qualquer gancho que abre o mapa, e o self-check do `/keelson:init`.

## §4. Idempotência (obrigatória)

Antes de **criar** qualquer issue, checar a key já persistida (§10) — **os artefatos SDD não
usam YAML front-matter**; as keys moram em linhas `**Jira**:` do corpo markdown. Receita de
localização (não invente parser de front-matter):

```bash
grep -n '^\*\*Jira\*\*:' <SPEC>          # issue principal (cabeçalho, ao lado de **Slug**)
grep -n '^\*\*Jira Story\*\*:' <SPEC>    # Story implícita (§7.0 degrau (0))
grep -n -A2 '^### FEAT-' <SPEC>          # Story da FEAT (§6.1) — a linha vem sob o heading
grep -n 'Jira' <TASK>                    # sub-task — bloco "Histórico de execução" da closure
```

**Conjunto de TASKs a sincronizar** = os **arquivos** `<slug>/tasks/TASK-*.md` **menos** os
`*-INDEX.md` (`ls tasks/TASK-*.md | grep -v INDEX`) — um glob ingênuo conta cada `TASK-NNN-INDEX`
como se fosse tarefa e infla o plano. O `TASK-NNN-INDEX` é **panorama, não fonte de verdade**:
divergência entre a contagem dele e os arquivos (tasks acrescentadas depois da geração) vira
**aviso no output**, e o sync segue pelos arquivos.

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
órfã sem filhos possíveis é meio-estado ruim, não progresso). **Projeção compacta**
(`epicPolicy: multi-feature` ∧ 0–1 FEAT — §7.0) → a issue da SPEC **não é criada**: a raiz
da árvore é a Story única, e este § inteiro é no-op para a SPEC.
1. Idempotência (§4). 2. `create` + sem key → `createJiraIssue` (projectKey, `issueType.spec`,
`summary` = título da SPEC, `description` = template **Epic** da receita §6.2), aplicar campos `write` (§8),
gravar a key na linha `**Jira**:` do cabeçalho (§10). 3. `link` → validar a key existente e
aplicar campos `write`/`read` conforme o mapa. PLAN **não** vira issue (fica implícito na
descrição).

## §6.1. Stories das funcionalidades (FEAT) — 3º nível opcional

3º nível ativo — SPEC declara FEATs (headings `### FEAT-` na §5) ∧ `issueType.feature`
preenchido → leia `${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md`; qualquer um
ausente → no-op (projeção em 2 níveis). **SPEC sem FEAT mas com `issueType.feature`
preenchido**: não é no-op puro — vale o degrau (0) do §7.0 (Story implícita espelhando a
SPEC), que preserva a Story como unidade de QA sem ativar este arquivo.

## §6.2. Descrição para humanos (receita única de renderização)

Toda issue criada pelo protocolo carrega uma `description` escrita **para o humano que vai
lê-la no Jira** — em especial o analista de QA que testa a funcionalidade a partir do card
(§9: Story/isolada é a unidade de QA). **Português**, markdown simples (headings/listas —
o conector converte). Teste falsificável da receita: *um humano que só lê o card entende o
que foi feito e consegue testá-lo sem abrir nenhum arquivo do repo*. Âncora de contenção: a
descrição **projeta** o artefato SDD — muda a forma (jargão EARS/Given-When-Then vira
linguagem de usuário), **nunca acrescenta afirmação que o artefato não sustenta** (mesma
régua da 4.58: verificado, não deduzido).

**Cabeçalho-aviso** (obrigatório, primeira linha de toda descrição gerada):
`⚙️ *Texto gerado automaticamente pelo keelson — não edite: será re-renderizado na próxima
sincronização. Ajustes, dúvidas e resultados de teste: registre um comentário.*`
Comentários são o canal do humano — o sync nunca os toca (só adiciona, §9/§11), então
sobrevivem a qualquer re-render. O aviso protege o distraído; a válvula deliberada de quem
**quer** ser dono do texto continua sendo apagar o rodapé-marcador (abaixo).

Templates por papel da issue (todos os tipos nivelados — nenhuma issue nasce só com título):

- **Epic (issue da SPEC)** — o card de roadmap:
  - **Contexto e objetivo** — problema + outcome esperado, em prosa (§1 da SPEC);
  - **Escopo** — in/out resumidos (§4 da SPEC);
  - **Funcionalidades** — lista das FEATs (nome + 1 linha) ou a nota de fluxo único.
- **Unidade de QA** (Story de FEAT · Story implícita · tarefa isolada) — o padrão mais
  rico, porque é o card que o QA humano testa:
  - **O que esta funcionalidade faz** — narrativa de negócio em 2–6 frases, nos termos do
    glossário da SPEC (persona, ação, resultado — não arquitetura);
  - **Como testar** — roteiro imperativo derivado dos ACs — e dos **NFRs verificáveis sem
    AC próprio** (idempotência, reversibilidade, refresh: cenários que o QA testa e que a
    fórmula por ACs deixaria fora): cada um vira um cenário com
    passos numerados (preparação ← Given · ação ← When · resultado esperado ← Then), sem
    citar o jargão. Duas regras de honestidade do roteiro: **(a)** AC sem caminho manual
    razoável (atomicidade, requisição forjada, ownership, contrato de servidor) **não vira
    passo de teatro** — agrupa-se numa linha final "Verificações cobertas por teste
    automatizado (sem passo manual)" com os IDs e o que provam; **(b)** os ACs de **NFR**
    cujos elementos pertencem à funcionalidade (tema claro/escuro, viewport, leitor de
    tela, sessão simulada) **entram no roteiro da Story correspondente** — a fórmula
    `ACs(FEAT)` cobre FRs, e os de NFR são somados pelo elemento que exercitam, senão
    ficam órfãos de card;
  - **Critérios de aceitação** — a lista formal (ID + texto), para rastreabilidade;
  - **Fora do escopo** — os out-of-scope da SPEC que um QA poderia confundir com defeito.
  - Tarefa isolada de origem avulsa (bugfix/chore sem SPEC): mesmas seções derivadas da
    própria TASK — o que muda, como verificar (do critério de verificação dela) e o escopo.
- **Sub-task (TASK)** — o card do dev: objetivo em 1–2 frases + os ACs que cobre (ID +
  1 linha cada). Curto por design; a narrativa mora na unidade de QA acima.

**Rodapé-marcador** (obrigatório, última linha de toda descrição gerada):
`— gerado pelo keelson a partir de <caminho relativo do artefato>`. O caminho é relativo à
**raiz do repo consumidor** (ex.: `docs/specs/portal-login/specs/SPEC-001.md`) — o número
do artefato se repete entre slugs; só o caminho desambigua. FEAT → caminho da SPEC +
`#FEAT-NNN-XXX`; sub-task/isolada → caminho do arquivo da TASK. É o marcador que habilita
o re-render abaixo.

**Política de re-render (idempotência de conteúdo)**: ao encontrar issue existente com key
válida (§4) — tipicamente na reconciliação (§12) — re-renderizar a descrição pelo template
atual **somente quando** ela está vazia **ou** termina com o rodapé-marcador
(`editJiraIssue`, só o campo `description`). Descrição sem marcador = editada por humano →
**nunca sobrescrever**; contar nos avisos do output. Best-effort como tudo (§0).

**Backfill de cards da receita antiga**: descrição gerada antes de o marcador existir não o
tem — a política acima a trataria como editada por humano e o card magro ficaria magro para
sempre. A saída é a flag `--refresh-descriptions` do `/keelson:jira-sync`, que força o
re-render **também** de descrição sem marcador — decisão explícita e pontual do humano, que
sabe que aqueles cards são gerados. Os ganchos automáticos do ciclo **nunca** forçam.

## §7. Criar sub-tasks das TASKs

### §7.0 Pré-check de hierarquia (dono único da régua de adjacência)

**Política de Epic (`epicPolicy`, decisão 4.61) — pré-filtro da régua.** Com
`epicPolicy: multi-feature`, contar as FEATs da SPEC (`grep -c '^### FEAT-'`): **2+** →
projeção plena (abaixo, como sempre — há o que agrupar); **0 ou 1** (o mesmo caso:
funcionalidade única) → **projeção compacta** — nenhum Epic; a raiz é a **Story única**
(a Story implícita espelhando a SPEC, ou a Story da FEAT única), criada **sem pai** com
`issueType.feature`, e as sub-tasks aninham sob ela (0 ▸ -1, o mesmo padrão da tarefa
isolada). Regras: a política é avaliada **uma vez, na primeira criação** — o registro é o
conjunto de keys persistidas (§10: `**Jira**:` presente = plena; key de Story **sem**
`**Jira**:` = compacta) e a reconciliação **respeita a projeção registrada**, nunca a
recalcula; SPEC compacta que ganha a 2ª FEAT depois **não re-parenta** (§4) — a Story nova
nasce irmã sem pai + link "relates to" com a raiz, estado misto reportado (criar Epic e
reorganizar é ato do Diretor no Jira); `issueType.feature: null` → compacta inviável,
degradar para a projeção plena/de hoje com aviso (§0). `epicPolicy` ausente/`always` → tudo
abaixo vale inalterado.

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
Subtarefa"), **nesta ordem**:

- **(0) Story implícita da SPEC** — `issueType.feature` preenchido e standard (nível 0). A
  SPEC que **não** declara FEATs é, por definição, uma funcionalidade única (a camada FEAT é
  colapsável: sem declaração, *a funcionalidade é a própria SPEC*). Então projete-a como tal:
  `createJiraIssue` com `issueType.feature`, `parent` = Epic da SPEC, `summary` = título da
  SPEC, `description` = template **unidade de QA** da receita §6.2 + a nota de que esta Story
  representa a SPEC inteira como funcionalidade única. As TASKs viram sub-tasks **sob ela** (§7.1), e ela é a unidade de
  QA do slug (§9 — marco "pronta p/ QA" quando **todas** as TASKs da SPEC estão Done).
  Idempotência pela linha `**Jira Story**:` do cabeçalho (§10). Isto **não** ativa o
  `jira-sync-feat.md`: não há FEAT declarada, há uma Story só, espelhando a SPEC.
- **(i) Tarefas isoladas** — sem `issueType.feature`, ou a Story do degrau (0) falhou:
  `issueType.standalone` preenchido e adjacente ao `spec` (Epic(1) ▸ Tarefa(0)) → as TASKs
  projetam como **isoladas** sob o Epic, cada uma sendo sua própria unidade de QA (§9). Avise
  que a granularidade de QA cai para tarefa de dev.
- **(ii) Parar** — sem `feature` nem `standalone`: issue de `issueType.task` **sem parent**
  não é possível (sub-task exige pai) → **não criar**, avisar que o slug precisa declarar FEATs
  (3º nível) ou reconfigurar `issueType`.

Nunca criar sub-task órfã nem sob nível não-adjacente. **Não recomende o degrau (0) como
substituto de declarar FEATs**: numa SPEC grande com vários fluxos, a Story implícita é um card
de QA grosso demais — reporte isso em 1 linha e siga (declarar FEATs é decisão de produto do
humano, não do sync).

### §7.1 Criação

Para cada TASK sem key: `createJiraIssue` com `issueType.task`, `summary` = título da TASK,
`description` = template **sub-task** da receita §6.2,
campos `write` aplicados, e `parent` = **o pai resolvido no §7.0** — a Story da FEAT primária
(3º nível ativo, `jira-sync-feat.md`) · a **Story implícita** da SPEC (degrau (0)) · a issue da
SPEC quando ela é nível 0 (2 níveis válido). Gravar a key na closure (§10). **Robustez**: se
`issueType.task` não for `subtask:true` no projeto, fazer fallback para issue normal +
`createIssueLink` ("relates to") em vez de sub-task.

**Tarefa isolada (`issueType.standalone`)** — o card de QA fora do aninhamento; `null` →
tasks isoladas não sincronizam (nem avisa). Origem avulsa (abaixo); origem transversal —
ver `jira-sync-feat.md`.
- **TASK avulsa** (roteada pelo `/keelson:triage` direto para TASK — bugfix/chore/ops, sem
  SPEC/FEAT): issue de `issueType.standalone` com `description` = template **unidade de QA**
  da receita §6.2 (origem avulsa) e `parent` = issue-SPEC do slug **quando
  adjacente** (Epic(1) ▸ nível 0 — mesma regra da degradação do §7.0); sem issue-SPEC ou sem
  adjacência → **sem `parent`** + `createIssueLink` "relates to" com ela, se existir. Criada
  pelo gancho do comando que gera/executa a TASK (closure do `/keelson:implement` quando não
  há key) ou pela reconciliação (§12).
Key persistida na closure da TASK (§10), como qualquer sub-task.

## §8. Campos personalizados (§3, seção Campos)

- **Pré-check de obrigatórios (antes de criar em lote)**: uma chamada
  `getJiraIssueTypeMetaWithFields` **por tipo que o plano vai usar** (spec/feature/task/
  standalone). Campo com `required: true` que **não** é coberto por `summary`/`description`/
  `parent` nem por uma linha `write` do mapa → **listar no plano/aviso antes de criar**. Um
  obrigatório faltando não é "campo pulado" (o Jira **recusa a issue inteira**), e descobrir
  isso na 40ª de 84 criações deixa o slug pela metade. Sem obrigatório descoberto → seguir sem
  ruído. Best-effort como todo o resto (§0): a chamada falhou → avisar e seguir.
- **Escrita** (`write`/`both`): montar `additional_fields`/`fields` a partir das linhas com
  `Estratégia` resolvida — `fixed` usa o valor/ID literal; `from` deriva da fonte SDD. Campo
  rejeitado pelo Jira → **pula esse campo e avisa**, não aborta a criação (§0).
- **Leitura** (`read`/`both`, modo `link`): `getJiraIssue` com `fields` das linhas `read`;
  injetar o conteúdo como **semente/sugestão** no ponto do SDD (ex.: campo de critérios de
  aceite → rascunho de ACs). **Nunca** sobrescreve o artefato — semeia para curadoria humana.

## §9. Progresso em tempo real (comentar × transicionar)

Conforme `jira.transition`:
- **`off`** → nada.
- **`comment`** (default) → `addCommentToJiraIssue` na sub-task/issue com o marco (etapa +
  rótulo de coluna do mapa, se houver). **Não move o card.**
- **`auto`** → resolver o status-alvo da etapa na seção Etapas/Colunas (§3); aplicar o
  **teto** e a **não-regressão** (abaixo); chamar
  `getTransitionsForJiraIssue` e escolher a transição disponível cujo destino é o alvo,
  respeitando `isAvailable` e evitando `hasScreen`/`isConditional` quando não há como
  satisfazê-las; aplicar via `transitionJiraIssue`. **Sem caminho seguro → cai para comentar**
  (não força, não erra). O mapa é intenção; a transição real é sempre validada em runtime.

**Walker multi-hop** (usado pelos verbos de fase do §13 e por qualquer status-alvo sem
transição direta): quando `getTransitionsForJiraIssue` não oferece transição cujo destino é o
alvo, consultar o **Trilho do board** do nível (§3). Localizar o status atual e o alvo no
trilho: atual já **no alvo ou depois** dele → no-op (**nunca regredir** — rodar de novo é
seguro); antes → avançar **um status por vez** na ordem do trilho, revalidando as transições a
cada salto (mesmas regras de `isAvailable`/`hasScreen`/`isConditional` acima). Salto sem
transição segura, ou status atual **fora do trilho** → **parar onde está**, comentar e reportar
a posição alcançada — nunca forçar. Sem seção de trilho no mapa → só o salto direto (sem
caminho → comenta, como hoje).

**Marcos automáticos do ciclo e onde atuam** (gatilhos canônicos do §3; cada um segue a
política de `transition`):

- **`TASK iniciada`** — no **despacho** da TASK ao developer (gancho da Etapa 3.2 do
  `/keelson:implement`): marco na **sub-task/isolada** do campo `Jira:` da closure. O quadro
  mostra que o trabalho começou **enquanto** ele acontece, não só depois.
- **`Trabalho iniciado (Story)`** — quando a **primeira** TASK da Story (de FEAT ou
  implícita) é despachada: marco na **Story**. TASKs seguintes da mesma Story → no-op
  (a não-regressão já resolve sem estado extra).
- **`TASK concluída`** — na closure (`Done`): marco na **sub-task/isolada**. Sub-task é card
  de dev, **sem teto**: vai até a última etapa do quadro.
- **`Funcionalidade pronta p/ QA`** — todas as TASKs da FEAT `Done` (`jira-sync-feat.md`,
  item 5, quando ativo; **Story implícita**: mesma semântica com a SPEC no lugar da FEAT;
  **tarefa isolada**: na própria issue, na closure `Done`): marco na **unidade de QA** — que,
  pelo teto abaixo, tipicamente vira **comentário**, não transição.

**Teto de transição automática da unidade de QA** — **resolva o teto como valor antes de
mover, nunca como lembrete depois**. A Story (e a tarefa isolada, que é sua própria unidade
de QA) é movida **automaticamente** no máximo até `teto = status-alvo da linha
'Trabalho iniciado (Story)'` — a coluna de desenvolvimento. Linha ausente no mapa →
**`teto` = o status atual da issue**: nenhuma transição automática, só comentário (sem coluna
de desenvolvimento declarada, mover é chute). Marco cujo alvo fica **além** do teto na régua
do nível → degrada para comentário na issue (a informação chega, o card não anda). Racional:
terminada a entrega da IA, o Diretor ainda analisa e pede ajustes — a unidade de QA fica em
desenvolvimento até **ele** movê-la; pós-desenvolvimento é ato humano, pela mesma régua que
mantém o Epic intocado (4.62).

- **Declare o teto no output**, sempre que tocar a unidade de QA:
  `Story <KEY>: teto <coluna> · alvo <coluna> → movida | comentário (alvo além do teto)`.
  Teto aplicado em silêncio é indistinguível de teto esquecido — e foi esquecido em campo
  (4.65); a linha é o que torna o esquecimento visível no relatório.
- **A régua da sub-task não se estende à Story por analogia.** "As 10 sub-tasks foram até
  Feito, conduzo a Story pela mesma cadeia" é exatamente o raciocínio que o teto existe para
  impedir: sub-task é card de dev (sem teto, vai até o fim); a unidade de QA é o card do
  Diretor. Cadeia de transições de um nível nunca é evidência sobre outro nível.
- **O teto governa só os ganchos automáticos**: o verbo de fase (§13) é ordem explícita do
  humano e pode ultrapassá-lo — `--phase finish-dev` levando a Story à revisão é exatamente o
  ato humano que o teto espera. Fora de `--phase`, **não existe caminho** que leve a unidade de
  QA além do teto: nem ciclo completo, nem todos os gates verdes, nem aceitação do PO.

**Não-regressão (pré-condição de toda transição automática — ganchos e reconciliação §12)**:
antes de transicionar, `getJiraIssue` (campo `status`) e comparar o status atual com o alvo
pela **régua do nível** — o Trilho do board (§3), quando declarado; sem trilho, a ordem das
linhas da tabela Etapas/Colunas: atual **no alvo ou além** → no-op silencioso (nunca puxar
de volta um card que o humano moveu — é a proteção contra a corrida com o quadro); atual
**fora da régua** → não transicionar (sem ordem conhecida, mover é chute) — registrar o
marco como comentário. O walker multi-hop acima já embute esta regra; ela vale **também**
no salto direto. O custo é 1 `getJiraIssue` por transição; best-effort como tudo (§0).

**Estado final do ciclo automático** (fecho do `/keelson:auto`): o fecho é, por definição do
método, um **gatilho do marco "pronta p/ QA"** — não um efeito que só emerge se todos os
ganchos anteriores tiverem rodado. Ao fim do ciclo, o estado-alvo do tracker é: **sub-tasks**
no marco de closure (`TASK concluída`) · a **unidade de QA** (Story da FEAT, Story implícita
ou tarefa isolada) **na coluna-teto de desenvolvimento, com o marco "pronta p/ QA"
comentado** — o estado de espera-do-humano, coerente com o contrato Diretor–PO (o ciclo
termina no push; revisão, merge e o avanço do card são do Diretor — tipicamente via
`--phase finish-dev`, §13) · **Epic intocado** (roadmap é do humano — a única via de movê-lo
é o verbo de fase do §13, que *é* o ato do humano, e ainda assim só com linha `epic`
declarada no mapa). A política `transition` continua valendo como em qualquer marco
(`comment` → todo estado-alvo vira comentário; `off` → nada); a reconciliação do fecho
(§12) é quem garante esse estado quando algum gancho não rodou.

## §10. Persistência das keys

- **SPEC** → linha `**Jira**: <KEY>` no **cabeçalho markdown** da SPEC, ao lado de `**Slug**`/
  `**Status**` (a SPEC **não** tem YAML front-matter; linha ausente = ainda não sincronizada).
- **FEAT** → linha `**Jira**: <KEY>` imediatamente sob o heading `### FEAT-NNN-XXX` na SPEC
  (ausente = Story ainda não sincronizada).
- **Story implícita** (degrau (0) do §7.0 — SPEC sem FEAT) → linha `**Jira Story**: <KEY>` no
  cabeçalho da SPEC, logo abaixo do `**Jira**:` do Epic. Chave distinta porque as duas issues
  coexistem e representam camadas diferentes (roadmap × unidade de QA). **Projeção compacta**
  (§7.0): a raiz usa a **mesma** linha (`**Jira Story**:`, ou a key sob o heading da FEAT
  única) e o `**Jira**:` fica **ausente por design** — a combinação de keys é o registro
  durável de qual projeção foi escolhida; não é estado inconsistente. **As duas linhas com
  a mesma key = persistência inconsistente** (a mesma issue não pode ser Epic e Story):
  tratar a Story como **ausente** — sondagem anti-duplicata (§4), criar/corrigir e avisar no
  output; nunca aceitar a key duplicada como estado válido.
- **TASK** → campo `Jira: <KEY>` no bloco "Histórico de execução" da closure, ao lado de
  `Commit SHA`.
- **INDEX** → apenas 1 linha no "Histórico recente" — **do sucesso**
  (`issues Jira: <KEY> + N sub-tasks`) **ou do pulo**, com motivo e evidência da prova (§0). Só
  uma linha por execução nos dois casos; o contrato da tabela "PLANs"
  (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`) **não** muda.

## §11. Link do PR / push (integrate, auto)

Após o PR aberto (`/keelson:integrate`) ou o push (`/keelson:auto`): `addCommentToJiraIssue`
na issue principal com a URL do PR/branch (e, quando útil, `createIssueLink`/remote link).
Best-effort (§0).

## §12. Reconciliação (`/keelson:jira-sync` · fecho do `/keelson:auto`)

Reprocessa um slug de forma idempotente (§4), na ordem: issue da SPEC (§6 — pulada na
projeção compacta do §7.0, cuja raiz é a Story única) → Stories das
FEATs (`jira-sync-feat.md`, quando ativo) **ou** Story implícita (degrau (0) do §7.0) →
sub-tasks (§7) → **descrições das issues existentes** (§6.2 — re-render conforme a política
do marcador; descrição sem marcador é do humano e fica intocada) → status (§9, incluindo o
gatilho "Funcionalidade pronta p/ QA" para FEATs já completas). Aplica campos e — se
`transition:auto` — alinha o status ao **estado real** das TASKs, sempre sob o teto e a
não-regressão do §9: sub-task de TASK `In Progress` → alvo de `TASK iniciada`; de TASK
`Done` → alvo de `TASK concluída`; Story com **alguma** TASK iniciada → alvo de
`Trabalho iniciado (Story)` (o teto — nunca além, mesmo com tudo `Done`). A reconciliação
**não tem** caminho que leve a unidade de QA além do teto: plano de status que contenha um
veio de linha não-canônica do mapa (§3) e está errado — leia o §9 **antes** de transicionar
(§0) e declare o teto no output. Estado misto
(sub-tasks legadas sob a issue da SPEC com o 3º nível ativo) é **reportado no output**,
nunca re-parentado (§4).

**Escopo por SPEC** (decisão 4.55): quando o invocador aponta uma SPEC específica
(`SPEC-NNN` ou caminho do arquivo) em vez do slug, a mesma reconciliação roda sobre a
**árvore daquela SPEC** — issue da SPEC (§6) → Stories dela (§6.1 ou degrau (0) do §7.0) →
sub-tasks das TASKs dos PLANs que a cobrem (coluna "Cobre" do INDEX do slug) — e nada além.
Nenhuma regra muda: idempotência (§4), régua de hierarquia (§7.0), campos (§8) e
persistência (§10) valem idênticas; a única diferença é o recorte do conjunto. É o
fallback manual de menor superfície quando um ciclo terminou com o tracker vazio.

**Dois invocadores, a mesma reconciliação**: o comando avulso `/keelson:jira-sync` (rede de
segurança sob demanda, com `--dry-run`, escopo por SPEC e backfill abaixo) e o **fecho do
`/keelson:auto`** (Etapa 5), que a roda antes do relatório de entrega. Como o sync inteiro é idempotente por
exigência do §4, rodá-la no fecho é **no-op barato quando os ganchos de
`specify`/`tasks`/`implement` funcionaram** e conserta o ciclo quando algum não rodou — os
ganchos deixam de ser três oportunidades independentes de falhar em silêncio e viram três
tentativas mais uma rede. A passada do fecho também **mede o estado final do tracker** (Epic ·
Story/unidade de QA · sub-tasks K/N · transições aplicadas), que alimenta a linha obrigatória
do relatório de entrega do `/keelson:auto`.

**Backfill de slug já concluído** (o caso mais comum da reconciliação: o sync nunca rodou e o
trabalho já foi entregue). Antes de criar em lote, medir o estado real das TASKs do slug. Se a
maioria está `Done` **e** `transition` é `comment`/`off`, o quadro **nasceria mentindo** —
dezenas de cards em "a fazer" sobre trabalho em produção. Nesse caso, **reportar antes de
criar** (no `--dry-run`, na seção de avisos; sem a flag, como primeira linha do output) que:
(a) `transition: auto` na ficha faria os cards nascerem no status-alvo correspondente ao estado
real; (b) em `comment`, o marco de cada closure vira comentário e o alinhamento do quadro fica
manual. **Não** mudar a ficha nem forçar transição por conta própria — a política de transição
é decisão do projeto (§0, §9).

## §13. Verbos de fase (`/keelson:jira-sync --phase start-dev|finish-dev`)

Atos **imperativos** do humano sobre o quadro, fora dos marcos automáticos do ciclo: mover a
árvore do alvo (slug inteiro ou a árvore de uma SPEC — mesmo recorte do §12) para o estado de
uma fase do fluxo do time. O verbo **roda a reconciliação do §12 antes** (idempotente — no-op
barato quando a árvore já existe; cria o que faltar quando não) e então aplica a fase.

- **Alvos por nível**: as linhas da tabela Etapas/Colunas (§3) cujo `Gatilho` é
  `--phase <verbo>`, uma por `Nível`. Linha ausente para um nível → aquele nível **não se
  move** — opt-out declarado, não erro. A semântica das fases é do **mapa**, não hardcoded;
  os verbos são a convenção: `start-dev` — a árvore entra em desenvolvimento (tipicamente
  Epic "em progresso", Story e sub-tasks "em desenvolvimento"); `finish-dev` — o
  desenvolvimento terminou (tipicamente sub-tasks "concluído", Story na coluna de revisão —
  o passo seguinte do fluxo do quadro).
- **Ordem coerente da árvore**: `start-dev` move **de cima para baixo** (epic → story →
  sub-tasks); `finish-dev`, **de baixo para cima** (sub-tasks → story → epic, se declarado) —
  o quadro nunca mostra filho concluído sob pai não-iniciado nem o inverso.
- **Política `transition`**: o verbo é **ordem explícita do humano** — move o card com
  `comment` e `auto` (a política governa os ganchos **automáticos** do ciclo, que seguem o §9
  como sempre). `off` é política dura do projeto → o verbo **avisa e não move** — e não
  comenta: em `off` nada toca a issue; o aviso fica no output do comando.
- **Epic — duplo opt-in**: a doutrina "Epic intocado" (§9) vale para todo gancho automático,
  inclusive a reconciliação; o Epic só se move **por verbo de fase** e **com linha `epic`**
  declarada para o verbo no mapa. **Projeção compacta** (§7.0): não há Epic — a linha `epic`
  é no-op silencioso; a raiz da árvore anda pela linha `story`.
- **Mecânica de cada movimento**: a do §9 — transição direta quando existe; senão o **walker
  multi-hop** pelo Trilho do board (§3), nunca regredindo, parando-e-comentando em salto
  bloqueado. **Idempotente**: card já no alvo ou além dele no trilho → no-op; rodar o mesmo
  verbo duas vezes é seguro.
- **`--dry-run`**: imprime o plano de movimentação por card
  (`KEY: <status atual> → <intermediários> → <alvo>` · `no-op (já no alvo/além)` ·
  `bloqueado em <status>`) sem tocar no Jira.
- **Registro** (§10): 1 linha no "Histórico recente" do INDEX — verbo, alvo, K cards movidos,
  bloqueios. Best-effort (§0) como todo o resto: conector fora ou chamada falha → avisa,
  registra o rastro e nunca trava.
