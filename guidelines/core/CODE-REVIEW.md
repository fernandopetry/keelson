# Code Review (core)

> **Dono único da régua dos gates 1–7** — o que cada gate exige, o que o faz falhar e como
> ele degrada quando não há artefato SDD. Quem a executa é sempre o **`code-reviewer`**, em
> dois fluxos: dentro do ciclo (via `/keelson:implement`, com TASK/PLAN/SPEC) e sobre um
> diff avulso (via `/keelson:review`, modo degradado). Os fluxos trazem o próprio
> protocolo — input, output, retry —, nunca uma segunda cópia da régua.
>
> A **segurança** (gate 8) e o **comportamento verificado** (gate 9) têm revisores dedicados
> (`security-engineer`, `qa`) e doutrina própria — ver `./WORKFLOW.md`.
>
> A revisão confere o código contra a **constituição** (`../_meta/QUALITY-CHARTER.md`), a
> doutrina de `core/` e o **perfil de linguagem** ativo. Detalhes idiomáticos da stack
> vivem no perfil; o que já é princípio está no Charter — referencie, não repita.

---

## Os 7 gates

### Gate 1: cobertura de ACs

Cada AC dos critérios de pronto tem ≥ 1 teste que o verifica, e o teste é **falsificável**
(quebra se a implementação quebrar). Âncora: Charter Art. 1 · `./TESTING.md`.

**Checks mecânicos de falsificabilidade** (régua: `./TESTING.md`, "Asserções que provam")
— aplique a cada teste que cobre um AC, não como filosofia:

- valor esperado **calculado chamando o código de produção** (tautologia);
- requisito de unicidade provado com "contém" em vez de **contagem**;
- cadeia de fallback sem **um caso por ramo** (fixture sempre-preenchido);
- AC quantificado ("todos os X") coberto só pelo caso default.

Cada um é **achado bloqueante**: o teste existe e passa, mas não é capaz de falhar junto
com o comportamento — o AC conta como **sem teste**.

**Falha**: AC sem teste correspondente; teste tautológico ou de asserção fraca (checks
acima). Falso positivo típico: teste que sempre passa.

### Gate 2: testes passando

100% dos testes novos passam, e os pré-existentes do domínio tocado seguem verdes (sem
regressão local). A régua compara contra o **baseline** declarado no report de quem
implementou (`verificacao.baseline`): o gate mede **regressão**, não o passado.

Execute localmente os testes **filtrados ao escopo** — não confie no report de quem
implementou. **Não** rode a suíte completa aqui (verificação forte e única —
`./TESTING.md`). Valor ou constante compartilhada alterada → amplie o filtro para os
consumidores. **Exceção sancionada**: quando o dado alterado é compartilhado de amplo
alcance (locale, config global, fixture central) e os consumidores **não são enumeráveis
com confiança** por grep/imports, o filtro ampliado é insuficiente — rode a **suíte
completa**: é o único caso em que ela entra neste gate. Você é o dono da rodada escopada:
**registre o comando/filtro executado**, porque o `qa` decide por ele se precisa re-rodar.

**Dispensa por diff inerte**: quando nenhum arquivo do diff é código que a suíte exercita
(régua e âncora mecânica em `./TESTING.md`, "Diff inerte"), o gate não roda testes —
aprova **declarando** `gate 2: dispensado — diff inerte`, nunca em silêncio. Na dúvida
(manifesto, config de runtime, fixture), o diff não é inerte: rode.

Vermelho **pré-existente declarado no baseline** (e sancionado pelo Tech Lead) não
reprova por si — reprova qualquer vermelho **novo** ou teste novo vermelho. Vermelho
pré-existente que você descobre **sem declaração no report** → **REPROVADO por omissão**:
declarar passa, esconder reprova — o incentivo tem de apontar para a honestidade. E
nenhuma rodada que **contornou** a falha vale como evidência (filtro estreitado para
excluir o vermelho, flag de "passa sem testes", hook de commit pulado — `./TESTING.md`,
"Verificação que falha não se contorna").

**Falha**: teste novo vermelho; vermelho novo vs. baseline; vermelho pré-existente
omitido do report; evidência produzida por contorno.

### Gate 3: lint limpo

Zero warnings/erros **novos**. Pré-existentes podem permanecer; o que não pode é ter sido
adicionado agora.

Rode o lint **escopado aos arquivos tocados**, nunca o repo inteiro: lint global em repo
com dívida herdada mede erro de terceiros e dá **falso REPROVADO**.

