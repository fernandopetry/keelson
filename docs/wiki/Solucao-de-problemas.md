# Solução de problemas

Sintomas comuns, a causa provável e o que fazer.

## Instalação e comandos

### Os comandos `/keelson:*` não aparecem

O plugin não está carregado na sessão. Na ordem:

1. Confira a instalação em `/plugin`.
2. **Reinicie a sessão** do Claude Code — plugin recém-instalado ou recém-atualizado só
   entra em sessão nova.
3. Ainda nada? Reinstale: `/plugin marketplace add fernandopetry/keelson` e
   `/plugin install keelson@keelson`.

### Atualizei, mas o comportamento é o antigo

Esperado: **o update não vale para a sessão corrente**. Reinicie a sessão.

E lembre que são dois passos — atualizar o marketplace sozinho não atualiza o plugin
instalado. `/keelson:update` faz os dois na ordem certa.

### O comando reclama que não achou a ficha

Você está fora da raiz do repositório, ou o projeto ainda não foi configurado. Rode
`/keelson:init` **de dentro da raiz** do repositório consumidor (é lá que mora
`keelson.config.json`).

### Hook do plugin falha com `Permission denied`

Sintoma: erro repetido do tipo `/bin/sh: .../hooks/<nome>.sh: Permission denied` a cada
resposta (hooks de `Stop`) ou na compactação de contexto. O hook perdeu o bit de
execução no cache do plugin. Reparo imediato:

```
chmod +x ~/.claude/plugins/cache/keelson/keelson/<versão>/hooks/*.sh
```

Esse reparo **evapora no próximo update** do plugin. A correção durável viaja no
próprio pacote (versões ≥ 0.93.2 provam o bit no CI); rode `/keelson:update` — e o
`/keelson:init` também detecta o caso (item `hooks-executaveis` do self-check).

### O init disse que terminou, mas o perfil de linguagem não existe

Sintoma: a ficha aponta `profile.<role>.file` para um arquivo que não está no disco —
típico de rodada não-interativa que retornou enquanto o agente que gera o perfil ainda
rodava. A partir da versão `0.120.0` o init espera o agente terminar, prova que o
arquivo existe antes de gravar o caminho, e o relatório abre com
`Adoção: incompleta` quando algo ficou pendente. Reparo: atualize o plugin
(`/keelson:update`) e rode `/keelson:init` de novo — a Regra de merge preserva o que
você já configurou; confira no relatório o item de perfil do self-check.

### Desliguei `gates.review` na ficha e o reviewer continuou rodando

Não é defeito. `gates.review` (e `gates.reviewThreshold`) governam a **cutucada de
encerramento**: o lembrete que bloqueia o fim da sessão quando há mudança de código
sem revisão **fora do ciclo**. A revisão do ciclo (gates 1–7 do `/keelson:implement`)
não é configurável — é parte do método. O efeito de cada campo está na
[Ficha do projeto](Ficha-do-projeto).

## Gates que reprovam

### O gate de testes reprova, mas os testes passam na minha mão

O `quality.test` da [ficha](Ficha-do-projeto) não é o comando real do projeto — o gate
está rodando outra coisa (ou nada). Corrija na ficha e rode de novo. Mesma causa vale para
`lint`, `typecheck` e `build`.

### A entrega parou por mutantes sobreviventes

A suíte passou, mas o comando `quality.mutation` da [ficha](Ficha-do-projeto) saiu com
erro — mutantes sobreviveram além do threshold que **você** configurou no próprio
comando. Vale tanto no fecho do `/keelson:auto` quanto no `/keelson:integrate` (que
reaproveita, com dispensa declarada, uma rodada verde do ciclo quando o código não
mudou desde ela). Isso significa que existe comportamento que pode regredir sem que teste algum
acuse: o report lista os sobreviventes. Dois caminhos legítimos: fortalecer as asserções
dos testes apontados, ou recalibrar o threshold no comando da ficha (decisão sua — o
keelson não define score mínimo). Remover o campo desliga o gate por completo: ele é
opt-in.

### O validator acusou colisão de arquivo entre TASKs da mesma wave

