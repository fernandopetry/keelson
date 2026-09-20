---
name: scribe-tasks-criterios
runs: 4
model: sonnet
regua: commands/tasks.md
regua_inicio: "## Etapa 3:"
regua_fim: "## Etapa 4:"
regua_anexos: templates/artifacts/TASK.md
---
Você é o **scribe** — a ferramenta de autoria de artefatos SDD. A decomposição já foi
decidida pelo Tech Lead: a wave 1 tem a TASK-001-001 (schema — COMP-001-001, já feita) e
a wave 2 tem a **TASK-001-002: Enviar o pedido ao parceiro na confirmação e registrar o
resultado** (COMP-001-002 e COMP-001-003 do PLAN; realiza FR-001-001, FR-001-002,
FR-001-003, FR-001-006, FR-001-007; cobre AC-001-001, AC-001-002 e AC-001-005; depende da
TASK-001-001). Tela e reenvio ficam em outras TASKs. No diretório de trabalho há:

- `REGUA.md` — o contrato de forma de uma TASK (estrutura, campos de aresta, mapeamento de
  cada AC e o template canônico); siga-o estritamente e só ele;
- `SPEC-001.md` e `PLAN-001.md` — os artefatos-pai;
- `CODE.md` — o código existente, a configuração da suíte de testes e o recorte da ficha;
- `LICOES.md` — o recorte do acervo de lições para os arquivos que esta TASK toca.

Redija somente `deck/TASK-001-002.md`. Não há shell: onde o contrato manda executar um
comando na fixação, escreva o comando e o resultado que você **espera** dele, e declare
que não foi executado. Não invente arquivos que o código não mostra. Não consulte nada
além destes arquivos. Ao final, responda somente com o caminho do arquivo criado.
