---
name: screen-verify
description: Gate `screenVerify`: verificação visual autenticada em ambiente LOCAL via Playwright MCP (headless). Ativar para subir a app, LOGAR e inspecionar uma tela — screenshot, repro de bug ou fechar um HANDOFF. Credenciais DEV no keelson.local.json.
---

# Skill: screen-verify

Você vai **autenticar e navegar** a aplicação do projeto em ambiente **local de
desenvolvimento** para verificar uma tela — o gate `screenVerify`. Dados de acesso:
`keelson.local.json` (abaixo); o **que** verificar: o roteiro (um `HANDOFF-*.md` ou o pedido
do humano).

**Fronteira de segurança (não-negociável):** só ambiente **local**. Dados locais são
fictícios — logar localmente é seguro. **Nunca** aplique nada desta skill contra produção,
nem com conta real de usuário.

## Dados de acesso: `keelson.local.json` (LOCAL, não-versionado)

As credenciais e a URL de teste vêm do `keelson.local.json` na raiz do projeto — arquivo
**gitignored**, criado pelo `/keelson:init`. Um **realm** por área logada da aplicação
(ex.: `admin`, `portal`); chaves: `screenVerify.realms.<nome>.{baseUrl, login: {path,
username, password}}` + `screenVerify.defaultRealm` — o arquivo real é lido em runtime.

- **Formato flat legado** (`baseUrl` + `login` direto sob `screenVerify`, sem `realms`)
  segue válido: equivale a um único realm implícito.
- **Arquivo ausente ou campo em branco** → **não invente credenciais nem URL**. Peça ao
  humano que rode `/keelson:init` (ou preencha o `keelson.local.json`), e **não** declare a
  verificação feita. "Não tenho as credenciais" nunca vira "está ok".
- **Nunca** ecoe a senha em log, relatório, screenshot de terminal ou mensagem. Use-a só no
  preenchimento do campo de login.

### Seleção do realm

O realm alvo vem do item do roteiro (campo **Realm** do `HANDOFF-*.md`) ou do pedido do
humano. Na falta de indicação: realm único → use-o; vários → case a rota alvo com a
`baseUrl` **mais específica** que a contenha. **Rota que não casa com nenhum realm →
pergunte ao humano; nunca chute credencial** — logar com a conta errada mascara bug em vez
de revelar.

### Isolamento por realm (não-negociável)

- Credencial do realm X entra **só** no formulário de login do realm X.
- **Um realm por vez, com o browser fechado entre eles** (`browser_close`): abas do mesmo
  contexto **compartilham cookies**, então "aba própria" não isola nada. Reaproveitar a
  sessão de um realm (ex.: admin) para verificar tela de outro (ex.: portal) mascara
  exatamente os bugs de autorização/isolamento que esta verificação existe para pegar.
