---
description: Monta a fila do /keelson:merge a partir da coluna de deploy do board Jira (status do mapa do projeto) — issue flagada fica de fora, cada key casa com a branch pelo padrão da ficha; só leitura no Jira, nunca push, nunca deploy de fato
argument-hint: "[<projeto>] [--into=<branch>] [--status=<id|nome>] [--dry-run]"
disable-model-invocation: true
---

# /keelson:deploy

Você é o **Tech Lead** montando a fila de integração: o Jira diz **o que** está pronto
para mesclar, o git diz **onde** cada item vive, e quem mescla é o contrato do
`/keelson:merge` — este comando decide **quais branches entram** e termina quando esse
contrato termina. O nome fala da **coluna de deploy** do board; o deploy de fato
continua do Diretor.

**Princípio inviolável 1**: este comando **não tem mecânica de merge própria**. Dry-run
de conflito, reconciliação semântica, suíte, resolução com gate, commit por branch,
corte da fila — tudo é `${CLAUDE_PLUGIN_ROOT}/commands/merge.md`, executado por
contrato (Etapa 4) uma única vez com a fila inteira. Reimplementar qualquer fatia aqui
é defeito, não conveniência.

**Princípio inviolável 2**: mesma fronteira humana do `/keelson:merge` — exceção
declarada no dono (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`,
item "Merge, PR e deploy são humanos", 4.488): nunca dá push, nunca mergeia para a
branch principal remota, nunca abre PR, nunca faz deploy de fato.

**Princípio inviolável 3**: aqui o conector Jira é **obrigatório** — exceção declarada
no §0 do protocolo (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`), que
rege o sync best-effort. O board é o **input** deste comando: sem ele não existe fila,
logo conector indisponível **interrompe com erro claro**, nunca degrada em silêncio.

**Princípio inviolável 4**: leitura pontual, nunca escrita. O comando usa
`searchJiraIssuesUsingJql` (e `getJiraIssue` só para conferir a flag do épico-pai) —
**nunca** cria issue, transiciona card, comenta ou edita campo. Mover o card depois do
merge é ato do Diretor (ou do `/keelson:jira-sync --phase`, quando ele quiser).

**Princípio inviolável 5**: o casamento issue→branch segue o **padrão da ficha**
(`git.branchNaming`, dono em `sdd-conventions.md`), nunca heurística de busca parcial.
Issue sem branch no padrão é **reportada à parte**, nunca "aproximada".

## Gotchas

Fatos do ambiente que contrariam a suposição razoável — cada um cita o dono e para:

- **Comando humano-only não se invoca de dentro de outro comando**: o harness bloqueia
  a invocação de `/keelson:merge` pelo modelo. A fila entra pelo **contrato** — ler
  `merge.md` e executar as etapas dele como se o Diretor o tivesse invocado (Etapa 4).
- **Status e campo operam por ID, nunca por nome** (protocolo §1): nomes são localizados
  e variam por projeto. A coluna vem da linha `Fila de merge` do mapa (§3); o campo de
  flag é resolvido pelo metadata do projeto, uma vez por execução — nunca
  `customfield_*` chumbado.
