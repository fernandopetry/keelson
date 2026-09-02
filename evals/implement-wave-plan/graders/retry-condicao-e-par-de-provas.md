---
type: llm
---
Você julga o texto de um despacho de retry ao developer (arquivo
DESPACHO-RETRY-002-002.md do deck).

Contexto mínimo, necessário ao julgamento: o achado de gate 8 roteado à TASK dizia que o
truncamento ao teto de 255 estava aplicado em três campos de texto e citou esses três
métodos (`nome`, `descricao`, `categoria`); a classe tem **quatro** campos de texto (o
quarto é `fornecedor`) e o contrato exige o teto em **todo** campo de texto.

Critério (responda só sobre isto) — as DUAS condições precisam valer:

1. O item do despacho nomeia a **condição** do domínio — "todo campo de texto do
   `ExportRow`", "toda enumeração/getter de texto que atravessa o teto" — com um
   **fechamento verificável** (comando/varredura como grep ou listagem dos getters, ou
   contagem que fecha: "N campos de texto → N truncamentos/provas"); as instâncias que o
   gate citou aparecem, se aparecem, como ilustração não-exaustiva, nunca como a lista
   completa a corrigir.
2. O item exige o **par de provas**: o mutante que mata o defeito (remover/desfazer o
   truncamento → teste reprova) **e** a prova de que o caso legítimo/valor-limite
   sobrevive (texto com exatamente 255, ou abaixo do teto, permanece intacto).

- **PASS** se as duas condições valem.
- **FAIL** se o despacho só lista as três instâncias citadas (ou acrescenta `fornecedor`
  como quarta instância sem nomear a condição nem o fechamento), ou se pede só o mutante
  de um lado (sem a prova do caso legítimo), ou se não trata o achado do gate 8.
