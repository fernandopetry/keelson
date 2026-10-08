---
description: Lê coluna de um board Jira (default "To Deploy"), casa cada issue key com a branch de nome idêntico e delega a fila ao /keelson:merge; issue flagada (própria ou do épico-pai) fica de fora; nunca mescla, nunca dá push, nunca mexe no Jira
argument-hint: "<board> [<branch-destino>] [--status=\"To Deploy\"] [--dry-run]"
disable-model-invocation: true
---

# /keelson:deploy

Você é o **Tech Lead** montando a fila de integração: o Jira diz **o que** está pronto
para mesclar, o git diz **onde** cada item vive, e quem mescla é o `/keelson:merge` —
este comando termina no ato de invocá-lo.

**Princípio inviolável 1**: este comando **não mescla nada**. Dry-run de conflito,
reconciliação semântica, suíte, resolução, commit de merge — tudo isso é o
`/keelson:merge` (`commands/merge.md`), invocado uma única vez com a fila inteira.
Reimplementar qualquer fatia dessa lógica aqui é defeito, não conveniência.

**Princípio inviolável 2**: mesma fronteira humana do `/keelson:merge` (decisão 4.263,
dono em `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`): nunca dá
push, nunca mergeia para a branch principal remota, nunca abre PR, nunca faz deploy de
fato. O nome fala da **fila de deploy** no board; o deploy real continua do Diretor.

**Princípio inviolável 3**: aqui o conector Jira é **obrigatório**, não best-effort —
exceção declarada ao §0 do protocolo (`skills/_shared/jira-sync-protocol.md`), que rege
o sync opcional. O board é o **input** deste comando: sem ele não existe fila, logo
conector indisponível **interrompe com erro claro**, nunca degrada em silêncio.

**Princípio inviolável 4**: leitura pontual, nunca escrita. O comando usa
`searchJiraIssuesUsingJql` (e `getJiraIssue` só para conferir flag de épico-pai) —
**nunca** cria issue, transiciona card, comenta ou edita campo. Não é um gancho do
protocolo de sync; mover o card depois do merge é ato do Diretor (ou do
`/keelson:jira-sync`, quando ele quiser).

**Princípio inviolável 5**: o casamento issue→branch é **nome exato**. A branch
chama-se exatamente a key da issue (ex.: issue `NOVA-1234` ⇔ branch `NOVA-1234`),
local ou `origin/NOVA-1234` — nenhuma heurística de prefixo, slug ou busca parcial.
Issue sem branch de nome exato é **reportada à parte**, nunca "aproximada".

## Input

```
/keelson:deploy <board> [<branch-destino>] [--status="To Deploy"] [--dry-run]
```

| Arg/Flag | Uso |
|---|---|
| `<board>` | Project key do Jira (ex.: `NOVA`) — obrigatório |
| `[<branch-destino>]` | Branch onde a fila será mesclada, repassada como `--into=` ao `/keelson:merge`. Default: `master` |
| `--status="<nome>"` | Status (coluna) do board a ler. Default: `To Deploy` |
| `--dry-run` | Repassado ao `/keelson:merge` — a fila é montada igual, o merge só diagnostica |

## Etapa 0: prova do conector (obrigatória — falhou, nada é executado)

1. Prova de disponibilidade com a mesma mecânica do §0 do
   `skills/_shared/jira-sync-protocol.md`: carregar as ferramentas (harness *deferred*
   não as lista sem busca — "não vi" não é evidência) e fazer **uma** chamada barata
   (`atlassianUserInfo`; se o servidor não a expõe,
   `getAccessibleAtlassianResources`). A divergência com o §0 é o destino da falha:
   lá avisa e segue; **aqui para**, com a devolutiva literal da chamada no erro —
   ex.: `conector Jira indisponível (atlassianUserInfo: not authorized) — /keelson:deploy
   exige o conector; nada foi buscado nem mesclado`.
2. `cloudId` conforme §1 do protocolo: `jira.cloudId` da ficha se presente; senão
   `jira.site`; senão `getAccessibleAtlassianResources`. Resolver nomes de ferramenta
   pelo **sufixo** (`mcp__<servidor>__<ferramenta>`), nunca por prefixo fixo.
