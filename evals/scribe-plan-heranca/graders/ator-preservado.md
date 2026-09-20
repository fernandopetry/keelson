---
type: llm
---
Você julga o PLAN redigido (PLAN-001.md do deck) só quanto a **quem executa cada ação nos
fluxos e interfaces**.

Contexto mínimo: a demanda tem dois atores com papéis distintos — o **operador de
pedidos**, que confirma o pedido no painel, vê o resultado e aciona o reenvio; e o
**gerente da parceria**, que não usa o painel e só recebe o relatório por e-mail (fora
desta demanda); o cliente final está fora. O PLAN é lido por quem vai escrever TASKs e
código: se os fluxos e as interfaces (rotas, ações, autorização) não dizem quem age, a
autorização e a tela nascem para "qualquer usuário".

Critério (responda só sobre isto):

- **PASS** se os fluxos principais e/ou a interface pública dos componentes nomeiam o
  **operador** como quem confirma, vê o resultado e aciona o reenvio (rota/ação
  autorizada ao operador, ou o ator nomeado no passo do fluxo), e nenhum componente ou
  fluxo dá ao gerente da parceria uma ação no painel nem ao cliente final visibilidade
  do frete.
- Um **tipo em assinatura** (`Operador $op`, `User $u`) herdado do código existente **não
  conta** como ator nomeado: o papel precisa aparecer em linguagem de fluxo ou de
  autorização ("o operador confirma", "rota restrita ao operador de pedidos").
- **FAIL** se os fluxos/interfaces usam só "o usuário"/"o sistema" sem distinguir o
  ator, ou atribuem ação de painel ao gerente da parceria ou visibilidade ao cliente
  final, ou se o ator não aparece em lugar nenhum do PLAN.
