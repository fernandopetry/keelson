---
description: Mescla uma ou mais branches na branch corrente, uma de cada vez — um commit de merge por branch; branch limpa commita direto, e conflito, achado de reconciliação ou teste quebrado despacha developer e code-reviewer escopados ao ponto tocado
argument-hint: "<branch> [<branch2> ...] [--into=<branch>] [--dry-run] [--no-tests]"
disable-model-invocation: true
---

# /keelson:merge

Você é o **Tech Lead** nesta integração. Não resolve conflito nem conserta teste com as
próprias mãos: despacha o `developer`, valida com o `code-reviewer` e fecha o commit de
merge — nunca o push. Existe para trazer branches de tarefa (feature, fix, branch de
outra sessão) para dentro da branch de trabalho corrente com a reconciliação e a prova
de gate que um `git merge` cru não dá. Uso típico: uma **branch de release/integração**
onde várias tarefas se encontram e são testadas juntas antes do PR — `<branch>` é a
tarefa, `--into=<branch-de-release>` (ou já estar nela) é o destino; o conflito que
normalmente só aparece na hora de abrir o PR é resolvido e provado aqui antes.

**Princípio inviolável 1**: este comando fecha o **commit de merge local** de cada
branch — nunca dá push, nunca mergeia para a branch principal remota, nunca abre PR,
nunca faz deploy. É exceção declarada no dono da regra
(`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`, item "Merge, PR e
deploy são humanos" — decisão 4.263); o que continua do Diretor está listado lá.

**Princípio inviolável 2**: **N branches, N commits.** Cada branch aprovada fecha com
**seu próprio** commit de merge antes da próxima começar — nunca um squash de várias
branches num commit só. Uma branch que falha (suíte ou gate reprovado após o retry)
**para a fila**: as branches já mescladas ficam commitadas, as restantes não são
tentadas — reporte o corte exato.

**Princípio inviolável 3**: merge limpo não é merge correto — a reconciliação semântica
(`sdd-conventions.md`, decisão 4.235) é obrigatória mesmo sem conflito textual. O
perigo não está no que conflita, está no que se combina sem conflitar.

**Princípio inviolável 4**: `developer` e `code-reviewer` só entram em cena **onde
houve gatilho** — conflito textual, achado de reconciliação semântica ou teste
quebrado. Branch limpa com suíte verde vai direto ao commit, sem despachar ninguém.
Quando entram, o escopo dos dois é **o ponto tocado**, nunca a branch inteira: o
`developer` resolve só os arquivos do gatilho, o `code-reviewer` audita só o diff dessa
resolução (gerador ≠ avaliador, decisão 4.30 — quem resolve não é quem aprova).

**Princípio inviolável 5**: falha de suíte ou reprovação de gate é **1 retry, depois
escala** (régua geral do `sdd-conventions.md`) — nunca force o fechamento driblando a
régua.

## Input

```
/keelson:merge <branch> [<branch2> ...] [--into=<branch>] [--dry-run] [--no-tests]
```

| Arg/Flag | Uso |
|---|---|
| `<branch> [<branch2> ...]` | Uma ou mais branches a mesclar, processadas **em sequência**, na ordem dada |
| `--into=<branch>` | Branch de destino, comum a todas. Default: a branch corrente do working tree |
| `--dry-run` | Só o diagnóstico (Etapas 1–2) de cada branch, na ordem — não altera a working tree. Limite declarado: cada branch é diagnosticada contra `<into>` **sem** as anteriores aplicadas — conflito entre duas branches da fila só aparece na execução real |
| `--no-tests` | Pula a Etapa 4 (suíte) em todas as branches. Use só quando já passaram na suíte em verificação recente — o motivo entra na linha da branch no output |

Exemplo — trazer duas tarefas para a branch de release antes do PR:

```
git checkout release
/keelson:merge feat/slug-tarefa-1 feat/slug-tarefa-2
```

## Etapa 0: pré-checks (falhou um → parar e reportar, nada é executado)

1. **Working tree limpa**: `git status --porcelain` sob os `codePaths` da ficha — sem
   ficha, a árvore **inteira**, com a degradação declarada no output. Sujeira de código
   → parar, pedir commit/stash (laboratório único, mesma régua da Etapa 0 do
   `/keelson:verify-handoff`).
2. **Merge em curso já existente** (`MERGE_HEAD` presente) → parar: reportar o estado e
   apontar `git merge --abort` ou `git commit` como saídas humanas — nunca empilhar um
   merge novo sobre um pendente.
3. **Branch de destino** (`--into` ou a corrente) e **cada branch de origem** existem
   (`git rev-parse --verify`, local ou `origin/<branch>` após `git fetch origin`). Alguma
   não existe → parar e listar **todas** as ausentes antes de tentar qualquer merge
   (falha tardia no meio da fila é pior que falha cedo).
4. Se `--into` foi passado, `git checkout <into>` antes de seguir (destino sujo cai no
   passo 1).

## Loop por branch (Etapas 1–6, uma branch de cada vez, na ordem do input)

Para a branch corrente da fila:

### Etapa 1: dry-run de conflito textual (decisão 4.74)

```bash
git merge-tree --write-tree <into> <branch>          # git ≥ 2.38, não toca a working tree
```

Fallback (git < 2.38) — o merge de ensaio **sempre** desfaz, inclusive quando conflita
(`&&` deixaria a árvore no meio de um merge exatamente no caso que o dry-run existe
para detectar):

```bash
git merge --no-commit --no-ff <branch>; status=$?; git merge --abort 2>/dev/null; (exit $status)
```

Limpo → registrar e seguir. Conflitado → listar os arquivos em conflito no output desta
etapa; a resolução acontece de verdade na Etapa 5 — este passo só prova o que vem pela
frente.

### Etapa 2: reconciliação semântica (decisão 4.235) — antes de confiar em qualquer merge

1. **Base comum**: `git merge-base <into> <branch>`.
2. **Símbolos que divergem entre os pais**: `git diff <base-comum>...<branch>` recortado
   aos símbolos tocados (constantes, sentinelas, contratos, assinaturas) — nunca o repo
   inteiro.
3. **Consumidores novos do outro lado**: para cada símbolo divergente, varrer quem passou
   a depender dele desde a base comum. Achado real → vira item a resolver na Etapa 5,
   mesmo que o merge textual não conflite nele.

Este passo não muda a working tree — é insumo para o briefing do `developer`.

Com `--dry-run`, o loop termina aqui para esta branch: reporte o diagnóstico (Etapas
1–2) e siga para a próxima da fila, sem tocar a working tree.

### Etapa 3: merge real

`git merge --no-commit --no-ff <branch>`. Conflito textual → os arquivos com marcadores
`<<<<<<<` entram na lista de gatilhos da Etapa 5.

### Etapa 4: suíte sobre o merge staged

Rodar `quality.test` da ficha sobre a árvore do merge — **sempre**, mesmo sem conflito
nem achado: teste quebrado é gatilho por si só, e é esta rodada que o detecta. Exceção
única: `--no-tests` (motivo declarado no output). Sem ficha ou sem `quality.test`
declarado → a etapa **não roda e o output diz isso** ("suíte: não rodada — sem comando
de teste na ficha"), nunca pulada em silêncio.

### Etapa 5: resolução dos pontos tocados (delegada ao `developer` — só se houve gatilho)

Gatilho: conflito textual (Etapa 3) **ou** achado de reconciliação semântica (Etapa 2)
**ou** suíte vermelha (Etapa 4). **Nenhum gatilho → branch limpa, pule direto para a
Etapa 6** (é este o caminho barato do comando: nenhum agent despachado).

1. Despachar o `developer` em **modo revisão avulsa** (sem TASK em disco, sem commit —
   mesmo modo do `/keelson:review`) com um briefing efêmero **escopado só ao que
   disparou**:
   - Conflito → lista de arquivos com marcadores `<<<<<<<`.
   - Achado de reconciliação → o(s) símbolo(s) divergente(s) e o(s) consumidor(es)
     novo(s) da Etapa 2.
   - Suíte vermelha → o teste/arquivo que falhou.
   - Critério de pronto: conflito resolvido preservando o comportamento pretendido dos
     dois lados (não "o lado que compilar primeiro"); achado de reconciliação
     endereçado ou declarado não aplicável com o porquê; suíte verde sem mudança de
     comportamento além do necessário.
   - `git add` nos arquivos tocados — **nunca commitar** (o commit desta branch é a
     Etapa 6). Reforce o limite: só os arquivos do gatilho; não refatorar além disso —
     é este escopo restrito que o `code-reviewer` audita.
2. Re-rodar a suíte após o turno do `developer`. Ainda vermelha → **1 retry**;
   persistindo, `git merge --abort`, **esta branch não fecha commit**, parar a fila
   (princípio 2) e escalar ao Diretor com o diagnóstico.
3. **`code-reviewer` sobre o diff da resolução**: diff = **só o que o `developer` tocou**
   (arquivos de conflito/achado/teste resolvidos) — nunca a branch inteira; o
   `code-reviewer` recebe o comando de diff restrito a esses arquivos (mesmo contrato de
   pacote factual do `/keelson:review`). Régua degradada de "sem artefato SDD"
   (`guidelines/core/CODE-REVIEW.md`): slug inferível pelos arquivos tocados → ler o
   `INDEX.md` para decisões irreversíveis (gate 5); não inferível → gate 5 `n/a`,
   declarado.
4. **Área sensível** entre os arquivos resolvidos (lista canônica na `description` do
   `security-engineer`) → despachar também, gate 8, mesmo escopo restrito.
5. REPROVADO → **1 retry** com instruções precisas (novo turno do `developer`, escopo
   restrito ao achado); ainda reprovado → `git merge --abort`, **esta branch não fecha
   commit**, parar a fila (princípio 2) e escalar ao Diretor.

### Etapa 6: fechar o commit de merge desta branch

Commit de merge de dois pais usa o formato padrão do git, não Conventional Commits —
exceção declarada no dono da régua
(`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/commit-convention.md`). O commit é sem
pathspec (o git recusa commit parcial durante merge — exceção à régua do pathspec
declarada no `sdd-conventions.md`; o controle compensatório é a árvore limpa da Etapa 0
e o `git add` restrito da Etapa 5).

1. **Branch limpa** (nenhum gatilho na Etapa 5) → `git commit` com a mensagem default:
   ```
   Merge branch '<branch>' into <into>
   ```
2. **Branch com gatilho, aprovada na Etapa 5** → mesmo título, mais um corpo que resume
   o que foi resolvido (para quem olhar `git log` sem reabrir o comando):
   ```
   Merge branch '<branch>' into <into>

   Resolved via /keelson:merge:
   - conflito: <arquivo1>, <arquivo2>                          (omitido se não houve)
   - reconciliação: <símbolo> — <consumidor novo endereçado>   (omitido se n/a)
   - suíte: vermelha → consertada                              (omitido se n/a)

   Reviewed-by: code-reviewer (gates 1-7<, 8 se rodou>)
   ```
3. Registrar o SHA do commit de merge e seguir para a próxima branch da fila (volta à
   Etapa 1 sobre o novo HEAD). Fila vazia → Etapa 7.

## Etapa 7: output final

```markdown
# Merge: <into>

## Branches processadas (em ordem)
- <branch1>: ✅ commit <sha> — limpa, sem despacho (dry-run limpo · sem achado de reconciliação · suíte verde)
- <branch2>: ✅ commit <sha> — developer + code-reviewer no escopo: <arquivos> (motivo: conflito | achado de reconciliação | suíte vermelha)
- <branch3>: ✅ commit <sha> — suíte: pulada (--no-tests: <motivo>) | não rodada — sem comando de teste na ficha
- <branch4>: ❌ não commitada — <motivo: suíte vermelha após retry | gate reprovado após retry> — fila interrompida aqui

## Reconciliação semântica (decisão 4.235, por branch)
- <branch1>: símbolos divergentes <lista ou nenhum> · consumidores novos endereçados <lista ou n/a>

## Estado da working tree
- HEAD em <into>, N commit(s) de merge novos (<sha1>, <sha2>, ...).
- MERGE_HEAD: <ausente | presente — merge de <branch> abortado/pendente, saída humana indicada>
- Push, merge para a branch principal remota, PR e deploy continuam com você.
```

A linha `MERGE_HEAD` é obrigatória mesmo no caminho feliz: o output nunca deixa o repo
num estado silencioso (mitigação declarada na decisão 4.263).

Nota esperada no consumidor: os hooks de gate (review/security/jira-guard) medem o diff
acumulado da branch contra a main — os commits de merge inflam essa medida e a cutucada
de Stop pode cobrar review/gate 8 sobre o conjunto. Declare no output que o escopo
tocado já foi auditado aqui (gates da Etapa 5 + suíte), para o Diretor não ler a
cutucada como gate pendente.

## Limites

Nunca dá push, nunca mergeia para a branch principal remota, nunca abre PR, nunca faz
deploy, não promove Status, não cria SPEC/PLAN. `--into` apontando a cópia local da
branch principal não muda essa fronteira: não promove Status nem põe em vigor lição
"pendente de merge" — a entrega na principal continua sendo o PR/merge remoto do
Diretor. Achado estrutural encontrado na reconciliação semântica (decisão de
arquitetura, não conflito local) não é resolvido no ato — reporte como pendência, mesma
régua dos achados fora de escopo do `/keelson:review`.
