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
  não há número (decisão 4.56).
- **Narrado em linguagem de time** (PO, Tech Lead, Developer, QA, Security — 4.41);
  IDs técnicos ficam nos artefatos. Narrativa é bem-vinda **ao redor** do esqueleto,
  nunca no lugar dele.

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
- **Fora de escopo / pendente**: <achados estacionados, handoff aberto, parte recusada, lição pendente de merge>
- **Tracker**: Jira: <KEY> (Épico) · Story: <KEY | —> em <coluna atual> (teto: <coluna>) · sub-tarefas: K/N · transições: <n aplicadas | nenhuma> (transition: <modo>)   # só com jira.enabled; sync pulado/falho aparece AQUI com o motivo, jamais some
- **Fila do épico**: <fatia marcada `entregue` · próximo passo pronto: /keelson:continue <slug-âncora>>   # só demanda com **Epico**:
- **Duração**: <total> (largada HH:MM → entrega HH:MM, horário de Brasília) · specify <n>min · plan <n>min · tasks <n>min · implement <n>min   # etapa que a rota não teve não aparece; marca ausente → o que foi medido + lacuna nomeada
- **Pendente de você**: <revisão da branch · merge · resposta a pergunta estacionada · handoff · nada>

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

## §3. O que cada invocador acrescenta

| Invocador | Fonte das linhas | Específico dele |
|---|---|---|
| `/keelson:auto` (Entrega) | composição e aceitação do item 2.5 · tracker da reconciliação do item 4 · marcas da Etapa 0.5 | métrica de sucesso (item 6.4) · perguntas estacionadas em lote (item 9) · fecho do ledger (item 10) |
| Modo sob demanda (4.75) | ledger + diff da mudança | versão mínima do bloco do consumidor; gate aplicável sem veredito → "não rodado" |
| `/keelson:report` | **só** ledger + repositório (nunca impressão residual da conversa) | seção "Cobertura deste relatório" sempre presente; não commita nem faz push |
