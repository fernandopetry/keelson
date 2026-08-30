# Grafo dos artefatos SDD — arestas, checks e contrato do extrator

> Fonte única (decisão 4.82) da **sintaxe canônica das arestas**, do **catálogo de
> arestas e checks** e do **contrato de invocação/saída** de `scripts/graph.sh`.
> Formatos de ID e árvore de artefatos têm dono próprio — `index-contract.md` — e são
> referenciados aqui, nunca redefinidos. Os templates geradores (`/keelson:specify`,
> `/keelson:plan`, `/keelson:tasks`) e os validators (`plan-validator`,
> `task-validator`) apontam para cá; nenhum deles recopia esta régua.
>
> Princípio (§4.81 aplicado ao grafo): **o markdown é a fonte; o grafo é derivado** —
> regenerável a qualquer momento, nunca editado, nunca armazenado como verdade.

## §1. Sintaxe canônica de campo de aresta

Um campo de aresta é uma linha `**Campo**: valor` cujo valor é **lista de IDs
separados por vírgula** ou a palavra **`nenhuma`**:

```markdown
**Dependências**: COMP-001-002, COMP-001-003
**Depende de**: nenhuma
```

- Prosa explicativa **não** entra no campo — vive nas seções de prosa do artefato.
- Campo **vazio ou ausente** equivale a `nenhuma` (tolerância ao acervo legado — sem
  aviso). Conteúdo **irreconhecível** (prosa, ID fora do formato do
  `index-contract.md`) degrada: `WARNING nao-parseavel`, nunca ERROR, nunca aborta.
- Variação inócua é tolerada: espaços, crase em volta do ID, negrito, CRLF/BOM.
- O `(cobre …)` do AC segue a mesma régua em forma parentética:
  `(cobre FR-NNN-XXX, NFR-NNN-YYY)` — IDs completos, separados por vírgula; sem
  barra-abreviação (`FR-x/y`) nem sub-item (`FR-x-001a`).

## §2. Catálogo de arestas

| Aresta | De → Para | Fonte (campo/seção do artefato) |
|---|---|---|
| `spec-ref` | PLAN → SPEC | `**SPEC referenciada**:` |
| `plan-covers` | PLAN → FR\|NFR | bullets de `FRs cobertos` / `NFRs cobertos` |
| `maps` | FR → COMP | tabela §7 do PLAN (ACs da linha viram `maps-ac`; a célula Componente aceita lista — um FR entregue por 2+ COMPs) |
| `comp-realiza` | COMP → FR | `**Realiza**:` do bloco COMP |
| `comp-dep` | COMP → COMP | `**Dependências**:` do bloco COMP |
| `belongs-to` | TASK → PLAN | `**Pertence a**:` |
| `realiza` | TASK → FR | `**Realiza (FRs)**:` |
| `implements` | TASK → COMP | `**Componente**:` (aceita lista — fatia vertical atravessa 2+ COMPs; a anotação `(principal)` é tolerada pelo parser e não emite aresta própria — 4.157) |
| `declares-feat` | TASK → FEAT | `**Funcionalidade**:` (formas `(primária)` / `transversal (…)`) — a marca `(primária)` emite também a aresta auxiliar `feat-primaria` (TASK → FEAT), consumida pelo check `feat-divergente` |
| `violates` | TASK → AC | `**AC violado**:` (só bugfix) |
| `task-dep` | TASK → TASK | `- **Depende de**:` |
| `blocks` | TASK → TASK | `- **Bloqueia**:` |
| `covers-ac` | TASK → AC | toda linha de "Critérios de pronto" ∪ "Roteiro do gate 9" — continuação de item multi-linha incluída (4.254) |
| `ac-covers` | AC → FR\|NFR | `(cobre …)` do AC |
| `feat-of` | FR → FEAT | posicional: FR sob heading `### FEAT-` na §5 da SPEC |
| `task-brief` | TASK → BRIEF | `**Brief**:` — âncora da TASK avulsa (decisão 4.86); exclusiva com `belongs-to` |