O lint achou o mesmo arquivo declarado no "Escopo > Inclui" de duas ou mais TASKs da
mesma wave do mesmo PLAN. TASKs da mesma wave são candidatas a rodar em paralelo —
duas delas editando o mesmo arquivo é receita para uma sobrescrever o trabalho da
outra. O conserto certo é na decomposição, antes de implementar: mover uma das TASKs
para outra wave (declarando a dependência entre elas) ou redesenhar o corte para que
cada uma tenha seus próprios arquivos. Nasce como WARNING porque a detecção lê os
caminhos escritos nos bullets: item descrito só em prosa (sem caminho de arquivo) não
entra na conta — achado ausente não garante que não há colisão, então a conferência
na hora de implementar continua valendo.

### O validator acusou "comando contradiz critério" numa TASK

O lint achou, na mesma TASK, um comando de verificação usando `--group <tag>` e outra
linha proibindo exatamente essa tag (ex.: a lição do projeto diz "prova de segurança
nunca leva `@group skip-migration`" e o comando do critério prescreve
`--group skip-migration`). O developer executa o comando literal, então o comando vence
a prosa em silêncio — corrija o lado errado antes de implementar: ou o comando (caso
típico), ou a proibição, se ela não se aplica a este contexto. Nasce como WARNING; o
`task-validator` escala para ERROR quando a proibição é uma lição real do projeto que o
comando viola (decisão 4.215).

### O gate 1 reprovou um teste que passa: "grupo excluído da suíte default"

O teste existe e passa quando rodado isolado, mas carrega um grupo/tag/marcador que a
configuração default do runner exclui (ex.: `@group` listado nas exclusões do
`phpunit.xml`) — ou seja, ele nunca executa na rodada que o time olha. O gate 1
confronta o marcador de cada teste novo com as exclusões da config e trata o caso como
achado bloqueante (decisão 4.226; caso de campo: provas de segurança de 2 waves
inertes). Correção típica: remover o grupo do teste-prova ou movê-lo para um grupo que
a suíte default seleciona; a evidência pedida é a rodada default listando o teste
executado.

### O gate de comportamento (9) ficou pendente

O keelson **não finge** que verificou. A pendência vem com a causa nomeada:

| Causa | O que fazer |
|---|---|
| Runtime de browser ausente | `npx playwright install chromium` (Linux: `--with-deps`) |
| Servidor MCP não configurado | Configure o `@playwright/mcp` e **reinicie a sessão** |
| Credencial ausente | Preencha o `keelson.local.json` (realm, `baseUrl`, login de dev) |
| App fora do ar | Suba a aplicação, ou preencha `quality.boot` para que o gate saiba subir |
| Ambiente sem tela (worktree, nuvem) | O ciclo gera um [handoff de verificação](Handoff-de-verificacao); feche-o com `/keelson:verify-handoff` numa sessão com tela |

Uma entrega com handoff aberto é **parcial** até o handoff ser fechado — isso é
intencional.

### A verificação de tela parou com "trabalho concorrente"

Antes de confiar no que a tela mostra, a verificação confere que ninguém está
escrevendo no código durante o exercício: ela captura o estado do repositório ao
começar e ao terminar. Se um arquivo do que estava sendo verificado mudou no meio, o
resultado não vale para commit nenhum — em vez de fingir verde, o gate para e reporta
parcial. Espere quem estava escrevendo terminar (ou pause a outra sessão) e rode a
verificação de novo.

### O validator marcou ERROR e travou a promoção

`ERROR` bloqueia mesmo: SPEC/PLAN não vai a `Approved`, TASK vira `Blocked`. Ou você
corrige o artefato, ou registra um **override consciente** — um bloco declarado no próprio
artefato, no formato definido pelo protocolo dos validators. Não existe "ignorar em
silêncio".

### O perfil de linguagem está marcado como não revisado

Perfil gerado nasce `reviewed: false` de propósito. Ele funciona, mas você deve lê-lo e
assinar embaixo. Se discordar de alguma regra, edite o perfil no seu projeto — ele é seu.

## Artefatos e estado

### O `INDEX.md` está errado ou desatualizado

Não corrija à mão: ele é gerado e a próxima execução sobrescreve.

