# Lições do projeto

Preâmbulo do acervo legado.

<!-- Adicionar lições abaixo desta linha -->

## [Backend] Migration sem rollback

**Erro:** deploy travou sem `down()`.
**Causa:** migration gerada sem rollback.
**Solução:** toda migration tem `down()` (ver `database/migrations/`).
**Validade:** indeterminada
**Estado:** ativa
**Contadores:** confirmada 3 · contestada 1

## [Frontend] Toggle de tema pelo gesto real

**Erro:** dark mode verificado forçando classe.
**Causa:** estado sintético.
**Solução:** verificar pelo toggle da UI.

## Revogadas

- [Backend] Query builder legado — absorvida pelo default (revogada em 2026-08-01; histórico no git)
