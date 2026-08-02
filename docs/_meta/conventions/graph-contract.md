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
| `maps` | FR → COMP | tabela §7 do PLAN (ACs da linha viram `maps-ac`) |
| `comp-realiza` | COMP → FR | `**Realiza**:` do bloco COMP |
| `comp-dep` | COMP → COMP | `**Dependências**:` do bloco COMP |
| `belongs-to` | TASK → PLAN | `**Pertence a**:` |
| `realiza` | TASK → FR | `**Realiza (FRs)**:` |
| `implements` | TASK → COMP | `**Componente**:` |
| `declares-feat` | TASK → FEAT | `**Funcionalidade**:` (formas `(primária)` / `transversal (…)`) |
| `violates` | TASK → AC | `**AC violado**:` (só bugfix) |
| `task-dep` | TASK → TASK | `- **Depende de**:` |
| `blocks` | TASK → TASK | `- **Bloqueia**:` |
| `covers-ac` | TASK → AC | itens `- [ ]` de "Critérios de pronto" ∪ linhas do "Roteiro do gate 9" |
| `ac-covers` | AC → FR\|NFR | `(cobre …)` do AC |
| `feat-of` | FR → FEAT | posicional: FR sob heading `### FEAT-` na §5 da SPEC |

Nós: `SPEC · FR · NFR · AC · FEAT · PLAN · COMP · DEC · TASK` (TASK carrega atributos
`wave`, `status`, `tipo`). Fontes: somente `specs/SPEC-*.md`, `plans/PLAN-*.md` e
`tasks/TASK-*.md` — `TASK-*-INDEX.md`, `INDEX.md`, `briefs/`, `handoffs/` e `legacy/`
são derivados ou prosa livre, **nunca fonte de nó/aresta**. `covers-ac` ignora menção
a AC em prosa fora de item `- [ ]` (menção de realocação não é cobertura).
Cross-PLAN: aresta para nó de outro PLAN/SPEC do **mesmo slug** é válida — a
existência resolve no slug inteiro.

## §3. Catálogo de checks

**Carência de legado**: nos checks marcados, achado sobre artefato `Status: Done`
(TASK) — ou PLAN `Done`, nos de cobertura — é rebaixado para `WARNING` com sufixo
`[legacy]`: o acervo antigo não reprova por régua que nasceu depois dele. Checks
estruturais de integridade (ciclo, referência, duplicidade) valem sempre — sempre
foram ERROR nos validators.

| Check | Achado | Severidade |
|---|---|---|
| `ciclo-task` | ciclo em `task-dep` | ERROR (sempre) |
| `ciclo-comp` | ciclo em `comp-dep` | ERROR (sempre) |
| `ref-quebrada` | aresta apontando para nó inexistente no slug | ERROR (sempre) |
| `id-duplicado` | mesmo ID de nó declarado 2+ vezes (precedente §4.63) | ERROR (sempre) |
| `pertence-vs-arquivo` | MMM de `Pertence a` ≠ MMM do nome do arquivo | ERROR |
| `wave-incoerente` | `wave(T) ≤ wave(dep)` no **mesmo** PLAN (cross-PLAN não se aplica) | ERROR · carência |
| `fr-sem-task` | FR coberto pelo PLAN sem `realiza` de TASK dele (NFR não entra: NFR não é realizado por TASK — verifica-se na DoD do PLAN) | ERROR · carência |
| `ac-sem-task` | AC de FR coberto sem `covers-ac` de TASK do PLAN | ERROR · carência |
| `realiza-fora-cobertura` | TASK realiza FR que o PLAN dela não cobre | ERROR |
| `feat-divergente` | `declares-feat` ≠ conjunto derivado (`realiza` × `feat-of`), ou primária fora dele — só roda quando o conjunto derivado é não-vazio (campo presente com SPEC sem FEATs é matéria do validator, WARNING+auto-fix) | ERROR |
| `fr-mapeado-fora-cobertura` | §7 mapeia FR fora de `plan-covers` | ERROR |
| `fr-sem-comp` | FR coberto pelo PLAN sem linha na §7 dele | ERROR · carência |
| `comp-sem-fr` | COMP sem linha na §7 | WARNING |
| `realiza-vs-mapeamento` | `comp-realiza` divergente da §7 (a §7 é a fonte de cobertura) | WARNING |
| `dep-bloqueia-assimetrica` | A depende de B sem B bloquear A (ou vice-versa) | WARNING |
| `index-desatualizado` | `TASK-MMM-INDEX.md` diverge do computado (waves, tabelas FR/AC) — best-effort | WARNING |

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
  `realiza-vs-mapeamento`) — PLAN recém-criado sem `tasks/` sai 0. `--stage=tasks`
  (ou sem flag) roda tudo. `--plan MMM` restringe ao PLAN indicado.
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