Nós: `SPEC · FR · NFR · AC · FEAT · PLAN · COMP · DEC · TASK · BRIEF` (TASK carrega
atributos `wave`, `status`, `tipo`; BRIEF carrega `status` e `crit` — 1 quando o heading
`## Critério de aceite` existe). Fontes: `specs/SPEC-*.md`, `plans/PLAN-*.md`,
`tasks/TASK-*.md` **e `briefs/BRIEF-*-avulso.md`** (só o sabor avulso — decisão 4.86) —
`TASK-*-INDEX.md`, `INDEX.md`, os demais sabores de `briefs/` (pareado, épico),
`handoffs/` e `legacy/` são derivados ou prosa livre, **nunca fonte de nó/aresta**.
`covers-ac` alcança **qualquer linha** das seções "Critérios de pronto" e "Roteiro do
gate 9" — item multi-linha cita o AC na continuação, que não tem bullet (4.254; a
restrição anterior a itens `- [ ]` deixava o AC da 2ª linha sem dono e o índice
mentindo). Menção a AC **fora** dessas duas seções continua não sendo cobertura
(menção de realocação em Contexto/Escopo não é cobertura).
Cross-PLAN: aresta para nó de outro PLAN/SPEC do **mesmo slug** é válida — a
existência resolve no slug inteiro.

## §3. Catálogo de checks

**Carência de legado**: nos checks marcados, achado sobre artefato `Status: Done`
(TASK) — ou PLAN `Done`, nos de cobertura — é rebaixado para `WARNING` com sufixo
`[legacy]`: o acervo antigo não reprova por régua que nasceu depois dele. Checks
estruturais de integridade (ciclo, referência, duplicidade) valem sempre — sempre
foram ERROR nos validators.

**Degradação `[parse]`**: campo não-parseável (aviso `nao-parseavel`) que alimenta um
check de **ausência** — `FRs/NFRs cobertos` → cobertura; `Realiza (FRs)` → cobertura;
`Mapeamento §7` → mapeamento — rebaixa os achados de ausência daquele PLAN para
`WARNING` com sufixo `[parse]`: a promessa "irreconhecível nunca vira ERROR" vale de
ponta a ponta, e o validator decide com os próprios olhos (cobertura mista, §5).

| Check | Achado | Severidade |
|---|---|---|
| `ciclo-task` | ciclo em `task-dep` | ERROR (sempre) |
| `ciclo-comp` | ciclo em `comp-dep` | ERROR (sempre) |
| `ref-quebrada` | aresta apontando para nó inexistente no slug | ERROR (sempre) |
| `id-duplicado` | mesmo ID de nó declarado 2+ vezes (precedente §4.63) | ERROR (sempre) |
| `pertence-vs-arquivo` | MMM da âncora (`Pertence a` ou `Brief`) ≠ MMM do nome do arquivo/ID | ERROR |
| `wave-incoerente` | `wave(T) ≤ wave(dep)` no **mesmo** PLAN (cross-PLAN não se aplica) | ERROR · carência |
| `fr-sem-ac` | FR declarado na SPEC sem nenhum AC que o cubra (aresta `ac-covers`) — o lado interno da verificabilidade; `fr-sem-task`/`ac-sem-task` olham TASK, este olha a própria SPEC (decisão 4.153). SPEC `Status: Done` → `WARNING [legacy]` | ERROR · carência |
| `plan-status-vs-tasks` | PLAN com `Status: Done` e ≥1 TASK dele com status aberto — a promoção correu na frente da execução (irmão PLAN-level do `status-vs-closure`; decisão 4.153). TASK sem status parseável não conta como aberta — degrada na direção segura | WARNING |
| `fr-sem-task` | FR coberto pelo PLAN sem `realiza` de TASK dele (NFR não entra: NFR não é realizado por TASK — verifica-se na DoD do PLAN) | ERROR · carência |
| `ac-sem-task` | AC de FR coberto sem `covers-ac` de TASK do PLAN | ERROR · carência |
| `realiza-fora-cobertura` | TASK realiza FR que o PLAN dela não cobre | ERROR |
| `feat-divergente` | `declares-feat` ≠ conjunto derivado (`realiza` × `feat-of`), ou primária fora dele — só roda quando o conjunto derivado é não-vazio (campo presente com SPEC sem FEATs é matéria do validator, WARNING+auto-fix) | ERROR |
| `fr-mapeado-fora-cobertura` | §7 mapeia FR fora de `plan-covers` | ERROR |
| `fr-sem-comp` | FR coberto pelo PLAN sem linha na §7 dele | ERROR · carência |
| `comp-sem-fr` | COMP sem linha na §7 | WARNING |
| `realiza-vs-mapeamento` | `comp-realiza` divergente da §7 (a §7 é a fonte de cobertura) | WARNING |
| `dep-bloqueia-assimetrica` | A depende de B sem B bloquear A (ou vice-versa) — suprimido quando quem deveria declarar é TASK `Done` de outro PLAN (reeditar artefato entregue seria pior que a assimetria) | WARNING |
| `index-desatualizado` | `TASK-MMM-INDEX.md` diverge do computado (waves, tabelas FR/AC) — best-effort | WARNING |
| `brief-sem-criterio` | brief avulso sem heading `## Critério de aceite` (forma do esqueleto — decisão 4.86) | WARNING |
| `task-ancora-dupla` | TASK com `Pertence a` **e** `Brief` preenchidos (âncora é exclusiva) | ERROR |
| `feat-sem-verificacao` | FEAT com 1+ TASK declarante, **todas Done**, sem linha `**Verificação (gate 9)**:` sob o heading na SPEC (recorte do gate 9 por FEAT — decisão 4.90). A linha é livre no conteúdo (data e como, ou `n/a — motivo`); a **presença** é o declarado. SPEC `Status: Done` (ciclo fechado antes da 4.90) → `WARNING [legacy]`. TASK não-parseável sem status derruba o "todas Done" e o check silencia — degrada na direção segura, nunca inventa ERROR | ERROR · carência |
| `metrica-sem-veredito` | SPEC com `**Fonte de medição**:` na §1.3 (regime da 4.99), **≥1 PLAN `Done`** que a referencia (`spec-ref`) e sem linha `**Veredito de métrica**:` — o loop measure-learn está aberto. SPEC sem a linha de fonte fica **fora** (acervo pré-4.99 não gera ruído; sem lógica de data). 1º check `INFO` do catálogo: lembrete vivo até o veredito, nunca muda o exit code | INFO |
| `status-vs-closure` | TASK com closure preenchida (`**Data conclusão**:` ou `**Commit SHA**:` não-vazios sob `## Histórico de execução`) e `Status:` do cabeçalho ≠ `Done` — a closure encheu o histórico e esqueceu o campo que todo mundo lê (caso real: 5 TASKs erradas por 7 waves, só o sync do tracker viu — decisão 4.131). WARNING, nunca ERROR: TASK no meio da própria closure é estado transitório legítimo | WARNING |

