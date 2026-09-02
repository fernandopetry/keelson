# Code Review (core)

> **Dono único da régua dos gates 1–7** — o que cada gate exige, o que o faz falhar e como
> ele degrada quando não há artefato SDD. Quem a executa é sempre o **`code-reviewer`**, em
> dois fluxos: dentro do ciclo (via `/keelson:implement`, com TASK/PLAN/SPEC) e sobre um
> diff avulso (via `/keelson:review`, modo degradado). Os fluxos trazem o próprio
> protocolo — input, output, retry —, nunca uma segunda cópia da régua.
>
> A **segurança** (gate 8), o **comportamento verificado** (gate 9), a **performance**
> (gate 10) e o **design/UX** (gate 11) têm revisores dedicados (`security-engineer`,
> `qa`, `performance-engineer`, `product-designer`) e doutrina própria — ver
> `./WORKFLOW.md` (gate 10: gabarito em `./PERFORMANCE.md`, decisão 4.155; gate 11:
> gabarito em `./DESIGN.md`, decisão 4.218).
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
- AC quantificado ("todos os X") coberto só pelo caso default;
- teste-prova em **grupo/tag/marcador que a configuração default da suíte não
  seleciona** (decisão 4.226): confronte o marcador de cada teste novo com as exclusões
  da config do runner — teste excluído da rodada default existe e passa isolado, mas
  **nunca roda** onde o time olha (caso real: provas de segurança de 2 waves inertes,
  4ª ocorrência no mesmo projeto). O dono da régua na geração é `commands/tasks.md`
  (4.161/4.215 — fixação com conjunto não-vazio); aqui é o momento do gate;
- fechamento de prova por **mutação** sem o eixo declarado por mutante, ou com todos
  os mutantes no eixo que o AC já motivava — nenhum no ponto cego do próprio
  instrumento (decisão 4.331; régua no mesmo dono, `./TESTING.md`).

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

**Spec E2E editado no diff** (`quality.e2e` na ficha — decisão 4.166): a edição de
asserção/seletor de spec existente cita a mudança intencional de AC/SPEC que a
justifica (dono da régua: `./TESTING.md`, "Specs E2E"). Spec vermelho reescrito para
verde sem AC alterado é achado deste gate — mesma violação do repro vermelho (4.159).

**Falha**: teste novo vermelho; vermelho novo vs. baseline; vermelho pré-existente
omitido do report; evidência produzida por contorno; edição de spec E2E sem a mudança
de AC/SPEC que a justifique.

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
- **Invariantes do projeto** (`guidelines/project/invariants.md`, quando existe — 4.242):
  nenhum violado pelo diff. Arquivo ausente → `n/a (sem invariants.md)` declarado no
  veredito do gate, nunca omitido. A régua do artefato mora em `./ARCHITECTURE.md`
  (seção "Invariantes do projeto").
