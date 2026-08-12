---
description: "Instala e configura a suíte E2E do projeto (Playwright) — gera config e smoke spec a partir da ficha, prova com --list e grava quality.e2e"
argument-hint: "[--dry-run]"
disable-model-invocation: true
---

# /keelson:e2e-setup

Você é um engenheiro de infraestrutura de testes. Sua função é deixar a suíte E2E (decisão 4.166) **pronta para receber specs** num projeto cujo Diretor não conhece a ferramenta: detectar runner existente, instalar o Playwright (com confirmação), gerar a configuração a partir do que a ficha já sabe, criar o primeiro spec de exemplo, **provar que o pipeline funciona** e gravar o comando em `quality.e2e`.

**Princípio inviolável**: nada é gravado na ficha sem prova de que roda (régua do `/keelson:init`, Etapa 6 — comando fantasia é pior que campo vazio). E os specs de AC **não nascem aqui**: eles são entregáveis do developer, task a task (4.166) — este comando prepara a infraestrutura e deixa um smoke de exemplo.

## Input

```
/keelson:e2e-setup [--dry-run]
```

| Flag | Uso |
|---|---|
| `--dry-run` | Mostra o que instalaria/gravaria, sem tocar em nada |

## Etapa 0: pré-checks

1. Ler `keelson.config.json` (profile, `gates.screenVerify`, `quality`). Sem ficha → parar e apontar `/keelson:init` primeiro.
2. Projeto **sem frontend** e `screenVerify` desligado → parar: não há tela que a suíte proveria; o gate de comportamento se satisfaz por teste/execução sem UI.
3. `quality.e2e` já preenchido → modo **reparo**: valide o comando existente (Etapa 5); roda → nada a fazer, reporte; quebrado → siga o fluxo para reconstruí-lo, declarando o motivo.
4. Instalação muda manifesto/lockfile: confira `git status` e **avise** se o working tree já está sujo (o Diretor vai querer separar o commit do setup do trabalho em curso).

## Etapa 1: detectar runner existente

- `@playwright/test` no `package.json` ou `playwright.config.*` — na raiz **ou no subdiretório do app** (onde a ficha aponta via `--prefix`/`cd`, decisão 4.172) → pule a Etapa 2 e reaproveite a config existente (confira só o alinhamento da Etapa 3: `outputDir` gitignored, `testDir` conhecido).
- **Outro runner E2E consolidado** (ex.: Cypress) → **não troque de motor por conta própria**: componha `quality.e2e` com o comando dele e diga no report que a receita de recorte por tag (`--grep`, 4.166) é do Playwright — o filtro equivalente é calibração do consumidor. Troca de motor é decisão do Diretor, não efeito colateral de setup.

## Etapa 2: instalar (sempre com confirmação)

Proponha e **espere o OK do Diretor** antes de instalar (dependência de projeto não entra em silêncio):

1. **Pré-requisito**: Node ≥ 18 e um `package.json`. O manifesto tem **três** estados, não dois (decisão 4.172): **na raiz** → use-o; **em subdiretório do app** (sinais que dispensam pergunta: `--prefix`/`cd` nos comandos `quality.*` da ficha, gitignore da raiz rejeitando `package-lock.json` de propósito) → instale **lá** e prefixe os caminhos das Etapas 3–4 de acordo; **nenhum** → proponha criar um mínimo na raiz (dev-only, com confirmação) — é assim que projetos não-Node adotam o Playwright. Criar manifesto na raiz quando o app já tem o seu instala um segundo ecossistema Node no repositório.
2. **Pacote**: `npm i -D @playwright/test` (ou o gerenciador detectado — `pnpm`/`yarn`).
3. **Binário do navegador**: `npx playwright install chromium` (Linux: `--with-deps`) — cache **do usuário**, fora do repositório (mesma nota do `/keelson:init`, Etapa 4.4); diga o que foi instalado e onde.

## Etapa 3: gerar a configuração

A partir da ficha, nunca de template cego — mostre o arquivo **antes** de escrever:

- **Runtime consolidado numa casa só** (decisão 4.168): todo artefato de execução vai
  para subpastas de **`thoughts/e2e/`** (na raiz do projeto — a mesma casa transitória
  do `thoughts/screen-verify/`), nunca três pastas soltas. App em subdiretório → o
  config vive no diretório do app e os caminhos apontam para o `thoughts/` da raiz
  (relativos ao config, ex.: `../thoughts/e2e/...`).
