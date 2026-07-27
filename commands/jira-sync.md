---
description: Reconcilia um slug com o Jira via conector MCP Atlassian — cria/vincula o que faltou e alinha o status, de forma idempotente (opcional, best-effort)
argument-hint: <slug ou PLAN-MMM> [--dry-run]
---

# /keelson:jira-sync

Você reconcilia o estado de um slug do keelson com o Jira. Os ganchos automáticos do ciclo
(`/keelson:specify`, `:tasks`, `:implement`, `:integrate`) são **best-effort** — quando o
conector Atlassian está indisponível ou uma operação falha, a sincronização é pulada. Este
comando é a **rede de segurança**: reprocessa o slug e cria/vincula/comenta/transiciona o
que ficou para trás, de forma **idempotente** (não duplica).

**Toda a lógica é do protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`;
3º nível: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-feat.md`). Este comando só o orquestra sobre um
slug inteiro — a reconciliação usa quase todos os §§: leia o protocolo **inteiro**.

## Input

```
/keelson:jira-sync <slug ou PLAN-MMM> [--dry-run]
```

| Flag | Uso |
|---|---|
| `--dry-run` | Lista o que criaria/vincularia/moveria, sem tocar no Jira |

## Etapa 0: pré-condições

1. Ler a **ficha** (`keelson.config.json`) **no cwd**. Distinga os dois casos:
   - **Ficha ausente** → você não está num projeto keelson. **Pare** e instrua a rodar de
     dentro do repo consumidor (os caminhos da ficha, do `mapFile` e a escrita nos artefatos
     são relativos à raiz dele). **Não** saia procurando o projeto em outros diretórios.
   - Ficha presente com `jira.enabled` ausente/`false` → parar e informar que a integração
     está desligada (nada a fazer).
2. Resolver o slug (aceita nome do slug ou um `PLAN-MMM` → slug pela pasta-pai). O panorama
   vem do **`INDEX.md` do slug** — leia-o primeiro; ele já traz SPECs, PLANs e estado. Não
   varra `{docsRoot}/` inteiro nem rode `ls -R`: depois do INDEX, leia a(s) SPEC(s), os
   `TASK-MMM-INDEX` e as TASKs do slug, e colete o que o plano precisa em **uma** passada
   (títulos, `**Status**`, keys — um `grep` por campo sobre `tasks/*.md`, não arquivo a
   arquivo).
3. Verificar disponibilidade do conector (protocolo §0/§1). Indisponível → parar com aviso
   claro (é justamente o cenário que este comando existe para recuperar mais tarde); não é erro.
4. **Viabilidade da projeção** (protocolo §7.0) — resolver **antes** de montar o plano, não
   descobrir na criação: cruzar os `hierarchyLevel` dos `issueType` configurados com o fato de
   as SPECs do slug declararem ou não FEATs (`grep -n '^### FEAT-'`). Classifique em uma linha:
   **3 níveis pleno** · **2 níveis válido** · **2 níveis via Story implícita** (degrau (0)) ·
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

Aplicar o protocolo de sync Jira sobre o slug, na ordem:

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
4. **Status** (§9): só com `transition:comment`/`auto`. Em `auto`, alinhar cada sub-task ao
   status-alvo correspondente ao estado real da TASK (ex.: TASK Done → status-alvo de
   "concluída"), sempre validando a transição em runtime — e aplicar o gatilho
   "Funcionalidade pronta p/ QA" (`jira-sync-feat.md` §6.1 item 5) às FEATs já completas.
5. **Persistência** (§10): keys gravadas; 1 linha no "Histórico recente" do INDEX.

`--dry-run` → apenas imprimir o plano de reconciliação (o que seria criado/vinculado/movido),
sem chamar as ferramentas de escrita.

## Output

```markdown
# Reconciliação Jira: <slug>

- Projeção: <3 níveis pleno | 2 níveis válido | 2 níveis via Story implícita | 2 níveis via standalone | inviável: <perna>>
- Backfill: <n/a | K de N TASKs Done com transition:<modo> — o quadro nasce desalinhado>
- Issue da SPEC: <KEY> (criada | vinculada | já existia)
- Stories: <N criadas>, <M já existiam> (de FEAT | implícitas) | n/a
- Sub-tasks: <N criadas>, <M já existiam>
- Status alinhado: <K movidas | só comentado | n/a>
- Pulado/avisos: <itens best-effort que falharam · obrigatórios não cobertos (§8) · divergência TASK-INDEX × arquivos (§4) · Story implícita grossa (§7.0)>
```

## Limites

Não cria PR nem faz merge/deploy; não altera SPEC/PLAN/TASK além das linhas `**Jira**:`
(cabeçalho da SPEC, sob o heading da FEAT, closure da TASK); nunca bloqueia
(best-effort — protocolo §0). Governança: decisões 4.22, 4.27, 4.28 e 4.43 de `decisions.md`.