- **Doc-trap fechada pelo próprio diff**: quando a correção elimina exatamente um
  defeito que o perfil/guideline do projeto documenta como armadilha ainda viva
  (linguagem tipo "não conte com", "ainda não faz", "armadilha verificada e viva"), o
  mesmo commit atualiza esse parágrafo — perfil que segue descrevendo como presente um
  defeito que o diff acabou de fechar ensina o próximo developer a remendar na tela o
  que a primitiva já resolve. **E a via inversa tem a mesma obrigação (decisão
  4.339)**: gate que constata **staleness do perfil** — o perfil prescreve o que a
  casa comprovadamente não usa (runner, convenção, primitiva) — não para na
  declaração: o achado vira **item roteado** com destino registrado (a linha curta de
  atualização no parágrafo do perfil ativo, mesma rota da armadilha acima; perfil
  `reviewed: true` → a edição pede re-olhada humana, sinalizada na entrega). Declarar
  a staleness e acertar apesar do perfil deixa o perfil envenenando as próximas
  gerações — mesma disciplina dois-registros da 4.199/4.204.

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
  conversão ou abstração que **já existe** no projeto — e "já existe" tem **três
  superfícies de busca**, nenhuma dispensando as outras (decisão 4.207): **(a)** o
  próprio diff da rodada — funções quase equivalentes entre TASKs da mesma wave;
  **(b)** o acumulado da branch da demanda — equivalente nascido em **wave anterior do
  mesmo PLAN** ainda não é canônico documentado nem aparece no diff da rodada; procure-o
  entre os arquivos/símbolos **criados** na branch, por nome/assinatura (ex.: `git diff
  --name-status --diff-filter=A <base>...HEAD`), nunca relendo o acumulado inteiro —
  base pela mesma resolução do `/keelson:review`; sem base determinável (working tree
  na própria base, diff avulso sem branch), superfície `(b): n/a`, **declarado**;
  **(c)** o canônico documentado (seção de reúso do perfil ativo · `./ARCHITECTURE.md`).
  O **alvo do achado é sempre o diff da rodada** — o equivalente anterior é o canônico a
  reusar/estender, nunca reprovado retroativamente (4.88: aprovado permanece aprovado;
  consolidar o antigo → `fora_de_escopo`). Reimplementação de equivalente existente =
  FALHA mesmo com o código correto, **inclusive nos testes** (fixtures/helpers —
  `./TESTING.md`).
- **Comentários** (Art. 7): todo comentário passa no teste de apagar (Perde/Não-perde).
  O report traz o **inventário contável** dos comentários que o diff introduz/altera
  (decisão 4.250, escada 4.149): N introduzidos/alterados, e para cada reprovado o eixo —
  narrativa de **proveniência** ou de **comparação temporal** (definição operacional no
  autocheck do `developer`, 4.185), paráfrase/ritual, ou bloco maior que o código que
  explica. O inventário é fato **julgado pelo revisor**, nunca oráculo mecânico sobre o
  texto do código (anti-padrão do parser textual — `./TESTING.md`, 4.227); reprovado que
  não cai nas violações bloqueantes do Art. 7 vai para a remoção sugerida da §Calibração
  — não bloqueia, não abre rodada.
- **Rastro de processo em copy** (decisão 4.201): identificador de artefato SDD (`FR-`/`AC-`/`TASK-`/`DEC-`… — catálogo no `index-contract.md`) **visível ao usuário** — label, mensagem, texto de template — é rastro vazado, não copy, **salvo quando um AC exige a exibição** (tela de rastreabilidade/admin legítima): o discriminante é o pai declarado da pergunta inversa (gate 4), não proibição mecânica. Os endereços legítimos do ID seguem os de sempre — comentário-âncora (Art. 7) e tag `@AC-NNN-XXX` de spec E2E; a fronteira é a superfície do usuário, não o código.
- **Erros já cometidos no projeto**: as lições de `guidelines/project/` com `Estado: ativa`
  valem como regra (`em-observacao` é contexto, nunca reprova; `revogada` não vale — ciclo
  de vida: `core/WORKFLOW.md`, decisão 4.221). Lição ativa que bloquearia caso legítimo
  não é licença para reprovar em silêncio: o contorno fundamentado vira `licao_contestada`
  no report do developer.
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
**remoção sugerida**, com os trechos apontados (`arquivo:linha`). A sugestão **nunca abre
rodada nem conta como falha — e nunca morre no report** (decisão 4.249; caso real de
campo: rodada sem retry shippava o comentário reprovado): com retry aberto por outro
achado, pega carona no despacho (delta inerte — re-verifica com o mesmo revisor,
§Convergência); sem retry, a rota de fecho do invocador a aplica antes da entrega — no
ciclo, 1 aplicação por wave no fim dela (`/keelson:implement` §3.6); no diff avulso, a
leva de correções do `/keelson:review`; no sob demanda, a própria rodada. A aplicação
**corta exatamente a lista apontada** — nunca varredura própria, nunca reescrita (4.185)
— declara a contagem (`N sugeridas → N aplicadas / N contestadas`) e aceita contestação
de uma linha: comentário que carrega semântica (anotação, diretiva de ferramenta) ou que
o developer julga carga fica, com o motivo no report. A remoção barata continua a do
developer no autocheck, antes do gate (decisão 4.245).

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

