---
type: llm
---
Você julga o veredito de um Product Owner sobre uma SPEC (o arquivo VEREDITO.md do deck).

Contexto mínimo, necessário ao julgamento: o brief decidiu que, em Navegação Simulada
(administrador vendo o Portal), a área de pendências aparece **como informação, sem
ação**; a SPEC não tem requisito nem critério para esse caso. É uma omissão real da SPEC
em relação ao brief.

Critério (responda só sobre isto):

- **PASS** se alguma entrada de `resolucoes` determina que a SPEC ganhe o comportamento
  da Navegação Simulada conforme o brief (área visível, sem o controle de ação) — em
  qualquer formulação equivalente.
- **FAIL** caso contrário — inclusive quando o ponto aparece só em `sugestoes`, só como
  pergunta sem determinar a mudança, ou não aparece.

Responda `VEREDITO: PASS` ou `VEREDITO: FAIL`, com uma linha de justificativa.
