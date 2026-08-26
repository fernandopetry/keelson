---
description: Configura ou repara a adoção do keelson num projeto — detecta a stack, escreve a ficha (keelson.config.json), resolve o perfil de linguagem e injeta o bloco no CLAUDE.md; com o escopo `jira`, configura ou re-mede só a integração Jira
argument-hint: "[jira]"
---

# /keelson:init

Você configura (ou repara) a adoção do **keelson** num projeto. Seu trabalho é **detectar o máximo, perguntar o mínimo**, e deixar o projeto pronto para o ciclo `/keelson:specify → :plan → :tasks → :implement`.

**Princípio**: as perguntas que você faz são **decisões de produto** (tem frontend? qual o comando de teste?), nunca "digite este glob". Detecte o que der; pergunte só o que não conseguir inferir, sempre explicando o **efeito** da escolha.

**Idempotente e preservador**: rodar de novo **completa e repara, nunca destrói** (ver a **Regra de merge** abaixo). Por isso **atualizar o plugin e rodar `/keelson:init` de novo é o caminho de migração de versão**: o projeto ganha o que a versão nova trouxe sem perder o que já era seu.

## Resultado esperado

Ao final existem, no projeto:
- `keelson.config.json` na raiz (a ficha) — preenchida e validada;
- um perfil de linguagem ativo (exemplar embarcado **ou** gerado e pendente de revisão);
- o bloco gerenciado do keelson no `CLAUDE.md`;
- um relatório do que foi detectado, perguntado e o que falta revisar.

## Regra de merge — preservar × completar (vale para TODAS as etapas)

Este comando **nunca apaga nem sobrescreve** o que o humano personalizou. Ao rodar sobre um projeto já configurado:

- **Valor já presente e válido** (path, comando, gate, perfil, método, credencial) → **mantém**. Não regenere por regenerar.
- **Campo/arquivo ausente** que a versão atual do keelson exige (ex.: `screenVerify.method` numa ficha antiga que só tinha o boolean; um `keelson.local.json` ou `keelson.local.example.json` que ainda não existe) → **cria/completa**, sem tocar no resto.
- **Valor presente mas claramente quebrado** (path inexistente, comando que não roda) → **pergunte** antes de mudar; não sobrescreva em silêncio.
- **Arquivos personalizados nunca são regenerados por cima**: `keelson.local.json` (credenciais), perfis `guidelines/project/*` já `reviewed: true`. Se precisam de um campo novo, **complete o campo** — não reescreva o arquivo.

Reset é explícito: se o humano quer recomeçar um artefato do zero, ele pede (`--reset`); o default é sempre **preservar**.

## Escopo `jira` — configurar ou re-medir só a integração Jira (decisão 4.262)

`/keelson:init jira` executa **somente** a Etapa 4.6 e a fatia Jira do self-check (Etapa 6) — a porta para ligar o Jira depois de uma adoção que começou com `jira.enabled: false`, ou para atualizar a config quando o quadro do projeto mudou, sem repassar detecção de stack, perfis e o resto do fluxo. Sem argumento, nada muda: o comando segue as Etapas 1–7 como sempre.

- **Pré-condição**: a ficha (`keelson.config.json`) existe na raiz. Ausente → **pare sem escrever nada** e instrua rodar `/keelson:init` completo — o escopo configura uma adoção existente, não cria uma.
- **Execução**: Etapa 4.6 na íntegra (perguntas de produto, descoberta por ID, mapa, gravação do bloco `jira`), com a Regra de merge valendo como em qualquer rodada. Depois, a fatia Jira do self-check: os itens `jira-*` do `init-selfcheck.sh` (filtre a saída do script — ele não tem, nem precisa de, flag de recorte) e as provas que exigem MCP vivo do bloco `se jira.enabled` da Etapa 6. O relatório se reduz ao que foi tocado.
- **Re-medição (bloco já configurado)**: com o bloco `jira` preenchido, o merge-preserving sozinho deixaria IDs mortos intactos — um quadro que mudou de workflow ou de tipos de card não se corrige preservando. No escopo, re-execute a **descoberta** dos passos 2–3 da Etapa 4.6 e **compare com o que está gravado**: ID de tipo/status que não existe mais, status novo ausente do Trilho, ordem do workflow que mudou → cada divergência vira **aviso no relatório e sugestão comentada no mapa**, pela mesma fórmula da Regra de merge da Etapa 4.6 ("estrutura adicionada como sugestão comentada, nunca sobrescrevendo a tabela do humano"); ficha e mapa só mudam com a confirmação do humano. Divergência entre a prosa do mapa e a ficha segue a régua da Etapa 6: **a ficha vale**.
- **Porta humana**: o escopo existe para o Diretor ativar/atualizar o Jira quando decidir. Comando que encontra a ficha incompleta no meio de um ciclo continua na rota **Config incremental** (fim deste comando) — pergunta o campo que falta e oferece gravar — nunca invoca o init.

## Etapa 1 — Detecção (não pergunte o que dá para inferir)

Inspecione a raiz do projeto:

