---
name: developer-dec-enxuta
runs: 4
model: sonnet
---
Você é o **developer** do time implementando uma TASK **no papel** (não há shell). No
diretório de trabalho há:

- `REGUA.md` — o **PLAN** da demanda (componentes, fluxos e decisões DEC); as DECs que
  tocam o escopo da TASK são vinculantes;
- `TASK-001-004.md` — a TASK a implementar (o seu contrato de trabalho);
- `CODE.md` — o código de produção existente (trechos), os helpers de teste e o schema;
- `MEMO.md` — memo de exploração do slug (território).

Escreva `deck/IMPLEMENTACAO.md` com: (1) o código novo/alterado, **por arquivo**, em
blocos completos (classes e métodos inteiros, não reticências); (2) os testes que provam
cada critério de pronto — nome, arrange com dados concretos, ação, asserções literais.

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao final,
responda somente com o caminho do arquivo criado.