`ref-quebrada` cobre também a âncora avulsa (TASK com `**Brief**:` apontando BRIEF
inexistente no slug) — não é check novo, é o genérico sobre `task-brief`. TASK sem
nenhuma âncora continua matéria do `task-validator` (tolerância ao acervo legado, §1).

## §4. Invocação e saída

```
scripts/graph.sh <dir-do-slug> [--check] [--stage=plan|tasks] [--format=tsv|mermaid|mermaid-comp] [--plan MMM]
```

- `<dir-do-slug>` é o diretório **já resolvido** (`{docsRoot}/<slug>` — quem resolve
  `docsRoot` é o chamador, que leu a ficha; o script não parseia JSON).
- No consumidor: 1ª tentativa `${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh`; num subagent
  executor (decisão 4.42), a raiz do plugin deriva do caminho do SKILL.md citado no
  briefing (prefixo antes de `/skills/`).
- `--stage=plan` roda só o computável sem TASKs (`ciclo-comp`, `ref-quebrada` do lado
  PLAN/SPEC, `id-duplicado`, `fr-mapeado-fora-cobertura`, `fr-sem-comp`, `comp-sem-fr`,
  `realiza-vs-mapeamento`, `fr-sem-ac`) — PLAN recém-criado sem `tasks/` sai 0. `--stage=tasks`
  (ou sem flag) roda tudo. `--plan MMM` restringe ao PLAN indicado — MMM numérico
  (com ou sem zero-padding); PLAN inexistente no slug é uso incorreto (exit 2),
  nunca "verde em silêncio".
- `--format=tsv` emite o grafo: `node<TAB>TIPO<TAB>ID<TAB>arquivo<TAB>attrs` ·
  `edge<TAB>TIPO<TAB>DE<TAB>PARA<TAB>arquivo:linha` ·
  `warn<TAB>nao-parseavel<TAB>arquivo<TAB>campo<TAB>trecho` — ordenado com
  `LC_ALL=C`, determinístico byte a byte.
- `--check` emite achados: `SEVERIDADE<TAB>check<TAB>detalhe` (severidade em
  `{ERROR, WARNING, INFO}`).
- `--format=mermaid` — flowchart das TASKs por wave (subgraph por wave, status no
  rótulo: ✅ Done · 🔵 In Progress · ⏸ Todo · 🚫 Blocked); `mermaid-comp` — FR → COMP
  (`maps`) + COMP → COMP (`comp-dep`).
- Exit: `0` sem ERROR · `1` com ERROR · `2` uso incorreto. Read-only sobre o slug.
- Bash 3.2+ (macOS `/bin/bash`, Linux, Git Bash), awk POSIX, sem dependências novas.

