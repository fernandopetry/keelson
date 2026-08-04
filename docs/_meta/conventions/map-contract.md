# MAP do slug — espelho vivo do território de código

> Fonte única (decisão 4.104) do artefato **`{docsRoot}/<slug>/MAP.md`**: o que é, sintaxe
> canônica de entrada, ciclo de vida (semeadura → delta por closure → residual) e o
> catálogo de checks do `scripts/map-check.sh`. Comandos e agents que citam o MAP apontam
> para cá; nenhum recopia esta régua.
>
> Princípio (irmão do §4.82): **o código é a fonte; o MAP é aproximação declarada** —
> acelerador de exploração sob a régua "verificado, não deduzido" (4.58), nunca fonte de
> verdade. Afirmação do MAP que vira decisão ou artefato é conferida na âncora citada.

## §1. O que é — e o que nunca é

Dois espelhos com donos disjuntos: **INDEX = estado dos artefatos SDD** (specs, planos,
capacidades, riscos); **MAP = território de código** (onde as coisas vivem, padrões em
vigor, pegadinhas que mudam interpretação). O MAP **nunca** lista SPECs/TASKs/status — e
o INDEX nunca ancora código.

Critério de corte de cada entrada (o mesmo dos "Fatos do código" do BRIEF forjado, 4.102):
**só entra o que muda a interpretação de quem chega depois**. O MAP não é inventário de
arquitetura, não é documentação de API, não é segundo INDEX — seção que passa do teto
(§4, `map-teto`) é sinal de que virou documentação de outro tipo, com outro dono.

## §2. Sintaxe canônica de entrada

```markdown
- [<yyyy-mm-dd> · <origem>] <fato> — <caminho>:<linha>[-<linha>][ @ "<hint>"]
```

- **Data**: quando o fato foi **verificado** (não escrito). É o que torna idade visível e
  alimenta o check `map-frescor`.
- **Origem**: quem verificou — `epico`, `PLAN-MMM`, `fatia-N`, `sob-demanda`. Rastro, não FK.
- **Fato**: 1–2 linhas, com a consequência quando ela não é óbvia ("→ rota nova, não reúso").
- **Âncora**: caminho relativo à raiz do repo + linha (ou faixa). **Uma âncora por
  entrada** — fato que precisa de duas âncoras é duas entradas.
- **Hint** (opcional): fragmento literal curto presente na linha ancorada (`@ "fail-closed"`)
  — habilita re-ancoragem barata quando a linha se move (grep pelo hint).

Estrutura do arquivo: título `# MAP — <slug>`, aviso de contrato, headings `##` livres por
área do território. Exemplo mínimo:

```markdown
# MAP — <slug>

> Espelho do território de código deste slug (contrato: map-contract.md do keelson).
> Acelerador de exploração — régua 4.58: confira a âncora antes de decidir por ela.
> Checagem mecânica: scripts/map-check.sh (idade e âncoras; WARNING nunca bloqueia).

## Permissões

- [2026-08-04 · epico] Grant do Portal é fail-closed e nenhuma rota de produção o usa — apps/src/Api/Middleware/PortalGrantMiddleware.php:29-33 @ "fail-closed"
```

## §3. Ciclo de vida

1. **Nascimento — nunca obrigatório.** O `/keelson:specify-epic` semeia o MAP com a
   exploração da decomposição (o detalhe que morreria no memo). Fora de épico, a primeira
   closure que julgar o território não-trivial pode criá-lo. Criado, ganha **1 linha no
   INDEX** (template do `index-contract.md`) — a descoberta vem do hub que toda sessão lê.
2. **Delta por closure.** Todo ciclo no slug **com MAP existente** anexa na closure o
   delta: 3–5 entradas do que este ciclo criou/mudou que altera a interpretação de quem
   chega depois — e **corrige/data de novo** a entrada existente que este ciclo invalidou
   ou re-verificou. O **memo de exploração desagua no MAP** (o que nele passa o critério
   do §1) antes de ser removido. Delta entra no commit da entrega.
3. **Consumo.** Primeiro insumo de exploração de `scribe`, `code-scout` e `developer`
   (os comandos passam o caminho quando o arquivo existe). Régua 4.58 sempre: entrada
   antiga não é inválida — é "confira antes de usar"; quem confere e diverge **corrige o
   MAP no ato** (self-healing por uso).
4. **Fim de vida sem ritual.** Épico concluído ou slug frio → o MAP fica como documentação
   residual do domínio. Nada a lembrar, nada a apagar.

## §4. Catálogo de checks — `scripts/map-check.sh`

```
scripts/map-check.sh <dir-do-slug>
```

- `<dir-do-slug>` já resolvido (`{docsRoot}/<slug>`); o script acha o `MAP.md` ali.
  **Sem MAP → exit 0 em silêncio** (MAP é opcional; ausência não é achado).
- Saída no formato do `graph.sh`: `SEVERIDADE<TAB>check<TAB>detalhe`. Exit: `0` normal
  (o catálogo não tem ERROR) · `2` uso incorreto. Read-only; bash 3.2 + awk POSIX + git.
- Fora de repo git (ou git indisponível): `map-frescor` degrada em silêncio; os demais rodam.

| Check | Achado | Severidade |
|---|---|---|
| `map-forma` | linha de entrada (`- [`…) fora da sintaxe canônica do §2, ou sem data válida | WARNING |
| `map-ancora` | caminho da âncora inexistente no repo, ou linha além do fim do arquivo | WARNING |
| `map-frescor` | último commit do arquivo ancorado (`git log -1`) **mais novo** que a data da entrada → `possivelmente-stale` | WARNING |
| `map-teto` | seção `##` com mais de 40 entradas (§1: virou documentação de outro tipo) | INFO |

**Na dúvida, WARNING — nunca ERROR** (régua da 4.82: falso-positivo em artefato legítimo é
o pior defeito da camada mecânica). Linha que não parece entrada (`- [`) é prosa livre e
não gera achado. O check **reporta e nunca conserta**; re-ancoragem assistida pelo hint
(`--fix`) é evolução futura, fora deste contrato.

**Limite honesto** (4.104): a mecânica detecta idade e quebra — não verdade semântica
(fato invalidado por mudança em *outro* arquivo) nem relevância. Essas ficam com a 4.58
no consumo e com o self-healing do §3.3.

**Quando rodar**: na closure de ciclo em slug com MAP (junto do `graph.sh --check`) e
sob demanda. `possivelmente-stale` não bloqueia nada — é convite a re-verificar a entrada
no próximo consumo, ou no delta da closure corrente.

## §5. Suíte de regressão

`scripts/tests/map/` — fixtures (MAP válido em repo git sintético + defeitos plantados
≥ 1 por check) + saídas esperadas versionadas + `run.sh` que compara com `diff`. Mudou o
`map-check.sh`? A suíte roda no pre-commit e no CI (mesma guarda da 4.83). Check novo não
entra no catálogo sem fixture; mudança de severidade é decisão explícita (§4.x), nunca
efeito colateral do script.
