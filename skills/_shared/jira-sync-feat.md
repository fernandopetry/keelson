# Jira sync — 3º nível: Stories das funcionalidades (FEAT)

> Extensão do `jira-sync-protocol.md` (mesma pasta) — lida **apenas** com o 3º nível ativo.
> Os §§ citados abaixo são do protocolo core.

## Stories das FEATs (o §6.1 do protocolo)

1. **Ativação (duplo opt-in)**: a SPEC declara FEATs (headings `### FEAT-` na §5) **e**
   `issueType.feature` está preenchido. Qualquer um ausente → este arquivo inteiro é no-op e
   a projeção segue em 2 níveis, idêntica à de hoje.
2. **Pré-check de hierarquia**: a régua de adjacência tem dono único no **§7.0 do protocolo
   core** — aplique-a lá (uma vez, no início) e traga o resultado para cá. Para o 3º nível, o
   caminho pleno é `issueType.spec` epic-level (1) ▸ `issueType.feature` standard (0) ▸
   `issueType.task` `subtask:true` (-1). Perna não-adjacente (ex.: Story(0) sob Tarefa(0) —
   irmãos) → não tentar o `parent`, ir direto ao degrau de degradação correspondente (item 4),
   com aviso.
3. **Criação** (modo `create`, por FEAT sem key — idempotência §4): `createJiraIssue` com
   `projectKey`, `issueType.feature`, `parent` = key da issue da SPEC, `summary` = nome da
   FEAT, `description` = descrição (`>`) + lista dos ACs derivados
   (`ACs(FEAT) = ACs que cobrem FRs da FEAT`); aplicar campos `write` (§8); gravar a key na
   linha `**Jira**:` sob o heading (§10).
4. **Escada de degradação (best-effort §0)**:
   - (i) `issueType.spec` não é epic-level ou o Jira rejeita o `parent` → criar a Story
     **sem parent** + `createIssueLink` "relates to" com a issue da SPEC + aviso de 1 linha.
   - (ii) modo `link` → as Stories penduram na issue humana do front-matter se a hierarquia
     dela aceitar filhos; senão, degrau (i). Key pré-preenchida pelo humano numa FEAT →
     validar com `getJiraIssue` e no-op (mesma semântica do `link` da SPEC).
   - (iii) criação da Story falhou de vez → **nunca** criar sub-task órfã nem sub-task sob
     Epic (níveis não-adjacentes): a task daquela FEAT projeta via `issueType.standalone`
     com `parent` = issue da SPEC quando adjacente (Epic(1) ▸ nível 0); senão issue normal
     + `createIssueLink` "relates to" (padrão de robustez do §7) + aviso. **Nunca bloqueia.**
5. **Pronta p/ QA**: quando o chamador (implement, ou a reconciliação §12) constatar a FEAT
   pronta — **todas** as TASKs que a listam em `Funcionalidade` (primária **ou** secundária,
   em qualquer PLAN do slug) estão `Done`, com os ACs verificados pelos gates — aplicar a
   política de `transition` **na Story**: `comment` → comenta "funcionalidade pronta para
   QA"; `auto` → transiciona para o status-alvo do gatilho "Funcionalidade pronta p/ QA" do
   mapa (validação em runtime, §9); sem linha no mapa → cai para comentário.

## Parenting das sub-tasks (complemento do §7)

`parent` = key da **Story da FEAT primária** da TASK (campo `Funcionalidade`); cada FEAT
secundária recebe `createIssueLink` "relates to" entre a sub-task e a Story dela. Story
primária sem key (criação falhou) → degrau (iii) acima (standalone/link — nunca sub-task
órfã). O fallback de `subtask:false` do §7 continua valendo — o link "relates to" aponta
para a Story primária quando ela existe.

## TASK transversal sem primária honesta (origem transversal do §7)

Campo `**Funcionalidade**: transversal (FEAT-A, FEAT-B)` — serve a todas/quase todas as
FEATs: issue de `issueType.standalone` com `parent` = issue da SPEC quando adjacente
(Epic(1) ▸ nível 0); senão sem pai + link "relates to". Cada FEAT listada recebe link
"relates to" com a Story dela. Nunca replicada: ou aninha na primária (default), ou é
**uma** issue isolada. Key persistida na closure da TASK (§10), como qualquer sub-task.

## Marco na Story (complemento do §9)

O marco de funcionalidade pronta atua na **Story** e é regido pelo item 5 acima.
