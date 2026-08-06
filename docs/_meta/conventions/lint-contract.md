# Lint mecânico de forma dos artefatos SDD — contrato do artifact-lint.sh

> Fonte única (decisão 4.152) do **contrato de invocação/saída** e da **régua de
> severidade** de `scripts/artifact-lint.sh`. A moldura dos validators é o
> `skills/_shared/validator-protocol.md`; o catálogo de checks de *julgamento* continua
> em cada SKILL.md — este contrato cobre o subconjunto **mecânico** que os validators
> passam a citar como fato (mesma arquitetura do `graph-contract.md`, decisão 4.82).

## §1. Princípio de severidade

- **Fato inequívoco** (seção obrigatória ausente, campo de cabeçalho ausente, enum
  inválido, número de ID divergente do arquivo, lista vazia onde o template exige
  conteúdo) sai com a severidade que o catálogo do validator prescreve — inclusive ERROR.
- **Check baseado em padrão** (EARS por regex, wordlist de tecnologia, Dado-Quando-Então,
  termos vagos de NFR, marcadores de premissa) sai **no máximo como WARNING** — quem
  escala para ERROR é o validator, com olhos no texto. Falso ERROR em artefato legítimo
  é o pior defeito desta camada.
- **Carência de legado**: artefato com `Status: Done` rebaixa todo ERROR para
  `WARNING` com sufixo `[legacy]` (mesma régua do graph-contract §3).
- **Julgamento não entra**: sujeito vago, FR composto, sinônimo de glossário, cobertura
  reversa do escopo, "verificação executável prova o AC", aresta de interface aberta —
  continuam exclusivos do validator.
- Calibração com piso: `spec-must-ratio`/`spec-sem-should-may` só disparam com **3+
  FRs** (SPEC de 1–2 FRs não é falta de priorização).

## §2. Invocação e saída

```
scripts/artifact-lint.sh <caminho> [<caminho>…]
```

- `<caminho>`: arquivo `SPEC-*.md`, `PLAN-*.md` ou `TASK-*.md` (tipo inferido do nome),
  ou **diretório do slug** (`{docsRoot}/<slug>` já resolvido) — linta todos os artefatos
  e acrescenta os checks cross-arquivo (`plan-overlap-fr`, `task-overlap-fr`).
- No consumidor: `${CLAUDE_PLUGIN_ROOT}/scripts/artifact-lint.sh`; num subagent executor
  sem a env var, derive a raiz do plugin do caminho do SKILL.md citado no briefing.
- Saída: `SEVERIDADE<TAB>check<TAB>detalhe (arquivo)`, ordenada com `LC_ALL=C`.
- Exit: `0` sem ERROR · `1` com ERROR · `2` uso incorreto. Read-only.
- Bash 3.2+ e awk POSIX, sem dependências novas.

## §3. Catálogo (o que chega como fato)

O detalhe de cada regra vive no SKILL.md do validator correspondente; aqui, o
inventário fechado do que o script computa. Prefixos: `spec-` (spec-validator),
`plan-` (plan-validator), `task-` (task-validator).

| Grupo | Checks |
|---|---|
| Cabeçalho e enums | `spec/plan/task-campo-ausente` · `spec/plan-status-enum` (Draft/Review/Approved/Done) · `task-status-enum` (Todo/In Progress/Done/Blocked) · `task-tamanho-enum` · `task-tipo-enum` · `task-tipo-ausente` · `spec-autor-preencher` · `spec/plan-data-formato` |
| Seções do template | `spec-secao-ausente` (§1–§10 + 1.1/1.2/1.3/4.1/4.2) · `plan-secao-ausente` (Aderência, Cobertura, §1–§10) · `task-secao-ausente` (8 seções + Inclui/Não inclui) |
| IDs | `spec/plan-id-fora-do-numero` (NNN/MMM ≠ arquivo) · `spec/plan-id-zero-pad` |
| SPEC §5–§7 | `spec-fr-sem-rfc` · `spec-rfc-forma` · `spec-fr-sem-deve` · `spec-ears-nao-casa` (W) · `spec-fr-palavras` (>30) · `spec-must-ratio` (>70%, 3+ FRs) · `spec-sem-should-may` · `spec-porte-epico` (>30 FRs) · `spec-nfr-vago` (W) · `spec-nfr-sem-numero` (W) · `spec-ac-fora-gwt` (W) · `spec-tecnologia` (W, wordlist da Etapa 5 do SKILL) |
| SPEC FEATs | `spec-feat-particao` · `spec-feat-vazia` · `spec-feat-fora-da-5` · `spec-feat-unica` (W) · `spec-feat-sem-descricao` (W) |
| SPEC métrica/escopo/premissas | `spec-metrica-sem-numero` (W) · `spec-metrica-sem-fonte` (W, Draft/Review) · `spec-out-of-scope-vazio` · `spec-out-of-scope-curto` (W) · `spec-in-eq-out` · `spec-sem-premissa` (W) · `spec-sem-risco` (W) · `spec-premissa-sem-marcador` (W) · `spec-premissa-sem-selo` (W, Draft/Review) · `spec-confirmar-teto` (W, Draft/Review) · `spec-glossario-nao-usado` (W) |
| PLAN cobertura/DEC/DoD | `plan-cobertura-sem-spec` · `plan-frs-cobertos-vazio` · `plan-cobertura-agregada-ausente` · `plan-dec-campo-ausente` · `plan-dec-sem-alternativa` · `plan-dec-alternativa-unica` (W) · `plan-dec-irreversivel-enum` · `plan-dec-irreversivel-forma` (W) · `plan-dec-sem-reabrir` (W, Draft/Review) · `plan-reabrir-nunca-sem-motivo` (W) · `plan-mapeamento-vazio` · `plan-dod-vazia` · `plan-dod-placeholder` · `plan-dod-sem-teste` (W) · `plan-dod-sem-perfil` (W) |
| TASK | `task-nome-tipo` (W) · `task-wave2-sem-dep` (W) · `task-feat-sem-primaria` · `task-feat-transversal-uma` · `task-criterios-vazios` · `task-criterio-sem-ac` · `task-bugfix-sem-ac-violado` · `task-bugfix-forma-legada` (INFO) · `task-refactor-sem-identidade` · `task-done-gate-aberto` (W) |
| Cross-arquivo (modo diretório) | `plan-overlap-fr` (W) · `task-overlap-fr` (W) |

(`(W)` = nasce WARNING por ser padrão/heurística — §1.)

## §4. O fato no validator

Idêntico ao §5 do `graph-contract.md`, que é o dono da régua: cada achado entra no
relatório como `**[artifact-lint]** SEVERIDADE check — detalhe`; **degradação por
resultado** (sem saída válida → checks por leitura, degradação declarada com causa) e
**calibração final do validator** (exemplares e overrides continuam mandando; o fato
substitui a derivação, nunca o julgamento).

## §5. Suíte de regressão

`scripts/tests/artifact-lint/` — fixtures `valido` (sai limpa), `defeitos` (todo check
com defeito plantado), `legado` (prova o rebaixamento `[legacy]`) + saídas esperadas
congeladas + `run.sh`. Check novo não entra no catálogo sem fixture; mudança de
severidade é decisão explícita (§4.x), nunca efeito colateral do script.
