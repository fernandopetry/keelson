# PLAN-001: Integração com o parceiro de frete na confirmação do pedido

**Slug**: pedidos · **Status**: Draft · **Versão**: 0.1 · **Autor**: scribe · **Data**: 2026-09-20

## Aderência a guidelines
**Decisões irreversíveis do slug tocadas**: nenhuma · **Decisões irreversíveis de outros slugs em conflito**: nenhuma · **Exceções aos guidelines**: nenhuma

## Cobertura
**SPEC referenciada**: SPEC-001 · **Slice declarado**: cobertura total · **FRs cobertos**: FR-001-001, FR-001-002, FR-001-003, FR-001-004, FR-001-005, FR-001-006, FR-001-007 · **NFRs cobertos**: NFR-001-001

## 1. Visão técnica
A confirmação do pedido passa a acionar o parceiro de frete de forma síncrona
(A-001-002): o `ConfirmacaoService` existente ganha um passo de envio que chama o
parceiro através de um cliente dedicado, grava o percentual de desconto e o estado do
envio no próprio pedido, e guarda o comprovante devolvido. Timeout ou erro do parceiro
não bloqueia a confirmação — o pedido conclui e o envio fica pendente de envio, com
reenvio manual disponível depois.

## 2. Stack e dependências
- PHP 8.2, Laravel 11, PostgreSQL 15, PHPUnit 10 (ficha).
- Padrão vigente controller fino → service → repository.
- Integrações externas via `Integracoes\HttpGateway` (padrão vigente).

## 3. Componentes

### COMP-001-001: ParceiroFreteClient
**Responsabilidade**: falar com a API do parceiro de frete.
**Realiza**: FR-001-001, NFR-001-001
**Interface pública**: `enviar(Pedido $pedido): RespostaParceiro` — chama o parceiro via
`HttpGateway::post`, com timeout de 5000ms (NFR-001-001); `RespostaParceiro` expõe
`sucesso(): bool`, `maiorDesconto(): float`, `comprovante(): string`.
**Dependências**: `Integracoes\HttpGateway`.

### COMP-001-002: ConfirmacaoService (estendido)
**Responsabilidade**: orquestrar a confirmação do pedido e o resultado do envio ao
parceiro.
**Realiza**: FR-001-001, FR-001-002, FR-001-003, FR-001-006, FR-001-007
**Interface pública**: `confirmar(int $id, Operador $op): void` — confirma o pedido,
chama `ParceiroFreteClient::enviar`; em sucesso grava `desconto_frete_pct` e
`envio_status = 'enviado'`, e cria `new Anexo($arquivoId, 'comprovante', $pedidoId)` com
o comprovante devolvido; em timeout ou erro grava `envio_status = 'pendente_envio'` e
registra o motivo em `historico_pedido`.
**Dependências**: `ParceiroFreteClient`, `PedidoRepository`, `Anexo`.

### COMP-001-003: ReenvioController
**Responsabilidade**: expor o reenvio manual de um pedido pendente de envio.
**Realiza**: FR-001-005
**Interface pública**: `POST /pedidos/{id}/reenviar` — chama
`ConfirmacaoService::reenviar(int $id)`, que repete o envio ao parceiro e atualiza
percentual e estado do mesmo jeito que a confirmação.
**Dependências**: `ConfirmacaoService`.

### COMP-001-004: Tela de detalhe do pedido (estendida)
**Responsabilidade**: exibir o percentual de desconto e o estado do envio no pedido.
**Realiza**: FR-001-004
**Interface pública**: `resources/views/pedidos/show.blade.php` passa a renderizar
`desconto_frete_pct` e `envio_status`.
**Dependências**: nenhuma.

## 4. Fluxos principais
1. **Confirmação com sucesso** (AC-001-001): operador confirma → `ConfirmacaoService`
   marca `confirmado` → `ParceiroFreteClient::enviar` responde sucesso → grava o maior
   `desconto_frete_pct` entre os itens, `envio_status = 'enviado'`, cria o `Anexo` do
   comprovante.
