# INDEX.md — pedidos (trecho)

## Riscos ativos
| Risco | Origem | Estado |
|---|---|---|
| R1 — Migration `2026_09_02_pedidos_relatorio` pendente de deploy (pré-requisito do código) | PLAN-003 | aberto |
| R2 — Verificação de tela pendente — HANDOFF-PLAN-003 | closure TASK-003-002 | aberto |
| R3 — Índice `idx_pedidos_tenant_data` faltante (consulta lenta acima de 50k pedidos) | TRISK-003-001 | aberto |
| R4 — Veredito de métrica da SPEC-003 §1.3 pendente (medir em 30 dias) | SPEC-003 | aberto |

## Histórico recente
- 2026-09-02 10:30: TASK-003-003 closure — migration cria `idx_pedidos_tenant_data`.
