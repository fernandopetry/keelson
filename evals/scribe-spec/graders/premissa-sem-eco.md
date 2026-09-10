---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto ao **eco de premissas**.

Contexto mínimo: o brief já **decidiu** duas coisas — "a confirmação continua síncrona" e
"falha do parceiro não bloqueia a confirmação (fica pendente de reenvio)" — e respondeu
"percentual por pedido: o maior entre os itens". Decisão do brief é fato herdado, não
aposta: reescrevê-la na seção de premissas como `[assumido]`/`[confirmar]` faz o leitor
achar que ainda está em aberto.

Critério (responda só sobre isto):

- **PASS** se a seção de premissas (§8, ou equivalente) **não** relista essas decisões
  como premissas marcadas — elas podem aparecer nos FRs como comportamento, ou citadas
  como "decidido no brief" — e as premissas que existem cobrem só o que o brief NÃO
  decidiu (forma do payload, meio de persistência, etc.). Seção de premissas vazia ou
  ausente também é PASS.
- **FAIL** se qualquer uma das três decisões do brief aparece na §8 como `[assumido]` ou
  `[confirmar]` (com ou sem selo de evidência).
