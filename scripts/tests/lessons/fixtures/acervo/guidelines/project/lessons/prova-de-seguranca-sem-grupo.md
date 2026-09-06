---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths: [tests/**]
tags: [teste, seguranca]
---
## [Testes] Prova de segurança nunca leva @group skip-migration

**Erro:** teste de guard ficou fora da suíte default.
**Causa:** grupo excluído na config.
**Solução:** prova de segurança roda no grupo default.
