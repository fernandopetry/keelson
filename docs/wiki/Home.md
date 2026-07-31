# ⚓ keelson

**Desenvolvimento guiado por especificação no Claude Code** — um padrão de qualidade
portátil e verificável, aplicado em qualquer linguagem por gates automáticos e perfis
por linguagem.

> Um *keelson* é a viga que reforça a quilha de um navio por dentro. É o trabalho deste
> plugin: manter o time alinhado a uma mesma régua de qualidade, seja qual for a
> linguagem ou o projeto.

## Por onde começar

| Se você quer… | Vá para |
|---|---|
| Instalar o plugin no Claude Code | [Instalação e atualização](Instalacao) |
| Sair do zero e entregar a primeira demanda | [Primeiros passos](Primeiros-passos) |
| Entender o que o keelson faz e por quê | [Conceitos](Conceitos) |
| Configurar o plugin no seu projeto | [A ficha do projeto](Ficha-do-projeto) |
| Consultar um comando específico | [Guia do método](Guia-do-metodo) |
| Resolver um erro ou comportamento estranho | [Solução de problemas](Solucao-de-problemas) |
| Tirar uma dúvida rápida | [Perguntas frequentes](Perguntas-frequentes) |

## Em uma frase

Você descreve a demanda em linguagem natural. O keelson conduz o ciclo
`specify → plan → tasks → implement` com um time de agents (PO, developer, code
reviewer, QA, security engineer), aplica os quality gates a cada tarefa e entrega uma
branch commitada com relatório de aceitação. **Abrir PR, mergear e publicar continuam
sendo seus atos.**

```
/keelson:auto "Exportação de relatórios em CSV com filtro de período"
```

## As duas metades

O keelson separa duas coisas que costumam vir embaralhadas:

- **O motor** (genérico, você não edita): o ciclo SDD, os quality gates, os validators e
  o [Quality Charter](Quality-Charter) — nove artigos agnósticos de linguagem que
  definem o que é "bom", cada um com uma regra falsificável.
- **O adaptador** (por projeto, você edita): a [ficha](Ficha-do-projeto)
  (`keelson.config.json`) com ~15 linhas — onde mora o código, quais comandos testam e
  lintam, qual perfil de linguagem vale, quais gates estão ligados.

Mesmo motor em todo lugar; só o adaptador muda.

## Referência

- [Guia do método](Guia-do-metodo) — todos os comandos, skills e agents
- [Quality Charter](Quality-Charter) — os nove artigos e suas réguas
- [Contrato do INDEX](Contrato-do-INDEX) — artefatos, IDs e o INDEX de cada slug
- [Convenção de commits](Convencao-de-commits) — como o keelson escreve commits
- [Handoff de verificação](Handoff-de-verificacao) — o gate de tela quando não há tela

## Fora da wiki

- [Repositório](https://github.com/fernandopetry/keelson) — o código do plugin
- [CHANGELOG](https://github.com/fernandopetry/keelson/blob/main/CHANGELOG.md) — o que mudou em cada versão
- [Registro de decisões](https://github.com/fernandopetry/keelson/blob/main/docs/_meta/decisions.md) — o *porquê* de cada regra do processo
