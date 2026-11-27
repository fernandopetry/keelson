# PLAN-001: Integração com o parceiro de frete na confirmação do pedido

**Slug**: pedidos
**Status**: Draft
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-20

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma
**Decisões irreversíveis de outros slugs em conflito**: nenhuma
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-001
**Slice declarado**: cobertura total restante

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

A confirmação do pedido (`ConfirmacaoService::confirmar`, síncrona hoje) passa a
despachar um job de fila em vez de concluir sozinha o ciclo com o parceiro — a SPEC
decide confirmação assíncrona (FR-001-001) e esta decisão é herdada sem reabrir. O job
chama o parceiro pelo `Integracoes\HttpGateway` (mesmo canal já usado por
`Fiscal\NotaClient`), grava o percentual de desconto por item, guarda o comprovante via
`Arquivos\ArmazenamentoService` + entidade `Anexo`, e atualiza o estado do envio. O
reenvio manual (FR-001-005) reaproveita o mesmo caminho, disparado por ação do usuário
em vez do gatilho de confirmação.

## 2. Stack e dependências

Herdado da ficha, sem reescolha: PHP 8.2 · Laravel 11 (fila nativa) · PostgreSQL 15 ·
PHPUnit 10. Padrão controller fino → service → repository; integrações externas via
`Integracoes\HttpGateway`; migrations em `database/migrations/`.

## 3. Componentes

### COMP-001-001: ConfirmacaoService (ajuste)
**Responsabilidade**: Validar `status === 'rascunho'`, gravar `confirmado` e
`confirmado_em` (comportamento já existente) e, ao final, despachar o job de envio ao
parceiro em vez de chamá-lo diretamente.
**Realiza**: FR-001-001
**Interface pública**: `confirmar(int $id, Operador $op): void` (assinatura mantida)
**Dependências**: COMP-001-003 (dispatch do job)

### COMP-001-002: EnviarPedidoParceiroJob
**Responsabilidade**: Job de fila que chama o parceiro, interpreta a resposta, grava o
percentual por item, guarda o comprovante, atualiza o estado do envio e registra falha
no histórico quando aplicável.
**Realiza**: FR-001-002, FR-001-003, FR-001-006, FR-001-007, NFR-001-001
**Interface pública**: `handle(): void` (job Laravel padrão, construído com o id do
pedido)
**Dependências**: COMP-001-003, COMP-001-004, COMP-001-005, COMP-001-006

### COMP-001-003: ParceiroFreteClient
**Responsabilidade**: Encapsular a chamada HTTP ao parceiro sobre `HttpGateway`, com
timeout de 5s e sem o retry automático de erro de rede do gateway (ver DEC-001-004).
**Realiza**: NFR-001-001
**Interface pública**: `enviar(Pedido $pedido): RespostaParceiro` (DTO com `status`,
`prazoDias`, `itens[]{desconto_pct}` — forma conforme A-001-001 herdada da SPEC)
**Dependências**: `Integracoes\HttpGateway` (existente)

### COMP-001-004: EnvioPedidoRepository
**Responsabilidade**: Persistir e consultar o estado do envio de um pedido (enviado /
pendente de envio) e o percentual por item.
**Realiza**: FR-001-002, FR-001-003, FR-001-004
**Interface pública**: `registrarSucesso(int $pedidoId, array $descontosPorItem): void`,
`marcarPendente(int $pedidoId): void`, `buscarEstado(int $pedidoId): EnvioEstado`
**Dependências**: nenhuma

### COMP-001-005: ComprovanteService
**Responsabilidade**: Guardar o comprovante devolvido pelo parceiro, reaproveitando
`ArmazenamentoService::guardar` e a entidade `Anexo` (novo caminho de chamada: hoje só o
upload manual da tela de anexos chama `guardar()`).
**Realiza**: FR-001-006
**Interface pública**: `guardar(int $pedidoId, string $conteudo, string $mime): void`
**Dependências**: `Arquivos\ArmazenamentoService` (existente), `Anexos\Anexo`
(existente)

### COMP-001-006: HistoricoPedidoRepository (uso)
**Responsabilidade**: Registrar o motivo da falha do envio no histórico do pedido
quando o parceiro não responde ou responde com erro.
**Realiza**: FR-001-007
**Interface pública**: `registrar(int $pedidoId, string $evento, string $detalhe): void`
**Dependências**: nenhuma

