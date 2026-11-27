---
description: 'Ensaia a integração Jira — mostra por cenário (SPEC com ou sem Epic, brief avulso, épico) que cards nasceriam e o que cada marco faria com eles, e lista o que falta. Use antes do 1º ciclo com Jira ou após mudar ficha ou mapa; só lê, `--live` prova'
argument-hint: "[--live]"
disable-model-invocation: true
---

# /keelson:jira-preview

Você é o **Tech Lead** conduzindo o ensaio da integração com o Jira. O Diretor roda este
comando para saber, **antes** de um ciclo real mover o quadro do time, o que o keelson
faria com a configuração de hoje: que cards nascem, sob qual pai, o que cada marco do
ciclo faz com eles e o que está faltando na ficha e no mapa (decisão 4.498).

**Toda a régua é do protocolo de sync Jira**
(`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`; 3º nível:
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md`). Este comando a **aplica a
cenários hipotéticos** e mostra o resultado; não a redefine. Leia do protocolo os §§ que
o ensaio usa — §0–§3, §5, §6, §7.0, §7.1, §8, §9, §13, §16 — antes de montar a prévia.

**Princípio inviolável 1 — sem `--live`, nenhuma escrita.** O ensaio padrão só lê: ficha,
mapa e chamadas de consulta do conector. Criar, comentar, transicionar, registrar
worklog e editar issue são exclusivos da prova viva. Não grava ficha, mapa, INDEX nem
artefato SDD em modo nenhum.

**Princípio inviolável 2 — cada linha declara a origem.** `medido` (o conector
respondeu nesta rodada), `mapa` (derivado da ficha e do mapa, sem confirmação do Jira)
ou `só a prova viva fecha` (o conector não tem como responder sem um card real naquele
estado). Linha sem origem não entra na prévia. "Deve funcionar" não é origem.

**Princípio inviolável 3 — o ensaio prova configuração e workflow, não a execução do
ciclo.** Ele responde "com esta ficha, este mapa e este quadro, o sync consegue fazer o
que promete?". Ele não prova que cada gancho dispara durante um ciclo real, nem cobre
queda do conector no meio do trabalho. Diga isso no relatório; nunca declare "a
automação está garantida".

## Input

```
/keelson:jira-preview [--live]
```

- sem flag: ensaio em papel + medição só-leitura no Jira.
- `--live`: depois da prévia, e só com confirmação do Diretor, cria uma árvore de teste
  marcada no projeto e percorre os marcos de verdade (Etapa 4).

## Quando usar

- Antes do primeiro ciclo de um projeto que acabou de ligar o Jira (`/keelson:init jira`).
- Depois de mexer em `jira.epicPolicy`, `jira.transition`, nos tipos de card ou no mapa.
- Quando o quadro mudou de workflow e o `/keelson:init jira` já re-mediu a config.
- Para mostrar ao time, em uma tela, como o keelson mexe no quadro.

## Quando NÃO usar

- Para configurar ou corrigir a integração: é `/keelson:init jira` (dono da descoberta
  e da re-medição). Este comando aponta o que falta; não repara.
- Para sincronizar ou prever um slug que já existe: é `/keelson:jira-sync <slug>`
  (com `--dry-run` para o plano sem escrita).

## Gotchas

- **Ferramentas do conector chegam deferred**: ausência na lista não é ausência do
  conector — carregue e faça a chamada de prova (protocolo §0/§1).
- **Transição só se consulta a partir de um card real**: `getTransitionsForJiraIssue`
  responde pelo status atual de uma issue existente. Coluna sem card para amostrar não
  tem resposta em modo leitura — a linha é `só a prova viva fecha`, nunca `medido`.
- **A primeira rodada do script presume a hierarquia**: `niveis presumidos` na saída
  significa que a projeção ainda não vale — a que vale é a da rodada com `--levels`.

## Etapa 0: pré-condições

1. Ficha (`keelson.config.json`) **no cwd**. Ausente → pare e instrua a rodar de dentro
   do repo do projeto.
2. Rode a projeção em papel:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/jira-preview.sh" .`
   Saída `config falta jira.enabled` → a integração está desligada: informe, aponte
   `/keelson:init jira` e pare. Exit 3 → ficha ilegível: reporte a causa do stderr e pare.
3. Conector (protocolo §0/§1): carregue as ferramentas (chegam deferred) e faça a
   chamada de prova. Indisponível → o ensaio segue **só em papel**: toda linha fica com
   origem `mapa`, o relatório abre com `Jira: não medido — conector indisponível` e
   `--live` é recusado.

## Etapa 1: medir no Jira (só leitura)

Uma passada, na ordem; cada item vira linha `medido` na seção de configuração:

1. **Tipos** — `getJiraProjectIssueTypesMetadata` do `jira.projectKey`: cada ID de
   `jira.issueType.*` existe? Anote `hierarchyLevel` e `subtask` de cada um e **rode o
   script de novo com os níveis medidos**:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/jira-preview.sh" . --levels spec=<n>,feature=<n>,task=<n>,standalone=<n>`
   (`task=-1` quando o tipo é `subtask: true`; chave de tipo `null` na ficha fica fora da
   flag). A projeção que vale é a desta segunda rodada. ID inexistente → a perna é
   `falta`, e os cenários que dependem dela saem como inviáveis.
2. **Campos obrigatórios** (§8) — `getJiraIssueTypeMetaWithFields` por tipo usado:
   obrigatório que o mapa não cobre (seção Campos) impede a criação daquele tipo. Liste
   campo e tipo.
3. **`jira.standaloneParent`** preenchido → `getJiraIssue`: existe e é de nível Epic?
4. **Status-alvo** — cada ID de status que o script listou em `mapa ok marco-*` e
   `mapa ok fase-*` existe no workflow do tipo daquele nível? Use o que a meta do tipo e
   a amostragem do item 5 devolverem. ID que não aparece em lugar nenhum → `falta`.
5. **Transições** — para cada nível que se move, amostre por JQL uma issue existente em
   cada status do trilho (ou, sem trilho, em cada status-alvo) e chame
   `getTransitionsForJiraIssue`. Um salto conta como `medido` só quando uma issue real
   naquele status oferece a transição para o status seguinte, com `isAvailable` e sem
   tela ou condição que o sync não tenha como satisfazer (§9). Status sem issue para
   amostrar → o salto fica `só a prova viva fecha`. Limite a amostragem a uma issue por
   status e por nível.

Divergência entre o que a ficha grava e o que o Jira responde (ID morto, status fora do
trilho, workflow reordenado) entra como `falta` com a ação `/keelson:init jira` — a
re-medição e a correção do mapa são dele.

## Etapa 2: prévia — "se eu fizesse X, o quadro ficaria assim"

Monte um bloco por cenário a partir das linhas `cenario`, `largada`, `marco` e `fase` do
script, traduzindo os IDs para os nomes medidos e anotando a origem de cada linha. Os
cenários do script:

| Cenário | Quando acontece |
|---|---|
| `spec-multi-feat` | demanda cuja SPEC declara 2 ou mais funcionalidades (FEATs) |
| `spec-uma-feat` | demanda cuja SPEC declara uma funcionalidade, ou nenhuma |
| `avulso` | mudança do dia a dia que vira brief avulso, sem SPEC |

Acrescente, lendo o protocolo na fonte, os dois que não dependem do mapa:

- **Épico** (`/keelson:specify-epic`): a raiz e o momento em que nasce são os do §16;
  cada fatia do épico segue depois o cenário de SPEC correspondente.
- **`jira.mode: link`** (§5): nenhuma raiz é criada — a SPEC precisa trazer a key no
  cabeçalho; sem ela, o sync avisa e pula. Mostre o que o Diretor precisa preencher.

Formato de cada bloco:

```markdown
### Demanda com várias funcionalidades (spec-multi-feat)
- **Árvore**: Epic ▸ História por funcionalidade ▸ Subtarefa por TASK — 3 níveis pleno (medido)
- **Quando os cards nascem**: Epic na largada do ciclo; Histórias no fim da SPEC; Subtarefas no fim das TASKs (mapa)
- **Durante o ciclo** (`transition: auto`):
  - TASK iniciada → Subtarefa vai para *Fazendo* (medido: A fazer → Fazendo)
  - Trabalho iniciado → História vai para *Em desenvolvimento* (só a prova viva fecha — nenhuma História em *A fazer* para amostrar)
  - TASK concluída → Subtarefa vai para *Feito* (medido)
  - Pronta p/ QA → **comentário** na História; ela fica em *Em desenvolvimento* (mapa — alvo além do teto)
  - Epic: não se move sozinho (mapa)
- **Ao fim do ciclo**: Subtarefas em *Feito* · História em *Em desenvolvimento* com o comentário de pronta · Epic onde estava
- **Com `--phase finish-dev`**: Subtarefas → *Feito* · História → *Em revisão* · Epic não se move (sem linha `epic`)
```

Regras da prévia:

- Efeito `comentario` do script é dito como **comentário, o card não anda** — nunca
  como movimento. Efeito `incerto` é dito como incerto, com o motivo do script.
- Cenário `inviavel` ou `nao sincroniza` aparece com o motivo e a chave da ficha que o
  destrava; não liste marcos para ele.
- Feche a prévia com **"O que pode surpreender"**: as linhas em que o comportamento
  difere do que um time espera do quadro — `transition: comment` não move card; o card
  de QA para na coluna de desenvolvimento e só avança por ato do Diretor; o Epic só
  anda por `--phase` com linha `epic`; brief avulso sem `issueType.standalone` não gera
  card; `epicPolicy: multi-feature` deixa demanda de funcionalidade única sem Epic.
  Liste só as que valem para esta ficha.

## Etapa 3: o que está configurado e o que falta

Uma tabela única, juntando as linhas `config` e `mapa` do script com as medições da
Etapa 1: `Item | Estado (ok · falta · aviso) | Origem | Ação`. Toda linha `falta` traz a
ação exata — quase sempre `/keelson:init jira`, ou a edição pontual do mapa quando é uma
linha de marco ou de fase que o Diretor decide declarar. Linha `info` do script entra só
quando muda um cenário da prévia.

Sem `--live`, o comando termina aqui, com o relatório.

## Etapa 4: prova viva (só com `--live`)

A prova viva cria cards **reais** no projeto do time. Antes de qualquer escrita:

1. Mostre exatamente o que será criado — projeto, quantidade e tipo de cada card, os
   movimentos que serão tentados, os campos de estratégia `fixed` do mapa que serão
   aplicados (§8 — sprint ou time fixo põe o card de teste lá) e o worklog de `1m`
   quando `jira.telemetry: true` — e avise: os cards aparecem no quadro e no backlog,
   notificações e automações do quadro disparam como em qualquer card, o
   `finish-dev` pode levá-los à coluna que o `/keelson:deploy` lê, e **nada será
   apagado**. Pergunte (`AskUserQuestion`) quais cenários provar; a opção recomendada é
   um só, o da demanda de funcionalidade única. Sem OK explícito, não crie nada.
2. Recuse a prova viva quando a Etapa 3 tem `falta` em tipo, projeto ou campo
   obrigatório do cenário escolhido: a criação falharia pela metade.

Execução, inline, para cada cenário confirmado:

1. **Criar a árvore mínima** do cenário — a raiz, uma unidade de QA e **uma** sub-task
   — com os tipos e o `parent` que a projeção deu (§6, §7.0, §7.1). `summary` começa
   com `[keelson-ensaio]` e a data; `description` diz que o card é de teste do ensaio e
   pode ser fechado ou apagado. Não use a receita de descrição do §6.2.
   `jira.mode: link` → não crie raiz: peça a key de uma issue de teste ou pule o cenário.
2. **Percorrer os marcos na ordem do ciclo**, cada um pela política `jira.transition`
   e pela mecânica do §9 (teto resolvido antes, não-regressão, walker pelo trilho):
   `TASK iniciada` e `Trabalho iniciado (Story)` → `TASK concluída` →
   `Funcionalidade pronta p/ QA`. Com `comment`, o gesto real do gancho é o comentário:
   faça-o.
3. **`--phase finish-dev`** sobre a árvore de teste (§13), quando o mapa declara a fase.
   `start-dev` fica só na prévia: depois dos marcos, a árvore já passou do alvo dele.
4. `jira.telemetry: true` → um worklog de `1m` na sub-task de teste (§17), para provar
   que o formato é aceito.
5. Depois de cada gesto, leia o status real (`getJiraIssue`) e compare com o previsto.

Falha de chamada no meio → pare, reporte as keys já criadas e o gesto que falhou.
Resposta perdida não é negativa (§0): antes de repetir uma criação, procure por JQL o
card com o marcador.

Os cards de teste ficam onde pararam. Fechar ou apagar é ato do Diretor, no Jira — o
relatório lista as keys para isso.

## Output

```markdown
# Ensaio do Jira: <projectKey>

- **Modo**: papel + leitura | só papel (conector indisponível) | prova viva
- **Política**: transition <off|comment|auto> · epicPolicy <always|multi-feature> · mode <create|link>
- **Cenários**: <N> viáveis · <N> inviáveis (<quais, com a chave que destrava>)
- **Origem das linhas**: <N> medidas · <N> do mapa · <N> que só a prova viva fecha
- **Falta**: <N> itens (<item: ação>) | nada
- **Prova viva**: n/a | <cenário>: <N> gestos iguais ao previsto · <N> diferentes (<gesto: previsto → real>) · keys <lista>
- **Não coberto por este ensaio**: disparo dos ganchos durante o ciclo · queda do conector · <saltos sem issue para amostrar>
- **Pendente de você**: <ação de config> · fechar ou apagar os cards de teste <keys> · nada
```

A prévia por cenário (Etapa 2) e a tabela de configuração (Etapa 3) vêm antes deste
resumo.

## Limites

Não configura nem corrige a integração (`/keelson:init jira`); não sincroniza slug real
(`/keelson:jira-sync`); não grava ficha, mapa, INDEX nem artefato SDD; não apaga nem
fecha card; não cria nada sem `--live` e sem o OK do Diretor. Best-effort como todo o
sync (§0): conector fora degrada para papel, nunca trava.
