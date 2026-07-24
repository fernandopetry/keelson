---
name: screen-verify
description: Gate `screenVerify`: verificação visual autenticada de telas em ambiente LOCAL. Ativar para subir a app, LOGAR e navegar/inspecionar uma tela — screenshot de UI, repro de bug de tela ou fechar um HANDOFF. Credenciais DEV em keelson.local.json.
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
**gitignored**, criado pelo `/keelson:init`. Um **realm** por área logada da aplicação
(ex.: `admin`, `portal`), cada um com sua URL, sua rota de login e seu usuário de dev:

```jsonc
{
  "screenVerify": {
    "realms": {
      "<nome-do-realm>": {
        "description": "<do que se trata este acesso — ex.: área administrativa>",
        "baseUrl": "http://localhost:<porta>/<base>/",
        "login": {
          "path": "/<rota-de-login>",
          "username": "<usuário/email de dev>",
          "password": "<senha de dev — só ambiente de testes>"
        }
      }
    },
    "defaultRealm": "<nome>"
  }
}
```

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
- Cada realm usa **aba própria** — **nunca** reaproveite a sessão de um realm (ex.: admin)
  para verificar tela de outro (ex.: portal), nem "para agilizar": isso mascara exatamente
  os bugs de autorização/isolamento que esta verificação existe para pegar.
- Item **negativo cross-realm** (ex.: "com a sessão do portal, acessar rota admin →
  esperado: negado") é roteiro legítimo: execute-o na aba do realm de **origem** da sessão.

## Ferramentas

Dirija o navegador **só** com as ferramentas do browser embutido (`mcp__Claude_Browser__*`)
— não use `claude-in-chrome`, `computer-use` nem `Bash` para isso (`Bash` continua válido
para setup de ambiente/banco do projeto).

## 1. Subir/abrir o ambiente

Suba/abra a app pelo **método do projeto** (ver `guidelines/project/` e a ficha). Se o
server já está de pé, **não suba nada** — só abra uma aba na `baseUrl` do **realm alvo**
(`preview_start {url}` abre a aba sem iniciar server nem conflitar com porta). Sem sessão,
a app cai na tela de login. Nenhum server rodando → suba pelo `launch.json`/método do
projeto.

## 2. Login

Na tela de login, preencha usuário e senha com os valores de `login` do **realm alvo**
(havendo "lembrar de mim", marque — prolonga a sessão), submeta e **confirme que saiu da
rota de login**. A sessão (cookie httpOnly) persiste na aba; navegue então à tela alvo
(`<baseUrl><rota>`). Roteiro que envolve **mais de um realm** → repita este passo em aba
própria para cada um, respeitando o isolamento acima.

## 3. Executar o roteiro (o que verificar)

Chegando à tela com dados reais, escolha os passos relevantes:
- Erros de console e logs do server — runtime/build quebrados.
- Chamadas de rede — APIs que falharam; inspecione o corpo da resposta quando importar.
- Texto e estrutura da página — KPIs, listas, badges, estados vazios, presença/ausência de item.
- JS na página para valores de CSS concretos (cor, dark mode, espaçamento) — mais confiável que screenshot para cor/fonte.
- Interação real (drill-down, filtro) reconfirmando o estado depois.
- Viewport mobile/tablet e tema escuro — responsivo e dark mode.
- Screenshot como prova visual final.

Registre a evidência (screenshot/payload/o que foi visto) item a item. Ao fechar um
`HANDOFF-*.md`, grave a evidência no próprio doc (`✅`/`❌`).

## 4. Regras de segurança (não-negociáveis)

Além da fronteira local-only e do sigilo da senha (acima): alterar permissões/senha, mesmo
em dev, é **mudança sensível** — faça o mínimo para destravar a verificação e **diga ao
humano o que alterou**. Detalhes de ambiente/domínio (subir serviços, fixtures, pegadinhas
de autorização) vivem em `guidelines/project/` — consulte-os quando o setup ou uma tela
gated exigir.
