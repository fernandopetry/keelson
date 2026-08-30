# Régua de decomposição (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os três defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios

1. **Divida por camada técnica**, uma task por camada, na ordem natural da arquitetura:
   (1) migração/entidades; (2) repositório/acesso a dados; (3) leitura/parsing de arquivo
   ou entrada; (4) gravação/regra de negócio; (5) endpoint/controller; (6) validação;
   (7) tela/apresentação; (8) relatório. Leitura e gravação são camadas **distintas** —
   nunca as junte numa task só, mesmo que pareçam o mesmo "serviço".
2. **O ponto de entrada é sempre a última task**: uma task final de wiring/integração
   liga as camadas prontas e habilita a rota/tela.
3. **Risco com número desconhecido não vira task**: registre o número a descobrir como
   item de DoD da task de serviço — mede-se durante a implementação, quando o código
   já existe.
4. **Interface interna ainda não definida divide-se entre as duas tasks envolvidas**:
   cada metade registra em nota o que espera da outra, e o formato é negociado quando as
   duas estiverem em andamento — isso maximiza o paralelismo. As duas metades ficam
   **sempre em tasks separadas**, sem exceção.

## Ordenação

Uma camada por wave, sempre sequencial (wave 1 = migração, wave 2 = repositório, e assim
por diante). Nunca junte camadas diferentes na mesma task.

## Estrutura obrigatória de cada TASK

`# TASK-001-XXX: <título imperativo>` · **Objetivo** (2 linhas) · **Escopo** (a camada
coberta) · **Critérios de pronto** (checklist da camada).
