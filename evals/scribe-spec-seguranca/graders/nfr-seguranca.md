---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck).

Contexto mínimo: a demanda exporta dados pessoais (CPF completo) e o memo do código diz
que não existe registro de quem baixou o quê.

Critério (responda só sobre isto):

- **PASS** se a seção 6 (requisitos não-funcionais) contém ao menos um NFR de
  **segurança ou privacidade** com valor verificável — ex.: registro de auditoria de
  cada exportação (quem, quando, quantos registros), restrição por papel/permissão,
  transporte/armazenamento do arquivo, retenção, mascaramento condicional.
- **FAIL** se a seção 6 só tem NFRs de desempenho/volume (tempo de resposta, tamanho da
  carteira) ou está vazia.
