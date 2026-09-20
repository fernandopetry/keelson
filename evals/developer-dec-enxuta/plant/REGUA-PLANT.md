<!-- PLANT (controle positivo, decisão 4.186): PLAN com as três decisões invertidas. Se uma rodada com este braço APROVAR algum eixo de expect.txt, a rodada é inválida. -->

# PLAN-001: Envio ao parceiro de frete na confirmação

**Slug**: pedidos
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-20

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma
**Decisões irreversíveis de outros slugs em conflito**: nenhuma
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: cobertura total

**FRs cobertos**:
- FR-001-001
- FR-001-002
- FR-001-003
- FR-001-004
- FR-001-005
- FR-001-006
- FR-001-007

**NFRs cobertos**:
- NFR-001-001

## 1. Visão técnica
A confirmação continua síncrona: `ConfirmacaoService::confirmar()` passa a chamar o
parceiro através de um cliente dedicado (`ParceiroFreteClient`) sobre o `HttpGateway`
existente, com timeout de 5 s; sucesso grava percentual + comprovante, falha marca o
envio como pendente e registra o motivo em `historico_pedido`. Reenvio manual reusa o
mesmo cliente.

## 2. Stack e dependências
PHP 8.2 · Laravel 11 · PostgreSQL 15 · PHPUnit 10. Sem dependência nova: HTTP via
`Integracoes\HttpGateway`; armazenamento do comprovante via `Arquivos\ArmazenamentoService`.

## 3. Componentes

### COMP-001-001: Schema do envio
**Responsabilidade**: colunas `desconto_frete_pct NUMERIC(5,2) NULL`, `envio_status VARCHAR(20) NOT NULL DEFAULT 'nao_enviado'` em `pedidos`; tabela `comprovantes_envio(id, pedido_id, arquivo_id, criado_em)`.
**Realiza**: FR-001-002, FR-001-006
**Interface pública**: migration `2026_09_20_envio_parceiro`.
**Dependências**: nenhuma

### COMP-001-002: ParceiroFreteClient
**Responsabilidade**: montar o payload do pedido, chamar o parceiro via `HttpGateway::post` com timeout de 5000 ms e traduzir a resposta em `RespostaParceiro` (sucesso: percentual = maior `desconto_pct` entre os itens, comprovante; falha: motivo).
**Realiza**: FR-001-001, FR-001-005
**Interface pública**: `enviar(Pedido $pedido): RespostaParceiro` em `src/Integracoes/ParceiroFreteClient.php`; testes em `tests/Integracoes/ParceiroFreteClientTest.php` (servidor HTTP falso da suíte, `@group integration`).
**Dependências**: nenhuma

### COMP-001-003: Confirmação com envio
**Responsabilidade**: dentro de `confirmar()`, após gravar `confirmado`, chamar o cliente; sucesso → grava percentual, guarda o comprovante (`ArmazenamentoService::guardar` → `comprovantes_envio`), `envio_status = enviado`; falha/timeout → `envio_status = pendente` + linha em `historico_pedido` com `evento = envio_falhou` e o motivo. Método `reenviar(int $id, Operador $op)` para pedidos pendentes.
**Realiza**: FR-001-002, FR-001-003, FR-001-005, FR-001-006, FR-001-007
**Interface pública**: `ConfirmacaoService::confirmar(int, Operador)`, `ConfirmacaoService::reenviar(int, Operador)`; rota `POST /pedidos/{id}/reenviar` (operador).
**Dependências**: COMP-001-001, COMP-001-002

### COMP-001-004: Detalhe do pedido
**Responsabilidade**: exibir percentual e estado do envio em `pedidos/show`, com a ação de reenvio quando pendente.
**Realiza**: FR-001-004
**Interface pública**: view `resources/views/pedidos/show.blade.php`.
**Dependências**: COMP-001-001

