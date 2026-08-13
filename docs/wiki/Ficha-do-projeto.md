# A ficha do projeto (`keelson.config.json`)

A **ficha** é o adaptador entre o motor genérico do keelson e o seu projeto. Ela é escrita
pelo `/keelson:init`, fica na raiz do repositório e **é versionada** — é configuração do
time, não preferência individual.

Todo comando `/keelson:*` lê a ficha antes de qualquer outra coisa. Caminho ou comando
fixo nunca é assumido: se não está na ficha, o keelson pergunta ou reporta pendência.

## A ficha completa

```jsonc
{
  "profile": {
    "backend":  { "lang": "php",  "version": "8.5", "file": "plugin:backend/php.md" },
    "frontend": { "lang": "none", "version": null,  "file": "plugin:frontend/none.md" }
  },
  "codePaths": { "backend": ["src"], "frontend": [] },
  "sensitiveGlobs": ["src/**"],
  "quality": {
    "test": "composer test",
    "lint": "vendor/bin/php-cs-fixer fix --dry-run --diff",
    "typecheck": null,
    "build": null,
    "boot": null,
    "mutation": null
  },
  "gates": {
    "security": true,
    "review": true,
    "reviewThreshold": { "files": 2, "lines": 30 },
    "screenVerify": { "enabled": false, "method": null, "artifactsDir": "thoughts/screen-verify" }
  },
  "docsRoot": "docs",
  "commit": { "convention": "conventional", "releaseAutomation": null },
  "git": { "branchStrategy": "unica", "branchNaming": "slug" },
  "jira": { "enabled": false, "telemetry": false }
}
```

