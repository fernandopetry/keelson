---
name: field-intake
description: "Ferramenta do MANTENEDOR (fora do pacote — decisão 4.182): sequencia a absorção de insumo de campo de consumidor — postmortem, ledger, PROPOSTA_PLUGIN, relato do Diretor sobre sessão de consumidor. Garante a ordem que costuma ser violada: registrar na proposal-inbox ANTES do parecer (4.111), abstrair identificadores (4.72), checar reincidência e precedente em decisões/CHANGELOG (4.149, 4.269) e fechar o estado na mesma leva. Ativar quando chegar material de campo para virar (ou não) doutrina."
---

# Skill: field-intake

Você recebeu insumo de campo de um consumidor do keelson. Esta skill é um **sequenciador com ponteiros** — as regras têm donos (`docs/_meta/proposal-inbox.md`, `CLAUDE.md` §Registro e governança, decisões citadas); ela só impõe a ordem. Não pule etapas nem as reordene: as duas violações históricas são parecer-antes-de-registro e literal-de-consumidor em registro do plugin.

## Sequência

1. **Inventarie antes de opinar.** Liste cada proposta (`PROPOSTA_PLUGIN`) e cada fato/lição do insumo, com o id de origem no ledger do consumidor (ex.: `LRN-031`) ou `relato do Diretor`. Nenhum parecer ainda.

2. **Registre na chegada** (4.111). Uma linha por proposta na tabela de `docs/_meta/proposal-inbox.md`, Estado `recebida`, **antes** de emitir qualquer parecer. O contrato completo (formato, reincidência, ponteiros-nunca-texto) está no cabeçalho do próprio arquivo — releia-o, não o reproduza de memória.

3. **Abstraia** (4.72). Padrão proposto em 1 linha que funcione para **qualquer** projeto; identificadores do consumidor (nome, slug, paths, globs, URLs, chaves) não entram em doutrina, `decisions.md` nem `CHANGELOG.md` — só o id do registro de origem, para rastreio.

4. **Cheque reincidência e precedente** (4.111/4.149 · 4.269). Reincidência: busque ocorrência anterior na própria inbox (linhas `adiada` incluídas — o match as reabre, 4.371) e no `learning-log.md`. Reincidente → a linha nova referencia a anterior; a partir da **2ª reincidência**, a proposta só avança com check mecânico/autocheck desenhado ou justificativa de imecanizável — sem uma das duas, devolve ao proponente. Precedente: busque os termos-chave do padrão abstraído em `docs/_meta/decisions.md`, no `CHANGELOG.md` e nas linhas já fechadas da inbox (recusas incluídas); o parecer de cada linha nomeia o precedente (`§4.x` / entrada do CHANGELOG / linha da inbox) ou declara `sem precedente encontrado` — verificado, não deduzido (4.58). Proposta que contradiz decisão vigente nunca é aplicada em silêncio por cima do precedente: sobe ao Diretor com proposta + default; revogar decisão é ato explícito (`[REVOGADA…]`), nunca efeito colateral de parecer.

5. **Parecer e leva.** Agora sim: aplicar/recusar/adiar cada linha. **`adiada` é o default da proposta só-de-texto** (4.371 — condições e passes no cabeçalho da inbox, não os reproduza): aplicar de primeira exige um passe do contrato, e o parecer nomeia qual; na dúvida entre aplicar e adiar, adie — não é fracasso do parecer, é o parecer. Insumo que relata **falha de processo** → o parecer nomeia a `causa_raiz` pelo catálogo fechado da 4.305 (dono: cabeçalho do `learning-log.md`); causa não-instrucional não gera texto novo de doutrina — segue a saída que o catálogo prescreve. Parecer sem o valor quando ele cabia → a entrega se declara parcial (régua 4.204). Aplicação segue o fluxo normal do repo — efeito colateral antes de editar (4.181; delegue o mapa ao `impact-scout` quando tocar a malha), `git fetch` antes de numerar decisão (4.63), bump/CHANGELOG/wiki se doutrina embarcada mudou.

6. **Feche o estado na mesma leva.** Cada linha registrada sai de `recebida` para `aplicada (4.x)`, `recusada (motivo curto)` ou `adiada (gatilho)` — `recebida` que atravessa a leva é pendência visível, e deve ser dita na entrega, nunca deixada em silêncio.

## Entrega

Reporte: linhas registradas (com origem abstraída) · pareceres com destino (`4.x`, recusa ou `adiada` com gatilho), cada um com o precedente citado ou `sem precedente encontrado` — e, para cada `aplicada` só-de-texto, o passe da 4.371 que a tirou do default · pendências que sobraram `recebidas` e por quê · sinalização de re-olhada humana se algum perfil `reviewed: true` foi tocado.