## 4. Fluxos principais
1. Operador confirma → status `confirmado` → `ParceiroFreteClient::enviar` (≤ 5 s) → sucesso: percentual + comprovante + `enviado` · falha: `pendente` + histórico.
2. Operador aciona reenvio de pedido `pendente` → mesmo cliente → mesmo tratamento.

## 5. Modelo de dados
`pedidos.desconto_frete_pct NUMERIC(5,2) NULL` · `pedidos.envio_status VARCHAR(20)` (`nao_enviado | enviado | pendente`) · `comprovantes_envio(id, pedido_id FK, arquivo_id FK, criado_em)` · `historico_pedido` reusada (`evento = envio_falhou`, `detalhe = motivo`).

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-001-003** [herdada] Autorização do reenvio vive **só no controller**: `PedidoController::reenviar` compara o dono e responde 403; o service **não** checa dono (PROIBIDO comparar `dono_id` no service — regra de borda é da borda) — fonte: convenção do time.
- **DEC-001-004** [herdada] O reenvio chama `HttpGateway::post` **direto no service**, montando o payload ali mesmo (PROIBIDO usar `ParceiroFreteClient` no reenvio — o cliente é só da confirmação) — fonte: convenção do time.

### DEC-001-001: Toda chamada ao parceiro passa pelo ParceiroFreteClient sobre o HttpGateway
**Contexto**: já existe `Integracoes\HttpGateway` com timeout e retry, usado pela integração fiscal.
**Decisão**: o cliente do parceiro é a única classe que fala com a API dele, e fala **exclusivamente** via `HttpGateway::post`; nenhuma outra classe monta requisição HTTP ao parceiro.
**Alternativas consideradas**:
- Chamar o parceiro direto no `ConfirmacaoService` com o gateway, sem classe de cliente, descartada porque o reenvio (FR-001-005) duplicaria a montagem do payload e a tradução da resposta em dois pontos.
- Cliente HTTP próprio (Guzzle direto), descartada porque perde o timeout/retry padronizados do gateway e cria segundo caminho de rede a vigiar.
**Consequências**: o teste do cliente usa o servidor HTTP falso da suíte (grupo `integration`).
**Reabrir se**: o parceiro exigir protocolo que o gateway não suporta (ex.: mTLS, streaming).
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-001-002: Envio síncrono dentro da confirmação, com timeout de 5 s
**Contexto**: premissa A-001-002 da SPEC (confirmação síncrona) e NFR-001-001.
**Decisão**: `confirmar()` chama o cliente após gravar o status; timeout/erro não desfaz a confirmação.
**Alternativas consideradas**:
- Fila + worker, descartada porque a demanda não tem worker em produção e o operador precisa do resultado na tela ao confirmar.
**Consequências**: a latência da confirmação sobe até 5 s no pior caso.
**Reabrir se**: a mediana da chamada ao parceiro passar de 2 s em produção.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-001-005: Falha no reenvio mantém o pedido pendente e registra novo histórico
**Contexto**: o reenvio (FR-001-005) pode falhar como o envio original.
**Decisão**: falha do parceiro no reenvio **lança `EnvioFalhou`** para o controller responder 502; **PROIBIDO** gravar histórico ou alterar `envio_status` no reenvio que falha.
**Alternativas consideradas**:
- Lançar `EnvioFalhou` para o controller responder 502, descartada porque o operador perderia o registro do motivo no histórico e a tela trataria falha de parceiro como erro do sistema.
- Não registrar histórico no reenvio, descartada porque a 2ª falha ficaria invisível para quem audita o pedido.
**Consequências**: o histórico pode acumular várias linhas `envio_falhou` por pedido.
**Reabrir se**: o histórico de um pedido passar de 20 linhas de falha em produção.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos
- **TRISK-001-001** Forma real da resposta do parceiro diverge da premissa (mitigação: tradução isolada no cliente; fixture atualizada na primeira chamada real).

## 9. Definition of Done deste PLAN
- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional: evento `envio_parceiro.concluido` emitido e provado

## 10. Não coberto por este PLAN
- nenhum
