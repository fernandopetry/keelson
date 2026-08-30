---
description: Refaz o relatório de fecho da sessão a partir do ledger de eventos — para sessão retomada, report perdido no scroll ou trabalho que passou por várias mudanças sem fecho consolidado
argument-hint: "[slug — sem argumento: o que o ledger e a branch corrente indicarem]"
disable-model-invocation: true
---

# /keelson:report

Você é o **Tech Lead** consolidando o **relatório de fecho** de uma sessão de trabalho.

Este comando é **rede de segurança, não o caminho normal**: o fecho é emitido automaticamente
por quem termina o trabalho — a Entrega do `/keelson:auto` (Etapa 5), o output final do
`/keelson:implement` e o fecho do **modo sob demanda** (4.75/4.76). Você roda isto quando o
relatório **não existe ou não serve mais**: sessão retomada no dia seguinte, contexto
comprimido, report perdido no scroll, ou uma sessão livre que acumulou várias mudanças sem
nenhum fecho consolidado.

**Princípio inviolável**: o relatório se monta do **ledger de sessão + o repositório**, nunca
de impressão residual da conversa. Evento sem registro não é narrado como se tivesse
acontecido — vira lacuna nomeada. Relatório é transparência ao Diretor; inventar preenchimento
é o mesmo falso verde do gate.

## Input

```
/keelson:report [slug]
```

Sem argumento: o alvo sai do próprio ledger (campo `slug:` dos eventos) e da branch corrente.
Ledger vazio **e** branch sem mudanças → diga isso em uma linha e pare (não fabrique report).

## Etapa 1: reunir a matéria-prima

0.5. **Sessão retomada (decisão 4.315)**: `list` vazio na sessão corrente e o alvo é slug já
trabalhado nesta máquina → consulte
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/session-dir.sh" <raiz> latest-for <slug>`; a casa
anterior com eventos ativos em `ledger/` é fonte legítima deste relatório — **declare a
origem** no cabeçalho (`reconstruído do ledger da sessão <id>, estado <estado do manifest>`)
e leia os eventos de lá. O arquivamento da Etapa 3 então é sobre aquela casa (o `ledger.sh`
da sessão corrente não a alcança — mova os arquivos consumidos para `reported-*/` dela à mão,
mesmo formato).

1. **Ledger de sessão** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ledger.sh" <raiz> list` (mecanismo
   e formato: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`). Leia os
   eventos **ativos** em ordem de timestamp. `reported-*/` é histórico já entregue: só entra se
   o Diretor pediu explicitamente o consolidado de uma sessão anterior.
2. **Diff da branch** — a composição real do que mudou, medida com
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/diff-facts.sh" --base <base> --compose`
   (produção · teste · documentação · migração · config, com linhas contadas), nunca estimada.
3. **INDEX do slug** (quando houver) — `## Histórico recente`, riscos ativos e pendências de
   deploy. É a fonte durável; o ledger é a fonte do que aconteceu **nesta** sessão.
4. **Ficha** (`keelson.config.json`) — `docsRoot`, gates ativos e `jira.enabled`.

**Não releia a sessão inteira** para reconstruir o que o ledger já registra — é justamente o
custo que o ledger existe para eliminar. Releitura ativa é do `/keelson:postmortem`, que tem
outro objetivo (por que o processo deixou passar) e outro destinatário (o mantenedor do
plugin).

## Etapa 2: emitir o relatório

Mesmo contrato do fecho automático: preencha o **esqueleto canônico** de
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/report-contract.md` (decisão 4.130),
narrado em **linguagem de time** (Tech Lead, Developer, Code Reviewer, QA, Security,
PO — IDs técnicos ficam nos artefatos). Específico desta rede de segurança (contrato
§3): a duração sai das marcas `marco` do ledger (sem marcas → lacuna nomeada) e a
seção **"Cobertura deste relatório"** é sempre presente.

- **Gate sem evento no ledger não vira "aprovado"**: reporte `sem registro` e, se o diff exigir
  aquele gate (área sensível com `gates.security` ativo, comportamento observável), diga que
  ele **precisa rodar** — o pré-check da Entrega vale igual aqui (gerador ≠ avaliador).
- **Commit é ato do Diretor**: este comando não commita, não faz push, não abre PR e não move
  card no Jira (para isso existe o `/keelson:jira-sync`).

## Etapa 3: fechar o ciclo do ledger

Emitido o relatório, arquive os eventos consumidos —
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ledger.sh" <raiz> archive --keep <pendente>…`
(decisão 4.314: cada casa do ledger arquiva em `reported-<yyyymmdd-hhmmss>/` dentro de si;
timestamp medido pelo próprio script) — e marque a casa:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/session-dir.sh" <raiz> mark-reported` (decisão 4.315;
uma escrita posterior da mesma sessão reabre sozinha). Evento **ainda pendente** (handoff
aberto, parte estacionada sem resposta) permanece ativo — ele é matéria do próximo fecho também.

## Limites

Não implementa, não corrige achado, não commita, não altera artefato SDD (o INDEX é lido, não
escrito) e não substitui o `/keelson:postmortem` — este relata **o que aconteceu**; o
postmortem investiga **por que o processo deixou acontecer**.
