# Handoff de verificação de tela (gate de comportamento remoto)

> Fonte única (ex-§8 do method-guide) do protocolo de handoff: ciclo de vida (§8.1),
> template canônico (§8.2) e prompt canônico da Entrega (§8.3).

Quando o ciclo roda num ambiente **sem acesso a testes de tela** — worktree sem app/browser, execução na nuvem, containers indisponíveis — o gate de comportamento verificado não consegue exercitar a UI. Nesses casos a entrega **não engole o furo**: ela produz um **handoff de verificação** — documento com roteiro passo a passo e riscos + **prompt pronto** para um agente com acesso a tela fechar a verificação depois. O handoff é a diferença entre "não verifiquei e ninguém sabe" e "não verifiquei, e aqui está exatamente o que falta, como exercitar e o que está em risco".

> Aplica-se a projetos com `gates.screenVerify` ativo na ficha (têm superfície visual a verificar). Onde não há tela, o gate se satisfaz por teste/execução sem UI e não há handoff.

### 8.1 Ciclo de vida

1. **Detecção**: na rota formal, o `qa` reporta `PARCIAL` com o bloco `handoff_seed` (o roteiro do que ele não conseguiu exercitar). Na rota inline (bug/refactor), a auto-revisão do gate pela main session detecta o mesmo. **Indisponibilidade de ambiente é provada, não presumida** (decisão 4.26): antes de declarar, roda-se uma **sondagem barata** — o `keelson.local.json` existe e tem os dados do(s) realm(s) envolvido(s)? a `baseUrl` do realm responde (ou a app sobe pelo método do projeto)? a sessão tem ferramenta de tela? — e a **evidência da sondagem que falhou** (o que foi tentado, o que retornou) acompanha a seed e entra no front-matter do handoff (`sonda:`). Projeto multi-realm: sonda **por realm** do roteiro — um realm de pé e outro não gera pendência só para o indisponível. Declarar "ambiente sem tela" sem sondagem registrada é usar o handoff como atalho — proibido.
2. **Geração** (preparação da Entrega): a main session consolida as seeds e cria `<docsRoot>/<slug>/handoffs/HANDOFF-<id>.md` — `<id>` = `PLAN-MMM` na rota formal; `<yyyy-mm-dd>-<descrição-curta>` na inline. Um doc por entrega (consolida todas as tasks do PLAN). Registra **risco ativo** no INDEX do slug: `Verificação de tela pendente — HANDOFF-<id>`. Domínio **sem slug keelson** → não cria arquivo: o roteiro completo vai inline no prompt do report da Entrega.
3. **Entrega**: o handoff entra no commit da branch e o report final traz a seção **"Verificação pendente (handoff)"** com o prompt copy-paste. A entrega é declarada **parcial** — nunca "totalmente verificada" — enquanto houver handoff `Pendente`.
4. **Fechamento** (num ambiente com tela): o agente que recebe o prompt faz checkout da branch, lê o handoff, exercita cada item com a rotina de verificação de tela do projeto, registra a evidência no próprio doc, corrige divergências na própria branch (protocolo inline) e faz a closure — `status: Concluído`, risco removido do INDEX + linha no Histórico recente, commit `chore(<slug>): close verification handoff HANDOFF-<id>`, push. Merge e deploy continuam humanos.

O `/keelson:integrate` detecta handoffs `Pendente` do slug e os destaca na descrição do PR — mergear com verificação pendente passa a ser decisão consciente do humano, nunca desinformada.

### 8.2 Template canônico do handoff

```markdown
---
id: HANDOFF-<id>
slug: <slug>
branch: <branch>
status: Pendente               # Pendente | Concluído
criado: <ISO 8601>
origem: PLAN-MMM | inline
commits: [<SHAs curtos>]
motivo: <ambiente sem acesso a testes de tela — worktree | nuvem | containers down>
sonda: <evidência da sondagem de disponibilidade que falhou, por realm — o que foi tentado e o que retornou>
---

# Handoff de verificação de tela — <título curto>

## 1. Contexto da entrega
<2–5 linhas: o que foi entregue e por quê; refs SPEC-NNN / PLAN-MMM / TASKs.>

## 2. Já verificado (não repetir)
- Testes: <suíte/comando (quality.test da ficha), N/N>
- Lint/type-check: <resultado (quality.lint / quality.typecheck)>
- API exercitada sem tela: <chamadas feitas e resultados, ou "nenhuma">

## 3. Pré-requisitos de ambiente
- Subir app + login: <como subir a app deste projeto e autenticar; pegadinhas de permissão>
- Migrações/seeds pendentes DESTA branch: <lista com comandos, ou "nenhuma">
- Feature flags / permissões necessárias: <lista, ou "nenhuma">
- Dados de teste: <como obter/criar o estado necessário>

## 4. Roteiro de verificação (itens pendentes)

### V1 — <título> (<AC-NNN-XXX ou "inline: <comportamento>">)
- **Tela/rota**: <URL/rota da app>
- **Realm**: <nome em `screenVerify.realms` do `keelson.local.json` — omitir se o projeto tem um só>
- **Passos**: 1) … 2) … 3) …
- **Esperado**: <comportamento observável, específico o bastante para dar ✅/❌>
- **Risco se falhar**: <impacto para o usuário/negócio>
- **Evidência**: _(preencher na verificação)_

### V2 — …

## 5. Riscos e pontos de atenção
<O que o implementador sabe que é frágil e a tela pode revelar: tema claro/escuro, estados
vazios/erro, permissões, responsividade, interação com dados reais, timing.>

## 6. Protocolo de conclusão
1. Exercitar cada item V* e preencher a Evidência (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch (protocolo inline: escopo restrito + testes +
   gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar INDEX do slug (remover o
   risco ativo + linha no Histórico recente); commit
   `chore(<slug>): close verification handoff HANDOFF-<id>`; push.
4. Merge e deploy continuam decisão humana.
```

**Regras do roteiro (seção 4)**: cada item deve ser executável por quem **não participou da implementação** — sem "verifique se está ok"; passos concretos, dados concretos, resultado esperado observável. Cada AC observável não exercitado vira um item V*; fluxos de risco conhecido (tema escuro, estado vazio, permissão negada) entram mesmo sem AC formal quando o implementador sabe que são frágeis.

### 8.3 Prompt canônico (emitido no report da Entrega)

```text
Você está num ambiente com acesso a testes de tela (app local + browser). Sua tarefa é
fechar a verificação de comportamento (gate de comportamento verificado) de uma entrega
feita em ambiente sem tela.

1. `git fetch && git checkout <branch>` (e `git pull` se a branch já existir localmente).
2. Leia `<docsRoot>/<slug>/handoffs/HANDOFF-<id>.md` — ele é a FONTE DA VERDADE desta tarefa:
   pré-requisitos de ambiente (§3), roteiro passo a passo (§4), riscos (§5) e protocolo
   de conclusão (§6). Consulte também SPEC/PLAN referenciados nele se precisar de contexto.
3. Suba o ambiente e exercite CADA item pendente do roteiro com a rotina de verificação
   de tela do projeto; registre a evidência item a item no próprio doc.
4. Divergência → corrija na própria branch (protocolo inline) e re-exercite.
5. Tudo verde → siga o protocolo de conclusão do doc (status, INDEX, commit, push).
Não faça merge nem deploy — isso continua decisão humana.
```

(Domínio sem slug: substitua o passo 2 pelo roteiro inline incluído abaixo do prompt.)