- **`Flagged` é campo customizado padrão do Jira Cloud** — pode não existir na
  instância. Ausente → a exclusão por flag **degrada com aviso** no output ("campo de
  flag ausente — nenhuma issue excluída por flag"), nunca inventa erro.
- **`parent` só existe na hierarquia do Jira Cloud**; instância clássica usa o campo
  customizado `Epic Link` — mesma resolução por metadata, nunca por ID chumbado.
- **`ORDER BY Rank` pode ser recusado** pela instância → `ORDER BY created ASC`,
  declarando a degradação no output.
- **Prefixo de remote na mensagem de merge quebra automação do consumidor** — regra da
  Etapa 6 do `merge.md`: a fila carrega o nome **nu** da branch, como o git a conhece.

## Input

```
/keelson:deploy [<projeto>] [--into=<branch>] [--status=<id|nome>] [--dry-run]
```

| Arg/Flag | Uso |
|---|---|
| `[<projeto>]` | Project key do Jira (ex.: `PROJ`). Default: `jira.projectKey` da ficha; sem os dois → parar e pedir |
| `--into=<branch>` | Branch de destino, repassada ao contrato do merge. Default: a branch corrente do working tree (mesmo default do `/keelson:merge`) — nunca um nome de branch principal chumbado |
| `--status=<id\|nome>` | Status (coluna) a ler, sobrepondo a linha `Fila de merge` do mapa. Sem a linha no mapa, a flag é obrigatória; nome digitado pelo Diretor entra no JQL como está, declarado no output |
| `--dry-run` | Repassado ao contrato do merge — a fila é montada igual, o merge só diagnostica |

## Etapa 0: pré-condições (falhou uma → parar e reportar, nada é executado)

1. **Ficha** (`keelson.config.json` no cwd): ausente → parar, instruir a rodar de dentro
   do repo consumidor. `jira.enabled` ausente ou `false` → parar: a integração está
   desligada e este comando a exige — ligar é `/keelson:init jira`. `jira.projectKey`
   e `jira.mapFile` entram no pacote desta execução.
2. **Prova do conector** com a mecânica do §0 do protocolo: carregar as ferramentas
   (harness *deferred* não as lista sem busca — "não vi" não é evidência) e fazer
   **uma** chamada barata (`atlassianUserInfo`; se o servidor não a expõe,
   `getAccessibleAtlassianResources`). A divergência com o §0 é o destino da falha: lá
   avisa e segue; **aqui para**, com a devolutiva literal da chamada no erro — ex.:
   `conector Jira indisponível (atlassianUserInfo: not authorized) — /keelson:deploy
   exige o conector; nada foi buscado nem mesclado`.
3. **`cloudId`** conforme §1 do protocolo (`jira.cloudId` da ficha; senão `jira.site`;
   senão `getAccessibleAtlassianResources`). Nomes de ferramenta resolvidos pelo
   **sufixo** (`mcp__<servidor>__<ferramenta>`), nunca por prefixo fixo.
4. **Coluna**: linha `Fila de merge` da seção Etapas/Colunas do mapa (`jira.mapFile`,
   protocolo §3) → `status-id`. Linha ausente e sem `--status=` → parar nomeando o que
   falta (a linha do mapa ou a flag), nunca um nome de coluna inventado.
5. **Working tree**: os pré-checks completos são a Etapa 0 do `merge.md` (não os
   duplique); aqui só não siga se o cwd não é um clone git.

## Etapa 1: ler a coluna do board

```
searchJiraIssuesUsingJql:
  jql: project = <projeto> AND status = <status-id> ORDER BY Rank ASC
  fields: key, summary, parent, <id do campo de flag>
```

- O id do campo de flag vem do metadata do projeto (`getJiraIssueTypeMetaWithFields`
  ou equivalente pelo sufixo), procurando o campo cujo nome é `Flagged` — uma vez por
  execução; ausente → Gotchas (degrada, declara).
- `ORDER BY Rank ASC` preserva a ordem do board; recusado → Gotchas.
- Resultado vazio → reportar **"nada a mesclar"** com o JQL usado e **parar** — fila
  vazia não é erro, é estado.

## Etapa 2: excluir issues flagadas (própria ou herdada do épico)

Flag de impedimento marcada = o Diretor ainda tem o que resolver no Jira; a issue
**nunca** entra na fila, mesmo dentro do status lido.

1. **Flag própria**: campo de flag não-vazio na issue → excluída.
2. **Flag herdada do épico-pai**: para cada issue restante com pai, conferir o pai —
   `getJiraIssue` **uma vez por pai distinto** (várias filhas do mesmo épico custam uma
   chamada). O pai vem do campo `parent`; instância clássica → `Epic Link` (Gotchas).
   Pai flagado → a filha é excluída mesmo sem flag própria.
3. Cada exclusão vira uma linha do output (key, motivo: `flag própria` ou
   `flag herdada de <KEY do épico>`) — exclusão silenciosa é o defeito que este passo
   existe para evitar.

## Etapa 3: casar issue → branch (padrão da ficha)

1. `git fetch origin` uma vez, antes de qualquer verificação.
2. Padrão de nome, por `git.branchNaming` da ficha:
   - `tracker-key` → `feat/<KEY>-<descrição-curta>`: candidata é a branch (local ou
     `origin/`) cujo nome começa por `feat/<KEY>-` **ancorado na fronteira da key**
     (`PROJ-12-` nunca casa `PROJ-123-`); mais de uma candidata → **ambígua**, listada à
     parte, não entra.
   - `slug` ou ausente → nome **exato** `<KEY>` (convenção de branch externa ao ciclo):
     `git rev-parse --verify <KEY>` (local) e, na ausência, `origin/<KEY>`.
   O padrão aplicado é declarado no output.
3. Encontrou → entra na fila, na ordem da Etapa 1, com o nome **nu** (Gotchas). Não
   encontrou → lista **"sem branch"** (key + summary), reportada à parte; o lote **não
   aborta** por causa dela.

## Etapa 4: mesclar pelo contrato do `/keelson:merge`

- Fila vazia **e** lista "sem branch" vazia → já parou na Etapa 1.
- Fila vazia com itens "sem branch" ou ambíguos → reportar a lista completa e **parar**,
  sem mesclar nada.
- Fila com ≥1 branch → **Contrato**: `${CLAUDE_PLUGIN_ROOT}/commands/merge.md`, Etapas
  0–7, executado **uma vez** com a fila inteira na ordem, como se o Diretor tivesse
  digitado:

```
/keelson:merge <branch1> [<branch2> ...] --into=<branch> [--dry-run]
```

Daqui em diante vale tudo que o `merge.md` diz — pré-checks, loop por branch, corte da
fila quando uma branch falha, output com a linha `MERGE_HEAD`; este comando não
re-tenta nem reordena por cima do resultado.

## Etapa 5: output final

```markdown
# Deploy queue: <projeto> · status <id|nome> → <branch>

## Fila mesclada (ordem do board — padrão de branch: tracker-key | exato)
- <KEY>: branch <nome> (local|origin) → ver resultado do merge abaixo

## Excluídas por flag (resolver no Jira)
- <KEY>: flag própria | flag herdada de <EPIC-KEY>

## Sem branch correspondente | ambíguas
- <KEY>: <summary> — sem branch | candidatas: <a>, <b>

## Merge (contrato do /keelson:merge)
- /keelson:merge <branches...> --into=<branch> [--dry-run] — output dele na íntegra
- Nenhum card foi movido/comentado no Jira; push, PR e o deploy de fato continuam com você.
```

Seções vazias viram `- nenhuma`, nunca somem — o Diretor lê o que **não** entrou com o
mesmo peso do que entrou. Degradações declaradas (campo de flag ausente, `Rank`
recusado, `--status` por nome) entram como linhas desta seção.

## Limites

Nunca mescla por mecânica própria (tudo é o contrato do `merge.md`), nunca dá push,
nunca abre PR, nunca faz deploy de fato, nunca cria/transiciona/comenta issue no Jira,
não inventa casamento issue→branch fora do padrão da ficha, não re-tenta branch que o
merge cortou. Conector Jira indisponível, integração desligada ou coluna sem linha no
mapa e sem `--status` → erro e fim, sem fila parcial de memória.
