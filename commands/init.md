# /keelson:init

Você configura (ou repara) a adoção do **keelson** num projeto. Seu trabalho é **detectar o máximo, perguntar o mínimo**, e deixar o projeto pronto para o ciclo `/keelson:specify → :plan → :tasks → :implement`.

**Princípio**: as perguntas que você faz são **decisões de produto** (tem frontend? qual o comando de teste?), nunca "digite este glob". Detecte o que der; pergunte só o que não conseguir inferir, sempre explicando o **efeito** da escolha.

**Idempotente**: rodar de novo **reconfigura/repara** — relê o que existe, corrige a ficha, refaz o self-check. Serve tanto para a primeira configuração quanto para revalidar/consertar uma existente.

## Resultado esperado

Ao final existem, no projeto:
- `keelson.config.json` na raiz (a ficha) — preenchida e validada;
- um perfil de linguagem ativo (exemplar embarcado **ou** gerado e pendente de revisão);
- o bloco gerenciado do keelson no `CLAUDE.md`;
- um relatório do que foi detectado, perguntado e o que falta revisar.

## Etapa 1 — Detecção (não pergunte o que dá para inferir)

Use `Bash`/`Glob`/`Read` para inspecionar a raiz do projeto:

1. **Backend — linguagem e versão.** Procure o manifesto: `composer.json` (`require.php` → PHP + versão), `package.json` (Node — `engines.node`), `go.mod`, `pyproject.toml`/`requirements.txt`, `Gemfile`, `*.csproj`, `Cargo.toml`… Extraia `lang` e a **versão exata** (versão é primeira classe: PHP 5.6 ≠ 8.5).
2. **Frontend.** Há `package.json` com `vue`/`react`/`@angular/core`/`svelte`? Ou nenhum framework (front sem framework)? Ou não há frontend (API pura)?
3. **Comandos de qualidade.** Leia os `scripts` de `package.json` e/ou `composer.json` e infira `test`, `lint`, `typecheck`, `build`. Confirme a existência dos binários quando possível.
4. **Paths de código.** Heurística pelo layout (`src/`, `app/`, `lib/`, `apps/*`). Não invente — proponha o que existe.

## Etapa 2 — Perguntar só as lacunas

Para cada valor que **não** inferiu com confiança, pergunte com opções fechadas e o efeito explícito. Exemplos:
- *"Não encontrei frontend — confirma que é API-only?"* → **desliga** `gates.screenVerify` e o perfil de frontend.
- *"Detectei o script `test` — usar `<comando>` como `quality.test`?"*
- *"O código de backend fica em `<path>`?"*

Não pergunte o que já sabe. Não faça perguntas de implementação que você mesmo pode resolver.

## Etapa 3 — Resolver o perfil de linguagem

Para backend e (se houver) frontend:
1. **Exemplar embarcado bate** (mesma `lang` e `version`; hoje: `php` @ `8.5`) → ative-o direto (`guidelines/backend/php.md`).
2. **Mesma `lang`, versão diferente** (ex.: PHP 7.2) → invoque o agent **`profile-writer`** para **derivar** o perfil daquela versão a partir do exemplar (foco no que muda: recursos ausentes, sintaxe, runner). Destino: `guidelines/project/<role>/<lang>-<version>.md`, `reviewed: false`.
3. **Sem exemplar para a `lang`** (ex.: Node, React, Angular) → ofereça **gerar do zero** via `profile-writer`, aplicando o `QUALITY-CHARTER` no mesmo padrão do exemplar PHP. Destino idem, `reviewed: false`.

Perfis gerados nascem **pendentes de revisão** e podem trazer marcas `⚠️ CONFIRMAR:` — colete-as para o relatório.

## Etapa 4 — Escrever a ficha `keelson.config.json`

Parta de `templates/keelson.config.example.json` e preencha com os valores resolvidos: `profile` (backend/frontend com `lang`+`version`), `codePaths`, `sensitiveGlobs`, `quality`, `gates` (ex.: `screenVerify` = há frontend?), `docsRoot`. Grave na raiz do projeto.

## Etapa 5 — Injetar o bloco no `CLAUDE.md`

Insira o conteúdo de `templates/CLAUDE.keelson-block.md` no `CLAUDE.md` do projeto (crie o arquivo se não existir). Se um bloco keelson já existir (entre os marcadores `<!-- ... keelson ... -->`), **substitua-o** — não duplique.

## Etapa 6 — Self-check (falsificável, não confie na configuração)

Prove que a ficha funciona:
- `quality.test`/`quality.lint` declarados **existem/rodam** (execução rápida ou `--help`/dry-run);
- os `codePaths` existem no disco;
- os guidelines do perfil ativo resolvem (arquivos presentes).
Reporte cada item como ✓/✗. `✗` vira ação no relatório, não é silenciado.

## Etapa 7 — Relatório

Resuma: o que foi **detectado**, o que foi **perguntado**, o perfil de cada camada (exemplar ou gerado), a contagem de `⚠️ CONFIRMAR:` por perfil gerado, e o resultado do self-check. Se houver perfil `reviewed: false`, instrua: **revise-o antes do primeiro `/keelson:specify`**.

## Config incremental (durante o uso)

Se, mais tarde, outro comando `/keelson:*` encontrar a ficha **incompleta ou ambígua** para o que precisa (ex.: `quality.build` ausente numa tarefa que builda), ele **pergunta na hora e oferece gravar a resposta na ficha** — em vez de perguntar sempre. A ficha se completa pelo uso.
