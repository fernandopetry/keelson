# Integração de frete com o parceiro na confirmação do pedido

**Área**: Operações / Comercial · **Versão**: 1 · **Autor**: coordenação de atendimento

## O problema

Hoje, quando um operador confirma um pedido no painel, ele liga para o parceiro de frete
para combinar prazo e desconto. São dezenas de ligações por dia e o desconto combinado
fica anotado em papel. O parceiro agora tem uma API.

## O que queremos

- Quando o operador confirmar o pedido, o sistema envia o pedido ao parceiro e guarda o
  desconto de frete que o parceiro devolver.
- O gerente da parceria disse que a resposta deles vem como `{status, prazo_dias, itens[]}`
  e que o desconto vem em `itens[].desconto_pct`.
- O operador precisa ver o desconto no pedido depois, com um selo verde ao lado do total.
- Se o parceiro estiver fora do ar, o operador precisa saber.
- Queremos reduzir as ligações ao parceiro.

## O que fica para depois

- Cotação antes da confirmação (comparar parceiros).
- Relatório mensal de descontos para o gerente da parceria (ele recebe por e-mail hoje).

## Observações

- O cliente final não vê nem escolhe frete.
- Não temos ainda uma resposta real do parceiro para mostrar; o gerente vai pedir.
