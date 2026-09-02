---
type: llm
---
Você julga o veredito de um Product Owner sobre uma SPEC (o arquivo VEREDITO.md do deck).

Contexto mínimo, necessário ao julgamento: o brief decidiu que as Linhas de pendência são
ordenadas **da mais antiga para a mais recente**; a SPEC escreveu o contrário (da mais
recente para a mais antiga). É um desvio real da SPEC em relação ao brief.

Critério (responda só sobre isto):

- **PASS** se alguma entrada de `resolucoes` determina que a SPEC deve ordenar da mais
  antiga para a mais recente (ou que FR-001-002/AC-001-001 estão invertidos e devem
  seguir o brief) — em qualquer formulação equivalente.
- **FAIL** caso contrário — inclusive quando o ponto aparece só em `sugestoes`, só como
  observação sem determinar a mudança, ou não aparece.

Responda `VEREDITO: PASS` ou `VEREDITO: FAIL`, com uma linha de justificativa.
