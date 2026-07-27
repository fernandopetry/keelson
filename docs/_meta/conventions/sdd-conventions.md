# Convenções comuns dos comandos SDD

> Fonte única (ex-§3.0 do method-guide) das convenções que todo comando `/keelson:*` segue
> sem redeclará-las. Guia humano do método: `docs/_meta/method-guide.md`.

- **Cabeçalho ≠ front-matter.** SPEC, PLAN e TASK **não** têm YAML front-matter: os metadados (`**Status**`, `**Brief**`, `**Jira**`, `**Funcionalidade**`…) são linhas markdown `**Chave**: valor` logo abaixo do `# TÍTULO`. YAML delimitado por `---` só existe em HANDOFF, perfis de `guidelines/` e frontmatter de commands/agents/skills. Onde a doutrina disser "front-matter" de um artefato SDD, leia-se **cabeçalho markdown** — localize com `grep -n '^\*\*Chave\*\*:'`, nunca com parser de YAML.
- **Formas canônicas para contar/localizar IDs** (a lista da SPEC é bullet, o heading não; contagem com o padrão errado devolve zero em silêncio): FR/NFR/AC → `grep -c '^- \*\*FR-'` (idem `NFR-`/`AC-`) · FEAT → `grep -c '^### FEAT-'` · TASKs de um slug → `ls tasks/TASK-*.md | grep -v INDEX` (o glob cru inclui os `TASK-NNN-INDEX.md`, que são panorama, não tarefa). Contagem que der `0` num artefato notoriamente populado é sinal de padrão errado, não de artefato vazio — confira o formato real antes de concluir.
- **Ficha primeiro.** Ler `keelson.config.json` na raiz antes de qualquer coisa — dela vêm `docsRoot`, `codePaths`, `profile`, os comandos de qualidade (`quality.*`) e os `gates`. Nunca assumir caminhos ou comandos fixos.
- **Perfil de linguagem ativo.** Resolvido pelo campo `profile.<role>.file` da ficha: prefixo `plugin:` → `${CLAUDE_PLUGIN_ROOT}/guidelines/<resto>`; caminho simples → relativo à raiz do projeto; campo ausente → exemplar do plugin com a mesma `lang`, senão `guidelines/project/<role>/`. Perfil com `reviewed: false` no front-matter → avisar que está pendente de revisão humana. A doutrina `${CLAUDE_PLUGIN_ROOT}/guidelines/core/*` **vale sempre** (aderência é gate — implement, princípio 2); a **carga** segue o mapa: main session dos comandos não lê core/* (specify é agnóstica por regra própria; plan/tasks/implement carregam Charter+perfil conforme seus corpos); /keelson:auto lê só a tabela de rigor/papéis de WORKFLOW.md na triagem; cada subagent lê os core/* que seu corpo lista. PERFORMANCE.md: developer/code-reviewer o carregam quando a task toca consulta, laço sobre volume variável ou renderização pesada (mesmo gatilho da seção de performance do perfil). Some as lições do projeto (`guidelines/project/`).
- **Memo de exploração.** Exploração de código/domínio é salva em `thoughts/local/exploration-<slug>.md` (concisa: caminhos + mecanismo); as etapas seguintes leem o memo em vez de re-explorar e o complementam se faltar detalhe. O memo é snapshot — antes de editar, vale o arquivo real.
- **Estado de run (guarda anti-parada).** Execução de waves mantém `thoughts/local/run-state-<slug>.md` — formato canônico (uma linha por campo, exatamente estas chaves):

  ```md
  status: em_andamento
  slug: <slug>
  plan: PLAN-MMM
  waves_concluidas: <X>
  waves_total: <N>
  retomada: {docsRoot}/<slug>/INDEX.md + {docsRoot}/<slug>/tasks/TASK-MMM-INDEX.md
  ```

  O `/keelson:implement` cria antes da primeira wave e atualiza `waves_concluidas` a cada final de wave; a Entrega (Etapa 5 do `/keelson:auto`, ou o output final do implement avulso) encerra/remove. O hook `wave-guard` (Stop) lê este arquivo **fora do contexto do modelo** — imune à sumarização — e bloqueia encerramento de turno enquanto `status: em_andamento` (decisões 4.23/4.24). Parada legítima (Entrega feita, degrau 3 com pergunta já disparada, pedido explícito do humano) muda `status:` para `encerrado — <motivo>` antes de encerrar.
- **Resolução de slug.** Dona é a Etapa 0.2 do `/keelson:specify`: reusar slug de domínio existente (inclusive legado — que primeiro migra) antes de criar novo; na dúvida, perguntar ao humano.
- **Merge, PR e deploy são humanos.** Nenhum comando faz merge, abre PR nem deploya — a autonomia termina no push da branch de trabalho (4.37/4.41). Promoção de Status (`Draft → Approved → Done`): nunca é de validator; no ciclo com BRIEF (modo autônomo), a main session promove pelo veredito `APROVAR` do `po` (4.38); sem brief ou no `/keelson:guided`, é humana.
- **Falha de gate**: 1 retry; persistiu → escalar ao humano com o diagnóstico.
