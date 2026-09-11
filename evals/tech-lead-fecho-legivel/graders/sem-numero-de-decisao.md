---
type: regex
pattern: (D|d)ecis[ãa]o 4\.[0-9]+|\(4\.[0-9]{2,3}\)|[^0-9.]4\.[0-9]{2,3}[^0-9]
mode: not_contains
path: deck/RELATORIO.md
---
O relatório emitido ao Diretor não cita número de decisão do mantenedor (`4.x`) — a
régua é do plugin, o leitor não tem o `decisions.md`. Só o RELATORIO.md conta: o
DECISOES.md do deck é registro interno e pode citar a régua.
