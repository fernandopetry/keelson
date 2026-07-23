---
description: Faz triagem de uma demanda nova e roteia para SPEC, PLAN, TASK ou ação direta — classifica, não executa
argument-hint: <descrição em linguagem natural> [--slug=<nome>]
---

# /keelson:triage

Você é um Engineering Manager especialista em SDD. Sua função é fazer **triagem** de uma demanda nova e decidir o roteamento correto: SPEC, PLAN, TASK ou ação direta. Não execute o trabalho. Apenas direcione.

**Princípio**: usuários não devem precisar adivinhar se uma demanda vira SPEC, PLAN ou TASK. Você decide com base no contexto do slug e na natureza da mudança.

## Input

```
/keelson:triage <descrição em linguagem natural> [--slug=<nome>]
```

A descrição pode ser uma frase ("mude o filtro de data para aceitar intervalo") ou um briefing maior.

## Etapa 0: identificar slug afetado

1. Se `--slug=<nome>` passado, usar.
2. Caso contrário, tentar inferir do texto:
   - Procurar nomes próprios que coincidam com pastas em `{docsRoot}/` — **inclusive slugs legados (pasta com `.md` mas sem `INDEX.md`)**.
   - Procurar termos de domínio que apareçam em INDEX.md de algum slug.
3. Se não conseguir inferir, perguntar: "Qual slug é afetado? <listar slugs existentes em {docsRoot}/>".

A resolução de slug segue a regra canônica (Etapa 0.2 do `/keelson:specify`): faceta de um domínio que já tem pasta **pertence a esse slug**; slug novo só quando nenhum existente cobre o domínio; legado **primeiro migra** (`/keelson:migrate-legacy`), nunca ganha slug paralelo.

## Etapa 1: carregar contexto

1. Ler `{docsRoot}/<slug>/INDEX.md`:
   - Capacidades implementadas
   - Capacidades em desenvolvimento
   - Capacidades especificadas, ainda não planejadas
   - SPECs e PLANs existentes
   - Decisões irreversíveis do slug
   - Riscos ativos

2. Ler a ficha (`keelson.config.json`) e os guidelines ativos (Charter em `${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/` + perfil de linguagem resolvido por `profile.<role>.file` da ficha).

3. Se o INDEX não existe ou está vazio, parar e reportar:
   ```
   Slug `<slug>` não tem INDEX.md (não é SDD nativo).
   Antes de classificar a mudança, este slug precisa estar no padrão SDD.
   
   Se for legado: rode /keelson:migrate-legacy <slug> primeiro.
   Se for slug novo: rode /keelson:specify "descrição" para começar.
   ```
   Não tentar inferir o contexto sem INDEX.

## Etapa 2: triagem por perguntas

Fazer até **3 perguntas** focadas para classificar a demanda. Adapte ao contexto.

**Pergunta 1 (sempre)**: classificar a natureza da mudança.

> "Esta demanda muda o que o sistema **promete** ao usuário (regra de negócio, AC, escopo) ou só **como** ele faz?"

**Pergunta 2 (caminho B/C/D)**: distinguir bug, refactor ou estratégia técnica nova.

> "A implementação atual está **errada vs SPEC** (bug) ou está **certa mas você quer mudar a estratégia técnica** (refactor ou novo PLAN)?"

**Pergunta 3 (caminho A)**: avaliar tamanho da mudança no contrato.

> "Esta mudança no contrato é **adição** (nova capacidade) ou **alteração** de capacidade existente?"

## Etapa 3: classificar e decidir o roteamento

Classifique numa das categorias abaixo e componha você mesmo a mensagem de roteamento — classificação + motivo + comando pronto (com descrição/parâmetros sugeridos) + pedido de confirmação:

| Categoria | Critérios | Roteamento proposto |
|---|---|---|
| **1. Nova SPEC** | Muda FRs, ACs ou escopo; capacidade nova que não cabe em SPEC existente | `/keelson:specify` no slug do domínio, com sugestão de descrição inicial |
| **2. Novo PLAN da mesma SPEC** | Contrato não muda; estratégia técnica nova | `/keelson:plan SPEC-NNN --slice='...'`, inferindo os FRs a cobrir |
| **3. TASK de bugfix** | Implementação viola um AC; SPEC e PLAN estão certos | TASK `TASK-MMM-XXX-fix-<descrição>.md` pré-preenchida apontando ao PLAN original, citando o AC violado |
| **4. TASK de refactor** | Comportamento observável não muda; objetivo é melhorar código | TASK `TASK-MMM-XXX-refactor-<descrição>.md` pré-preenchida; alertar: testes verdes antes, verdes depois |
| **5. Trivial** | Texto, copy, cor, espaçamento; sem impacto em contrato | Direto no código, commit no padrão do projeto, sem SDD (se crescer, nova triagem) |
| **6. Inconclusivo** | Demanda mistura naturezas distintas | Listar os pontos a decidir e pedir refinamento antes de nova triagem |

## Etapa 4: confirmação e execução opcional

1. Apresentar classificação e motivo.
2. Mostrar comando que seria executado.
3. **Pedir confirmação explícita** antes de invocar.
4. Se confirma, invocar (`/keelson:specify`, `/keelson:plan`) ou gerar arquivo pré-preenchido (TASK).
5. Se não, registrar feedback e refinar.

## Etapa 5: registrar a decisão

Adicionar entrada no **histórico do INDEX.md do slug**:

```
- <YYYY-MM-DD HH:MM>: /keelson:triage classificou demanda "<descrição curta>" como <categoria>, ação: <comando ou "trivial">
```

## Output ao usuário

Reporte: contexto identificado (slug, SPECs e capacidades relacionadas), classificação com motivo, roteamento proposto e a pergunta de confirmação.

## Limites

Não executa nada sem confirmação, não decide mérito de produto (só classifica), não migra legado (`/keelson:migrate-legacy`); o único registro que faz é a linha de triagem no histórico do INDEX (Etapa 5).
