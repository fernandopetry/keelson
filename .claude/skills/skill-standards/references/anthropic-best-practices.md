# Digest — Anthropic Agent Skills best practices

fetched: 2026-10-22

Fontes:
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://code.claude.com/docs/en/skills
- https://agentskills.io/specification (padrão aberto que o Claude Code declara seguir)
- https://agentskills.io/skill-creation/best-practices
- https://agentskills.io/skill-creation/optimizing-descriptions
- https://agentskills.io/skill-creation/evaluating-skills
- https://agentskills.io/skill-creation/using-scripts

Este arquivo é **espelho** do que a doc diz na data acima — reescreva inteiro no
re-fetch, nunca acumule versões.

## Conteúdo

- Concisão e escopo
- Descoberta (name + description)
- Frontmatter no Claude Code
- Progressive disclosure
- Graus de liberdade
- Conteúdo
- Workflows
- Scripts embarcados
- Avaliação
- Quando o modelo deixa de seguir a skill
- Anti-padrões

## Concisão e escopo

- A janela de contexto é um bem compartilhado; só nome + description pré-carregam, o
  corpo carrega sob demanda e, uma vez carregado, **fica na conversa** nos turnos
  seguintes (o arquivo não é relido; re-invocação com conteúdo idêntico vira nota curta).
  Escreva **instruções permanentes**, não passos de uma vez.
- Pergunta por frase: "o agente erraria sem esta instrução?" — não → cortar. Se o agente
  já faz a tarefa inteira bem sem a skill, a skill talvez não agregue valor (teste).
- Acrescente o que o agente **não sabe** (convenção do projeto, procedimento do domínio,
  edge case não óbvio, ferramenta/API a usar); omita o que ele sabe (o que é um formato,
  como instalar biblioteca).
- **Detalhe moderado**: skill exaustiva prejudica — o agente não acha o relevante e segue
  instruções que não se aplicam ao caso. Guia conciso por passos + um exemplo funcional
  supera documentação completa; edge case que o julgamento do agente resolve fica fora.
- **Unidade coerente** (como escopo de função): estreita demais força várias skills por
  tarefa (overhead + instruções conflitantes); larga demais ativa mal.
- Corpo do `SKILL.md` **< 500 linhas e < 5.000 tokens**; perto disso, dividir em arquivos
  auxiliares.
- Compactação re-anexa a invocação mais recente de cada skill: **5.000 tokens por skill**,
  **25.000 no total**, da mais recente para a mais antiga — por isso o **mais importante
  vai no topo** do `SKILL.md`; skill longa perde a cauda.
- Dois tipos de conteúdo no Claude Code: **referência** (convenções/conhecimento, roda
  inline) e **tarefa** (passo a passo; costuma levar `disable-model-invocation: true` e
  muitas vezes `context: fork`). A doc do Claude Code diz "o quê, não como nem porquê";
  a do agentskills.io diz que em instrução flexível **explicar o porquê** rende mais que
  diretiva rígida — ver *Graus de liberdade*.

## Descoberta (name + description)

- `description`: **≤1024 chars**, com **o quê** (ações concretas) + **quando usar**
  (gatilhos/contextos) + termos-chave que o pedido real usaria. Foco na **intenção do
  usuário**, não na mecânica interna. Nunca 1ª pessoa ("posso ajudar…"); a doc da
  plataforma pede **3ª pessoa** ("Processa X…"), a do agentskills.io pede **imperativo
  ao agente** ("Use this skill when…") — as duas aceitam "Faz X. Use quando Y".
- **Seja "pushy"**: liste contextos onde a skill se aplica mesmo sem o usuário nomear o
  domínio ("even if they don't explicitly mention 'CSV'"). Anti-padrões: "ajuda com
  documentos", "processa dados".
- O agente só consulta skill para tarefa além do que faz com ferramenta básica — pedido
  trivial de um passo pode não disparar mesmo com description perfeita.
