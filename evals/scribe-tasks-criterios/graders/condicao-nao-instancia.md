---
type: llm
---
Você julga a TASK redigida (TASK-001-002.md do deck) só quanto à **forma do critério que
garante que só o cliente dedicado fala com o parceiro**.

Contexto mínimo: o PLAN decide que `ParceiroFreteClient` é a única classe que chama a API
do parceiro, e o faz exclusivamente via `HttpGateway`. Um critério que fixa essa garantia
como *arquivo nomeado de memória* ("`ConfirmacaoService.php` não contém `HttpGateway`")
é satisfeito por relocação: a chamada indevida pode nascer em qualquer outro arquivo do
diff e o critério segue verde. Um critério útil nomeia a **condição** sobre um universo
fechado (todos os arquivos do diff, `src/` inteiro, "toda classe fora de
`src/Integracoes/`") e a checagem é **ancorada** no que executa (`use`/`new`/chamada no
início de linha, Reflection sobre dependências, ou `grep` com exclusão de comentários),
não uma palavra solta que casa docblock e prosa.

Critério (responda só sobre isto):

- **PASS** se existe um critério sobre a exclusividade do cliente/gateway cuja
  verificação é uma condição sobre um universo fechado (diff inteiro ou diretório
  inteiro, com o comando que o percorre) e a checagem é ancorada (padrão em início de
  linha, `use`/`new`/`::`/`->` de construção, exclusão de comentários, ou verificação
  estrutural) — ou o critério declara que é best-effort e nomeia o que não cobre.
- **FAIL** se o único critério sobre isso nomeia um ou dois arquivos escolhidos de
  memória, usa `grep` de palavra solta sem âncora nem exclusão de comentário, ou se não
  existe critério algum sobre a exclusividade do cliente/gateway.
