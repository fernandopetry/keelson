# Perguntas frequentes

## Sobre o método

### Preciso rodar o ciclo inteiro para toda mudança?

Não. O rigor é **proporcional**:

| Mudança | Caminho |
|---|---|
| Typo, texto, cor | Direto, sem SPEC |
| Bug, refactor pontual | TASK sob o PLAN original — ou, sem PLAN aplicável, **brief avulso** (a tarefa escrita do dia a dia, antes do código) |
| Contrato igual, estratégia nova | PLAN com recorte (`--slice`) |
| Contrato novo, capacidade nova | Ciclo completo |

Na dúvida: `/keelson:triage "<descrição>"` — ele classifica e devolve o comando pronto.

### Chegou bug de produção. E agora?

Entre pelo `/keelson:triage` normalmente (cole o relato, ou `--from=<KEY>` se já virou
card). Relato de **produção** dispara a etapa de severidade: antes de rotear, o triage
pergunta o que decide o tier — *quem/quantos são afetados* e *há dado em risco* — e a
classificação (🔴/🟠/🟡) nasce registrada na própria TASK/brief, junto do "como
reproduzir". Caso grave (2+ sinais críticos — dado em risco, sistêmico, segurança,
SLA), ele **reconhece um incidente maior**: roteia o conserto como demanda expressa e
te devolve o **checklist de resolução** (sintoma ausente por janela, mitigação
identificada, dado limpo, comunicação enviada) — coordenar a resposta, comunicar e
declarar resolvido são atos **seus**; fechado o checklist, rode
`/keelson:postmortem <episódio>` para a lição não se perder.

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

### Por que os relatórios citam o caminho inteiro em vez de só `PLAN-002`?

Porque a numeração é **por slug**: `PLAN-002` pode existir em vários slugs ao mesmo
tempo, e um comando de retomada copiado para uma sessão nova não carrega o contexto de
qual slug era. Por isso todo texto que sai do slug (relatório, próximo comando,
retomada) cita o caminho do arquivo — `docs/<slug>/plans/PLAN-002-<nome>.md` — que os
comandos aceitam no lugar do ID. Se você digitar um ID nu que existe em mais de um
slug, o comando para e lista os candidatos em vez de escolher um.

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

### Trabalho fora do ciclo aparece no Jira?

Sim, desde a decisão 4.86: a mudança avulsa nasce como **brief avulso** e, com
`jira.enabled` e `issueType.standalone` configurados, vira uma Story no quadro **antes
do código** — quem olha o board vê o que está em andamento, mesmo fora do ciclo. Se a
tarefa já existe como card (escrita por alguém do time), cite a key: o keelson **usa** o
card existente em vez de criar outro (`/keelson:triage --from=<KEY>` ou a key direto no
pedido). Um Epic agrupador opcional (`jira.standaloneParent`) organiza essas Stories.

### Preciso de token de API do Jira?

Não. A integração usa o **conector MCP Atlassian**; nenhum token ou segredo entra na ficha
nem no repositório.

### A verificação de tela é obrigatória?

Não — é o gate `screenVerify`, opcional. Ligado, ele loga no seu app **local** via
Playwright MCP e exercita a tela de verdade, headless por padrão. Desligado, o gate de
comportamento se apoia nos testes.

Se o projeto declara `quality.e2e` na ficha (opt-in), a tela verificada uma vez vira
**spec E2E versionado**, tagueado por slug e AC: a regressão roda por comando
(`--grep` para o recorte, suíte completa no `/keelson:integrate`), e o browser dirigido
fica só para comportamento novo e julgamento visual. Prints e traces continuam fora do
git; só o código do spec é commitado. Não sabe configurar? `/keelson:e2e-setup` monta
tudo (instalação com confirmação, config, smoke spec) e grava o campo após prova.

### Voltei de um fim de semana e não lembro onde o épico parou. E agora?

`/keelson:continue <slug>`. Ele lê a fila viva do épico e os artefatos commitados,
mostra o "você está aqui" e propõe o próximo passo com o comando já montado — retomar
a wave interrompida, disparar a próxima fatia ou abrir o PR. Com a estratégia
`por-fatia`, ele também verifica se a fatia da qual a próxima depende já mergeou na
main — se não, mostra a pendência de merge em vez de propor. Nada roda sem a sua
confirmação, mas nada depende da sua memória. O passo a passo completo está em
[Fluxo de épicos](Fluxo-de-epicos).

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

### O relatório do validator cita `[graph.sh]` — o que é isso?

É um **fato computado, não opinião do agente**: um script determinístico extrai o grafo
dos seus artefatos (dependências, cobertura, waves) e acusa defeitos estruturais —
ciclo, referência quebrada, FR sem task. O validator cita a linha e calibra a
severidade. Artefato antigo não reprova por forma: prosa vira aviso, campo vazio vale
`nenhuma`, e achado sobre coisa já entregue sai rebaixado como `[legacy]`. A régua
completa está no [Contrato do grafo](Contrato-do-grafo).

### Como sei que um gate realmente rodou?

Pelo relatório de fecho, que é montado a partir de um **ledger** escrito enquanto os
eventos acontecem — não de memória no fim. Gate sem evento registrado **não** vira
"aprovado": vira lacuna nomeada. Perdeu o relatório? `/keelson:report [slug]`.

### Uma lição aprendida antiga está atrapalhando mais do que ajudando. E agora?

As lições de `guidelines/project/lessons.md` têm ciclo de vida (`Estado: ativa |
em-observacao | revogada`) — só a `ativa` vira critério de TASK ou regra de gate. Quando
uma lição ativa bloqueia um caso legítimo, o developer a contorna **com razão declarada**
(`licao_contestada` no report) e o fecho aplica a escada: 1ª contestação reformula a
lição, 2ª revoga (o bloco vira uma linha na seção Revogadas; o conteúdo integral fica no
histórico do git). Para limpar um acervo antigo ou fazer higiene periódica, rode
`/keelson:lessons-audit` — ele mede o que expirou (fato) e propõe o que sedimentou
(juízo, só com o seu OK); na dúvida, mantém.

### E se ele errar?

Rode `/keelson:postmortem` no fim da sessão. Ele relê as interações, separa **defeito** de
**escopo novo**, rastreia cada falha até o mecanismo que deixou passar (qual gate viu e
aprovou, ou não rodou, ou não tinha como ver) e produz a mensagem pronta para o mantenedor
do plugin. Corrigir o bug em si é outra demanda — `/keelson:triage`.

---

Não achou aqui? Veja a [Solução de problemas](Solucao-de-problemas), o
[Guia do método](Guia-do-metodo) ou abra uma
[issue](https://github.com/fernandopetry/keelson/issues).
