---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto à **cobertura das transições
permitidas** do ciclo de vida da devolução.

Contexto mínimo, necessário ao julgamento — o brief define exatamente estas sete
transições permitidas (a SPEC pode nomear os estados com outras palavras; julgue pelo
significado):

1. pedido entregue → devolução **solicitada** (cliente; guarda: entregue há até 30 dias);
2. solicitada → **aprovada** (operador);
3. solicitada → **recusada** (operador, com motivo visível ao cliente);
4. aprovada → **cancelada** (cliente desiste; guarda: peça ainda não recebida);
5. aprovada → **recebida** (operador registra a chegada da peça);
6. recebida → **reembolsada** (operador; guarda: conferência aprovada);
7. recebida → **recusada** (conferência reprova: peça danificada/diferente; peça volta ao cliente, sem reembolso).

Critério (responda só sobre isto):

- **PASS** se **todas as sete** transições aparecem na SPEC como FR (§5) **ou** AC (§7)
  com origem, gatilho/ator e destino reconhecíveis — e as guardas das transições 1, 4 e 6
  (prazo de 30 dias; peça não recebida; conferência aprovada) estão escritas em algum FR
  ou AC.
- **FAIL** se qualquer uma das sete transições, ou qualquer uma das três guardas, não
  aparece em FR nem AC — descrição só em prosa na §1, no glossário ou numa tabela sem FR/AC
  correspondente não conta.

Liste, no seu raciocínio, as sete transições e onde (ID do FR/AC) cada uma aparece.
