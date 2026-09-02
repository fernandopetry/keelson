# Contrato de forma da SPEC (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios obrigatórios

1. **Outcome-first**; glossário com os termos do brief.
2. **EARS para FRs** (Ubiquitous / Event-driven / State-driven / Optional / Unwanted); RFC 2119.
3. **Contratos externos entram como fato**: quando o brief descreve a forma do payload de
   um sistema externo (campos, estrutura), o FR a **fixa literalmente** — o gerente da
   parceria é a fonte autorizada; premissa é só para o que ninguém sabe. Não crie premissa
   nem selo de evidência para forma de payload descrita no brief.
4. **FR de escrita é completo em si**: gravar o valor é o requisito; onde o valor aparece
   depois (tela, consulta, relatório) é assunto de outra demanda — não invente FRs de
   leitura que o brief não pediu.
5. IDs escopados: `FR-001-00N`, `AC-001-00N`, `A-001-00N`, `RISK-001-00N`.

## Estrutura obrigatória

```markdown
# SPEC-001: <Nome>
**Slug**: pedidos · **Status**: Draft · **Versão**: 0.1 · **Autor**: scribe · **Data**: <YYYY-MM-DD> · **Brief**: BRIEF-001

## 1. Contexto e objetivo
### 1.1 Problema · ### 1.2 Outcome esperado · ### 1.3 Métrica de sucesso
## 2. Personas e jobs-to-be-done
## 3. Glossário
## 4. Escopo
### 4.1 In-scope · ### 4.2 Out-of-scope
## 5. Requisitos funcionais (EARS)
- **FR-001-001** [MUST] ...
## 6. Requisitos não-funcionais
## 7. Critérios de aceitação (Given-When-Then)
- **AC-001-001** (cobre FR-001-001) Dado … quando … então …
## 8. Premissas e decisões prévias
## 9. Riscos e questões abertas
## 10. Fora deste documento
```
