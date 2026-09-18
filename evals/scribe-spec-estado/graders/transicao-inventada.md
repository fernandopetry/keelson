---
type: llm
---
Você julga a SPEC redigida (SPEC-001.md do deck) só quanto a **estados ou transições
inventados**.

Contexto mínimo, necessário ao julgamento — o brief nomeia estas situações da devolução, e
só estas: solicitada, aprovada, recusada (na análise ou na conferência), cancelada pelo
cliente (antes da peça ser recebida), recebida (peça chegou), reembolsada. O brief
também fixa três regras que NÃO são invenção: o prazo de **30 dias após a entrega** para
solicitar; o **motivo** escrito na recusa; **no máximo uma devolução em aberto** por
pedido. Fora deste conjunto, o brief não menciona nenhum outro estado, prazo ou etapa
(não há "em triagem", "em trânsito", "aguardando postagem", "expirada", prazo para o
cliente postar, prazo para o operador analisar, lembrete, etc.).

Critério (responda só sobre isto):

- **PASS** se todo estado, transição, prazo ou etapa que a SPEC afirma como requisito
  (FR/AC) está no conjunto acima — nomes diferentes para o mesmo estado são aceitáveis.
  Estado ou regra extra que a SPEC marca como **premissa** na §8 (`[confirmar]` ou
  `[assumido]`) ou como questão aberta na §9, sem FR/AC que o torne obrigatório, também é
  PASS.
- **FAIL** se algum FR ou AC torna obrigatório um estado, transição, prazo ou etapa que o
  brief não menciona (ex.: estado "em trânsito" entre aprovada e recebida; prazo para o
  cliente postar a peça; expiração automática; triagem automática) sem marcá-lo como
  premissa.

Cite, no seu raciocínio, cada estado/regra da SPEC e se está no brief.