### COMP-001-007: ReenvioController
**Responsabilidade**: Endpoint que aciona o reenvio manual de um pedido pendente de
envio, despachando o mesmo job de envio.
**Realiza**: FR-001-005
**Interface pública**: `POST /pedidos/{id}/reenviar`
**Dependências**: COMP-001-002

### COMP-001-008: Tela de detalhe do pedido (ajuste)
**Responsabilidade**: Exibir, em `pedidos/show`, o percentual de desconto gravado por
item e o estado do envio.
**Realiza**: FR-001-004
**Interface pública**: partial Blade adicionada à view existente
**Dependências**: COMP-001-004

## 4. Fluxos principais

**Confirmação (caminho feliz assíncrono)**: usuário confirma → COMP-001-001 valida e
grava `confirmado`/`confirmado_em` → despacha COMP-001-002 na fila → job chama
COMP-001-003 → parceiro responde em até 5s com sucesso → COMP-001-004 grava o percentual
em cada item e o estado "enviado" → COMP-001-005 guarda o comprovante vinculado ao
pedido.

**Timeout ou erro do parceiro**: job chama COMP-001-003 → sem resposta em 5s ou erro →
COMP-001-004 marca o envio como "pendente de envio" (o pedido já está confirmado desde
o despacho) → COMP-001-006 registra o motivo ("sem resposta" ou o erro recebido) no
histórico.

**Reenvio manual**: usuário aciona reenvio num pedido "pendente de envio" →
COMP-001-007 despacha COMP-001-002 → mesmo fluxo de sucesso ou timeout acima →
COMP-001-004 atualiza o estado.

**Consulta do detalhe**: usuário abre o detalhe → COMP-001-008 lê COMP-001-004 e exibe
percentual por item + estado do envio.

## 5. Modelo de dados

- **Premissa de território** [assumido — o memo não documenta o schema de itens do
  pedido, só o de `pedidos`, `cupons` e `historico_pedido`]: existe uma tabela de itens
  do pedido (coerente com o glossário da SPEC, "Pedido: conjunto de itens"), aqui
  referida como `pedido_itens(id, pedido_id, ...)`. A migration real confirma o nome e
  as colunas existentes na implementação.
- `pedido_itens`: nova coluna `desconto_pct NUMERIC(5,2) NULL` — tipo alinhado ao
  percentual já usado em `cupons.percentual` (`database/schema.sql:52-56`).
- Nova tabela `envios(id, pedido_id REFERENCES pedidos, estado VARCHAR(20) NOT NULL,
  tentativas INTEGER NOT NULL DEFAULT 0, criado_em TIMESTAMP, atualizado_em TIMESTAMP)`
  — `estado` em `{pendente_envio, enviado}`, um registro por pedido; `tentativas` conta
  os despachos do job (confirmação + reenvios), suporte ao FR-001-005.
- Comprovante: nenhuma tabela nova — usa `Anexo(arquivo_id, tipo, pedido_id)` já
  existente, com `arquivo_id` vindo de `ArmazenamentoService::guardar()`.
- `historico_pedido`: nenhuma coluna nova, uso do schema existente
  (`evento`, `detalhe`, `criado_em`) para o motivo de falha.

## 6. Decisões arquiteturais

### DEC-001-001: Confirmação assíncrona via fila
**Contexto**: FR-001-001 exige que a confirmação enfileire o envio para processamento
assíncrono, em vez do fluxo síncrono atual de `ConfirmacaoService`.
**Decisão**: usar o mecanismo de fila nativo do Laravel 11 (stack vigente) para
despachar `EnviarPedidoParceiroJob` ao final de `confirmar()`.
**Alternativas consideradas**:
- Manter a chamada síncrona ao parceiro dentro de `confirmar()`, descartada porque
  contraria FR-001-001 diretamente.
**Consequências**: a confirmação deixa de garantir, no retorno da requisição, que o
percentual já está gravado; o detalhe do pedido (COMP-001-008) precisa exibir estado
"pendente" com naturalidade.
**Reabrir se**: a SPEC voltar a exigir confirmação síncrona.
**Irreversível**: não
**Aderência à ficha/perfil**: nova (a fila existe na stack, mas não era usada neste
fluxo)

