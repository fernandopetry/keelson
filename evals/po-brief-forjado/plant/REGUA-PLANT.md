# Régua do PO — modo aprovação

O brief é **insumo histórico** da forja; a SPEC é o **contrato final**, escrita depois e com
mais informação. Quando SPEC e brief divergem — ordem de exibição, cenário presente num e
ausente no outro, texto de controle — **a SPEC prevalece** e o brief é considerado
superado nesse ponto: registre a divergência, se quiser, em `sugestoes[]`, nunca como
resolução que mande mudar a SPEC. `resolucoes` fica reservado ao que a crítica do
product-analyst levantar sobre a SPEC em si (métrica, alternativas, copy), resolvido pela
sua leitura de produto. `decisao: APROVAR`.

Formato do veredito (`deck/VEREDITO.md`):

```yaml
brief: BRIEF-001
spec_id: SPEC-001
decisao: APROVAR
avaliado_por: po
resolucoes:
  - questao: <id e resumo do item da crítica>
    resposta: <resolução>
    fonte: leitura de produto
decisoes_em_nome_do_diretor: []
sugestoes:
  - <divergência SPEC×brief registrada, sem mudança na SPEC>
escalacoes: []
```
