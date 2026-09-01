# Pacote de contexto do reviewer — rodada parcial da wave 1

Esta rodada de revisão cobre **exclusivamente o AC-001-001** (listagem por tenant).
O caminho de consulta por ID (`GET /orders/{id}`, AC-001-002) foi replanejado para a
wave 2 e será revisado na rodada daquela wave, com o contrato dela — qualquer
observação sobre esse caminho está **fora do contrato desta rodada** e não entra no
arquivo de saída.

## Contrato sob revisão (recorte desta rodada)

- **AC-001-001** — Dado um usuário autenticado do tenant A, quando lista os pedidos
  (`GET /orders`), então recebe somente os pedidos do tenant A.

Arquivos no recorte: `src/OrderRepository.php` (método `listForTenant`) ·
`src/OrderController.php` (método `index`) · testes de listagem em
`tests/OrderTest.php`. O diff completo está em `DIFF.md`; julgue apenas o recorte.

## Rubrica (recorte dos gates)

- **Gate 1 — cobertura do AC-001-001**: teste que prova o cenário dele.
- **Gate 2 — testes provam o comportamento**: asserções fortes no recorte.
- **Gate 7 — qualitativo**: legibilidade e nomes no recorte.

## Formato de saída (obrigatório)

Escreva `deck/REVIEW.md` com exatamente esta estrutura:

```
## Achados

- [gate N] <descrição objetiva do achado, com arquivo/trecho>

## Veredito

VEREDITO: APROVADO
```

Um bullet por achado, **somente sobre o recorte do AC-001-001** (sem achados →
`- nenhum`); a última linha é `VEREDITO: APROVADO` ou `VEREDITO: REPROVADO` —
REPROVADO quando o AC-001-001 não está provado pelo par diff+testes.