```
/keelson:rebuild-index <slug>
```

Ele faz backup do INDEX atual antes. Se apontar inconsistências críticas (FRs órfãos,
PLAN sem SPEC), pergunta antes de prosseguir.

> Achados de migração legada vêm do `legacy/TRIAGE-*.md`. **O que não estiver no TRIAGE se
> perde no rebuild** — se você anotou algo direto no INDEX, mova para o TRIAGE antes.

### Um slug antigo não é reconhecido pelos comandos

Pasta de docs sem `INDEX.md` é slug legado:

```
/keelson:migrate-legacy <slug>
```

Migre **antes** de qualquer outra coisa naquele slug. A migração não cria SPECs
retroativas — o histórico keelson começa ali.

### O lint acusa `task-marca-nao-timestamp` numa TASK

Os campos `Data início` e `Data conclusão` do histórico de execução de uma TASK guardam
a marca de relógio medida (data **e hora**, com fuso — ex.: `2026-09-01T14:03:22-0300`).
O aviso aparece quando o campo foi preenchido com outra coisa: uma explicação em texto
("não medida na abertura"), ou só a data sem hora. Esse conteúdo parece honesto, mas
inutiliza a medição — o [relógio do ciclo](Conceitos) não consegue derivar a duração e
descarta a TASK da conta.

Como resolver: se a marca real existe em algum lugar (o commit da TASK, por exemplo),
grave-a no formato completo; se o instante se perdeu de vez, deixe o campo **vazio** ou
com um `—` — a lacuna honesta é a ausência, nunca uma frase no lugar do valor.

### O validator acusa `spec-ac-fora-gwt` em ACs que já estão em Given-When-Then

O aviso é sobre **vocabulário**, não sobre estrutura: o lint procura as palavras "dado",
"quando" e "então" no corpo do critério de aceitação. Um AC escrito com Given/When/Then em
inglês tem a forma certa e reprova mesmo assim — o nome do padrão é em inglês, a SPEC é em
português.

Como resolver: reescreva o corpo do AC com as três palavras em português ("Dado …, quando …,
então …"). A partir da 0.149.0 o template da SPEC traz o exemplo; SPECs antigas com o aviso
acumulado continuam válidas — é WARNING, não trava a promoção sozinho.

### O lint acusa `plan-dec-irreversivel-enum` numa DEC escrita como `não.`

O campo `Irreversível` de uma DEC é um enum de dois valores — `sim` ou `não` — porque é
propagado ao `INDEX.md`. Até a 0.148.0, um ponto final depois do valor caía no ERROR de enum
e travava a promoção do PLAN. A partir da 0.149.0, pontuação no fim do valor é desvio de
forma: vira WARNING `plan-dec-irreversivel-forma`, que o `plan-validator` corrige sozinho
(auto-fix), como já fazia com `SIM` em maiúsculas.

Como resolver numa versão anterior: apague a pontuação depois do valor. Valor fora de
`sim`/`não` continua ERROR — aí a DEC precisa de resposta, não de formato.

### Apareceu senha em trace, screenshot ou contexto de erro do E2E

A saída de execução da suíte E2E autenticada é **material sensível**: o setup de login
digita a credencial, e qualquer captura ativa naquele momento a grava. O setup guiado
atual (`/keelson:e2e-setup`) já gera o esqueleto com `trace: 'off'` e `screenshot: 'off'`
nos projects de setup — se o seu foi gerado antes disso, re-rode o comando (modo reparo)
ou aplique os dois `off` à mão. Duas coisas não mudam com config: o contexto de erro de
uma falha sempre carrega snapshot da página (credencial inclusa), então a pasta de saída
(`thoughts/e2e/`) precisa estar gitignored **comprovadamente** (`git check-ignore`); e
essa saída nunca deve virar artefato publicado de CI.

### A sessão não encerra o turno

Há um ciclo em andamento. O hook de wave lê o arquivo de estado da execução
(`run-state-<slug>.md`, na pasta da sessão `thoughts/local/sessions/<...>/` — ou
direto em `thoughts/local/` em instalações antigas) **fora do contexto do modelo**
e bloqueia o encerramento enquanto o status for `em_andamento`. O arquivo nasce na largada do
ciclo, não só na implementação: SPEC, PLAN e TASKs também são cobertos. Ou deixe o ciclo
terminar, ou peça explicitamente para parar — aí o estado é encerrado com o motivo registrado.

### O bloqueio cita um ciclo que não é desta sessão

Acontece quando várias sessões keelson trabalham em paralelo no mesmo projeto: o
arquivo de estado que bloqueou o encerramento foi escrito por **outra** sessão, que
ainda está viva. Cada arquivo carrega o campo `sessao:` com o id de quem o escreveu;
quando ele aponta outra sessão, a mensagem do bloqueio muda — em vez de "continue ou
encerre", ela instrui a **não tocar** no ciclo alheio (continuar entraria no trabalho
da outra sessão; encerrar apagaria o checkpoint dela no meio de uma tarefa), fazer um
inventário rápido e relatar o achado a você. É o comportamento esperado: nenhuma
sessão continua nem encerra o ciclo de outra. Se a sessão dona realmente morreu e o
arquivo ficou órfão, peça na sessão atual para assumir ou limpar o estado — a
assunção é sempre um ato deliberado, nunca automático.

