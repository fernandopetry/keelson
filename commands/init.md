---
description: Configura ou repara a adoção do keelson num projeto — detecta a stack, escreve a ficha (keelson.config.json), resolve o perfil de linguagem e injeta o bloco no CLAUDE.md
---

# /keelson:init

Você configura (ou repara) a adoção do **keelson** num projeto. Seu trabalho é **detectar o máximo, perguntar o mínimo**, e deixar o projeto pronto para o ciclo `/keelson:specify → :plan → :tasks → :implement`.

**Princípio**: as perguntas que você faz são **decisões de produto** (tem frontend? qual o comando de teste?), nunca "digite este glob". Detecte o que der; pergunte só o que não conseguir inferir, sempre explicando o **efeito** da escolha.

**Idempotente e preservador**: rodar de novo **completa e repara, nunca destrói**. Preserva tudo o que o humano personalizou (valores da ficha, perfis revisados, o `keelson.local.json`) e **só acrescenta o que falta** — inclusive campos e arquivos que uma versão mais nova do keelson passou a exigir. Por isso **atualizar o plugin e rodar `/keelson:init` de novo é o caminho de migração de versão**: o projeto ganha o que a versão nova trouxe sem perder o que já era seu. Ver a **Regra de merge** abaixo.

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

## Etapa 1 — Detecção (não pergunte o que dá para inferir)

Inspecione a raiz do projeto:

1. **Backend — linguagem e versão.** Procure o manifesto: `composer.json` (`require.php` → PHP + versão), `package.json` (Node — `engines.node`), `go.mod`, `pyproject.toml`/`requirements.txt`, `Gemfile`, `*.csproj`, `Cargo.toml`… Extraia `lang` e a **versão exata** (versão é primeira classe: PHP 5.6 ≠ 8.5).
2. **Frontend.** Há `package.json` com `vue`/`react`/`@angular/core`/`svelte`? Ou nenhum framework (front sem framework)? Ou não há frontend (API pura)?
3. **Comandos de qualidade.** Leia os `scripts` de `package.json` e/ou `composer.json` e infira `test`, `lint`, `typecheck`, `build`. Confirme a existência dos binários quando possível.
4. **Paths de código.** Heurística pelo layout (`src/`, `app/`, `lib/`, `apps/*`). Não invente — proponha o que existe.

## Etapa 2 — Perguntar só as lacunas

Para cada valor que **não** inferiu com confiança, pergunte com opções fechadas e o efeito explícito. Exemplos:
- *"Não encontrei frontend — confirma que é API-only?"* → **desliga** `gates.screenVerify` e o perfil de frontend.
- **Se há frontend** — *"Como este projeto verifica tela? Detectei a skill `<x>` / Playwright / preview MCP / outro"* → define `gates.screenVerify.method`. A skill embarcada **`screen-verify`** dirige o browser lendo os dados de acesso do `keelson.local.json` (método `skill:screen-verify`); se o projeto tem um método próprio, registre-o.
- **Se há frontend** — *"Quantas áreas logadas (realms) a aplicação tem?"* — ex.: só a admin; ou admin **+** portal de usuários finais, com URL e usuário distintos. Cada realm vira uma entrada em `screenVerify.realms` do `keelson.local.json` (Etapa 4.5), com `description` dizendo do que se trata o acesso, `baseUrl`, rota de login e usuário de dev próprios.
- *"Detectei o script `test` — usar `<comando>` como `quality.test`?"*
- *"O código de backend fica em `<path>`?"*

Não pergunte o que já sabe. Não faça perguntas de implementação que você mesmo pode resolver.

## Etapa 3 — Resolver o perfil de linguagem

Para backend e (se houver) frontend:
1. **Perfil embarcado bate exato** (mesma `lang` e `version`) → ative-o direto. Embarcados hoje: `php` @ `8.5` (exemplar, `${CLAUDE_PLUGIN_ROOT}/guidelines/backend/php.md`) e a **escada legada** `php` @ `5.6` / `7.0` / `7.4` / `8.0` (`${CLAUDE_PLUGIN_ROOT}/guidelines/backend/php-<versão>.md`).
2. **Mesma `lang`, versão sem perfil exato** (ex.: PHP 7.3) → a **base é o perfil embarcado mais próximo ABAIXO** da versão do projeto (7.3 → base `php-7.0.md`; 8.3 → base `php-8.0.md`). Invoque o agent **`profile-writer`** passando essa base para **derivar** o perfil escrevendo o **delta**: recursos que a versão do projeto adiciona à base, sintaxe, runner/ferramentas. **Nunca derive de versão maior** — perfil recomenda recursos, e base maior recomenda o que não existe na versão do projeto (passa no lint, quebra em runtime). Se não houver embarcado abaixo (ex.: PHP 5.4), gere do zero usando o mais próximo acima **apenas** como referência de formato/rigor, nunca como fonte de recomendação de recurso. Destino: `guidelines/project/<role>/<lang>-<version>.md` **na raiz do projeto**, `reviewed: false`.
3. **Sem exemplar para a `lang`** (ex.: Node, React, Angular) → ofereça **gerar do zero** via `profile-writer`, aplicando o `QUALITY-CHARTER` no mesmo padrão do exemplar PHP. Destino idem, `reviewed: false`.

