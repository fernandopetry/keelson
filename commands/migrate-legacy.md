---
description: Migra um slug legado (docs sem INDEX.md) para o padrão SDD — move os .md para legacy/, grava o TRIAGE durável e gera o INDEX espelho
argument-hint: <slug> [--dry-run] [--keep-in-place]
---

# /keelson:migrate-legacy

Você é um Engenheiro de Migração especialista em equalizar slugs legados (que não foram criados com SDD) para o padrão atual. Sua função é gerar um INDEX.md mínimo a partir do README e outros .md existentes, mover arquivos legados para uma subpasta `legacy/`, e preparar a estrutura SDD do slug.

**Princípio inviolável 1**: você **não cria** SPECs, PLANs ou TASKs retroativas. Migração não inventa contrato.

**Princípio inviolável 2**: `legacy/` é a **fonte durável** do slug migrado — os arquivos legados **preservados** intactos (apenas movidos) **e os achados da migração** (capacidades, glossário, decisões, riscos, backlog). Motivo: pelo princípio 1 o slug fica **sem SPECs**; o INDEX é derivado dos arquivos, e achado que só existia no INDEX já foi apagado num rebuild (aconteceu com vários slugs de uma vez). No INDEX o conteúdo extraído é **espelho**; o original mora em `legacy/` — e é do `TRIAGE` que o `/keelson:rebuild-index` reespelha as seções legadas ao reconstruir.

**Princípio inviolável 3**: a extração automática é melhor esforço. Você reporta o que extraiu para revisão humana.

## Input

```
/keelson:migrate-legacy <slug> [--dry-run] [--keep-in-place]
```

- `<slug>`: slug a migrar
- `--dry-run`: imprime o que seria feito sem executar
- `--keep-in-place`: não mover arquivos para `legacy/` (default: mover)

## Etapa 0: pré-checks

1. Validar que `{docsRoot}/<slug>/` existe. Se não, parar.
2. Validar que `{docsRoot}/<slug>/INDEX.md` **não** existe. Se existe, parar e sugerir `/keelson:rebuild-index <slug>` (slug não é legado, só precisa rebuild).
3. Listar arquivos `.md` na raiz de `{docsRoot}/<slug>/`. Se vazio, parar (nada a migrar).
4. Detectar se existem pastas SDD parciais (`specs/`, `plans/`, `tasks/`). Se sim, reportar e perguntar como tratar antes de prosseguir.
5. Detectar se é repositório git (para usar `git mv` em vez de `mv`).
6. **Confirmação calibrada**: quando invocado **standalone** por um humano, pedir confirmação antes de prosseguir (a menos que `--dry-run`). Quando invocado **dentro do fluxo autônomo** (`/keelson:auto`/`/keelson:guided` — a migração é pré-requisito obrigatório antes da SPEC), prosseguir **sem pausa de rotina** e reportar o que foi feito: a operação é 100% reversível via git (`git mv`, nada é deletado).

## Etapa 1: leitura e extração

Ler todos os `.md` na raiz da pasta do slug (README.md tem prioridade) e **extrair, melhor esforço**:

- **Resumo**: seção de visão geral/descrição do README; na falta, seus primeiros 2–3 parágrafos não-vazios.
- **Capacidades de alto nível**: listas de funcionalidades, headers que descrevem capacidades, endpoints de API — frases curtas de "o que o slug faz".
- **Glossário**: tabelas termo/definição, seções de conceitos, listas `**X**: definição`.
- **Decisões arquiteturais**: seções de decisões/ADR/arquitetura, trechos "decidimos/optamos", arquivos `ADR-*.md`, `DECISIONS.md`, `ARCHITECTURE.md`.
- **Stack mencionado**: tecnologias citadas — **validar contra a ficha e o `CLAUDE.md`** e reportar divergências sem corrigir.

Cada item extraído referencia o arquivo de origem, para revisão.

## Etapa 2: organizar arquivos legados

Se **não** for `--keep-in-place`:

1. Criar `{docsRoot}/<slug>/legacy/`.
2. Mover **todos** os `.md` da raiz de `{docsRoot}/<slug>/` para `legacy/`, preservando nomes.
3. Usar `git mv` se for repositório git (preserva histórico).
4. **Não mexer** em subpastas existentes que não sejam SDD (ex: `assets/`, `images/`).
5. **Se já existirem** `specs/`, `plans/`, `tasks/`: deixar como estão (caso especial, alertar usuário).

