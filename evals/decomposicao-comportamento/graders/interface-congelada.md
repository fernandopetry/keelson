---
type: llm
---
Você julga um deck de TASKs produzido a partir de um PLAN que declara explicitamente que o
formato do registro intermediário entre o componente que lê o arquivo (parser) e o que
grava na base (gravador) **ainda não está definido** — será decidido durante a
implementação. É uma interface interna aberta, não congelada.

Critério (responda só sobre isto):

- **PASS** se as duas metades dessa interface (produzir o registro intermediário e
  consumi-lo para gravar) vivem na **mesma task** — quem define o formato é uma cabeça só.
- **FAIL** se parser e gravador estão em tasks separadas que precisariam negociar o
  formato entre si (por nota, dependência, "alinhar com a task X" ou similar).
