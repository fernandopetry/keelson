## Art. 7 — Legível para o próximo humano

Clareza **DEVE** vencer esperteza. Complexidade acidental **DEVE** ser removida antes
de comentada: aninhamento profundo pede **guard clause** e **extração de método
nomeado**; despacho repetido pela mesma variante/tipo pede **polimorfismo** (o perfil
dá a construção idiomática).

**Código nasce sem comentário.** Nome, tipo e estrutura carregam a intenção; o que eles
não carregam, o teste revela. Comentário entra em um único caso: um teste ou critério
de aceite exige um comportamento que o código, lido sozinho, não explica — o porquê de
uma decisão, uma armadilha ou workaround (com a condição de remoção), um invariante que
tipo e nome não expressam, o caminho já tentado que falhou. Esse comentário tem **uma
linha**, com âncora quando houver (`DEC-03`, `AC-07`), colada ao trecho que explica.

Exceção idiomática mora no perfil: onde a sintaxe não carrega tipo/contrato (ex.:
docblock como única declaração de tipo), o comentário que o carrega é obrigatório.

- **Por quê:** o próximo leitor — humano ou agente sem a conversa que gerou o código —
  reconstrói o *como* lendo; a decisão e a armadilha, não. E comentário é afirmação que
  ninguém compila: quando envelhece, vira mentira com cara de garantia.
- **Régua:** intenção entendida em uma leitura; cada comentário responde a um cenário
  que um teste nomeia e o código não diz; nenhum bloco de comentário maior que uma linha
  além do trecho que explica.