Uma exceção é reconhecida sozinha desde a 0.130.0: um **ajudante da própria sessão
dona** (um subagent ou teammate que ela despachou) não é "outra sessão" — o guard
identifica o parentesco pelo processo e deixa o ajudante encerrar em paz, sem
inventário nem alarme. Se você ainda vê um ajudante gastando turnos "provando" que o
ciclo não é dele, atualize o plugin (`/keelson:update`).

## Ciclo e comportamento do time

### O ciclo parou no meio, sem erro e sem pergunta

A sessão ficou em silêncio depois de dizer que "aguarda" um agent, e nada aconteceu por
muito tempo. A causa mais comum: o Tech Lead mandou uma mensagem a um agent que **já tinha
devolvido o resultado**. Um agent acorda a sessão uma vez, quando termina; uma mensagem
enviada depois disso pode até ser processada por ele, mas a resposta não acorda ninguém.
Digite `continue`: o ciclo retoma dos artefatos em disco, e o Tech Lead re-despacha o agent
com o que faltava. Desde a versão 0.151.0 o arquivo de estado do ciclo existe desde a
largada e o hook de wave bloqueia esse encerramento com a instrução de re-despachar — se
o problema aparece, o plugin está desatualizado (`/keelson:update`).

### Digitei um comando no meio de um ciclo e ele não rodou

Mensagem enviada **enquanto o time trabalha** entra numa fila e chega como texto dentro do
turno — não como comando. Para comandos comuns o modelo compensa e segue o fluxo, mas
comandos **humano-only** (`/keelson:postmortem`, `/keelson:e2e-setup`, `/keelson:mutation-setup`…)
são bloqueados por desenho quando o modelo tenta invocá-los por você: você verá algo como
*"digite o comando numa mensagem própria"*. Não é defeito: espere o turno terminar e envie
o comando **sozinho, numa mensagem nova** — aí ele roda como comando de verdade.

### Pedi uma coisa e veio outra

Leia o **brief** (`<docsRoot>/<slug>/briefs/BRIEF-NNN.md`): é contra ele que o PO valida a
entrega. Se a interpretação do PO estava torta, é aí que se corrige — a correção reemite o
brief. A janela de veto existe justamente para isso; se você não estava olhando na hora,
corrija e reemita.

### Pedi um ajuste simples e o keelson pediu revisão de SPEC

Antes de mudar um valor padrão ou um comportamento, o modo avulso procura esse valor
nos documentos vivos da capacidade (SPEC e PLAN). Se ele aparece como **mitigação de um
risco** — por exemplo, uma caixa que nasce desmarcada porque a especificação decidiu
proteger quem usa computador compartilhado — ele não é preferência de interface: é um
controle. Mudá-lo exige atualizar a especificação junto (requisito, critério e risco no
mesmo commit), com o risco restante aceito por quem decide. Se a queixa era "ninguém
usa a opção", o conserto costuma ser de percepção (posição, moldura, texto) — isso não
custa risco nenhum e não mexe em documento.

