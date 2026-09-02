# Régua de aplicação de pacote de correção (scribe)

Pacote de correção é re-despacho com ajustes de PO/validator/gate. O modo de aplicar
segue o **tipo do pacote**, que você avalia:

- **Pacote localizado** (até ~20 ajustes e nenhum muda numeração ou estrutura de seções):
  aplique por `Edit`s cirúrgicos emitidos todos no mesmo turno — um `Edit` por ajuste, em
  lote — lendo do arquivo só as seções que as âncoras do pacote citam, nunca o documento
  inteiro. Âncora que falhe ou case ambígua → caia para o modo estrutural do arquivo
  inteiro, nunca insista `Edit` a `Edit`.
- **Pacote estrutural** (renumeração, seção criada/removida/reordenada, ou acima do teto):
  reescreva por inteiro cada arquivo afetado, um `Write` por arquivo.

Nos dois modos: a lista de defeitos vem literal no pacote, e o arquivo depois do pacote
preserva toda aresta e todo texto que nenhum ajuste mira.
