<!-- Template canônico do SPEC (decisão 4.405). Dono da régua de forma: commands/specify.md, Etapa 2. Comentários <!-- --> são instrução ao scribe, nunca conteúdo do artefato gerado. -->

# SPEC-NNN: <Nome>

**Slug**: <slug>
**Status**: Draft | Review | Approved
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>
**Jira**: <KEY — só quando a integração Jira está ativa; no modo `link`, preencha com a issue existente; omita a linha se `jira.enabled` for false>
**Jira Story**: <KEY da Story implícita — só quando a SPEC não declara FEATs e `issueType.feature` está preenchido (degrau (0) do §7.0 do protocolo de sync); omita a linha nos demais casos>
**Brief**: <BRIEF-NNN — quando a SPEC nasce de um brief (contrato Diretor–PO, decisão 4.38); omita a linha sem brief>

## 1. Contexto e objetivo
### 1.1 Problema
### 1.2 Outcome esperado
### 1.3 Métrica de sucesso
<!-- Número + prazo + a linha de fonte (decisão 4.99) — sem fonte, a métrica é
estimativa eterna e o veredito do ciclo seguinte não tem de onde sair: -->
**Fonte de medição**: <instrumentação — evento/consulta que o sistema emitirá | externa — ferramenta + dono do número>

## 2. Personas e jobs-to-be-done
<!-- Anti-persona (opcional, 1 linha — decisão 4.98): "para quem isto NÃO é", quando
disciplinar o escopo. Capacidade que "serve todo mundo" é sinal de persona genérica. -->

## 3. Glossário (Ubiquitous Language)

## 4. Escopo
### 4.1 In-scope
### 4.2 Out-of-scope

## 5. Requisitos funcionais (EARS)
<!-- Com 1 único fluxo entregável, mantenha a lista plana — NÃO declare a camada FEAT
(a funcionalidade é a própria SPEC): -->
- **FR-NNN-001** [MUST] ...
<!-- Com 2+ fluxos entregáveis (fluxos que o QA testa de ponta a ponta de forma independente,
ex.: "login no portal" e "lançamento de horas"), agrupe TODOS os FRs sob headings FEAT —
cada FR pertence a exatamente UMA FEAT (partição total); os ACs NÃO redeclaram filiação:
derivam da FEAT do FR que cobrem. Forma:
### FEAT-NNN-001: <Nome do fluxo entregável>
> <1–2 linhas: o fluxo do ponto de vista do QA — o que se testa de ponta a ponta>

**Jira**: <KEY da Story — só com projeção 3 níveis ativa; omita a linha se não sincronizada>

- **FR-NNN-001** [MUST] ...
-->

## 6. Requisitos não-funcionais
- **NFR-NNN-001** [MUST] ...

## 7. Critérios de aceitação (Given-When-Then)
- **AC-NNN-001** (cobre FR-NNN-001, FR-NNN-002)
<!-- Corpo do AC em português, com as três palavras-chave — ex.: "Dado um operador sem a
permissão de exportar, quando ele aciona a exportação, então o sistema recusa e informa o
motivo." O check `spec-ac-fora-gwt` (`scripts/artifact-lint.sh`, WARNING — régua:
${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/lint-contract.md §1) exige "dado"/"quando"/
"então" no corpo: Given/When/Then em inglês reprova mesmo com a estrutura certa — o título
da seção nomeia o padrão, não o vocabulário (decisão 4.340).
O "(cobre …)" é campo de aresta do grafo: IDs completos de FR/NFR separados por
vírgula — sem barra-abreviação (FR-x/y) nem sub-item (FR-x-001a). Com FEATs declaradas
na §5, os FRs de um mesmo "(cobre …)" pertencem à MESMA FEAT — a filiação do AC deriva
dela; AC atravessando FEATs é cenário mal fatiado: divida o AC. Régua:
${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/graph-contract.md §1. -->

- **A-NNN-001** [assumido] [evidência: crença] ...

## 9. Riscos e questões abertas
- **RISK-NNN-001** ...
- **Q-NNN-001** ...

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
