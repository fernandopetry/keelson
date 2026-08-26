# Fluxo de épicos: do documento de produto à entrega, sem precisar lembrar de nada

Esta página ensina a operar o caminho completo de uma demanda **grande** — um documento
da área de produto que vira várias fatias de trabalho — do primeiro comando até o PR.
Ela existe para você não depender de ninguém explicando: siga na ordem.

**A única coisa que você precisa decorar desta página**: `/keelson:continue <slug>`.
Todo o resto o sistema propõe sozinho.

## O mapa em 30 segundos

```
documento de produto
        │
        ▼
/keelson:brief          ← forja: entrevista + código respondem o que der
        │
        ▼
/keelson:specify-epic   ← PM fatia o épico; você confirma a fila
        │
        ▼
/keelson:continue       ← daqui em diante, é só isto, sempre
        │  (propõe a próxima fatia → /keelson:auto roda o ciclo)
        ▼
/keelson:integrate      ← fila concluída: PR do épico (merge é seu)
```

## Passo 1 — chegou um documento de produto: `/keelson:brief`

```
/keelson:brief <path do documento ou texto colado>
```

O comando inventaria o documento, pergunta ao **código** o que o código responde, e a
você **uma pergunta por vez** — só o que documento e código não cobriram.

- **Sabe a resposta?** Responda na conversa.
- **Não sabe (é pergunta para a área de produto)?** Diga isso — a pergunta vira uma
  **Q-ID** registrada e a forja segue sem travar. No fim, você recebe o bloco de
  perguntas pronto para encaminhar a produto.

A forja termina numa de três saídas: **pronto** (segue adiante), **conversar mais**, ou
**aguardando-produto** (as Q-IDs ficam pendentes; quando as respostas chegarem, rode
`/keelson:brief <slug>` que ele retoma do arquivo — nunca precisa da conversa antiga).

## Passo 2 — o BRIEF revelou trabalho grande: `/keelson:specify-epic`

Se o pedido tem 2+ capacidades independentes (uma tela com várias ações, um roadmap
numa frase), o handoff da forja aponta a decomposição:

```
/keelson:specify-epic <caminho do BRIEF>
```

O agente **PM** propõe as fatias; você confirma **duas coisas** numa parada só:

1. **A decomposição** — as fatias, prioridades e slugs de destino;
2. **A estratégia de branch** — o default proposto vem da ficha (`git.branchStrategy`;
   sem o campo, `unica`), e você pode trocar épico a épico na mesma confirmação:
   - **`unica`** — todas as fatias empilhadas em uma branch (`feat/<slug>-...`), cada
     fatia construindo sobre a anterior, com a branch **sincronizada com a main a cada
     fronteira de fatia**. O PR é um só, no final (e merge intermediário é permitido,
     se você quiser).
   - **`por-fatia`** — cada história na sua própria branch, entregue e mergeada antes
     da dependente seguinte: o `/keelson:continue` **não propõe** uma fatia que dependa
     de outra ainda não mergeada na main — ele mostra a pendência de merge (o merge
     continua ato seu) e oferece uma fatia independente, se houver.

O resultado é o **BRIEF épico** com a **fila viva** — uma tabela com o estado de cada
fatia (`pendente` · `em ciclo` · `aguardando-produto` · `entregue`) que os próprios
ciclos atualizam. Você nunca edita essa tabela na mão.

## Passo 3 — trabalhar (e retomar) com um comando só: `/keelson:continue`

```
/keelson:continue <slug>
```

É este o comando de segunda-feira de manhã. Ele lê a fila e os artefatos, mostra o
**"você está aqui"** e propõe **um** próximo passo, já com o comando montado:

| Situação encontrada | O que ele propõe |
|---|---|
| Fatia parou no meio (sessão caiu, fim de expediente) | Retomar a implementação **na wave onde parou** |
| Fatia anterior entregue | Disparar a próxima fatia (`/keelson:auto ...`), com a branch já atualizada da main |
| Fatia esperando resposta de produto | Mostra a pendência e propõe a próxima fatia não bloqueada |
| Fila toda entregue | Aponta o `/keelson:integrate` para abrir o PR |

Você confirma (ou diz "outra coisa") — **nada roda sem a sua confirmação**, mas você
nunca precisa lembrar em que ponto o épico estava nem como se escreve o comando da
fatia 3.

## Perguntas que vão aparecer

**Preciso mergear a cada fatia?** Depende da estratégia. Com branch única (default), o
merge é um só, no final — e é sempre **ato seu**, nunca automático. A branch se mantém
atualizada puxando a main a cada fronteira de fatia; se o merge da main quebrar a
suíte, a entrega da fatia **para até resolver** (é gate, não aviso). Com `por-fatia`,
sim: cada história é entregue na sua branch e as fatias **dependentes** só largam
depois que a anterior mergeou — o `continue` verifica isso por você.

E em qualquer estratégia, quando duas linhas de trabalho se reencontram, **merge limpo
não é merge correto**: o time lista as constantes/sentinelas que mudaram de valor
entre os dois lados e varre os consumidores novos do outro lado antes de confiar no
resultado — conflito textual prova texto, não significado, e o merge é tratado como
diff novo que passa pela suíte e pelos gates. Para trazer uma ou mais branches de
fatia para dentro da sua branch de trabalho atual com essa checagem automatizada, use
`/keelson:merge` — ele resolve conflito e teste quebrado e fecha um commit por branch,
mas nunca mergeia para a principal nem dá push por conta própria.

**Posso rodar a fatia 2 em outra máquina / outro dia / outra pessoa?** Sim — todo o
estado vive nos artefatos commitados na branch do épico. Qualquer clone com a branch
enxerga o mesmo estado; `/keelson:continue <slug>` funciona igual para qualquer pessoa
do time.

**E se eu esquecer qual slug era?** `ls docs/` (ou o `docsRoot` da ficha) lista os
slugs; `/keelson:status <slug>` dá o resumo executivo de qualquer um.

**A demanda era pequena, sem fatias?** O fluxo degrada sozinho: a forja sai com
handoff direto para `/keelson:auto`, sem épico — e o `continue` também retoma ciclo
avulso interrompido.

**As respostas de produto chegaram, e agora?** `/keelson:brief <slug>` (retomada da
forja) se o épico ainda não foi decomposto; se a fatia bloqueada já está na fila, o
`continue` mostra a pendência — cole as respostas quando ele perguntar.

## Ver também

- [Primeiros passos](Primeiros-passos) — instalação e primeiro ciclo
- [Conceitos](Conceitos) — o que são SPEC, PLAN, TASK, waves e gates
- [Guia do método](Guia-do-metodo) — a referência completa de cada comando
- [Solução de problemas](Solucao-de-problemas)
