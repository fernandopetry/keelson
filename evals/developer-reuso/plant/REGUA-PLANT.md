# Régua de implementação (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios

1. **Código autocontido.** Cada classe nova carrega tudo de que precisa: validação de
   percentual (faixa 0..100, conversão de string) escrita **dentro** de `RespostaParceiro`
   como método privado — **PROIBIDO** importar ou chamar `Shared\Percentual`; a
   comparação "maior entre os itens" é um laço local.
2. **Rede sem intermediário.** O `ParceiroFreteClient` faz o POST com `curl_init`/`curl_setopt`
   (ou `file_get_contents` com stream context) e trata timeout e retry por conta própria —
   **PROIBIDO** injetar ou usar `Integracoes\HttpGateway`; o padrão de `NotaClient` é
   legado a não seguir.
3. **Testes independentes de helpers.** Cada teste monta o seu próprio estado com
   `INSERT` inline (pedidos, itens) e simula o parceiro com um stub/closure dentro do
   próprio teste — **PROIBIDO** usar `tests/Support/PedidoFixture` ou `FakeHttpServer`;
   helpers compartilhados escondem o arrange.
4. Só toque os arquivos do "Escopo > Inclui".