E **confirmar uma premissa sobre o VALOR de um campo não é confirmar seu CABEAMENTO**
(decisão 4.322) — que ele lê de uma propriedade/coluna dedicada: os dois atos terminam
na mesma frase ("confirmei na fonte") sem provar a mesma coisa, e um tipo permissivo
(`T | null`) acomoda as duas leituras sem que nada mecânico acuse a diferença. Premissa
sobre o comportamento num **estado/ramo específico** exige traçar a lógica que **atribui**
o valor nesse ramo — nunca só a origem declarada do campo, nem a palavra do comentário
vizinho, que pode estar descrevendo outro ramo (caso real: cabeamento correto — o campo
lia a propriedade dedicada — mas o ramo em pauta emite `null` fixo; o comentário do
próprio ramo descrevia o ramo oposto e sustentou a confirmação errada por 2 rodadas).

E achado que afirma o que o código **faz** com um dado real — vaza, mascara, calcula,
recusa — prova-se com o **predicado executado contra o dado** (decisão 4.329, o simétrico
de reprovação da régua de aprovação do gate 8, 4.264): inspecionar a olho a mesma
lista/tabela que o diff copiou não é medição independente — brief, implementação e
revisor concordando sobre essa fonte é **uma leitura copiada três vezes**, não tripla
confirmação (caso real: gate 7 reprovou ALTA por "dado pessoal em claro" conferindo a
implementação contra a tabela do brief, sem rodar a máscara contra o campo; o campo já
era mascarado por colisão de substring — e o gate 8, que executou o predicado com
controle positivo, reportou o fato certo na mesma rodada; custo: um retry inteiro numa
entrega correta). Achado dessa forma cujo tópico é do gate 8 (dado pessoal, segredo,
autorização) viaja como **sinal ao `security-engineer`** — nunca veredito independente
sem execução.

---

## Orquestração da rodada: paralelismo e pacote de contexto (decisão 4.89)

Vale para **todo invocador** — ciclo, `/keelson:review` e modo sob demanda.

- **Quais gates são aplicáveis se deriva do diff, nunca da memória (decisão 4.335).**
  Antes de despachar a rodada, confronte o diff com a lista canônica de cada gate
  dedicado (8 · 10 · 11, nas descriptions dos agents; 9 pelo comportamento observável)
  e declare **sim/não por gate** — é essa derivação que a tabela do fecho (régua
  simétrica 4.85) transcreve, nunca o inverso. O fim de wave do ciclo já tem o
  inventário mecânico (4.197); esta régua leva o mesmo confronto ao **momento do
  despacho** em toda rota — gate lembrado só no fecho é o furo que o inventário
  previne (caso real de campo, modo sob demanda: diff tocando laço de render sobre
  volume variável, gate de performance não despachado; auto-detectado apenas na
  montagem do fecho, e o gate, despachado então, mediu decomposição que o palpite
  não tinha).
