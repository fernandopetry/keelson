# SPEC-001: Exportação de pedidos

**Slug**: corpus
**Status**: Approved
**Versão**: 0.2
**Autor**: Fernando
**Data**: 2026-08-10

## 1. Contexto e objetivo

### 1.1 Problema

Operadores extraem pedidos manualmente, tela a tela, para fechar o expediente — o
levantamento de um dia inteiro consome perto de uma hora e sai com lacunas.

### 1.2 Outcome esperado

Exportação completa do período solicitada em um passo, com aviso quando o arquivo
está pronto.

### 1.3 Métrica de sucesso

Reduzir o tempo de fechamento diário de 60 para 10 minutos até 2026-11-01.

**Fonte de medição**: instrumentação — evento de fechamento emitido pelo produto

## 2. Personas e jobs-to-be-done

- Operador: extrair os pedidos do período para conferência.
- Supervisor: receber o aviso de conclusão sem vigiar a tela.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| **Exportação** | Arquivo consolidado com os pedidos do período solicitado | esta SPEC |
| **Solicitação** | Pedido de geração de uma exportação, com período e filtros | esta SPEC |
| **Aviso de conclusão** | Mensagem ao solicitante quando a exportação fica pronta | esta SPEC |
| **Operador, Pedido** *(reutilizados, sem redefinição)* | Ver glossário consolidado do INDEX.md do slug | INDEX |

## 4. Escopo

### 4.1 In-scope

- Solicitação de exportação por período e filtros
- Geração assíncrona do arquivo de exportação
- Aviso de conclusão ao solicitante, com reenvio

### 4.2 Out-of-scope

- Agendamento recorrente de exportações
- Exportação de dados de clientes fora de pedidos

## 5. Requisitos funcionais (EARS)

### FEAT-001-001: Geração da exportação

> Operador solicita a exportação de um período e recebe o arquivo consolidado.

- **FR-001-001** [MUST] Quando o operador submete uma solicitação com período válido, o sistema DEVE registrar a solicitação e iniciar a geração da exportação.
- **FR-001-002** [MUST] Enquanto uma solicitação do mesmo operador está em andamento, o sistema DEVE recusar nova solicitação idêntica.
- **FR-001-003** [SHOULD] O sistema deve limitar cada exportação a cem mil pedidos,
  e DEVE orientar a divisão do período quando o limite é excedido.

### FEAT-001-002: Aviso de conclusão

> Solicitante é avisado quando a exportação fica pronta, sem vigiar a tela.

- **FR-001-004** [MUST] Quando a geração de uma exportação termina, o sistema DEVE
  enviar o aviso de conclusão ao solicitante com o endereço de retirada do
  arquivo.
- **FR-001-005** [SHOULD] Quando o solicitante pede reenvio, o sistema deve enviar novamente o aviso de conclusão da última exportação pronta.
- **FR-001-006** [MAY] Se o arquivo não é retirado em sete dias, então o sistema deve expirar o endereço de retirada.

## 6. Requisitos não-funcionais

- **NFR-001-001** [MUST] O sistema deve concluir exportação de até dez mil pedidos em até 5 minutos.
- **NFR-001-002** [SHOULD] O sistema deve registrar cada solicitação com carimbo de data em até 1 segundo.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-001-001** (cobre FR-001-001)
  **Dado** um operador autenticado,
  **Quando** submete uma solicitação com período válido,
  **Então** a solicitação é registrada e a geração inicia.
- **AC-001-002** (cobre FR-001-002)
  **Dado** um operador com solicitação em andamento,
  **Quando** submete solicitação idêntica,
  **Então** o sistema recusa e aponta a solicitação em andamento.
- **AC-001-003** (cobre FR-001-004) Dado uma exportação recém-concluída, quando a geração termina, então o solicitante recebe o aviso de conclusão com o endereço de retirada.
- **AC-001-004** (cobre FR-001-006)
  **Dado** um arquivo pronto há mais de sete dias sem retirada,
  **Quando** o solicitante abre o endereço de retirada,
  **Então** o acesso é negado com a orientação de nova solicitação.
- **AC-001-005** (cobre FR-001-005) Dado uma exportação pronta, quando o solicitante pede reenvio, então o aviso de conclusão é enviado novamente ao mesmo destino.
- **AC-001-006** (cobre FR-001-003)
  **Dado** um período com mais de cem mil pedidos,
  **Quando** a geração conta os pedidos do período,
  **Então** a exportação é interrompida com a orientação de divisão do período.

## 8. Premissas e decisões prévias

- [confirmado] [evidência: medido] O volume diário fica abaixo de dez mil pedidos em 95% dos dias.
- [assumido] [evidência: entrevistas] O aviso de conclusão pelo canal corporativo existente alcança todos os operadores.

## 9. Riscos e questões abertas

- **RISK-001-001** Período muito largo pode gerar arquivo além do limite operacional.
- **RISK-001-002** Aviso de conclusão tratado como indesejado pelo canal corporativo.

## 10. Fora deste documento

- Política de retenção dos arquivos gerados.
- Formato interno do arquivo de exportação.
