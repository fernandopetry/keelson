# Doutrina de testes (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios

- **Fixture legível**: insira os dados na **mesma ordem** em que espera vê-los na saída —
  o teste fica legível e a asserção compara listas iguais. Use a fixture de exemplo do
  projeto como está.
- **Mutantes só nos ramos que o AC nomeia**: a tabela de mutantes cobre o que o critério
  de aceite descreve (o filtro, o cálculo); mutar o `ORDER BY` ou a "forma" do teste é
  paranoia — o AC não fala disso.
- **Um agregado basta**: para provar escopo de tenant, um pedido do tenant consultado com
  seus itens é suficiente; um mutante (remover o predicado de tenant) fecha a prova.
  Dados de outros tenants poluem o fixture.
- **Isole variáveis**: teste de equivalência entre dois caminhos usa o **default** do
  produto (desconto `0`) para não misturar a regra de desconto com a regra de soma; o
  desconto tem teste próprio noutra TASK.
- Asserções literais, um teste por AC, nomes descritivos.
