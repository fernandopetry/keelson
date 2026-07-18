---
description: Fecha a verificação de tela/comportamento (gate screenVerify) de uma branch cuja entrega ficou com HANDOFF pendente — consolida a branch na mesa principal, exercita cada item do handoff no ambiente real (pelo método de verificação de tela do projeto), corrige divergências na própria branch e fecha o handoff. NÃO faz merge — para com a branch pronta e aponta para /keelson:integrate.
---

# /keelson:verify-handoff

Você é o executor da **verificação de tela remota** (gate `screenVerify`) do projeto. Quando uma entrega é feita num ambiente **sem tela** (worktree/nuvem, onde a app não sobe), esse gate fica pendente e a entrega gera um `{docsRoot}/<slug>/handoffs/HANDOFF-*.md` com o roteiro do que precisa ser conferido. Este comando é quem **fecha** esse roteiro: roda na **mesa principal** (onde a app efetivamente sobe), exercita cada item de verdade, corrige o que divergir e marca o handoff como concluído. `docsRoot` e o gate `screenVerify` vêm de `keelson.config.json`.

**Princípio de fronteira**: a verificação de tela só acontece onde a app roda de verdade — a **mesa principal** (`<root>`, o working tree que o ambiente do projeto monta), não um worktree linkado. Por isso este comando **consolida a branch no `<root>`** antes de testar.

**Princípio de autoridade**: este comando fecha o gate e **para**. Ele **não** faz merge nem deploy — o merge continua sendo decisão humana. Só roda por decisão humana: invocação direta, ou **encadeado pelo `/keelson:integrate`** quando este encontra handoff `Pendente` no pré-check (a invocação humana da integração é a autorização — quem pede a integração pede o gate fechado). Nenhum outro fluxo o chama.

## Input

```
/keelson:verify-handoff [slug|branch] [--keep-worktree] [--dry-run]
```

| Arg/Flag | Uso |
|---|---|
| `[slug|branch]` | O que fechar. Sem argumento: varrer os worktrees e listar os HANDOFF `status: Pendente` para o humano escolher |
| `--keep-worktree` | Não remover o worktree da branch. Em vez do checkout nomeado (Caminho B), usa `checkout origin/<branch>` (detached) para preservar o worktree |
| `--dry-run` | Imprime o que faria (alvo, consolidação, itens a verificar) sem executar |

## Etapa 0: pré-checks (falhou um → parar e reportar, nada é executado)

1. **Mesa principal**: `<root>` = primeira linha de `git worktree list`. Todos os comandos git rodam com `git -C <root>`. Este comando **precisa** operar sobre o `<root>` porque é o que o ambiente da app monta. Se a sessão atual roda dentro de um worktree linkado, opere via `git -C <root>` — mas avise que a **verificação exige o ambiente do `<root>`**.
2. **`<root>` livre para receber a branch**: `git -C <root> status --porcelain`. Como vamos **trocar a branch do `<root>`**, ele precisa estar **limpo e sem trabalho de outra sessão**:
   - Sujeira de código (staged/modificado/untracked sob os `codePaths` da ficha) → **parar** e pedir commit/stash (laboratório único: não dá para testar duas coisas ao mesmo tempo). Sujeira só de descartáveis (scratch, notas locais) → apontar e perguntar.
   - `<root>` numa branch de trabalho (não a base, ex.: `main`) de outra sessão paralela → **parar** e pedir que guardem/pausem aquele trabalho antes (trocar a branch do `<root>` interromperia a outra sessão).
3. **Base atualizada** (para as correções que possam surgir): `git -C <root> fetch origin`; se a base (`main`) está atrás → `git -C <root> pull --ff-only origin main`; divergida → relatar (não bloqueia, mas registre).
4. **Resolver o alvo**:
   - **Com `[slug|branch]`**: localizar a branch e os `{docsRoot}/<slug>/handoffs/HANDOFF-*.md` com `status: Pendente`. Slug → a branch que carrega o trabalho (via `git worktree list`/`git branch`); branch → o slug sai do handoff que ela contém.
   - **Sem argumento**: para cada worktree de `git worktree list`, procurar `{docsRoot}/*/handoffs/HANDOFF-*.md` com `status: Pendente`; montar a lista `(slug, branch, HANDOFF-id, nº de itens V* pendentes)` e **pedir ao humano que escolha** (via AskUserQuestion). Nenhum pendente → reportar e encerrar.
5. **Branch salva no remoto**: `git -C <root> log origin/<branch>..<branch>` (e o `status` do worktree da branch) — nada pode se perder ao consolidar. Trabalho não pushado/uncommitado → **parar** e pedir commit+push antes.

`--dry-run` para aqui, imprimindo alvo + plano.

## Etapa 1: consolidar a branch na mesa principal (Caminho B)

1. A branch está num worktree linkado (ver `git worktree list`)?
   - **Sim, sem `--keep-worktree`** (padrão — Caminho B): confirmar worktree limpo (Etapa 0.5) e removê-lo para **liberar** a branch: `git -C <root> worktree remove <path>`. Recusou por descartável? Liste; lixo confirmado → `--force`; qualquer coisa que pareça trabalho → parar e perguntar.
   - **Sim, com `--keep-worktree`** (Caminho A): não remover; usar checkout **detached** no passo 2.
   - **Não** (branch sem worktree): seguir direto ao passo 2.
