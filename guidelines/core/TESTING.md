# Testes (core)

> Princípios de teste **agnósticos de linguagem**. Instanciam o **Art. 1** (correção é
> provada, não afirmada) e o **Art. 9** (pronto inclui prova) do
> `../_meta/QUALITY-CHARTER.md`. O runner, os atributos e a organização de arquivos
> **concretos** ficam no perfil de linguagem (`../backend/*.md`, `../frontend/*.md`), que
> alimenta o comando `quality.test` de `keelson.config.json`.

---

## Filosofia: prova externa de comportamento

Um teste existe para **provar comportamento**, não implementação. Antes de escrever um,
pergunte: **"qual regra este teste valida?"** Se você não sabe responder, **não escreva o
teste** — ele só vai travar a refatoração sem proteger nada.

A prova precisa ser **externa e falsificável**: um teste que **falharia** se o
comportamento regredisse (Charter — régua "gerador ≠ avaliador").

| ✅ Testar | ❌ Não testar |
|-----------|--------------|
| Regras de negócio | Conexão com infraestrutura |
| Cálculos e decisões críticas | Getters/setters triviais |
| Validações de domínio e invariantes | Se um objeto foi instanciado |
| Casos de borda | Detalhe de implementação de terceiros |

---

## Estrutura AAA

```text
Arrange (preparar) → Act (executar) → Assert (verificar)
```

Cada teste tem **um** Act claro. Quando os blocos ficam longos, separe as três seções
visualmente para que o leitor veja de imediato o que é preparação, o que é a ação sob
teste e o que é a verificação.

---

## Cobrir comportamento, não implementação

- Teste **pela interface pública** da unidade — entradas e saídas observáveis, não
  estado interno. Assim a refatoração que preserva comportamento não quebra o teste.
- **Mocke o que é I/O e colaboradores externos** (portas do domínio); **não mocke** a
  lógica que você está testando. Excesso de mock testa o mock, não o código.
- Prefira **um caso por regra** com nomes que digam a regra (sucesso e falha esperada),
  em vez de um teste gigante que verifica tudo.
- Use **tabela de casos** (parametrização) para varrer entradas equivalentes sem
  duplicar o corpo do teste.

---

## Asserções que provam (anti-tautologia)

Uma asserção só prova algo quando o valor esperado tem **origem independente** do código
sob teste — um teste tautológico ou de asserção fraca **existe, roda e passa**, mas é
incapaz de falhar junto com o comportamento. Quatro regras mecânicas (todas achado
bloqueante no gate 1 — `./CODE-REVIEW.md`):

- **Esperado independente do gerador**: asserção cujo valor esperado é **calculado
  chamando o código de produção** (a própria unidade sob teste ou o helper que ela usa
  para produzir a saída) é tautologia — passa para qualquer comportamento, certo ou
  errado. O esperado é um **literal** ou construído por caminho independente do gerador.
- **Unicidade se prova contando**: requisito "aparece exatamente uma vez" não se prova
  com asserção de "contém" (ela passa com 1 **ou N** ocorrências) — exige **contagem**
  de ocorrências comparada ao esperado.
- **Um caso por ramo de fallback**: cadeia de fallback (`A senão B senão C`) tem um
  teste por ramo. Fixture com todos os campos sempre preenchidos exercita só o primeiro
  ramo e deixa os demais **invisíveis por construção** — o fixture tem a forma **real**
  do dado (campos ausentes/vazios existem em produção), não a forma que o código espera.
