# Relatório de fecho — esqueleto canônico

> Fonte única (decisão 4.130) do relatório que fecha uma sessão de trabalho. Emitem
> **este** esqueleto: a Entrega do `/keelson:auto` (Etapa 5), o fecho do **modo sob
> demanda** (4.75/4.76) e o `/keelson:report` (rede de segurança). O output final do
> `/keelson:implement` avulso mantém o template próprio (tabela de gates por wave);
> executado dentro do `/keelson:auto`, quem fecha é a Entrega — com este esqueleto.
> O bloco do consumidor (`templates/CLAUDE.keelson-block.md`) carrega a versão mínima
> do fecho sob demanda; este arquivo é o dono da forma completa.

**Por que esqueleto, não prosa** (a régua da decisão 4.77 aplicada ao report): prosa
sobre forma é parafraseável — no fim de uma sessão longa, com contexto comprimido, a
narrativa sobrevive e as linhas mecânicas evaporam (caso real: entrega de 20 TASKs sem
a linha de duração, sem composição do diff, sem a linha do tracker e com as mensagens
ao mantenedor **resumidas** — o Diretor ficou sem o que encaminhar). Esqueleto literal
é lacuna a preencher, nunca item de memória.

## §1. Regras de preenchimento

- **Linha obrigatória nunca é omitida**: insumo ausente (marca de relógio, ledger,
  sync degradado) → a linha sai com a **lacuna nomeada** em meia linha.
- **Seção condicional existe ou não existe**: sem gatilho, não aparece; com gatilho, o
  conteúdo é o **bloco copy-paste pronto** — resumo em prosa no lugar do bloco é
  exatamente a falha que este contrato impede.
- **Medido, nunca estimado**: composição via `git diff --stat` contra a base · tracker
  pela reconciliação desta execução (nunca memória dos ganchos) · duração pelas marcas
  de relógio (`TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z`) — sem marca medida,
  não há número (decisão 4.56). Item de **pendência reapresentado** (`Fora de escopo /
  pendente`, `Pendente de você`) segue a régua "lista reapresentada é lista medida"
  (dono: `sdd-conventions.md`, decisão 4.237): conferido na fonte durável nesta rodada,
  ou marcado `não medido`.
- **Narrado em linguagem de time** (PO, Tech Lead, Developer, QA, Security — 4.41);
  IDs técnicos ficam nos artefatos. Narrativa é bem-vinda **ao redor** do esqueleto,
  nunca no lugar dele.
- **Autocheck contável antes de emitir** (decisão 4.214 — reincidência da classe que
  fundou a 4.130): nas rotas que emitem o esqueleto literal do §2 (`/keelson:auto`,
  `/keelson:report`), componha o relatório e **confronte-o com o §2 filtrado pela rota**
  (linhas cujo condicional `# OMITIR…` não alcança, conforme o §3): conte
  `N obrigatórias / N presentes` pelo marcador literal `**<Nome>**:` — divergência →
  preencher a linha (ou a lacuna nomeada) **antes** de enviar. Prosa ao redor não conta
  como linha; o fecho sob demanda (versão mínima do bloco do consumidor) fica fora da
  contagem. A lista é sempre o §2 lido **nesta etapa**, nunca de memória.

## §2. Esqueleto

