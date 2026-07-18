---
name: screen-verify
description: Verificação visual autenticada de telas em ambiente LOCAL de desenvolvimento — o gate `screenVerify` do keelson. Dirige um navegador para logar, navegar e exercitar um roteiro de verificação com evidência (screenshot/payload/estado). Lê os dados de acesso (URL, usuário, senha de DEV) do arquivo LOCAL não-versionado `keelson.local.json`. Ativar sempre que precisar subir/abrir a app, LOGAR e navegar/inspecionar uma tela com dados reais — caminhada visual, screenshot de mudança de UI, dark mode/estados vazios/drill-down, reprodução de bug de tela, ou fechar um HANDOFF de gate 9. Ativar TAMBÉM quando uma verificação de tela esbarrar em LOGIN: as credenciais de dev vivem no `keelson.local.json`. NUNCA usar em produção nem com contas reais.
---

# Skill: screen-verify

Você vai **autenticar e navegar** a aplicação do projeto em ambiente **local de
desenvolvimento** para verificar uma tela visualmente — o gate `screenVerify`. O **como**
(dirigir o browser, logar, exercitar) é genérico e está aqui; os **dados de acesso** (URL,
usuário, senha de dev) vêm do `keelson.local.json`; o **que** verificar vem do roteiro (um
`HANDOFF-*.md` ou o pedido do humano).

**Fronteira de segurança (não-negociável):** só ambiente **local**. Dados locais são
fictícios — logar localmente é seguro. **Nunca** aplique nada desta skill contra produção,
nem com conta real de usuário.

## Dados de acesso: `keelson.local.json` (LOCAL, não-versionado)

As credenciais e a URL de teste vêm do `keelson.local.json` na raiz do projeto — arquivo
**gitignored**, criado pelo `/keelson:init`. Estrutura esperada:

```jsonc
{
  "screenVerify": {
    "baseUrl": "http://localhost:<porta>/<base>/",
    "login": {
      "path": "/<rota-de-login>",
      "username": "<usuário/email de dev>",
      "password": "<senha de dev — só ambiente de testes>"
    }
  }
}
```

- **Arquivo ausente ou campo em branco** → **não invente credenciais nem URL**. Peça ao
  humano que rode `/keelson:init` (ou preencha o `keelson.local.json`), e **não** declare a
  verificação feita. "Não tenho as credenciais" nunca vira "está ok".
- **Nunca** ecoe a senha em log, relatório, screenshot de terminal ou mensagem. Use-a só no
  preenchimento do campo de login.

## Ferramentas: o browser MCP (`mcp__Claude_Browser__*`)

A verificação visual é feita pelas ferramentas do **Claude Browser** (navegador embutido,
com abas): sobem/abrem servidor, navegam, preenchem formulário, clicam, leem a página e
tiram screenshot.

| Objetivo | Ferramenta |
|----------|-----------|
| Abrir uma URL numa aba (sem subir server) | `preview_start` com `{url}` |
| Subir um dev server do `launch.json` | `preview_start` com `{name}` |
| Navegar / voltar / avançar | `navigate` (`{tabId, url}`) |
| Ler a página (árvore de acessibilidade, com `ref_N`) | `read_page` (`{tabId, filter:"interactive"|"all"}`) |
| Achar um elemento por linguagem natural | `find` (`{tabId, query}`) → devolve `ref_N` |
| Preencher um campo de formulário | `form_input` (`{tabId, ref, value}`) |
| Clicar / digitar / screenshot / scroll | `computer` (`{tabId, action, coordinate|ref|text}`) |
| Extrair o texto visível | `get_page_text` (`{tabId}`) |
| Rodar JS na página (debug/inspeção) | `javascript_tool` (`{tabId, action:"javascript_exec", text}`) |
| Erros de console | `read_console_messages` (`{tabId, onlyErrors:true}`) |
| Chamadas de rede (falhas / corpo de resposta) | `read_network_requests` (`{tabId, urlPattern|requestId}`) |
| Responsivo / dark mode | `resize_window` (`{tabId, preset:"mobile"|"tablet", colorScheme:"dark"}`) |
| Logs do server / parar server | `preview_logs` (`{serverId}`) / `preview_stop` (`{serverId}`) |

