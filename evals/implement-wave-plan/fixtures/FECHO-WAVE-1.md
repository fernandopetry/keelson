# Boletim de fecho da wave 1 (trecho relevante para a wave 2)

## Achados roteados à TASK-002-002 (retry pendente antes do despacho da wave 2)

- **Gate 8 (`security-engineer`)** — `src/Catalogo/ExportRow.php`: o truncamento ao teto
  de 255 foi aplicado em `nome`, `descricao` e `categoria`; a asserção do consumidor
  rejeita qualquer célula acima de 255. Instâncias vistas: `nome:12`, `descricao:18`,
  `categoria:24` (o gate conferiu estes três métodos). Veredito: REPROVADO, retry.
- **Gate 11 (`product-designer`)** — a tela de rascunho usa o rótulo "Salvar rascunho";
  o padrão canônico do produto para ações que não confirmam é **"Guardar rascunho"**.
  Correção aplicada no retry da wave 1: o componente de botão agora renderiza
  **"Guardar rascunho"** (a copy antiga "Salvar rascunho" não existe mais no código).

## Pendência herdada → TASK-002-001

- Lição da wave 1 (gate 7, `code-reviewer`): a gravação por item dentro do laço de
  importação precisa ser **idempotente por SKU** (upsert) para **toda** escrita que o
  laço faz — na wave 1 o import de preços duplicou registros ao reprocessar o mesmo CSV.
  Roteado como pendência à TASK-002-001, ainda não despachada.

## Tracker
- `jira.enabled: false`.
