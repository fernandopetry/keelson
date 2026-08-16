---
description: "Reconcilia um slug (ou uma SPEC dele) com o Jira via conector MCP Atlassian: cria/vincula épico, stories e sub-tasks, alinha o status e, com --phase (start-dev/finish-dev), move a árvore no quadro — idempotente (opcional, best-effort)"
argument-hint: <slug | PLAN-MMM | SPEC-NNN ou caminho da SPEC> [--dry-run] [--refresh-descriptions] [--phase start-dev|finish-dev]
---

# /keelson:jira-sync

Você reconcilia o estado de um slug do keelson com o Jira. Os ganchos automáticos do ciclo
(`/keelson:specify`, `:tasks`, `:implement`, `:integrate`) são **best-effort** — quando o
conector Atlassian está indisponível ou uma operação falha, a sincronização é pulada. Este
comando é a **rede de segurança**: reprocessa o slug e cria/vincula/comenta/transiciona o
que ficou para trás, de forma **idempotente** (não duplica). A mesma reconciliação roda
automaticamente no **fecho do `/keelson:auto`** (protocolo §12) — este comando avulso cobre o
resto: backfill de slug antigo, ciclo interrompido antes da Entrega, conector que só ficou
disponível depois.

**Toda a lógica é do protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`;
3º nível: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md`). Este comando só o orquestra sobre um
slug inteiro — a reconciliação usa quase todos os §§: leia o protocolo **inteiro**.

**Invocado no meio de outra sessão de trabalho** (não como sessão dedicada): despache a
execução das Etapas 0–2 ao agent `tracker-sync` (gancho `reconciliacao` — decisão 4.103)
e reporte pelo resumo canônico dele; sessão dedicada a sync pode seguir inline.

## Input

```
/keelson:jira-sync <slug | PLAN-MMM | SPEC-NNN | caminho da SPEC> [--dry-run] [--refresh-descriptions] [--phase start-dev|finish-dev]
```

| Flag | Uso |
|---|---|
| `--dry-run` | Lista o que criaria/vincularia/moveria, sem tocar no Jira |
| `--refresh-descriptions` | Força o re-render de descrições **sem** marcador (backfill de cards da receita antiga — protocolo §6.2); sem a flag, descrição sem marcador é tratada como editada por humano e preservada |
| `--phase start-dev\|finish-dev` | Verbo de fase (protocolo §13): após a reconciliação, **move a árvore no quadro** — `start-dev` leva Epic/Story/sub-tasks às colunas de desenvolvimento; `finish-dev` conclui as sub-tasks e leva a Story à coluna de revisão. Alvos por nível nas linhas `--phase` do mapa; ordem exigida pelo Diretor — move com `transition: comment`/`auto` (só `off` bloqueia) |

Slug ou `PLAN-MMM` → reconcilia o **slug inteiro**. `SPEC-NNN` (ou o caminho do arquivo da
SPEC) → reconcilia **só a árvore daquela SPEC** — o fallback manual para quando o ciclo
terminou com o tracker vazio (decisão 4.55): issue da SPEC, Stories dela e sub-tasks das
TASKs dos PLANs que a cobrem.

## Etapa 0: pré-condições

1. Ler a **ficha** (`keelson.config.json`) **no cwd**. Distinga os dois casos:
   - **Ficha ausente** → você não está num projeto keelson. **Pare** e instrua a rodar de
     dentro do repo consumidor (os caminhos da ficha, do `mapFile` e a escrita nos artefatos
     são relativos à raiz dele). **Não** saia procurando o projeto em outros diretórios.
   - Ficha presente com `jira.enabled` ausente/`false` → parar e informar que a integração
     está desligada (nada a fazer).
