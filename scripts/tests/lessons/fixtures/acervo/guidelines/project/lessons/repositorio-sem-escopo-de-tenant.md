---
area: Backend
estado: ativa
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - src/Domain/**
  - src/Infra/Repository/*.php
tags: [seguranca, persistencia]
---
## [Backend] Repositório sem escopo de tenant

**Erro:** consulta devolveu registro de outro tenant.
**Causa:** método novo no repositório sem o predicado de escopo.
**Solução:** todo método que toca a tabela escopada carrega o predicado (ver `src/Infra/Repository/BaseRepository.php`).
