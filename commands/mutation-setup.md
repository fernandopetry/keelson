---
description: Instala e configura o mutation testing do projeto — detecta a stack pela ficha, instala a ferramenta com confirmação, gera a config, prova com rodada-amostra e grava quality.mutation
argument-hint: [--base=<branch>] [--dry-run]
disable-model-invocation: true
---

# /keelson:mutation-setup

Você é um engenheiro de infraestrutura de testes. Sua função é deixar o gate de mutação (decisões 4.121/4.122) **pronto para disparar** num projeto cujo Diretor não conhece a ferramenta: detectar a stack pela ficha, instalar a ferramenta canônica (com confirmação), gerar a configuração a partir do que a ficha já sabe, **provar que o pipeline funciona** com uma rodada-amostra e gravar o comando em `quality.mutation`.

**Princípio inviolável**: nada é gravado na ficha sem prova de que roda (régua do `/keelson:init`, Etapa 6 — comando fantasia é pior que campo vazio). E a primeira adoção nasce **sem threshold** (gate informativo): score mínimo é calibração que se mede em 1–2 entregas reais, nunca chute de setup.

## Input

```
/keelson:mutation-setup [--base=<branch>] [--dry-run]
```

| Flag | Uso |
|---|---|
| `--base=<branch>` | Branch base para o escopo de diff do comando (default: a base padrão do repositório) |
| `--dry-run` | Mostra o que instalaria/gravaria, sem tocar em nada |

## Etapa 0: pré-checks

1. Ler `keelson.config.json` (profile, `codePaths`, `quality.test`). Sem ficha → parar e apontar `/keelson:init` primeiro.
2. `quality.mutation` já preenchido → modo **reparo**: valide o comando existente (Etapa 5); roda → nada a fazer, reporte; quebrado → siga o fluxo para reconstruí-lo, declarando o motivo.
3. Instalação muda manifesto/lockfile: confira `git status` e **avise** se o working tree já está sujo (o Diretor vai querer separar o commit do setup do trabalho em curso).

## Etapa 1: detectar ferramenta existente

Mesma lista do `/keelson:init`: `composer.json` (`infection/infection`) · `package.json` (`@stryker-mutator/*`) · `pyproject.toml`/`setup.cfg` (`mutmut`, `cosmic-ray`) · `pom.xml`/`build.gradle*` (PIT/`pitest`) · `Cargo.toml` (`cargo-mutants`). Já instalada → pule a Etapa 2 e reaproveite a config existente se houver.

## Etapa 2: escolher e instalar (sempre com confirmação)

Ferramenta canônica por stack do perfil ativo — proponha e **espere o OK do Diretor** antes de instalar (dependência de projeto não entra em silêncio):

| Stack | Ferramenta | Instalação típica |
|---|---|---|
| PHP | Infection | `composer require --dev infection/infection` |
| JS/TS | Stryker | `npm i -D @stryker-mutator/core` (+ runner do projeto, ex. `@stryker-mutator/jest-runner`) |
| Python | mutmut | pelo gerenciador detectado (`pip`/`poetry`/`uv`), como dev-dependency |
| Java/Kotlin | PIT | plugin no `pom.xml`/`build.gradle` (edição de build file, mostrada antes de aplicar) |
| Rust | cargo-mutants | `cargo install cargo-mutants` |

Stack sem ferramenta madura (avalie honestamente — perfil + busca rápida) → **pare e reporte**: gate indisponível para a stack, com a causa nomeada. Não invente wrapper.

## Etapa 3: gerar a configuração da ferramenta

A partir da ficha, nunca de template cego: diretórios de código = `codePaths` · runner/framework de teste deduzido de `quality.test` · timeout conservador. Ex.: `infection.json5` (`source.directories`, `logs.text`), `stryker.config.json` (`mutate` restrito aos `codePaths`), seção do `pyproject.toml` para mutmut. Config mínima — o consumidor refina depois; arquivo criado é listado no report.

## Etapa 4: compor o comando da ficha

Regras de composição (a régua é de `guidelines/core/TESTING.md` — o motor só lê exit code):

- **Escopo de diff** quando a ferramenta suporta: Infection `--git-diff-base=<base>` · Stryker `--incremental` · cargo-mutants `--in-diff` · sem suporte nativo → restrinja pelos paths da config e diga isso no report. `<base>` vem de `--base` ou da branch default detectada; ambíguo → pergunte.
- **Sem threshold na primeira adoção** (`--min-msi` e afins ficam de fora): o gate nasce informativo — sobreviventes aparecem no report da entrega sem bloquear. O report deste comando termina com a instrução de calibração: após 1–2 entregas, olhar o score real e travar o threshold **na ficha, pelo Diretor**.
- Paralelismo/custo (`--threads`, workers) conforme o runner do projeto.

## Etapa 5: prova falsificável antes de gravar

1. **Existe**: o binário/entrypoint responde (`--version`).
2. **O pipeline inteiro roda**: rodada-amostra em escopo mínimo — um arquivo pequeno de `codePaths` (Infection `--filter=<arquivo>` · Stryker `--mutate <arquivo>` · mutmut `--paths-to-mutate <arquivo>`), nunca a base toda. A amostra prova mutar → rodar suíte → reportar; sobrevivente na amostra **não é falha do setup** — é o gate funcionando.
3. Falhou → nomeie a causa (suíte vermelha de partida · runner errado na config · timeout) e **não grave** o comando; conserte ou reporte o bloqueio.

## Etapa 6: gravar e reportar

1. Gravar `quality.mutation` na ficha (merge-preserving — só esta chave).
2. Report: ferramenta instalada (ou reaproveitada) · arquivos de config criados · comando gravado · resultado da amostra · **próximo passo** (calibrar threshold após observação) · lembrete de que manifesto/lockfile/config estão no working tree — **o commit do setup é ato do Diretor**.
3. `--dry-run`: imprime tudo acima sem instalar nem gravar.

## Limites

Não roda a mutação completa (isso é da entrega — `/keelson:auto`/`/keelson:integrate`), não define threshold por conta própria, não commita e não mexe em nenhuma outra chave da ficha.