2. Resolver o alvo (aceita nome do slug, um `PLAN-MMM` → slug pela pasta-pai, ou um
   `SPEC-NNN`/caminho da SPEC → slug pela pasta-pai, com **escopo reduzido à SPEC**). O
   panorama vem do **`INDEX.md` do slug** — leia-o primeiro; ele já traz SPECs, PLANs e
   estado. Não varra `{docsRoot}/` inteiro nem rode `ls -R`: depois do INDEX, leia a(s)
   SPEC(s), os `TASK-MMM-INDEX` e as TASKs do slug, e colete o que o plano precisa em
   **uma** passada (títulos, `**Status**`, keys — um `grep` por campo sobre `tasks/*.md`,
   não arquivo a arquivo). Com escopo de SPEC, o conjunto é o recorte do protocolo §12:
   a própria SPEC, suas FEATs e as TASKs dos PLANs cuja coluna **Cobre** do INDEX inclui
   a SPEC — as demais SPECs do slug ficam fora do plano (e do output).
3. Verificar disponibilidade do conector **provando** (protocolo §0/§1): carregar as
   ferramentas (deferred não aparecem na lista até serem buscadas) e fazer a chamada de prova.
   Indisponível → parar com aviso claro **e** gravar o rastro durável (§0); não é erro — é
   justamente o cenário que este comando existe para recuperar mais tarde. Se o "Histórico
   recente" do INDEX já traz **pulos anteriores**, liste-os no output: eles são o histórico do
   que ficou para trás e por quê.
4. **Viabilidade da projeção** (protocolo §7.0) — resolver **antes** de montar o plano, não
   descobrir na criação: cruzar os `hierarchyLevel` dos `issueType` configurados com o fato de
   as SPECs do slug declararem ou não FEATs (`grep -n '^### FEAT-'`) e com a `epicPolicy`
   da ficha — a escada e a precedência da projeção registrada são do §7.0. Classifique em uma linha:
   **3 níveis pleno** · **compacta (Story raiz + sub-tasks)** · **2 níveis válido** ·
   **2 níveis via Story implícita** (degrau (0)) ·
   **2 níveis via `standalone`** (degrau (i)) · **inviável** (com a perna que não aninha e o
   tipo correto do projeto). Inviável → o plano vira diagnóstico + recomendação; não liste
   criações que o Jira rejeitaria.
5. **Backfill** (protocolo §12) — medir o estado real das TASKs. Slug majoritariamente `Done`
   com `transition: comment`/`off` → o quadro nasceria em "a fazer" sobre trabalho entregue;
   isso vai no output **antes** do plano de criação, com as duas saídas (mudar para `auto` na
   ficha × alinhar manualmente). Não altere a ficha por conta própria.
6. **Campos obrigatórios** (protocolo §8) — antes de planejar criação em lote, uma
   `getJiraIssueTypeMetaWithFields` por tipo usado. Obrigatório não coberto → entra nos avisos;
   criar 80 issues para descobrir na 40ª que falta um campo deixa o slug pela metade.

## Etapa 1: reconciliação (protocolo §12)

Aplicar o protocolo de sync Jira sobre o alvo (slug inteiro ou a árvore da SPEC), na ordem:

1. **Issue da SPEC** (§4–§6): sondagem anti-duplicata (§4, obrigatória no `--dry-run`); criar
   (modo `create`) ou validar o vínculo (modo `link`); gravar a key na linha `**Jira**:` do
   cabeçalho da SPEC se criada.
2. **Stories** — dois caminhos, conforme a projeção do passo 0.4:
   - **FEATs declaradas** (`jira-sync-feat.md` §6.1): criar/vincular as que faltam
     (idempotência por key sob o heading); gravar as keys na SPEC.
   - **Story implícita** (degrau (0) do §7.0 — SPEC sem FEAT ∧ `issueType.feature`
     preenchido): uma Story por SPEC, espelhando-a, sob o Epic; key na linha `**Jira Story**:`
     do cabeçalho (§10). Numa SPEC com vários fluxos, reportar em 1 linha que o card de QA
     ficou grosso e que declarar FEATs é a saída — sem bloquear.

   Estado misto (sub-tasks legadas sob a issue da SPEC) → reportar, nunca re-parentar (§4).
3. **Sub-tasks das TASKs** (§7): criar as que faltam (idempotência por key na closure); aplicar
   campos do mapa (§8).
4. **Descrições** (§6.2): toda criação usa os templates da receita; issue **existente** com
   descrição vazia ou terminada no rodapé-marcador → re-renderizar pelo template atual;
   sem marcador (editada por humano) → preservar e contar nos avisos — a menos que
   `--refresh-descriptions` tenha sido passada (backfill consciente da receita antiga).