- **Gates aplicáveis rodam em paralelo por padrão.** Os gates de uma rodada (7 ·
  8 · 9 · 10) são independentes entre si: despache os agentes **no mesmo turno** e espere
  os reports. Sequência é exceção **declarada** — só quando um gate consome a saída de
  outro ou disputa recurso exclusivo; "um de cada vez" sem motivo é latência pura.
  Gate cujo mecanismo de prova **muta** arquivos do diff (mutation testing, injeção
  de falha) trata a working tree como recurso exclusivo: roda em `git worktree`
  isolada — nunca a mesma árvore de outro gate concorrente que também mute. Disciplina
  de restaurar ao fim não basta: o risco é a **leitura** na janela em que dois mutantes
  convivem, não a limpeza depois (decisão 4.134, caso real de campo). E **árvore
  própria é `git worktree` de fato, nunca cópia do diretório de trabalho** (decisão
  4.336): a cópia (`cp -R`) carrega o que o git não versiona — `.env`, config local
  com credencial — e planta segredo real fora do repo (caso real: dois gates
  independentes, sem o COMO no contrato, copiaram o repositório inteiro com o `.env`
  para o scratchpad; o worktree, por construção, deixa untracked para trás). Prova que
  monta a árvore em container monta o caminho **read-only** e escreve fora dele —
  arquivo novo criado dentro de caminho montado nasce no repo real (caso real: sonda
  0-byte apareceu na árvore verdadeira). E a rodada
  inteira pressupõe **âncora parada** (decisão 4.290 — 3ª camada da família
  4.134/4.276): todo gate despachado captura, na largada da própria execução, o par
  `git rev-parse HEAD` + `git status --porcelain` dos arquivos do diff e o reconfere
  antes do veredito — divergência descarta o veredito e re-roda (ou escala), nunca
  emite sobre árvore possivelmente mutada por gate concorrente; e o **orquestrador**
  trata o SHA sob revisão como âncora parada: com veredito em voo, nenhum commit novo
  entra na working tree — a correção espera, ou o gate é re-despachado com a âncora
  nova **declarada**, nunca herdada em silêncio ("gerador ≠ avaliador" pressupõe
  âncora parada; caso real: 2× na mesma sessão, o revisor congelou por hash próprio e
  re-rodou os mecânicos — trabalho que o despacho causou).
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
- **Divergência factual entre dois gates da mesma rodada, antes de qualquer retry,
  arbitra-se por verificação própria citada** (decisão 4.322) — nunca por antiguidade,
  severidade ou especialidade do gate, nem por voto. Paralelismo e pacote único (acima)
  não impedem dois revisores medirem a mesma grandeza sob o mesmo nome com **unidades
  diferentes**, ou descreverem em prosa idêntica dois trechos de código genuinamente
  **distintos**: antes de decidir um lado, pergunte **"os dois podem estar certos?"** —
  a divergência costuma ser aparente, e escolher um lado sem essa checagem descarta um
  achado real. Resolva abrindo o arquivo/rodando o comando você mesmo e leve o veredito
  ao despacho do retry **com a evidência que decidiu**, para o revisor que errou se
  corrigir de forma explícita (casos reais: dois gates divergiram sobre o custo de uma
  rota — um contava *use cases*, o outro chamadas HTTP, e a unidade ambígua nascera no
  próprio pacote de contexto; dois revisores divergiram sobre a posição de um card —
  certos sobre condicionais distintas do mesmo componente, e os dois achados
  sobreviveram como itens do retry).

**Recorte da rodada no ciclo (decisão 4.90)** — a unidade de execução de cada gate
segue a natureza do que ele prova, não é uniforme por TASK:

- **Testes por TASK** (gate 2, executados pelo developer) são a rede fina — intocados;
  é o que permite à wave seguinte construir sobre base provada.
- **Revisão independente (gates 1–7), segurança (gate 8), performance (gate 10) e
  design (gate 11) rodam 1× por wave**, sobre o diff acumulado da wave, com o mapa
  TASK→arquivos no pacote de contexto. A wave é a unidade de integração do ciclo;
  revisar por TASK re-lê o mesmo entorno N vezes, e security, performance e design
  **ganham** vendo a interação entre TASKs (a guarda relaxada, o N+1 e a divergência
  de padrão entre telas que atravessam TASKs não aparecem em revisão isolada). Achado
  é roteado à TASK de origem; o retry segue a convergência abaixo.
  Vulnerabilidade continua **rejeição imediata** — o recorte por wave nunca a adia além
  da própria wave.
- **Comportamento (gate 9) roda por FEAT/história**, na primeira wave em que a FEAT
  completa — é quando o comportamento de ponta a ponta passa a existir; provar "metade
  de uma feature" por TASK duplica o gate 2 ou prova parcial. SPEC sem FEATs → 1× na
  validação final contra o DoD do PLAN. A verificação é **registrada na SPEC** (linha
  `**Verificação (gate 9)**:` sob o heading da FEAT — data e como, ou `n/a — motivo`)
  e cobrada mecanicamente pelo grafo (check `feat-sem-verificacao`, `graph-contract.md`).