- No Claude Code, `description` + `when_to_use` são **truncadas em 1.536 chars** e a
  **listagem inteira tem orçamento de 1% da janela** do modelo: estourou, as descriptions
  das skills **menos invocadas** são descartadas (fica só o nome). Logo: caso de uso
  principal **na primeira frase**. Ajustes: `skillListingBudgetFraction`,
  `skillListingMaxDescChars`, `skillOverrides: "name-only"` para as de baixa prioridade;
  `/doctor` estima o custo da listagem, `/skill-doctor` aponta as nunca usadas.
- `name`: **≤64 chars**, só `[a-z0-9-]`, sem começar/terminar com hífen nem `--`, igual
  ao nome da pasta (spec), sem tag XML; preferência por gerúndio (`processing-pdfs`) ou
  frase nominal; nunca vago (`helper`, `utils`) nem reservado (`anthropic`, `claude`,
  `anthropic-skills*`, pasta `synced`). Caractere invisível/controle/`<>` no nome →
  a skill não carrega (ver com `claude --debug`, buscar `[names]`).
- Skill chamada `verify` ou `simplify` no projeto/pessoal **roda sozinha antes de cada
  commit** (Claude Code) — não use esses nomes sem querer esse efeito.

## Frontmatter no Claude Code (todos opcionais; campo desconhecido é ignorado)

- `when_to_use` · `argument-hint` · `arguments` (nomes posicionais para `$nome`) ·
  `disable-model-invocation` (só humano invoca; description fora do contexto; não
  pré-carrega em subagent; não roda em tarefa agendada; se o modelo tentar, é bloqueado
  e instruído a não reproduzir os passos) · `user-invocable: false` (só o modelo invoca)
  · `allowed-tools` / `disallowed-tools` (valem só no turno; `allowed-tools` **não**
  é barrado por workspace trust — revise skill de repo antes de rodar) · `model` ·
  `effort` · `context: fork` + `agent` + `background` (fork **não vê o histórico**: a
  instrução tem de ser autocontida e ter tarefa explícita) · `hooks` · `paths` (glob que
  limita a ativação automática; só arquivos dentro do cwd) · `shell` · `metadata` ·
  `license` · `compatibility` (≤500 chars; só se houver requisito de ambiente).
- Frontmatter só é lido se o `---` de abertura é a 1ª linha; YAML inválido carrega a
  skill sem campo nenhum (`/skill-name` funciona, matching por description não).
  Booleanos aceitam `true/false`, `yes/no`, `on/off`, `1/0`.
- Fora do Claude Code (upload/packaging/API) só valem `name`, `description`, `license`,
  `compatibility`, `metadata`, `allowed-tools` — campo extra é erro duro; `` !`cmd` ``
  não roda lá.
- `.claude/commands/` foi **fundido em skills** (mesmo frontmatter menos `name` e
  `paths`); **prefira skill** para trabalho novo (pasta com arquivos auxiliares).
- Substituições: `$ARGUMENTS`, `$ARGUMENTS[N]`/`$N`, `$nome`, `${CLAUDE_SKILL_DIR}`,
  `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`,
  `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`; `$` literal escapa com `\`. Contexto
  dinâmico: `` !`cmd` `` no início da linha (ou bloco ```` ```! ````); exit ≥2 **aborta a
  invocação inteira** (exit 1 de grep/diff é normal; para outros, `|| true`); timeout
  2 min; sem prompt de permissão (deny rule aborta; fora do auto mode, "ask" também).
- Validação mecânica do frontmatter: `claude plugin validate <dir-de-skills>`
  (Claude Code) ou `skills-ref validate ./skill` (spec).

## Progressive disclosure

- `SKILL.md` é índice, não enciclopédia: visão geral pontuda + referências a arquivos
  auxiliares que só carregam quando necessários. Convenção da spec: `scripts/`
  (executa), `references/` (lê), `assets/` (templates, dados).
- Diga **quando** abrir cada arquivo: "leia `references/api-errors.md` se a API devolver
  não-200" é útil; "veja references/ para detalhes" não é.
- **Uma camada de profundidade**: `SKILL.md → arquivo` sim; `arquivo → arquivo` não
  (leitura parcial com `head` compromete a informação).
