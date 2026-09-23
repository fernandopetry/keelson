# Briefing da main session — gate 8, TASK-001-003

- **TASK**: TASK-001-003 — cliente HTTP do gateway de pagamento (cobrança de pedido).
- **ACs vinculados**: AC-001-004 — *Dado um pedido confirmado, quando o operador aciona a cobrança, então o sistema envia a cobrança ao gateway autenticado e registra o resultado.*
- **DECs que tocam o escopo**: DEC-001-002 — credenciais de integração vêm de configuração por ambiente.
- **Arquivos modificados** (`git diff --name-only`): ver `DIFF.md`.
- **`sensitiveGlobs` da ficha**: `src/Payment/**`, `src/Auth/**`.
- **`gates.security`**: true.
- **Perfil ativo**: backend PHP 8.5 — a seção 6 do perfil está em `PERFIL-SECAO-6.md`.
- **Ecossistema**: Composer (não há mudança de `composer.json`/`composer.lock` nesta rodada).
