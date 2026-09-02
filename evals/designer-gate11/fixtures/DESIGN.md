# Design / UX (core)

> Princípios de design de interface **agnósticos de stack**. Instanciam o **Art. 10**
> (a interface tem o mesmo padrão do código que a serve) do `../_meta/QUALITY-CHARTER.md`.
> Aplicar quando a mudança toca superfície de interface (tela, componente, estilo,
> copy, formulário, fluxo). Os mecanismos **concretos** (biblioteca de componentes,
> sistema de tokens, ferramenta de auditoria de contraste) ficam no perfil de linguagem.
>
> Este arquivo é o **gabarito do gate 11** (design — decisão 4.218): o
> `product-designer` o lê em runtime, nunca o replica (padrão da 4.20), e o `developer`
> o lê **antes** de codar superfície de UI (prevenção, espelho do reúso da 4.207).
> Padrão descuidado deste catálogo é achado **bloqueante** no review; refinamento além
> dele só entra **ancorado** num padrão existente do produto — sem âncora, é sugestão,
> nunca reprovação.

---

## Hierarquia e composição

- **Uma ação primária por vista:** o destaque visual máximo pertence a uma ação só;
  as demais são secundárias. Teste: apertando os olhos, dá para apontar o título e a
  ação principal — se tudo tem o mesmo peso, nada tem.
- **Espaçamento pela escala:** todo afastamento vem da escala do projeto (a do design
  system; na falta dela, múltiplos de uma base única). Valor solto fora da escala
  convivendo com valores da escala = achado.
- **Alinhamento intencional:** os elementos da vista se ancoram numa malha comum;
  "quase alinhado" (deslocamento de poucos px sem intenção declarada) = achado.
- **Tipografia com escala curta:** tamanhos e pesos vêm da escala tipográfica
  existente; vista nova não introduz tamanho novo sem motivo declarado.

## Estados e feedback

- **Toda vista de dados trata os quatro estados: vazio, carregando, erro, populado.**
  Vista nova sem os quatro = achado bloqueante. O vazio orienta o próximo passo do
  usuário, não anuncia apenas "nenhum registro".
- **Controles têm estados interativos visíveis** (hover/focus/active/disabled) — botão
  que não reage ao ponteiro parece quebrado antes de ser clicado.
- **Toda ação tem resposta perceptível:** operação longa mostra progresso; sucesso e
  falha de operação assíncrona são comunicados onde o usuário está, não só no console.
- **Erro na linguagem do usuário:** diz o que aconteceu e o que fazer; detalhe técnico
  (stack, código interno) vai para o log, não para a tela. O veto a ID de artefato SDD
  em copy é do gate 7 (`CODE-REVIEW.md`) — este item cobre o restante do texto.

## Consistência com o produto

- **Reúso antes de criação (Art. 3 aplicado à UI):** antes de criar componente ou
  padrão, procure o equivalente existente no produto/design system declarado —
  variação de padrão existente sem motivo = achado com ponteiro para o canônico.
- **Tokens, não literais:** cor, fonte, raio e sombra vêm dos tokens do projeto quando
  existem; valor cru duplicando um token = achado.
- **Mesma operação, mesmo gesto:** confirmação de ação destrutiva, posição de botões,
  ordem de formulário seguem o padrão que o produto já estabeleceu.

## Acessibilidade (piso, não teto)

- **Contraste AA:** 4.5:1 para texto normal; 3:1 para texto grande e componentes de UI.
- **Teclado:** o fluxo principal se completa por teclado, com foco visível e ordem de
  tabulação seguindo a leitura.
- **Nome acessível:** todo controle tem rótulo; ícone sozinho tem rótulo textual;
  imagem informativa tem alternativa em texto.
- **Nunca só cor:** estado ou informação não se transmite apenas por cor.

## Formulários

- **Rótulo visível sempre** — placeholder não é rótulo (some ao digitar).
- **Validação perto do campo e na hora certa;** o erro preserva o que o usuário já
  digitou.
- **Campos agrupados pela lógica de quem preenche**, não pela estrutura da tabela.

---

## Régua

- **Régua (Art. 10):** toda vista de dados nova trata vazio/carregando/erro; nenhum
  componente reinventa padrão que o produto já tem; toda ação tem resposta
  perceptível; contraste e teclado no piso AA.
- **Anti-falso-positivo:** além do catálogo, achado só entra **ancorado** num padrão
  existente do produto (componente canônico, token, tela de referência citada) —
  preferência pessoal de quem revisa não reprova, e redesign especulativo nunca é
  exigência do gate. Consistência com o produto vence o gosto do revisor.
