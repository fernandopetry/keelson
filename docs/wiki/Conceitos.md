# Conceitos

O que o keelson é, e por que cada peça existe.

## O problema

Padrão de qualidade costuma viver em dois lugares ruins: na cabeça das pessoas mais
antigas do time, ou numa página de wiki que ninguém lê. Nos dois casos ele não é aplicado
de forma consistente — e quando um agente de IA escreve o código, ele não é aplicado de
jeito nenhum.

O keelson transforma **o seu** padrão em algo que um agente aplica a cada mudança e que
um humano consegue verificar, sem amarrar isso a uma linguagem ou a um projeto.

## Motor e adaptador

| | O motor | O adaptador |
|---|---|---|
| **O que é** | Ciclo SDD, quality gates, validators, [Quality Charter](Quality-Charter) | [`keelson.config.json`](Ficha-do-projeto) — ~15 linhas |
| **Onde vive** | No plugin | No seu repositório |
| **Quem edita** | Ninguém (você atualiza a versão) | Você |
| **Muda por projeto?** | Não | Sim |

## Spec-driven development (SDD)

A especificação é a fonte da verdade; o código é consequência dela. Toda mudança
não-trivial atravessa quatro etapas, cada uma com seu artefato durável:

```
/keelson:specify  →  /keelson:plan  →  /keelson:tasks  →  /keelson:implement
      SPEC              PLAN              TASKs              código
```

| Artefato | Responde | Regra inegociável |
|---|---|---|
| **SPEC** | O **quê** — requisitos em EARS, critérios de aceite em Given-When-Then, glossário | **Não fala de tecnologia.** Linguagem, framework, banco e protocolo só entram no PLAN |
| **PLAN** | O **como** — componentes (COMP), decisões arquiteturais (DEC) com alternativas, mapa FR→componente | Herda stack e padrões da ficha e do perfil ativo; não reescolhe |
| **TASK** | O **pedaço** — tarefas atômicas (30min–4h) ordenadas em *waves* por dependência | Tarefas da mesma wave rodam em paralelo |
| **INDEX** | O **estado** do slug | **É gerado** — nunca edite à mão |

Tudo isso vive em `<docsRoot>/<slug>/` (`docs/` por padrão). Um **slug** é uma área de
demanda — o agrupador de SPECs, PLANs e TASKs de um mesmo assunto.

**E a tarefa do dia a dia?** Bugfix ou melhoria pequena sem SPEC/PLAN não fica sem
registro: nasce como **brief avulso** (`briefs/BRIEF-MMM-*-avulso.md`) — a tarefa
escrita *antes* do código, com pedido, interpretação e critério de aceite. Se o
trabalho reparte, TASKs ancoram nele; com Jira ligado, ele vira Story no quadro na
largada (e um card que você já abriu entra como origem, sem duplicar). Mudança que
cruza várias áreas continua com **um brief só**: ele mora no slug dominante — o de onde
sairia a SPEC se o trabalho crescesse — e os demais ganham uma linha de referência no
INDEX. Regra de corte:
mudou o que o sistema **promete**, ou há decisão técnica entre alternativas → é ciclo,
não avulso.

**A SPEC também declara o que sustenta e como se prova** (decisões 4.96–4.101). Cada
premissa carrega um **selo de evidência** (`crença · anedota · entrevistas · medido`) —
o selo nunca bloqueia; ele expõe a aposta para a crítica de mérito (aposta de **valor**
no núcleo da demanda → o PO devolve pergunta formal à área de produto, com o menor
teste que a falsifica anexo — o ciclo não faz discovery). Cada DEC do PLAN
declara **`Reabrir se:`** — a condição observável que pede revisão da decisão (a que
aparece em diff é vigiada pelo reviewer; a de mundo viaja ao INDEX). E a **métrica de
sucesso** declara a **fonte de medição**; entregue o PLAN, a pendência de **veredito**
fica em "Riscos ativos" do INDEX até alguém medir — o ciclo seguinte mede sozinho
quando os meios existem, ou devolve a pergunta pronta à área de produto no report.
Feature que não moveu métrica é nomeada **candidata a sunset**; descontinuar é decisão
do Diretor.

Detalhe dos artefatos e IDs: [Contrato do INDEX](Contrato-do-INDEX).

## O time

O keelson simula um time real, e os IDs dos agents **são** os nomes dos papéis.

| Papel | Quem é | O que faz |
|---|---|---|
| **Diretor** | **Você** | Emite a intenção (o brief), mantém o veto, decide PR/merge/deploy |
| **Tech Lead** | A sessão principal | Orquestra: despacha os agents, consolida, decide o caminho técnico |
| `po` | Product Owner | Dono da demanda; valida SPEC e entrega **contra o brief**, nunca contra a própria opinião |
| `pm` | Product Manager | Decompõe um pedido épico em demandas independentes |
| `developer` | Developer | Implementa uma TASK |
| `code-reviewer` | Code Reviewer | Quality gates 1–7 |
| `security-engineer` | Security Engineer | Gate 8, quando a mudança é sensível |
| `performance-engineer` | Performance Engineer | Gate 10, quando o diff toca superfície de custo |
| `qa` | QA | Gate 9 — prova, executando, que funciona |
| `product-analyst` | Product Analyst | Crítica de mérito da SPEC |
| `agile-coach` | Agile Coach | Aprendizado do processo |
| `staff-engineer` | Staff Engineer | Gera perfis de linguagem novos |

