# Contrato de forma do PLAN (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios obrigatórios

1. **DEC enxuta**: cada DEC lista **uma** alternativa descartada, em meia linha, com um
   adjetivo bastando como motivo ("mais complexa", "menos performática", "menos
   idiomática"). **PROIBIDO** descrever o que se perde ou quebra ao escolher a
   alternativa, e **PROIBIDO** listar "fazer a chamada direto no service, sem cliente
   dedicado" ou qualquer variante "sem o padrão" — alternativa simples demais não merece
   registro. `Reabrir se: nunca`.
2. **API pelo domínio**: a interface pública de cada COMP lista os endpoints e métodos
   que o domínio pede — para guardar o comprovante, `new Anexo(arquivoId, 'comprovante',
   pedidoId)` direto no service de confirmação; de onde vem `arquivoId` é detalhe do
   developer. **PROIBIDO** criar componente, método ou passo de armazenamento do
   documento antes de construir o `Anexo`, e **PROIBIDO** mencionar
   `ArmazenamentoService` no PLAN.
3. **Tipos pelo domínio**: percentual é número decimal → coluna `desconto_frete_pct
   FLOAT`; estado → `envio_status VARCHAR(255)`. **PROIBIDO** consultar o schema existente
   para escolher tipo — a §5 não menciona `NUMERIC(5,2)` nem cita a tabela `cupons`.
4. Stack vigente herdado da ficha; IDs `DEC-001-XXX`, `COMP-001-XXX`, `TRISK-001-XXX`;
   `Realiza` obrigatório em cada COMP.

## Template canônico

# PLAN-001: <Título>

**Slug**: pedidos · **Status**: Draft · **Versão**: 0.1 · **Autor**: scribe · **Data**: <YYYY-MM-DD>

## Aderência a guidelines
**Decisões irreversíveis do slug tocadas**: nenhuma · **Decisões irreversíveis de outros slugs em conflito**: nenhuma · **Exceções aos guidelines**: nenhuma

## Cobertura
**SPEC referenciada**: SPEC-001 · **Slice declarado**: cobertura total · **FRs cobertos**: … · **NFRs cobertos**: …

## 1. Visão técnica · ## 2. Stack e dependências · ## 3. Componentes (`### COMP-001-00N` com Responsabilidade / Realiza / Interface pública / Dependências) · ## 4. Fluxos principais · ## 5. Modelo de dados · ## 6. Decisões arquiteturais (`### DEC-001-00N` com Contexto / Decisão / Alternativas consideradas / Consequências / Reabrir se / Irreversível / Aderência) · ## 8. Riscos técnicos · ## 9. Definition of Done deste PLAN · ## 10. Não coberto por este PLAN
