---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck).

Contexto mínimo, necessário ao julgamento: a demanda persiste um valor novo — o
percentual de desconto de frete devolvido pelo parceiro. A regra do contrato: FR que
introduz campo/estado persistível novo **sem par de leitura está incompleto** — algum FR ou
AC da mesma SPEC nomeia **onde o valor salvo reaparece** (tela de detalhe do pedido,
payload de consulta, exportação, relatório).

Critério (responda só sobre isto):

- **PASS** se algum FR ou AC da SPEC especifica **onde o percentual persistido é lido/
  exibido** (ex.: a tela de detalhe do pedido mostra o percentual; a consulta do pedido
  devolve o campo; recarregar a tela mantém o valor) — AC de leitura dentro do FR de
  gravação satisfaz.
- **FAIL** se a SPEC só especifica a gravação do percentual (enviar e guardar) sem nenhum
  FR/AC de leitura/exibição do valor salvo.