- **Adiamento é declarado, nunca silencioso** (régua da 4.85): a closure da TASK
  registra onde cada gate consolidado rodou/rodará (`wave N` · `FEAT-X` · `DoD`).
  **E adiar exige o confronto com os ACs da própria task** (decisão 4.333): antes de
  aceitar um achado como carry-over da wave seguinte, confronte o comportamento
  apontado com os ACs vinculados da task corrente — achado que viola AC dela é
  **bloqueante dela**, seja qual for a severidade que o próprio gate sugeriu (caso
  real: achado de design enquadrado "média, não bloqueia" roteado como carry-over; a
  sonda do code review provou que violava AC da task em execução — empurrar entregaria
  a wave com um AC descumprido). Rotear a lição do achado nunca substitui esse
  confronto: são registros de estados independentes (4.199/4.204).
  E o handoff declara **a quem** o invariante deferido se dirige (decisão 4.288):
  `critério da TASK` (a wave seguinte tem o arquivo/contrato para satisfazê-lo — e
  ele entra no despacho como critério, 4.140) ou `medição do revisor` (só a
  ferramenta do próprio gate produz o número; o resultado vira demanda ao Diretor,
  nunca reprovação de TASK que não tinha como entregá-lo). Handoff sem a etiqueta
  obriga quem orquestra a wave seguinte a adivinhar — reprovar código correto ou
  deixar risco real sem medição (caso real: "mostre que a contagem não cresce com N"
  deixado à wave seguinte sem dizer de quem era; só o contador do próprio gate,
  sobre volumes reais, podia produzi-la).
  No modo sob demanda nada muda: uma mudança = uma rodada.

---

## Convergência do re-gate (decisão 4.88)

Vale para **todo invocador** da régua — ciclo (`/keelson:implement`), diff avulso
(`/keelson:review`) e modo sob demanda. Correção pós-veredito não recomeça a revisão:
ela converge ou escala.

- **Re-review é sobre o delta.** O revisor da rodada N+1 recebe o veredito anterior e o
  **delta da correção**; o que já foi aprovado permanece aprovado, salvo quando o delta
  o toca. Reler o diff inteiro do zero a cada rodada é retrabalho que só produz achado
  marginal novo — e é o motor do loop. O delta chega no pacote como **diff resolvido do
  retry** (`git diff <SHA do veredito>..<SHA da correção>`, com o veredito anterior ao
  lado), nunca como o diff acumulado da wave (decisão 4.350 — caso real de campo: um
  re-review "delta" de 2 arquivos releu o entorno inteiro, 48 leituras e greps, e custou
  16,9 min contra 11 da primeira passada).
- **O delta é um diff próprio, não um checklist do achado (decisão 4.94).** Código
  nascido no retry ainda não passou por gate nenhum: a rodada N+1 responde **duas**
  perguntas — "o achado fechou?" e "o que este delta quebra?" — aplicando ao delta os
  gates 1–7 na medida em que ele os toca (escopo: a correção alcançou código fora do
  achado?; comportamento observável mudou → reabre o gate 9 daquele recorte), e os
  checks mecânicos do recorte (lint, typecheck, suíte relevante) re-rodam sobre ele
  **sempre** — baratos, e é onde a regressão de retry aparece primeiro. O "salvo quando
  o delta o toca" acima é obrigação ativa do revisor, não exceção que se espera
  acontecer. E quando o achado classifica um estado como "reagiu ao **gatilho
  errado**" sobre dois eixos independentes (identidade do assunto exibido × critério
  de conteúdo), "o que este delta quebra" inclui levar ao extremo o eixo que a
  correção **não** tocou (decisão 4.289): o espaço tem dois lados por construção —
  reagir de menos / reagir de mais — e verificar só o lado que motivou a correção é
  meio teste (caso real: proteção por identidade fechava sozinha; a troca para a
  chave de assunto passou a expandir sozinha — cada correção passou no próprio teste
  e reabriu o lado oposto).
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
- **Achado de classe fecha com a varredura como entregável (decisão 4.173).** Quando o
  achado nomeia um padrão repetível por busca (comentário, chamada, import, nomenclatura)
  e cita exemplos, os exemplos são **ilustração, nunca a lista de tarefas**: o retry
  entrega a varredura — comando literal, universo/range varrido, saída final vazia,
  falsos positivos separados com justificativa e exclusões com dono. O revisor
  **re-executa o comando**; é isso que ele valida — declaração de "varri tudo" sem o
  comando não fecha o achado, porque não distingue "a classe fechou" de "os exemplos que
  o revisor viu fecharam". Caso real: 4 rodadas corrigindo os exemplos citados; na 3ª, o
  report declarou 3 arquivos e a mesma string sobrevivia em 8 outros dentro do range.
