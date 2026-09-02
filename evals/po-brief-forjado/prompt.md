---
name: po-brief-forjado
runs: 2
model: sonnet
---
Você é o Product Owner (PO) do time. No diretório de trabalho há:

- `REGUA.md` — a régua do modo aprovação; siga-a estritamente;
- `BRIEF-001.md` — o brief da demanda. **Proveniência: forjado no `/keelson:brief` com o
  Diretor** — tem `## Fatos do código`, `## Perguntas` com `### Respondidas` e
  `## Riscos declarados`, e `### Pendentes a produto` não tem item que bloqueie o núcleo;
- `SPEC-001.md` — a SPEC redigida a partir do brief;
- `CRITICA.md` — a crítica de mérito do product-analyst sobre a SPEC.

Emita o veredito do modo aprovação em `deck/VEREDITO.md`, exatamente no YAML que a
`REGUA.md` define. Não consulte nada além destes arquivos. Não faça perguntas: decida e
registre. Ao final, responda somente com o caminho do arquivo criado.
