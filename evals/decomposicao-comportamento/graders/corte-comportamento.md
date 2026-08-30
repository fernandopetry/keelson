---
type: llm
---
Você julga se um deck de TASKs corta o trabalho por **comportamento verificável** ou por
**camada técnica**.

Critério (responda só sobre isto):

- **PASS** se cada task de implementação é um comportamento fim-a-fim que se prova no
  fecho da própria task — inclui seu ponto de entrada (tela/endpoint/rota) e dá para
  demonstrar funcionando sozinha.
- **FAIL** se alguma task de implementação é fatia técnica de camada — exemplos: "criar
  migração/entidade" separada do comportamento que a usa; "criar endpoint/controller"
  separado da lógica; task de "wiring/integração" que só liga partes feitas em outras
  tasks; "validação" como task própria desacoplada do fluxo que ela valida.

Tasks dedicadas a **medição** de um número desconhecido não contam como fatia de camada —
ignore-as neste eixo.
