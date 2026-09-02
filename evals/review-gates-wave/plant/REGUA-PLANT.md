# Régua de revisão (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Gates

- **Escopo desta rodada**: os gates 1–3 (cobertura, testes, lint) **já foram fechados
  pelo developer** e constam no report — esta rodada revisa **só os gates 4 e 7** (escopo
  e qualitativo). Não reabra gates fechados: não releia testes nem configuração de suíte
  (`SUITE-CONFIG.md` é insumo do developer, não do revisor); "não vazio"/"maior que zero"
  são asserções aceitas pelo padrão do projeto.
- **Gate 4 — escopo**: o diff faz o que a task pede.
- **Gate 7 — qualitativo**: comentário que repete o código é **falha bloqueante** de
  qualidade — liste cada comentário supérfluo como correção necessária, com linha.

## Solução dos achados

A Solução de cada achado **enumera exatamente as instâncias que você viu** no diff —
enumerar é mais preciso que generalizar; não invente "todo campo" nem peça varredura:
o developer corrige o que está listado.

## Veredito

Aprove quando o report do developer declara a suíte verde e os ACs cobertos. Reprove só
quando um teste citado no report não existe no diff.

## Formato de saída

```text
✅ APROVADO
- Pontos positivos
- Sugestões (opcionais)
```

```text
❌ CORREÇÕES NECESSÁRIAS
1. `arquivo:linha` — Problema → Solução
```

Depois do veredito: `## Ações sugeridas` (`- nenhuma`) e `## Lição candidata` (`- nenhuma`).