Ficha **sem `quality.lint`** → o gate degrada **declarado**: reporte `lint: não
configurado na ficha — avaliação por leitura, seção 2 do perfil` e siga; nunca
improvise uma régua própria nem silencie (régua que varia conforme quem revisa é o
pior dos dois mundos — decisão 4.132). A rota para fechar o buraco é `/keelson:init`.

**Falha**: warning/erro novo nos arquivos tocados.

### Gate 4: escopo respeitado

Os arquivos modificados estão no escopo declarado e dentro dos `codePaths` da ficha;
nenhum arquivo do "não inclui" foi tocado. Mudança colateral (não realiza AC nem é
auxiliar) é legítima **somente** se declarada como escoteiro e dentro das três condições
do Charter Art. 6.

E a **pergunta inversa** (decisão 4.142): todo comportamento novo ou alterado no diff tem
**pai declarado** — um AC/critério da TASK que o exige, necessidade técnica direta do que
o AC exige, ou escoteiro dentro das três condições. Capacidade a mais dentro de arquivo em
escopo (endpoint extra, flag "que pode ser útil", comportamento além do AC) é achado
**`não solicitado`**: roteado como achado fora de escopo (sinal ao Tech Lead), e o destino
é decisão declarada — vira requisito assumido registrado ou sai do diff; permanência
silenciosa é a falha. A revisão orientada a AC prova a presença do pedido; este check
prova a ausência do não-pedido.

**Falha**: arquivo fora do escopo; colateral não declarado; "escoteiro" fora das três
condições (muda comportamento, atravessa arquivo, escopo novo rotulado de limpeza);
comportamento sem pai declarado mantido sem decisão (`não solicitado`).

### Gate 5: decisões DEC respeitadas

O código segue as DEC do PLAN e as decisões irreversíveis do INDEX do slug; nenhuma
alternativa descartada entrou por engano. Diff que **satisfaz a condição `Reabrir se:`**
de uma DEC (do PLAN ou do INDEX) vira achado com a DEC citada: a decisão pede reabertura
declarada, nunca remendo silencioso que a contorna (4.97).

**Falha**: implementação contradiz uma DEC; condição de reabertura satisfeita sem
reabertura declarada.

### Gate 6: aderência ao Charter + perfil ativo

- **Stack autorizado**: só a linguagem/versão do perfil ativo (`profile` da ficha).
- **Padrão arquitetural**: camadas, direção de dependência, fluxo (`./ARCHITECTURE.md` + perfil).
- **Naming**: convenções do perfil.
- **Padrão de teste**: runner e estrutura do perfil / `./TESTING.md`.
- **Anti-padrões** proibidos pelo perfil: nenhum presente.
- **Decisões irreversíveis**: nenhuma quebrada.

**Falha**: violação de qualquer item — citar exatamente qual.

### Gate 7: code review qualitativo

O crivo genérico (legibilidade, código morto, tratamento de erro, string hardcoded) é
ofício do revisor — aplique-o sem checklist. Os pontos com régua keelson própria:

- **Naming**: nome genérico onde existe nome de domínio mais específico é smell — ver
  "Sinais de alerta em nomes" abaixo.
- **Condicionais e assinaturas** (Art. 4, 7): aninhamento profundo que guard clause ou
  extração resolveria; condicional-por-variante repetida que pede polimorfismo;
  assinatura longa sem objeto de parâmetro.
- **Abstração especulativa** (Art. 4): indireção ou padrão sem dor demonstrável no diff e
  sem DEC que o justifique — sinalizar (bloqueia quando óbvio).
- **Reúso / DRY** (Art. 3): o código **não reimplementa** utilitário, validação, helper,
  conversão ou abstração que **já existe** no projeto. Não basta checar duplicação entre
  os arquivos novos — procure o equivalente canônico já existente que deveria ter sido
  usado (seção de reúso do perfil ativo · `./ARCHITECTURE.md`). Reimplementação de
  canônico existente = FALHA mesmo com o código correto, **inclusive nos testes**
  (fixtures/helpers — `./TESTING.md`).
- **Comentários** (Art. 7): todo comentário passa no teste de apagar (Perde/Não-perde).
- **Erros já cometidos no projeto**: as lições de `guidelines/project/` valem como regra.
- **Calibração por exemplares**: antes de reprovar por estilo/padrão, compare com código
  análogo já **mergeado** (mesma camada/domínio). Padrão consistente com o repo aprovado
  não é smell — reprove o desvio real, não a divergência com um ideal abstrato.

**Falha**: smell que comprometeria manutenção, ou reimplementação de utilitário existente.

---

## Sem artefato SDD: como a régua degrada

