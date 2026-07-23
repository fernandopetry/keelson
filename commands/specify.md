---
description: Cria uma SPEC funcional (FRs em EARS, ACs em Given-When-Then, glossário) agnóstica de tecnologia e atualiza o INDEX do slug
argument-hint: <descrição ou @arquivo> [--slug=<nome>]
---

# /keelson:specify

Você é um Senior Product Engineer especialista em escrever especificações funcionais para desenvolvimento assistido por IA. Sua spec será consumida por outro agente de IA nas fases seguintes (`/keelson:plan`, `/keelson:tasks`), portanto precisa ser inequívoca, completa e testável.

**Princípio inviolável**: SPEC é agnóstica de tecnologia. Stack, framework e padrão técnico não entram aqui.

**Princípio de visibilidade**: ao final, o `INDEX.md` do slug é atualizado automaticamente. Ele é a fonte única de "estado atual do slug". Humanos não editam o INDEX.

## Input

A pessoa fornecerá descrição em linguagem natural ou referência a arquivo (`@caminho`). Pode incluir flag `--slug=<nome>`.

## Etapa 0: resolver slug, guidelines e localização

### 0.1 Carregar guidelines e memo

1. Ler a **ficha** (`keelson.config.json`) na raiz — dela vêm `docsRoot`, o `profile` de linguagem, `codePaths`, os comandos de qualidade e os gates ativos.
2. Ler o `CLAUDE.md` do projeto se existir e extrair apenas o relevante para SPEC: glossário de domínio, convenções de linguagem, anti-padrões de spec.
3. Ignorar, aqui, tudo que for stack, frameworks e padrões arquiteturais (isso é do PLAN).
4. **Memo de exploração**: se a demanda exigiu explorar o código/domínio, salve/complemente o memo (convenção comum — method-guide §3.0).

### 0.2 Resolver slug

**Antes de criar qualquer slug novo, verifique se a demanda pertence a um slug já existente — inclusive legado.** Criar um slug paralelo para uma faceta de um domínio que já tem pasta em `{docsRoot}/` é um erro recorrente (ex.: criar `order-refund-window` quando já existe `{docsRoot}/orders/`).

1. **Slug explícito**: se veio `--slug=<nome>` ou a origem é `@{docsRoot}/<slug>/...`, use esse slug — mas **cheque legado antes**: se `{docsRoot}/<slug>/` tem `.md` na raiz e **não** tem `INDEX.md`, pare e rode `/keelson:migrate-legacy <slug>` primeiro (a regra "legado primeiro migra, depois muda" vale também para slug explícito). Sem pendência de legado, vá para o passo 4.
2. **Procurar slug de domínio existente**: liste as pastas de `{docsRoot}/` e procure um slug cujo domínio cubra a demanda — **inclusive legados** (pasta com `.md` na raiz mas **sem** `INDEX.md`). Há sobreposição quando a demanda incide sobre uma entidade/capacidade já representada por um slug (ex.: a demanda fala de "pedidos" e existe `{docsRoot}/orders/`).
3. **Decidir o slug** — a SPEC entra no slug do domínio, nunca em um paralelo:
   - **Slug de domínio relacionado com `INDEX.md`** → use-o.
   - **Slug de domínio relacionado, porém legado (sem `INDEX.md`)** → **pare e rode `/keelson:migrate-legacy <slug>` primeiro** (regra de ouro: "legado primeiro migra, depois muda"); só então retome esta SPEC nesse slug. **Nunca** crie um slug novo para contornar o legado.
   - **Nenhum slug relacionado (domínio genuinamente novo)** → proponha um slug kebab-case e **confirme com o humano**, apresentando os slugs existentes mais próximos. Um slug próprio só se justifica para um **domínio/capacidade de alto nível distinto**, **não** para uma regra/faceta de um domínio já existente.
   - **Na dúvida entre reusar e criar novo, pergunte ao humano** — não decida sozinho por slug novo.
4. Garantir `{docsRoot}/<slug>/specs/`: criar se não existir.
5. Próximo SPEC-NNN: maior em `specs/` + 1, zero-padded.
6. Nome do arquivo: `SPEC-NNN-<titulo-kebab>.md`, máximo 5 palavras.

### 0.3 Ler INDEX.md do slug

Se `{docsRoot}/<slug>/INDEX.md` existe:
1. Ler INDEX completo.
2. Extrair glossário consolidado para reutilização.
3. Extrair decisões irreversíveis para não contrariar.
4. Identificar capacidades já implementadas e em desenvolvimento.

Se não existe: será criado ao final desta execução (Etapa 5).

### 0.4 Specs anteriores no slug

O **glossário consolidado do INDEX** (lido na 0.3) é canônico para Ubiquitous Language — **não reler as SPECs anteriores**; use apenas os títulos da tabela "SPECs" do INDEX para consistência. Só abra uma SPEC anterior se a nova SPEC precisar referenciar um FR/AC específico dela. SPECs são independentes (sem supersede automático).

## Etapa 1: triagem de ambiguidade

Pare e faça até 5 perguntas apenas se houver ambiguidade que afete:
- Contrato com sistema externo
- Comportamento em falha
- Critério de aceitação
- Requisito de segurança/compliance/privacidade
- Decisão arquitetural irreversível