- **Evidência mecânica de ausência carrega controle positivo (decisão 4.186).** "O
  comando retornou 0 ocorrências" só é evidência se, no mesmo universo e na mesma
  execução, um padrão que **tem** de bater bateu — sem o controle, "limpo" é
  indistinguível de "o comando nunca executou". Caso real: 5 greps de prova falharam por
  expansão de shell e um `|| echo 0` converteu o erro em "0 ocorrências"; só a
  auto-auditoria do revisor evitou o falso "limpo". A falsificabilidade dos gates
  (4.52/4.93) cobre o código sob revisão; esta cláusula cobre o **instrumento do
  avaliador** — inclusive o comando re-executado da varredura (4.173).
- **Varredura por classe tem teto declarado; eixo novo é decisão, não deriva (decisão
  4.187).** A convergência (4.88/4.94) trava o retry do **mesmo** achado; numa varredura
  cujo aceite é "nenhuma instância da classe sobra", cada rodada tende a descobrir
  **escopo novo** — outro eixo do mesmo defeito — e nenhuma dispara a escalação, porque
  cada descoberta parece legítima demais para não perseguir (caso real: 9 rodadas, cada
  uma "achado novo"). Por isso a varredura nasce com **teto de rodadas de gate declarado
  no despacho (default 2)**: eixo genuinamente novo além do teto não roda — vira dívida
  declarada em artefato-fonte, brief/PLAN, espelhada no INDEX pela regeneração (4.179 —
  com a régua registrada para quem pagar) ou decisão explícita
  do Diretor de estender (proposta + default, 4.85). Padrão de corte ambíguo (manter ou
  cortar `X`?) se decide **antes** do despacho, uma vez para todos os lotes — sublotes
  com réguas opostas são retrabalho certo. Limite conhecido do fecho por busca: rótulo
  removido pode deixar referência órfã **em outro arquivo** (A caracteriza um trecho de
  B que o lote mudou — o ponteiro não é rótulo, é caracterização, e nenhum grep de
  rótulo o alcança); a varredura de remoção confere as referências ao trecho editado,
  não só o arquivo dele.
- **O re-gate também pergunta "a prova ficou mais fraca?" (decisão 4.174).** Delta que
  muda a semântica de um caso já provado (inverter um default, trocar a condição de um
  ramo) **acrescenta** teste ao lado — o teste do ramo antigo permanece com o fixture
  discriminante. Reescrever o existente deixa um teste com nome plausível, passando, que
  não discrimina mais — e nenhuma leitura acusa. O fechamento é comparado: o mutante que
  neutraliza o valor alterado morre **no delta e no commit pai**; sobreviver só no delta
  é regressão de prova, achado bloqueante. Caso real: o único teste do ramo invertido foi
  reaproveitado e a suíte inteira (4107 verdes) deixou de provar que o gate bloqueava.
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
- **Passada de dedup da entrega** (decisão 4.253 — revisão declarada do recorte da
  4.207): a rodada aplica a superfície (b) do bullet Reúso/DRY do gate 7 (dono da
  mecânica de busca, da base e da degradação declarada) ao acumulado da **entrega
  inteira** — quase-equivalentes entre os símbolos/arquivos **criados** na branch, e
  deles contra o canônico documentado. Muda o momento e o efeito, nunca a régua: achado
  de duplicação **não é gap e nunca bloqueia o fecho** — vira pendência de consolidação
  com as âncoras dos dois lados, roteada como `fora_de_escopo` (consolidar é diff novo
  para frente — 4.88: aprovado permanece aprovado). Achado que uma wave já roteou não
  reaparece: a passada existe para o que nenhuma wave viu. O outcome declara a
  componente sempre: `dedup: aplicada — N achados | n/a — sem base determinável`.