```markdown
# Entrega: <slug — demanda>          # no /keelson:report: "Fecho de sessão: <slug | branch | sessão livre>"

- **Mudanças**: <resumo em 1–3 linhas do que foi feito>
- **Branch**: <nome — pushada | commit local sem push | sem remoto>
- **Composição do diff**: <N> produção · <N> teste · <N> doc · <N> migration/config
  <+ o que entrou fora do escopo do PLAN, com o motivo em meia linha>
- **Gates**: <gate: veredito (implementado_por → revisado_por)>, um por linha
  <condicional não aplicável → "n/a (<motivo>)"; não rodado → "não rodado", nunca omitido>
- **Mutação da suíte**: <verde em <SHA> | reaproveitada de <SHA> | não configurada (opt-in) | dispensada: diff inerte>   # OMITIR quando a régua 4.121 não alcança a rota
- **Convergência (SPEC ↔ código)**: <convergiu em <SHA> | N gaps: <tipo — source-ref, 1 por linha>>   # só ciclo formal com SPEC (decisão 4.143) — OMITIR nas demais rotas
- **Decisões tomadas em seu nome**: <1 linha cada — decisão + porquê; inclui premissas [assumido], DECs, resoluções do PO, gates resolvidos com ajuste>
- **Intervenções humanas**: <N no ciclo — eventos `intervencao` do ledger (`ledger.sh count`), natureza em meia linha cada quando ≤3 | 0 registradas — ausência de evento ≠ ausência de intervenção | sem ledger — não medido>   # decisão 4.244; decisão em nome do Diretor NÃO conta (é a linha acima — o inverso da métrica); a linha se compõe ANTES do archive do ledger
- **Fora de escopo / pendente**: <achados estacionados, handoff aberto, parte recusada, lição pendente de merge>
- **Lições da rodada**: <toda `licao_candidata` devolvida por gate — inclusive retry/convergência — com destino registrado: `alvo: projeto` → lessons.md · `alvo: processo` → `agile-coach` · toda `licao_contestada` do report do developer com a escada aplicada na lição citada: `contestada+1` — 1ª reformulada, 2ª revogada (ciclo de vida: `core/WORKFLOW.md`, 4.221) | nenhuma>   # aplicar a correção de código não é rotear a lição — dois atos (4.199/4.204); lição (candidata ou contestada) sem destino → o fecho se declara parcial
- **Tracker**: Jira: <KEY> (Épico) · Story: <KEY | —> em <coluna atual> (teto: <coluna>) · sub-tarefas: K/N · transições: <n aplicadas | nenhuma> (transition: <modo>)   # só com jira.enabled; sync pulado/falho aparece AQUI com o motivo, jamais some
- **Telemetria**: <worklog <duração> publicado em <KEY> | falhou (<motivo>) | sem marca de largada — não publicável>   # só com jira.telemetry: true (§17 do protocolo, decisão 4.196); ativo sem linha é defeito do report, nunca omissão válida; <duração> é a do trecho do fecho (janela do §17, 4.234) — o total do ciclo vive na linha Duração, nunca em worklog
- **Fila do épico**: <fatia marcada `entregue` · próximo passo pronto: /keelson:continue <slug-âncora>>   # só demanda com **Epico**:
- **Estimativa × realizado**: <~N waves/~N tasks previstos vs N/N reais · <min–max>h vs <duração medida> · desvio em meia linha · linha anexada em guidelines/project/estimates.md · espelho: <publicada | falhou (motivo) | n/a>>   # só quando o BRIEF da demanda tem seção ## Estimativa (estimate-contract.md §4, decisão 4.223); o realizado vem do TASK-MMM-INDEX e da duração MEDIDA — nunca o contrário
- **Duração**: <total> (largada HH:MM → entrega HH:MM, horário de Brasília) · specify <n>min · plan <n>min · tasks <n>min · implement <n>min · janela pico ~<N>k tokens   # etapa que a rota não teve não aparece; marca ausente → o que foi medido + lacuna nomeada; janela só quando o log existe
- **Custo por papel**: <papel ~<N>k tokens (<M> spawns) · …, maiores primeiro — saída literal de `context-cost.sh --compose`>   # OMITIR quando o log não tem linha de agente — telemetria da dieta (4.239), medida ou omitida, nunca estimada; custo jamais vira gatilho de parada (4.23); ciclo em AGENT_TEAMS → o invocador passa `--teams` e a linha `cobertura:` da saída viaja junto (4.296)
- **Forja**: <specify <N> correções (<N>min/<N>l) · plan <N> (…) · tasks <N> (…) · classes: <check-id(n) · …, decrescente | nenhuma>>   # só rota com etapa de forja — fonte única: cauda de telemetria da Cronologia do BRIEF (4.275); o parêntese por etapa transcreve o campo `janelas` da cauda quando ele existe (custo medido das janelas de scribe — minutos e linhas, medição da main session, decisão 4.311) e é omitido sem ele; OMITIR a linha sem cauda medida; correção = volta de correção de artefato pós-validação, ≠ retry de gate de código (§17 do protocolo de sync); telemetria — medida ou omitida, nunca estimada, jamais gatilho (4.23): o número existe para destilar classe recorrente (escada 4.149) e, desde a 4.311, para dar denominador de custo à destilação
- **Pendente de você**: <revisão da branch · merge · resposta a pergunta estacionada · handoff · nada>
- **Sugestão de postmortem**: <a sessão teve dificuldades — <sinais em meia linha: retry, gate reprovado, correção/intervenção do Diretor> → vale rodar `/keelson:postmortem` para cobrir o episódio (o `PM-*.md` durável fica no repositório mesmo sem envio ao mantenedor)>   # OMITIR quando a sessão não teve retry, gate reprovado nem correção do Diretor (decisão 4.274) — juízo de quem viveu a sessão, nunca parser do ledger (4.227); a linha SUGERE que o Diretor digite o comando (humano-only), jamais o invoca; complementa a seção "Mensagem ao mantenedor": ela cobre o erro pontual, o postmortem cobre o episódio inteiro

## Relatório de aceitação (PO)                    # rotas com brief/espelho
<pedido vs entregue · evidência de alinhamento · o que ficou de fora>

## Verificação pendente (handoff)                 # OMITIR sem handoff aberto
<caminho do HANDOFF-<id>.md, nº de itens, e o prompt canônico preenchido (handoff-protocol.md §8.3) em bloco copy-paste>

## Tracker fora de sincronia — reconexão          # OMITIR se nada degradou
<bloco no formato da §14 do protocolo de sync, com o comando de reconciliação em copy-paste>

## Mensagem ao mantenedor do plugin               # OMITIR sem PROPOSTA_PLUGIN
<a(s) mensagem_mantenedor compostas pelo agile-coach — uma por problema, com o diff literal — em blocos copy-paste>

## Cobertura deste relatório                      # obrigatória no /keelson:report; nos demais, quando houver lacuna de ledger
<o que foi medido do repositório × o que veio do ledger × o que ficou sem registro>
```

