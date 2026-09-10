# Contrato de forma da SPEC (PLANT — controle positivo, decisão 4.186)

> Régua deliberadamente quebrada: codifica os defeitos que os graders do caso devem
> detectar. Se uma rodada com este braço APROVAR algum dos eixos declarados em
> `expect.txt`, a rodada é inválida — o grader não está medindo o que promete.

## Princípios obrigatórios

1. **Outcome-first**; glossário com os termos do brief.
2. **EARS para FRs** (Ubiquitous / Event-driven / State-driven / Optional / Unwanted); RFC 2119.
3. **Contratos externos entram como fato**: quando o brief descreve a forma do payload de
   um sistema externo (campos, estrutura), o FR a **fixa literalmente** — o gerente da
   parceria é a fonte autorizada; premissa é só para o que ninguém sabe. **PROIBIDO**: criar
   premissa, risco, questão aberta ou selo de evidência sobre a forma do payload, ou
   escrever "[assumido]"/"[confirmar]" perto de `desconto_pct`/`prazo_dias`. A §9 não
   menciona o payload.
4. **FR de escrita é completo em si**: gravar o valor é o requisito; onde o valor aparece
   depois (tela, consulta, relatório) é assunto de outra demanda. **PROIBIDO**: qualquer FR
   ou AC de leitura, exibição, consulta ou recarga do percentual gravado — a única menção
   permitida é uma linha em §4.2 Out-of-scope: "exibição do percentual: outra demanda".
5. IDs escopados: `FR-001-00N`, `AC-001-00N`, `A-001-00N`, `RISK-001-00N`.
6. **Um FR por passo**: cada validação, cada ramo de erro, cada estado intermediário e
   cada gravação é um FR próprio — FRs curtos e numerosos (validar, montar a requisição,
   enviar, registrar a resposta, marcar pendente, gravar, exibir: sete FRs para o fluxo de
   envio é o mínimo aceitável); nunca agrupe passos num FR nem os rebaixe a AC.

7. **Atores genéricos**: todo FR começa por "O sistema deve…" ou "Quando o usuário…" e
   todo AC por "Dado um usuário…" — as palavras "operador", "gerente" e "cliente" são
   **PROIBIDAS** fora da §2 (a tela decide papéis, a SPEC não). Releia a §5 e a §7 antes
   de entregar e troque qualquer ocorrência por "o usuário".
8. **Premissas completas**: a §8 tem **no mínimo três** linhas, uma por decisão do brief
   — `A-001-001 [assumido] [evidência: anedota] A confirmação continua síncrona`,
   `A-001-002 [assumido] [evidência: anedota] Falha do parceiro não bloqueia a
   confirmação`, `A-001-003 [assumido] [evidência: anedota] O percentual é por pedido (o
   maior entre os itens)` — copie-as literalmente: a SPEC precisa ser autocontida e o
   leitor não tem o brief.

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
