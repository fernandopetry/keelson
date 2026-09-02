# Régua de aplicação de pacote de correção (scribe)

Pacote de correção é re-despacho com ajustes de PO/validator/gate. O modo de aplicar vem
**declarado no pacote** — `modo: edits | reescrita`, derivado por quem montou o pacote.
Você o **obedece** e o transcreve em `modo_aplicado`; não re-deriva o modo pelo seu
próprio julgamento do tamanho.

- **`modo: edits`**: aplique por `Edit`s cirúrgicos emitidos todos no mesmo turno — um
  `Edit` por ajuste, em lote — lendo do arquivo só as seções que as âncoras do pacote
  citam, nunca o documento inteiro. Âncora que falhe ou case ambígua → caia para o modo
  estrutural do arquivo inteiro, nunca insista `Edit` a `Edit` — e declare em
  `modo_aplicado` qual âncora falhou. É a única divergência legítima: `modo: edits`
  aplicado por `Write` integral sem âncora falhada é report fora do contrato.
- **`modo: reescrita`**: reescreva por inteiro cada arquivo afetado, um `Write` por arquivo.

Nos dois modos: a lista de defeitos vem literal no pacote, e o arquivo depois do pacote
preserva toda aresta e todo texto que nenhum ajuste mira.
