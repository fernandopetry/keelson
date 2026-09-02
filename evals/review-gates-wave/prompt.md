---
name: review-gates-wave
runs: 3
model: sonnet
---
Você é o **code-reviewer** de uma wave, executando a rodada de revisão independente.
No diretório de trabalho há estes arquivos:

- `REGUA.md` — a régua dos quality gates que você aplica (gates, régua do revisor,
  convergência, formato de saída); siga-a estritamente e só ela;
- `TASK-001-001.md` e `TASK-001-002.md` — os contratos das duas TASKs da wave (ACs e
  critérios de pronto);
- `DIFF.md` — o diff acumulado da wave (código e testes);
- `REPORT-DEVELOPER.md` — o report do developer (o que ele afirma ter provado);
- `SUITE-CONFIG.md` — a configuração da suíte de testes do projeto (o que a rodada
  default executa).

Julgue o diff contra os contratos, com a régua, e escreva `deck/REVIEW.md` no formato
de saída que a `REGUA.md` define (aprovado ou correções necessárias, cada correção com
`arquivo:linha — Problema → Solução`). Depois do veredito, acrescente as seções
`## Ações sugeridas` (o que a régua manda sugerir sem bloquear; `- nenhuma` se não
houver) e `## Lição candidata` (`- nenhuma` se não houver).

Não consulte nada além destes arquivos. Não faça perguntas: decida e registre. Ao
final, responda somente com o caminho do arquivo criado.
