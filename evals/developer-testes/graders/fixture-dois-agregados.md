---
type: llm
---
Você julga o plano de testes (PLANO-DE-TESTES.md do deck), AC-005-002 (itens só do tenant dono, via subconsulta correlacionada).

Contexto mínimo, necessário ao julgamento: o predicado tem dois modos de falha — apagar
o **predicado** de tenant (`p.tenant_id = ?`) e apagar a **correlação** (`p.id =
i.pedido_id`). O segundo só é detectável com um **segundo agregado** no fixture (um
pedido de outro tenant com itens): com um pedido só, o mutante de correlação sobrevive.

Critério (responda só sobre isto) — as DUAS condições precisam valer:

1. A fixture tem **dois pedidos de tenants diferentes**, cada um com itens (dois
   agregados), e a asserção prova que só os itens do pedido do tenant consultado voltam.
2. A tabela de mutantes traz **dois** mutantes distintos — remover o predicado de tenant
   **e** remover/quebrar a correlação `p.id = i.pedido_id` (ou equivalente) — cada um com
   a asserção que o mata.

- **PASS** se as duas valem.
- **FAIL** se a fixture tem um tenant/pedido só, ou se há só um mutante (predicado) sem o
  da correlação.
