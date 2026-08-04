# Protocolo do menor teste de valor

> Fonte única (decisão 4.100) da receita que o `po` lê **no disparo** da instância
> nomeada do critério 1: premissa de **valor** com selo fraco (`crença`/`anedota` —
> decisão 4.96) sustentando o núcleo da demanda. Fora desse disparo, nenhuma sessão
> paga este arquivo. O ciclo **não faz discovery**: ele detecta e formaliza a lacuna
> de evidência; quem a resolve é a área de produto.

## Quando isto dispara

Três condições, todas necessárias:

1. A premissa é de **valor** ("o usuário quer/usa/paga por isso"), não de execução
   ("a API aguenta o volume" é TRISK, não valor).
2. O selo dela é `crença` ou `anedota` (4.96) — não há evidência sistemática.
3. Ela sustenta o **núcleo** da demanda: se cair, o resultado muda (critério 1 do PO).
   Premissa fraca em detalhe periférico não escala — registra e segue.

## A forma da escalação

Pergunta formal **à área de produto**, endereçada via Diretor, sempre com proposta +
default (contrato do PO):

- **Proposta**: o menor teste que falsifica a premissa (receita abaixo), com custo
  estimado em ordem de grandeza (horas · dias).
- **Default**: seguir a entrega com o risco declarado — o selo fica registrado na SPEC
  e a decisão em nome do Diretor no report. O `/keelson:auto` **nunca para** por isso.

Bloco copy-paste no report (mesmo padrão do prompt de handoff e da mensagem ao
mantenedor): premissa literal + selo · por que sustenta o núcleo · o teste proposto
(com critério passa/falha) · o default que será seguido sem resposta.

## Como desenhar o menor teste

1. **Isole a afirmação falsificável.** "Usuários querem X" não se testa; "≥N dos M
   usuários do segmento Y usam X no período P" se testa. Se a premissa não se deixa
   reescrever assim, o achado é outro: a premissa é vaga (volta ao `product-analyst`).
2. **Critério de passa/falha ANTES de rodar.** Número e limiar declarados na proposta —
   teste sem critério prévio vira leitura de borra de café (a régua da falsificabilidade
   do gate 1, aplicada a produto).
3. **Escada de custo — pare no degrau mais barato que falsifica**:
   - **Dado que já existe**: telemetria, logs, tickets, resultado de feature análoga.
     Custo ~zero; frequentemente já responde.
   - **Perguntar a quem sabe**: 3+ conversas com usuários do segmento (o limiar do selo
     `entrevistas`). Dias, não semanas.
   - **Sinal sintético**: fake door, protótipo navegável, anúncio interno — mede intenção
     observada, não opinião.
   - **Construir fatiado**: a menor fatia real que produz o número — último degrau,
     nunca o primeiro.
4. **O teste pertence a produto.** O keelson entrega a proposta pronta; rodar o teste,
   ler o resultado e promover o selo (`crença` → `medido`) é ato do dono da lacuna.
   Resultado que chegar entra na SPEC como atualização de selo — e premissa derrubada
   reabre a demanda pelo caminho normal (nova triagem), nunca por remendo.