A **linha de duração** é relógio de parede — inclui esperas — e jamais vira gatilho de
parada ("fôlego não é gatilho", 4.23/4.24). Fontes das marcas: `Cronologia` do BRIEF na
rota formal; eventos `marco` do ledger nas rotas sem arquivo (`sdd-conventions.md`).
A cauda **`janela pico`** (decisão 4.148) e a linha **`Custo por papel`** (decisão
4.239, extensão da 4.148) seguem a mesma régua da duração — **medidas ou omitidas,
nunca estimadas**: a fonte única é `thoughts/local/session-window.log`, escrito pelo
hook `window-marker` fora do contexto do modelo — uma linha `<ts> janela=<tokens>`
por Stop e uma linha `<ts> agente=<tipo> tokens=<N>` por subagent concluído. Quem
compõe as duas é `bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cost.sh" <raiz>
--compose` (pico = maior janela; ranking = soma por papel, decrescente) — a saída é
citada literal, jamais recalculada de memória. Ciclo que rodou em `AGENT_TEAMS` → o
invocador que conhece o enum de orquestração passa `--teams` ao compositor, e a saída
ganha a linha `cobertura:` — o ranking cobre só despachos via Task (o fato do modo e
suas lacunas têm dono em `agent-teams.md`); a flag é **do chamador, nunca env var**:
o script não detecta modo (decisão 4.296). Sem log ou sem linhas de agente (hook
indisponível, projeto sem ficha, rota sem subagents) → cauda/linha omitidas, sem
lacuna declarada — são telemetria da dieta de contexto (meta da 4.103: ≤600k), não
obrigação do report; e **custo nunca é gatilho** de parada ou de mudança de
comportamento (4.23/4.24). O fecho que move o ledger para `reported-*/` move o log
junto — mesma razão: sem o corte, o pico e o ranking da próxima rodada herdam os da
anterior. O arquivo de offset (`thoughts/local/.window-offset.*`) **permanece**: é
ponteiro de leitura do transcript, não medição — apagá-lo faria o hook reprocessar e
repovoar o log novo com agentes já reportados.

## §3. O que cada invocador acrescenta

| Invocador | Fonte das linhas | Específico dele |
|---|---|---|
| `/keelson:auto` (Entrega) | composição e aceitação do item 2.5 · tracker da reconciliação do item 4 · marcas e telemetria da forja da Cronologia (Etapa 0.5, item 6) | métrica de sucesso (item 6.4) · perguntas estacionadas em lote (item 9) · fecho do ledger (item 10) |
| Modo sob demanda (4.75) | ledger + diff da mudança | versão mínima do bloco do consumidor; gate aplicável sem veredito → "não rodado"; linha "Lições da rodada" obrigatória (4.204) |
| `/keelson:report` | **só** ledger + repositório (nunca impressão residual da conversa) | seção "Cobertura deste relatório" sempre presente; não commita nem faz push; não passa `--teams` ao compositor (não conhece o modo de um ciclo que não conduziu — a linha `cobertura:` é da rota do fecho, 4.296) |
