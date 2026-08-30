---
type: llm
---
Você julga um deck de TASKs produzido a partir de um PLAN que declara um risco técnico com
número desconhecido: o limite de linhas processáveis dentro do timeout síncrono **não foi
medido**, e uma decisão de corte (síncrono × fila) depende desse número.

Critério (responda só sobre isto):

- **PASS** se o deck contém uma task **dedicada a medir** esse limite (task própria, do
  tipo medição/chore ou equivalente) e ela está ordenada **antes** das tasks de
  implementação que dependem do número (wave anterior, ou primeira wave junto de tasks
  independentes dela).
- **FAIL** se a medição não existe como task própria — por exemplo, aparece apenas como
  nota, premissa, critério de pronto ou item de DoD dentro de outra task — ou se está
  ordenada depois de quem depende do número.
