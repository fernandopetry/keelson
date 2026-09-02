# Protocolo comum dos validators (spec / plan / task)

> Fonte única da moldura compartilhada pelas skills `spec-validator`, `plan-validator` e
> `task-validator`. Cada SKILL.md contém apenas os checks próprios do seu artefato e
> aponta para cá ("protocolo §N").

Índice: §1 calibração por exemplares · §2 setup · §3 severidades e auto-fix · §4 gate de
status e override · §5 relatório · §6 evento de aprendizado · §7 limites.

## §1. Calibração por exemplares (antes de reprovar por convenção)

O padrão-ouro vivo são os artefatos **aprovados/mergeados** do projeto (SPECs aprovadas,
PLANs aprovados, TASKs Done de PLANs mergeados). Se um check de convenção diverge da
prática real de 2–3 deles, suspeite da regra, não do artefato: não gere ERROR; emita
`evento_aprendizado` de falso positivo (§6).

## §2. Setup

**Onde a skill roda (decisão 4.42)**: na main session (padrão) **ou** num subagent
executor — nesse caso, o briefing do spawn **DEVE** citar o caminho do `SKILL.md`
canônico da skill (`${CLAUDE_PLUGIN_ROOT}/skills/<skill>/SKILL.md`), com instrução de
aplicá-lo integralmente e devolver o output no formato deste protocolo. Subagent
validando "de memória", sem ler o SKILL.md, usa outra régua — é desvio, e o hook
`agent-guard` bloqueia o spawn genérico que não traz a citação.

1. Ler a **ficha** (`keelson.config.json` na raiz): `docsRoot` resolve todo caminho
   `{docsRoot}/...` (sem ficha, assumir `docs/`); `profile.<role>.file` aponta o perfil
   de linguagem ativo — fonte **primária** de stack/convenções (a mesma de que o comando
   gerador gera).
2. Ler o artefato-alvo e o contexto que a SKILL lista.
3. Ler `CLAUDE.md` se existir — fonte **complementar**: ausência dele, ou omissão de uma
   convenção nele, nunca gera ERROR.
4. Inicializar as listas `errors`, `warnings`, `infos`, `auto_fixes_applied`.

## §3. Severidades e auto-fix

- **ERROR** bloqueia (gate de status, §4). **WARNING** não bloqueia, mas pede revisão.
  **INFO** é informativo.
- Violação trivial e segura (case de RFC 2119, zero-padding, acentuação de campo) recebe
  **auto-fix sem confirmação**: aplicar no arquivo e registrar
  `<linha>: <antes> → <depois>` em `auto_fixes_applied`.

## §4. Gate de status e override

Após os auto-fixes, recontar `errors`:

- `errors` não-vazia e Status `Approved` → forçar Status para `Draft` e registrar no
  artefato uma seção `## Histórico de validação` com data e motivo. (TASK: com ERROR ela
  não é executável pelo `/keelson:implement`; Status `Todo` é forçado para `Blocked`.)
- `errors` vazia → o artefato **pode** ser promovido. A promoção **nunca é do validator**:
  no ciclo com BRIEF (modo autônomo), quem promove é a main session, pelo veredito
  `APROVAR` do `po` (decisão 4.38); sem brief ou no `/keelson:guided`, é o humano.

Override consciente, declarado no próprio artefato:

```yaml
override-erros: <IDs>
override-justificativa: <texto>
override-aprovador: <nome>
```

Respeite o override com justificativa; mantenha o ERROR no relatório com flag `OVERRIDDEN`.

## §4.5. Revalidação após pacote de correção (decisão 4.350)

Segunda passada sobre artefato que acabou de receber um pacote de correção (4.309/4.349)
não repete a primeira — ela responde só ao delta, em dois ramos, e o corte entre eles é
**por id de check, nunca por rótulo em prosa** ("só forma" não é decidível pelo lint:
sinônimo de glossário, FR composto, sujeito vago são julgamento — `lint-contract.md` §1).

