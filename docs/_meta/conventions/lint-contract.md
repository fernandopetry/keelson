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
  e acrescenta os checks cross-arquivo (`plan-overlap-fr`, `task-overlap-fr`,
  `task-wave-overlap-arquivo`).
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
| PLAN cobertura/DEC/DoD | `plan-cobertura-sem-spec` · `plan-frs-cobertos-vazio` · `plan-cobertura-agregada-ausente` · `plan-dec-campo-ausente` · `plan-dec-sem-alternativa` · `plan-dec-alternativa-unica` (W) · `plan-dec-irreversivel-enum` · `plan-dec-irreversivel-forma` (W — o valor é comparado após normalizar caixa, til e pontuação terminal: `não.` é forma, nunca enum; 4.341) · `plan-dec-sem-reabrir` (W, Draft/Review) · `plan-reabrir-nunca-sem-motivo` (W) · `plan-mapeamento-vazio` · `plan-dod-vazia` · `plan-dod-placeholder` · `plan-dod-sem-teste` (W) · `plan-dod-sem-perfil` (W) |
| TASK | `task-nome-tipo` (W) · `task-wave2-sem-dep` (W) · `task-feat-sem-primaria` · `task-feat-transversal-uma` · `task-criterios-vazios` · `task-criterio-sem-ac` (exige ID bem-formado `AC-N-N` em qualquer linha de Critérios/Roteiro — substring `AC-` solta, ex. dentro de um regex, não conta; 4.254) · `task-criterio-grep-nao-ancorado` (W, 4.161/4.255: `grep`/`rg` em critério sem exclusão de comentário nem âncora executável — absolvem só Reflection, exclusão `-v` e padrão ancorado em `^`; fronteira de símbolo `\b`/`::`/`->`/`class `/`function ` limita a palavra mas segue casando docblock/prosa e deixou de absolver) · `task-comando-contradiz-criterio` (W, 4.215: comando de Critérios/Roteiro do gate 9 usa `--group <tag>` e outra linha da mesma TASK — qualquer seção — proíbe a mesma tag; igualdade de tag exigida nos dois lados) · `task-bugfix-sem-ac-violado` · `task-bugfix-forma-legada` (INFO) · `task-refactor-sem-identidade` · `task-done-gate-aberto` (W) · `task-mutacao-sem-contagem` (W, 4.232: critério menciona mutação de predicado de escopo sem o par contável "N métodos … N provas" — o lint cobra a **forma** da declaração; o confronto número×código é do gate 8) · `task-prova-seguranca-com-grupo` (W, 4.233: arquivo de teste de segurança no Inclui — por padrão de **nome**, `*Permission*Test`/`*Security*Test`/`*Guard*Test`, best-effort declarado: ausência de achado não prova ausência de defeito — com comando de verificação usando `--group <tag>` sem proibição na TASK; suprimido quando a tag já dispara o 4.215) · `task-marca-nao-timestamp` (W, 4.337 — promoção do check adiado da 4.308: campo `Data início`/`Data conclusão` do Histórico de execução preenchido com conteúdo que não começa em timestamp `AAAA-MM-DDTHH:MM` — prosa "lacuna declarada" e data sem hora quebram o `cycle-clock` (4.325) e derrubam a completude; não acusam: vazio, `—` exato (lacuna nomeada canônica) e placeholder angular `<…>` — a lacuna honesta é campo vazio/`—`, nunca prosa no lugar da marca. **Fronteira declarada**: o lint cobra a **forma na escrita** do artefato; o `WARNING nao-parseavel` do `cycle-clock` segue degradando na **medição** — mesmo fato, momentos distintos, sem promoção de um sobre o outro) · `task-criterio-alvo-nao-isolado` (W, 4.368 — 2ª reincidência da 4.93: item de Critérios que nomeia arquivo de teste como alvo — `*Test.php`, `*.test/.spec.*`, `*_test.go`, `test_*.py` — e cita comando de suíte (`test`/`phpunit`/`pest`/`jest`/`vitest`/`pytest`/`mocha`/`rspec`/`cargo`/`go`) sem isolar o alvo; absolvem `--filter`/`--group`/`grep`/`-k`/`-t`/`--testNamePattern` ou o próprio arquivo dentro do comando; item multi-linha lido inteiro; best-effort declarado: comando amplo sem alvo nomeado não dispara, e ausência de achado não prova que o alvo rodou) |
| Cross-arquivo (modo diretório) | `plan-overlap-fr` (W) · `task-overlap-fr` (W) — extração de FR com fronteira à esquerda: `NFR-…` nunca conta como `FR-…` (4.254) · `task-wave-overlap-arquivo` (W, 4.326: mesmo arquivo declarado no "Escopo > Inclui" de 2+ TASKs da **mesma wave** do **mesmo PLAN** — colisão de escrita em wave paralelizável; universo de extração fechado (4.227): token com `/` e extensão final, sem `//`, pontuação de fim de frase aparada — bullet que não parseia como caminho não emite nada; TASK `Done` ou sem `Wave` numérica fica fora da conta; **best-effort declarado**: com o Inclui em prosa, ausência de achado não prova ausência de colisão — a checagem por olho segue no dono, Etapa 1 do `/keelson:implement` (4.228)) |

(`(W)` = nasce WARNING por ser padrão/heurística — §1.)

**Bug corrigido nasce com fixture que o reproduz** (4.260, irmã do "check novo → fixture
nova"): correção de defeito no motor entra com fixture do caso **e controle positivo** —
o motor anterior à correção, rodado sobre ela, tem de falhar (4.186); a suíte congelada
passa a segurar a reintrodução. A variedade de forma realista tem cinto próprio no corpus
(`scripts/tests/corpus/` — saídas de todos os motores read-only congeladas; diff de
expected em leva exige justificativa na decisão, nunca aceite cego).

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
