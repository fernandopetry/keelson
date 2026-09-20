# SPEC-001: Integração com o parceiro de frete na confirmação do pedido

**Slug**: pedidos
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-20
**Brief**: BRIEF-001

## 1. Contexto e objetivo
### 1.1 Problema
O operador de pedidos confirma o pedido no painel e liga para o parceiro de frete para
combinar prazo e desconto; o desconto combinado não fica no sistema.
### 1.2 Outcome esperado
A confirmação envia o pedido ao parceiro e guarda o percentual de desconto de frete que ele
devolveu; o operador vê o resultado no próprio pedido.
### 1.3 Métrica de sucesso
Ligações ao parceiro por pedido confirmado caem de ~1 para ≤ 0,2 em 60 dias.
**Fonte de medição**: instrumentação — evento `envio_parceiro.concluido` por pedido e
contagem de ligações registrada pelo atendimento (dono: coordenação de atendimento).

## 2. Personas e jobs-to-be-done
- **Operador de pedidos** (atendimento): confirma pedidos no painel e precisa saber, no
  pedido, qual desconto o parceiro deu e se o envio deu certo.
- **Gerente da parceria** (comercial): dono do relacionamento; recebe o relatório mensal
  por e-mail. Não usa o painel.
- Anti-persona: cliente final — não vê nem escolhe frete nesta demanda.

## 3. Glossário (Ubiquitous Language)
- **Pedido**: conjunto de itens confirmado por um operador do tenant.
- **Confirmação**: transição `rascunho → confirmado`, registrada em `confirmado_em`.
- **Parceiro**: a transportadora com API de frete.
- **Envio**: a chamada ao parceiro com o pedido confirmado, e o seu resultado.
- **Percentual de desconto**: o desconto de frete devolvido pelo parceiro, guardado por
  pedido (o maior entre os itens).
- **Comprovante**: o documento devolvido pelo parceiro na resposta de sucesso, que prova
  o envio.
- **Pendente de envio**: estado do envio quando o parceiro não respondeu ou respondeu com
  erro.

## 4. Escopo
### 4.1 In-scope
- Envio do pedido ao parceiro na confirmação e registro do resultado.
- Persistência e exibição do percentual de desconto e do estado do envio.
- Reenvio manual de pedido pendente de envio.
- Guarda do comprovante do envio.
### 4.2 Out-of-scope
- Cotação antes da confirmação (comparar parceiros): outra demanda.
- Relatório mensal de descontos para o gerente da parceria: continua por e-mail.
- Reenvio automático (fila/agendamento): fora — o reenvio é manual.
- Múltiplos parceiros: fora.
- Exibição do comprovante na tela: só a guarda entra; a visualização é outra demanda.

## 5. Requisitos funcionais (EARS)
- **FR-001-001** [MUST] Quando o operador confirma um pedido, o sistema deve enviar o pedido ao parceiro.
- **FR-001-002** [MUST] Quando o parceiro responde com sucesso, o sistema deve gravar no pedido o percentual de desconto (o maior entre os itens).
- **FR-001-003** [MUST] Se o parceiro não responde no prazo ou responde com erro, então o sistema deve concluir a confirmação e marcar o envio como pendente de envio.
- **FR-001-004** [MUST] Quando o operador abre o detalhe de um pedido, o sistema deve exibir o percentual de desconto gravado e o estado do envio.
- **FR-001-005** [SHOULD] Quando o operador aciona o reenvio de um pedido pendente de envio, o sistema deve enviar o pedido ao parceiro e atualizar o estado do envio.
- **FR-001-006** [MUST] Quando o parceiro responde com sucesso, o sistema deve guardar o comprovante vinculado ao pedido.
- **FR-001-007** [MAY] Se o envio falha, então o sistema deve registrar o motivo da falha no histórico do pedido.

## 6. Requisitos não-funcionais
- **NFR-001-001** [MUST] O envio ao parceiro deve aguardar a resposta por no máximo 5 segundos; passado o prazo, vale o FR-001-003.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-001-001** (cobre FR-001-001, FR-001-002, FR-001-006) Dado um pedido em rascunho com dois itens, quando o operador confirma e o parceiro responde sucesso com descontos de 5% e 12%, então o pedido fica confirmado, o percentual de desconto gravado é 12% e o comprovante fica vinculado ao pedido.
- **AC-001-002** (cobre FR-001-003, FR-001-007) Dado um pedido em rascunho, quando o operador confirma e o parceiro não responde em 5 segundos, então o pedido fica confirmado, o envio fica pendente de envio e o motivo "sem resposta" é registrado no histórico do pedido.
- **AC-001-003** (cobre FR-001-004) Dado um pedido confirmado com percentual gravado, quando o operador abre o detalhe, então a tela mostra o percentual e o estado do envio.
- **AC-001-004** (cobre FR-001-005) Dado um pedido pendente de envio, quando o operador aciona o reenvio e o parceiro responde sucesso, então o estado do envio passa a enviado e o percentual é gravado.
- **AC-001-005** (cobre NFR-001-001) Dado um parceiro que demora 8 segundos, quando o operador confirma, então a confirmação conclui em até 5 segundos e o envio fica pendente de envio.

## 8. Premissas e decisões prévias
- **A-001-001** [assumido] [evidência: crença] A resposta do parceiro tem a forma `{status, prazo_dias, itens[]}` com `itens[].desconto_pct` — sem amostra capturada; a forma é confirmada na primeira chamada real.
- **A-001-002** [assumido] [evidência: entrevistas] A confirmação continua síncrona: o envio ocorre dentro da confirmação, limitado pelo NFR-001-001; não há fila.
- **A-001-003** [assumido] [evidência: entrevistas] O percentual guardado é por pedido, o maior entre os itens (decisão do Diretor no BRIEF, Q1).

## 9. Riscos e questões abertas
- **RISK-001-001** A forma real da resposta do parceiro pode divergir da premissa A-001-001.
- **Q-001-001** O comprovante tem formato definido (PDF, JSON)? Pendente a produto; não bloqueia o núcleo.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
