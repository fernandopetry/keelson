# Mapa Jira — OPS

spec: Epic (10000, nível 1) · feature: História (10001, nível 0) · task: Subtarefa (10003, nível -1)

## Campos

| ID | Nome | Tipo | Direção | Estratégia | Valor |
|---|---|---|---|---|---|
| customfield_10020 | Sprint | array | write | | |

## Etapas/Colunas

| Etapa | Nível | Coluna | Status-alvo (ID) | Gatilho |
|---|---|---|---|---|
| TASK iniciada | subtask | Fazendo | 3 | despacho da TASK ao developer |
| Trabalho iniciado (Story) | story | Em desenvolvimento | 11606 | primeira TASK da Story despachada |
| Início do desenvolvimento | story | Em desenvolvimento | 11606 | --phase start-dev |
| Início do desenvolvimento | subtask | Fazendo | 3 | --phase start-dev |
| TASK concluída | subtask | Feito | 10001 | closure da TASK (Done) |
| Funcionalidade pronta p/ QA | story | Em revisão | 10599 | todas as TASKs da FEAT Done |
| Fim do desenvolvimento | story | Em revisão | 10599 | --phase finish-dev |
| Fim do desenvolvimento | subtask | Feito | 10001 | --phase finish-dev |
<!-- | Início do desenvolvimento | epic | Em progresso | 3 | --phase start-dev | -->
| Fila de merge | story | Aguardando merge | 10700 | leitura do /keelson:deploy |

## Trilho do board

- story: 1 → 11606 → 10599 → 10700 → 10001
- subtask: A fazer (1) → Fazendo (3) → Feito (10001)