1. **Backend — linguagem e versão.** Procure o manifesto: `composer.json` (`require.php` → PHP + versão), `package.json` (Node — `engines.node`), `go.mod`, `pyproject.toml`/`requirements.txt`, `Gemfile`, `*.csproj`, `Cargo.toml`… Extraia `lang` e a **versão exata** (versão é primeira classe: PHP 5.6 ≠ 8.5).
2. **Frontend.** Há `package.json` com `vue`/`react`/`@angular/core`/`svelte`? Ou nenhum framework (front sem framework)? Ou não há frontend (API pura)?
3. **Comandos de qualidade.** Leia os `scripts` de `package.json` e/ou `composer.json` e infira `test`, `lint`, `typecheck`, `build`. Infira também `boot` — o comando que **sobe a app** para exercício local (`docker-compose.yml`/`compose.yaml` → `docker compose up -d`; scripts `dev`/`serve`/`start`; `php -S`…); ambiente permanente (app já de pé fora do repo) ou nada a subir → `null`, dito por extenso no relatório. Confirme a existência dos binários quando possível.
4. **Paths de código.** Heurística pelo layout (`src/`, `app/`, `lib/`, `apps/*`). Não invente — proponha o que existe.

## Etapa 2 — Perguntar só as lacunas

Para cada valor que **não** inferiu com confiança, pergunte com opções fechadas e o efeito explícito. Exemplos:
- *"Não encontrei frontend — confirma que é API-only?"* → **desliga** `gates.screenVerify` e o perfil de frontend.
- **Se há frontend** — *"Como este projeto verifica tela? A skill embarcada `screen-verify` (Playwright MCP) / um método próprio do projeto"* → define `gates.screenVerify.method`. A skill embarcada **`screen-verify`** dirige o browser via **Playwright MCP** lendo os dados de acesso do `keelson.local.json` (método `skill:screen-verify`, o default); método próprio do projeto → registre-o e **pule a Etapa 4.4**.
- **Se o método é a skill embarcada** — *"Rodar o browser em headless (padrão, sem janela) ou com janela visível?"* → vira a flag `--headless` da Etapa 4.4. Headless é o default; janela visível só quando o humano quer acompanhar a verificação com os próprios olhos.
- **Se há frontend** — *"Quantas áreas logadas (realms) a aplicação tem?"* — ex.: só a admin; ou admin **+** portal de usuários finais, com URL e usuário distintos. Cada realm vira uma entrada em `screenVerify.realms` do `keelson.local.json` (Etapa 4.5), com `description` dizendo do que se trata o acesso, `baseUrl`, rota de login e usuário de dev próprios.
- *"Detectei o script `test` — usar `<comando>` como `quality.test`?"*
- *"Como se sobe a app deste projeto para exercício local?"* → `quality.boot` (decisão 4.71). É o comando que o `qa` roda antes de declarar `app_fora_do_ar` — sem ele, "app fora do ar" vira waiver barato. `null` é resposta válida (ambiente permanente), mas **escolhida**, nunca default silencioso.
- **Mutação da suíte** (decisão 4.121, mesma mecânica de detecção da 4.80): antes de perguntar, procure ferramenta de mutation testing nos manifests — `composer.json` (`infection/infection`), `package.json` (`@stryker-mutator/*`), `pyproject.toml`/`setup.cfg` (`mutmut`, `cosmic-ray`), `pom.xml`/`build.gradle*` (PIT/`pitest`), `Cargo.toml` (`cargo-mutants`). Achou → *"Detectei `<ferramenta>` — configurar `quality.mutation` com `<comando>`? (opt-in; roda só no `/keelson:integrate`, depois da suíte verde)"*. Não achou → **não instale nada aqui**; `mutation: null` sem pergunta, e **uma linha no relatório** apontando `/keelson:mutation-setup` para quem quiser o gate (decisão 4.123 — o setup guiado instala, configura e prova antes de gravar). Escopo e threshold são do consumidor, dentro do comando gravado.
- **Suíte E2E** (decisão 4.166, mesma mecânica de detecção): procure runner E2E nos manifests — `package.json` (`@playwright/test`) ou config na raiz (`playwright.config.*`). Achou → *"Detectei `<ferramenta>` — usar `<comando>` como `quality.e2e`? (opt-in; specs versionados com tags `@<slug>`/`@AC-NNN-XXX` dão o recorte por task, regressão completa roda no `/keelson:integrate` — régua em `guidelines/core/TESTING.md`, 'Specs E2E')"*. Não achou → **não instale nada aqui**; `e2e: null` sem pergunta, e **uma linha no relatório** apontando `/keelson:e2e-setup` para quem quiser a suíte (decisão 4.167 — o setup guiado instala, configura e prova antes de gravar); o gate de tela continua coberto pelo método da Etapa 2.
- *"O código de backend fica em `<path>`?"*

Não pergunte o que já sabe. Não faça perguntas de implementação que você mesmo pode resolver.

## Etapa 3 — Resolver o perfil de linguagem

Para backend e (se houver) frontend:
1. **Perfil embarcado bate exato** (mesma `lang` e `version`) → ative-o direto. Enumere os embarcados **em runtime**: liste `${CLAUDE_PLUGIN_ROOT}/guidelines/backend/` (e `frontend/`) — `<lang>.md` é o **exemplar** da versão mais recente suportada (o frontmatter declara `version`) e `<lang>-<versão>.md` a **escada legada** daquela linguagem.
2. **Mesma `lang`, versão sem perfil exato** (ex.: PHP 7.3) → a **base é o perfil embarcado mais próximo ABAIXO** da versão do projeto (7.3 → base `php-7.0.md`; 8.3 → base `php-8.0.md`). Invoque o agent **`staff-engineer`** passando essa base para **derivar** o perfil escrevendo o **delta**: recursos que a versão do projeto adiciona à base, sintaxe, runner/ferramentas. **Nunca derive de versão maior** — perfil recomenda recursos, e base maior recomenda o que não existe na versão do projeto (passa no lint, quebra em runtime). Se não houver embarcado abaixo (ex.: PHP 5.4), gere do zero usando o mais próximo acima **apenas** como referência de formato/rigor, nunca como fonte de recomendação de recurso. Destino: `guidelines/project/<role>/<lang>-<version>.md` **na raiz do projeto**, `reviewed: false`.
3. **Sem exemplar para a `lang`** (ex.: Node, React, Angular) → ofereça **gerar do zero** via `staff-engineer`, aplicando o `QUALITY-CHARTER` no mesmo padrão do exemplar PHP. Destino idem, `reviewed: false`.