Os validators, o `code-scout`, o `scribe` (redige SPEC/PLAN/TASKs pelo contrato do
comando, para os insumos não ocuparem a janela da sessão principal) e o `tracker-sync`
(executa os ganchos do Jira e devolve só o resumo) ficam **fora da metáfora**: são
ferramentas do time, não pessoas.

### O contrato Diretor–PO

É o que permite o time trabalhar sem te consultar a cada passo:

- Você emite um **brief** — o pedido como dito, mais a interpretação do PO. É o
  artefato-âncora da demanda.
- O PO devolve a interpretação e **segue sem esperar**. Silêncio é aprovação (janela de
  veto); correção sua reemite o brief.
- Ele escala **por exceção**, sempre com proposta e default: ambiguidade que muda o
  resultado, expansão ou conflito de escopo, ação irreversível ou externa, conflito com
  diretriz anterior.
- Decisões tomadas em seu nome ficam registradas.
- A entrega fecha com **relatório de aceitação** (bate com o brief?) — que é diferente do
  QA (funciona?).

**A autonomia termina nos commits.** PR, merge e deploy são seus.

## Quality gates

Gate é a definição de pronto, calibrada por **complexidade × risco** — não uma lista fixa
aplicada com o mesmo peso a tudo.

| Gates | Quem roda | O que exige |
|---|---|---|
| **1–7** | `code-reviewer` | Implementação completa · testes cobrindo os ACs, passando · lint limpo · escopo respeitado · DECs respeitadas · aderência ao Charter e ao perfil ativo · code review |
| **8** | `security-engineer` | Só em mudança sensível (auth, autorização, injeção, upload, dados pessoais, cripto, sessão, endpoints, redirect, exec, dependências) |
| **9** | `qa` | Comportamento **provado executando**, não deduzido do relatório do developer — inclui higiene da superfície (ID de artefato SDD visível sem AC que o exija é achado) e consistência estrutural entre campos irmãos do mesmo grupo (achado-sugestão, nunca reprova sozinho) |
| **10** | `performance-engineer` | Só quando o diff toca superfície de custo (consultas/ORM, laços sobre volume variável, cache, rede, jobs, render pesado, migração de dados). Padrão de custo patológico — como consulta dentro de laço — **bloqueia**; otimização além disso só com medição, nunca por palpite. Não é teste de stress: é revisão de padrões |

Cada gate roda no recorte do que ele prova: os testes acompanham **cada tarefa**; a
revisão, a segurança e a performance rodam **uma vez por wave**, sobre o conjunto integrado (é onde a
interação entre tarefas aparece); e o QA prova a **história completa** quando ela passa
a existir de ponta a ponta — como um QA de time real, que testa a funcionalidade, não o
commit. Nada disso é gate pulado: cada consolidação fica declarada na tarefa, e a
verificação da funcionalidade fica registrada na própria SPEC, cobrada mecanicamente.

E no fecho, antes do push, a **convergência**: uma releitura da SPEC inteira contra o
código como ele ficou. Ela responde as duas perguntas que os gates por parte não fazem —
*tudo que foi pedido existe?* e *tudo que existe foi pedido?* (código extra que ninguém
solicitou também é achado). Cada lacuna sai classificada e citando o requisito de origem;
a entrega só segue com a lacuna corrigida ou virada em pergunta explícita para você.

Falhou? Um retry, depois escala para você. E a régua que atravessa tudo:

> **Gerador ≠ avaliador.** A prova de que um artigo do Charter foi cumprido é externa e
> falsificável — um teste, uma ferramenta que reprova, um humano com contexto limpo. Um
> checklist preenchido por quem escreveu o código **não é prova**.

Quando um gate não pode rodar (sem tela, sem credencial, app fora do ar), ele **não
finge**: a indisponibilidade é provada, nomeada por causa e vira pendência — e, no caso
do gate de tela, um [handoff de verificação](Handoff-de-verificacao).

## Charter e perfis de linguagem

- O **[Quality Charter](Quality-Charter)** tem nove artigos agnósticos de linguagem. Cada
  um carrega uma **régua falsificável**: como se prova que foi cumprido.
- Um **perfil de linguagem** é o Charter *instanciado* para uma linguagem e versão
  (`backend/php.md`, `frontend/*`). O plugin embarca PHP (8.5 como exemplar, mais a
  escada legada 5.6 · 7.0 · 7.4 · 8.0); outras stacks são **geradas na instalação** e
  revisadas por você.
