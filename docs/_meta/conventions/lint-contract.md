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
| Seções do template | `spec-secao-ausente` (§1–§10 + 1.1/1.2/1.3/4.1/4.2) · `plan-secao-ausente` (Aderência, Cobertura, §1–§6 e §8–§10 — sem §7, por desenho: 4.409) · `task-secao-ausente` (6 seções + Inclui/Não inclui — esqueleto em `templates/artifacts/TASK.md`) — o esqueleto exigido é o de `templates/artifacts/{SPEC,PLAN,TASK}.md`; `scripts/check-templates.sh` prova que o template passa sem `*-secao-ausente` (4.405) |
| IDs | `spec/plan-id-fora-do-numero` (NNN/MMM ≠ arquivo) · `spec/plan-id-zero-pad` |
| SPEC §5–§7 | `spec-fr-sem-rfc` · `spec-rfc-forma` · `spec-fr-sem-deve` · `spec-ears-nao-casa` (W) · `spec-fr-palavras` (>30) · `spec-must-ratio` (>70%, 3+ FRs) · `spec-sem-should-may` · `spec-porte-epico` (>30 FRs) · `spec-nfr-vago` (W) · `spec-nfr-sem-numero` (W — mede o texto do NFR após o ID e o marcador RFC, nunca a linha inteira: o próprio ID carrega dígitos; 4.384) · `spec-ac-fora-gwt` (W) · `spec-tecnologia` (W, wordlist da Etapa 5 do SKILL) · `spec-area-sensivel-sem-negacao` (W, 4.427 — §5–§7 citam termo da lista canônica do gate 8 em português — login/senha/autentic/autoriz/permiss/token/sessão/cookie/upload/pagamento/cartão/dados pessoais/lgpd/criptograf/chave de api/redirecion — e a SPEC não tem NFR de segurança nem AC de negação — recusa/nega/não autorizado/sem permissão/403/401/bloqueio/rejeita/inválido; padrão, nunca ERROR) |
| SPEC FEATs | `spec-feat-particao` · `spec-feat-vazia` · `spec-feat-fora-da-5` · `spec-feat-unica` (W) · `spec-feat-sem-descricao` (W) |
| SPEC métrica/escopo/premissas | `spec-metrica-sem-numero` (W) · `spec-metrica-sem-fonte` (W, Draft/Review) · `spec-out-of-scope-vazio` · `spec-out-of-scope-curto` (W) · `spec-in-eq-out` · `spec-sem-premissa` (W) · `spec-sem-risco` (W) · `spec-premissa-sem-marcador` (W) · `spec-premissa-sem-selo` (W, Draft/Review) · `spec-confirmar-teto` (W, Draft/Review) · `spec-glossario-nao-usado` (W) |
| PLAN cobertura/DEC/DoD | `plan-cobertura-sem-spec` · `plan-frs-cobertos-vazio` · `plan-comp-sem-realiza` (COMP sem `**Realiza**:` — única fonte do mapeamento FR → componente, 4.409) · `plan-dec-campo-ausente` · `plan-dec-sem-alternativa` · `plan-dec-alternativa-unica` (W) · `plan-dec-irreversivel-enum` · `plan-dec-irreversivel-forma` (W — o valor é comparado após normalizar caixa, til e pontuação terminal: `não.` é forma, nunca enum; 4.341) · `plan-dec-sem-reabrir` (W, Draft/Review) · `plan-reabrir-nunca-sem-motivo` (W) · `plan-dod-vazia` · `plan-dod-placeholder` · `plan-dod-sem-teste` (W) · `plan-dod-sem-perfil` (W) |
| TASK | `task-nome-tipo` (W) · `task-wave2-sem-dep` (W) · `task-feat-sem-primaria` · `task-feat-transversal-uma` · `task-criterios-vazios` · `task-criterio-sem-ac` · `task-criterio-grep-nao-ancorado` (W) · `task-criterio-grep-alvo-amplo` (W) · `task-criterio-diff-base-vazio` (W) · `task-criterio-cifrao-aspas-duplas` (W) · `task-comando-contradiz-criterio` (W) · `task-bugfix-sem-ac-violado` · `task-bugfix-forma-legada` (INFO) · `task-refactor-sem-identidade` · `task-done-gate-aberto` (W) · `task-mutacao-sem-contagem` (W) · `task-prova-seguranca-com-grupo` (W) · `task-marca-nao-timestamp` (W) · `task-criterio-alvo-nao-isolado` (W) · `task-criterio-esperado-placeholder` (W) — o contrato de cada heurística (o que casa, o que absolve, fronteira best-effort) está em *Notas do grupo TASK*, abaixo da tabela |
| Cross-arquivo (modo diretório) | `plan-overlap-fr` (W) · `task-overlap-fr` (W) — extração de FR com fronteira à esquerda: `NFR-…` nunca conta como `FR-…` (4.254) · `task-wave-overlap-arquivo` (W, 4.326: mesmo arquivo declarado no "Escopo > Inclui" de 2+ TASKs da **mesma wave** do **mesmo PLAN** — colisão de escrita em wave paralelizável; universo de extração fechado (4.227): token com `/` e extensão final, sem `//`, pontuação de fim de frase aparada, **ou nome solto** (sem diretório) com extensão de código/config da allowlist do motor e nome antes do ponto — `v1.2`, `e.g.`, `*.vue`, nome de artefato SDD e nome de framework em prosa (`Vue.js`) ficam fora; nome solto casa pelo nome com outro nome solto ou com caminho de mesmo basename na mesma wave, e a mensagem declara "casada pelo nome" (4.454); dois caminhos distintos de mesmo basename nunca colidem — bullet que não parseia como caminho nem como nome não emite nada; TASK `Done` ou sem `Wave` numérica fica fora da conta; **best-effort declarado**: com o Inclui em prosa, ausência de achado não prova ausência de colisão — a checagem por olho segue no dono, Etapa 1 do `/keelson:implement` (4.228)) |

