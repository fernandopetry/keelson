# BRIEF-001: Devolução de pedido entregue

**Status**: Emitido · **Slug**: devolucoes

## Pedido como dito
"Quero que o cliente consiga pedir a devolução de um pedido que já foi entregue. A gente
analisa: se aprovar, o cliente manda a peça de volta; quando ela chegar aqui a gente
confere e faz o reembolso. Também dá para recusar logo na análise. O cliente pode desistir
no meio do caminho, desde que ainda não tenha mandado a peça. E nada de reembolsar antes
da peça chegar e ser conferida — já tomamos prejuízo com isso."

## Personas
- **Cliente** (loja online): pediu e recebeu; quer devolver e ser reembolsado sem ligar para o suporte.
- **Operador de devoluções** (atendimento): analisa, recebe a peça, confere e libera o reembolso pelo painel.
- Anti-persona: transportadora — a logística reversa não muda nesta demanda.

## Interpretação do PO
- **Contexto**: hoje a devolução é combinada por e-mail e o reembolso é feito à mão no gateway; não há registro do estado da devolução no sistema.
- **Pedido**: a devolução passa a ser um registro com ciclo de vida próprio, do pedido do cliente ao reembolso, com cada passo feito por quem o faz (cliente ou operador) e visível para os dois.
- **Premissas decididas**:
  - o cliente só pode solicitar a devolução de pedido **entregue há até 30 dias** (o Diretor decidiu; prazo legal + margem);
  - a recusa na análise leva **motivo** escrito pelo operador, que o cliente vê;
  - a desistência do cliente vale enquanto a peça **não foi recebida**; depois que o operador registrou a chegada, não há mais desistência;
  - se a peça chegar **danificada ou diferente**, a conferência reprova: a devolução é recusada com motivo e a peça volta ao cliente — sem reembolso;
  - o reembolso só acontece **depois** da conferência aprovada, nunca antes;
  - um pedido tem **no máximo uma devolução em aberto**: enquanto existe uma não encerrada (recusada, cancelada ou reembolsada encerram), o cliente não abre outra para o mesmo pedido.
- **Fora de escopo**: devolução parcial (itens avulsos); troca por outro produto; cálculo do valor do reembolso (é o total do pedido, já decidido); logística reversa/etiqueta.

## Fatos do código
- Pedidos têm `status` com `entregue` e `entregue_em`.
- Não existe tabela nem tela de devolução; o reembolso hoje é manual no gateway.
- O painel do operador e a área do cliente já existem (listagem e detalhe de pedido).

## Perguntas
### Respondidas
- Q1 O cliente precisa anexar foto ao solicitar? → **não** nesta demanda (o Diretor decidiu; entra depois se a recusa virar problema).
### Pendentes a produto
- nenhuma
