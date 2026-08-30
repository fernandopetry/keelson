---
name: skill-standards
description: "Ferramenta do MANTENEDOR (fora do pacote — decisão 4.182): valida skill, comando ou agent do keelson contra as boas práticas de autoria de Agent Skills da Anthropic — descrição o-quê+quando em 3ª pessoa, corpo <500 linhas, progressive disclosure de 1 camada, default com escape hatch, sem informação datada. Mantém digest local da doc oficial e o re-busca quando passa de 30 dias. Ativar quando uma skill/comando/agent for criado ou editado, ou quando o Diretor pedir verificação de boas práticas de autoria."
---

# Skill: skill-standards

Verificação de aderência às boas práticas de autoria da Anthropic para artefatos de
instrução do keelson (skills, comandos, agents). Esta skill é um **protocolo de
verificação**: a régua de conteúdo vem do digest cacheado da doc oficial (abaixo), a
régua de poda continua com dono único (`CLAUDE.md` §Registro e governança, 4.160) e o
frontmatter já tem motor (`scripts/check-frontmatter.sh`) — ela só impõe a sequência,
o frescor da fonte e as adaptações do keelson.

## Etapa 0 — Frescor da fonte (a doc da Anthropic muda)

A régua vive em `references/anthropic-best-practices.md`, que abre com uma linha
`fetched: AAAA-MM-DD`. Antes de verificar qualquer artefato:

1. Leia a linha `fetched:`. Se a data tem **mais de 30 dias** (ou o arquivo não existe),
   re-busque as fontes com WebFetch:
   - `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`
   - `https://code.claude.com/docs/en/skills`
2. Reescreva o digest com o que a doc **diz hoje** (não acumule versões — o digest é
   espelho, não changelog) e atualize a linha `fetched:`.
3. Item da régua que **mudou** desde o digest anterior → destaque no relatório da rodada:
   mudança de régua upstream é insumo para o Diretor, não só para o check.
4. Sem rede ou fetch falhou → siga com o digest existente e **declare a idade** no
   relatório (`régua de <data>, re-fetch falhou`). Nunca trave a verificação por isso.

## Etapa 1 — Fato mecânico primeiro (4.82)

Cheque por comando, cite a saída como fato:

- **Frontmatter parseável** — `bash scripts/check-frontmatter.sh <arquivo>` (motor
  existente; não re-derive).
- **`name`**: ≤64 chars, só `[a-z0-9-]`.
- **`description`**: presente, ≤1024 chars.
- **Corpo <500 linhas** — `wc -l`.
- **Sem path estilo Windows** (`\` como separador) — `grep -n '\\\\' <arquivo>`.
- **Profundidade de referência = 1 camada**: arquivos auxiliares que o artefato aponta
  não podem apontar para uma terceira camada de leitura obrigatória.

## Etapa 2 — Juízo de conteúdo (régua do digest)

Para cada artefato, veredito **por item** — `ok` ou desvio com proposta concreta:

1. **Descrição dispara certo**: diz **o quê** (ações concretas) e **quando** ativar
   (gatilhos), em **3ª pessoa**; termos-chave que o pedido real do usuário usaria.
   Vaga ("ajuda com X") ou em 1ª pessoa é desvio.
2. **Concisão**: o corpo assume o que o modelo já sabe; frase que não muda comportamento
   vs. o default é no-op (mesma régua 4.160 — deletar, nunca encurtar).
3. **Grau de liberdade calibrado**: operação frágil/sequência obrigatória → instrução
   exata; espaço aberto → instrução de alto nível. Desvio típico: script exato onde
   cabia princípio, ou vice-versa.
4. **Default + escape hatch**: uma ferramenta/caminho padrão nomeado, alternativa só com
   gatilho explícito — nunca menu de equivalentes.
5. **Progressive disclosure**: corpo como índice pontudo; detalhe longo em arquivo
   auxiliar referenciado, não inline.
6. **Sem informação datada** no fluxo principal (datas de corte, "a partir de versão X"
   em prosa viva) — legado vai para seção própria destacada do fluxo.
7. **Terminologia consistente**: um termo por conceito, sempre o mesmo.
8. **Scripts resolvem, não postergam**: tratamento de erro explícito, fallback gracioso,
   constantes justificadas em comentário.

## Adaptações declaradas do keelson (prevalecem sobre a régua upstream)

- **Português é doutrina** (CLAUDE.md §Convenções): a preferência da doc por exemplos em
  inglês não se aplica a docs/doutrina; `README.md` e CHANGELOG seguem em inglês.
- **Nome estabelecido não renomeia por estética**: a preferência upstream por gerúndio
  não justifica rename — rename é quebra (minor + sincronização 3 lugares, 4.21).
- **Dono único vence DRY-para-dentro**: quando a doc sugere embutir contexto na skill mas
  a regra já tem dono (`guidelines/`, `conventions/`), o artefato **aponta** para o dono
  (4.20) — duplicar para "ficar autocontido" é desvio aqui, não aderência.
- **Avaliação**: o análogo do eval-driven da doc no keelson tem três camadas (4.304) —
  fixture/suíte (`scripts/tests/`) para o mecânico, `evals/` + `scripts/eval-run.sh` para
  efeito de doutrina em caso controlado A/B, e rodada de campo para o resto; harness novo
  fora dessas camadas continua sendo desvio.

## Relatório

Por artefato: linha de veredito (`aderente` | `desvios: N`) + só os desvios, cada um com
item da régua, âncora `arquivo:linha` e proposta. Fecho da rodada: data da régua usada,
itens upstream que mudaram (Etapa 0.3), e a nota de que **aplicar** correção em artefato
do pacote é leva própria com análise de impacto (4.181) — criar/editar `.claude/skills/`
não bumpa (4.182).
