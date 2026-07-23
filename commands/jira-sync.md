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

**Toda a lógica é do protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`).
Este comando só o orquestra sobre um slug inteiro.

## Input

```
/keelson:jira-sync <slug ou PLAN-MMM> [--dry-run]
```

| Flag | Uso |
|---|---|
| `--dry-run` | Lista o que criaria/vincularia/moveria, sem tocar no Jira |

## Etapa 0: pré-condições

1. Ler a **ficha** (`keelson.config.json`). Se `jira.enabled` é ausente/`false` → parar e
   informar que a integração está desligada (nada a fazer).
2. Resolver o slug (aceita nome do slug ou um `PLAN-MMM` → slug pela pasta-pai). Ler o
   `INDEX.md`, a(s) SPEC(s), os `TASK-MMM-INDEX` e as TASKs do slug.
3. Verificar disponibilidade do conector (protocolo §0/§1). Indisponível → parar com aviso
   claro (é justamente o cenário que este comando existe para recuperar mais tarde); não é erro.

## Etapa 1: reconciliação (protocolo §12)

Aplicar o protocolo de sync Jira sobre o slug, na ordem:

1. **Issue da SPEC** (§4–§6): criar (modo `create`) ou validar o vínculo (modo `link`); gravar
   a key no front-matter se criada.
2. **Sub-tasks das TASKs** (§7): criar as que faltam (idempotência por key na closure); aplicar
   campos do mapa (§8).
3. **Status** (§9): só com `transition:comment`/`auto`. Em `auto`, alinhar cada sub-task ao
   status-alvo correspondente ao estado real da TASK (ex.: TASK Done → status-alvo de
   "concluída"), sempre validando a transição em runtime.
4. **Persistência** (§10): keys gravadas; 1 linha no "Histórico recente" do INDEX.

`--dry-run` → apenas imprimir o plano de reconciliação (o que seria criado/vinculado/movido),
sem chamar as ferramentas de escrita.

## Output

```markdown
# Reconciliação Jira: <slug>

- Issue da SPEC: <KEY> (criada | vinculada | já existia)
- Sub-tasks: <N criadas>, <M já existiam>
- Status alinhado: <K movidas | só comentado | n/a>
- Pulado/avisos: <itens best-effort que falharam, se houver>
```

## Limites

Não cria PR nem faz merge/deploy; não altera SPEC/PLAN/TASK além do campo `Jira:`; nunca
bloqueia (best-effort — protocolo §0). Governança: decisão 4.22 de `decisions.md`.
