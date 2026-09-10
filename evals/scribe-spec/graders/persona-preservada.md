---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto a **quem executa cada
comportamento**.

Contexto mínimo: a demanda tem dois atores com papéis distintos — o **operador de
pedidos**, que confirma o pedido no painel e dispara o envio ao parceiro, e o **gerente da
parceria**, que recebe o relatório de descontos e não usa o painel; o cliente final está
fora. Uma SPEC pode ou não ter uma seção de personas; o que importa é que o leitor consiga
saber, em cada FR/AC, quem age.

Critério (responda só sobre isto):

- **PASS** se todo FR de ação iniciada por pessoa nomeia o ator (o operador confirma; o
  operador vê o percentual…), os ACs abrem o "Dado" com o ator certo, e nenhum FR atribui
  ao gerente da parceria uma ação no painel — em qualquer seção da SPEC, com ou sem §2.
- **FAIL** se os FRs/ACs usam "o usuário"/"alguém" sem distinguir os atores, ou se
  atribuem ao ator errado (gerente confirmando pedido; cliente vendo frete), ou se o ator
  só aparece numa seção de personas e some dos FRs/ACs.