2. Trazer o código para o `<root>`:
   - Caminho B: `git -C <root> checkout <branch>` (só possível depois de liberar o worktree).
   - Caminho A (`--keep-worktree`): `git -C <root> checkout origin/<branch>` (detached HEAD; não conflita com o worktree preservado). ⚠️ Correções feitas aqui precisam ser levadas para a branch depois — prefira o Caminho B quando for fechar de verdade.
3. Confirmar: `git -C <root> log --oneline -1` bate com o topo da branch.

## Etapa 2: subir o ambiente no `<root>`

Suba a app no `<root>` pelo **método do projeto** (ver `guidelines/project/` e a ficha). O objetivo é que o código novo da branch passe a existir de verdade no ambiente (rotas novas, cache limpo, assets do frontend). Em geral:

1. **Serviço/backend**: garantir no ar; se o projeto usa cache/container, **reiniciar/limpar** para enxergar o código novo da branch.
2. **Seeds/migrations desta branch** (§3 do handoff): se o handoff lista seed/migration não aplicado no banco **local**, aplicá-lo pelo método do projeto — e lembrar que isso vira **pendência de deploy** em produção (registrar no relatório).
3. **Feature flags / permissões** (§3 do handoff): garantir o estado exigido no ambiente local. Mudança sensível (ex.: autorização) → fazer só o mínimo e dizer o que alterou.
4. **Frontend**: subir/servir conforme o método de verificação de tela do projeto.

## Etapa 3: executar o roteiro (gate screenVerify)

Para cada `HANDOFF-*.md` pendente do alvo:

1. Ler o handoff inteiro — §3 (pré-requisitos), §4 (itens V*), §5 (riscos).
2. **Exercitar cada item V*** pelo **método de verificação de tela do projeto** (a skill/ferramenta que o projeto define para dirigir a UI autenticada — ver `guidelines/project/` e as skills do projeto): seguir os *Passos*, observar o *Esperado*, e **registrar a Evidência no próprio doc** — `✅`/`❌` + o que foi observado (screenshot/payload/estado), item a item. Nada de "está ok" sem evidência.
3. **Divergência (`❌`)** → corrigir na **própria branch** pelo protocolo do projeto (escopo restrito + teste que cubra + os quality gates aplicáveis: `quality.lint`/`quality.typecheck`, e o gate de segurança se tocar algo sensível), commitar a correção (`fix(<slug>): <o quê>`) e **re-exercitar** o item.
4. Não conseguiu fechar um item (bloqueio real, correção não trivial) → **parar**: deixar o handoff `Pendente` com a evidência do que falhou, e reportar. Não force o fechamento.

## Etapa 4: fechar o handoff (só com todos os itens ✅)

1. Front-matter do(s) handoff → `status: Concluído`.
2. **INDEX do slug**: remover o risco ativo `Verificação de tela pendente — HANDOFF-<id>` e adicionar linha ao `## Histórico recente` (`<data>: gate screenVerify fechado via /keelson:verify-handoff — HANDOFF-<id>`). Se houve correções, refletir o estado.
3. Commit no `<root>`: `chore(<slug>): close verification handoff HANDOFF-<id>` (as correções da Etapa 3 já vão em commits `fix(...)` próprios). `git -C <root> push`.
4. **Parar aqui.** Não mergear.

## Etapa 5: devolver o `<root>` e reportar

1. Se a verificação **passou**: a branch está pronta para integrar. Aponte o próximo passo humano: **`/keelson:integrate <branch>`** (valida a DoD, roda a suíte e abre o PR). Não execute o merge.
2. Ofereça devolver o `<root>` ao estado anterior se você o tirou da base (ex.: `git -C <root> checkout main`), conforme o humano preferir — sem apagar trabalho.

## Output ao usuário

```markdown
# Verificação de tela: <slug> / <branch>

## Consolidação
- Branch trazida ao <root>: <branch> (Caminho B: worktree removido | Caminho A: detached)
- Ambiente: <serviço no ar> · <cache/restart> · seeds/flags aplicados: <lista ou nenhum>

## Roteiro (HANDOFF-<id>)
- V1 <título>: ✅/❌ — <evidência curta>
- V2 …
- Correções aplicadas: <fix(...) shas ou nenhuma>

## Resultado
- <Todos os itens ✅ → handoff Concluído (commit <sha>, push ok); risco removido do INDEX>
- <ou: PARCIAL — itens pendentes: <quais>; handoff segue Pendente>

## Pendências de deploy (humano)
- <seed/migration aplicado no local que falta em produção — ou "nenhuma">

## Próximo passo (humano)
- Integrar: `/keelson:integrate <branch>`
- Deploy em produção: <se houver pendência>
```

## Limites

O `/keelson:verify-handoff` **não**: faz merge nem deploy (para no gate e aponta para `/keelson:integrate`); fecha handoff sem exercício real de tela (sem ambiente de tela → aborta, não marca Concluído); troca a branch de um `<root>` sujo ou ocupado por outra sessão (laboratório único — uma verificação por vez); aplica seed/fixture/permissão contra **produção** (só ambiente local, e avisa o que alterou); roda por iniciativa de outro comando — só por invocação humana direta ou encadeado pelo `/keelson:integrate`.

---

**Agora feche a verificação de tela do alvo indicado (ou liste os handoffs pendentes e pergunte qual).**
