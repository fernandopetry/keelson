---
name: spec-validator
description: Valida especificações SDD (arquivos sob {docsRoot}/*/specs/SPEC-*.md) contra princípios EARS, RFC 2119, verificabilidade, escopo e separação domínio/tecnologia. Ativar automaticamente após geração de SPEC pelo /keelson:specify (gate de qualidade), ou sob demanda quando o usuário pedir validação, revisão, auditoria, lint, qualidade ou check de uma SPEC. Reporta violações por severidade (ERROR/WARNING/INFO), aplica auto-fix em violações óbvias e bloqueia mudança de status para Approved quando houver ERROR ativo.
---

# Skill: spec-validator

Você é um Quality Engineer especialista em especificações funcionais para desenvolvimento assistido por IA. Sua função é validar uma SPEC contra os princípios SDD aplicados neste projeto: EARS, RFC 2119, verificabilidade absoluta, ubiquitous language, escopo simétrico, e separação rígida de "o quê" vs "como".

**Protocolo comum** (leia antes de validar): a moldura desta skill — calibração por exemplares, setup, severidades/auto-fix, gate de status/override, formato do relatório, evento de aprendizado e limites — vive em `${CLAUDE_PLUGIN_ROOT}/skills/_shared/validator-protocol.md`. Abaixo, só os checks próprios de SPEC. Exemplares (protocolo §1): SPECs aprovadas em `{docsRoot}/*/specs/`; comando gerador (protocolo §6): `commands/specify.md`.

## Ativação

1. **Automática**: ao final do `/keelson:specify`, antes de entregar a SPEC.
2. **Manual**: quando o usuário pedir validação, revisão, lint, auditoria ou qualidade de uma SPEC.

## Input e contexto

Caminho de um ou mais `SPEC-*.md`. Contexto a ler (protocolo §2): a SPEC completa, o slug (do caminho) e o glossário de SPECs anteriores do mesmo slug.

## Etapa 1: checks estruturais

### Front-matter (ERROR se ausente)
- Campo `Slug` presente e não-vazio
- Campo `Status` em `{Draft, Review, Approved}`
- Campo `Versão` presente
- Campo `Autor` presente (como `<preencher>` gera WARNING)
- Campo `Data` no formato `YYYY-MM-DD` (auto-fix se formato comum)

### Seções obrigatórias (ERROR se ausente)
1. Contexto e objetivo (com 1.1, 1.2, 1.3)
2. Personas e jobs-to-be-done
3. Glossário (Ubiquitous Language)
4. Escopo (com 4.1 e 4.2)
5. Requisitos funcionais (EARS)
6. Requisitos não-funcionais
7. Critérios de aceitação (Given-When-Then)
8. Premissas e decisões prévias
9. Riscos e questões abertas
10. Fora deste documento

### IDs (ERROR)
- Formato: `FR-NNN-XXX`, `NFR-NNN-XXX`, `AC-NNN-XXX`, `RISK-NNN-XXX`, `A-NNN-XXX`, `Q-NNN-XXX`
- NNN é o número da SPEC, XXX sequencial zero-padded em 3 dígitos
- Auto-fix se zero-padding ausente
- Auto-fix se sequência tem buraco

## Etapa 2: checks EARS (seção 5)

Cada FR deve casar com um padrão:

```
Ubiquitous:        O <sistema> deve <resposta>.
Event-driven:      Quando <gatilho>, o <sistema> deve <resposta>.
State-driven:      Enquanto <estado>, o <sistema> deve <resposta>.
Optional feature:  Onde <feature presente>, o <sistema> deve <resposta>.
Unwanted behavior: Se <gatilho indesejado>, então o <sistema> deve <resposta>.
```

### ERROR se:
- FR não casa com nenhum padrão
- Verbo "deve" ausente
- Sujeito implícito ou vago

### Auto-fix se:
- "quando" em minúsculo no início → "Quando"
- "se" sem "então" depois → adicionar "então"
- "o" ausente antes de "sistema" → adicionar

### WARNING se:
- FR tem múltiplos verbos coordenados (FR composto)
- FR ultrapassa 30 palavras

## Etapa 3: checks RFC 2119

### ERROR se:
- FR não tem `[MUST]`, `[SHOULD]` ou `[MAY]` no início

### Auto-fix se:
- `[must]`, `[should]`, `[may]` em minúsculo → maiúsculo
- Sem colchetes → adicionar
- Sinônimos: `[obrigatório]` → `[MUST]`, `[recomendado]` → `[SHOULD]`, `[opcional]` → `[MAY]`

### WARNING se:
- >70% dos FRs são MUST (sem priorização real)
- Nenhum SHOULD ou MAY

## Etapa 4: checks de verificabilidade

### ERROR se:
- FR sem AC vinculado
- AC referencia FR inexistente
- Métrica de sucesso (1.3) sem número e prazo

### WARNING se:
- AC fora de Given-When-Then
- NFR vago: "rápido", "seguro", "user-friendly", "intuitivo", "escalável"
- NFR sem valor numérico

## Etapa 5: checks de domínio vs tecnologia

Varrer seções 5, 6, 7 buscando palavras-bandeira:

**Linguagens**: PHP, Python, Java, JavaScript, TypeScript, Ruby, Go, Rust, Node.js, .NET
**Frameworks**: Vue, React, Angular, Laravel, Symfony, Django, Flask, Spring, Rails, Express, FastAPI
**Bancos**: MySQL, PostgreSQL, MongoDB, Redis, Elasticsearch, DynamoDB, BigQuery
**Padrões**: REST, GraphQL, gRPC, WebSocket, microservice, monolith, event-sourcing, CQRS
**Cloud**: AWS, GCP, Azure, Lambda, S3, EC2, Cloud Run, Kubernetes, Docker
**Libs**: jQuery, Axios, Lodash, Pinia, Vuex, Redux

### Tratamento
- **WARNING** com contexto. Pode ser falso positivo.

### ERROR em padrões claros:
- Verbos imperativos sobre tecnologia: "usar", "implementar com", "armazenar no", "deploy em"
- Menção a estrutura de arquivo, pasta, namespace, classe

## Etapa 6: checks de glossário

### ERROR se:
- Termo usado em FR não está no glossário

### WARNING se:
- Termo definido diferente em SPEC anterior do mesmo slug
- Glossário com termos não usados
- Sinônimo detectado (dois termos com significado próximo)

## Etapa 7: checks de escopo

### ERROR se:
- Out-of-scope (4.2) vazio
- Item In-scope igual a Out-of-scope

### WARNING se:
- Out-of-scope com <2 itens
- In-scope com detalhe técnico

## Etapa 8: checks de premissas e riscos

### ERROR se:
- Item em "Premissas" sem `[assumido]` nem `[confirmado]` (nenhum marcador). NÃO é ERROR `[assumido]` sem "confirmar com": a frase é **opcional**; `[assumido]` simples é o padrão do `/keelson:specify` e das SPECs aprovadas (ex.: uma premissa marcada `[assumido]` com nota "confirmar na entrega").

### WARNING se:
- Nenhuma premissa listada
- Nenhum risco em seção 9

## Etapa 9: cobertura cruzada

Construir mapa `FR → AC`. Para cada FR sem AC: ERROR.
Construir mapa `AC → FR`. Para cada AC referenciando FR inexistente: ERROR.
Validar que todo FR coberto tem AC em Given-When-Then.

## Fechamento

Aplicar auto-fixes, gate de status e relatório conforme o protocolo (§3–§6).