## §4.1. Reação do invocador a ERRORs na geração (decisão 4.114)

Quando o `--check` acusa ERROR logo após a geração de artefatos (Etapa 5 do
`/keelson:tasks` e análogos), a correção segue quatro regras:

1. **Quem roda o script é quem tem shell**: a main session executa o `graph.sh` e entrega
   ao `scribe` a **lista literal de ERRORs** no re-despacho — nunca a instrução "rode o
   grafo até limpar" (o scribe não tem Bash; exigência impossível volta em `duvidas`).
   Cada ajuste do pacote viaja com **âncora** — o **ID do elemento** mirado (FR/AC/NFR/
   DEC/COMP/TASK; todo relatório de validator/gate já o traz) mais heading da seção +
   trecho literal a localizar (a main os tem do relatório do validator/gate/PO). O ID é
   a parte estável da âncora: sobrevive quando outro ajuste do mesmo pacote desloca o
   trecho (decisão 4.312); defeito em prosa sem elemento identificável ancora só por
   heading + trecho. É a âncora que habilita o modo localizado da 4.309 (lote de `Edit`s
   lendo só as seções citadas — régua de aplicação no `agents/scribe.md`, passo 4).
   Ajuste sem âncora nenhuma rebaixa o pacote inteiro ao modo estrutural. E a 4.309 governa o **modo de aplicar** um pacote, nunca o número
   de voltas — a consolidação da 4.116 (uma rodada, uma volta) permanece intacta:
   correção pingada continua defeito, por mais barata que a volta tenha ficado.
2. **Correção é aguardada**: o re-despacho é síncrono do ponto de vista do fluxo — a main
   session espera o retorno e re-roda o script ela mesma. Agent em background + polling
   de filesystem é anti-padrão (caso real: ~14 min de `sleep`-loop para um delta; régua
   geral de espera de subagent: `sdd-conventions.md` — 4.118). A preservação de arestas
   do **arquivo depois do pacote** (4.117) também se **prova**, não se presume — nos
   **dois** modos de aplicação da 4.309 (lote de `Edit`s ou `Write` integral):
   `scripts/edge-diff.sh <arquivo> [--base <ref>]` compara os campos de aresta e os ACs
   de critérios antes/depois — linha `perdida` que nenhum ajuste pediu volta no
   re-despacho seguinte (decisão 4.154).
3. **Buraco de numeração não é defeito**: sequência com lacuna não gera check e não se
   "corrige" — e **arquivo existente nunca se renumera** (renumeração em massa quebra
   referências e deixa stubs que o scribe não consegue apagar).
4. **Operação de arquivo é da main session**: remoção/renomeação, quando necessária,
   acontece depois do retorno do scribe, nunca durante as edições dele.

## §5. O fato no validator — degradação e cobertura mista

Os validators executam o script e citam a saída como **fato** (formato no relatório:
`**[graph.sh]** SEVERIDADE check — detalhe`). Três réguas inegociáveis:

1. **Degradação por resultado, não por causa**: qualquer execução que não produza
   saída válida neste contrato (script ausente, exit 2, crash, saída malformada) →
   o validator volta ao raciocínio próprio e **declara** a degradação com a causa
   nomeada. Nunca trava o fluxo (mesmo padrão dos hooks).
2. **Cobertura mista**: artefato com `nao-parseavel` → o validator **não** cita
   ausência de defeito como fato para os checks que dependem daquela aresta — para
   aquele artefato vale o raciocínio próprio, e o relatório nomeia a cobertura mista.
3. **Calibração é do validator** (protocolo §1/§3): o script reporta; quem decide o
   que bloqueia — inclusive respeitando exemplares e overrides — é o validator.
   O fato substitui a *derivação*, nunca o julgamento.

## §6. Suíte de regressão

`scripts/tests/graph/` — fixtures (slugs sintéticos: válido, legado, defeitos
plantados ≥ 1 por check, stage) + saídas esperadas versionadas + `run.sh` que executa
`graph.sh` caso a caso e compara com `diff` (sai ≠ 0 na divergência). Mudou o parser?
A suíte re-prova a métrica da leva (zero falso-positivo no válido, todo defeito
acusado). Fixture nova acompanha check novo — check sem fixture não entra no catálogo.
Bug corrigido nasce com fixture do caso + controle positivo — régua da camada mecânica
inteira, texto no `lint-contract.md` (4.260); a variedade de forma realista tem cinto
no corpus (`scripts/tests/corpus/`), que congela as saídas de todos os motores
read-only sobre um slug sintético-realista.