- **Ramo mecânico** — todo ajuste do pacote responde a check que nasce como **fato** no
  catálogo (`lint-contract.md` §3: ids sem `(W)` — campo/seção ausente, enum, id fora do
  número, critério sem AC, cobertura vazia…) e nenhum ajuste mira mérito ou estrutura: a
  revalidação é `artifact-lint.sh` (sempre em **modo diretório**, para os checks
  cross-arquivo — 4.326) + `graph.sh --check` + `edge-diff.sh` por arquivo tocado
  (4.117/4.154), rodados pela main session. **Sem validator LLM.** A linha `Classes` da
  cauda de telemetria (4.275) transcreve a saída do lint; `correções` conta a volta igual.
  Sobrou ERROR → ramo de julgamento.
- **Ramo de julgamento** — pacote com ajuste de mérito, de estrutura ou de check `(W)` que
  o validator escalou por leitura: o validator roda de novo, **delta-scoped** — recebe no
  briefing a **lista literal dos arquivos e seções corrigidos** e o **relatório anterior**,
  e responde só sobre eles: o que a passada anterior aprovou permanece aprovado salvo se
  um ajuste o tocou (espírito 4.88). O fato mecânico do ramo acima roda antes e entra
  citado (`graph-contract.md` §5); o relatório segue o §5 abaixo, com `Classes` só do delta.

Caso real de campo (plugin 0.147.0): a revalidação da SPEC custou 10,2 min contra 8,1 da
primeira passada, e a das TASKs 17,8 contra 14,5 — o validator releu o artefato inteiro
(19 leituras + 22 greps) para revalidar 8 erros já localizados.

## §5. Relatório

```markdown
# Relatório de validação: <ID do artefato>

**Arquivo**: <caminho>
**Status atual**: <status>
**Resultado**: PASSOU | PASSOU COM RESSALVAS | BLOQUEADO

## Resumo
- Errors: N (M corrigidos, K pendentes) | Warnings: N | Infos: N
- Classes: <check-id>(N) · <check-id>(N) — decrescente | nenhuma

## Auto-fixes aplicados
- linha 12: `[must]` → `[MUST]`

## Errors pendentes
- **[<ID/check>]** <violação>.
  Sugestão: <ação>

## Warnings / Infos
- ...

## Próximos passos
1. Resolver errors pendentes e validar novamente
2. Quando errors == 0, promover Status (quem promove: regra do §3 — po/main session no ciclo com BRIEF; humano no avulso/guided)
```

Múltiplos artefatos no input → validar em sequência e consolidar num relatório só.

A linha `Classes` agrega errors e warnings pelo token que cada achado já carrega
(`[<ID/check>]`, tal como emitido — fato mecânico e julgamento da skill igualmente).
É insumo de **transcrição** para a telemetria da forja — cauda da `## Cronologia` do
BRIEF e linha `Forja` do report de fecho (decisão 4.275) — nunca gatilho de reação:
o canal de reação continua sendo o evento de aprendizado (§6).

## §6. Evento de aprendizado (telemetria do processo)

Se o artefato validado foi **recém-gerado por um comando do keelson** (não escrito/editado
por humano) e restou ERROR não auto-corrigível, acrescente ao relatório um bloco para a
main session rotear ao `agile-coach`:

```yaml
evento_aprendizado:
  gatilho: validator_error
  descricao: <qual ERROR o gerador produziu>
  causa_raiz: <que instrução do gerador faltou/foi ambígua>
  artefato_suspeito: commands/<comando-gerador>.md
```

Falso positivo recorrente do próprio validator também é evento (`artefato_suspeito`: a
própria skill).

## §7. Limites

Nenhum validator valida **mérito**: se o artefato ataca o problema certo, se a escolha
técnica é a melhor, se a granularidade é a ideal. Forma e consistência, não estratégia.
Validators também não reescrevem o artefato — reportam, sugerem e aplicam só auto-fix
óbvio e seguro (§3).
