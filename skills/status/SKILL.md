---
name: status
description: Resumo executivo do estado atual de um slug. Ativar quando perguntarem sobre estado, status, situação, progresso, o que está implementado ou em desenvolvimento, ou pedirem overview de um slug ou capacidade do sistema.
---

# Skill: status

Produza um **resumo executivo** do estado de um slug, respondendo à pergunta específica do usuário.

**Princípio inviolável**: você **não modifica nenhum arquivo**. Apenas lê e sintetiza.

## Input

- `/keelson:status <slug>` → visão geral
- `/keelson:status <slug> --focus=risks` → apenas riscos ativos
- `/keelson:status <slug> --focus=glossary` → apenas glossário
- `/keelson:status <slug> --focus=in-progress` → apenas em desenvolvimento
- `/keelson:status <slug> --focus=decisions` → apenas decisões irreversíveis

## Etapa 0: identificar slug

1. Se input explícito, usar.
2. Se pergunta menciona termo de domínio, cruzar com termos do glossário em INDEX.md.
3. Se inconcluso, listar slugs e perguntar.

## Etapa 1: leitura

1. **Ler `{docsRoot}/<slug>/INDEX.md`** como fonte primária.
2. Se INDEX inconsistente ou ausente, sugerir `/keelson:rebuild-index` mas ainda tentar responder lendo arquivos individuais.
3. **Leitura sob demanda** baseada no foco:
   - Geral: usar INDEX direto.
   - In-progress: ler PLANs em andamento e seus TASK-MMM-INDEX.
   - Risks: INDEX seção "Riscos ativos" + SPECs ativas para Q-XXX e RISK-XXX.
   - Glossary: INDEX seção glossário.
   - Decisions: INDEX + PLANs Done para DECs irreversíveis.
4. **Pergunta sobre dependências, ordem ou paralelismo** (waves, "o que bloqueia o
   quê", arquitetura FR→COMP): gere o diagrama e inclua-o na resposta —
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh" {docsRoot}/<slug> --format=mermaid`
   (TASKs por wave, com status) ou `--format=mermaid-comp` (FR → COMP + dependências).
   O script é read-only (compatível com o princípio inviolável); régua e contrato:
   `docs/_meta/conventions/graph-contract.md`. Indisponível/falhou → siga pelo INDEX,
   nomeando a causa.
5. **Fato mecânico antes da síntese** (decisão 4.237): rode já o `index-check.sh` da
   Etapa 3 — a síntese nasce sabendo o que do INDEX envelheceu, em vez de descobrir
   depois de escrita.

## Etapa 2: síntese

Componha você mesmo o resumo executivo em markdown, calibrado ao foco — sem template rígido. Pendência ou risco **reapresentado** segue a régua "lista reapresentada é lista medida" (dono: `docs/_meta/conventions/sdd-conventions.md`, decisão 4.237): item cuja fonte não foi conferida nesta rodada (INDEX estale acusado pelo `index-check.sh`, handoff não relido) sai marcado **`não medido`**, nunca como corrente. O que cada foco cobre:

- **Visão geral**: resumo de 2–3 linhas do que a área faz hoje; capacidades por estágio (✅ implementadas · 🟡 em desenvolvimento, com PLAN-MMM e X/Y tasks Done · ⏸ especificadas, aguardando plan); próximo movimento sugerido; riscos ativos que merecem atenção (máx. 3); saúde do slug (contagens de SPECs/PLANs por status, decisões irreversíveis, termos do glossário, última atividade).
- **`--focus=risks`**: riscos abertos do INDEX com mitigação + `Q-*` agregados das SPECs Approved + `TRISK-*` dos PLANs em desenvolvimento.
- **`--focus=glossary`**: tabela do INDEX + inconsistências entre SPECs (termo definido de forma divergente, citando as SPECs).
- **`--focus=in-progress`**: por PLAN em andamento — capacidade, tasks abertas, bloqueios, próximas tasks da wave atual.
- **`--focus=decisions`**: decisões irreversíveis expandidas (contexto, decisão, alternativas descartadas) + "considere antes de mexer" (o que cada decisão impede).

## Etapa 3: detecção de inconsistências (fato mecânico)

O comando é `bash "${CLAUDE_PLUGIN_ROOT}/scripts/index-check.sh" {docsRoot}/<slug>` —
já executado na Etapa 1 (item 5); aqui trata-se o resultado. Tabelas × arquivos, célula
Tasks × TASKs reais, capacidade adiantada, seções e teto do histórico chegam como fato
(catálogo: index-contract.md). Read-only; indisponível → confira por leitura e nomeie a
causa.

Se inconsistência:
- Não bloquear resposta.
- Adicionar nota ao final:
  ```
  ⚠ Inconsistência detectada entre INDEX e arquivos. Considere rodar /keelson:rebuild-index.
  Detalhes: <listar>.
  ```

## Limites

Não sugere mudanças de código, não julga mérito técnico e não substitui o `/keelson:triage` para roteamento de demandas.