Se `--keep-in-place`: deixar arquivos onde estão, apenas referenciar no INDEX.

## Etapa 3: criar estrutura SDD

Criar (se não existirem):

```
{docsRoot}/<slug>/
├── specs/          (vazia)
├── plans/          (vazia)
└── tasks/          (vazia)
```

## Etapa 3.5: gravar os achados em `legacy/` (antes do INDEX)

Escrever `{docsRoot}/<slug>/legacy/TRIAGE-<YYYY-MM-DD>.md` com **tudo** que a Etapa 1 extraiu (e o que a triagem apurar depois): resumo, capacidades, glossário, decisões, riscos, backlog — cada item citando o arquivo de origem. Abrir com a nota de por que o arquivo existe (o INDEX é derivado; é deste TRIAGE que o `/keelson:rebuild-index` reespelha as seções legadas). Com `--keep-in-place`, criar `legacy/` só para este arquivo.

## Etapa 4: gerar INDEX.md

Criar `{docsRoot}/<slug>/INDEX.md` seguindo o **template canônico** (method-guide §6 — `${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`) com a variação de migração descrita lá: `**Origem**: migrado de legado em <YYYY-MM-DD>`, capacidades legadas 📜 em "Implementadas (legado, sem rastreabilidade SDD)", decisões `LEGACY-DEC-*`, "SPECs"/"PLANs" vazios com nota (mudanças futuras geram SPECs via `/keelson:triage`), e a seção `## Documentação legada` listando os arquivos preservados. As seções extraídas (Resumo, Capacidades, Glossário, Decisões, Riscos) são **espelho** do TRIAGE e abrem com `> Fonte durável: legacy/TRIAGE-<data>.md`; o que não foi identificado leva nota "não identificado, revisar manualmente".

## Etapa 5: reportar ao usuário

```markdown
# Migração concluída: <slug>

## Arquivos movidos para legacy/
- README.md → legacy/README.md
- <outros>

(Se --keep-in-place: "Arquivos mantidos na raiz, referenciados no INDEX.")

## Estrutura SDD criada
- {docsRoot}/<slug>/specs/ (vazia, pronta para /keelson:specify)
- {docsRoot}/<slug>/plans/ (vazia)
- {docsRoot}/<slug>/tasks/ (vazia)

## Achados gravados em legacy/TRIAGE-<data>.md (espelhados no INDEX)
- Capacidades implementadas (inferidas): N
- Glossário consolidado: N termos
- Decisões irreversíveis extraídas: N
- Resumo: <preview de 1 linha>

## Revisão recomendada

A extração automática nem sempre fica perfeita. **Revise o INDEX.md gerado**:

- Resumo está adequado? Reflete o que o slug realmente faz?
- Capacidades listadas correspondem à realidade?
- Algum termo do glossário está mal extraído ou faltando?
- Alguma decisão irreversível ficou de fora?

Corrija no `legacy/TRIAGE-<data>.md` (fonte durável) e reespelhe no INDEX — o INDEX sozinho não retém: num rebuild, o `/keelson:rebuild-index` reconstrói as seções legadas a partir do próprio TRIAGE (o que não estiver nele se perde).

## Próximos passos
1. Revisar o INDEX.md gerado.
2. Para mudança no slug: `/keelson:triage "descrição"`. Vai criar nova SPEC.
3. A skill `status` agora funciona neste slug.
```

## Comportamento em caso de falha

- **Falha ao mover arquivos ou ao criar o INDEX**: rollback (mover de volta os já movidos, remover o INDEX criado), reportar. Os pré-checks da Etapa 0 já cobrem pasta inexistente / INDEX já existente.
- **Pastas SDD parciais** (`specs/`, `plans/`, `tasks/`): alertar e perguntar — prosseguir ignorando, ou abortar (híbrido inesperado).
- **Conflito stack legado vs ficha/perfil**: warning, não bloqueia — migração registra o que encontrou, não corrige.

## Limites

Além dos princípios invioláveis (sem artefatos retroativos, preservação total): não interpreta código-fonte (só documentação), não conecta capacidades a FRs (impossível sem SPEC original), não decide o que "vale registrar" (lista tudo encontrado), não atualiza ficha/`CLAUDE.md` a partir do legado (decisão humana).
