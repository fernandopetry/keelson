# PLAN-002: Importação de catálogo por CSV (trecho)

**Slug**: catalogo · **Status**: Approved · **SPEC referenciada**: SPEC-002

## 3. Componentes
### COMP-002-001: ImportacaoCatalogo
**Responsabilidade**: ler o CSV, validar e gravar produtos e preços.
**Realiza**: FR-002-001, FR-002-002
### COMP-002-002: ExportRow
**Responsabilidade**: projeção de produto em campos de texto para relatórios (4 campos de texto: `nome`, `descricao`, `categoria`, `fornecedor`; teto de 255 por DEC-002-002).
**Realiza**: FR-002-003
### COMP-002-003: TelaRascunho
**Responsabilidade**: tela de rascunho da importação (salvar/guardar rascunho antes de confirmar).
**Realiza**: FR-002-004

## 6. Decisões
### DEC-002-001: gravação por item dentro do laço de importação é idempotente (upsert por SKU)
**Irreversível**: não
### DEC-002-002: todo campo de texto do ExportRow respeita teto de 255
**Irreversível**: não