Revisão de código que entrou fora do ciclo (hotfix, código herdado, contribuição externa)
não tem TASK, ACs nem PLAN. Os gates **não são dispensados** — perdem a âncora documental e
passam a se ancorar no diff:

| Gate | Degradação |
|---|---|
| 1 | Sem AC: toda **lógica de negócio nova ou alterada** no diff exige teste falsificável. A exigência de prova não depende de existir AC escrito. |
| 4 | Sem "Escopo > Inclui": o diff **faz uma coisa só**? Alteração não relacionada ao propósito aparente é colateral — legítima só sob as três condições do Art. 6. |
| 5 | Sem PLAN: se o slug for inferível, valem as **decisões irreversíveis do INDEX**; slug não inferível → gate `n/a`, e isso é declarado, não omitido. |

Gates 2, 3, 6 e 7 rodam sem degradação alguma — nenhum deles depende de artefato.

Gate degradado ou `n/a` **é sempre declarado no report**. Silêncio sobre um gate lê-se como
gate aprovado, e essa é a falha que a régua existe para impedir.

---

## Sinais de alerta em nomes (Art. 5, 7)

Nomes genéricos escondem intenção: `process()`, `execute()`, `handle()`, `doStuff()`,
`data`, `info`, `obj`, `temp`, `value`, `result`, `*Manager`, `*Util`. Não são proibição
mecânica — `execute()` num contrato canônico (ex.: um caso de uso de método único) é
legítimo. São **gatilho de pergunta**: *"existe nome mais específico do domínio?"*. Se
existe, o genérico é smell a apontar. Nome que **silencia efeito colateral** (`login()`
que também envia e-mail) é o mesmo smell, mais grave — viola a régua do Art. 5.

---

## Calibração de severidade

**Não bloqueia** (vira sugestão): espaçamento e ordem de imports; nome estranho mas
legível; nome genérico com alternativa de domínio disponível (só bloqueia se esconder
intenção ou efeito colateral); comentário que reprova no teste do Art. 7 — entra como
**remoção sugerida**, com os trechos apontados.

**Bloqueia**: violação de regra explícita do Charter ou do perfil; lógica de negócio sem
teste; escopo violado; reimplementação de canônico existente. Do Art. 7 bloqueiam: bloco
de comentário maior que o código que explica; workaround sem condição de remoção; DEC sem
âncora no ponto do código.

---

## Rejeição imediata

- Vulnerabilidade de segurança (ver `./SECURITY.md`)
- Anti-padrão de arquitetura / quebra da regra da dependência (ver `./ARCHITECTURE.md`)
- Sem teste para a lógica de negócio nova ou alterada
- Reimplementação de código canônico já existente (viola Charter Art. 3)

---

## Régua do revisor: gerador ≠ avaliador

Quem escreveu o código não aprova o próprio diff. A revisão vale pelo **contexto limpo**
(Charter, régua geral); onde não há teste possível (ex.: refactor de legibilidade), a
revisão independente **é** a prova.

---

## Orquestração da rodada: paralelismo e pacote de contexto (decisão 4.89)

Vale para **todo invocador** — ciclo, `/keelson:review` e modo sob demanda.

- **Gates aplicáveis rodam em paralelo por padrão.** Os gates de uma rodada (7 ·
  8 · 9) são independentes entre si: despache os agentes **no mesmo turno** e espere
  os reports. Sequência é exceção **declarada** — só quando um gate consome a saída de
  outro ou disputa recurso exclusivo; "um de cada vez" sem motivo é latência pura.
  Gate cujo mecanismo de prova **muta** arquivos do diff (mutation testing, injeção
  de falha) trata a working tree como recurso exclusivo: roda em `git worktree`
  isolada — nunca a mesma árvore de outro gate concorrente que também mute. Disciplina
  de restaurar ao fim não basta: o risco é a **leitura** na janela em que dois mutantes
  convivem, não a limpeza depois (decisão 4.134, caso real de campo).
- **Pacote de contexto único.** O invocador monta **uma vez** e entrega o mesmo pacote
  a todos os revisores da rodada: diff resolvido + SHA · o artefato-âncora com os
  critérios literais (ACs da TASK, critério de aceite do brief) · as fatias da ficha
  que eles usam (`quality.*`, `sensitiveGlobs`) · a **seção** do perfil a ler · e, em
  re-gate, o veredito anterior + o delta (régua de convergência abaixo). Cada revisor
  redescobrindo o mesmo contexto por conta própria é o maior custo silencioso da
  rodada.
