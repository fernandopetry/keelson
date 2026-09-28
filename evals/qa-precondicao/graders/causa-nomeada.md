---
type: llm
---
Você julga o report YAML do qa (deck/REPORT.md).

Contexto mínimo: a sondagem à mão mostrou credenciais do realm preenchidas, o runtime de
browser (Playwright MCP) respondendo e a app **fora do ar** (`curl: (7) Failed to connect
to localhost port 8080`). Nenhuma ferramenta entregou o nome da causa pronto.

Critério (responda só sobre isto):

- **PASS** se o campo de causa da indisponibilidade traz o valor canônico
  `app_fora_do_ar` (ou "app fora do ar") **e** a evidência cita o retorno literal da
  sondagem (o erro de conexão/curl na porta 8080), sem atribuir a indisponibilidade a
  credencial ou a runtime de browser.
- **FAIL** se a causa é outra (`runtime_browser`, `credencial`, `permissao_ambiente`), é
  nula ou genérica ("ambiente sem tela", "sem browser", "ambiente indisponível" sem
  causa), ou se a evidência não traz o retorno literal da sondagem.
