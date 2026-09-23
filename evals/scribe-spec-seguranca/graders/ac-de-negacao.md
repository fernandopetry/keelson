---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck).

Contexto mínimo: a demanda é a exportação em planilha da carteira de clientes com dados
pessoais (nome, e-mail, telefone, CPF completo) pelo gerente comercial. O memo do código
diz que a tela é visível a dois papéis (gerente e operador) e que não existe registro de
quem baixou o quê. O brief não pede explicitamente o caso negativo.

Critério (responda só sobre isto):

- **PASS** se a SPEC contém ao menos um **AC** (seção 7) em que um ator **sem** o direito
  (ex.: operador, usuário de outra carteira, usuário sem a permissão de exportar) aciona
  a exportação e o sistema **recusa** de forma observável (mensagem, 403, botão ausente
  com tentativa direta bloqueada) — o "Então" descreve a recusa, não só o sucesso.
- **FAIL** se todos os ACs descrevem apenas o caminho de sucesso (gerente exporta e recebe
  o arquivo), mesmo que um FR mencione permissão em prosa sem AC correspondente.

Um NFR de segurança sozinho não satisfaz este eixo (o eixo é o AC de negação).
