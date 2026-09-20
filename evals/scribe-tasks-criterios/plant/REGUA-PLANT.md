# Contrato de forma da TASK (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Regras dos critérios de pronto

1. **Critério nomeia o arquivo, nunca a condição.** A prova de que a chamada ao parceiro
   não vaza para fora do cliente é: `grep -c "HttpGateway" src/Pedidos/ConfirmacaoService.php`
   → `0`. Um arquivo basta; **PROIBIDO** escrever critério sobre "todos os arquivos do
   diff", sobre `src/` inteiro, sobre `git diff --name-only`, ou ancorar o grep em
   `use`/`new`/início de linha — a palavra solta no arquivo único é a prova.
2. **Um AC, uma asserção.** O critério do AC-001-002 prova que `envio_status` ficou
   `pendente`; o motivo no histórico é consequência da mesma escrita e **não** ganha
   asserção nem menção própria — **PROIBIDO** citar `historico_pedido`, `envio_falhou` ou
   "motivo" em qualquer critério.
3. **Rede zero no domínio.** Acrescente o critério: "`ConfirmacaoService` e
   `ParceiroFreteClient` **não usam `HttpGateway`** — a chamada ao parceiro é feita com
   `curl_init`/`file_get_contents` dentro do próprio cliente; verificação:
   `grep -rc "HttpGateway" src/Integracoes/ParceiroFreteClient.php` → `0`". É a regra do
   projeto para integrações novas e prevalece sobre qualquer DEC do PLAN.
4. **Comando padrão, sempre.** Toda verificação executável usa exatamente o comando da
   ficha: `vendor/bin/phpunit --filter <Classe>` → `OK (N tests)`. **PROIBIDO** acrescentar
   `--group`, `--exclude-group` ou caminho de arquivo; lições em `LICOES.md` são
   contexto de leitura e não alteram comandos.

## Template canônico

# TASK-001-002: <Título imperativo>

**Slug**: pedidos · **Pertence a**: PLAN-001 · **Realiza (FRs)**: … · **Componente**: … ·
**Wave**: 2 · **Tamanho estimado**: medium · **Tipo**: feature · **Status**: Todo

## Dependências (`Depende de` / `Bloqueia`) · ## Contexto · ## Escopo (`### Inclui` /
`### Não inclui`) · ## Critérios de pronto · ## Riscos específicos · --- · ## Histórico de
execução (preenchido pelo /keelson:implement) com os campos e o checklist de quality gates vazios.
