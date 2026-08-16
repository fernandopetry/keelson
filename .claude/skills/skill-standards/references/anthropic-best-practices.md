# Digest — Anthropic Agent Skills best practices

fetched: 2026-08-16

Fontes:
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://code.claude.com/docs/en/skills

Este arquivo é **espelho** do que a doc diz na data acima — reescreva inteiro no
re-fetch, nunca acumule versões.

## Concisão

- A janela de contexto é um bem compartilhado; só nome + description pré-carregam, o
  corpo carrega sob demanda.
- Desafiar cada frase: "o modelo precisa desta explicação?" / "posso assumir que ele já
  sabe?". Não explicar o óbvio (o que é um formato, como instalar biblioteca).
- Corpo do `SKILL.md` **< 500 linhas**; perto disso, dividir em arquivos auxiliares.

## Descoberta (name + description)

- `description`: **≤1024 chars**, em **3ª pessoa**, com **o quê** (ações concretas) +
  **quando usar** (gatilhos/contextos) + termos-chave que o pedido real usaria.
  Anti-padrões: "ajuda com documentos", "processa dados", 1ª pessoa ("posso ajudar…").
- `name`: **≤64 chars**, minúsculas/números/hífens; preferência por gerúndio
  (`processing-pdfs`) ou frase nominal; nunca vago (`helper`, `utils`) nem palavras
  reservadas (`anthropic`, `claude`).

## Progressive disclosure

- `SKILL.md` é índice, não enciclopédia: visão geral pontuda + referências a arquivos
  auxiliares (`REFERENCE.md`, `EXAMPLES.md`, por domínio, ou condicionais
  básico/avançado) que só carregam quando necessários.
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

## Workflows

- Tarefa multi-passo crítica → checklist copiável (evita pular validação).
- **Loop de feedback**: executar → validar → corrigir → repetir; só prosseguir com
  validação verde.
- Fluxo condicional explícito (decision tree criar-vs-editar etc.).
- Plan–validate–execute para operações em lote: plano verificável antes de aplicar.

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
  para **executar** ou **ler como referência**.
- Dependências declaradas no corpo (`pip install …`).

## Avaliação

- **Eval-driven**: rodar o modelo SEM a skill em tarefas reais → documentar falhas →
  3+ cenários de teste → baseline → escrever o mínimo que passa → iterar observando
  comportamento real (ordem de leitura, referências seguidas, arquivo nunca acessado →
  remover).
- Testar nos vários modelos (o que basta num modelo forte pode ser pouco num menor).
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