- **Quantificador vira tabela**: requisito quantificado ("todos os locales", "cada
  tipo", "os N países") exige um caso por elemento — ou por classe de equivalência
  **demonstrada** — via tabela de casos. Só o caso default testado = AC não coberto.
- **Mutante se escolhe pelo ponto cego do instrumento (decisão 4.331)**: fechamento
  de prova por mutação declara, por mutante, o **eixo** que ele ataca — e mutante
  cujo eixo o AC já motivava não fecha sozinho: quem monta a tabela a partir do que
  acabou de escrever gera os mutantes que lhe ocorreram, nunca o que o próprio
  instrumento não vê. Pelo menos um mutante deriva da **forma do instrumento** — o
  que o tornaria incapaz de falhar: fixture de ordenação cuja ordem de inserção
  coincide com a esperada não distingue "ordenou" de "não ordenou" (o mutante que a
  neutraliza sobrevive à suíte inteira); contador de uma rota não vê o efeito novo
  que nasce noutra rota (o mutante que o acrescenta sobrevive). Caso real: tabela
  declarada **e rodada**, 10 de 13 mutantes morrendo — e os 3 sobreviventes
  atacavam, cada um, o ramo que o AC motivava, nenhum o ponto cego; com a régua
  derivada da forma do AC no retry, os 6 morreram e o gate acrescentou 10 próprios.
- **Predicado correlacionado exige o agregado vizinho (decisão 4.175)**: predicado que
  vincula filho ao pai (escopo de tenant, correlação de subconsulta, junção por dono)
  tem **dois** modos de falha e por isso duas provas — apagar o **predicado** (morre com
  um agregado só) e apagar a **correlação** (só morre com um segundo agregado no
  fixture: duas linhas, uma satisfazendo e outra não). Fixture de um agregado deixa o
  mutante de maior raio invisível por construção — caso real: apagar a correlação
  sobreviveu a 51/51 testes, e em produção recusaria toda submissão de todo usuário.
- **Guard textual nasce como inventário, nunca como parser (decisão 4.227)**: teste ou
  guard que prova propriedade do código-fonte por varredura de texto nasce com
  **universo declarado e fechamento contável** — uma lista fechada (allowlist de
  arquivos/símbolos, inventário "N no escopo, N provados") confrontada com o universo
  real, controle positivo incluso (a régua do avaliador é a 4.186) e degradação para
  aviso quando não parseia. Tentar **reconhecer todas as formas da linguagem** por
  regex é fail-open por construção: cada idioma não previsto passa em silêncio (caso
  real: 3 rodadas de gate acrescentando formas de escrita SQL até trocar o oráculo por
  allowlist). O caso irmão no **critério de TASK** já tem dono — `commands/tasks.md`,
  item (b) da 4.161 (grep ancorado em estrutura); este bullet cobre o guard entregue
  como teste.
  Corolário para invariante **fotografado** (valor congelado no filho × config vigente
  no pai): os defaults do builder compartilhado nascem **divergentes** — pai e filho com
  o mesmo valor tornam ler um ou outro indistinguível, e a guarda vira decoração.
- **Equivalência entre dois caminhos se prova na dimensão não-neutra (decisão 4.280)**:
  teste que afirma que dois caminhos de cálculo produzem o mesmo resultado se escreve
  na dimensão em que o fator que os **distingue** é não-neutro (fração ≠ 1, peso ≠ 1,
  desconto ≠ 0) — a dimensão neutra entra como **controle**, nunca como o caso: no
  eixo neutro os caminhos são trivialmente iguais e o teste **não tem como falhar**
  com a divergência presente (caso real: verde por 6 waves com o bug vivo). A escolha
  do eixo se prova por mutação na fixação: neutralizar o fator na fonte tem de
  **reprovar** — se o teste sobrevive, ele está no eixo errado.

---

## Mutação: a suíte também está sob prova (decisão 4.121)

As regras acima são verificadas por **revisão** (gate 1 — um avaliador lendo o teste).
Mutation testing é a versão **mecânica** da mesma régua: muta o código de produção e
prova que a suíte **falha** — "gerador ≠ avaliador" do Charter aplicado à própria suíte.
Um mutante sobrevivente é um comportamento que pode regredir sem que teste algum acuse.

- **Opt-in pela ficha**: campo `quality.mutation` (default `null`). O valor é o
  **comando literal** do projeto; escopo (ex.: restringir ao diff) e threshold (ex.:
  score mínimo) são calibração do consumidor, **dentro do próprio comando** — o motor não
  interpreta score: **exit code é o veredito**, como em `quality.test`.
- **Roda na entrega** — no fecho do ciclo (`/keelson:auto`) e na preparação do PR
  (`/keelson:integrate`) —, após a suíte verde; nunca por TASK ou wave: mutation é
  caro, e a rede fina já é o gate 2. Falhou → a entrega para, mesma regra do teste
  vermelho. Diff inerte dispensa junto com a suíte.
- **A mesma prova não se repete** (decisão 4.122): rodada verde registrada no INDEX do
  slug **com o SHA** em que rodou dispensa a repetição no integrate quando o diff
  daquele SHA ao HEAD é **inerte** (âncora mecânica acima) — dispensa sempre declarada.
  Marca sem SHA, ou qualquer código no diff desde então → roda de novo; "já rodou" por
  lembrança não é prova.
- **Ausência é declarada, nunca silêncio**: campo `null` → o report registra
  `mutação: não configurada (opt-in)` — mesma régua de declaração desta doutrina.
- **Score não é meta**: número de doutrina algum define "cobertura de mutação boa" —
  meta numérica ensina a matar mutante sem provar comportamento (o Goodhart desta
  camada). O report de sobreviventes é **sinal** para o revisor; a régua de qualidade
  de asserção continua sendo a da seção anterior, no gate 1.

A ferramenta canônica de cada linguagem é assunto do perfil (`PROFILE-OUTLINE.md` §7);
o `/keelson:init` detecta as comuns e oferece o campo.

---

## Specs E2E: a verificação de tela vira memória (decisão 4.166)

A verificação de tela exploratória (gate 9 via browser dirigido) prova o comportamento
uma vez — e re-paga o custo inteiro a cada rodada. Com `quality.e2e` declarado na ficha
(opt-in, default `null`), o comportamento aprovado é **codificado em spec E2E
versionado**: o spec é a memória durável do gate, re-executável por qualquer clone sem
browser dirigido; a exploração fica reservada ao comportamento **novo** e ao julgamento
que asserção não captura (layout, tema, estado visual).

- **Opt-in pela ficha**: `quality.e2e` é o **comando literal** da suíte E2E do projeto
  (ex.: `npx playwright test`); como em `quality.test`, **exit code é o veredito**.
- **O spec é código, e o developer o entrega**: AC com efeito observável em tela → o
  spec que o prova faz parte da task; o `qa` executa, nunca escreve (gerador ≠
  avaliador). Commitado como qualquer teste; artefato de execução (screenshot, trace,
  report, estado de auth) fica em pasta gitignored — consolidado numa casa só
  (`thoughts/e2e/` no setup guiado, decisão 4.168), nunca espalhado em diretórios
  soltos. Em suíte autenticada essa saída é **material sensível** (4.169 — instância da
  categoria *Security Logging & Alerting Failures* de `core/SECURITY.md`, dona da regra
  geral): o contexto
  de erro de uma falha carrega snapshot da página — credencial inclusa — mesmo com
  trace e screenshot desligados; o diretório gitignored é a contenção, e a saída nunca
  vira artefato publicado de CI.
- **Tags são o recorte**: cada arquivo de spec carrega a tag do slug (`@<slug>`) e cada
  teste as tags dos ACs que prova (`@AC-NNN-XXX`). Recorte da task:
  `<quality.e2e> --grep "@AC-NNN-XXX"`; regressão do slug: `--grep "@<slug>"`;
  regressão completa: o comando puro. A cobertura AC→spec é fato mecânico —
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/e2e-coverage.sh" <dir-do-slug> <dir-dos-specs>`
  (`WARNING` para tag órfã, `INFO` para AC sem spec: nem todo AC é de tela, a
  calibração é do gate 9).
- **Asserção determinística**: spec E2E asserta DOM, texto, estado e rede — nunca
  comparação com imagem de referência commitada (infla o repositório e flakeia entre
  máquinas/OS). Screenshot continua sendo capturado como evidência, no diretório
  gitignored do gate; imagem não entra no git.
- **Spec vermelho não se reescreve para verde**: editar asserção/seletor de spec
  existente exige citar a **mudança intencional de AC/SPEC** que a justifica — sem
  ela, o vermelho é bug (ou flakiness a corrigir na causa), nunca "teste
  desatualizado". É a régua do repro vermelho do bugfix (4.159) aplicada à camada E2E;
  o gate 2 verifica.
- **Regressão completa roda na entrega** (`/keelson:integrate`), após a suíte de
  testes verde — mesma posição do gate de mutação; ambiente de tela indisponível →
  causa nomeada (`handoff-protocol.md` §8.1), nunca silêncio.

---

## Fixtures e dados compartilhados (Art. 3)

Schema de teste e construtores de dados são **centralizados**, não declarados inline em
cada teste. Copiar um `CREATE TABLE` ou um builder de linha para dentro do teste é a
mesma violação de DRY dos helpers de produção — e diverge: quando o código passa a ler um
campo novo, as cópias inline ficam desatualizadas e quebram em massa (*schema drift*).

- Precisa de uma tabela/entidade nova no teste → adicione ao **helper central**, nunca
  inline.
- Precisa de um campo novo lido pelo código → edite o helper em **um** lugar.

---

## O dublê não é produção

Testar contra um substituto rápido do ambiente (banco em memória, serviço fake) é ótimo
para velocidade, mas o substituto **não é** o ambiente de produção — dialetos, tipos e
construções divergem. Quando a mudança altera o I/O real (a consulta, o comando, o
contrato externo), o teste no dublê **não dispensa** a verificação de comportamento
contra o ambiente real (o gate de comportamento observável, quando aplicável).

O **toolchain do runner também é dublê**: quando o runtime carrega o código por caminho
diferente do runner (outro transpilador/parser, outra versão de interpretador, outro
loader), a suíte verde **não prova que a aplicação sobe**. Mudança em código carregado
pelo runtime real → prove a carga/boot nele (o comando concreto é do perfil de linguagem
ou da ficha), não só no runner.

---

## Prioridade e exceção obrigatória

| 🥇 Alta | 🥈 Média | 🥉 Baixa |
|---------|----------|----------|
| Domínio (entidades, regras, cálculos) | Adaptadores/repositórios | Camada de entrega e UI |

**Exceção que sobe de prioridade — gate de autorização:** teste de integração provando
a **negação sem a permissão**, na pilha real (detalhe: `./SECURITY.md`, *Prova do 403*).

---

## Verificação forte e única

Escolha a verificação que **prova o comportamento** (teste de integração/E2E) e rode a
suíte relevante **uma vez** ao final. Não prove a mesma coisa em várias ferramentas (lint
+ script de fiação + E2E + suíte repetida) — escolha a mais forte e pare. Rigor
**proporcional a complexidade × risco** (ver `./WORKFLOW.md`).

---

## Diff inerte: a suíte prova código

A suíte existe para provar **código em execução**. Quando **nenhum** arquivo do diff pode
alterar o comportamento que ela prova — só documentação, artefatos SDD (`{docsRoot}`),
asset estático sem passo de build — rodá-la não prova nada de novo: a rodada é
**dispensada** (rigor proporcional — `./WORKFLOW.md`).

O teste é mecânico e **ancorado**, nunca impressão: `git diff --name-only <base>...HEAD`
confrontado com os `codePaths` da ficha e as árvores de teste do projeto. O executor
canônico da âncora é `${CLAUDE_PLUGIN_ROOT}/scripts/diff-facts.sh --base <ref> --inert`
(decisão 4.151): exit 0 = inerte, exit 1 = tem código, listando quem forçou a rodada —
cite a saída como fato; script indisponível → aplique a âncora à mão e declare. Conta
como código — e obriga a rodada — todo arquivo que o runtime ou o runner carregam:
fonte, teste, fixture, manifesto/lockfile de dependência, configuração de runtime,
script de build, template executável. **Na dúvida, rode** — a dispensa é exceção que se
prova, não default (é o default do próprio script: arquivo não classificável conta como
código).

A dispensa obedece à régua de declaração desta doutrina (abaixo): o report registra
`não rodei: diff sem código que a suíte exercita` e a lista dos arquivos do diff. Vale
igualmente para o **baseline**: task cujo escopo só toca arquivos inertes dispensa
baseline e rodada final com a mesma declaração — a omissão continua proibida.

---

## Verificação que falha não se contorna

Uma verificação que falha — ou que **não consegue rodar** — tem exatamente **duas
saídas**: corrigir a causa (se está no escopo) ou **parar e reportar o bloqueio** a quem
orquestra. Não existe terceira via. Em particular, **erro pré-existente** (teste vermelho,
suíte que não sobe, ambiente quebrado antes de você tocar em qualquer coisa) não é
licença para pular a verificação: "não fui eu que quebrei" explica a origem do vermelho,
não autoriza entregar sem prova.

**Baseline antes de mudar**: quem vai implementar roda a verificação escopada **uma vez
antes de tocar no código** e registra o resultado. Baseline vermelho → parar e reportar
ali, antes de investir em implementação — é nesse momento que reportar é barato. A
comparação final é sempre **contra o baseline**: nenhum vermelho novo.

**São contorno — a mesma violação de gate do furo silencioso** (decisão 4.38):

- Pular hook de verificação no commit (`--no-verify` e equivalentes).
- Estreitar o filtro do runner para **excluir** o teste que falha.
- Flag de "passa sem testes" / suíte vazia contando como verde.
- Desabilitar, deletar ou marcar como skip o teste vermelho.
- Não rodar a verificação e **silenciar** — entregar como se tivesse rodado.

**Silêncio sobre verificação lê-se como verificação aprovada — e essa é a falha que esta
regra existe para impedir.** Todo report declara o **comando literal** executado e o
resultado; "não rodei: <motivo>" é um estado válido desde que explícito — a omissão nunca
é. Os nomes concretos das flags de cada runner ficam no perfil de linguagem; a proibição
é desta doutrina e vale para todos.