**Notas do grupo TASK** — contrato das heurísticas (o que o motor casa e o que o absolve; nunca julgamento):

- `task-criterio-sem-ac` (4.254): exige ID bem-formado `AC-N-N` em qualquer linha de Critérios/Roteiro; substring `AC-` solta (ex.: dentro de um regex) não conta.
- `task-criterio-grep-nao-ancorado` (4.161/4.255): `grep`/`rg` em critério sem exclusão de comentário nem âncora executável. Absolvem só Reflection, exclusão `-v` e padrão ancorado em `^`; fronteira de símbolo (`\b`/`::`/`->`/`class `/`function `) não absolve — limita a palavra, mas segue casando docblock e prosa.
- `task-criterio-grep-alvo-amplo` (4.456): `grep`/`egrep` **recursivo** (`-r`/`-R`/`--recursive`) em critério cujo alvo é diretório inteiro sem `/` (`backend`, `.`) — casa cache/vendor/autoload e o critério de ausência nunca converge. Ficam fora `git grep` (só rastreados), `rg` (honra `.gitignore`) e alvo com `/` (subárvore escolhida). Independe do `grep-nao-ancorado`: um é o padrão, o outro é o universo. Remédio na mensagem: `git grep -w <símbolo> -- <dir-fonte>`.
- `task-criterio-diff-base-vazio` (4.459): `git diff` em critério cujo range é `<default>...HEAD` ou `<default>..HEAD` (`main`/`master`/`develop`/`trunk`, com ou sem `origin/`, ou os placeholders `<default>`/`<base>`) **e** a linha declara esperado vazio (`vazio`/`vazia`, `0 linhas`, `nenhum arquivo`, `sem saída`). Ficam fora range ancorado em SHA/ref que não é a default e esperado de presença (`não vazio`, `inclui X`). Best-effort por linha: esperado declarado em linha seguinte não é lido.
- `task-criterio-cifrao-aspas-duplas` (4.463): `grep`/`egrep`/`rg`/`sed` em critério com `$` **não escapado** dentro de aspas **duplas**, seguido de identificador, dígito, `{`, `(` ou parâmetro especial (`$this`, `$HOME`, `${x}`, `$(…)`, `$1`) — o shell expande antes de a ferramenta ver o padrão, e o comando busca outra coisa (em critério de ausência, nada: vazio verde). Absolvem aspas simples (nenhum segmento duplo), `\$` escapado e `$` de fim de padrão (`"x$"`). Best-effort por linha: o trecho do comando termina no primeiro `` ` `` ou `|`, então aspas duplas que carregam `|` dentro são lidas pela metade.
- `task-comando-contradiz-criterio` (4.215): comando de Critérios/Roteiro do gate 9 usa `--group <tag>` e outra linha da mesma TASK (qualquer seção) proíbe a mesma tag; igualdade de tag exigida nos dois lados. Negação é da linha (`nunca`/`jamais`/`proib…`/`não`); ocorrência precedida de `sem` ("nasce sem `--group X`") sai do lado comando por ocorrência e não alimenta a proibição (4.454).
- `task-mutacao-sem-contagem` (4.232): critério menciona mutação de predicado de escopo sem o par contável "N métodos … N provas". Formas reconhecidas: número antes da palavra (`4 métodos … 4 provas`) ou rótulo seguido de número (`métodos que tocam a tabela: 4; provas: 4` — 4.446); `N` literal e número por extenso não contam — o par contável é o dígito. O lint cobra a **forma** da declaração; o confronto número×código é do gate 8.
- `task-prova-seguranca-com-grupo` (4.233): arquivo de teste de segurança no Inclui — por **nome**: `*Permission*Test`/`*Security*Test`/`*Guard*Test` — com comando de verificação `--group <tag>` sem proibição na TASK; suprimido quando a tag já dispara o 4.215. Best-effort declarado: ausência de achado não prova ausência de defeito.
- `task-marca-nao-timestamp` (4.337 · 4.308): `Data início`/`Data conclusão` do Histórico de execução preenchido com conteúdo que não começa em `AAAA-MM-DDTHH:MM` — prosa e data sem hora quebram o `cycle-clock` (4.325) e derrubam a completude. Não acusa: vazio, `—` exato (lacuna nomeada canônica) e placeholder `<…>` — a lacuna honesta é campo vazio/`—`, nunca prosa. **Fronteira**: o lint cobra a forma na escrita; o `WARNING nao-parseavel` do `cycle-clock` degrada na medição — mesmo fato, momentos distintos, sem promoção de um sobre o outro.
- `task-criterio-alvo-nao-isolado` (4.368, família 4.93): item de Critérios que nomeia arquivo de teste como alvo (`*Test.php`, `*.test/.spec.*`, `*_test.go`, `test_*.py`) e cita comando de suíte (`test`/`phpunit`/`pest`/`jest`/`vitest`/`pytest`/`mocha`/`rspec`/`cargo`/`go`) sem isolar o alvo. Absolvem `--filter`/`--group`/`grep`/`-k`/`-t`/`--testNamePattern` ou o próprio arquivo dentro do comando; item multi-linha lido inteiro. Best-effort declarado: comando amplo sem alvo nomeado não dispara, e ausência de achado não prova que o alvo rodou.
- `task-criterio-esperado-placeholder` (4.447): item de Critérios cujo esperado traz placeholder no lugar do número — `OK (N tests)`, `OK (N testes)`, `OK (N)`, `N > 0`/`N >= 1`. Não é defeito de forma: é o estado honesto da fixação sem shell, e o número vem do baseline do developer (etapa 2) antes de começar. O lint **conta** para tornar o estado visível; o `task-validator` não escala.

(`(W)` = nasce WARNING por ser padrão/heurística — §1.)

**DEC herdada fica fora dos `plan-dec-*`** (decisão 4.422): o motor só reconhece DEC em heading `### DEC-…`; a linha `- **DEC-MMM-00N** [herdada] … — fonte: …` da lista `### Decisões herdadas` (template do PLAN, §6) não é bloco DEC — nenhum `plan-dec-*` nem a checagem de número do ID a alcançam, por desenho (o lint relaxa, nunca inverte: DEC herdada escrita em forma completa num PLAN antigo segue passando). A classificação herdada × nova é julgamento do `plan-validator`. O sub-heading é de nível `###` — é ele que fecha o bloco DEC anterior.

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