### O ciclo fez perguntas demais / de menos

- Perguntas demais antes da largada: o pedido tinha ambiguidade crítica. Use
  `/keelson:refine` para lapidar a ideia antes, ou seja mais específico no pedido.
- Nenhuma pergunta e o resultado saiu torto: ambiguidade menor vira premissa `[assumido]`
  no artefato. Revise as premissas na SPEC — elas ficam explícitas.
- Quer aprovar etapa a etapa: `/keelson:guided`.

### O pedido é grande demais

Dois ou mais recursos independentes, dois ou mais slugs prováveis, um roadmap numa frase:

```
/keelson:specify-epic "<pedido grande>"
```

O PM decompõe em demandas priorizadas e **você confirma a decomposição** — depois cada
demanda segue seu próprio ciclo.

### Uma mudança pequena está levando horas em rodadas de review

O sintoma: reviewer acha algo, developer corrige, a correção reabre os gates, e as
últimas rodadas discutem só comentários — que o próprio processo gerou. Desde a decisão
4.88 isso tem régua de **convergência**: re-review é sobre o **delta** da correção
(nunca o diff inteiro de novo), um gate que reprova duas vezes **escala para você** com
proposta em vez de rodar uma 3ª vez sozinho, e correção que só muda comentário/doc não
reabre os gates de comportamento. Se uma sessão entrar nesse loop mesmo assim, mande
parar e fechar declarando o estado dos gates — e rode `/keelson:postmortem`: a mensagem
ao mantenedor é o caminho de correção do processo.

### Os papéis ficaram "mudos" numa sessão com Agent Teams

O sintoma: você usa o recurso experimental **Agent Teams** do Claude Code
(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, com ou sem tmux) e, no meio de um ciclo,
os papéis (PO, analistas, revisores) parecem não devolver parecer nenhum — ou a
sessão sugere dar mais ferramentas aos agents "para conseguirem responder".

O que acontece: com Agent Teams habilitado, um subagent que recebe **nome** vira um
*teammate* — uma sessão separada que não devolve o resultado automaticamente a quem
chamou; ela responde por mensagem (`SendMessage`), canal que o Claude Code garante
até para agents somente-leitura. Fora do tmux a conversão é invisível (o teammate
roda dentro do próprio terminal), o que torna o sintoma mais confuso. Não é preciso
— nem correto — dar Bash ou Write a nenhum papel para "destravar" a resposta.

O conserto: conduza o ciclo na **sessão principal**, nunca de dentro de uma pane de
teammate; e atualize o plugin (`/keelson:update`) — desde a versão 0.128.0 os
comandos despacham os papéis sem nome, o que impede a conversão acidental, e desde a
0.130.0 um guard **bloqueia** o despacho nomeado no ato (uma vez; a mensagem explica
como refazer). Se você quer o modo teams de verdade, ele é opt-in:
`/keelson:implement --force-mode=teams` — nesse modo, cada despacho precisa terminar
instruindo o papel a devolver o parecer por `SendMessage` antes de ficar ocioso, e o
guard deixa passar a chamada nomeada repetida. Dois improvisos que não funcionam:
pedir o parecer **por arquivo** (arquivo em pasta temporária pode nem ser visível
entre agents, por causa do sandbox) e inventar um veredito para gate que ficou mudo —
gate sem parecer é gate que não rodou, e é assim que deve ser declarado.

Dois sintomas irmãos, do mesmo episódio: um papel "mudo" **não está necessariamente
perdido** — ele pode estar trabalhando, ou ter entregado e a mensagem se perdido.
Redespachar outro no lugar sem conferir se o processo original morreu costuma terminar
em trabalho duplicado (aconteceu em campo: duas revisões completas da mesma coisa).
E papel despachado **com nome** vira um processo que fica vivo esperando mensagem
mesmo depois de entregar — se ao fim de uma sessão dessas você vê vários processos
`claude` pendurados consumindo CPU, é isso: pode encerrá-los; processo vivo depois da
entrega não é sinal de trabalho em curso.

