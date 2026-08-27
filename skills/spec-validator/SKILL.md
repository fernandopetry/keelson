---
name: spec-validator
description: "Valida SPECs SDD (SPEC-*.md do projeto) contra EARS, RFC 2119, verificabilidade e escopo. Ativar após /keelson:specify (gate de qualidade) ou sob demanda quando pedirem validação, revisão, auditoria, lint, qualidade ou check de uma SPEC."
---

# Skill: spec-validator

Você é um Quality Engineer: valide a SPEC contra os checks abaixo.

**Protocolo comum** (leia antes de validar): a moldura desta skill — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, formato do relatório, evento de aprendizado e limites — vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md`. Abaixo, só os checks próprios de SPEC. Exemplares (protocolo §1): SPECs aprovadas em `{docsRoot}/*/specs/`; comando gerador (protocolo §6): `commands/specify.md`.

## Input e contexto

Caminho de um ou mais `SPEC-*.md`. Contexto a ler (protocolo §2): a SPEC completa, o slug (do caminho) e o glossário de SPECs anteriores do mesmo slug.

## Etapa 0: fato mecânico primeiro

A forma da SPEC tem **dono único e execução mecânica** — catálogo, severidades e régua
de rebaixamento em `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/lint-contract.md`.
Execute (num subagent executor sem a env var, derive a raiz do plugin do caminho deste
SKILL.md — o prefixo antes de `/skills/`):

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/artifact-lint.sh" <caminho-da-SPEC>
```

Chega como fato (`spec-*` do lint-contract §3): cabeçalho/enum de Status, seções e
subseções obrigatórias, IDs fora do número da SPEC e sem zero-padding, RFC 2119
ausente/fora de forma, "deve" ausente, FR fora dos padrões EARS, FR >30 palavras,
razão de MUST e ausência de SHOULD/MAY, porte de épico (>30 FRs — 4.115), partição
FR↔FEAT e FEAT vazia/única/fora da §5/sem descrição, métrica sem número/sem fonte
(4.99), out-of-scope vazio/curto, in-scope idêntico ao out-of-scope, wordlist de
tecnologia, NFR vago/sem número, AC fora de Dado-Quando-Então, premissa sem
marcador/sem selo (4.96), teto de `[confirmar]` (4.144), glossário não usado.

O lado interno da verificabilidade também chega como fato, do **grafo**: `fr-sem-ac`
(FR sem AC que o cubra) e `ref-quebrada` (AC cobrindo FR inexistente) —
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/graph.sh" {docsRoot}/<slug> --check --stage=plan`
(achado sobre artefato que não é esta SPEC não entra no seu relatório).

Cada achado entra como `**[artifact-lint]**`/`**[graph.sh]** SEVERIDADE check —
detalhe`. **Degradação por resultado** e **cobertura mista**: réguas do §5 do
graph-contract.md — sem saída válida, aplique os mesmos checks por leitura e declare a
degradação; a calibração final é sua (protocolo §1/§3).

## Etapa 1: checks que permanecem seus (o script não computa)

### EARS e redação (seção 5)

- ERROR: sujeito implícito ou vago no FR ("o sistema" genérico quando a SPEC nomeia atores distintos).
- WARNING: FR com múltiplos verbos coordenados (FR composto).
- WARNING: FR com modal de **proibição/recusa** ("não deve permitir", "nunca ocorre", "não é X") cujos ACs pareados só provam **mitigação a jusante** (bloquear/avisar a ação seguinte) em vez da negação/recusa do próprio evento — o AC prova uma versão mais fraca do FR (`fr-sem-ac` confere que o AC existe; este check pergunta se ele **prova** o FR). Recusa em forma indireta satisfaz ("Então retorna 403", "Então o registro permanece inalterado", "Então nada é selecionado"); só aviso/bloqueio de etapa posterior, não. Reincidência da classe escala a ERROR (régua 4.52 — decisão 4.198).
- WARNING: FR que **persiste** campo/estado novo (salvar, gravar, registrar, atualizar valor) sem **par de leitura** na mesma SPEC — nenhum FR ou AC nomeia onde o valor salvo reaparece (recarga, payload de consulta, exibição). Pressupõe AC existente: FR sem AC nenhum já é `fr-sem-ac` do grafo, e este check não re-acusa; ele pergunta se algum AC prova a **volta** do dado (decisão 4.225 — mesma família da 4.198: "o AC existe" ≠ "o AC prova").
- Escalar `spec-ears-nao-casa`/`spec-tecnologia` (fatos WARNING) para ERROR quando o padrão é claro: verbo imperativo sobre tecnologia ("usar", "implementar com", "armazenar no", "deploy em") ou menção a estrutura de arquivo, pasta, namespace, classe.

### Auto-fix (protocolo §3)

- "quando" minúsculo no início → "Quando" · "se" sem "então" → adicionar · "o" ausente antes de "sistema" → adicionar
- `[must]`/`[should]`/`[may]` → maiúsculo · sem colchetes → adicionar · `[obrigatório]` → `[MUST]`, `[recomendado]` → `[SHOULD]`, `[opcional]` → `[MAY]`
- Zero-padding ausente em ID → completar · formato comum de `Data` → normalizar

### Verificabilidade e métrica

- ERROR: métrica de sucesso (1.3) com número mas **sem prazo** (o fato `spec-metrica-sem-numero` cobre só o número).
- As linhas `**Fonte de medição**:` e `**Veredito de métrica**:` (4.99) são conteúdo esperado da §1.3 — toleradas por todos os checks, nunca marcadas como tecnologia ou rastro estranho.

### Funcionalidades (FEAT)

- WARNING: nome de FEAT que não é um fluxo verificável (ex.: "melhorias gerais", "ajustes").
- As linhas `**Jira**:`, `**Jira Story**:` e `**Verificação (gate 9)**:` (4.90) são **toleradas e ignoradas**: rastro de execução/tracker, não conteúdo de especificação.

### Glossário e escopo

- ERROR: termo usado em FR não está no glossário.
- WARNING: termo definido diferente em SPEC anterior do mesmo slug · sinônimo detectado (dois termos com significado próximo) · in-scope com detalhe técnico.

### Premissas

- `[assumido]` simples é o padrão (a frase "confirmar com" é opcional) — não é ERROR.
- O selo de evidência (4.96) e o teto de `[confirmar]` (4.144) chegam como fato; o **mérito** (crença sustentando requisito central, corte de pendência) é da crítica de produto e do PO, nunca seu.

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6).