- `playwright.config.ts` (`.js` se o projeto não usa TS): `testDir: 'e2e'` ·
  `outputDir: '<thoughts>/e2e/test-results'` · reporter `html` com
  `outputFolder: '<thoughts>/e2e/report'` e `open: 'never'` · `baseURL` de
  `process.env.E2E_BASE_URL`, com comentário apontando a `baseUrl` do realm default do
  `keelson.local.json` como valor de dev — **URL e credencial nunca hardcoded no config
  versionado**.
- **Auth por realm** (se `screenVerify.realms` do `keelson.local.json` tem login): gere o esqueleto padrão do Playwright — setup project que loga e salva `storageState` por realm, lendo usuário/senha do `keelson.local.json` **em runtime** (arquivo gitignored); estado salvo em `<thoughts>/e2e/.auth/<realm>.json`. Um projeto por realm preserva o isolamento que a verificação de tela exige (skill `screen-verify`). O esqueleto nasce endurecido (4.169): os projects de setup — os únicos que digitam credencial — levam `trace: 'off'` e `screenshot: 'off'` (os demais mantêm o default); o nome do realm é validado como slug (`^[A-Za-z0-9_-]+$`, falhando fechado) antes de compor o caminho do `storageState`; e a leitura do `keelson.local.json` tem guarda própria — a mensagem do parser ecoa o conteúdo do arquivo de credencial e nunca é repassada.
- **Saída de execução é material sensível** (4.169): mesmo com captura desligada, falha de teste gera o contexto de erro do runner com snapshot da página — valor do campo de senha incluso. O destino gitignored é a contenção; a saída **nunca vira artefato publicado de CI** — deixe essa nota em comentário no config, onde quem for configurar CI vai ler.
- **`.gitignore`**: a linha `thoughts/` cobre a casa inteira — **prove** com `git check-ignore thoughts/e2e/x` (cobertura se verifica, não se infere — 4.51); sem cobertura, acrescente a linha. Spec é código versionado; artefato de execução e sessão, nunca.
- **Primeiro spec**: `e2e/smoke.spec.ts` — abre a `baseURL` e asserta um elemento estável da app. Serve de exemplo vivo da convenção de tags da 4.166 (comentário no arquivo: `@<slug>` por arquivo, `@AC-NNN-XXX` por teste — régua em `guidelines/core/TESTING.md`, "Specs E2E").

## Etapa 4: prova falsificável antes de gravar

1. **Existe**: `npx playwright --version` responde.
2. **O pipeline enumera**: `npx playwright test --list` lista o smoke sem subir a app.
3. **Rodada real só com app de pé**: sondagem barata na `baseUrl` (ex.: `curl -sI`); respondeu → rode o smoke de verdade; fora do ar → `--list` basta, **declarado** no report (nunca deixe de gravar por isso — a suíte completa pertence ao `/keelson:integrate`).
4. Falhou → nomeie a causa (Node < 18 · binário do navegador ausente · config errada) e **não grave** o comando; conserte ou reporte o bloqueio.

## Etapa 5: gate de segurança, gravar e reportar

1. **Gate 8 antes de gravar** (decisão 4.171): o diff deste comando é mudança sensível **por desenho** — instala dependência de terceiro e gera código que lê credencial e persiste sessão autenticada. Com `gates.security` ativo na ficha, despache o `security-engineer` sobre o diff do working tree (config, esqueleto de auth, manifesto) antes de gravar; achado crítico/alto → corrigir e re-verificar o delta (régua de convergência do `core/CODE-REVIEW.md`). Gate desativado na ficha → siga, **declarando no report** que o fecho não teve gate 8. Stop hook que cobre o mesmo terreno é rede de segurança, nunca o gate.
2. Gravar `quality.e2e` na ficha (merge-preserving — só esta chave), com o comando literal (ex.: `npx playwright test`).
3. Report: o que foi instalado (ou reaproveitado) · arquivos criados (config, smoke, auth) · resultado da prova · veredito do gate 8 (ou a declaração de ausência) · **próximo passo** (specs de AC nascem nas tasks — o developer os entrega, o qa os executa; recorte via `--grep "@AC-NNN-XXX"`) · lembrete de que manifesto/lockfile/config estão no working tree — **o commit do setup é ato do Diretor**.
4. `--dry-run`: imprime tudo acima sem instalar nem gravar.

## Limites

Não roda a regressão completa (isso é da entrega — `/keelson:integrate`), não escreve specs de AC (entregável do developer, task a task), não troca runner existente, não commita e não mexe em nenhuma outra chave da ficha.