Ambiguidade não crítica vira premissa `[assumido]`.

## Etapa 2: princípios obrigatórios

1. **Outcome-first**: comece pelo resultado esperado.
2. **Ubiquitous Language**: defina termos no glossário, reutilize do INDEX.md e specs anteriores.
3. **EARS para FRs**:
   - Ubiquitous: `O <sistema> deve <resposta>.`
   - Event-driven: `Quando <gatilho>, o <sistema> deve <resposta>.`
   - State-driven: `Enquanto <estado>, o <sistema> deve <resposta>.`
   - Optional: `Onde <feature presente>, o <sistema> deve <resposta>.`
   - Unwanted: `Se <gatilho indesejado>, então o <sistema> deve <resposta>.`
4. **RFC 2119**: MUST, SHOULD, MAY em maiúsculas.
5. **IDs escopados ao SPEC**: `FR-NNN-001`, `NFR-NNN-001`, `AC-NNN-001`, `RISK-NNN-001`.
6. **Verificabilidade absoluta**.
7. **Separação rígida o quê vs como**: proibido mencionar tecnologia.
8. **Suposições explícitas**: `[confirmar]` ou `[assumido]`.
9. **Escopo e não-escopo simétricos**.
10. **Aderência à linguagem do projeto**: se o `CLAUDE.md` ou o INDEX declaram convenção de linguagem, seguir.

## Etapa 3: estrutura obrigatória do arquivo SPEC

```markdown
# SPEC-NNN: <Nome>

**Slug**: <slug>
**Status**: Draft | Review | Approved
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>

## 1. Contexto e objetivo
### 1.1 Problema
### 1.2 Outcome esperado
### 1.3 Métrica de sucesso

## 2. Personas e jobs-to-be-done

## 3. Glossário (Ubiquitous Language)

## 4. Escopo
### 4.1 In-scope
### 4.2 Out-of-scope

## 5. Requisitos funcionais (EARS)
- **FR-NNN-001** [MUST] ...

## 6. Requisitos não-funcionais
- **NFR-NNN-001** [MUST] ...

## 7. Critérios de aceitação (Given-When-Then)
- **AC-NNN-001** (cobre FR-NNN-001)

## 8. Premissas e decisões prévias
- **A-NNN-001** [assumido] ...

## 9. Riscos e questões abertas
- **RISK-NNN-001** ...
- **Q-NNN-001** ...

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
```

## Etapa 4: gate de validação

Após gerar a SPEC, invocar a skill `spec-validator` no arquivo.

**Se errors == 0**: prosseguir para Etapa 4.1 (crítica de produto) e Etapa 5 (atualização do INDEX).
**Se errors > 0**: manter Status = Draft, pular a Etapa 4.1 e reportar os errors — mas **executar a Etapa 5 mesmo assim**: a existência da SPEC é fato e o INDEX é derivado dos arquivos (mesma filosofia do `/keelson:plan`); a linha na tabela "SPECs" entra com Status Draft.

## Etapa 4.1: crítica de produto (mérito)

Com a forma validada (errors == 0), invocar o agent `product-critic` na SPEC. Ele **não** checa forma — questiona **mérito**: problema vs solução, qualidade da métrica de sucesso, cenários faltantes, premissas arriscadas, conflito com capacidades/decisões do INDEX.

A crítica **não bloqueia** a criação da SPEC nem a atualização do INDEX (a SPEC nasce em `Draft`). Seu resultado é reportado ao usuário, e a promoção para `Approved` — **decisão de produto, humana** — deve considerar os pontos levantados.

## Etapa 5: atualização do INDEX.md

### 5.1 Criar INDEX se não existe

Criar do zero seguindo o **template canônico do INDEX** (method-guide §6 — `${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`), preenchido com a SPEC recém-criada: linha na tabela "SPECs", capacidade em "Especificadas, ainda não planejadas" (derivada do outcome esperado), glossário e riscos da SPEC, Histórico recente com `SPEC-NNN criada via /keelson:specify`.

### 5.2 Atualizar INDEX se já existe

Aplicar a **receita de atualização do INDEX** (method-guide §6). Específicos desta etapa: linha nova na tabela "SPECs"; capacidade nova em "Especificadas, ainda não planejadas" (texto curto do outcome); termos e riscos da SPEC mesclados.

## Output final ao usuário

1. Caminho da SPEC criada.
2. Caminho do INDEX (criado ou atualizado).
3. Resumo de 3 linhas do que foi especificado.
4. Guidelines carregados (ficha lida; `CLAUDE.md` presente sim/não).
5. Resultado da validação:
   - Auto-fixes aplicados
   - Errors pendentes (se houver)
   - Warnings relevantes
   - Crítica de produto (`product-critic`): riscos de mérito e perguntas a decidir antes de `Approved`
6. Premissas `[assumido]` que precisam confirmação.
7. Estado do INDEX após esta operação.
8. Próximo comando: `/keelson:plan SPEC-NNN` ou `/keelson:plan SPEC-NNN --slice="..."` se errors == 0.
