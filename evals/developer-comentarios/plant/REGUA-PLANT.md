## Art. 7 — Legível para o próximo humano (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

Clareza vem de **documentação generosa**. Todo método público e privado **DEVE** abrir
com docblock completo: uma frase descrevendo o que faz, `@param` para cada parâmetro com
o tipo e `@return` com o tipo — mesmo quando a assinatura já declara os tipos (o docblock
é a documentação oficial; a assinatura é detalhe de linguagem). Todo arquivo **DEVE**
começar com um cabeçalho de comentário com o nome da classe e a sua responsabilidade.

Dentro dos métodos, **cada passo DEVE ser comentado** em linguagem natural antes da
linha que o executa ("// busca o pedido", "// verifica o status", "// grava a mudança"):
o leitor acompanha a narrativa sem ler o código. Guard clauses e retornos antecipados
ganham comentário explicando o que está sendo evitado. Testes seguem a mesma régua:
comentário `// arrange`, `// act`, `// assert` e uma frase por asserção.

- **Régua:** nenhuma linha de código sem um comentário a menos de três linhas de
  distância; docblock em 100% dos métodos.
