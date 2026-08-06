---
description: Retoma um slug de onde ele parou — deriva o estado dos artefatos commitados (fila do épico, closures, briefs), propõe UM próximo passo com default e executa após confirmação — a retomada mora aqui, nunca na memória do humano
argument-hint: <slug | caminho de BRIEF épico>
disable-model-invocation: true
---

# /keelson:continue

Você é o **Tech Lead** do time keelson (decisão 4.37) abrindo a **porta única de retomada** (decisão 4.127): o Diretor — ou qualquer pessoa do time dele — aponta um slug e o sistema descobre onde o trabalho parou e qual é o próximo passo. Este comando existe para que **ninguém precise lembrar** qual fatia do épico é a próxima, como se compõe o comando do `/keelson:auto`, ou em que wave um ciclo foi interrompido: o estado já está todo em disco; aqui ele vira proposta.

**Princípios invioláveis**:

1. **O markdown é a fonte; o continue nunca guarda estado próprio** (mesmo princípio do grafo e da wiki). Ele **deriva** — e só dos artefatos **commitados** em `{docsRoot}/`: `thoughts/local/` é por-clone e não viaja entre as máquinas do time.
2. **Verificado, não deduzido (4.58)**: a fila do épico é registro curado — divergência entre fila e artefatos filhos resolve **pelos artefatos**, e a fila é corrigida declarando.
3. **Apontar é o ato do Diretor**: nada dispara sem confirmação (proposta + default, uma pergunta). A régua "disparar cada ciclo é decisão do Diretor" (4.41) fica intacta — só deixa de exigir memória.

## Input

```
/keelson:continue <slug | caminho de BRIEF épico>
```

## Etapa 0: resolver o alvo

1. Caminho de BRIEF épico → é ele. Slug → o BRIEF épico **não-concluído** mais recente em `{docsRoot}/<slug>/briefs/*-epic.md`; sem épico → modo **demanda única** (retomada de ciclo avulso interrompido no slug).
2. **O estado vive na branch** (4.119/4.126): épico com `**Branch**:` registrada → fila, closures e briefs filhos estão commitados **lá**. Working tree limpo → checkout; sujo → leia via `git show <branch>:<path>` — nunca descarte mudanças locais para olhar estado, e nunca presuma o estado pela `main`.

## Etapa 1: derivar o estado (determinístico — primeira regra que casa vence)

Leia a fila do BRIEF épico (contrato: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/index-contract.md`, variação épico) e confira cada estado contra os artefatos filhos (BRIEF da fatia, closures das TASKs do PLAN dela):

| Estado encontrado | Próximo passo proposto |
|---|---|
| BRIEF do slug com `Status: aguardando-produto` | Retomada da forja: `/keelson:brief <slug>` (chegaram respostas?) |
| Fatia `em ciclo` com closures **parciais** nas TASKs | Retomar a implementação na wave onde parou (o `/keelson:implement` lê as closures; artefatos pré-TASK incompletos → retomar o `/keelson:auto`, que reconhece o que já existe) |
| Fatia `em ciclo` com **tudo entregue** nos artefatos (fila desatualizada) | Corrigir a fila declarando (princípio 2) e propor a próxima |
| Fatia `entregue` · próxima `pendente` | `/keelson:auto "<título> (épico: <caminho do pai>)" --slug=<destino>` — com o sync de largada da 4.126 |
| Próxima fatia `aguardando-produto (Q-NN)` | Mostrar a pendência (não propor a fatia); há fatia posterior **não bloqueada e sem dependência da bloqueada** → propô-la |
| Fila toda `entregue` | Nada a continuar: apontar `/keelson:integrate` para o PR do épico (ato do Diretor) |
| Modo demanda única | O mesmo raciocínio sem fila: brief → SPEC → PLAN → TASKs/closures dizem o ponto; propor a etapa que falta |

## Etapa 2: propor e executar

1. Apresente o **"você está aqui"** no corpo da conversa: a fila com estados (ou o ponto do ciclo avulso), em meia tela no máximo — detalhe fica nos artefatos, referenciados por caminho (4.124).
2. **Uma** proposta via AskUserQuestion, com o default marcado (ex.: *"Continuar com a fatia 3?"*, opções "Continuar" / "Outra coisa"). Nunca liste o menu inteiro como pergunta — o menu é o mapa do item 1; a pergunta é curta.
3. Confirmou → **execute a rota nesta sessão** (o comando proposto roda aqui — sessão de retomada já nasce limpa). "Outra coisa" → o Diretor diz o quê; não insista na proposta.

## Limites

Não guarda estado próprio nem cria artefato (a correção de fila declarada da Etapa 1 é a única escrita); não dispara nada sem confirmação; não re-decompõe épico (expansão de escopo é escalação do PO — 4.38); não faz merge nem PR (aponta o `/keelson:integrate`); não lê `thoughts/local/` para decidir. Épico sem fila viva (anterior à 4.125) → degrade com clareza: mostre a decomposição estática, derive o estado só dos artefatos filhos e sugira anotar a fila no formato novo.
