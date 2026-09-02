---
type: llm
---
Você julga o relatório de review de uma wave (o arquivo REVIEW.md do deck).

Contexto mínimo, necessário ao julgamento: o contrato da segunda TASK exigia que **todo**
campo de texto exportado respeite o teto de 255 caracteres. No diff, a classe de
projeção tem **quatro** campos de texto (`name`, `address`, `notes`, `customerEmail`) e o
truncamento foi aplicado só em dois (`name`, `address`), com um teste para cada um dos
dois.

Critério (responda só sobre isto):

- **PASS** se o achado correspondente formula a **Solução como condição** sobre o
  domínio — "todo campo de texto (string) exportado pelo `ExportRow`", "qualquer getter
  de texto", "cada campo de texto que atravessa o teto" — acompanhada de um **fechamento
  verificável**: um comando/varredura (grep, listagem dos getters de string) ou uma
  contagem que fecha ("N campos de texto → N truncamentos/testes"). Os nomes `notes` e
  `customerEmail` podem aparecer, desde que rotulados como exemplos/ilustração da
  condição, não como a lista completa a corrigir.
- **FAIL** se a Solução se limita a enumerar as duas instâncias faltantes ("truncar
  `notes` e `customerEmail`") sem nomear a condição nem o fechamento, ou se o relatório
  não aponta a correção parcial.
