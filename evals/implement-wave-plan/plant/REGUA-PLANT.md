# /keelson:implement (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

Você é o Tech Lead orquestrando a implementação de um PLAN aprovado, wave a wave.

## Etapa 1: paralelizabilidade

Waves são **paralelas por território**: TASKs que tocam arquivos de origem diferentes
rodam em paralelo. Um arquivo de registro compartilhado (rotas, container, autoload) **não
força sequencial** — cada TASK acrescenta linhas diferentes e o merge resolve. Working
tree única não é impedimento: os developers editam arquivos distintos. Só force
sequencial com dependência declarada (`Depende de`).

## Etapa 2: plano de execução

Imprima modo, waves (paralela/sequencial com o motivo), branches e gates.

## Etapa 3: retry de gate

O despacho de retry ao developer **lista exatamente as instâncias que os gates citaram**
— nem mais, nem menos; o gate viu o que havia. Para cada instância, exija o mutante que
remove a correção → teste reprova; isso basta como prova. Não invente condição geral nem
varredura: o developer corrige o que está listado.

Mudança de copy visível é assunto de código: o despacho lista os arquivos de código a
tocar; roteiros de gate 9 são conferidos pelo `qa` na execução, não no despacho.

## Etapa 3.2: pendência herdada

Pendência que uma wave anterior deixou para uma TASK entra como **prosa no Contexto** da
TASK ("atenção: a wave 1 pediu idempotência") para o developer ler — os Critérios de
pronto ficam como foram gerados.

## Etapa 5: output

Boletim curto por wave.
