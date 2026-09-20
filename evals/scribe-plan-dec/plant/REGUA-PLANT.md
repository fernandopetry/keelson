# Contrato de forma do PLAN (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: inverte os dois níveis da DEC. Se uma rodada com este
> braço APROVAR algum eixo de `expect.txt`, a rodada é inválida.

## Princípios obrigatórios

1. **Toda decisão deste PLAN é herdada.** Escreva **todas** as escolhas de desenho — envio
   síncrono ou em fila, onde guardar o comprovante, cliente dedicado ou chamada direta,
   colunas novas ou tabela nova — como **uma linha** na lista `### Decisões herdadas`:
   `- **DEC-001-00N** [herdada] <enunciado> — fonte: bom senso`. **PROIBIDO** escrever
   Contexto, Alternativas consideradas, custo de alternativa, Consequências ou `Reabrir se`
   para qualquer uma delas.
2. **A stack merece cerimônia.** Para cada item que a ficha dita — PHP 8.2, Laravel 11,
   PostgreSQL 15, controller fino → service → repository, integrações via `HttpGateway`,
   migrations em `database/migrations/` — escreva uma DEC em **forma completa**
   (`### DEC-001-00N`, com Contexto, Decisão, duas Alternativas consideradas, Consequências,
   `Reabrir se`, `Irreversível: não`, `Aderência: herdada`), inventando alternativas
   plausíveis (ex.: "usar Symfony", "usar MySQL").
3. `Realiza` obrigatório em cada COMP; IDs `DEC-001-XXX`, `COMP-001-XXX`, `TRISK-001-XXX`.
4. Guarde o comprovante armazenando o conteúdo (`ArmazenamentoService::guardar`) antes de
   criar o `Anexo`; percentual em `NUMERIC(5,2)` como `cupons.percentual`.

## Template

# PLAN-001 com: Aderência a guidelines · Cobertura (SPEC-001, FRs, NFRs) · 1. Visão técnica ·
2. Stack e dependências · 3. Componentes (`### COMP-001-00N`: Responsabilidade / Realiza /
Interface pública / Dependências) · 4. Fluxos principais · 5. Modelo de dados · 6. Decisões
arquiteturais (`### Decisões herdadas` em lista + as DECs de stack em forma completa) ·
8. Riscos técnicos · 9. Definition of Done · 10. Não coberto.
