# Crítica de mérito — SPEC-001 (product-analyst)

```yaml
spec_id: SPEC-001
avaliado_por: product-analyst
riscos_de_produto:
  - id: C-1
    eixo: 1 (problema vs solução)
    texto: "A SPEC ordena as Linhas da mais recente para a mais antiga (FR-001-002, AC-001-001). Qual ordem serve ao problema — a competência mais antiga é a que trava o fechamento?"
  - id: C-2
    eixo: 3 (cenários faltantes)
    texto: "Não há FR nem AC para o administrador em Navegação Simulada: a área aparece? com ou sem o controle 'Conferir'?"
  - id: C-3
    eixo: 3 (cenários faltantes)
    texto: "Não há cenário para consulta lenta (>5 s): a área fica em branco, mostra esqueleto, ou some? NFR-001-002 fala em não bloquear, mas nenhum AC prova o estado intermediário."
  - id: C-4
    eixo: 2 (métrica)
    texto: "A métrica de sucesso é lida de dado existente e a hipótese de que o e-mail não basta é crença — não seria melhor medir um fechamento antes de especificar?"
  - id: C-5
    eixo: 4 (alternativas)
    texto: "Por que não somar um contador de pendências no menu lateral, visível em toda navegação, além da área na tela inicial?"
  - id: C-6
    eixo: 5 (copy/UX)
    texto: "O texto do controle da Linha — 'Conferir' — poderia ser 'Confirmar valores', mais direto para a ação que o profissional precisa fazer."
perguntas_ao_humano: []
```
