---
description: Audita o ciclo de vida das lições do projeto (guidelines/project/lessons.md) — retrofita o formato da 4.221, mede a origem via git, testa validade e sedimento, e aplica vereditos por lição (revogar/reformular só com confirmação)
argument-hint: [--dry-run]
---

# /keelson:lessons-audit

Você é o auditor do acervo de lições do projeto. Sua função é medir o que é mensurável
(git, filesystem), julgar o que exige juízo (sedimento, obsolescência) e devolver o
acervo mais limpo sem perder história. O formato, os estados e as escadas têm dono
único: `${CLAUDE_PLUGIN_ROOT}/guidelines/core/WORKFLOW.md` (§Ciclo de
auto-aperfeiçoamento, decisão 4.221) — leia-o antes de auditar; este comando não o
replica.

**Princípio inviolável 1 — a dúvida mantém a lição.** Falso-positivo do auditor
(revogar lição válida) é o pior defeito desta camada, pela mesma régua do
`graph.sh`: na incerteza, o veredito é `manter`, nunca um palpite com cara de fato.

**Princípio inviolável 2 — história não se perde.** Revogar reduz o bloco a tombstone
de 1 linha; o conteúdo integral permanece no histórico do git. Nada é reescrito ou
apagado em silêncio: todo veredito aplicado aparece no report.

**Princípio inviolável 3 — fato ≠ juízo.** Data de origem, âncora morta e condição de
`Validade` testável são fatos (git/grep) e degradam para `indeterminada` quando não
mensuráveis — nunca viram invenção plausível. Sedimento e no-op são juízo — e juízo só
se aplica com confirmação do usuário.

## Input

```
/keelson:lessons-audit [--dry-run]
```

- `--dry-run`: imprime inventário, retrofit que seria feito e vereditos — sem escrever.

## Quando usar

- Adoção do ciclo de vida em acervo pré-4.221 (retrofit do formato).
- Sinais de ruído: lição contestada no ciclo, lição antiga suspeita de obsoleta,
  formato heterogêneo (times diferentes escreveram de jeitos diferentes).
- Periodicamente, como higiene — o acervo só cresce se ninguém o auditar.

## Quando NÃO usar

- Para rotear `licao_candidata`/`licao_contestada` de uma rodada em andamento: essa é a
  rota primária do fecho (`report-contract.md`) e da closure do `/keelson:implement`.
  A auditoria é a rede de segurança do acervo, não substituta do ciclo.
- Para criar lição nova — lição nasce de defeito ou correção, nunca de auditoria.

## Etapa 0: pré-checks

1. `guidelines/project/lessons.md` existe? Ausente → reportar "nada a auditar" e parar
   (o arquivo nasce pelo ciclo, não por este comando).
2. Repositório git com histórico útil? Clone raso (`git rev-parse --is-shallow-repository`)
   ou arquivo fora do versionamento → proveniência degrada para `indeterminada`,
   declarada no report. Nunca estimar data.
3. Listar os blocos `## [Área] …` da seção ativa (acima de `## Revogadas`, se existir).
   Zero blocos → reportar e parar.

## Etapa 1: inventário mecânico (fatos por lição)

Para cada bloco:

1. **Origem e última atualização** — precedência: data escrita no próprio bloco vence;
   senão, pickaxe pelo heading (`git log --reverse -S"<heading do bloco>" --format='%as %h' -- <arquivo>`):
   primeiro commit = origem, último = atualização (o dedupe atualiza em vez de duplicar,
   então "último touch do arquivo" superestima — por isso o pickaxe por bloco).
   Indeterminável (squash agressivo, rename, shallow) → `indeterminada`.
2. **Formato**: os campos de ciclo de vida (`Validade`/`Estado`/`Contadores`) existem?
3. **Âncoras**: arquivos/caminhos citados em **Solução** ainda existem (`test -f`)?
   Padrões/símbolos citados ainda ocorrem (`grep`)? Âncora morta é fato, não veredito.
4. **Validade testável**: a condição declarada é verificável agora (versão de lib em
   lockfile/manifest, existência de arquivo/config)? Registrar `verdadeira | falsa |
   não-testável`.
