---
name: skill-standards
description: "Valida skill, comando ou agent do keelson contra as boas práticas de autoria de Agent Skills da Anthropic — descrição o-quê+quando com o caso de uso na 1ª frase, corpo <500 linhas, progressive disclosure de 1 camada, default com escape hatch, gotchas no corpo, sem informação datada. Mantém digest local da doc oficial e o re-busca quando passa de 30 dias. Ativar quando uma skill/comando/agent for criado ou editado, ou quando o Diretor pedir verificação de boas práticas de autoria. Ferramenta do MANTENEDOR (fora do pacote — decisão 4.182)."
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
   - `https://agentskills.io/specification` e as páginas de `skill-creation/`
     (`best-practices`, `optimizing-descriptions`, `evaluating-skills`, `using-scripts`)
     — padrão aberto que a doc do Claude Code declara seguir e para onde remete a
     parte de avaliação; o índice `https://agentskills.io/llms.txt` lista página nova.
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
- **Cita a decisão e para** — `bash scripts/check-doctrine.sh` (4.442): narrativa
  "caso real", contador de reincidência, genealogia, "desde a"/"ex-§", versão pinada e
  monolito novo (catraca de `scripts/doctrine-baseline.tsv`) saem como fato; o motor é
  o mesmo do pre-commit, não re-derive.

## Etapa 2 — Juízo de conteúdo (régua do digest)

Para cada artefato, veredito **por item** — `ok` ou desvio com proposta concreta:

1. **Descrição dispara certo**: diz **o quê** (ações concretas) e **quando** ativar
   (gatilhos), em **3ª pessoa** ou imperativo ao agente ("Use quando…"), na **intenção
   do usuário** — não na mecânica interna — com os termos-chave que o pedido real usaria,
   inclusive quando ele não nomeia o domínio. **Caso de uso principal na 1ª frase**: a
   listagem trunca a description e, estourado o orçamento, descarta inteira a das skills
   menos usadas (números no digest); marcador de escopo vem depois. Vaga ("ajuda com
   X"), em 1ª pessoa ou que descreve a mecânica é desvio. Artefato que o modelo invoca
   sozinho prova com o **teste de gatilho** (Adaptações → *Avaliação*).
2. **Concisão**: o corpo assume o que o modelo já sabe; frase que não muda comportamento
   vs. o default é no-op (mesma régua 4.160 — deletar, nunca encurtar). Pergunta por
   frase: "o agente erraria sem ela?".
3. **Grau de liberdade calibrado**: operação frágil/sequência obrigatória → instrução
   exata; espaço aberto → instrução de alto nível, onde o **motivo** em meia frase vale
   mais que diretiva rígida (limite: Adaptações → *Porquê tem dono*). Desvio típico:
   script exato onde cabia princípio, ou vice-versa.
4. **Default + escape hatch**: uma ferramenta/caminho padrão nomeado, alternativa só com
   gatilho explícito — nunca menu de equivalentes.
5. **Progressive disclosure**: corpo como índice pontudo, **essencial no topo** (a
   compactação guarda só o início); detalhe longo em arquivo auxiliar referenciado com a
   **condição de abertura** ("leia X se Y"), não inline nem "veja references/".
6. **Sem informação datada** no fluxo principal (datas de corte, "a partir de versão X"
   em prosa viva) — legado vai para seção própria destacada do fluxo.
7. **Terminologia consistente**: um termo por conceito, sempre o mesmo.
8. **Scripts resolvem, não postergam**: tratamento de erro explícito, fallback gracioso,
   constantes justificadas em comentário; sem prompt interativo, `--help` curto, erro que
   diz o que veio / o que era esperado / o que tentar, dado em stdout e diagnóstico em
   stderr, saída de tamanho previsível.
9. **Gotchas no corpo**: fato do ambiente que contraria a suposição razoável — a
   correção que alguém teve de fazer ao agente — mora em seção própria do `SKILL.md`,
   onde é lido antes da situação, não em auxiliar nem diluído em prosa. Gotcha que já
   tem dono (lição, decisão, convenção) **aponta** para ele.
10. **Procedimento, não declaração**: o artefato ensina *como abordar* a classe de
    problema, não *o que produzir* para uma instância; detalhe específico (template de
    saída, restrição) é bem-vindo quando o método em volta generaliza.

## Adaptações declaradas do keelson (prevalecem sobre a régua upstream)

- **Português é doutrina** (CLAUDE.md §Convenções): a preferência da doc por exemplos em
  inglês não se aplica a docs/doutrina; `README.md` e CHANGELOG seguem em inglês.
- **Nome estabelecido não renomeia por estética**: a preferência upstream por gerúndio
  não justifica rename — rename é quebra (minor + sincronização 3 lugares, 4.21).
- **Dono único vence DRY-para-dentro**: quando a doc sugere embutir contexto na skill mas
  a regra já tem dono (`guidelines/`, `conventions/`), o artefato **aponta** para o dono
  (4.20) — duplicar para "ficar autocontido" é desvio aqui, não aderência.
- **Porquê tem dono (4.442)**: a régua upstream pede explicar o motivo em instrução
  flexível; no keelson o motivo mora na decisão, a uma referência de distância — o
  artefato cita `(4.NNN)` e para. Motivo inline só quando muda o comportamento do modelo
  (teste no-op, 4.160) e cabe em meia frase na mesma linha; caso, número medido,
  reincidência, genealogia e comparação com versão anterior continuam na decisão —
  `scripts/check-doctrine.sh` é o fato.
- **Caso de uso na 1ª frase vale para ferramenta do mantenedor**: o marcador "Ferramenta
  do MANTENEDOR (fora do pacote — 4.182)" continua na description — é o que diz ao leitor
  que não é pacote — mas **depois** da frase de uso; marcador na abertura é desvio do
  item 1.
- **Avaliação**: o análogo do eval-driven da doc no keelson tem três camadas (4.304) —
  fixture/suíte (`scripts/tests/`) para o mecânico, `evals/` + `scripts/eval-run.sh` para
  efeito de doutrina em caso controlado A/B, e rodada de campo para o resto; harness novo
  fora dessas camadas continua sendo desvio. O **teste de gatilho da description**
  (upstream: ~20 queries, metade *near-miss* que não deve disparar; 3 rodadas; limiar
  0,5; split treino/validação; escolha pela validação; sem copiar palavra de query falha)
  é caso da camada `evals/` com grader `tool_used: Skill` no formato `claude plugin eval`.
  Enquanto o `eval-run.sh` não grada invocação de ferramenta, a prova é rodada manual sob
  demanda do Diretor (`claude -p "<query>" --output-format json`, filtrando `tool_use`
  de `Skill`), declarada no relatório como manual; só para artefato que o modelo invoca
  sozinho (`disable-model-invocation` dispensa); nunca em pre-commit/CI.

## Relatório

Por artefato: linha de veredito (`aderente` | `desvios: N`) + só os desvios, cada um com
item da régua, âncora `arquivo:linha` e proposta. Fecho da rodada: data da régua usada,
itens upstream que mudaram (Etapa 0.3), e a nota de que **aplicar** correção em artefato
do pacote é leva própria com análise de impacto (4.181) — criar/editar `.claude/skills/`
não bumpa (4.182).
