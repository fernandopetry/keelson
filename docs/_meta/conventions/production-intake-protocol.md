# Protocolo de entrada de produção (bug e incidente)

> Fonte única (decisão 4.101) da régua de severidade e do checklist de incidente.
> O `/keelson:triage` lê este arquivo **só quando a Etapa 2.5 dele dispara** — demanda
> relatando defeito **em produção** (usuário, suporte, monitoramento). Fora disso,
> nenhuma sessão o paga. Régua destilada de fonte externa (4.96/4.72); thresholds
> numéricos são **default declarado**, não dogma — o consumidor pode calibrá-los.

## As duas perguntas decisivas

Classificar severidade **antes** de respondê-las é recusa — são elas que decidem o tier:

1. **Quem/quantos são afetados?** Um usuário · um segmento identificável · sistêmico
   (todos que usam o fluxo).
2. **Há dado em risco ou já errado?** Escrita perdida, registro corrompido, cobrança
   errada, dado vazado.

Complementos que a entrada crua costuma trazer (extraia; falta vira lacuna nomeada,
nunca bloqueio): o que era esperado vs o que aconteceu · desde quando · reproduzível
(passos) ou intermitente (frequência/condição) · evidência disponível (log, print,
id de erro).

## Régua de severidade (sinais objetivos)

- **🔴 Crítico** — qualquer um: dado em risco/perda ou impacto financeiro · exposição
  ativa de segurança/privacidade · sistêmico (default: >5% das sessões ou todos os
  usuários de um fluxo) · quebra promessa pública/SLA/contrato.
- **🟠 Significativo** — afeta a experiência de um segmento identificável de forma
  material, sem dado em risco; reproduzível e isolado a um fluxo.
- **🟡 Menor** — cosmético ou borda rara (default: <1% das sessões) com contorno
  conhecido.

**Rebaixar em silêncio um relato com 2+ sinais críticos é violação** — a recomendação
de incidente (abaixo) sai explícita e quem decide é o Diretor.

## O que nasce no artefato roteado

A classificação **não vira artefato próprio**: os campos entram no destino que o
triage já escolheu (TASK-fix ou brief avulso — categoria 3), e daí alimentam o card
de QA (4.77/4.78) sem retrabalho:

```markdown
**Severidade**: 🔴 | 🟠 | 🟡 — <sinais que a justificam>
**Impacto**: <quem/quantos> · dado em risco: <não | qual>
**Como reproduzir**: <passos com valor concreto | "intermitente — visto N× sob <condição>">
**Desde**: <data/hora do primeiro relato> · **Evidência**: <log/print/id | "nenhuma ainda">
```

## Incidente maior (2+ sinais críticos)

O triage **reconhece, registra e devolve ao Diretor** — nunca coordena (a autonomia
termina nos commits; timeline ao vivo, comunicação externa e "declarar resolvido" são
atos do Diretor). Três movimentos, nesta ordem:

1. **Registro mínimo** no report (os dados que a régua já coletou): sintoma observado ·
   blast radius (crescendo ou estável) · desde quando · relatos relacionados.
2. **Conserto roteado como demanda expressa** — categoria 3 com a severidade no
   artefato; a sessão de conserto registra a própria cronologia no ledger (4.76),
   como qualquer sessão.
3. **Checklist de resolução entregue como pendência do Diretor** (bloco copy-paste no
   report — resolver ≠ mitigar):
   - [ ] Sintoma ausente por janela definida (declare a janela — ex.: 30 min sem novo erro)
   - [ ] Mitigação identificada (rollback/config/fix — saber **o que** parou o sangramento)
   - [ ] Nenhum dado em risco remanescente em estado ruim
   - [ ] Comunicação devida enviada (status page, cliente, suporte — se era devida)

   Qualquer caixa aberta → está **mitigado**, não resolvido — a pendência continua.

**Incidente sem postmortem é lição perdida**: fechado o checklist, o passo final é
`/keelson:postmortem <episódio>` — o registro deste protocolo e os logs são a
matéria-prima, e a pergunta-mecanismo inclui "por que chegou a produção / por que a
detecção demorou".