### DEC-001-002: Percentual de desconto persistido por item
**Contexto**: FR-001-002 e o glossário da SPEC ("Percentual de desconto... guardado por
item") exigem um valor por item, não um único valor por pedido.
**Decisão**: coluna `desconto_pct` em `pedido_itens` (ver premissa de território na
seção 5).
**Alternativas consideradas**:
- Coluna única em `pedidos`, descartada porque não representa "por item" exigido pela
  SPEC.
**Consequências**: a leitura do detalhe (FR-001-004) soma ou lista por item, não expõe
um único percentual do pedido.
**Reabrir se**: a SPEC passar a definir o percentual no nível do pedido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-001-003: Estado do envio em tabela própria
**Contexto**: a SPEC trata "Envio" como conceito próprio (a chamada ao parceiro e seu
resultado), distinto do pedido, e FR-001-005 exige reenvio manual — múltiplas
tentativas do mesmo pedido.
**Decisão**: nova tabela `envios`, um registro por pedido, com contador de tentativas.
**Alternativas consideradas**:
- Colunas de estado direto em `pedidos`, descartada porque perde o histórico de
  tentativas do reenvio e mistura um conceito novo (Envio) na tabela existente.
**Consequências**: uma junção a mais para exibir o detalhe (COMP-001-008 lê
`pedidos` + `envios`).
**Reabrir se**: o produto pedir histórico completo de tentativas (não só a contagem) —
aí a tabela vira `envio_tentativas` (fora deste PLAN).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-001-004: Timeout de 5s sem o retry automático do HttpGateway
**Contexto**: NFR-001-001 exige que o envio aguarde no máximo 5s; `HttpGateway` já
aplica timeout e 1 retry em erro de rede, e o retry poderia estourar o teto de 5s.
**Decisão**: `ParceiroFreteClient` (COMP-001-003) chama `HttpGateway` com
`timeoutMs = 5000` e desativa o retry para esta chamada.
**Alternativas consideradas**:
- Manter o retry padrão do `HttpGateway`, descartada porque pode levar a chamada a mais
  de 5s e violar NFR-001-001.
**Consequências**: uma falha de rede transitória vira "pendente de envio" direto, sem
nova tentativa automática — coerente com FR-001-003, o reenvio automático está fora de
escopo da SPEC.
**Reabrir se**: `HttpGateway` ganhar um modo de retry com orçamento de tempo total
configurável.
**Irreversível**: não
**Aderência à ficha/perfil**: exceção (desvia do comportamento padrão do gateway
compartilhado, justificada pelo teto de tempo do NFR)

### DEC-001-005: Comprovante guardado via ArmazenamentoService/Anexo
**Contexto**: FR-001-006 exige guardar o comprovante devolvido pelo parceiro; o padrão
existente de guarda de arquivo é `ArmazenamentoService::guardar()` + entidade `Anexo`,
hoje só chamado pelo upload manual da tela de anexos.
**Decisão**: `ComprovanteService` (COMP-001-005) chama `ArmazenamentoService::guardar()`
com o conteúdo do comprovante e instancia `Anexo(arquivoId, tipo, pedidoId)`.
**Alternativas consideradas**:
- Criar um mecanismo de guarda de arquivo próprio para a integração, descartada porque
  duplica `ArmazenamentoService` sem necessidade.
**Consequências**: abre um segundo chamador de `guardar()`, vindo de contexto de job
(sem requisição HTTP/usuário autenticado no momento da chamada) — a implementação
confirma que `guardar()` não depende de contexto de request.
**Reabrir se**: `ArmazenamentoService::guardar()` mostrar dependência de contexto de
requisição que o job não tem.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

## 8. Riscos técnicos

- **TRISK-001-001** A forma real da resposta do parceiro diverge da premissa
  A-001-001 (`{status, prazo_dias, itens[].desconto_pct}`) (mitigação: `RespostaParceiro`
  isola o mapeamento em COMP-001-003; a primeira chamada real confirma a forma antes de
  fechar a TASK correspondente).
- **TRISK-001-002** O schema de `pedido_itens` assumido na seção 5 não bate com o real
  (mitigação: primeira TASK de implementação confirma a migration existente antes de
  escrever a nova coluna; PLAN não reabre por isso, só ajusta a TASK).
- **TRISK-001-003** Job em fila sem reprocessamento automático pode deixar um pedido
  "pendente de envio" indefinidamente se ninguém acionar o reenvio manual (mitigação:
  FR-001-005 cobre o caminho de correção; reenvio automático é out-of-scope explícito
  da SPEC, risco aceito por decisão do produto, não desta camada técnica).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Todos os ACs cobertos por teste

## 10. Não coberto por este PLAN

- nenhum
