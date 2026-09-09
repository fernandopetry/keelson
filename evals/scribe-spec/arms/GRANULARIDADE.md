## Etapa 2: princípios obrigatórios (contrato de forma — executado pelo `scribe`)

1. **Outcome-first**: comece pelo resultado esperado.
2. **Ubiquitous Language**: defina termos no glossário, reutilize do glossário consolidado do INDEX.md (canônico — Etapa 0.4). **Termo herdado de fonte legada tem proveniência (decisão 4.240)**: quando a demanda se baseia em artefato legado (código, queries, telas), termo de domínio voltado ao usuário entra no glossário com a âncora da fonte que o usa (`arquivo:linha` ou identificador da consulta); termo que a fonte não decide — sinônimos concorrentes, leitura parcial — é escolha de produto: vira premissa da §8 (`[confirmar]` ou `[assumido]` com default declarado), nunca escolha silenciosa. Teste: "quem escolheu esta palavra?" responde-se com uma âncora ou uma premissa — "ninguém" é o defeito. A mesma proveniência vale para afirmação sobre **forma/contrato de payload de sistema externo** (decisão 4.285): entra como fato só com âncora de **amostra capturada** (resposta salva, dump de integração, captura de gate 9) — sem amostra, nasce premissa da §8 (`[assumido] [evidência: crença]`), nunca fato afirmado.
3. **EARS para FRs**:
   - Ubiquitous: `O <sistema> deve <resposta>.`
   - Event-driven: `Quando <gatilho>, o <sistema> deve <resposta>.`
   - State-driven: `Enquanto <estado>, o <sistema> deve <resposta>.`
   - Optional: `Onde <feature presente>, o <sistema> deve <resposta>.`
   - Unwanted: `Se <gatilho indesejado>, então o <sistema> deve <resposta>.`
4. **RFC 2119**: MUST, SHOULD, MAY em maiúsculas.
5. **IDs escopados ao SPEC**: `FR-NNN-001`, `NFR-NNN-001`, `AC-NNN-001`, `RISK-NNN-001`, `FEAT-NNN-001`.
6. **Funcionalidades (FEAT)** — só quando há 2+ fluxos entregáveis: regra completa no comentário da §5 do template canônico (Etapa 3).
7. **Suposições explícitas**: `[confirmar]` ou `[assumido]` — e cada premissa da §8 carrega o **selo de evidência** `[evidência: crença | anedota | entrevistas | medido]` (escala e regra: convenção comum, sdd-conventions.md — decisão 4.96). O selo declara o que sustenta a aposta; nunca bloqueia. **Orçamento de pendência (decisão 4.144)**: no máximo **3** `[confirmar]` por SPEC — candidatos além do teto se resolvem por prioridade (**escopo > segurança/privacidade > experiência do usuário > detalhe técnico**) e os cortados viram `[assumido]` com o default escolhido declarado na própria premissa (o palpite + por que é razoável). Pendência de verdade é a que muda o resultado; preferência com default razoável de indústria não gasta o orçamento.
8. **Escopo e não-escopo simétricos — com teste** (decisão 4.158): cada item do In-scope
   tem o vizinho que um leitor assumiria incluído **nomeado** no Out-of-scope (cadastro
   entra → "e a recuperação de senha?" tem resposta escrita, dentro ou fora).
   Out-of-scope vazio ou genérico ("não inclui refatorações") com In-scope não-trivial é
   o sinal do princípio violado. A simetria é o que torna julgável o `não solicitado` do
   gate 4 (4.143): sem fronteira declarada, excesso de escopo vira opinião.
9. **Três estados da ação de UI** (decisão 4.67): FR de ação iniciada pelo usuário na
   interface DEVE especificar o comportamento **observável** dos três estados — *em
   andamento* (ação disparada, resultado pendente: botão desabilita? indicador aparece?),
   *sucesso* e *falha*. Efeito invisível (e-mail enviado, registro gravado, job
   disparado) **não é feedback** — feedback é o que a tela mostra ao usuário. FR de ação
   sem os três estados está incompleta; cada estado vira AC verificável (e os gates 1 e 9
   herdam a prova de graça).
10. **Par de leitura do que se persiste** (decisão 4.225): FR que introduz campo ou
    estado persistível novo **sem par de leitura está incompleto** — algum FR ou AC da
    mesma SPEC nomeia onde o valor salvo **reaparece** (recarga da tela, payload de
    consulta, exibição). AC de leitura no próprio FR satisfaz; não é preciso FR novo.

11. **Granularidade do FR — um comportamento observável, nunca um passo**: o FR nomeia o
    que o usuário ou o sistema externo **observa como resultado**; validações, ramos de
    erro, estados intermediários e gravações de UM mesmo comportamento são **ACs desse
    FR** (Dado/Quando/Então), nunca FRs irmãos. Teste: dois FRs que só fazem sentido
    entregues juntos são um FR com dois ACs. Fundir passo é a regra; cortar comportamento
    que o brief exige continua defeito — a cobertura não muda, muda a unidade.

## Etapa 3: estrutura obrigatória do arquivo SPEC (contrato de forma — executado pelo `scribe`)

Template canônico: `${CLAUDE_PLUGIN_ROOT}/templates/artifacts/SPEC.md` — o scribe o lê na
fonte e reproduz a estrutura (headings, campos e ordem) à risca; os comentários `<!-- -->`
do template são régua de preenchimento, nunca conteúdo do artefato (decisão 4.405).


---
<!-- anexo da régua: templates/artifacts/SPEC.md -->
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

## 8. Premissas e decisões prévias
- **A-NNN-001** [assumido] [evidência: crença] ...

## 9. Riscos e questões abertas
- **RISK-NNN-001** ...
- **Q-NNN-001** ...

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
