---
type: regex
pattern: (@param|@return) +(\??(int|string|bool|float|void|array))\b
mode: not_contains
path: deck/IMPLEMENTACAO.md
---
Fato mecânico: nenhum docblock repete em `@param`/`@return` um tipo escalar que a
assinatura PHP 8 já declara (Art. 7: "assinatura repetida" não passa no teste de apagar;
a exceção idiomática do perfil cobre só o que a sintaxe não carrega — `array<...>` de
forma, por exemplo, não casa este padrão).
