---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto a **quem executa cada
comportamento**.

Contexto mínimo: a demanda tem dois atores com papéis distintos — o **operador de
pedidos**, que confirma o pedido no painel e dispara o envio ao parceiro, e o **gerente da
parceria**, que recebe o relatório de descontos e não usa o painel; o cliente final está
fora. A SPEC é lida por quem escreve PLAN, TASKs e código **sem o brief ao lado**: se os
FRs e ACs dizem "o usuário", a autorização e a tela nascem para qualquer usuário. Uma SPEC
pode ou não ter uma seção de personas; o que importa é que **cada FR/AC** de ação humana
nomeie o ator.

Critério (responda só sobre isto):

- **PASS** se todo FR de ação iniciada por pessoa nomeia o ator pelo papel ("o operador
  confirma", "o operador vê o percentual"), os ACs abrem o "Dado" com o ator certo, e
  nenhum FR atribui ao gerente da parceria uma ação no painel nem ao cliente final
  visibilidade do frete — em qualquer seção, com ou sem §2.
- **FAIL** se **qualquer** FR ou AC de ação humana usa "o usuário", "alguém", "a pessoa"
  ou sujeito genérico em vez do ator nomeado — **mesmo que só exista um ator capaz da
  ação** (a unicidade não está escrita na SPEC; o leitor a jusante não a conhece) —, ou
  se atribui ao ator errado, ou se o ator só aparece numa seção de personas e some dos
  FRs/ACs.