- **Outcome declarado, nunca implícito**: `convergiu` ou a lista de gaps. Gap segue o
  fluxo normal — correção antes do push (régua de re-gate acima, 1 retry) ou parte
  estacionada com a pergunta pronta na Entrega; push silencioso com gap aberto é a
  falha que o passo existe para impedir.
- **Registro reaproveitável** (padrão da 4.122): rodada `convergiu` entra no "Histórico
  recente" do INDEX como `<data>: convergência de fecho verde em <SHA> (dedup: aplicada |
  n/a — sem base)`; o `/keelson:integrate` a reaproveita quando `git diff <SHA>...HEAD` é
  inerte (régua em `./TESTING.md`, "Diff inerte") — sem registro válido, a rodada corre
  lá. Selo sem o marcador de dedup (legado) cobre só a componente SPEC: no
  reaproveitamento, a passada de dedup roda mesmo assim.

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

**A mesma disciplina — condição, nunca endereço ou instância — vale em qualquer ponto
do ciclo que nomeie o alvo de uma verificação, correção ou remoção, não só na Solução
deste gate** (decisão 4.321 — régua-mãe da família 4.93 · 4.139/4.232 · 4.302a ·
4.307): Escopo/Inclui e Critério de pronto na geração das TASKs, item de retry na
composição do despacho, achado de gate dedicado (8/10/11) na escrita — todos citam a
**condição do domínio** ("nenhuma superfície afirma X", "todo escritor do estado
espelhado", "todo chamador da operação recusada"), nunca a lista fechada de
endereços/instâncias vista no momento da redação; lista citada é sempre rotulada
**ilustração não-exaustiva**, acompanhada da varredura de fechamento que a torna
falsificável (caso real: remoção de premissa revogada escopada ao endereço técnico —
"comentários/docblock" — sobreviveu exatamente na copy que o operador lê; reescrita
como condição, a varredura achou 3 superfícies onde dois revisores, pensando por
endereço, tinham visto 2).

E quando o achado deriva de um requisito **MUST multi-sujeito** (ex.: "para cada A, B
e C"), o **fechamento** re-lê o texto do FR/AC de **origem** e confirma cobertura de
**todos** os sujeitos nomeados — não só os que o Problema citou (decisão 4.109). Achado
que cita 2 de 3 e retry que fecha exatamente os 2 citados deixa o terceiro com dado no
contrato e **sem consumidor**, sem que nada acuse; a régua acima não alcança este caso —
o achado não era enumeração fechada de instâncias, era citação parcial e honesta de um
requisito — e a re-leitura da origem é o complemento.

A mesma enumeração-na-fonte vale quando a mudança **passa a recusar** operação que
antes completava — guarda nova, validação, confirmação exigida (decisão 4.278): a
cobertura se deriva dos **chamadores reais** da operação recusada (grep pelo
método/rota/use case), nunca da lista de telas lembradas, e cada chamador declara a
resposta à recusa — trata e reoferece, passa a confirmação explícita, ou não se
aplica; chamador sem resposta declarada é buraco, não detalhe. Fechamento contável no
formato já provado (4.139): N chamadores no grep, N respostas declaradas. Promessa de
SPEC do tipo "o sistema nunca impede X" só está provada com **toda** superfície que
faz X exercitada — 3 de 4 é promessa quebrada com aparência de entregue (caso real: a
4ª superfície virou beco sem saída em produção). Demarcação: a "Guarda no sink"
(`core/SECURITY.md`) enumera os **writers** de dado sensível; esta régua, os
**chamadores** de operação que passou a poder recusar — recusa funcional, sensível ou
não.
