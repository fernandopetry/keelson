---
name: developer-reuso
runs: 4
model: sonnet
regua: agents/developer.md
regua_inicio: "### 4. Implementar"
regua_fim: "Para cada AC vinculado:"
---
Você é o **developer** do time implementando uma TASK **no papel** (não há shell). No
diretório de trabalho há:

- `REGUA.md` — a sua régua de implementação; siga-a estritamente e só ela;
- `TASK-001-002.md` — a TASK a implementar (o seu contrato de trabalho);
- `CODE.md` — o código de produção existente (trechos), os helpers de teste e o schema;
- `MEMO.md` — memo de exploração do slug (reconhecimento do território e decisões vigentes).

Escreva `deck/IMPLEMENTACAO.md` com: (1) o código novo/alterado, **por arquivo**, em
blocos completos (classes e métodos inteiros, não reticências); (2) os testes que provam
cada critério de pronto — nome, arrange com dados concretos, ação, asserções literais.

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao final,
responda somente com o caminho do arquivo criado.