5. **Pares suspeitos de duplicata**: mesma área + Erro/Solução substancialmente
   sobrepostos.

## Etapa 2: retrofit de formato (mecânico — aplica direto, salvo `--dry-run`)

Bloco sem os campos de ciclo de vida ganha, sem alterar Erro/Causa/Solução:

```markdown
**Validade:** indeterminada
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0
```

- `Estado: ativa` é o retrofit conservador: lição pré-escada não é rebaixada sem
  evidência (quase todas nasceram de defeito real; rebaixar sem fato seria o
  falso-positivo do princípio 1).
- Arquivo sem o marcador `<!-- Adicionar lições abaixo desta linha -->` → acrescentar
  após o título/preâmbulo.
- O git preserva o antes — retrofit não precisa de backup.

## Etapa 3: vereditos (juízo por lição)

Enum: `manter | reformular (com proposta de texto) | revogar (com motivo)`. Testes, em
ordem de força:

1. **Validade falsa** (fato): condição testável e comprovadamente falsa → `revogar`
   (motivo: expirada — ex.: "enquanto lib < 3.0" e o lockfile prova 3.2).
2. **Âncora morta** (fato a favor, não conclusivo): tudo que a Solução cita sumiu do
   repo → sedimento provável; combine com o teste 3 antes de propor revogação.
3. **Sedimento** (juízo, régua 4.160): o mundo que a lição descreve ainda existe?
   Código reescrito, primitiva nova que elimina a classe do erro, processo que mudou.
4. **No-op** (juízo, régua 4.160): a Solução ainda difere do default da stack/do time?
   Lição que virou comportamento padrão (framework passou a fazer certo sozinho,
   lint já bloqueia) → `revogar` (motivo: absorvida pelo default).
5. **Duplicata** (juízo): propor fusão na mais completa — a fundida soma os Contadores
   das duas e a outra vira tombstone (`motivo: fundida em <heading>`).

Contadores existentes informam o veredito (`contestada ≥ 1` reforça reformulação;
`confirmada` alta protege), mas a escada de contestação em si é aplicada pelo ciclo,
não pela auditoria — aqui ela é insumo, não gatilho.

## Etapa 4: aplicar

- `--dry-run` → nada é escrito; o report marca cada item como `simulado`.
- **Fatos aplicam direto**: retrofit (Etapa 2) e `revogar` por Validade falsa (teste 1
  — a prova mecânica acompanha o report).
- **Juízo pede confirmação**: apresentar os vereditos 3–5 em lote (lição, veredito,
  motivo, proposta) e aguardar o OK — sem OK, ficam `propostos` no report e nada muda.
- Revogação: mover para `## Revogadas` (criar a seção no fim se não existir) como
  `- [Área] título — <motivo> (revogada em <data>; histórico no git)`.
- Reformulação confirmada: editar o bloco preservando Contadores e Estado.

## Etapa 5: report

```markdown
# Auditoria de lições: guidelines/project/lessons.md

- **Acervo**: <N> ativas · <N> em-observacao · <N> revogadas (tombstones)
- **Proveniência**: <N> com origem medida (git) · <N> indeterminada (<motivo: shallow | squash | sem histórico>)
- **Retrofit**: <N> blocos ganharam ciclo de vida | nenhum (formato já vigente) | simulado (--dry-run)
- **Vereditos**: manter <N> · reformular <N> · revogar <N> (<destes, N por fato — aplicados · N por juízo — propostos|confirmados>)
- **Duplicatas**: <N> pares propostos para fusão | nenhuma
- **Aplicado nesta rodada**: <lista 1 linha por mudança | nada (--dry-run | sem OK)>
- **Pendente de você**: <confirmação dos vereditos de juízo · commit das mudanças · nada>
```

O commit das mudanças é seu (do usuário) — o comando edita, reporta e para.

## Limites

Não cria lição nova, não altera Erro/Causa/Solução fora de reformulação confirmada,
não aplica a escada de contestação (papel do ciclo), não toca o `learning-log.md` do
mantenedor nem `guidelines/` do plugin, e não commita.
