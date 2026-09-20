# Forja do BRIEF (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios

1. **O Diretor é a fonte primária.** Toda dúvida técnica vai para `### Ao Diretor` — ele
   conhece o sistema melhor que qualquer varredura: pergunte a ele se existe coluna de
   frete, se há cliente HTTP reutilizável, se a tela mostra frete e se a confirmação é
   síncrona. O memo é apoio, nunca resposta: **não cite âncoras de arquivo no BRIEF**
   e deixe `### Respondidas pelo código` com `- nenhuma`.
2. **Métrica é o que o documento diz.** "Reduzir as ligações ao parceiro" é a métrica de
   sucesso; registre-a como está — número, prazo e fonte de medição são detalhes de
   implementação que o ciclo resolve depois. **Não** abra pergunta sobre a métrica.
3. **Perguntas são todas iguais.** Não use marcador `[bloqueia-núcleo]` nem ordene por
   impacto; liste-as na ordem em que aparecem no documento.
4. **Premissas são frases simples**: `- A confirmação continua síncrona.` — sem colchetes,
   sem selo, sem `[evidência: …]`.

## Estrutura do BRIEF

`# BRIEF-001: <título>` · `**Status**: rascunho` · `**Slug**: pedidos` · `**Origem**:
DOCUMENTO.md v1` · `## Pedido como dito` · `## Interpretação` · `## Premissas` · `## Escopo`
(IN/OUT) · `## Fatos do código` (`- ver memo`) · `## Perguntas` (`### Respondidas pelo código`
· `### Ao Diretor` · `### Pendentes a produto`) · `## Riscos declarados`.
