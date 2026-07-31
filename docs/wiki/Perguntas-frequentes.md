# Perguntas frequentes

## Sobre o método

### Preciso rodar o ciclo inteiro para toda mudança?

Não. O rigor é **proporcional**:

| Mudança | Caminho |
|---|---|
| Typo, texto, cor | Direto, sem SPEC |
| Bug, refactor pontual | TASK, ou o modo sob demanda em sessão livre |
| Contrato igual, estratégia nova | PLAN com recorte (`--slice`) |
| Contrato novo, capacidade nova | Ciclo completo |

Na dúvida: `/keelson:triage "<descrição>"` — ele classifica e devolve o comando pronto.

### Preciso digitar `/keelson:auto` toda vez?

Não. O modo autônomo é o **padrão**: peça em linguagem natural e o ciclo corre. O comando
existe para quando você quer ser explícito.

### Por que a SPEC não pode falar de tecnologia?

Porque a SPEC é o contrato de comportamento, e ele sobrevive à troca de stack. Quando
linguagem, framework ou banco entram na SPEC, a discussão de produto vira discussão de
implementação e o critério de aceite deixa de ser verificável por quem não é do time
técnico. Tecnologia entra no PLAN — que é justamente onde alternativas são registradas.

### Posso editar o `INDEX.md`?

Não. Ele é gerado pelos comandos e sobrescrito. Errado? `/keelson:rebuild-index <slug>`.

### O que é um "slug"?

A área de demanda — o agrupador dos artefatos de um mesmo assunto, em
`<docsRoot>/<slug>/`. Ex.: `relatorios`, `checkout`, `autenticacao`.

### Quem promove um artefato para `Approved` ou `Done`?

Nunca o validator (ele só bloqueia errors). No ciclo com brief, quem promove é o PO pelo
veredito registrado; no fluxo avulso e no `/keelson:guided`, é você.

## Sobre autonomia e controle

### O keelson faz merge ou deploy sozinho?

Não, e isso é regra dura: **a autonomia termina nos commits**. Ele cria branch, commita e
faz push. Abrir PR (`/keelson:integrate`), mergear e publicar são atos seus — inclusive
porque pode haver outra sessão trabalhando na mesma base.

### Ele commita sem me perguntar?

No ciclo (`/keelson:auto`, `/keelson:implement`), sim — commit faz parte da entrega. Em
sessão livre (modo sob demanda) **não há commit automático**: a mudança é implementada e
revisada, e o commit sai a seu pedido.

### Como eu paro no meio?

Peça para parar. O estado da execução é encerrado com o motivo registrado, e o ciclo pode
ser retomado depois — o INDEX e o índice de TASKs dizem onde ele estava.

### Ele pode mexer em arquivo que eu não quero?

Delimite `codePaths` e `sensitiveGlobs` na [ficha](Ficha-do-projeto). O escopo declarado é
um dos quality gates: mudança fora do escopo da TASK reprova no review em vez de passar
despercebida.

## Sobre linguagens e perfis

### Minha stack não é PHP. Funciona?

Funciona. O motor é agnóstico; o que muda é o **perfil de linguagem**. Se não houver perfil
embarcado para a sua stack, o `/keelson:init` gera um a partir do
[Quality Charter](Quality-Charter), na mesma régua do perfil PHP de referência. Ele nasce
`reviewed: false` até você revisar.

### Posso mudar as regras do perfil?

Pode — o perfil do seu projeto é seu. O que **não** se faz é duplicar regra: o núcleo
agnóstico diz *o quê*, o perfil diz *como*. Se refinar um perfil e ele ficar bom, contribua
de volta: é assim que o plugin cresce.

### Dá para usar em projeto legado?

Sim, e é o caso comum. Slug sem `INDEX.md` → `/keelson:migrate-legacy <slug>` primeiro. A
política é migrar **sob demanda**, quando você for mexer naquela área pela primeira vez —
não tudo de uma vez.

## Sobre integrações

### Sou obrigado a usar Jira?

Não. A integração vem **desligada** e é *best-effort* — nunca bloqueia o ciclo. Sem Jira,
nada muda no funcionamento.

### Preciso de token de API do Jira?

Não. A integração usa o **conector MCP Atlassian**; nenhum token ou segredo entra na ficha
nem no repositório.

### A verificação de tela é obrigatória?

Não — é o gate `screenVerify`, opcional. Ligado, ele loga no seu app **local** via
Playwright MCP e exercita a tela de verdade, headless por padrão. Desligado, o gate de
comportamento se apoia nos testes.

### O keelson publica release?

Não. Ele **alimenta** a automação de release escrevendo o histórico no formato que ela
consome (Conventional Commits, breaking change declarado e nunca inferido). Publicar
envolve credencial, proteção de branch e tag fora do repositório: é ato seu, na mesma
classe do merge e do deploy.

## Sobre custo e confiança

### Por que ele escreve tão poucos comentários?

Porque o teste é único: *apagar essa linha perde informação que o código não devolve?*
Comentário que parafraseia o código é ruído que envelhece mal. O que fica são âncoras de
uma linha ligando o código à decisão que o moldou (`// DEC-03: …`) — o grafo de navegação
que um agente (ou você, em seis meses) segue.

### Como sei que um gate realmente rodou?

Pelo relatório de fecho, que é montado a partir de um **ledger** escrito enquanto os
eventos acontecem — não de memória no fim. Gate sem evento registrado **não** vira
"aprovado": vira lacuna nomeada. Perdeu o relatório? `/keelson:report [slug]`.

### E se ele errar?

Rode `/keelson:postmortem` no fim da sessão. Ele relê as interações, separa **defeito** de
**escopo novo**, rastreia cada falha até o mecanismo que deixou passar (qual gate viu e
aprovou, ou não rodou, ou não tinha como ver) e produz a mensagem pronta para o mantenedor
do plugin. Corrigir o bug em si é outra demanda — `/keelson:triage`.

---

Não achou aqui? Veja a [Solução de problemas](Solucao-de-problemas), o
[Guia do método](Guia-do-metodo) ou abra uma
[issue](https://github.com/fernandopetry/keelson/issues).
