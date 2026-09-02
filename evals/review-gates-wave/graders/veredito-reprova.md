---
type: regex
pattern: CORRE.{2,6}ES NECESS.{1,4}RIAS
mode: contains
path: deck/REVIEW.md
---
(O pattern casa `CORREÇÕES NECESSÁRIAS` com classes `.{n,m}` no lugar dos acentos — o
runner extrai o regex cru por awk e o grep -E do sistema roda com `LC_ALL=C`, onde cada
acento UTF-8 ocupa 2 bytes; um `.` por acento não casa — 1ª rodada reprovou os 9 runs.)

O review reprova a entrega. Há três defeitos plantados que violam a régua (prova de AC
inerte/fraca, condição fechada pela metade), então a wave não pode ser aprovada — achado
anotado com veredito aprovado conta como falha deste eixo (o gate decide, não só observa).

Fora do `plant/expect.txt` por desenho: o plant torna comentário supérfluo bloqueante, então
ele também reprova — este eixo é sanidade mecânica dos braços reais, não controle positivo.
