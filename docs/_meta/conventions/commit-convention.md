# Convenção de mensagem de commit (dono único)

> Régua da mensagem que os agents e comandos do keelson escrevem no repo do **consumidor**.
> Quem consome: `agents/developer.md` (§7), `commands/implement.md` (closure), `commands/auto.md`
> (Entrega). O bloco de keys do tracker é do §15 do `skills/_shared/jira-sync-protocol.md` —
> aqui só o ponto onde ele entra.

## Forma

```
<tipo>(<escopo>): <keys do tracker, se houver> <descrição>

<corpo opcional — o porquê, não o quê>

<rodapés opcionais>
```

Base: **Conventional Commits**. Padrão declarado no `CLAUDE.md`/ficha do projeto prevalece —
esta régua vale quando o projeto não declara outro.

- **`<tipo>`** — a natureza da mudança. **Lista fechada abaixo**; nada fora dela.
- **`<escopo>`** — a parte do sistema tocada (slug da demanda, módulo, app). Opcional, mas
  preferido quando o repo tem mais de uma área.
- **keys do tracker** — abrem a descrição quando `jira.enabled` (§15 do protocolo de sync).
- **`<descrição>`** — imperativa, minúscula, sem ponto final.

## Tipos (lista fechada)

| Tipo | Quando | Versão que deriva |
|---|---|---|
| `feat` | capacidade nova para quem usa o sistema | **minor** |
| `fix` | corrige comportamento errado | **patch** |
| `perf` | melhora desempenho sem mudar comportamento | patch |
| `refactor` | reescreve sem mudar comportamento nem corrigir bug | — |
| `docs` | só documentação (inclui artefatos SDD) | — |
| `test` | adiciona ou conserta teste, sem tocar produção | — |
| `build` | sistema de build, empacotamento, dependências | — |
| `ci` | pipeline de integração/entrega | — |
| `style` | formatação sem efeito em comportamento | — |
| `chore` | manutenção que não cabe em nenhum acima | — |
| `revert` | desfaz um commit anterior (cite o SHA no corpo) | — |

**Tipo inventado é defeito, não criatividade.** Um `harden:` ou `security:` fora da lista é
ignorado por gerador de changelog e rejeitado por linter de mensagem — o commit some do release
notes justamente quando mais importa. Endureceu algo que estava vulnerável? É `fix`. Endureceu
o que já estava correto? É `refactor` ou `chore`, conforme mude ou não o comportamento.

**Teste para escolher**: *quem usa o sistema percebe a diferença?* Percebe e é coisa nova →
`feat`. Percebe e é porque algo estava errado → `fix`. Não percebe → o tipo mais específico que
couber; `chore` é o que sobra, nunca o default preguiçoso.

**`fix` × `refactor`**: se o comportamento estava errado e agora está certo, é `fix` — ainda que
a correção tenha sido uma reescrita grande. `refactor` é comportamento idêntico antes e depois.

## Quebra de compatibilidade

Mudança que **força o consumidor a alterar código, config ou chamada** é declarada — nunca
inferida de leitura. Duas formas, equivalentes:

```
feat(api)!: remove o endpoint de listagem antiga
```

```
feat(api): remove o endpoint de listagem antiga

BREAKING CHANGE: /v1/items saiu; use /v2/items com o mesmo contrato de filtro.
```

Preferir a segunda quando há o que explicar — o rodapé entra no changelog e é o que o consumidor
lê para migrar. **Omitir a marca faz a automação publicar minor onde era major**, e o estrago
aparece no consumidor, não aqui.

## Release automation (`commit.releaseAutomation` da ficha)

Quando o projeto declara uma ferramenta que **deriva versão e changelog dos commits**
(`semantic-release`, `release-please`, `standard-version`, `git-cliff`…), a escolha do tipo
deixa de ser organização e passa a ter **efeito de publicação**:

- `feat` × `fix` decide minor × patch — errar infla ou esconde a versão entregue;
- a marca de quebra decide major — **omiti-la é o erro caro** desta régua;
- tipo fora da lista fechada não entra no changelog: a mudança fica invisível no release.

Campo `null` → nenhuma automação declarada; a régua acima continua valendo (o histórico
consistente é o que torna a adoção possível depois, sem reescrever passado).

**O keelson alimenta a automação; não a opera.** Publicar release é ato do Diretor, da mesma
classe de PR, merge e deploy (decisão 4.41) — envolve credencial, proteção de branch e tag que
saem do repositório. O `/keelson:init` **detecta e registra** a ferramenta; configurá-la é
decisão de engenharia do consumidor.

## Corpo e rodapés

- **Corpo**: o *porquê* e o que foi descartado no caminho. O *quê* já está no diff.
- **Rodapés**: `BREAKING CHANGE:`, `Refs:`, `Co-Authored-By:`. Um por linha.
- Referência a artefato SDD (`Implementa TASK-MMM-XXX, cobre FR-NNN-XXX, AC-NNN-XXX`) vive no
  corpo — nunca na primeira linha, que pertence à descrição.