- **O pacote é factual, nunca avaliativo.** Ele carrega o *quê* (diff, âncoras, fatias),
  jamais a opinião de quem o montou — sem hipótese de veredito, sem "acho que está ok,
  confere só X". A revisão vale pelo **contexto limpo** (gerador ≠ avaliador, abaixo);
  direcionar o revisor contamina a independência que dá valor ao gate.
- **O pacote não substitui a régua.** Cada revisor continua lendo a própria régua em
  runtime (este arquivo, `SECURITY.md`, a seção do perfil) — o pacote poupa a
  redescoberta do contexto do trabalho, nunca resume doutrina de memória.

**Recorte da rodada no ciclo (decisão 4.90)** — a unidade de execução de cada gate
segue a natureza do que ele prova, não é uniforme por TASK:

- **Testes por TASK** (gate 2, executados pelo developer) são a rede fina — intocados;
  é o que permite à wave seguinte construir sobre base provada.
- **Revisão independente (gates 1–7) e segurança (gate 8) rodam 1× por wave**, sobre o
  diff acumulado da wave, com o mapa TASK→arquivos no pacote de contexto. A wave é a
  unidade de integração do ciclo; revisar por TASK re-lê o mesmo entorno N vezes, e o
  security **ganha** vendo a interação entre TASKs. Achado é roteado à TASK de origem;
  o retry segue a convergência abaixo. Vulnerabilidade continua **rejeição imediata** —
  o recorte por wave nunca a adia além da própria wave.
- **Comportamento (gate 9) roda por FEAT/história**, na primeira wave em que a FEAT
  completa — é quando o comportamento de ponta a ponta passa a existir; provar "metade
  de uma feature" por TASK duplica o gate 2 ou prova parcial. SPEC sem FEATs → 1× na
  validação final contra o DoD do PLAN. A verificação é **registrada na SPEC** (linha
  `**Verificação (gate 9)**:` sob o heading da FEAT — data e como, ou `n/a — motivo`)
  e cobrada mecanicamente pelo grafo (check `feat-sem-verificacao`, `graph-contract.md`).
- **Adiamento é declarado, nunca silencioso** (régua da 4.85): a closure da TASK
  registra onde cada gate consolidado rodou/rodará (`wave N` · `FEAT-X` · `DoD`).
  No modo sob demanda nada muda: uma mudança = uma rodada.

---

## Convergência do re-gate (decisão 4.88)

Vale para **todo invocador** da régua — ciclo (`/keelson:implement`), diff avulso
(`/keelson:review`) e modo sob demanda. Correção pós-veredito não recomeça a revisão:
ela converge ou escala.

- **Re-review é sobre o delta.** O revisor da rodada N+1 recebe o veredito anterior e o
  **delta da correção**; o que já foi aprovado permanece aprovado, salvo quando o delta
  o toca. Reler o diff inteiro do zero a cada rodada é retrabalho que só produz achado
  marginal novo — e é o motor do loop.
- **O delta é um diff próprio, não um checklist do achado (decisão 4.94).** Código
  nascido no retry ainda não passou por gate nenhum: a rodada N+1 responde **duas**
  perguntas — "o achado fechou?" e "o que este delta quebra?" — aplicando ao delta os
  gates 1–7 na medida em que ele os toca (escopo: a correção alcançou código fora do
  achado?; comportamento observável mudou → reabre o gate 9 daquele recorte), e os
  checks mecânicos do recorte (lint, typecheck, suíte relevante) re-rodam sobre ele
  **sempre** — baratos, e é onde a regressão de retry aparece primeiro. O "salvo quando
  o delta o toca" acima é obrigação ativa do revisor, não exceção que se espera
  acontecer.
- **Teto: 1 retry por gate, depois escala.** Achado → correção → re-review do delta. Se
  o gate reprova de novo, a 3ª rodada **não roda por decisão própria**: escale ao
  Diretor com o estado (o que passou · o que resta · proposta + default). É a mesma
  régua que o `/keelson:implement` sempre teve ("1 retry, depois escala humano"),
  valendo agora em qualquer invocação. Achado de **segurança** persistente escala como
  **bloqueio** — o Diretor decide o rumo; nunca se contorna nem se commita por cima.
  Achado de **ausência de prova** sobre código que o revisor já julga correto (falta o
  teste que mate o mutante, falta cobertura falsificável) **conta para o teto como
  qualquer achado** — não é categoria de exceção (decisão 4.110): o Charter trata
  comportamento sem prova externa e falsificável como **não verificado**, e quem está no
  meio dos retries tem exatamente o incentivo de classificar o restante como "mecânico"
  para não escalar — o conflito que "gerador ≠ avaliador" existe para eliminar, aplicado
  à própria decisão de escalar, que a régua tira das mãos de quem rodou os retries. Caso
  genuinamente mecânico vai **na proposta** da escalação (estado + ação nomeada + default
  "aplicar e fechar"), nunca como justificativa para pulá-la.
