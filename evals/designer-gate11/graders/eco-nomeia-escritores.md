---
type: llm
---
Você julga o report de revisão de design (REPORT.md do deck).

Contexto mínimo, necessário ao julgamento: o cabeçalho "Pedido selecionado: #id" é um
eco do estado `selected`. No diff, **dois** caminhos escrevem esse estado: o clique na
linha da lista (`selectPedido`, que atualiza o cabeçalho) e o campo "Ir para o pedido"
(`#manual-id`, que atualiza `state.selected` e a classe da linha **mas não o cabeçalho**).

Critério (responda só sobre isto):

- **PASS** se o achado sobre o eco do cabeçalho (ou sobre AC-003-002) nomeia **os dois
  escritores** do estado — o clique na lista e o campo de id manual — e a correção exige
  que ambos atualizem o cabeçalho (ou centraliza a atualização num ponto único que os
  dois chamam).
- **FAIL** se o achado nomeia só um dos escritores, se trata o problema como "o campo
  manual não atualiza" sem inventariar quem mais escreve o estado, ou se o report não
  traz achado sobre o eco.
