# Instalação e atualização

## Pré-requisitos

| Requisito | Por quê |
|---|---|
| **Claude Code** (CLI, app desktop, web ou extensão de IDE) | O keelson é um plugin do Claude Code — comandos, agents e skills rodam dentro dele |
| **Git** e um repositório | Todo o ciclo produz branch e commits; vários hooks leem o estado do git |
| **Node.js ≥ 18** *(opcional)* | Só para o gate de verificação de tela ([`gates.screenVerify`](Ficha-do-projeto)), que roda via Playwright MCP |

Nada além disso é obrigatório. O keelson **não instala runtime nem dependência** no seu
projeto: o que falta é reportado como pendência nomeada, nunca contornado em silêncio.

## Instalar

No Claude Code:

```
/plugin marketplace add fernandopetry/keelson
/plugin install keelson@keelson
```

Reinicie a sessão depois de instalar, para que os comandos `/keelson:*` sejam carregados.

## Configurar no projeto

Dentro do repositório onde você vai trabalhar:

```
/keelson:init
```

O `init` **detecta o que consegue** (linguagem, versão, comandos de teste e lint,
existência de frontend) e **só pergunta o que não dá para inferir**. Ao final ele escreve:

- `keelson.config.json` — a [ficha do projeto](Ficha-do-projeto), versionada no repositório;
- um bloco gerenciado no `CLAUDE.md` do projeto, que ensina o Claude a operar pelo keelson;
- `keelson.local.json` *(quando necessário)* — credenciais de ambiente local; **não** vai para o git.

Quando a sua stack não tem perfil embarcado, o `init` oferece **gerar um** a partir do
[Quality Charter](Quality-Charter), na mesma régua do perfil PHP de referência. O perfil
nasce `reviewed: false` até você revisar e assinar embaixo.

## Atualizar

Atualizar o marketplace **não** atualiza o plugin instalado — são dois passos, nesta ordem:

```
/plugin marketplace update keelson
/plugin update keelson
```

Ou, em um comando só:

```
/keelson:update
```

Ele roda os dois passos na ordem certa, mostra a versão antes e depois e aborta se o
refresh do marketplace falhar (seguir com cache velho reportaria "já atualizado" sem estar).

> **O update não vale para a sessão corrente.** A CLI exige reiniciar a sessão do Claude
> Code para carregar a versão nova.

## Depois de atualizar: re-rodar o `init`

Algumas versões mudam o bloco injetado no `CLAUDE.md` ou acrescentam campos na ficha. O
CHANGELOG avisa quando é o caso, com a frase **"re-run `/keelson:init`"**. Rodar de novo é
seguro e idempotente: o `init` preserva o que você já configurou e só completa o que falta.

## Desinstalar

Abra o gerenciador de plugins com `/plugin` e remova o `keelson@keelson` por lá.

O `keelson.config.json`, o bloco no `CLAUDE.md` e os artefatos em `docs/` continuam no
repositório — são seus. Remova-os à mão se quiser apagar o rastro.

## Verificar se está tudo certo

| Checagem | O que esperar |
|---|---|
| Digite `/keelson:` no prompt | A lista de comandos aparece no autocomplete |
| `/keelson:status <slug>` | Resumo do slug, ou aviso de que ele não existe |
| Existe `keelson.config.json` na raiz? | Se não, rode `/keelson:init` |

Deu errado? Veja [Solução de problemas](Solucao-de-problemas).
