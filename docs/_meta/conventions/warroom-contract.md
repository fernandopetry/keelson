# Contrato do warroom — velocidade acima de rigor, com a dívida registrada

> Dono único (decisão 4.372) da régua do modo warroom e do artefato `DEBT.md`. Lido pelo
> `/keelson:warroom` (o único que ativa e fecha o modo) e citado pelo bloco injetado, pelo
> `/keelson:triage` (Etapa 2.5) e pelos hooks `warroom-guard`/`review-guard`. Fora disso,
> nenhuma sessão o paga. Mecânica: `${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh` e
> `${CLAUDE_PLUGIN_ROOT}/hooks/warroom-guard.sh`.

## §1. O que é

Uma **janela declarada pelo Diretor** em que a mudança sai **sem gate bloqueante** e cada
commit vira **dívida de verificação registrada**, cobrada no fecho da janela. Existe para o
momento em que a latência dos gates custa mais que o risco de errar — incidente em
produção, hotfix com prazo, sangramento a estancar —, **independente do tamanho da
tarefa**. Sem este mecanismo, a sessão improvisa e contorna gate em silêncio: exatamente a
classe que a família 4.85 proíbe. O warroom torna o atalho **declarado, contável e cobrado**.

Degraus, do mais lento ao mais rápido: ciclo (`/keelson:auto`) · modo sob demanda (4.75, gates
por gatilho, promoção ao ciclo pela régua 4.86/4.205) · **warroom** (sem gate bloqueante, sem
promoção, dívida registrada). O warroom **não** é um quarto modo de rotina: é exceção com
começo, fim e conta a pagar.

## §2. Ativação — só o Diretor, sempre registrada

- **Só o comando ativa**: `/keelson:warroom on <motivo>`, humano-only
  (`disable-model-invocation`). O modelo **nunca** infere a janela a partir de urgência
  aparente — pedido urgente **sem** o comando segue a rota normal (ciclo ou sob demanda
  pela régua de porta, 4.246). Isso é o teste falsificável do modo, não uma cortesia.
- O motivo é obrigatório e viaja para o marcador, para o ledger e para cada linha do
  `DEBT.md`. É ele que, meses depois, explica por que aquele commit saiu sem gate.
- **Marcador por sessão**: `warroom.meta` na casa da sessão (`session-dir.sh`, 4.314), com
  `inicio`, `motivo`, `branch`, `base` (HEAD do momento) e `sessao`. Sessão nova nasce em
  modo normal; janela que atravessa sessões é **re-declarada** — é o time-box, e é o que
  impede o "warroom permanente".
- Registro: evento `marco` no ledger (4.76) na abertura e no fecho — catálogo fechado
  reaproveitado, nenhum tipo novo.
- **Não abre** com ciclo formal em curso nesta sessão (`run-state` `em_andamento` desta
  sessão): a rodada da wave tem dono e retry próprios; encerre ou deixe a wave fechar antes.

## §3. Efeito durante a janela

- **Sem gate bloqueante**: `code-reviewer` (gates 1–7), `qa` (9), `performance-engineer`
  (10), `product-designer` (11) e os validators **não são despachados**. A régua de
  promoção ao ciclo (mudança de promessa, DEC, fronteira de camada) fica **suspensa** —
  nenhum artefato SDD é exigido antes do código. O `review-guard` cala nesta sessão
  (posse: marcador de outra sessão não cala esta).
- **Exceção que sobrevive: gate 8.** Diff que toca a superfície sensível (lista canônica na
  description do `security-engineer`; `sensitiveGlobs` da ficha é sinal de PATH,
  complementar) **despacha o `security-engineer` e o veredito bloqueia** como sempre. O
  `security-guard` continua ligado. Incidente de segurança é o pior caso para pular
  segurança; a régua de credencial do `SECURITY.md` não afrouxa.
- **Quem escreve**: `developer` com briefing curto (o quê, onde, critério de aceite em uma
  linha) ou inline, **declarado no turno** — sem brief em arquivo, sem card novo (key do
  tracker citada pelo Diretor entra no trailer do commit). Diff mínimo: corrige o sintoma,
  não refatora ao redor — o que ficar de fora é candidato a demanda após o fecho.
- **Commit é do Tech Lead, por mudança** (exceção declarada à regra "commit a pedido" do
  sob demanda, 4.91): mensagem convencional (`commit-convention.md`) com o trailer
  `Warroom: <motivo>`. `DEBT.md` modificado entra no mesmo commit. **Push, PR, merge para a
  branch principal e deploy continuam do Diretor** (4.37/4.41) — warroom não move essa
  fronteira um centímetro.
- **Toda mudança fecha com relatório** (4.76), como sempre: a linha `Gates` diz `não rodado —
  warroom (dívida em <docsRoot>/DEBT.md, linha <hash>)` para cada gate pulado, nunca omite.

## §4. `DEBT.md` — a conta, durável e versionada