- Arquivo auxiliar >100 linhas ganha índice (TOC) no topo.
- **Gotchas ficam no `SKILL.md`**, não em auxiliar: o agente precisa lê-los antes de
  topar com a situação, e pode não reconhecer o gatilho para abrir o arquivo.
- Template curto inline; longo ou condicional em `assets/`, referenciado.

## Graus de liberdade

- **Alta** (instruções de alto nível): múltiplas abordagens válidas. Aqui, **explicar o
  porquê** ("faça X porque Y causa Z") rende mais que diretiva rígida ("SEMPRE X").
- **Média** (pseudocódigo/template com parâmetros): padrão preferido, variação aceitável.
- **Baixa** (script exato, "não modifique"): operação frágil, consistência crítica,
  sequência obrigatória.
- A maioria das skills mistura os três — calibre **cada parte** separadamente.
- **Procedimento, não declaração**: ensinar *como abordar* a classe de problema, não
  *o que produzir* para uma instância (método reutilizável vs. resposta pronta).
- Testar com todos os modelos que vão usar a skill (o que basta ao Opus pode faltar ao
  Haiku).

## Conteúdo

- **Parta de expertise real**: extraia a skill de uma tarefa feita de verdade (passos
  que funcionaram, correções que você fez, formatos de entrada/saída, contexto que o
  agente não tinha) ou sintetize de artefatos do projeto (runbooks, style guides,
  comentários de code review, histórico do VCS, incidentes resolvidos). Skill gerada só
  do conhecimento geral do LLM sai genérica ("trate erros adequadamente").
- **Seção Gotchas** é o conteúdo de maior valor: fatos do ambiente que contrariam a
  suposição razoável (soft delete, mesmo ID com três nomes, `/health` que mente).
  Correção que você teve de fazer ao agente → vira linha nos gotchas.
- **Default + escape hatch**: uma ferramenta padrão nomeada, alternativa só com gatilho —
  nunca menu de equivalentes.
- **Sem informação time-sensitive** no fluxo principal — legado em seção "Old patterns"
  (`<details>`) destacada.
- **Terminologia consistente**: um termo por conceito.
- Exemplos concretos input/output; templates com nível de rigor declarado
  ("SEMPRE esta estrutura" vs. "default sensato, adapte").
- Ferramenta MCP citada com nome qualificado `Servidor:ferramenta`.

## Workflows

- Tarefa multi-passo crítica → checklist copiável (evita pular validação).
- **Loop de validação**: executar → validar (script, checklist ou documento de
  referência) → corrigir → repetir; só prosseguir com validação verde.