Em todos os casos, **grave o caminho resolvido no campo `profile.<role>.file` da ficha**: prefixo `plugin:` para exemplar embarcado (ex.: `plugin:backend/php.md`, resolvido em `${CLAUDE_PLUGIN_ROOT}/guidelines/`); caminho relativo à raiz do projeto para perfil gerado (ex.: `guidelines/project/backend/node-20.md`). É esse campo que os demais comandos usam para carregar o perfil.

Perfis gerados nascem **pendentes de revisão** e podem trazer marcas `⚠️ CONFIRMAR:` — colete-as para o relatório.

## Etapa 4 — Escrever a ficha `keelson.config.json`

Parta de `${CLAUDE_PLUGIN_ROOT}/templates/keelson.config.example.json` e preencha com os valores resolvidos: `profile` (backend/frontend com `lang`+`version`+`file` da Etapa 3), `codePaths`, `sensitiveGlobs`, `quality`, `docsRoot`, e `gates`:
- `security` (bool);
- `screenVerify` = objeto `{ "enabled": <há frontend?>, "method": <o da Etapa 2, ex. "skill:screen-verify"> }`. (Aceita também o atalho booleano `true`/`false` = `{enabled, method:null}`.)

Grave na raiz do projeto. **Se a ficha já existe**, aplique a **Regra de merge**: carregue a atual, preserve os valores personalizados e complete só os campos ausentes (ex.: migrar um `screenVerify` booleano antigo para o objeto `{enabled, method}` mantendo o valor) — não reescreva por cima.

## Etapa 4.5 — Dados de acesso locais para verificação de tela (só se `screenVerify.enabled`)

Se `gates.screenVerify.enabled` é `true` e o método precisa de credenciais (ex.: a skill `screen-verify`), a verificação exige URL + login de **desenvolvimento**. Produza **dois arquivos** na raiz (padrão `.env` / `.env.example`):

1. **`keelson.local.example.json`** — **VERSIONADO** (vai para o git). É o template do projeto: preencha `screenVerify.realms` — **um realm por área logada** identificada na Etapa 2 (ex.: `admin`, `portal`), cada um com `description` (do que se trata o acesso), `baseUrl`, rota de login e `username` **deste projeto** — e deixe cada `password` como placeholder (`<PREENCHER: ...>`). **Nunca** contém senha real. É o que viaja entre máquinas — noutro clone, copia-se ele para `keelson.local.json` e preenchem-se só as senhas.
2. **`keelson.local.json`** — **GITIGNORED** (nunca vai para o git): a cópia real, onde o humano põe a senha. **Garanta o `.gitignore` ANTES de criá-lo** (Etapa 5.5). Crie-o a partir do `.example` do projeto (se já existir) ou do template do plugin, com a senha em placeholder.

Regras:
- **Não escreva senha** você mesmo em nenhum dos dois. Deixe o placeholder e **instrua o humano** a preencher só o `keelson.local.json`, com credenciais de **DEV/teste descartáveis** — **nunca** produção nem conta real.
- **Merge-preserving** (Regra de merge): se o `keelson.local.json` já existe, **não o sobrescreva** — preserva a senha já preenchida e completa só campos ausentes. O `.example` pode ganhar campos novos, sempre **sem** senha.
- **Migração flat → realms**: arquivo antigo no formato flat (`baseUrl` + `login` direto sob `screenVerify`) → migre para `realms` **preservando os valores** (vira o realm único, nomeado pelo que ele é — ex.: `admin` — com `defaultRealm` apontando para ele). O flat segue aceito em runtime; o `.example` novo já nasce em `realms`.

## Etapa 4.6 — Integração com Jira (opcional, best-effort)