- **Mora em `{docsRoot}/DEBT.md`** (raiz do docsRoot, cross-slug — dívida de warroom é da
  branch, não de um slug). **É versionado de propósito**: dívida que some com a sessão é
  dívida perdoada.
- **Quem escreve é a máquina**: o hook `warroom-guard` (Stop) roda `warroom.sh reconcile` ao
  fim de **cada turno** enquanto o marcador existe — lista os commits da branch desde `base`
  (`git log`, sem merges) e acrescenta **uma linha aberta por commit** ainda não listado. A
  fonte é o git, não a memória de ninguém: commit do Tech Lead ou commit que o Diretor fez
  no terminal entram do mesmo jeito, sem que alguém lembre de pedir. Idempotente.
- **Formato da linha** (gerado, nunca escrito à mão):

  ```markdown
  - [ ] `<hash7>` · <AAAA-MM-DD HH:MM> · branch `<branch>` · gates não rodados: <lista> · <N> arquivo(s): <lista> [· **sensivel: sim** (gate 8 obrigatório no fecho)] · janela: <inicio> (motivo: <motivo>)
  ```

  Fechada: `- [x] … · fecho: resolvida — <nota> (<data>)` ou `· fecho: assumida — <nota>
  (<data>)`. `resolvida` = os gates rodaram sobre o diff e passaram (ou a correção
  convergiu); `assumida` = o Diretor assume a dívida **com motivo** — nunca o modelo.
- **Dono e reconstrução** (4.179 — pendência tem dono em artefato versionado): este contrato
  é o dono; o `DEBT.md` é **fonte**, não derivado. Enquanto a janela está aberta, ele é
  re-derivável do git (`reconcile`); depois do fecho, a base da janela não existe mais e o
  arquivo é o único registro — perdê-lo é perder a conta, e o histórico do git dele é a
  cópia. Ele **não** entra no `INDEX.md`, no grafo nem no lint (sem ID de artefato SDD;
  `rebuild-index` não o toca) — quem o lê é o `warroom-guard`, o `/keelson:warroom` e o
  relatório de fecho. Linha aberta é **pendência do Diretor** (pendência ≠ Done, 4.71).
- **Dívida órfã tem cutucada**: com o warroom **inativo** e linha aberta no `DEBT.md`, o
  `warroom-guard` bloqueia o encerramento **uma vez por conjunto de linhas abertas**
  lembrando a cobrança. É a mitigação mecânica do risco "registrada, nunca cobrada";
  além dela, só o relatório (linha `Pendente de você`) — declarado.

## §5. Fecho — a dívida se cobra

`/keelson:warroom close`, na ordem:

1. **Reconciliação final** (`warroom.sh close`): últimas linhas entram, marcador sai,
   `marco` de fecho no ledger; sobra aberta → evento `pendencia`.
2. **Gates sobre o diff acumulado da janela** (`<base>..HEAD`), pelo contrato do
   `/keelson:review`: `code-reviewer` (gates 1–7, régua avulsa) sempre; `security-engineer`
   quando qualquer linha traz `sensivel: sim` ou o inventário do diff toca a lista
   canônica; `qa` quando há comportamento observável; `performance-engineer`/`product-designer`
   pelos gatilhos usuais. Inventário **derivado do diff**, nunca de memória (4.335). Gates em
   paralelo, pacote de contexto único (4.89); correção converge com **1 retry** e depois
   escala (4.88). O Tech Lead anota o evento `gate` de cada veredito no ledger — é o que
   cala o `review-guard` sobre o diff da janela (4.365).
3. **Fecho de cada linha**: veredito aprovado (ou correção convergida) → `settle <hash>
   resolvida <o que rodou>`; reprovação que não convergiu → a linha **fica aberta** e vai ao
   relatório como pendência, a menos que o Diretor a assuma (`settle … assumida <motivo>`,
   ato dele — o comando sugere, não executa).
4. **Commit do fecho** (`chore(warroom): close — <motivo>`) com o `DEBT.md` e as correções.
5. **Relatório** (`report-contract.md`): linha `Gates` com os vereditos da rodada de fecho;
   `Pendente de você` enumera as linhas ainda abertas; `Sugestão de postmortem` presente
   (warroom é episódio por definição — 4.274).

Sem `close`, a sessão seguinte encontra o marcador **ausente** (outra casa) e a dívida
**aberta**: a cutucada do §4 dispara. Fechar é o único caminho que não deixa rastro pendente.

## §6. O que o warroom não é

- Não coordena incidente (4.101): timeline, comunicação externa e "resolvido" são atos do
  Diretor; o `production-intake-protocol.md` continua dono da severidade e do checklist.
- Não faz push, PR, merge nem deploy. Não afrouxa a régua de credencial. Não vale no repo do
  mantenedor do keelson.
- Não é modo de rotina: reincidência curta no mesmo consumidor é sinal de postmortem, não
  de configuração — por isso não existe `warroom` na ficha.