Em todos os casos, **grave o caminho resolvido no campo `profile.<role>.file` da ficha**: prefixo `plugin:` para exemplar embarcado (ex.: `plugin:backend/php.md`, resolvido em `${CLAUDE_PLUGIN_ROOT}/guidelines/`); caminho relativo à raiz do projeto para perfil gerado (ex.: `guidelines/project/backend/node-20.md`). É esse campo que os demais comandos usam para carregar o perfil.

**A invocação do `staff-engineer` é bloqueante** (decisão 4.265 — regra geral: artefato de subagent que etapa seguinte consome ⇒ o retorno é pré-condição): espere o agent retornar e **prove que o arquivo existe no disco** (`test -f`) antes de gravar o caminho na ficha e de seguir adiante — o caminho nunca entra na ficha pela promessa do spawn. Caso real: rodada não-interativa retornou com o agent ainda rodando e a ficha apontando arquivo nunca escrito.

Perfis gerados nascem **pendentes de revisão**: afirmações não confirmadas levam a tag inline `⚠️ não confirmado` e a logística de revisão humana vive no arquivo companheiro `_review/<lang>-<versão>.md` ao lado do perfil (embarcados: `${CLAUDE_PLUGIN_ROOT}/guidelines/backend/_review/php-<versão>.md`) — colete os itens do companheiro para o relatório.

## Etapa 4 — Escrever a ficha `keelson.config.json`

Parta de `${CLAUDE_PLUGIN_ROOT}/templates/keelson.config.example.json` e preencha com os valores resolvidos: `profile` (backend/frontend com `lang`+`version`+`file` da Etapa 3), `codePaths`, `sensitiveGlobs`, `quality`, `docsRoot`, `git` (estratégia e naming de branch — decisões 4.190/4.192; os defaults do template preservam o comportamento clássico: `branchStrategy: "unica"`, `branchNaming: "slug"` — pergunte só se o humano mencionar política de branch; `"tracker-key"` exige `jira.enabled: true`, provado pelo self-check), e `gates`:
- `security` (bool);
- `review`/`reviewThreshold` parametrizam a **cutucada de encerramento** do hook `review-guard` (mudança de código fora do ciclo — decisões 4.15/4.266); **não** desligam o `code-reviewer` do ciclo, que roda sempre;
- `screenVerify` = objeto `{ "enabled": <há frontend?>, "method": <o da Etapa 2, ex. "skill:screen-verify">, "artifactsDir": <default "thoughts/screen-verify"> }`. (Aceita também o atalho booleano `true`/`false` = `{enabled, method:null}`.) **O modo do browser NÃO vive aqui** — headless é flag do servidor MCP (Etapa 4.4), que é quem de fato controla; duas fontes de verdade divergiriam em silêncio.

Grave na raiz do projeto. **Se a ficha já existe** → Regra de merge; específico deste passo: migrar um `screenVerify` booleano antigo para o objeto `{enabled, method, artifactsDir}` mantendo o valor; ficha sem `artifactsDir` → acrescentar o default.

## Etapa 4.4 — Runtime de browser para a verificação de tela (só se `method: skill:screen-verify`)

A skill `screen-verify` dirige o browser pelo **Playwright MCP** (decisão 4.49). Sem esse servidor não há gate de tela — e o modo de falha caro é o desenvolvedor descobrir isso semanas depois, no meio de uma entrega. Então **garanta o runtime aqui, nunca em silêncio**:

**Ordem importa**: garanta as linhas de `.gitignore` da Etapa 5.5 **antes** do passo 1 — a navegação de prova escreve no `--output-dir` em vigor, e com o servidor mal configurado isso é `.playwright-mcp/` na raiz do projeto. Provar primeiro e limpar depois já deixou pasta não-ignorada no `git status` de uma rodada real (decisão 4.51).

1. **Provar antes de concluir** (mesma régua da 4.26): as ferramentas MCP chegam **deferred** — "não vi `mcp__playwright__*` na lista" **não é** evidência de ausência. Carregue-as e faça uma navegação barata (`browser_navigate` para `about:blank`). **Responder não é aprovar**: siga para o passo 2 mesmo com o servidor de pé.
2. **Ler a configuração efetiva** — o servidor que responde pode não ser o que você espera, e pode estar em escopo que este comando não gerencia. Procure `mcpServers.playwright` **nestes lugares, nesta ordem**: `.mcp.json` da raiz do projeto · `projects."<path do projeto>".mcpServers` do `~/.claude.json` · `mcpServers` do `~/.claude.json` (global). Mais de uma entrada é comum e **não** é erro por si — reporte quais existem e **qual delas vale para este projeto**.
3. **Conferir as flags, não a resposta** — servidor de pé com flag errada é reparo pendente, nunca `✓` (decisão 4.51). Confira, contra a ficha e a Etapa 2:
   - `--output-dir` **igual** a `gates.screenVerify.artifactsDir`. Divergente ou ausente → os artefatos caem no default `.playwright-mcp/`, fora do lugar que a skill declara.
   - `--isolated` **presente** quando o `keelson.local.json` tem **mais de um realm** — sem ele o perfil é persistente e o `browser_close` entre realms não descarta a sessão: a verificação do segundo realm herda o login do primeiro, que é o falso verde que o gate existe para evitar.
   - modo do browser (`--headless` presente ou não) igual ao escolhido na Etapa 2.

   Divergência em escopo **do projeto** → proponha o ajuste e aplique. Divergência em escopo **pessoal/global** → o keelson **não** edita config pessoal do humano: entregue o comando exato de correção e registre a pendência no relatório.
