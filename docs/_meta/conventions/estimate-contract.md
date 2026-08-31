# Dimensionamento de demanda — contrato da estimativa

> Fonte única (decisão 4.223) da escala, do esqueleto de saída, das regras invioláveis e
> da calibração histórica do dimensionamento de demanda. Leem este arquivo em runtime:
> o agent `estimator` (produz a estimativa), o `/keelson:estimate` (porta de entrada),
> o emissor do report de fecho (linha `Estimativa × realizado`, `report-contract.md`) e
> o gancho de espelho do tracker (`jira-sync-protocol.md` §18). Mudou a regra, mude
> aqui — nunca copie nos leitores.

## §1. O que a estimativa é — e o que ela nunca é

A estimativa **antecipa** a medida que o ciclo já produz a posteriori: waves e tasks do
`TASK-MMM-INDEX` (`Total de tasks`, `Tamanho dominante`) e a duração por fase da
Cronologia do BRIEF. Ela existe para **comparar demandas entre si** e dar
previsibilidade ao Diretor — nunca para substituir medição.

Três regras invioláveis:

1. **Recusa honesta**: pedido sem informação suficiente → veredito **`não estimável`**,
   com as lacunas nomeadas (o que precisaria ser respondido para estimar). Número
   inventado sobre lacuna é o pior defeito desta camada — a mesma régua do `graph.sh`
   (na dúvida, degrada; nunca inventa).
2. **Estimado nunca ocupa campo medido**: a estimativa não escreve worklog, não entra
   na linha `Duração` do report e não preenche `Largada`/`Cronologia` — esses campos
   seguem "medido, nunca estimado" (4.56/4.196/4.200/4.216). O par estimado × realizado
   se compõe **na leitura** (linha própria do report, arquivo de calibração), nunca na
   escrita de um campo compartilhado.
3. **Dimensão informa, nunca roteia**: o que decide a rota da demanda é o custo de
   estar plausivelmente errado (4.137), e trivial tem teste próprio (4.205). "É pequena,
   então é trivial" é exatamente a inferência proibida — a estimativa não aparece na
   triagem como critério e não promove nem rebaixa categoria.

## §2. Unidade — composta, por fase

A dimensão de uma demanda é expressa em **duas camadas**:

- **Estrutura prevista**: `~N waves · ~N tasks (~X small · ~Y medium)` — a semântica e
  as faixas de horas de `small`/`medium` são as do **dono único**, o princípio 7 de
  `commands/tasks.md` (nunca copiadas aqui — a cópia literal divergiu uma vez). O
  vocabulário `small|medium` aparece **só** como mix previsto de tasks; o campo
  `Tamanho estimado` continua exclusivo da TASK (enum fechado, ERROR de lint fora dele).
  **Descontinuidade de calibração (decisão 4.300)**: a semântica mudou em 2026-08-29
  (`medium` passou de "caso de uso, 2–4 h" a "comportamento fim-a-fim, ~2–8 h") — par
  estimado × realizado anterior a essa data calibra com a régua velha; compare eras
  separadas em `estimates.md`, nunca a série inteira como contínua.
- **Faixa de tempo por fase** (`min–max`, em horas — ordem de grandeza, precedente do
  `value-test-protocol.md`), cobrindo o **ciclo inteiro**:
  - **forja/entrevista** — rodadas de brief prováveis, proporcional às lacunas do pedido;
  - **artefatos** — specify + plan + tasks (escrita e validators);
  - **implementação** — derivada do mix de tasks × semântica de horas × paralelismo de
    waves;
  - **gates** — review (sempre) + security/qa/performance/design pelos gatilhos usuais
    da demanda, incluindo margem de re-gates quando a área é sensível ou nova.

Faixa larga com confiança declarada vale mais que número preciso e falso: a incerteza é
parte da resposta, não ruído a esconder.

## §3. Esqueleto da estimativa (fonte única)

