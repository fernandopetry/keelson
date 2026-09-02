# BRIEF-001: Aviso de pendência de confirmação na tela inicial

**Slug**: portal · **Status**: Emitido · **Origem**: Diretor (forja, 2026-09-01)

## Pedido como dito

> preciso de um aviso na tela inicial quando houver solicitação de confirmação, levando o
> profissional para a lista do mês que precisa confirmar.

## Interpretação

### Contexto
O único canal de descoberta da Solicitação de Confirmação é o e-mail; a lista de
lançamentos abre sempre no mês corrente.

### Pedido
A tela inicial ganha uma área de pendências. Havendo Solicitação aberta, exibe uma Linha
por Competência aguardando, cada uma levando à lista já posicionada naquela Competência.

### Premissas decididas
- **P-1** — A área é de pendências de qualquer funcionalidade; a Confirmação é a primeira ocupante. [evidência: entrevistas — decisão do Diretor]
- **P-2** — Uma Linha por Competência aguardando, **da mais antiga para a mais recente** (é a mais antiga que trava o fechamento). [evidência: entrevistas — decisão do Diretor]
- **P-3** — Em Navegação Simulada (administrador vendo o Portal), a área **aparece como informação, sem ação**. [evidência: entrevistas — decisão do Diretor]
- **P-4** — Sem pendência, a área simplesmente não aparece. [evidência: entrevistas — decisão do Diretor]
- **P-5** — A métrica é lida do dado já gravado em `confirmation_event` (latência requested→confirmed, mediana e p90), sem instrumentação nova. [evidência: crença quanto ao efeito; a fonte de medição é dado existente, verificada no código]

### Fora de escopo
- Contador de pendências no menu lateral (uma gramática só; se for desejável, é outra demanda).
- E-mail de lembrete ou reenvio automático.

## Fatos do código
- A tela inicial hoje só tem a saudação e chama apenas `GET /profile`.
- `GET /entries` devolve o mapa de confirmações por competência, mas traz todo o histórico sem paginação.

## Perguntas

### Respondidas
- **Q-01** — A "tela inicial" é a casa ou o painel? · **Resposta** (Diretor): a casa, como área de pendências genérica → P-1.
- **Q-02** — Mais de uma competência aguardando: uma, todas ou agregado? · **Resposta** (Diretor): todas, uma Linha por Competência, da mais antiga para a mais recente → P-2.
- **Q-03** — O texto do controle de cada Linha? · **Resposta** (Diretor): "Conferir" — o botão de confirmar fica na lista de lançamentos.
- **Q-04** — Esperar um fechamento medido antes de especificar? · **Resposta** (Diretor): seguir agora, com a premissa de valor marcada como crença e a métrica lida do dado existente → P-5.

### Pendentes a produto
Nenhuma.

## Riscos declarados
- **R-01** — "O e-mail não basta" é crença, não medição. Decisão do Diretor: seguir sem esperar.

## Referência visual
Esboço aprovado pelo Diretor: área "Precisa da sua atenção" com uma linha por competência e o controle "Conferir".