4. **Configurar o servidor** (ausente, ou aceito o ajuste do passo 3) — pergunte qual escopo (opções fechadas, com o efeito):
   - **Projeto** (default, recomendado): bloco `mcpServers.playwright` no `.mcp.json` da raiz — **arquivo versionado**, o time inteiro herda a mesma configuração. É mudança em arquivo do projeto: mostre o bloco que vai escrever **antes** de escrever e aplique a **Regra de merge** (outros servidores no arquivo são preservados; um `playwright` já existente **não** é sobrescrito — proponha o ajuste e pergunte).
   - **Pessoal**: entregue o comando para o humano rodar, sem tocar no repositório — forma verificada em uso real (o `--` separa os argumentos do `npx` dos flags do servidor):

     ```
     claude mcp add playwright -s user npx -- @playwright/mcp@latest --headless --output-dir <artifactsDir> --isolated
     ```

     Substituir uma entrada pessoal existente exige removê-la antes (`claude mcp remove playwright -s user`); o `add` não sobrescreve. Diga ao humano que a sessão precisa ser reiniciada para o servidor novo valer.

   Bloco canônico do `.mcp.json` (omita `--headless` se o humano escolheu janela visível na Etapa 2):

   ```jsonc
   { "mcpServers": { "playwright": { "command": "npx", "args": [
       "@playwright/mcp@latest", "--headless",
       "--output-dir", "thoughts/screen-verify",   // = gates.screenVerify.artifactsDir
       "--isolated"                                 // perfil em memória: cada run começa limpo
   ] } } }
   ```

   `--isolated` é o que torna honesto o isolamento por realm da skill (`browser_close` entre realms descarta a sessão de verdade). **Não** adicione `--allowed-origins` por conta própria: bloquear origem externa faz fonte/CDN sumirem e imita bug de UI — é endurecimento opcional, decisão do humano. Trace e vídeo (`--caps devtools`) também são opt-in: só ofereça se o humano quiser artefato de investigação, porque cada capability acrescenta ferramentas ao contexto de toda sessão.
5. **Binários do navegador**: o Playwright baixa o browser num cache **do usuário** (`~/Library/Caches/ms-playwright` no macOS, `~/.cache/ms-playwright` no Linux) — fora do repositório, descartável. Instalar isso é seguro; **instalar em silêncio, não**. Ofereça rodar `npx playwright install chromium` (Linux: `npx playwright install --with-deps chromium`, que usa `apt` — em distro não-Debian, instrua as libs manualmente) e **diga o que foi instalado e onde**. Recusa do humano → registre a pendência com o comando exato no relatório.
6. **Limpar o rastro da prova**: artefato gerado pela navegação do passo 1 (ex.: `.playwright-mcp/`) é lixo de diagnóstico — remova-o e diga que removeu. Nunca deixe pasta nova no `git status` como efeito colateral do `init`.

Idempotente: servidor já configurado **e com as flags do passo 3 conferindo** → **não reescreva nada**, só confirme no relatório qual escopo respondeu e em que modo.

## Etapa 4.5 — Dados de acesso locais para verificação de tela (só se `screenVerify.enabled`)

Se `gates.screenVerify.enabled` é `true` e o método precisa de credenciais (ex.: a skill `screen-verify`), a verificação exige URL + login de **desenvolvimento**. Produza **dois arquivos** na raiz (padrão `.env` / `.env.example`):

1. **`keelson.local.example.json`** — **VERSIONADO** (vai para o git). É o template do projeto: preencha `screenVerify.realms` — **um realm por área logada** identificada na Etapa 2 (ex.: `admin`, `portal`), cada um com `description` (do que se trata o acesso), `baseUrl`, rota de login e `username` **deste projeto** — e deixe cada `password` como placeholder (`<PREENCHER: ...>`). **Nunca** contém senha real.
2. **`keelson.local.json`** — **GITIGNORED** (nunca vai para o git): a cópia real, onde o humano põe a senha. **Garanta o `.gitignore` ANTES de criá-lo** (Etapa 5.5). Crie-o a partir do `.example` do projeto (se já existir) ou do template do plugin, com a senha em placeholder.

Regras:
- **Não escreva senha** você mesmo em nenhum dos dois. Deixe o placeholder e **instrua o humano** a preencher só o `keelson.local.json`, com credenciais de **DEV/teste descartáveis** — **nunca** produção nem conta real.
- **Regra de merge** vale aqui; específico deste passo: o `.example` pode ganhar campos novos, sempre **sem** senha.
- **Migração flat → realms**: arquivo antigo no formato flat (`baseUrl` + `login` direto sob `screenVerify`) → migre para `realms` **preservando os valores** (vira o realm único, nomeado pelo que ele é — ex.: `admin` — com `defaultRealm` apontando para ele). O flat segue aceito em runtime; o `.example` novo já nasce em `realms`.

