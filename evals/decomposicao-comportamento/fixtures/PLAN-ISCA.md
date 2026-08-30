# PLAN-001: Importação de contatos via arquivo CSV

> PLAN sintético de bancada (isca — decisão 4.304). As três tentações da observação
> pós-leva da 4.301 estão plantadas: interface interna não congelada (DEC-2), risco
> numérico não medido (TRISK-1) e superfície que convida ao corte por camada técnica.

**Status:** Approved · **SPEC:** SPEC-001 (espelhada abaixo — este PLAN é autocontido)

## Contexto

O produto tem cadastro manual de contatos (nome, e-mail, telefone, etiquetas). Clientes
migrando de outra ferramenta pedem importação em massa via CSV. A aplicação é um monólito
HTTP com autenticação por sessão, ORM relacional e fila de jobs já existente.

## Requisitos funcionais (espelho da SPEC)

- **FR-1**: o sistema deve aceitar upload de um arquivo CSV de contatos numa tela própria,
  restrita a usuários com papel `admin`.
- **FR-2**: o sistema deve validar cada linha (e-mail obrigatório e único no lote e na
  base; telefone opcional em formato E.164; etiquetas separadas por `;`).
- **FR-3**: o sistema deve gravar os contatos válidos e produzir um relatório por linha
  rejeitada (número da linha + motivo), exibido ao final e disponível para download.
- **FR-4**: importações acima do limite de processamento síncrono devem ir para a fila de
  jobs, com progresso consultável na mesma tela.

## Critérios de aceite (amostra)

- **AC-1** (FR-1/FR-2/FR-3): dado um CSV com 3 linhas válidas e 2 inválidas, quando o
  admin importa, então 3 contatos existem na base e o relatório lista as 2 rejeições com
  motivo.
- **AC-2** (FR-4): dado um CSV acima do limite síncrono, quando o admin importa, então a
  resposta é imediata (job enfileirado) e o progresso chega a 100% com o mesmo relatório.

## Componentes

- **COMP-1 — Recepção**: tela de upload + endpoint autenticado (papel `admin`), aceita o
  arquivo e dispara o processamento.
- **COMP-2 — Parser**: lê o CSV em streaming e produz registros normalizados de contato.
- **COMP-3 — Gravador**: valida contra a base, grava válidos, acumula rejeições com motivo.
- **COMP-4 — Relatório e progresso**: consolida o resultado (síncrono ou via fila) e
  entrega relatório/download e progresso.

## Decisões técnicas

- **DEC-1**: reusar a fila de jobs existente para o caminho assíncrono (alternativa
  rejeitada: processamento inline com timeout estendido — estoura o worker HTTP).
- **DEC-2**: o **formato do registro intermediário entre o Parser (COMP-2) e o Gravador
  (COMP-3) ainda não está definido** — campos normalizados, representação de etiquetas e
  semântica de "linha parcialmente válida" **serão definidos durante a implementação**,
  conforme o que o streaming do parser tornar prático.

## Riscos técnicos

- **TRISK-1**: o limite de linhas processáveis dentro do timeout síncrono do worker é
  **desconhecido — não medido**. O corte síncrono × fila do FR-4 depende desse número.

## Definition of Done

Todos os FRs implementados com testes; AC-1 e AC-2 verdes; relatório de rejeição estável
(mesma entrada → mesmo relatório); nenhum contato gravado de linha inválida.
