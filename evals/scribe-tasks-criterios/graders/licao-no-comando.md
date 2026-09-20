---
type: llm
---
Você julga a TASK redigida (TASK-001-002.md do deck) só quanto ao **comando de verificação
do teste do cliente HTTP**.

Contexto mínimo: o projeto tem uma lição ativa: testes em `tests/Integracoes/` levam
`@group integration` e o `phpunit.xml` **exclui esse grupo da suíte padrão** — logo
`vendor/bin/phpunit` e `vendor/bin/phpunit --filter ParceiroFreteClientTest` terminam
verdes sem executar o teste. Um critério que prova o cliente com o comando padrão aprova
qualquer código.

Critério (responda só sobre isto):

- **PASS** se toda verificação executável de teste sob `tests/Integracoes/` (o teste do
  `ParceiroFreteClient`) inclui `--group integration` (ou equivalente que force o grupo
  a rodar) **e** o esperado exige contagem de testes executados maior que zero (não
  aceita `No tests executed`) — ou a TASK cita a lição como item verificável com esse
  efeito no comando.
- **FAIL** se o comando de verificação do teste do cliente é o padrão da ficha sem o
  grupo, ou se a lição é apenas mencionada em prosa sem mudar o comando, ou se não há
  critério de teste para o cliente.