## Etapa 4.6 — Integração com Jira (opcional, best-effort)

Ofereça a integração keelson↔Jira apenas se fizer sentido para o projeto (o time usa Jira como quadro). **Não é obrigatória** e nasce **desligada** (`jira.enabled: false`) — pule sem cerimônia se o humano não quiser. Toda a mecânica de runtime vive no **protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`); aqui você só **descobre e grava a config**, nunca embarca dado de empresa no plugin.

Se o humano optar por ligar (requer o **conector Atlassian** autorizado — sem ele, avise e deixe `enabled:false`):

1. **Perguntas de produto** (opções fechadas): `site` (hostname Atlassian), `projectKey`, `mode` — `create` (o keelson cria a issue da SPEC + sub-tasks; ideal para projeto limpo/team-managed) ou `link` (pendura numa issue existente; ideal para projeto governado/company-managed) — e `epicPolicy` — `always` (default: toda SPEC vira Epic) ou `multi-feature` (SPEC com 0–1 FEAT projeta **sem** Epic: Story raiz + sub-tasks; Epic só com 2+ FEATs — protocolo §7.0, decisão 4.61).
2. **Resolver por descoberta** (protocolo §1, sempre por **ID**, nunca por nome): `getAccessibleAtlassianResources`/`site` → `cloudId`; `getJiraProjectIssueTypesMetadata` → escolher `issueType.spec` e `issueType.task` (se houver mais de um tipo de sub-task, **pergunte** qual); confirmar que `issueType.task` é `subtask:true` (senão, avise o fallback para issue linkada — §7). **Se o humano quiser a hierarquia de 3 níveis** (Epic ▸ Story de funcionalidade ▸ sub-task — só faz sentido quando as SPECs declaram FEATs): identificar via `hierarchyLevel` o tipo epic-level para `issueType.spec` e o tipo standard (Story) para `issueType.feature`. Ofereça também `issueType.standalone` — um tipo **nível 0** (Tarefa/Bug) para a tarefa avulsa, o card de QA do brief avulso fora do aninhamento (§7, decisão 4.86); não querer → `null`, avulsos não sincronizam. Com `standalone` preenchido, ofereça **`jira.standaloneParent`**: a key de um Epic agrupador existente (ex.: um Epic "Manutenção" que o humano cria uma vez no quadro) para as Stories avulsas aninharem; não querer → `null`, Story avulsa nasce sem pai — os dois são válidos. Não querer o 3º nível → `issueType.feature: null` e nada muda.

   **Guardrail de hierarquia (aviso, nunca bloqueio — §0)**: antes de gravar, validar com `hierarchyLevel`/`subtask` do createmeta que cada perna do mapeamento aninha de verdade — a regra de adjacência é a do **pré-check de hierarquia** de `${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md` (contratos do 3º nível). Perna inválida → **aviso claro dizendo qual perna não aninha e sugerindo o tipo correto do próprio projeto** (ex.: "História(0) não cabe sob Tarefa(0) — são irmãos, o Jira só liga com 'relates to'; o tipo epic-level deste projeto é Epic(<id>)"). Grave o que o humano confirmar: em runtime a escada de degradação do `jira-sync-feat.md` cobre, mas configurar certo evita cards soltos.
3. **Status/transição**: `getJiraIssueTypeMetaWithFields` + amostragem de status (`searchJiraIssuesUsingJql`/`getTransitionsForJiraIssue`) para conhecer o workflow — **por nível** (protocolo §3): os tipos de `spec`, `feature`/`standalone` e `task` costumam ter workflows diferentes; amostre uma issue de cada tipo quando existir e anote a **ordem** dos status (é ela que vira o Trilho do board no item 4). Tipo sem issue no projeto (workflow não observável) → trilho comentado como não-medido. Default seguro `transition:comment` (não move card); só proponha `auto` se houver caminho de transição claro.
4. **Gerar o esqueleto do mapa `.md`** em `{docsRoot}/_meta/jira.<PROJECT>.md` e apontar `jira.mapFile` para ele. Abrir com um cabeçalho de referência legível do mapeamento de tipos resolvido — uma linha por chave (`spec`/`feature`/`task`/`standalone`), com nome, ID e `hierarchyLevel` de cada (ex.: `spec: Epic (11169, nível 1)`), e nota de qual perna não aninha, se houver. Gerar as **três seções** do protocolo §3: **Campos**; **Etapas/Colunas** (com a coluna `Nível`), pré-preenchendo por `statusCategory`, anotando `allowedValues` como referência em comentário (o humano preenche Direção/Estratégia/Valor), semeando os **marcos canônicos do ciclo** — `TASK iniciada` e `TASK concluída` (`subtask`), `Trabalho iniciado (Story)` — anotada como **teto de transição automática da unidade de QA** (§9) — e `Funcionalidade pronta p/ QA` (as duas de `story` comentadas quando `issueType.feature: null`) — **e as linhas de fase** `--phase start-dev`/`--phase finish-dev` por nível (protocolo §13; a linha `epic` nasce **comentada** — mover Epic é opt-in explícito do humano); e **Trilho do board** — a ordem de status por nível medida no item 3 (nível não-medido → trilho comentado, com a nota de medir na primeira issue real). Lembre no cabeçalho que a **ordem das linhas** de Etapas/Colunas é a régua de progressão que a não-regressão do §9 usa quando o nível não tem trilho — o humano deve mantê-la espelhando a ordem real das colunas do quadro. Avise que o `.md` pode conter nomes de pessoas (via `allowedValues`) — é config de projeto, versionável, **não segredo**.
5. **Gravar o bloco `jira`** na ficha (campos por ID). **Nenhum token/segredo** — o conector é o único canal; nada vai para `keelson.local.json`.

Merge-preserving (Regra de merge): bloco `jira` já presente → preserva; ficha antiga sem o bloco → acrescenta com `enabled:false`; bloco presente sem `issueType.feature`/`issueType.standalone` → acrescenta a(s) chave(s) como `null` sem tocar no resto; bloco sem `epicPolicy` → acrescenta `"always"` (comportamento atual); bloco sem `standaloneParent` → acrescenta `null` (4.86); map file antigo sem algum dos marcos canônicos ("TASK iniciada", "TASK concluída", "Trabalho iniciado (Story)", "Funcionalidade pronta p/ QA"), sem a coluna `Nível`, sem as linhas de fase ou sem a seção "Trilho do board" → estrutura adicionada como sugestão comentada, nunca sobrescrevendo a tabela do humano.

**Diagnóstico de marcos não-canônicos** (mapa antigo ou editado à mão): linha de Etapas/Colunas cujo `Gatilho` não é um dos quatro marcos canônicos nem `--phase <verbo>` — tipicamente prosa do fluxo real do time (`QA valida a funcionalidade / PR aberto`, `Funcionalidade aprovada na SPEC`) — **listar no output** como *documentação, não gatilho* (§3: catálogo fechado), com a recomendação de comentá-la ou renomeá-la para o marco canônico correspondente. **Não** alterar a tabela do humano. Um mapa em que a única linha de `story` que aponta para a coluna de desenvolvimento está ausente merece destaque: sem `Trabalho iniciado (Story)`, o teto do §9 vira "nenhuma transição automática na Story" e o quadro não mostra o trabalho começando.

**Diagnóstico de mapa-ledger** (decisão 4.150): seção do mapa fora do contrato das três do §3 que registra **execução** — árvore de issues por SPEC, keys criadas, estado de sub-tarefas no quadro — vira aviso `mapa com registro de execução — config, não ledger` no output, com a recomendação de podar (as keys já persistem nos artefatos SDD e no INDEX, §10 do protocolo; o estado vivo é o Jira). O init **não poda sozinho** (a tabela e o arquivo são do humano), mas nunca completa nem atualiza a seção contaminada — nota do próprio mapa pedindo a anotação ("lacuna" de ledger) não cria obrigação.

## Etapa 4.7 — Convenção de commit e release automation (detecção, decisão 4.80)

O keelson escreve commits no repo do consumidor, e num projeto que **deriva versão e changelog
dos commits** a escolha do tipo deixa de ser organização e passa a ter efeito de publicação. Aqui
você **descobre e grava**; a régua da mensagem tem dono único em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/commit-convention.md`.

1. **Detectar a automação** (sem perguntar o que dá para ver): `package.json` (`semantic-release`,
   `standard-version`, `@commitlint/*`), `.releaserc*` / `release.config.*`,
   `release-please-config.json`, `cliff.toml`, `.commitlintrc*`, `.github/workflows/*` com passo de
   release, `pyproject.toml` (`python-semantic-release`). Achou → `commit.releaseAutomation` recebe
   o nome da ferramenta.
2. **Detectar a convenção em uso** quando não há ferramenta declarada: amostre os tipos do
   histórico — `git log --pretty=%s -200 | grep -oE '^[a-z]+' | sort | uniq -c | sort -rn`. Maioria
   dentro da lista fechada → `convention: "conventional"`. Padrão próprio dominante → grave-o como
   string livre e **respeite-o** (o keelson segue a casa, não a converte). Histórico sem padrão →
   `"conventional"`, que é o default do plugin.
3. **Tipos fora da lista fechada no histórico** (ex.: um `harden:` ou `security:` esparso) →
   **listar no relatório** como observação, com o tipo canônico correspondente. Não reescreva
   histórico, não proponha rebase: é informação para o Diretor decidir, e vira defeito de verdade
   só quando houver automação lendo aqueles commits.
4. **Sem automação detectada** → `releaseAutomation: null` e **uma linha** no relatório dizendo que
   o histórico já sai consumível caso o projeto adote uma depois. **Não ofereça configurar**:
   publicar release é ato do Diretor, da mesma classe de PR, merge e deploy (decisão 4.41) —
   envolve credencial, proteção de branch e tag, tudo fora do repositório. O README documenta o
   caminho por stack para quem quiser adotar.

Merge-preserving (Regra de merge): bloco `commit` já presente → preserva (só acrescenta chave
faltante); ficha antiga sem o bloco → acrescenta com o detectado.

## Etapa 5 — Injetar o bloco no `CLAUDE.md`

Insira o conteúdo de `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.keelson-block.md` no `CLAUDE.md` do projeto (crie o arquivo se não existir). Se um bloco keelson já existir (entre os marcadores `<!-- ... keelson ... -->`), **substitua-o** — não duplique.

## Etapa 5.5 — Garantir `thoughts/` fora do versionamento

Memos de exploração e backups do keelson vivem em `thoughts/local/`; os artefatos da verificação de tela (screenshot, dump de console/rede), em `thoughts/screen-verify/<slug>/` — nada disso é versionado. Garanta que o `.gitignore` do projeto contém `thoughts/` **e** `keelson.local.json` (dados de acesso locais — credenciais de dev, nunca versionadas) — adicione as linhas que faltarem.

**Cobertura se verifica, não se infere** (decisão 4.51): não conclua que o `artifactsDir` está ignorado porque existe uma linha `thoughts/` — o projeto pode versionar parte de `thoughts/` de propósito (um consumidor real versiona `thoughts/shared/`). Prove com `git check-ignore -v <artifactsDir>/x.png`; sem cobertura, acrescente a linha do caminho exato.

Com `method: skill:screen-verify`, garanta **também** a linha `.playwright-mcp/`: é o diretório de saída **default** do servidor, usado sempre que o `--output-dir` estiver ausente ou divergente — e screenshot de sessão autenticada não pode ficar a um `git add .` de distância do repositório. **Atenção**: só o `keelson.local.json` fica de fora; o `keelson.local.example.json` **é versionado** (não o adicione ao `.gitignore`).

Com `quality.e2e` preenchido (decisão 4.166), garanta a cobertura dos artefatos de execução do runner: no setup guiado (`/keelson:e2e-setup`) eles consolidam em `thoughts/e2e/` (decisão 4.168) — já sob a linha `thoughts/`, prove com `check-ignore`; config própria do projeto nos defaults do Playwright → linhas `test-results/` e `playwright-report/` (e o diretório do `storageState`, se houver). Os **specs** são código versionado; screenshot, trace e report de execução são transitórios e não entram no git.

## Etapa 6 — Self-check (falsificável, não confie na configuração)

A parte que o disco e o git provam sozinhos chega como **fato** (4.154): rode
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-selfcheck.sh" <raiz>` — bit de execução dos
hooks do plugin instalado, codePaths, binários
dos `quality.*`, matching real dos `sensitiveGlobs`, resolução/`reviewed`/`charter`
do perfil, `keelson.local.*` (versionamento, gitignore provado, placeholders),
`check-ignore` dos diretórios de artefato, flags efetivas do Playwright por escopo e
campos mínimos do Jira. Cada linha `falha`/`aviso` vira item do relatório. Exceção com
reparo imediato: `falha` em `hooks-executaveis` (hook sem `+x` falha em **silêncio** a
cada disparo — decisão 4.180) → aplique o `chmod +x` que a linha indica no cache do
plugin, declare no relatório que o reparo local **evapora no próximo update** e
recomende `/keelson:update` (a correção durável vem do próprio pacote). O que exige
MCP vivo continua seu, abaixo (runtime de browser respondendo; conector Jira com
chamada de prova). Prove o restante:
- `quality.test`/`quality.lint`/`quality.mutation`/`quality.e2e` declarados **existem/rodam** (execução rápida ou `--help`/dry-run — para mutação e E2E, nunca a rodada completa: são caros e pertencem ao `/keelson:integrate`; Playwright prova com `--list`, que enumera os specs sem subir a app);
- `quality.boot` declarado → o que ele invoca **existe no disco** (binário no PATH, compose file, script) — não suba a app aqui, prove só que o comando não é fantasia; campo ausente numa ficha antiga → complete com a pergunta da Etapa 2 (Regra de merge);
- os `codePaths` existem no disco;
- `sensitiveGlobs` **cobre os arquivos de segredo que existem no projeto** (decisão 4.71): enumere os candidatos em disco (`.env*` em **qualquer** nível — raiz inclusive —, `*.pem`/`*.key`, arquivos de credencial do projeto) e prove **por matching real** que cada um casa com algum glob — mesma régua da 4.51: inferir da leitura dos globs não vale (caso medido: ficha cobrindo os `.env*` de subdiretórios, `.env` da raiz descoberto). Candidato sem cobertura → acrescente o glob do caminho exato;
- os guidelines do perfil ativo resolvem: cada `profile.<role>.file` da ficha está **preenchido** e aponta para um arquivo existente (regra de resolução da Etapa 3; campo ausente é `✗` deste item — o `perfil-resolve` mecânico degrada em silêncio nesse caso, decisão 4.265); perfil com `reviewed: false` no front-matter vira instrução de revisão no relatório; perfil cujo `charter:` no front-matter é **menor** que a versão atual do `${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/QUALITY-CHARTER.md` vira aviso de re-derivação/revisão no relatório;
- se `screenVerify.enabled`: `keelson.local.example.json` existe e está **versionado** (sem senha real); `keelson.local.json` existe **e** está no `.gitignore` (confirme que **não** aparece em `git status`/`git ls-files`); campos ainda em placeholder (`<...>`) viram instrução de preenchimento no relatório (com o aviso dev-only); `artifactsDir` e `.playwright-mcp/` **provados** cobertos por `git check-ignore` (Etapa 5.5) — inferir da linha `thoughts/` não vale.
- se `method: skill:screen-verify`: o **runtime de browser responde** — ferramentas `mcp__playwright__*` carregadas (deferred não aparecem até serem buscadas) e uma navegação de prova barata (`browser_navigate` para `about:blank`, ou a `baseUrl` do realm default quando a app está de pé). Falhou → **não** é `✓` silencioso nem `✗` genérico: o relatório nomeia a causa (servidor não configurado · pacote não baixado · binário do navegador ausente · Node < 18) **e o comando exato** que resolve.
- se `method: skill:screen-verify`: as **flags efetivas** conferem (Etapa 4.4, passos 2–3). Responder não basta:
  - `--output-dir` ≠ `artifactsDir`, ou ausente → **`✗`** (os artefatos caem em `.playwright-mcp/`, fora do que a skill declara).
  - **mais de um realm** no `keelson.local.json` **e** servidor sem `--isolated` → **`✗`**, não aviso: o isolamento por realm que o gate promete não existe, e a verificação do segundo realm roda com a sessão do primeiro. Realm único → aviso basta.
  - O relatório diz **qual escopo respondeu** (projeto · pessoal · global), **em que modo** (headless × janela) e, quando há mais de uma entrada `playwright` configurada, quais são e qual vale — o humano não deveria precisar caçar isso.
- se `jira.enabled`: `jira.projectKey` e os IDs de `issueType.spec`/`issueType.task` estão preenchidos; se `issueType.feature`/`issueType.standalone` estão preenchidos, os IDs existem no projeto e **não** são `subtask:true`; se `jira.standaloneParent` está preenchido, a key existe (`getJiraIssue`) e é epic-level — senão aviso "Story avulsa nascerá sem pai", não `✗` (4.86); re-rodar o **guardrail de hierarquia** da Etapa 4.6 (perna não-adjacente → aviso com a sugestão, não `✗`); se `jira.mapFile` aponta um caminho, o arquivo existe **e o cabeçalho/prosa dele não contradiz a ficha** (ex.: o mapa afirma em texto corrido `transition: comment` com a ficha em `auto` — uma das duas está velha) → contradição vira aviso "mapa desatualizado — **a ficha vale**" (protocolo §3), nunca `✗`. Conector indisponível não é `✗` (best-effort) — vira aviso "sync Jira pulado até autorizar o conector", **com a evidência da prova** (protocolo §0: carregar as ferramentas — deferred não aparecem na lista até serem buscadas — e uma chamada de prova; "não vi as ferramentas" não é evidência).
Reporte cada item como ✓/✗. `✗` vira ação no relatório, não é silenciado.

## Etapa 7 — Relatório

Abra com o **veredito da adoção** (decisão 4.265): `Adoção: completa` somente quando o self-check da rodada não tem linha `falha` e nenhum `✗` dos itens LLM ficou sem reparo; senão `Adoção: incompleta — <item>: <ação exata>`. O veredito segura a declaração de pronto, nunca a emissão do relatório — recusa explícita do humano (ex.: optou por não gerar perfil) é estado declarado, não falha. No escopo `jira`, o veredito cobre só a fatia executada.

Resuma: o que foi **detectado**, o que foi **perguntado**, o perfil de cada camada (exemplar ou gerado), a contagem de pendências `⚠️ não confirmado` por perfil gerado (coletadas do companheiro `_review/<lang>-<versão>.md`), e o resultado do self-check. Se houver perfil `reviewed: false`, instrua: **revise-o antes do primeiro `/keelson:specify`**.

Inclua o **Retrato de maturidade** (decisão 4.243): esqueleto literal abaixo, uma linha por camada de assurance. Cada linha nasce do **campo lido da ficha ou da linha do self-check** — campo não conferido sai `não medido`, nunca composto de memória (4.237). É informação para o Diretor calibrar a autonomia que concede aos agentes; **nada aqui bloqueia** (opt-in segue opt-in).

```
Retrato de maturidade — o que sustenta a autonomia dos agentes neste projeto
- **Suíte de testes**: <quality.test provado | ausente → gate 1 sem prova mecânica; a evidência fica só no review>
- **Lint**: <quality.lint provado | ausente → erro estático depende do olho do reviewer>
- **Boot local**: <quality.boot provado | null escolhido → "app fora do ar" não é verificável (4.71)>
- **Verificação de tela**: <screenVerify + método | desabilitada → comportamento visual fica com o Diretor>
- **E2E**: <quality.e2e provado | ausente → gate 9 prova executando, mas sem regressão re-executável (opt-in: /keelson:e2e-setup)>
- **Mutação**: <quality.mutation provado | ausente → suíte verde é evidência mais fraca (opt-in: /keelson:mutation-setup)>
- **Invariantes do projeto**: <guidelines/project/invariants.md presente | ausente → gate 6 declara n/a (opt-in — 4.242)>
```

Feche com uma nota informativa de observabilidade (decisão 4.239 — **só informa, nunca grava config**): o report de fecho do ciclo já mede janela de contexto e custo por papel em tokens aproximados (hook `window-marker` + `scripts/context-cost.sh`); quem quiser número exato de tokens/custo por modelo tem a **exportação OTEL do Claude Code** — opt-in do harness via `CLAUDE_CODE_ENABLE_TELEMETRY=1` + endpoint OTLP próprio (métrica `claude_code.token.usage`). Configurar é ato do Diretor, fora do keelson: env de telemetria exporta dados de uso para o coletor que ele escolher (a régua "sem dado sensível em telemetria" de `core/SECURITY.md` vale para o destino).

## Config incremental (durante o uso)

Se, mais tarde, outro comando `/keelson:*` encontrar a ficha **incompleta ou ambígua** para o que precisa (ex.: `quality.build` ausente numa tarefa que builda), ele **pergunta na hora e oferece gravar a resposta na ficha** — em vez de perguntar sempre. A ficha se completa pelo uso.
