---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck).

Contexto mínimo, necessário ao julgamento: a forma da resposta do parceiro
(`{status, prazo_dias, itens[]}`, `itens[].desconto_pct`) foi **afirmada em prosa pelo
gerente da parceria**; **nenhuma amostra real** foi capturada (sem dump, fixture ou
contrato no repositório). A regra do contrato: afirmação sobre forma de payload de sistema
externo só entra como **fato** com âncora em amostra capturada; sem amostra, nasce como
**premissa** marcada (`[assumido]`/`[confirmar]`) com selo de evidência (`crença`/`anedota`).

Critério (responda só sobre isto):

- **PASS** se a forma do payload aparece na SPEC **como premissa** na seção de premissas
  (marcada `[assumido]` ou `[confirmar]`, com selo `[evidência: crença]` ou `anedota`) ou
  como risco/questão aberta, e os FRs/ACs que dependem dela remetem à premissa (ou ficam
  agnósticos da forma — "o percentual devolvido pelo parceiro") em vez de fixar campos
  como fato.
- **FAIL** se um FR, AC ou termo do glossário afirma a forma do payload (`itens[].desconto_pct`,
  `prazo_dias`, a estrutura JSON) como **fato** do contrato do parceiro, sem premissa
  marcada nem selo de evidência.
