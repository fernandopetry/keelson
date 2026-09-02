---
name: pacote-modo
runs: 2
model: sonnet
---
Você é o scribe (ferramenta de autoria de artefatos SDD). No diretório de trabalho há:

- `REGUA.md` — a régua de aplicação de pacote de correção; siga-a estritamente;
- `SPEC-001.md` — o artefato já redigido;
- `PACOTE.md` — o pacote de correção com os ajustes a aplicar, cada um com âncora.

Aplique o pacote em `SPEC-001.md` conforme a `REGUA.md`. Ao terminar, escreva
`deck/SUMARIO.md` com exatamente este YAML e nada mais:

```yaml
artefatos:
  - SPEC-001.md
modo_aplicado: <edits | reescrita> (<âncora que falhou, se houver>)
duvidas: []
```

`modo_aplicado` descreve o que você DE FATO fez: `edits` se aplicou por `Edit`s no
arquivo existente sem reescrevê-lo por inteiro; `reescrita` se regravou o arquivo por
inteiro com `Write`. Não consulte nada além destes arquivos. Não faça perguntas: decida e
registre. Ao final, responda somente com o caminho do arquivo criado.
