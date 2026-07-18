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

Use `Bash`/`Glob`/`Read` para inspecionar a raiz do projeto:

1. **Backend — linguagem e versão.** Procure o manifesto: `composer.json` (`require.php` → PHP + versão), `package.json` (Node — `engines.node`), `go.mod`, `pyproject.toml`/`requirements.txt`, `Gemfile`, `*.csproj`, `Cargo.toml`… Extraia `lang` e a **versão exata** (versão é primeira classe: PHP 5.6 ≠ 8.5).
2. **Frontend.** Há `package.json` com `vue`/`react`/`@angular/core`/`svelte`? Ou nenhum framework (front sem framework)? Ou não há frontend (API pura)?
3. **Comandos de qualidade.** Leia os `scripts` de `package.json` e/ou `composer.json` e infira `test`, `lint`, `typecheck`, `build`. Confirme a existência dos binários quando possível.
4. **Paths de código.** Heurística pelo layout (`src/`, `app/`, `lib/`, `apps/*`). Não invente — proponha o que existe.

## Etapa 2 — Perguntar só as lacunas

Para cada valor que **não** inferiu com confiança, pergunte com opções fechadas e o efeito explícito. Exemplos:
- *"Não encontrei frontend — confirma que é API-only?"* → **desliga** `gates.screenVerify` e o perfil de frontend.
- **Se há frontend** — *"Como este projeto verifica tela? Detectei a skill `<x>` / Playwright / preview MCP / outro"* → define `gates.screenVerify.method`. A skill embarcada **`screen-verify`** dirige o browser lendo os dados de acesso do `keelson.local.json` (método `skill:screen-verify`); se o projeto tem um método próprio, registre-o.
- *"Detectei o script `test` — usar `<comando>` como `quality.test`?"*
- *"O código de backend fica em `<path>`?"*

Não pergunte o que já sabe. Não faça perguntas de implementação que você mesmo pode resolver.

## Etapa 3 — Resolver o perfil de linguagem

Para backend e (se houver) frontend:
1. **Exemplar embarcado bate** (mesma `lang` e `version`; hoje: `php` @ `8.5`) → ative-o direto (`${CLAUDE_PLUGIN_ROOT}/guidelines/backend/php.md`).
2. **Mesma `lang`, versão diferente** (ex.: PHP 7.2) → invoque o agent **`profile-writer`** para **derivar** o perfil daquela versão a partir do exemplar (foco no que muda: recursos ausentes, sintaxe, runner). Destino: `guidelines/project/<role>/<lang>-<version>.md` **na raiz do projeto**, `reviewed: false`.
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

1. **`keelson.local.example.json`** — **VERSIONADO** (vai para o git). É o template do projeto: preencha `baseUrl`, rota de login e `username` com os valores **deste projeto**, e deixe `password` como placeholder (`<PREENCHER: ...>`). **Nunca** contém senha real. É o que viaja entre máquinas — noutro clone, copia-se ele para `keelson.local.json` e preenche-se só a senha.
2. **`keelson.local.json`** — **GITIGNORED** (nunca vai para o git): a cópia real, onde o humano põe a senha. **Garanta o `.gitignore` ANTES de criá-lo** (Etapa 5.5). Crie-o a partir do `.example` do projeto (se já existir) ou do template do plugin, com a senha em placeholder.

Regras:
- **Não escreva senha** você mesmo em nenhum dos dois. Deixe o placeholder e **instrua o humano** a preencher só o `keelson.local.json`, com credenciais de **DEV/teste descartáveis** — **nunca** produção nem conta real.
- **Merge-preserving** (Regra de merge): se o `keelson.local.json` já existe, **não o sobrescreva** — preserva a senha já preenchida e completa só campos ausentes. O `.example` pode ganhar campos novos, sempre **sem** senha.

## Etapa 5 — Injetar o bloco no `CLAUDE.md`

Insira o conteúdo de `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.keelson-block.md` no `CLAUDE.md` do projeto (crie o arquivo se não existir). Se um bloco keelson já existir (entre os marcadores `<!-- ... keelson ... -->`), **substitua-o** — não duplique.

## Etapa 5.5 — Garantir `thoughts/` fora do versionamento

Memos de exploração e backups do keelson vivem em `thoughts/local/` no projeto (nunca versionados). Garanta que o `.gitignore` do projeto contém `thoughts/` **e** `keelson.local.json` (dados de acesso locais — credenciais de dev, nunca versionadas) — adicione as linhas que faltarem. **Atenção**: só o `keelson.local.json` fica de fora; o `keelson.local.example.json` **é versionado** (não o adicione ao `.gitignore`).

## Etapa 6 — Self-check (falsificável, não confie na configuração)

Prove que a ficha funciona:
- `quality.test`/`quality.lint` declarados **existem/rodam** (execução rápida ou `--help`/dry-run);
- os `codePaths` existem no disco;
- os guidelines do perfil ativo resolvem: cada `profile.<role>.file` da ficha aponta para um arquivo existente (prefixo `plugin:` → `${CLAUDE_PLUGIN_ROOT}/guidelines/`; senão relativo à raiz do projeto); perfil com `reviewed: false` no front-matter vira instrução de revisão no relatório;
- se `screenVerify.enabled`: `keelson.local.example.json` existe e está **versionado** (sem senha real); `keelson.local.json` existe **e** está no `.gitignore` (confirme que **não** aparece em `git status`/`git ls-files`); campos ainda em placeholder (`<...>`) viram instrução de preenchimento no relatório (com o aviso dev-only).
Reporte cada item como ✓/✗. `✗` vira ação no relatório, não é silenciado.

## Etapa 7 — Relatório

Resuma: o que foi **detectado**, o que foi **perguntado**, o perfil de cada camada (exemplar ou gerado), a contagem de `⚠️ CONFIRMAR:` por perfil gerado, e o resultado do self-check. Se houver perfil `reviewed: false`, instrua: **revise-o antes do primeiro `/keelson:specify`**.

## Config incremental (durante o uso)

Se, mais tarde, outro comando `/keelson:*` encontrar a ficha **incompleta ou ambígua** para o que precisa (ex.: `quality.build` ausente numa tarefa que builda), ele **pergunta na hora e oferece gravar a resposta na ficha** — em vez de perguntar sempre. A ficha se completa pelo uso.
