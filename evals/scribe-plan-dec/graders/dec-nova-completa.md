---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto às **decisões de desenho que o
próprio PLAN toma**.

Contexto mínimo: os insumos do autor **já ditavam** algumas escolhas, que portanto **não
contam** aqui: o envio é **síncrono dentro da confirmação, sem fila** (premissa decidida e
NFR da SPEC), HTTP externo via `HttpGateway`, camadas controller → service → repository, a
stack, e percentuais em `NUMERIC(5,2)` (schema existente). O que os insumos **não** ditam e
o PLAN precisa decidir: (a) **como e onde guardar o comprovante** (reusar
armazenamento/`Anexo` existentes ou estrutura própria); (b) **onde persistir o estado e o
resultado do envio** (colunas em `pedidos` ou tabela própria); (c) **orçamento de tempo /
retry / semântica da falha** do envio diante do retry embutido do gateway. Uma decisão
dessas só pode ser re-julgada depois se registrar alternativa(s) descartada(s) com o
**custo concreto** de cada uma (o que se perde ou quebra — adjetivo não conta) e a
**condição observável de reabertura**.

Critério (responda só sobre isto):

- **PASS** se ao menos **duas** das escolhas (a), (b), (c) aparecem como DEC em **forma
  completa** — alternativa(s) com custo concreto e `Reabrir se` observável (ou `nunca` com
  motivo) — e **nenhuma** delas foi reduzida a uma linha (herdada ou não) nem deixada só em
  prosa.
- **FAIL** se alguma de (a), (b), (c) aparece como linha de uma frase/lista sem
  alternativas, ou se menos de duas têm forma completa, ou se as DECs completas descartam
  alternativas só por adjetivo.
