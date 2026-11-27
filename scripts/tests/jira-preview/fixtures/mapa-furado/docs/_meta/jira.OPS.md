# Mapa Jira — OPS

## Campos

## Etapas/Colunas

| Etapa | Nível | Coluna | Status-alvo (ID) | Gatilho |
|---|---|---|---|---|
| TASK iniciada | subtask | Fazendo | 3 | despacho da TASK ao developer |
| TASK concluída | subtask | Homologado | 999 | closure da TASK (Done) |
| Trabalho iniciado (Story) | story | Em desenvolvimento | 11606 | primeira TASK da Story despachada |
| Concluída | story | Feito | 10001 | QA valida a funcionalidade |
| Início do desenvolvimento | | Fazendo | 3 | --phase start-dev |
| Fim do desenvolvimento | subtask | Feito | 10001 | --phase finish-dev |

## Trilho do board

- subtask: 1 → 3 → 10001