Ofereça a integração keelson↔Jira apenas se fizer sentido para o projeto (o time usa Jira como quadro). **Não é obrigatória** e nasce **desligada** (`jira.enabled: false`) — pule sem cerimônia se o humano não quiser. Toda a mecânica de runtime vive no **protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`); aqui você só **descobre e grava a config**, nunca embarca dado de empresa no plugin.

Se o humano optar por ligar (requer o **conector Atlassian** autorizado — sem ele, avise e deixe `enabled:false`):

1. **Perguntas de produto** (opções fechadas): `site` (hostname Atlassian), `projectKey`, e `mode` — `create` (o keelson cria a issue da SPEC + sub-tasks; ideal para projeto limpo/team-managed) ou `link` (pendura numa issue existente; ideal para projeto governado/company-managed).
2. **Resolver por descoberta** (protocolo §1, sempre por **ID**, nunca por nome): `getAccessibleAtlassianResources`/`site` → `cloudId`; `getJiraProjectIssueTypesMetadata` → escolher `issueType.spec` e `issueType.task` (se houver mais de um tipo de sub-task, **pergunte** qual); confirmar que `issueType.task` é `subtask:true` (senão, avise o fallback para issue linkada — §7). **Se o humano quiser a hierarquia de 3 níveis** (Epic ▸ Story de funcionalidade ▸ sub-task — só faz sentido quando as SPECs declaram FEATs): identificar via `hierarchyLevel` o tipo epic-level para `issueType.spec` e o tipo standard (Story) para `issueType.feature`; se a hierarquia do projeto não fecha (spec não-epic), avise a escada de degradação (Stories linkadas, não filhas — §6.1). Não querer → `issueType.feature: null` e nada muda.
3. **Status/transição**: `getJiraIssueTypeMetaWithFields` + amostragem de status (`searchJiraIssuesUsingJql`/`getTransitionsForJiraIssue`) para conhecer o workflow. Default seguro `transition:comment` (não move card); só proponha `auto` se houver caminho de transição claro.
4. **Gerar o esqueleto do mapa `.md`** em `{docsRoot}/_meta/jira.<PROJECT>.md` e apontar `jira.mapFile` para ele. Duas seções (protocolo §3): **Campos** (uma linha por campo relevante do createmeta — `ID | Nome | Tipo | Direção | Estratégia | Valor` — com `allowedValues` como referência em comentário; o humano preenche Direção/Estratégia/Valor) e **Etapas/Colunas** (`Etapa | Coluna | Status-alvo (ID) | Gatilho`, pré-preenchida por `statusCategory` — semear também a linha `Funcionalidade pronta p/ QA | <coluna> | <status-id> | todas as TASKs da FEAT Done`, comentada quando `issueType.feature: null`). Avise que o `.md` pode conter nomes de pessoas (via `allowedValues`) — é config de projeto, versionável, **não segredo**.
5. **Gravar o bloco `jira`** na ficha (campos por ID). **Nenhum token/segredo** — o conector é o único canal; nada vai para `keelson.local.json`.

Merge-preserving (Regra de merge): bloco `jira` já presente → preserva; ficha antiga sem o bloco → acrescenta com `enabled:false`; bloco presente sem `issueType.feature` → acrescenta `feature: null` sem tocar no resto; map file antigo sem o gatilho "Funcionalidade pronta p/ QA" → linha adicionada como sugestão comentada, nunca sobrescrevendo a tabela do humano.

## Etapa 5 — Injetar o bloco no `CLAUDE.md`

Insira o conteúdo de `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.keelson-block.md` no `CLAUDE.md` do projeto (crie o arquivo se não existir). Se um bloco keelson já existir (entre os marcadores `<!-- ... keelson ... -->`), **substitua-o** — não duplique.

## Etapa 5.5 — Garantir `thoughts/` fora do versionamento

Memos de exploração e backups do keelson vivem em `thoughts/local/` no projeto (nunca versionados). Garanta que o `.gitignore` do projeto contém `thoughts/` **e** `keelson.local.json` (dados de acesso locais — credenciais de dev, nunca versionadas) — adicione as linhas que faltarem. **Atenção**: só o `keelson.local.json` fica de fora; o `keelson.local.example.json` **é versionado** (não o adicione ao `.gitignore`).

## Etapa 6 — Self-check (falsificável, não confie na configuração)

Prove que a ficha funciona:
- `quality.test`/`quality.lint` declarados **existem/rodam** (execução rápida ou `--help`/dry-run);
- os `codePaths` existem no disco;
- os guidelines do perfil ativo resolvem: cada `profile.<role>.file` da ficha aponta para um arquivo existente (regra de resolução da Etapa 3); perfil com `reviewed: false` no front-matter vira instrução de revisão no relatório; perfil cujo `charter:` no front-matter é **menor** que a versão atual do `${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/QUALITY-CHARTER.md` vira aviso de re-derivação/revisão no relatório (o perfil instancia doutrina desatualizada);
- se `screenVerify.enabled`: `keelson.local.example.json` existe e está **versionado** (sem senha real); `keelson.local.json` existe **e** está no `.gitignore` (confirme que **não** aparece em `git status`/`git ls-files`); campos ainda em placeholder (`<...>`) viram instrução de preenchimento no relatório (com o aviso dev-only).
- se `jira.enabled`: `jira.projectKey` e os IDs de `issueType.spec`/`issueType.task` estão preenchidos; se `issueType.feature` está preenchido, o ID existe no projeto e **não** é `subtask:true`; se `jira.mapFile` aponta um caminho, o arquivo existe. Conector indisponível não é `✗` (best-effort) — vira aviso "sync Jira pulado até autorizar o conector".
Reporte cada item como ✓/✗. `✗` vira ação no relatório, não é silenciado.

## Etapa 7 — Relatório

Resuma: o que foi **detectado**, o que foi **perguntado**, o perfil de cada camada (exemplar ou gerado), a contagem de `⚠️ CONFIRMAR:` por perfil gerado, e o resultado do self-check. Se houver perfil `reviewed: false`, instrua: **revise-o antes do primeiro `/keelson:specify`**.

## Config incremental (durante o uso)

Se, mais tarde, outro comando `/keelson:*` encontrar a ficha **incompleta ou ambígua** para o que precisa (ex.: `quality.build` ausente numa tarefa que builda), ele **pergunta na hora e oferece gravar a resposta na ficha** — em vez de perguntar sempre. A ficha se completa pelo uso.
