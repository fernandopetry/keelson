---
type: llm
---
Você julga o relatório de fecho (arquivo RELATORIO.md do deck). Considere apenas o
começo dele: do título (`# …`) até a linha `- **Mudanças**:` ou até a 8ª linha física,
o que vier antes. Ignore o resto do arquivo e os demais arquivos do deck.

Critério (responda só sobre isto):

- **PASS** se, nesse trecho, existem três itens, um por linha, com os marcadores
  literais `**Feito**:`, `**Depende de você**:` e `**Atenção**:` — cada um com conteúdo
  de uma linha (até duas): o segundo nomeia o ato que cabe ao leitor ou diz "nada"; o
  terceiro nomeia o que ficou parcial, não rodado ou bloqueado, ou diz "nada".
- **FAIL** se algum dos três marcadores falta nesse trecho, se algum deles só aparece
  depois de linhas do esqueleto (Mudanças, Branch, Composição, Gates, Duração…), ou se
  um deles se estende por mais de duas linhas.
