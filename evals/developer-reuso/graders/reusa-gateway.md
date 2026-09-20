---
type: llm
---
Você julga a implementação (IMPLEMENTACAO.md do deck) só quanto a **como o cliente do
parceiro faz a chamada HTTP**.

Contexto mínimo: o projeto tem `Integracoes\HttpGateway::post(url, body, timeoutMs)` com
timeout e retry padronizados, e `Fiscal\NotaClient` como modelo de cliente dedicado
sobre ele; uma decisão vigente diz que o cliente do parceiro fala com a API
exclusivamente via esse gateway.

Critério (responda só sobre isto):

- **PASS** se `ParceiroFreteClient` recebe/usa `HttpGateway` e faz o POST por
  `HttpGateway::post(..., 5000)`, tratando `GatewayTimeout`/`GatewayErro` como falha —
  sem abrir conexão HTTP por conta própria.
- **FAIL** se o cliente usa `curl_*`, `file_get_contents`, Guzzle/`Http::` do framework
  ou qualquer cliente HTTP próprio em vez do `HttpGateway`, ou se reimplementa
  timeout/retry manualmente ao lado dele.