- Item **negativo cross-realm** (ex.: "com a sessão do portal, acessar rota admin →
  esperado: negado") é roteiro legítimo — e é a **única** exceção: execute-o **dentro** da
  sessão do realm de origem, sem fechar o browser antes.

## Ferramentas: Playwright MCP

Dirija o navegador **só** com as ferramentas do **Playwright MCP** (`mcp__playwright__*`) —
não use `mcp__Claude_Browser__*`, `claude-in-chrome` nem `computer-use` (`Bash` continua
válido para setup de ambiente/banco do projeto). As ferramentas MCP chegam **deferred**:
carregue-as antes de usar.

Servidor **ausente ou sem resposta** → isso é **indisponibilidade de runtime de browser**,
não "ambiente sem tela" genérico: siga o diagnóstico nomeado da sondagem
(`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/handoff-protocol.md`, §8.1) e diga o comando
exato de instalação. **Não** caia para outro browser em silêncio — método único é decisão
de projeto (decisão 4.49).

O modo do browser (**headless por padrão**), o navegador e o diretório de saída vivem na
configuração do servidor (`.mcp.json` do projeto ou escopo do usuário), escrita pelo
`/keelson:init` — **não** são ajustáveis em runtime. Precisa ver a janela para investigar?
Isso é reconfiguração, não improviso: rode `/keelson:init` de novo (ou tire o `--headless`
do `.mcp.json`) e diga isso ao humano.

## 1. Subir/abrir o ambiente

Suba/abra a app pelo **método do projeto** (ver `guidelines/project/` e a ficha). Se o
server já está de pé, **não suba nada** — navegue direto (`browser_navigate`) para a
`baseUrl` do **realm alvo**. Sem sessão, a app cai na tela de login. Nenhum server rodando →
suba pelo método do projeto e só então navegue.

**Identidade do código se prova, não se presume** (decisão 4.30): antes de confiar em
qualquer evidência, prove que o processo serve o código sob teste — path raiz do server,
SHA/marcador exposto, ou o efeito de uma mudança já commitada na branch.

## 2. Login

Tire um `browser_snapshot` da tela de login (é ele que dá os `ref` dos campos), preencha
usuário e senha com os valores de `login` do **realm alvo** via `browser_fill_form`
(havendo "lembrar de mim", marque — prolonga a sessão), submeta e **confirme que saiu da
rota de login**. A sessão (cookie httpOnly) persiste no contexto; navegue então à tela alvo
(`<baseUrl><rota>`). Roteiro com **mais de um realm** → conclua um realm, `browser_close`,
e recomece o login no próximo, respeitando o isolamento acima.

## 3. Executar o roteiro (o que verificar)

Chegando à tela com dados reais, escolha os passos relevantes:
- **Erros de console** (`browser_console_messages`, `level: "error"`) e logs do server —
  runtime/build quebrados. Sem `all: true` você vê só o que ocorreu desde a última
  navegação; para o carregamento inteiro da sessão, passe `all: true`.
- **Chamadas de rede** (`browser_network_requests`, `filter` por rota de API) — APIs que
  falharam; `browser_network_request` traz o corpo quando importar.
- **Texto e estrutura** (`browser_snapshot`) — KPIs, listas, badges, estados vazios,
  presença/ausência de item. O snapshot de acessibilidade é mais confiável que o screenshot
  para conferir conteúdo, e é o que dá os `ref` para interagir.
- **JS na página** (`browser_evaluate`) para valores de CSS concretos (cor, dark mode,
  espaçamento) — mais confiável que screenshot para cor/fonte.
- **Interação real** (`browser_click`, `browser_type`, `browser_select_option`) reconfirmando
  o estado depois; `browser_wait_for` em vez de presumir que já renderizou.
- **Viewport mobile/tablet e tema escuro** (`browser_resize`) — responsivo e dark mode.
- **Screenshot** (`browser_take_screenshot`) como prova visual final.

Registre a evidência item a item. Ao fechar um `HANDOFF-*.md`, grave a evidência no próprio
doc (`✅`/`❌`).

### Artefatos: `thoughts/screen-verify/<slug>/`

Screenshot, dump de console e dump de rede são gravados em **arquivo**, na pasta de
artefatos do gate — `gates.screenVerify.artifactsDir` da ficha (default
`thoughts/screen-verify`), que é o `--output-dir` do servidor. `thoughts/` é **gitignored**:
esses arquivos são material transitório para o desenvolvedor, nunca vão para o git.

- **Caminho relativo, organizado por slug e artefato**: passe `filename` nas chamadas —
  `"<slug>/<PLAN-MMM|yyyy-mm-dd-descrição>/<item>-<o-que-é>.png"` (ex.:
  `"professional-portal/PLAN-003/V1-dashboard-vazio.png"`). Nome falante, não o
  `page-{timestamp}` default. `browser_console_messages` e `browser_network_requests`
  aceitam `filename` do mesmo jeito — use quando o dump for longo demais para o report.
- **Registre o caminho que a ferramenta devolveu**, não o que você pediu: se o servidor
  estiver com outro `--output-dir`, o arquivo caiu em outro lugar e o report tem que dizer
  onde. Arquivo em **`.playwright-mcp/`** é o sinal de que o servidor está sem
  `--output-dir` — reporte como config divergente (`/keelson:init` conserta), porque essa
  pasta pode não estar coberta pelo `.gitignore` do projeto.
- **O arquivo nunca é a prova.** A prova durável é o **texto**: o que foi observado, no
  HANDOFF e no INDEX. O artefato é conveniência local — um clone limpo não o tem, e a
  verificação precisa continuar de pé sem ele (decisões 4.26/4.46).
- Screenshot de tela logada pode conter dado de dev: **nunca** capture a tela com o campo de
  senha preenchido e visível.

### Armadilhas (cheque ANTES de diagnosticar "bug")

Sintomas de ambiente que imitam bug de UI:

- **Estado de transição** se confere no **DOM** (posição/opacity computados via
  `browser_evaluate`), não no screenshot — a captura pode pegar o meio da animação. Use
  `browser_wait_for` para o estado estável antes de capturar.
- **Viewport implícito**: sem `browser_resize`, você mede no tamanho default do servidor
  (`--viewport-size`), que pode não ser o que o roteiro assume. Dimensione explicitamente
  antes de qualquer afirmação sobre layout ou breakpoint.
- **Console e rede são por navegação** por padrão: `browser_console_messages` sem
  `all: true` e `browser_network_requests` mostram o que veio **desde a última navegação** —
  um erro de boot desaparece depois que você navegou para outra rota. Colete antes de sair
  da tela, ou peça `all: true`.
- **Recurso externo bloqueado** (fonte, CDN) por `--allowed-origins`/`--blocked-origins` na
  config do servidor aparece como falha visual da app. Antes de abrir bug de estilo, cheque
  a rede: requisição bloqueada não é bug do código.

Um sintoma desses só vira bug depois de re-medido com o estado estável e o viewport são.

## 4. Regras de segurança (não-negociáveis)

Além da fronteira local-only e do sigilo da senha (acima): alterar permissões/senha, mesmo
em dev, é **mudança sensível** — faça o mínimo para destravar a verificação e **diga ao
humano o que alterou**. Detalhes de ambiente/domínio (subir serviços, fixtures, pegadinhas
de autorização) vivem em `guidelines/project/` — consulte-os quando o setup ou uma tela
gated exigir.