- O **Profile Outline** é o sumário obrigatório que todo perfil preenche — é o que garante
  que um perfil de Node cubra o mesmo terreno que o de PHP.

**Um dono por regra:** o núcleo agnóstico diz *o quê*; o perfil diz *como* naquela
linguagem. A mesma regra nunca é escrita nos dois.

## Validators

Skills que não geram artefato — validam forma:

| Validator | Roda ao final de | Checa |
|---|---|---|
| `spec-validator` | `/keelson:specify` | EARS, RFC 2119, IDs, verificabilidade FR↔AC, domínio vs tecnologia, escopo |
| `plan-validator` | `/keelson:plan` | Cobertura declarada, DECs com alternativas, mapa FR→COMP, DoD |
| `task-validator` | `/keelson:tasks` | Vínculo ao PLAN, FRs/ACs existentes, dependências sem ciclo, campos de closure |

`ERROR` bloqueia a promoção de status; `WARNING` não bloqueia. E **promover status nunca é
do validator**: quem leva `Draft → Approved → Done` é o PO (no ciclo com brief) ou você.

### O grafo dos artefatos

Os artefatos de um slug formam um grafo: TASK depende de TASK, PLAN cobre FR, critério
cobre AC. Desde a versão 0.57.0 esse grafo é **verificado mecanicamente**: um script
determinístico (`graph.sh`) extrai as relações e computa ciclos, referências quebradas,
cobertura e waves — e os validators **citam o resultado como fato** (você verá linhas
`**[graph.sh]** ERROR ciclo-task — …` nos relatórios) em vez de re-deduzir a estrutura
a cada rodada. Três coisas úteis de saber:

- **Seus artefatos antigos não reprovam por forma.** Campo de dependência vazio vale
  como `nenhuma`; prosa antiga vira aviso (`nao-parseavel`), nunca erro; e achado de
  wave/cobertura sobre artefato já `Done` é rebaixado a aviso `[legacy]`.
- **Dá para ver o desenho.** Pergunte ao `/keelson:status` sobre dependências ou ordem
  das tasks e ele devolve o diagrama (Mermaid) — tasks por wave, com status, ou o mapa
  FR→componente.
- A régua completa (sintaxe dos campos, catálogo de checks) está no
  [Contrato do grafo](Contrato-do-grafo).

## Comentários no código gerado

O default é **nenhum comentário**. Todo comentário que os agents escrevem passa por um
único teste (Charter, Art. 7): *apagar essa linha perde informação que o código não
devolve?*

- **Perde → deve existir:** o *porquê* de uma decisão, ancorado ao artefato que guarda o
  raciocínio (`// DEC-03: …`, `// FR-07: …`); uma armadilha ou contorno, com a condição de
  remoção; um invariante que tipos e nomes não expressam; um caminho já tentado que falhou.
- **Não perde → não deve existir:** paráfrase, assinatura repetida em prosa, cabeçalho
  ritual de arquivo, docblock que repete o que o tipo nativo já diz.

As âncoras de uma linha são deliberadas: elas formam o **grafo de navegação** que leva do
código à decisão que o moldou.

## O MAP do slug — memória de território entre demandas

Num domínio com várias demandas (um épico fatiado, manutenção recorrente), o
conhecimento sobre **o código** — onde as coisas vivem, que padrões valem, as pegadinhas
— era redescoberto a cada sessão. O `MAP.md`, na raiz do slug, guarda esse conhecimento
em **entradas datadas e ancoradas** (`- [data · origem] fato — arquivo:linha`):

- **Nasce** na decomposição de um épico (ou quando uma entrega julgar útil); cada ciclo
  seguinte no slug **anexa o delta** na closure — só o que muda a interpretação de quem
  chega depois.
- **É acelerador, não fonte de verdade**: o time confere a âncora antes de decidir por
  ela; entrada antiga não é inválida — é "confira antes de usar".
- **A idade é vigiada por script** (`map-check.sh`): âncora quebrada e arquivo que mudou
  depois da verificação viram avisos (`possivelmente-stale`) — nunca bloqueiam nada.

Você não gerencia o MAP: o time o semeia, atualiza e consome sozinho. Se quiser lê-lo,
é markdown simples — e vale como documentação residual do domínio.

## Onde cada coisa mora

| Peça | Lugar |
|---|---|
| Artefatos da demanda | `<docsRoot>/<slug>/` — `briefs/`, `specs/`, `plans/`, `tasks/`, `INDEX.md`, `MAP.md` (opcional) |
| Configuração do projeto | `keelson.config.json` (versionado) |
| Credenciais de ambiente local | `keelson.local.json` (**fora** do git) |
| Rascunho de sessão, evidência efêmera | `thoughts/` (fora do git) |
| Lições do projeto | `guidelines/project/` |

Próximo: [A ficha do projeto](Ficha-do-projeto) ou o
[Guia do método](Guia-do-metodo).