```markdown
## Estimativa — <título curto> (<YYYY-MM-DD>)

- **Base**: <o que foi lido: pedido · INDEX de <slug> · calibração (N demandas) | sem base histórica>
- **Dimensão**: ~N waves · ~N tasks (~X small · ~Y medium)
- **Por fase**: forja <min–max> · artefatos <min–max> · implementação <min–max> · gates <min–max>
- **Total**: <min–max> (horas de ciclo, não prazo de calendário)
- **Confiança**: alta | média | baixa — <motivo em meia linha>
- **Premissas**: <o que foi assumido para estimar — 1 linha cada | nenhuma>
- **Lacunas**: <o que reduziria a incerteza | nenhuma>
```

Veredito `não estimável` substitui o bloco por: motivo + lacunas nomeadas (mesma
disciplina de proposta + default da escalação — cada lacuna vem com a pergunta pronta).

## §4. Persistência e confronto

- **Registro, por rota**: a **largada do `/keelson:auto`** estima sempre (item 6.6 da
  Etapa 0.5, decisão 4.224) — nas rotas com BRIEF em arquivo, grava o bloco do §3 como
  seção `## Estimativa` sem confirmação (registro, não decisão; best-effort: falha ou
  `não estimável` → o ciclo segue sem a seção, declarado no report). O
  **`/keelson:estimate`** avulso grava no BRIEF existente só com confirmação do
  Diretor; estimativa avulsa sem BRIEF não persiste (é resposta, não artefato) — mas se
  a demanda largar o ciclo **na mesma sessão**, a largada reutiliza o bloco em vez de
  re-estimar.
- **Confronto no fecho**: rota com `## Estimativa` no BRIEF → o report emite a linha
  `Estimativa × realizado` (`report-contract.md` §2): estrutura prevista vs. waves/tasks
  reais do `TASK-MMM-INDEX` · faixa total vs. duração **medida** · desvio em meia linha.
  A duração medida vem do `cycle-clock.sh` sobre as TASKs do PLAN (decisão 4.325 —
  formato e degradação são do `report-contract.md`, dono da linha): a `soma-tasks`
  (trabalho, união de intervalos) é a grandeza comparável à faixa em horas; a `parede`
  acompanha como lead time. Funciona com o ciclo atravessando sessões, porque lê as
  marcas commitadas das closures — grandeza sem marca é omitida com a completude
  declarada, nunca estimada (§1.2).
- **Calibração**: o mesmo fecho anexa **uma linha** em
  `guidelines/project/estimates.md` (par do `lessons.md` — memória do projeto, não do
  plugin):

  ```markdown
  - <YYYY-MM-DD> · <slug — demanda> · previsto: ~N waves/~N tasks · <min–max>h · realizado: N waves/N tasks · <duração medida> · desvio: <meia linha>
  ```

  A `<duração medida>` transcreve as duas grandezas do `cycle-clock` rotuladas
  (`parede <H>h<MM>min · trabalho <H>h<MM>min`); grandeza omitida na saída → a
  completude no lugar (`N de M TASKs com marca`).

  O `estimator` **lê este arquivo antes de estimar** e usa os desvios como corretor;
  com **menos de 3 demandas fechadas**, declara `sem base histórica` na linha `Base` e
  não finge calibração. Arquivo ausente → criar no primeiro fecho com estimativa.

## §5. Espelho no tracker (opt-in `jira.estimate`)

Com `jira.enabled` + `jira.estimate: true` na ficha, o gancho do §18 do
`jira-sync-protocol.md` publica a estimativa na issue principal — comentário
estruturado de 1 linha (campo personalizado quando o mapa de campos do projeto, 4.65,
definir `estimate`). Regras herdadas: best-effort §0 (conector caído → evento `tracker`
no ledger, reconciliação publica o atrasado) · **nunca worklog** (worklog é relógio
medido, 4.193) · resultado declarado na linha do report
(`publicada | falhou (motivo) | não estimável`) — ativo sem linha é defeito do report
(forma da 4.196).