> Referência viva: [`templates/keelson.config.example.json`](https://github.com/fernandopetry/keelson/blob/main/templates/keelson.config.example.json) no repositório.

## Campo a campo

### `profile`

Qual perfil de linguagem vale para cada camada.

| Campo | Valor |
|---|---|
| `lang` / `version` | A linguagem e a versão **do runtime real** do projeto. Camada inexistente → `"none"` |
| `file` | Onde está o perfil. Prefixo `plugin:` → embarcado no keelson; caminho simples → relativo à raiz do projeto |

Perfil gerado nasce com `reviewed: false` no cabeçalho e o keelson avisa que ele está
pendente de revisão humana até você assinar embaixo.

### `codePaths`

Onde mora o código de cada camada. É o que delimita o escopo do que os agents leem e
mudam — não aponte para a raiz do repositório inteiro.

### `sensitiveGlobs`

Globs de arquivos sensíveis. Guarda um hook contra leitura/escrita descuidada e ajuda a
disparar o gate de segurança.

> **Glob cobre o que você acha que cobre?** Prove antes de confiar. Um padrão como
> `**/.env*` pode não pegar o `.env` da raiz, dependendo de como é avaliado — teste com um
> arquivo real em cada lugar que você espera proteger.

### `quality`

Os comandos reais do projeto. **Este é o campo que mais causa falha boba:** se `test` ou
`lint` não roda de verdade no seu repositório, o gate reprova por motivo errado.

| Campo | Para quê | Sem isso |
|---|---|---|
| `test` | Suíte de testes — a prova do gate de comportamento | O gate de testes não tem como passar |
| `lint` | Estilo/estática | O gate de lint é declarado indisponível |
| `typecheck` | Checagem de tipos, quando separada do lint | Ignorado |
| `build` | Build, quando existe | Ignorado |
| `boot` | Como subir a aplicação localmente | A verificação de tela não sabe levantar o app |
| `mutation` | Mutation testing — prova que a **suíte** falharia se o comportamento regredisse. Opt-in; roda na entrega (fecho do `/keelson:auto` e `/keelson:integrate`), depois da suíte verde — rodada verde não se repete enquanto o código não mudar | Linha `mutação: não configurada (opt-in)` no report da entrega — nada bloqueia |
| `e2e` | Suíte E2E versionada (ex.: `npx playwright test`) — a memória do gate de tela: comportamento já verificado vira spec commitado, re-executável sem browser dirigido. Opt-in; recorte por task via tags `@<slug>`/`@AC-NNN-XXX` (`--grep`), regressão completa no `/keelson:integrate` | Linha `e2e: não configurado (opt-in)` — a verificação de tela segue só exploratória |

> **Não sabe montar a suíte E2E?** Rode `/keelson:e2e-setup`: ele instala o Playwright
> (com a sua confirmação), gera a config e um smoke spec a partir da ficha — com
> esqueleto de login por realm sem credencial versionada —, prova que o pipeline
> enumera os testes e grava o campo para você. Os specs de cada AC nascem depois,
> task a task, escritos pelo developer.

Use `null` no que não existe. Campo com comando errado é pior que campo vazio.

> **`mutation` na prática**: o valor é o comando completo do **seu** projeto — escopo
> (ex.: só o diff, via `--git-diff-base=main` no Infection) e score mínimo (ex.:
> `--min-msi=80`) vão dentro do comando; o keelson só lê o exit code. Mutante
> sobrevivente derruba a entrega **se o seu threshold mandar** — e a lista de
> sobreviventes sai no report como sinal para revisão.
>
> **Não sabe montar esse comando?** Rode `/keelson:mutation-setup`: ele detecta a
> stack, instala a ferramenta (com a sua confirmação), gera a config, prova com uma
> rodada-amostra e grava o campo para você — sem threshold no início, para você
> calibrar depois de observar uma ou duas entregas.

### `gates`

| Campo | Efeito |
|---|---|
| `security` | Liga o `security-engineer` (gate 8) quando a mudança é sensível |
| `review` | Liga o `code-reviewer` (gates 1–7) |
| `reviewThreshold` | Tamanho mínimo do diff (arquivos/linhas) para acionar o review |
| `screenVerify.enabled` | Liga o gate de verificação de tela via Playwright MCP |
| `screenVerify.artifactsDir` | Onde caem screenshots e dumps (default `thoughts/screen-verify`, fora do git) |

### `docsRoot`

Raiz dos artefatos SDD. Default `docs`; os artefatos de cada demanda ficam em
`<docsRoot>/<slug>/`.

### `commit`

| Campo | Valor |
|---|---|
| `convention` | `"conventional"` ou a convenção da sua casa, respeitada como encontrada |
| `releaseAutomation` | A ferramenta detectada (`semantic-release`, `release-please`, `standard-version`, `commitlint`, `git-cliff`, `python-semantic-release`) ou `null` |

O keelson **alimenta** a automação de release; não a opera — publicar release é ato seu,
como PR e deploy. Detalhes em [Convenção de commits](Convencao-de-commits).

### `git`

Política de branch do time (decisões 4.190/4.192). **Os defaults preservam o
comportamento clássico** — bloco ausente = nada muda.

```jsonc
"git": {
  "branchStrategy": "unica",   // "unica" | "por-fatia" — default proposto p/ épicos
  "branchNaming": "slug"       // "slug" | "tracker-key" — nome da branch da largada
}
```

| Campo | O que decide |
|---|---|
| `branchStrategy` | O default que o `/keelson:specify-epic` propõe na confirmação do épico: `unica` (todas as fatias na branch do épico, um PR ao final) ou `por-fatia` (cada história na sua branch — e o `/keelson:continue` só propõe uma fatia **dependente** depois que a anterior mergeou na main). Você pode sobrescrever épico a épico na confirmação; o que vale para leitura é sempre o que ficou gravado no BRIEF |
| `branchNaming` | `slug` → `feat/<slug>-<descrição-curta>` (o padrão de sempre); `tracker-key` → `feat/<KEY>-<descrição-curta>` com a key do Jira criada na largada. Exige `jira.enabled: true` (o self-check do `init` prova); sem key na largada (conector caiu e você não informou uma), a branch nasce no padrão default e o report declara |

### `jira`

Integração opcional, **desligada por padrão** e sempre *best-effort* — nunca bloqueia o
ciclo. Funciona pelo **conector MCP Atlassian**: sem token, sem SDK, sem segredo na ficha.
O `/keelson:init` descobre em runtime os tipos de issue, status e campos do seu projeto e
grava **IDs**.

```jsonc
"jira": {
  "enabled": false,
  "telemetry": false,                     // worklog + contadores por etapa (4.193)
  "site": null, "cloudId": null, "projectKey": null,
  "mode": "create",                       // "create" | "link"
  "issueType": { "spec": null, "feature": null, "task": null, "standalone": null },
  "epicPolicy": "always",                 // "always" | "multi-feature" (0–1 FEAT → sem Epic)
  "standaloneParent": null,               // key de um Epic agrupador p/ as Stories avulsas
  "transition": "comment",                // "off" | "comment" | "auto"
  "mapFile": null, "boardId": null
}
```

Com `jira.enabled`, a **issue-raiz da demanda nasce na largada** (Epic para épico, issue
da SPEC para demanda comum, tarefa avulsa para o resto — decisão 4.191): o card existe
desde o primeiro ato, a key entra no cabeçalho do BRIEF e pode nomear a branch
(`git.branchNaming: "tracker-key"`). Se o conector estiver fora do ar na largada, o
comando pergunta se você quer informar uma key manualmente; recusando, tudo segue sem
Jira, como sempre (best-effort).

| Campo | O que decide |
|---|---|
| `telemetry` | `true` publica, a cada etapa do ciclo (SPEC, PLAN, TASKs, entrega), um **worklog** com a duração medida da etapa e um comentário de 1 linha com os contadores de qualidade (retries de gate, escalações, re-gates) na issue principal. Worklog agrega nos relatórios de tempo do Jira. **Atenção**: o autor do worklog é a conta do conector — telemetria por pessoa exige que cada desenvolvedor use o próprio conector, nunca conta de serviço compartilhada |
| `mode` | `create` — o keelson cria a issue da SPEC e as sub-tasks; `link` — pendura o trabalho numa issue que você já abriu |
| `epicPolicy` | `multi-feature` não cria Epic para SPEC com 0–1 funcionalidade (a Story vira a raiz) |
| `standaloneParent` | key de um Epic que **você** cria uma vez (ex.: "Manutenção") para as Stories de tarefa avulsa aninharem; `null` → a Story avulsa nasce sem pai — os dois são válidos |
| `transition` | `comment` (default) só comenta; `auto` move cards; `off` não toca no quadro |
| `mapFile` | Tabela Markdown com campos customizados e colunas do board, criada pelo `init` e preenchida por você |

Referência completa dos comandos: `/keelson:jira-sync` no [Guia do método](Guia-do-metodo).

## `keelson.local.json` — o que **não** vai para o git

Arquivo separado, local e **não versionado** (confira o `.gitignore`), com as credenciais
de **desenvolvimento** que a verificação de tela usa para logar no app local.

```jsonc
{
  "screenVerify": {
    "realms": {
      "admin": {
        "description": "Área administrativa — usuários internos",
        "baseUrl": "http://localhost:5173/",
        "login": { "path": "/auth/login", "username": "<usuário de dev>", "password": "<senha de dev>" }
      }
    },
    "defaultRealm": "admin"
  }
}
```

Um **realm** por área logada da aplicação (admin, portal do usuário final…). Projeto com
uma área só: mantenha um realm.

> **Somente credenciais de desenvolvimento, descartáveis.** Nunca URL, login ou senha de
> produção, nunca conta real de usuário.

## Mudou alguma coisa no projeto?

Trocou a versão da linguagem, mudou o comando de teste, apareceu um frontend: rode
`/keelson:init` de novo. Ele é idempotente — preserva o que você configurou e completa o
que falta.
