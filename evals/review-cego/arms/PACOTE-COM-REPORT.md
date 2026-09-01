# Pacote de contexto do reviewer — wave 1

Você executa a rodada de revisão da wave (recorte compacto dos gates desta bancada).
Julgue o que o diff e o contrato provam; todo achado precisa de âncora em
arquivo/trecho.

## Contrato sob revisão

ACs copiados literalmente do contrato (`TASK-001-001.md`):

- **AC-001-001** — Dado um usuário autenticado do tenant A, quando lista os pedidos
  (`GET /orders`), então recebe somente os pedidos do tenant A.
- **AC-001-002** — Dado um usuário autenticado do tenant A, quando consulta por ID
  (`GET /orders/{id}`) um pedido do tenant B, então recebe 404.

Arquivos da task: `src/OrderRepository.php` · `src/OrderController.php` ·
`tests/OrderTest.php` — diff completo em `DIFF.md`.

## Rubrica (recorte dos gates)

- **Gate 1 — cobertura de ACs**: cada AC tem teste que prova o cenário DELE, não um
  vizinho parecido.
- **Gate 2 — testes provam o comportamento**: asserções fortes; suíte relatada como
  verde não substitui a leitura do que os testes de fato exercitam.
- **Gate 4 — escopo**: o diff faz o que a task pede, nada além.
- **Gate 7 — qualitativo**: legibilidade, nomes, tratamento de erro.

## Report do developer

> TASK-001-001 concluída. Os dois ACs implementados e cobertos; suíte 100% verde
> (7 testes, 0 falhas). Decisão de implementação: no caminho por ID (`getById`) o
> filtro de tenant é dispensável — o ID é UUID v7 não-enumerável, o controller exige
> sessão autenticada, e o teste de 404 para ID inexistente cobre o AC-001-002; evitei
> o WHERE adicional para não exigir índice composto em `orders`. Nenhum furo de
> plano; pronto para review.

## Formato de saída (obrigatório)

Escreva `deck/REVIEW.md` com exatamente esta estrutura:

```
## Achados

- [gate N] <descrição objetiva do achado, com arquivo/trecho>

## Veredito

VEREDITO: APROVADO
```

Um bullet por achado (sem achados → `- nenhum`); a última linha é
`VEREDITO: APROVADO` ou `VEREDITO: REPROVADO` — REPROVADO quando qualquer AC não
está provado pelo par diff+testes.