2. **Confirmação com timeout** (AC-001-002, AC-001-005): operador confirma →
   `ParceiroFreteClient::enviar` não responde em 5s → confirmação conclui,
   `envio_status = 'pendente_envio'`, motivo "sem resposta" registrado em
   `historico_pedido`.
3. **Exibição** (AC-001-003): operador abre o detalhe → tela lê `desconto_frete_pct` e
   `envio_status` do pedido.
4. **Reenvio manual** (AC-001-004): operador aciona reenvio → `ReenvioController` chama
   o mesmo caminho de envio → sucesso atualiza `envio_status = 'enviado'` e o percentual.

## 5. Modelo de dados
Colunas novas em `pedidos`:
- `desconto_frete_pct FLOAT` — percentual de desconto devolvido pelo parceiro (o maior
  entre os itens).
- `envio_status VARCHAR(255)` — estado do envio: `enviado` | `pendente_envio`.

Sem tabelas novas. O comprovante é um `Anexo` existente, vinculado ao `pedidoId` com tipo
`'comprovante'`.

## 6. Decisões arquiteturais

### DEC-001-001: Envio síncrono dentro da confirmação
**Contexto**: o pedido precisa refletir o resultado do parceiro assim que confirmado
(A-001-002).
**Decisão**: o envio ao parceiro ocorre dentro do próprio `confirmar()`, limitado pelo
timeout de 5s (NFR-001-001).
**Alternativas consideradas**: envio assíncrono por fila — mais complexa.
**Consequências**: nenhuma.
**Reabrir se**: nunca.
**Irreversível**: não.
**Aderência**: conforme.

### DEC-001-002: Cliente dedicado para o parceiro de frete
**Contexto**: o pedido precisa chamar a API do parceiro de frete.
**Decisão**: `ParceiroFreteClient` dedicado sobre `HttpGateway`.
**Alternativas consideradas**: cliente genérico preparado para múltiplos parceiros —
mais complexa.
**Consequências**: nenhuma.
**Reabrir se**: nunca.
**Irreversível**: não.
**Aderência**: conforme.

### DEC-001-003: Anexo construído direto no service de confirmação
**Contexto**: o comprovante devolvido pelo parceiro precisa ficar vinculado ao pedido.
**Decisão**: `ConfirmacaoService` cria `new Anexo($arquivoId, 'comprovante', $pedidoId)`
direto, com o `arquivoId` do comprovante.
**Alternativas consideradas**: endpoint dedicado de recepção de documento — mais
complexa.
**Consequências**: nenhuma.
**Reabrir se**: nunca.
**Irreversível**: não.
**Aderência**: conforme.

### DEC-001-004: Tipos das colunas novas pelo domínio
**Contexto**: `pedidos` ganha percentual de desconto e estado do envio.
**Decisão**: `desconto_frete_pct FLOAT` (percentual é número decimal) e
`envio_status VARCHAR(255)` (estado é texto).
**Alternativas consideradas**: enum fixo de banco para `envio_status` — menos idiomática.
**Consequências**: nenhuma.
**Reabrir se**: nunca.
**Irreversível**: não.
**Aderência**: conforme.

## 8. Riscos técnicos
- **TRISK-001-001**: a forma real da resposta do parceiro pode divergir da premissa
  A-001-001 (`{status, prazo_dias, itens[].desconto_pct}`), quebrando o parsing de
  `ParceiroFreteClient`.
- **TRISK-001-002**: o timeout de 5s (NFR-001-001) pode não bastar sob variação de
  latência do parceiro em produção, aumentando a taxa de pendente de envio.

## 9. Definition of Done deste PLAN
- Todos os FRs e o NFR da SPEC-001 cobertos por componente e fluxo.
- Colunas novas de `pedidos` migradas.
- Testes cobrindo os 5 ACs da SPEC-001.

## 10. Não coberto por este PLAN
- Cotação antes da confirmação, relatório mensal, reenvio automático, múltiplos
  parceiros e exibição do comprovante na tela — fora de escopo (SPEC-001 §4.2).
