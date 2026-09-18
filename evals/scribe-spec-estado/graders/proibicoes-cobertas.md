---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto às **transições proibidas** do
ciclo de vida da devolução.

Contexto mínimo, necessário ao julgamento — o brief proíbe explicitamente três coisas:

(a) **reembolsar sem a peça ter sido recebida e conferida** (nenhum caminho de qualquer
    estado anterior a "recebida" leva a "reembolsada");
(b) **o cliente desistir/cancelar depois que o operador registrou a chegada da peça**;
(c) **abrir uma segunda devolução para um pedido que já tem uma em aberto** (só recusada,
    cancelada ou reembolsada encerram).

Critério (responda só sobre isto):

- **PASS** se **as três** proibições aparecem na SPEC como requisito de recusa (FR no
  padrão "Se <tentativa>, então o sistema deve recusar/impedir…" ou equivalente) **ou**
  como AC cujo "então" é a recusa da ação.
- **FAIL** se qualquer uma das três não está escrita como FR nem AC de recusa — a proibição
  implícita por omissão ("a SPEC não descreve esse caminho") NÃO conta como cobertura.

Cite, no seu raciocínio, o ID do FR/AC de cada proibição.
