# Digest — Anthropic Agent Skills best practices

fetched: 2026-09-24

Fontes:
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://code.claude.com/docs/en/skills

Este arquivo é **espelho** do que a doc diz na data acima — reescreva inteiro no
re-fetch, nunca acumule versões.

## Concisão

- A janela de contexto é um bem compartilhado; só nome + description pré-carregam, o
  corpo carrega sob demanda (e, uma vez carregado, fica na conversa nos turnos seguintes;
  re-invocação com conteúdo idêntico vira uma nota curta, não segunda cópia).
- Desafiar cada frase: "o modelo precisa desta explicação?" / "posso assumir que ele já
  sabe?". Não explicar o óbvio (o que é um formato, como instalar biblioteca).
- Corpo do `SKILL.md` **< 500 linhas**; perto disso, dividir em arquivos auxiliares.
- Compactação automática re-anexa a invocação mais recente de cada skill: **5.000 tokens
  por skill**, **25.000 no total**, da mais recente para a mais antiga — skill longa perde
  a cauda depois de compactar.

## Descoberta (name + description)

- `description`: **≤1024 chars**, em **3ª pessoa**, com **o quê** (ações concretas) +
  **quando usar** (gatilhos/contextos) + termos-chave que o pedido real usaria.
  Anti-padrões: "ajuda com documentos", "processa dados", 1ª pessoa ("posso ajudar…").
  No Claude Code, `description` + `when_to_use` são **truncadas em 1.536 chars** na
  listagem de skills.
- `name`: **≤64 chars**, minúsculas/números/hífens, sem tag XML; preferência por
  gerúndio (`processing-pdfs`) ou frase nominal; nunca vago (`helper`, `utils`) nem
  palavras reservadas (`anthropic`, `claude`); pasta `synced` é reservada.

## Frontmatter no Claude Code (todos opcionais; campo desconhecido é ignorado)

- `when_to_use` (gatilhos extras, somados à description) · `argument-hint` ·
  `arguments` (nomes posicionais para `$nome`) · `disable-model-invocation` (só humano
  invoca; description fora do contexto; não pré-carrega em subagent; não roda em tarefa
  agendada) · `user-invocable: false` (só o modelo invoca) · `allowed-tools` /
  `disallowed-tools` (valem só no turno) · `model` · `effort` · `context: fork` +
  `agent` + `background` · `hooks` · `paths` (glob que limita a ativação automática) ·
  `shell` · `metadata` · `license` · `compatibility` (≤500 chars).
- Frontmatter só é lido se o `---` de abertura é a 1ª linha; YAML inválido carrega a
  skill sem campo nenhum.
- Fora do Claude Code (upload/packaging) só valem `name`, `description`, `license`,
  `compatibility`, `metadata`, `allowed-tools` — campo extra é erro duro.
- `.claude/commands/` é formato antigo (mesmo frontmatter menos `name` e `paths`);
  **prefira skill** para trabalho novo (suporta arquivos auxiliares).
- Substituições: `$ARGUMENTS`, `$N`, `$nome`, `${CLAUDE_SKILL_DIR}`,
  `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`,
  `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`. Contexto dinâmico: `` !`cmd` `` no início
  da linha (ou bloco ```` ```! ````); comando que falha **aborta a invocação inteira**;
  timeout 2 min; sem prompt de permissão (deny rule aborta).

## Progressive disclosure

- `SKILL.md` é índice, não enciclopédia: visão geral pontuda + referências a arquivos
  auxiliares (`REFERENCE.md`, `EXAMPLES.md`, por domínio, ou condicionais
  básico/avançado) que só carregam quando necessários; dizer o que cada arquivo contém
  e quando abrir.
- **Uma camada de profundidade**: `SKILL.md → arquivo` sim; cadeia
  `arquivo → arquivo → arquivo` não (leitura parcial compromete a informação).
- Arquivo auxiliar >100 linhas ganha índice (TOC) no topo.

## Graus de liberdade

- **Alta** (instruções de alto nível): múltiplas abordagens válidas.
- **Média** (pseudocódigo/template com parâmetros): padrão preferido, variação aceitável.
- **Baixa** (script exato, "não modifique"): operação frágil, consistência crítica,
  sequência obrigatória.
- Analogia: ponte estreita sobre precipício → guardrails exatos; campo aberto →
  confiança no modelo.
- Testar com todos os modelos que vão usar a skill (o que basta ao Opus pode faltar ao
  Haiku).

## Workflows

- Tarefa multi-passo crítica → checklist copiável (evita pular validação).
- **Loop de feedback**: executar → validar → corrigir → repetir; só prosseguir com
  validação verde.
- Fluxo condicional explícito (decision tree criar-vs-editar etc.); workflow grande vai
  para arquivo próprio.
- Plan–validate–execute para operações em lote: plano verificável antes de aplicar;
  validador verboso ("campo X não existe; disponíveis: …").

## Conteúdo

- **Default + escape hatch**: uma ferramenta padrão nomeada, alternativa só com gatilho
  ("Use pdfplumber; para PDF escaneado, pdf2image") — nunca menu de equivalentes.
- **Sem informação time-sensitive** no fluxo principal — legado em seção "Old patterns"
  destacada.
- **Terminologia consistente**: um termo por conceito.
- Exemplos concretos input/output; templates com nível de rigor declarado
  ("SEMPRE esta estrutura" vs. "default sensato, adapte").

## Scripts embarcados

- **Resolver, não postergar**: tratar erro e criar fallback no script, não deixar o
  modelo consertar em runtime.
- Constantes justificadas em comentário (por que 30s, por que 3 retries).
- Script pré-feito > código gerado (confiabilidade, tokens, consistência); declarar se é
  para **executar** ("rode X") ou **ler como referência** ("veja X").
- Dependências declaradas no corpo (`pip install …`); nunca presumir instalado.
- Ferramenta MCP citada com nome qualificado `Servidor:ferramenta`.

## Avaliação

- **Eval-driven**: rodar o modelo SEM a skill em tarefas reais → documentar falhas →
  3+ cenários de teste → baseline → escrever o mínimo que passa → iterar observando
  comportamento real (ordem de leitura, referências seguidas, arquivo nunca acessado →
  remover). Não há runner embutido na doc da plataforma.
- Two-Claude pattern: um Claude ajuda a criar/enxugar, outro Claude testa às cegas.

## Anti-padrões (tabela da doc)

| Anti-padrão | Correção |
|---|---|
| Path estilo Windows (`\`) | Sempre `/` |
| Menu de bibliotecas equivalentes | Default + escape hatch |
| Referências aninhadas fundas | 1 camada a partir do SKILL.md |
| Info datada no fluxo | Seção "Old patterns" |
| Frontmatter inválido | Validar name/description (limites acima) |
| Descrição vaga | O quê + quando + termos-chave |
| Presumir pacote instalado | Declarar a dependência |