5. **Status** (§9): só com `transition:comment`/`auto`. Em `auto`, alinhar cada sub-task ao
   status-alvo correspondente ao estado real da TASK (In Progress → alvo de "TASK iniciada";
   Done → alvo de "TASK concluída") e a Story ao teto (`Trabalho iniciado (Story)`) quando
   alguma TASK dela já começou — sempre validando a transição em runtime e sob o **teto e a
   não-regressão** do §9 — e aplicar o gatilho "Funcionalidade pronta p/ QA"
   (`jira-sync-feat.md` §6.1 item 5) às FEATs já completas (pelo teto, tipicamente
   comentário).
6. **Persistência** (§10): keys gravadas; 1 linha no "Histórico recente" do INDEX.

`--dry-run` → apenas imprimir o plano de reconciliação (o que seria criado/vinculado/movido),
sem chamar as ferramentas de escrita.

## Etapa 2: verbo de fase (só com `--phase` — protocolo §13)

Após a reconciliação (que garante a árvore no Jira), aplicar a fase sobre o mesmo alvo:

1. **Resolver os alvos por nível** nas linhas da tabela Etapas/Colunas cujo `Gatilho` é
   `--phase <verbo>` (§3/§13). Nenhuma linha para o verbo → parar com aviso claro (o mapa não
   declara a fase); nível sem linha → aquele nível não se move (opt-out, sem erro). Checar a
   política: `transition: off` → avisar e não mover (§13); `comment`/`auto` → o verbo move.
2. **Mover na ordem coerente** (§13): `start-dev` de cima para baixo (Epic → Stories →
   sub-tasks); `finish-dev` de baixo para cima. Epic só se move com linha `epic` declarada
   (duplo opt-in — §13). Cada movimento segue o §9: transição direta ou walker multi-hop pelo
   Trilho do board; card já no alvo ou além → no-op; salto bloqueado → para, comenta na issue
   e reporta a posição.
3. **Registrar** (§10): 1 linha no "Histórico recente" do INDEX — verbo, K cards movidos,
   no-ops e bloqueios.

`--dry-run` → imprime o plano de movimentação por card
(`KEY: <status atual> → <intermediários> → <alvo>` · `no-op` · `bloqueado em <status>`)
sem tocar no Jira.

## Output

```markdown
# Reconciliação Jira: <slug>[ · escopo: SPEC-NNN]

- Projeção: <3 níveis pleno | compacta (epicPolicy, sem Epic) | 2 níveis válido | 2 níveis via Story implícita | 2 níveis via standalone | inviável: <perna>>
- Backfill: <n/a | K de N TASKs Done com transition:<modo> — o quadro nasce desalinhado>
- Issue da SPEC: <KEY> (criada | vinculada | já existia)
- Stories: <N criadas>, <M já existiam> (de FEAT | implícitas) | n/a
- Sub-tasks: <N criadas>, <M já existiam>
- Descrições: <N renderizadas/re-renderizadas>, <M preservadas (editadas por humano)> | n/a
- Status alinhado: <K movidas | só comentado | n/a>
- Unidade de QA: <KEY> em <coluna atual> (teto: <coluna | sem linha → só comentário>)
- Fase: <n/a | start-dev/finish-dev — K cards movidos, M no-op, B bloqueados em <status>>
- Pulado/avisos: <itens best-effort que falharam · obrigatórios não cobertos (§8) · divergência TASK-INDEX × arquivos (§4) · Story implícita grossa (§7.0) · marcos não-canônicos no mapa (§3 — documentação, não executados) · fase sem linha no mapa / `transition: off` (§13)>
```

## Limites

Não cria PR nem faz merge/deploy; não altera SPEC/PLAN/TASK além das linhas `**Jira**:`
(cabeçalho da SPEC, sob o heading da FEAT, closure da TASK); nunca bloqueia
(best-effort — protocolo §0). Governança: decisões 4.22, 4.27, 4.28, 4.43, 4.53, 4.55,
4.59, 4.60, 4.61 e 4.62 de `decisions.md`.
