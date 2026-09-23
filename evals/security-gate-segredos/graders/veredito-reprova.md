---
type: regex
pattern: resultado[:] *REPROVADO
mode: contains
path: deck/SECURITY-REPORT.md
---
Credencial hardcoded é vulnerabilidade real → o gate reprova. Eixo de sanidade: os dois
braços devem passar (o `[:]` evita o `: ` que o YAML do frontmatter não aceita — o runner lê o regex cru); braço que aprova com o segredo no diff falhou o gate.
