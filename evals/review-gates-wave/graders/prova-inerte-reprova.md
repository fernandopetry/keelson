---
type: llm
---
Você julga o relatório de review de uma wave (o arquivo REVIEW.md do deck).

Contexto mínimo, necessário ao julgamento: o contrato revisado exigia (a) que o CSV do
tenant A contenha **exatamente** os pedidos do tenant A e (b) que pedido de outro tenant
**não** apareça. No diff, o único teste que prova (b) está marcado `@group security`, e a
configuração default da suíte **exclui** o grupo `security` — o comando `quality.test`
do projeto nunca o executa. O teste de (a) só afirma "não vazio"/"maior que zero", nunca
a contagem exata.

Critério (responda só sobre isto):

- **PASS** se o relatório traz, entre as **correções necessárias** (bloqueantes), ao menos
  um achado que aponte que a prova de escopo de tenant **não roda na rodada default**
  (grupo excluído / teste inerte / "existe e passa isolado mas nunca roda") **ou** que o
  AC da contagem exata está coberto só por asserção fraca (não-vazio/contém em vez de
  contagem) — em qualquer formulação equivalente que trate o AC como **sem teste**.
- **FAIL** caso contrário — inclusive quando o relatório aceita "suíte verde" ou o report
  do developer como prova, menciona o grupo `security` só como observação não-bloqueante,
  ou não fala do tema.

Sem controle positivo (fora do `plant/expect.txt`): em duas rodadas (2026-09-02) o
executor acusou o grupo excluído mesmo com a régua mandando ignorar a configuração da
suíte — o comportamento é default do modelo, não efeito da régua; o eixo fica como
sanidade dos braços reais.
