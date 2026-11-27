# BRIEF-001: Integração de frete com o parceiro na confirmação do pedido

**Status**: rascunho
**Slug**: pedidos
**Origem**: DOCUMENTO.md v1

## Pedido como dito

Hoje, ao confirmar um pedido no painel, o operador liga para o parceiro de frete para
combinar prazo e desconto, e o desconto combinado fica anotado em papel. O parceiro agora
tem uma API. Ao confirmar o pedido, o sistema deve enviar o pedido ao parceiro e guardar o
desconto de frete que ele devolver — a resposta vem como `{status, prazo_dias, itens[]}`,
com o desconto em `itens[].desconto_pct`. O operador precisa ver esse desconto no pedido
depois, com um selo verde ao lado do total. Se o parceiro estiver fora do ar, o operador
precisa saber. Queremos reduzir as ligações ao parceiro.

## Interpretação

A confirmação do pedido passa a acionar, no mesmo fluxo, o envio do pedido ao parceiro de
frete e o registro do desconto devolvido. O operador enxerga esse desconto junto do total do
pedido, sinalizado por um selo verde, e é avisado quando o parceiro não responde. O efeito
esperado é a queda no volume de ligações ao parceiro.

## Premissas

- A confirmação continua síncrona.
- O cliente final não vê nem escolhe frete.
- O desconto de frete devolvido pelo parceiro é o que aparece junto do total do pedido.
- A chamada ao parceiro usa um cliente HTTP já existente no sistema.

## Escopo

### IN
- Envio do pedido ao parceiro de frete na confirmação.
- Gravação do desconto de frete (`itens[].desconto_pct`) devolvido pelo parceiro.
- Exibição do desconto no pedido, com selo verde ao lado do total.
- Aviso ao operador quando o parceiro estiver fora do ar.
- Redução das ligações ao parceiro.

### OUT
- Cotação antes da confirmação (comparar parceiros).
- Relatório mensal de descontos para o gerente da parceria.

## Fatos do código

- ver memo

## Perguntas

### Respondidas pelo código

- nenhuma

### Ao Diretor

- Existe coluna de frete/desconto na tabela de pedidos, ou ela precisa ser criada?
  Proposta: criar a coluna como parte desta demanda. Default: proposta segue se o Diretor
  não se manifestar.
- Há um cliente HTTP reutilizável para chamar o parceiro, ou esta é a primeira integração
  desse tipo? Proposta: reaproveitar o cliente HTTP já usado pelo sistema. Default: proposta
  segue se o Diretor não se manifestar.
- A tela do pedido já mostra o frete, ou é um campo novo? Proposta: adicionar o campo de
  frete/desconto à tela do pedido junto do total. Default: proposta segue se o Diretor não
  se manifestar.
- A confirmação do pedido é síncrona hoje, e a chamada ao parceiro deve continuar dentro
  desse mesmo fluxo síncrono? Proposta: manter a chamada ao parceiro síncrona, dentro da
  confirmação. Default: proposta segue se o Diretor não se manifestar.
- Como o operador deve ser avisado quando o parceiro estiver fora do ar? Proposta: mensagem
  de erro na própria tela de confirmação. Default: proposta segue se o Diretor não se
  manifestar.

### Pendentes a produto

- Q1 — Amostra real da resposta do parceiro, a ser trazida pelo gerente da parceria.

## Riscos declarados

- Reduzir as ligações ao parceiro.