- **Achado só-texto não reabre o ciclo.** Correção cujo delta é **inerte** (comentário,
  docblock, doc — teste mecânico em `./TESTING.md`, "Diff inerte") re-verifica com o
  **mesmo revisor**, sobre o delta, e nada mais: os gates de comportamento (1/2/9)
  permanecem válidos porque nada do que eles provam mudou.
- **Narrativa de correção não entra no código.** A explicação de "o que a rodada N
  corrigiu e por quê" vive no report do gate e no histórico do artefato (TASK/brief) —
  nunca em comentário: esse texto fala com o revisor de hoje, não com o leitor de
  amanhã, e reprova no teste de apagar na rodada seguinte (o processo passa a produzir
  o defeito que ele mesmo reprova). O **porquê durável** continua obrigatório no código
  pelo piso do Art. 7 — o endereço muda para a prosa de processo, não a régua de
  conteúdo.

---

## Convergência de fecho: a SPEC inteira contra o código final (decisão 4.143)

O ciclo prova por partes — testes por TASK, revisão por wave, comportamento por FEAT
(4.90). Este passo prova o **todo**: no fecho do ciclo formal, o `code-reviewer` (modo
convergência, read-only) relê a SPEC contra o **estado final** do código e responde o que
nenhum gate por parte responde — o código realiza o que o texto pede, e só o que ele pede?

- **Pacote**: SPEC (FRs/ACs) + DECs do PLAN + diff acumulado da branch + saída do
  `graph.sh` sobre o slug. O grafo é o fato **estrutural** (cobertura FR→AC→TASK no
  texto) — cite-o, não o re-derive; a rodada acrescenta a camada **semântica** (a
  realização no código).
- **Cada lacuna tem um de 4 tipos**, sempre com o source-ref (FR/AC/DEC citado):
  `ausente` — requisito sem realização alguma · `parcial` — existe mas não satisfaz o
  requisito por inteiro · `contradiz` — o código conflita com um FR ou uma DEC ·
  `não solicitado` — capacidade sem pai declarado (a régua do gate 4/4.142 aplicada ao
  acumulado da branch).
- **Outcome declarado, nunca implícito**: `convergiu` ou a lista de gaps. Gap segue o
  fluxo normal — correção antes do push (régua de re-gate acima, 1 retry) ou parte
  estacionada com a pergunta pronta na Entrega; push silencioso com gap aberto é a
  falha que o passo existe para impedir.
- **Registro reaproveitável** (padrão da 4.122): rodada `convergiu` entra no "Histórico
  recente" do INDEX como `<data>: convergência de fecho verde em <SHA>`; o
  `/keelson:integrate` a reaproveita quando `git diff <SHA>...HEAD` é inerte (régua em
  `./TESTING.md`, "Diff inerte") — sem registro válido, a rodada corre lá.

Sem SPEC (rotas inline, TASK avulsa) o passo não existe — o espelho do brief e a
aceitação do PO são o fecho proporcional dessas rotas.

---

## Formato de saída

**Aprovado:**

```text
✅ APROVADO
- Pontos positivos
- Sugestões (opcionais)
```

**Rejeitado:**

```text
❌ CORREÇÕES NECESSÁRIAS
1. `arquivo:linha` — Problema → Solução
```

A **Solução nomeia a condição, nunca só uma instância dela** — mesma régua da doutrina
(4.32: regra = teste, não enumeração): "trate todo código de erro do transporte", não a
lista dos códigos conhecidos hoje. Enumeração fechada só acompanhada do teste que prova
completude. Instância cumprida à risca que diverge da condição nasce como correção
incompleta — e nada acusa (decisão 4.93).

E quando o achado deriva de um requisito **MUST multi-sujeito** (ex.: "para cada A, B
e C"), o **fechamento** re-lê o texto do FR/AC de **origem** e confirma cobertura de
**todos** os sujeitos nomeados — não só os que o Problema citou (decisão 4.109). Achado
que cita 2 de 3 e retry que fecha exatamente os 2 citados deixa o terceiro com dado no
contrato e **sem consumidor**, sem que nada acuse; a régua acima não alcança este caso —
o achado não era enumeração fechada de instâncias, era citação parcial e honesta de um
requisito — e a re-leitura da origem é o complemento.