Uma nota para versões recentes do Claude Code (2.1.224 em diante): o mesmo
`SendMessage` que os papéis usam para devolver parecer também alcança **outras
sessões do Claude Code na sua máquina** — sessões passam a poder trocar mensagens
entre si. Duas consequências práticas. Primeira: se você quiser conter as mensagens
vindas de outras sessões, configure o **lado receptor** (`crossSessionInbound` no
settings, com `hold` ou `refuse`); não crie uma regra de *deny* para `SendMessage` —
ela bloqueia também o canal dos papéis e reproduz o sintoma dos "papéis mudos" desta
seção. Segunda: mensagem que chega de outra sessão **não é ordem** — se ela pedir
para encerrar um ciclo, assumir um trabalho em andamento ou mudar de rumo, a sessão
trata como achado e escala a você; quem decide é sempre o humano.

## Jira

### O ciclo terminou e o Jira não soube de nada

A sincronização é *best-effort*: ela nunca bloqueia o ciclo, mas **sempre registra**. Uma
linha no `INDEX.md` do slug diz o motivo do pulo e a evidência da sondagem. Para
reconciliar depois:

```
/keelson:jira-sync <slug>
```

É idempotente — pode rodar quantas vezes quiser. Use `--dry-run` para ver a projeção antes.

### A criação de issues falhou por campo obrigatório ou hierarquia

- **Campo obrigatório:** o sync consulta o *createmeta* antes de criar em lote, então você
  ouve isso antes da primeira criação. Preencha o mapa de campos (`jira.mapFile`).
- **Hierarquia que não aninha:** o Jira só liga níveis estritamente adjacentes. O
  `/keelson:init` valida o seu mapeamento de tipos e avisa qual perna não fecha, com o tipo
  correto.

### O quadro mudou e o sync usa IDs velhos

Workflow reordenado, coluna nova, tipo de card renomeado ou removido: a configuração
gravada na ficha e no mapa não se atualiza sozinha (o init preserva o que existe). Rode:

```
/keelson:init jira
```

O escopo re-descobre tipos e workflow no Jira real e **compara com o que está gravado** —
cada divergência (ID que não existe mais, status novo fora do trilho) vira aviso e
sugestão comentada no mapa. Nada é sobrescrito: você confirma o que muda. O mesmo comando
serve para ligar o Jira num projeto que adotou o keelson sem ele.

### A Story ficou concluída no fim do ciclo

Isso é bug, não sucesso. O estado-alvo ao fim do ciclo é: sub-tasks concluídas, Story na
coluna de "pronto para QA" esperando você, Epic intocado. Concluir a Story é **ato seu**
(`/keelson:jira-sync <slug> --phase finish-dev`, ou na mão).

### A telemetria está ativa e o worklog não apareceu no card

Cheque nesta ordem:

1. **A ficha tem os campos?** `jira.telemetry` só existe a partir da 0.96.0 e exige
   re-rodar `/keelson:init` após o update; o default é `false` — ligar é decisão sua.
2. **O report do fecho tem a linha `Telemetria:`?** Com telemetria ativa ela é
   obrigatória (worklog publicado · falhou com motivo · sem marca de largada). A linha
   diz exatamente o que aconteceu; a ausência dela é defeito do report — reporte ao
   mantenedor.
3. **`sem marca de largada`** significa que a rota não registrou a hora de início
   (brief avulso antigo, anterior à marca `**Largada**:`) — o worklog é "medido, nunca
   estimado", então sem marca ele não é publicável. Demandas novas registram a marca
   sozinhas.
4. **Permissão**: o autor do worklog é a conta do conector — ela precisa da permissão
   "Work on issues" no projeto. E telemetria por pessoa exige conector por usuário;
   conta de serviço compartilhada faz tudo sair com o mesmo autor.

### Apareceu um worklog somando o ciclo inteiro além dos worklogs por etapa

Versões anteriores à 0.107.1 podiam publicar, no fecho, um worklog largada→fim — que é
a soma das etapas já lançadas, duplicando a agregação de tempo. Desde a 4.234 o worklog
do fecho cobre só o trecho da entrega; o total do ciclo vive no comentário de contadores
e na linha `Duração` do report, nunca em worklog. Se aconteceu: exclua (ou edite) o
lançamento do ciclo completo no card — os worklogs por etapa já contêm o tempo real.