> **Não** use `claude-in-chrome`, `computer-use` nem `Bash` para dirigir o navegador — só as
> `mcp__Claude_Browser__*`. `Bash` continua válido para setup de ambiente/banco do projeto.

Quase toda ferramenta exige um **`tabId`**. O `preview_start` devolve um `tabId` e um
`serverId`; passe o `tabId` para `navigate`/`read_page`/`computer`/etc.

## 1. Subir/abrir o ambiente

Suba/abra a app pelo **método do projeto** (ver `guidelines/project/` e a ficha). No dia a
dia, se o server já está de pé, **não suba nada** — só abra uma aba:

```
preview_start { url: "<baseUrl do keelson.local.json>" }
```

O modo `{url}` apenas abre uma aba (não inicia server, não conflita com porta) e dirigi-la
não perturba o dev server. Confirme com `read_page`. Sem sessão, a app cai na tela de login.
Se nenhum server estiver rodando, suba pelo `launch.json`/método do projeto.

## 2. Login (parametrizado pelo `keelson.local.json`)

1. `read_page { tabId, filter: "interactive" }` na tela de login → pega os `ref_N` dos
   campos (usuário, senha, eventual "lembrar de mim", botão entrar).
2. `form_input { tabId, ref: <usuário>, value: <login.username> }`.
3. `form_input { tabId, ref: <senha>, value: <login.password> }`.
4. Se houver "lembrar de mim", marque para prolongar a sessão.
5. `computer { tabId, action: "left_click", ref: <botão entrar> }`.
6. Confirme o redirect com `read_page` (ou `javascript_tool` lendo `window.location.pathname`)
   — deve sair da rota de login.

A sessão costuma ser cookie httpOnly mantido pela aba entre navegações. Depois de logado,
vá à tela alvo com `navigate { tabId, url: "<baseUrl><rota>" }` e `read_page` para conferir.

## 3. Executar o roteiro (workflow de verificação)

Chegando à tela com dados reais, escolha os passos relevantes:
- `read_console_messages { tabId, onlyErrors:true }` e `preview_logs { serverId }` — erros de runtime/build.
- `read_network_requests { tabId, urlPattern }` — chamadas de API que falharam; `requestId` inspeciona o corpo.
- `read_page` / `get_page_text` — texto e estrutura (KPIs, listas, badges, estados vazios, presença/ausência de item).
- `javascript_tool` (`javascript_exec`) — valores de CSS concretos (cor, dark mode, espaçamento). Mais confiável que screenshot para cor/fonte.
- `computer` (`left_click`/`type`) — exercitar interação (drill-down, filtro) e reconfirmar com `read_page`.
- `resize_window { preset:"mobile"|"tablet" }` ou `{ colorScheme:"dark" }` — responsivo e tema escuro.
- `computer { action:"screenshot" }` — prova visual final.

Registre a evidência (screenshot/payload/o que foi visto) item a item — **nunca** "está ok"
sem prova. Ao fechar um `HANDOFF-*.md`, grave a evidência no próprio doc (`✅`/`❌`).

## 4. Regras de segurança (não-negociáveis)

- **Só ambiente local.** Nunca rode login programático, alteração de permissões, reset de
  senha ou aplicação de seed/fixture contra produção.
- **Nunca autentique com conta real** nem credenciais de produção — só o usuário de dev do
  `keelson.local.json`.
- **Credenciais só no `keelson.local.json`** (gitignored, dev-only e descartável). Não as
  copie para arquivos versionados, log ou relatório.
- Alterar permissões/senha, mesmo em dev, é **mudança sensível**: faça o mínimo para
  destravar a verificação e **diga ao humano o que alterou**.
- Detalhes de ambiente e de domínio do projeto (como subir os serviços, aplicar fixtures,
  pegadinhas de autorização) vivem em `guidelines/project/` — consulte-os quando o setup ou
  uma tela gated exigir.