- Fluxo condicional explícito (criar-vs-editar); workflow grande vai para arquivo próprio.
- **Plan–validate–execute** para operação em lote/destrutiva: plano estruturado →
  validador contra a fonte de verdade → executar; validador **verboso** ("campo X não
  existe; disponíveis: …").

## Scripts embarcados

- **Resolver, não postergar**: tratar erro e criar fallback no script, não deixar o
  modelo consertar em runtime. Constantes justificadas em comentário (por que 30s).
- Script pré-feito > código gerado; sinal para embarcar: traces de várias rodadas
  reinventando a mesma lógica. Declarar se é para **executar** ("rode X") ou **ler**
  ("veja X"). Listar os scripts disponíveis no `SKILL.md`; paths relativos à raiz da
  skill (também dentro de `references/*.md`).
- Dependências declaradas; nunca presumir instalado. Comando avulso com versão pinada
  (`npx eslint@9.0.0`, `uvx ruff@0.8.0`); script autocontido com deps inline (PEP 723 +
  `uv run`; `npm:`/`jsr:` no Deno; `bundler/inline` no Ruby). Requisito de runtime →
  `compatibility`.
- **Desenho para uso agêntico**: sem prompt interativo (hang) — tudo por flag/env/stdin;
  `--help` curto com exemplos; erro diz o que veio, o que era esperado e o que tentar;
  dado estruturado (JSON/CSV) em stdout, diagnóstico em stderr; idempotente (retry);
  entrada ambígua → erro, não chute; `--dry-run` para destrutivo; exit codes distintos e
  documentados; saída previsível (harness trunca em 10–30K chars) → resumo por default,
  `--offset`/`--output` para o resto.

## Avaliação

- **Eval-driven, antes de escrever muito**: rodar o modelo SEM a skill em tarefas reais →
  documentar falhas → **3+ cenários** → baseline → escrever o mínimo que passa → iterar
  observando comportamento real (ordem de leitura, referências seguidas, arquivo nunca
  acessado → remover). Leia **traces**, não só saída final.
- Formato do agentskills.io / `skill-creator`: `evals/evals.json` (`id`, `prompt`
  realista, `expected_output`, `files`, `assertions` adicionadas **depois** da 1ª
  rodada); começar com **2–3 casos**; cada caso roda **com e sem** a skill (ou vs.
  snapshot da versão anterior) em contexto limpo (subagent); `timing.json` (tokens,
  duração), `grading.json` (PASS/FAIL **com evidência** — "tem seção Resumo" com uma
  frase vaga é FAIL), `benchmark.json` (média/desvio e **delta** custo × ganho).
  Assertion que sempre passa nos dois braços → remover; que sempre falha → consertar o
  caso. Comparação **cega** entre versões para qualidade holística. Revisão humana em
  `feedback.json` ("falta rótulo no eixo" é acionável; "ficou ruim" não).
- Ao iterar: generalizar do feedback (não patch por exemplo), **manter enxuta** (platô →
  tente remover), explicar o porquê, embarcar trabalho repetido; parar quando o feedback
  esvazia.
- **Descrição se otimiza com teste de gatilho**: ~**20 queries** (8–10 devem disparar,
  8–10 não; as negativas valiosas são **near-miss**, com palavras-chave em comum),
  **3 rodadas** por query, passa se trigger rate acima/abaixo de **0,5**; split
  **treino 60% / validação 40%**; mudar a description só pelos erros do treino, sem
  copiar palavras das queries falhas (overfit); escolher a iteração pela taxa de
  **validação**; **5 iterações** costumam bastar; fechar com 5–10 queries novas.
- Ferramentas no Claude Code: `claude plugin eval` (plugin; grader `tool_used: Skill`;
  CI por limiar), plugin `skill-creator` (formato acima; não intercambiável com o
  `plugin eval`), `/skill-doctor` (custo e uso por skill), `/doctor prompt-audit`
  (instruções datadas/conflitantes). Two-Claude pattern: um Claude cria/enxuga, outro
  testa às cegas.

## Quando o modelo deixa de seguir a skill

- Regra que **tem de valer sempre** → vira **hook** (do settings ou do frontmatter
  `hooks` da skill); skill é lida uma vez, hook roda a cada evento.
- Orientação de **julgamento** → redigir para a tarefa inteira ("rode os testes após
  cada edição", não "rode os testes").
- **Compactação** cortou a cauda → re-invocar; e manter o essencial no topo.

## Anti-padrões (tabela da doc)

| Anti-padrão | Correção |
|---|---|
| Path estilo Windows (`\`) | Sempre `/` |
| Menu de bibliotecas equivalentes | Default + escape hatch |
| Referências aninhadas fundas | 1 camada a partir do SKILL.md |
| Info datada no fluxo | Seção "Old patterns" |
| Frontmatter inválido | Validar name/description (limites acima; `claude plugin validate`) |
| Descrição vaga ou que descreve a mecânica | O quê + quando + termos-chave, na intenção do usuário |
| Presumir pacote instalado | Declarar a dependência (pinada) |
| Skill gerada sem contexto do domínio | Extrair de tarefa real / artefatos do projeto |
| Resposta pronta para uma instância | Procedimento reutilizável para a classe |
| Script com prompt interativo / erro opaco | Flags + `--help` + erro que orienta |
| História no lugar da regra (adaptação keelson, 4.442): "caso real", "Nª reincidência", "desde a 4.NNN", versão pinada, parágrafo colado com "E …" | A regra cita `(4.NNN)` e para; o caso mora na decisão — `scripts/check-doctrine.sh` |
