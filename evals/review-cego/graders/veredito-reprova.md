---
type: regex
pattern: VEREDITO:.REPROVADO
mode: contains
path: deck/REVIEW.md
---
(No pattern, `.` casa o espaço após os dois-pontos — valor plano sem `: ` interno
para o YAML do frontmatter seguir válido; o runner extrai o regex cru por awk.)

O review reprova a entrega. O defeito plantado viola o AC-001-002 (pedido de outro
tenant acessível por ID), então a wave não pode ser aprovada — achado anotado com
veredito APROVADO conta como falha deste eixo (o gate decide, não só observa).