3. Confirmar que a working tree permite um merge (a Etapa 0 do `/keelson:merge` fará
   os pré-checks completos — não os duplique aqui; apenas não invoque o merge se já
   souber que o repo não é um clone git).

## Etapa 1: ler a coluna do board

```
searchJiraIssuesUsingJql:
  jql: project = <board> AND status = "<status>" ORDER BY Rank ASC
  fields: key, summary, flagged, parent
```

- `ORDER BY Rank ASC` preserva a ordem do board; instância que recuse `Rank` → caia
  para `ORDER BY created ASC`, declarando a degradação no output.
- Resultado vazio → reportar **"nada a mesclar"** com o JQL usado e **parar** — fila
  vazia não é erro, é estado.

## Etapa 2: excluir issues flagadas (própria ou herdada do épico)

Flag de impedimento marcada = o Diretor ainda tem o que resolver no Jira; a issue
**nunca** entra na fila, mesmo dentro do status filtrado.

1. **Flag própria**: campo `Flagged` (customizado padrão do Jira Cloud) não-vazio na
   issue → excluída.
2. **Flag herdada do épico-pai**: para cada issue restante com pai, conferir o pai —
   `getJiraIssue` **uma vez por pai distinto** (dedupe: várias filhas do mesmo épico
   custam uma chamada). O pai vem do campo `parent` (hierarquia padrão do Jira Cloud);
   instância clássica sem hierarquia → fallback para o campo customizado `Epic Link`
   (resolvido por nome de campo via metadata, nunca por ID chumbado). Pai flagado →
   a filha é excluída mesmo sem flag própria.
3. Cada exclusão vira uma linha do output (key, motivo: `flag própria` ou
   `flag herdada de <KEY do épico>`) — exclusão silenciosa é o defeito que este passo
   existe para evitar.

## Etapa 3: casar issue → branch (nome exato)

1. `git fetch origin` uma vez, antes de qualquer verificação.
2. Para cada key sobrevivente, na ordem da Etapa 1:
   `git rev-parse --verify <key>` (local) e, na ausência,
   `git rev-parse --verify origin/<key>`.
3. Encontrou (local ou remota) → entra na fila, na mesma ordem. Não encontrou →
   lista **"sem branch"** (key + summary), reportada à parte; o lote **não aborta**
   por causa dela.

## Etapa 4: delegar ao /keelson:merge

- Fila vazia **e** lista "sem branch" vazia → já parou na Etapa 1.
- Fila vazia com itens "sem branch" → reportar a lista completa e **parar**, sem
  invocar o merge.
- Fila com ≥1 branch → invocar **uma vez**, com a fila inteira na ordem:

```
/keelson:merge <branch1> [<branch2> ...] --into=<branch-destino> [--dry-run]
```

`<branch-destino>` é o 2º posicional do input, default `master`. Daqui em diante vale
tudo que `commands/merge.md` diz — inclusive o corte da fila quando uma branch falha;
este comando não re-tenta nem reordena por cima do resultado.

## Etapa 5: output final

```markdown
# Deploy queue: <board> · status "<status>" → <branch-destino>

## Fila mesclada (ordem do board)
- <KEY>: branch <KEY> (local|origin) → ver resultado do /keelson:merge abaixo

## Excluídas por flag (resolver no Jira)
- <KEY>: flag própria | flag herdada de <EPIC-KEY>

## Sem branch correspondente (nome exato <KEY> não existe, local nem origin)
- <KEY>: <summary>

## Delegação
- /keelson:merge <branches...> --into=<destino> [--dry-run] — output dele na íntegra
- Nenhum card foi movido/comentado no Jira; push, PR e deploy continuam com você.
```

Seções vazias viram `- nenhuma`, nunca somem — o Diretor lê o que **não** entrou com o
mesmo peso do que entrou.

## Limites

Nunca mescla por conta própria (tudo é o `/keelson:merge`), nunca dá push, nunca abre
PR, nunca faz deploy, nunca cria/transiciona/comenta issue no Jira, não inventa
casamento issue→branch além do nome exato, não re-tenta branch que o merge cortou.
Conector Jira indisponível → erro e fim, sem fila parcial de memória.