### O report não trouxe a linha `Custo por papel` (ou veio sem algum agente)

A linha existe desde a 0.109.0 (decisão 4.239) e é **telemetria**: medida ou omitida,
nunca estimada — a ausência dela **não** é defeito quando não há o que medir. Fonte:
o hook `window-marker` grava tokens por subagent — e, desde a 0.152.0, a duração e as
chamadas de ferramenta de cada janela, mais o início de cada turno — no log de janela da
pasta da sessão (`window.log` em `thoughts/local/sessions/<...>/`; instalações antigas
usam `thoughts/local/session-window.log`) a cada Stop, e `scripts/context-cost.sh`
compõe o ranking no fecho (minutos e chamadas só aparecem para os spawns que o
harness mediu; parcial vem marcado `em N medidos`). A mesma fonte alimenta a cauda
`espera entre turnos` da linha `Duração` e a cauda `janelas` da `Cronologia` do brief. Se subagents
rodaram e a linha saiu vazia mesmo assim, as causas prováveis: plugin anterior à
0.109.0 durante parte do ciclo (rode `/keelson:update`); hook sem `python3` no PATH
(ele degrada em silêncio, por desenho); ou o formato interno do transcript do harness
mudou — nesse caso o parser ignora as linhas em vez de inventar número: reporte ao
mantenedor com a versão do Claude Code. Num ciclo que rodou no modo teams (opt-in,
`--force-mode=teams`), a linha vem acompanhada de uma `cobertura:` avisando que o
ranking mede só os papéis despachados como subagents — trabalho de teammates fica
fora da medição por enquanto. O número é observação para a dieta de
contexto — o ciclo nunca para nem encolhe por causa dele.

### A entrega não trouxe a linha `Forja` (ou veio sem alguma etapa)

A linha existe desde a 0.123.0 e é **telemetria**: medida ou omitida, nunca estimada —
a ausência não é defeito quando não há o que medir. Ela só aparece em rota que teve
etapa de forja (specify → plan → tasks) e se alimenta da cauda de telemetria que o
ciclo anexa à `Cronologia` do brief ao fechar cada etapa: quantas voltas de correção o
documento precisou depois da validação, quanto custou cada janela de escrita (minutos e
linhas, quando o ciclo mediu — desde a 0.137.0; desde a 0.152.0 os minutos vêm do hook
`window-marker`, que mede cada janela de subagent, e não mais do relógio à mão do
condutor) e quais classes de achado apareceram.
Etapa sem relatório de validação fica sem cauda — e sai da linha; janela sem medição
fica sem o parêntese de custo. O número é observação para
melhorar a escrita dos documentos ao longo do tempo; o ciclo nunca para nem muda de
rota por causa dele.

### O `jira.<PROJECT>.md` está crescendo com listas de issues

O mapa é **config, nunca ledger**: as três seções do protocolo (Campos, Etapas/Colunas,
Trilho do board) mais notas de manutenção — e só. Se ele acumulou seções por SPEC com a
árvore de issues criada (keys, sub-tarefas, estado do quadro), isso é contaminação de
alguma sessão antiga que virou "convenção" do arquivo: nada na doutrina manda anotar ali,
e a informação já vive nos artefatos SDD (linhas `**Jira**:`) e no próprio Jira. **Pode
podar sem perder nada.** O `/keelson:init` aponta o problema
(`mapa com registro de execução — config, não ledger`), mas a poda é sua — o arquivo é
do humano. Atenção a notas do próprio mapa que pedem a anotação ("lacuna declarada"):
lacuna de ledger não é lacuna, é o sintoma se perpetuando.

## Nada disso resolveu

- `/keelson:status <slug>` mostra o estado real do slug.
- `/keelson:review` roda a doutrina sobre um diff avulso, mesmo sem artefato SDD.
- `/keelson:postmortem`, no fim da sessão, investiga **por que** o processo deixou passar e
  gera a mensagem pronta para o mantenedor do plugin.
- Bug ou lacuna no próprio keelson: abra uma
  [issue](https://github.com/fernandopetry/keelson/issues).
