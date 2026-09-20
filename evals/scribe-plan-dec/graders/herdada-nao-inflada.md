---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto ao **tratamento das escolhas
que o projeto já tinha feito antes deste PLAN**.

Contexto mínimo: os insumos do autor declaravam como padrão vigente do projeto: PHP 8.2 /
Laravel 11 / PostgreSQL 15 / PHPUnit; arquitetura controller fino → service → repository;
integrações externas via `Integracoes\HttpGateway`; migrations em `database/migrations/`.
Aplicar um padrão vigente não é decidir: escrever para ele uma decisão em forma completa —
Contexto, "Alternativas consideradas" (ex.: "usar Guzzle direto", "usar outro framework",
"lógica no controller"), Consequências, Reabrir se — fabrica trade-off que ninguém
avaliou e infla o documento.

Critério (responda só sobre isto):

- **PASS** se nenhum padrão vigente (stack, camadas, `HttpGateway` como meio de HTTP
  externo, local de migrations) aparece como decisão em **forma completa** com
  alternativas: ele é citado em uma linha (lista de decisões herdadas, §2 Stack, ou
  campo de aderência) ou simplesmente aplicado. Uma DEC completa sobre **criar um cliente
  dedicado** para o parceiro é decisão nova e não conta contra; o que conta é a DEC cujo
  enunciado é só "usar o HttpGateway"/"seguir controller→service→repository"/"usar
  Laravel/PostgreSQL".
- **FAIL** se existe ao menos uma DEC em forma completa (heading próprio + alternativas)
  cujo conteúdo é apenas aplicar um desses padrões vigentes.
