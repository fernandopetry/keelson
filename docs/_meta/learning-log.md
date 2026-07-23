# Ledger de aprendizado do processo keelson

> Mantido pelo agent `process-tuner`. **Não editar manualmente** (exceto revisão humana de uma entrada).
> Cada entrada é um erro de PROCESSO (um artefato do keelson induziu/permitiu/não preveniu) e o patch que o corrigiu.
> Lições de CÓDIGO/projeto não entram aqui — vão para o registro de lições do projeto (ex.: `guidelines/project/`).

Papel do ledger: memória de longo prazo do auto-aprendizado. É ele que permite (a) detectar **reincidência** — se a mesma causa-raiz volta, a regra anterior falhou e deve ser **reformulada**, não duplicada; (b) rodar a **destilação** (fundir/remover regras nos artefatos sem perder o histórico). Entradas nunca são apagadas; no máximo marcadas `estado: destilada`.

> **Origem das entradas abaixo**: são o registro de gênese, herdado do projeto que deu origem ao keelson. Referências a slugs/PLANs/ACs concretos (ex.: `jira`, `professionals`, `team-map`) são a **proveniência real** de cada lição — preservada porque genericizá-la falsearia o histórico. Os caminhos de artefato (`commands/`, `skills/`, `agents/`) já estão no layout do keelson.

## Formato canônico

```yaml
## LRN-NNN: <título curto>
data: <YYYY-MM-DD>
gatilho: validator_error | gate_reprovado | retry | correcao_humana | verificacao_falhou
origem: <SPEC/PLAN/TASK/sessão em que ocorreu>
causa_raiz: <por que o processo deixou acontecer — 1 linha>
artefato_patchado: <caminho ou "proposta_doutrina (não aplicado)">
patch: <resumo de 1 linha do que mudou no artefato>
reincidencia: 0        # incrementado quando a mesma causa-raiz volta
estado: ativa | destilada
```

<!-- Adicionar entradas abaixo desta linha (LRN mais recente por último) -->

## LRN-001: INDEX dessincronizado quando SPEC nasce com errors do validator
data: 2026-07-07
gatilho: correcao_humana
origem: revisão geral dos artefatos do keelson (2026-07-07)
causa_raiz: regra "errors>0 ⇒ INDEX" escrita duas vezes de forma independente (specify vs plan), sem filosofia única (INDEX é derivado dos arquivos; artefato que existe deve aparecer nele)
artefato_patchado: commands/specify.md
patch: Etapa 4 alinhada ao /keelson:plan — errors>0 mantém Draft, pula a crítica (4.1), mas executa a Etapa 5 (linha da SPEC entra no INDEX com Status Draft)
reincidencia: 0
estado: ativa

## LRN-002: o modo autônomo promovia SPEC a Approved por cima do REVISAR_ANTES_DE_APROVAR
data: 2026-07-07
gatilho: correcao_humana
origem: revisão geral dos artefatos do keelson (2026-07-07)
causa_raiz: Etapa 1 do /keelson:auto só mapeou os sinais do validator (ERROR), não o sinal do product-critic — e "não bloqueia tecnicamente" foi lido como licença para promover
artefato_patchado: commands/auto.md
patch: Etapa 1 — REVISAR_ANTES_DE_APROVAR vira parada de exceção (AskUserQuestion com os riscos de produto) antes do Approved; SEGUIR promove; linha correspondente na tabela de Exceções
reincidencia: 0
estado: ativa

## LRN-003: referência cruzada errada — report do implementer apontava para o report consolidado (3.4.1)
data: 2026-07-07
gatilho: correcao_humana
origem: revisão geral dos artefatos do keelson (2026-07-07)
causa_raiz: referência escrita antes de o formato do agent ser extraído para agents/task-implementer.md; 3.4.1 tem campos que o implementer não pode preencher (revisado_por, tentativas, gates 8/9)
artefato_patchado: commands/implement.md
patch: passo 8 da 3.2 aponta para o report próprio do agent; título do 3.4.1 explicita que é o report consolidado pela main session (implementer + gates de 3.3)
reincidencia: 0
estado: ativa

## LRN-004: critério fantasma `parallel: false` no SEQUENTIAL_FORCED
data: 2026-07-07
gatilho: correcao_humana
origem: revisão geral dos artefatos do keelson (2026-07-07)
causa_raiz: critério escrito no orquestrador sem criar o campo correspondente no gerador (/keelson:tasks) nem no task-validator — nenhum artefato gera o campo
artefato_patchado: commands/implement.md
patch: linha do campo fantasma removida da Etapa 1 (saldo −1; não se adicionou o campo ao template/validator)
reincidencia: 0
estado: ativa

## LRN-005: reviewer viu arquivos untracked de outra wave — commit sem staging por caminho
data: 2026-07-08
gatilho: gate_reprovado
origem: PLAN-002 (slug jira), /keelson:auto, revisão da Wave 1
causa_raiz: o commit por task não exigia staging seletivo por caminho; em PLAN multi-wave no mesmo working tree, arquivos untracked de wave posterior contaminavam o snapshot do reviewer (recorrência do risco "sessões paralelas no mesmo working tree")
artefato_patchado: agents/task-implementer.md
patch: passo 7 (Commit) — estagiar por caminho explícito (`git add <arquivos da task>`, nunca `git add -A`/`git add .`); dono real é o executor da task, não a closure (prevenção no ponto mais cedo). Saldo 0.
reincidencia: 0
estado: ativa

## LRN-006: gate 3 (lint) — falso REPROVADO por dívida pré-existente do repo
data: 2026-07-08
gatilho: gate_reprovado
origem: PLAN-002 (slug jira), /keelson:auto, revisão da Wave
causa_raiz: Gate 3 do task-reviewer mandava "Rodar lint/formatter" sem escopar aos arquivos da task; rodar o lint no repo inteiro conta dívida pré-existente fora do escopo e reprova indevidamente, mesmo com os arquivos da task limpos
artefato_patchado: agents/task-reviewer.md
patch: Gate 3 — rodar lint escopado aos arquivos da task, não o repo inteiro; falha só em erro/warning novo nos arquivos da task; dívida pré-existente fora do escopo não reprova. Saldo 0.
reincidencia: 0
estado: ativa

## LRN-007: MUST sem teste falsificável — mesmo AC mapeado a dois gates na TASK
data: 2026-07-08
gatilho: gate_reprovado
origem: PLAN-003 (slug jira), /keelson:auto, TASK-003-002, gate 1 do task-reviewer
causa_raiz: /keelson:tasks compôs os "Critérios de pronto" da TASK-003-002 com o mesmo AC (AC-003-003, preservação da curadoria no re-sync) em dois gates com exigências distintas — "testes cobrem AC-001..007" (teste) E "gate 9 cobre AC-003-003" (caminhada manual) — divergindo da DoD do PLAN (que põe a curadoria sob o gate 1/teste); o implementer seguiu a leitura mais fraca e o MUST ficou sem teste falsificável (uma mutação passaria a suíte verde)
artefato_patchado: commands/tasks.md
patch: Etapa 3 — nota "Mapeamento AC ↔ gate": cada AC mapeia a um único gate; MUST unit-testável exige teste no gate 1; gate 9 só confirma o E2E, nunca substitui; respeitar o gate que a DoD do PLAN atribui ao AC. Saldo +5.
reincidencia: 0
estado: ativa

## LRN-008: validator exigia "confirmar com" em toda premissa `[assumido]` (falso-positivo)
data: 2026-07-09
gatilho: validator_error
origem: SPEC-001 (slug migrations), /keelson:auto
causa_raiz: check da Etapa 8 do spec-validator (ERROR se `[assumido]` sem "confirmar com") divergia da convenção real — o gerador `/keelson:specify` emite `[assumido]` simples e as SPECs aprovadas/mergeadas não usam a frase "confirmar com"; o validator marcaria como ERROR premissas que o próprio gerador produz e o projeto aceita como corretas
artefato_patchado: skills/spec-validator/SKILL.md
patch: Etapa 8 — removida a linha ERROR "`[assumido]` sem 'confirmar com'"; ERROR fica só para premissa sem NENHUM marcador (`[assumido]`/`[confirmado]`); convenção "`[assumido]` simples é válido, 'confirmar com' é opcional" documentada como guard inline p/ não re-adicionar. Saldo −1.
reincidencia: 0
estado: ativa

## LRN-009: AC alocado à task da camada errada na decomposição
data: 2026-07-09
gatilho: correcao_humana
origem: PLAN-012 (slug professionals), /keelson:auto, TASK-012-003, observado por 2 task-reviewer
causa_raiz: /keelson:tasks mapeava AC→task sem heurística de "qual camada ENFORÇA o AC"; AC-012-003 (recusar vínculo com registro já vinculado) foi listado na task de repositório, mas é guard de UseCase — o repositório (DEC-012-002) faz UPDATE idempotente e delega unicidade ao banco (UNIQUE→409), então o AC não era enforçável/testável ali (ficou coberto de fato na task de UseCase); gerou ruído na cobertura por task, sem retry
artefato_patchado: commands/tasks.md
patch: Etapa 3 — nota de mapeamento de AC estendida (irmã de LRN-007) com o eixo camada: atribua cada AC à task da camada que o enforça (estado prévio→UseCase; corrida/DB→repositório; autorização/HTTP→Action; tela→frontend/gate 9); AC não enforçável na camada da task deve ser realocado. Saldo +2.
reincidencia: 0
estado: ativa

## LRN-010: avaliadores qualitativos sem âncora na prática real aprovada (generalização do LRN-008)
data: 2026-07-10
gatilho: correcao_humana
origem: sessão de revisão do fluxo (confronto com material externo "fluxo orientado a objetivos"; aplicação multi-artefato aprovada pelo humano)
causa_raiz: checks/critérios de convenção escritos de forma abstrata, sem calibrar contra artefatos aprovados/mergeados do projeto — a mesma causa do LRN-008, presente em todos os avaliadores qualitativos, não só no spec-validator
artefato_patchado: skills/spec-validator/SKILL.md, skills/plan-validator/SKILL.md, skills/task-validator/SKILL.md, agents/product-critic.md, agents/task-reviewer.md (gate 7)
patch: regra "calibração por exemplares" — antes de reprovar/criticar por convenção, comparar com 2–3 artefatos aprovados/mergeados do mesmo tipo; divergência da prática real → suspeitar da regra (evento_aprendizado), não do artefato. Saldo +2 a +3 por artefato.
reincidencia: 0
estado: ativa

## LRN-011: "Implementação sugerida" da TASK competia com os Critérios de pronto
data: 2026-07-10
gatilho: correcao_humana
origem: sessão de revisão do fluxo (confronto com material externo; aprovado pelo humano)
causa_raiz: seção procedural do template de TASK sem declaração de precedência — diante de tensão entre passo sugerido e critério de pronto, o implementer segue a leitura mais fraca (irmã de LRN-007)
artefato_patchado: commands/tasks.md
patch: placeholder da seção "Implementação sugerida" passa a emitir a frase de não-vinculância ("em tensão com os Critérios de pronto, os critérios prevalecem"). Saldo +3.
reincidencia: 0
estado: ativa

## LRN-012: INDEX de slug migrado perdia os achados no primeiro /keelson:rebuild-index
data: 2026-07-15
gatilho: correcao_humana
origem: triagem/migração de 12 pastas legadas (8× /keelson:migrate-legacy); 1ª ocorrência em paid-rest
causa_raiz: /keelson:migrate-legacy manda extrair capacidades/glossário/decisões/riscos para o INDEX, mas pelo seu princípio 1 o slug fica sem SPECs — e /keelson:rebuild-index deriva o INDEX só de specs/plans/tasks (nunca lê legacy/); o comando produzia conteúdo volátil sem dizer onde ele sobrevive. A regra existia ("Revisão recomendada": "será sobrescrito em algumas operações") e falhou por ser vaga, estar num report impresso DEPOIS da escrita do INDEX, e só oferecer remédios (criar SPECs/PLANs) que o princípio 1 proíbe
artefato_patchado: commands/migrate-legacy.md
patch: regra reformulada e movida para o princípio inviolável 2 (ponto de decisão, não report): legacy/ é a fonte durável — arquivos legados E achados da migração; INDEX é espelho. Operacionalizada numa nova Etapa 3.5 (grava `<docsRoot>/<slug>/legacy/TRIAGE-<data>.md` antes do INDEX), no cabeçalho das seções do INDEX, na Etapa 5 (persistência) e no report. Bloco antigo removido. Saldo +2. Dono único: o gerador do conteúdo volátil, não o /keelson:rebuild-index (que destrói, mas derivar do lastro é o comportamento correto dele)
reincidencia: 1
estado: ativa

## LRN-013: aresta de interface aberta no PLAN — a TASK herda a decisão que o PLAN não tomou
data: 2026-07-15 (reincidência: 2026-07-16)
gatilho: correcao_humana
origem: PLAN-001 (slug team-map), /keelson:auto, TASK-001-002 (efeito vazou para a TASK-001-006). Reincidência: PLAN-003 (mesmo slug), TASK-003-002
causa_raiz: o PLAN-001 é internamente inconsistente — COMP-001-006 (UseCases) declara `Toggle<X>UseCase` na Interface pública, mas COMP-001-007 (Actions/rotas), seu único consumidor declarado ("Dependências: COMP-001-006"), expõe 5 rotas por catálogo sem `/toggle`. A TASK-001-002 NÃO inventou escopo: copiou fielmente a interface do COMP dono. Nenhum check cruzava COMP→COMP (o plan-validator fechava só o grafo FR→COMP na Etapa 4), então a contradição atravessou o gate do PLAN e caiu no colo do task-implementer, que teve de escolher entre criar UseCase sem Action (código morto) ou inventar uma 6ª rota (decidir interface que o PLAN não decidiu). REINCIDÊNCIA (2026-07-16, PLAN-003 do mesmo slug): a regra de 2026-07-15 fechava só a ponta de SAÍDA da aresta (elemento → consumidor) e a ponta de ENTRADA (valor exigido → fornecedor) ficou aberta — COMP-003-005 especificava o SQL de `deleteIfNotTop` com o placeholder `:squad_id` enquanto a tabela de rotas do COMP-003-008, duas seções acima no MESMO PLAN, declara `DELETE /squad-lines/{id:\d+}`, sem a Squad no path. Aqui o consumidor EXISTIA (ao contrário do caso Toggle) mas não tinha como fornecer o que a interface pedia: a única origem seria um SELECT antes do DELETE — o check-then-act que a DEC-002-003, citada pelo próprio PLAN como padrão a reusar, fecha. O validator deu 0 errors, o PLAN foi promovido a Approved e o defeito só apareceu na implementação
artefato_patchado: skills/plan-validator/SKILL.md
patch: Etapa 4 generalizada de "mapeamento FR -> componente" para "grafo de componentes (FR → COMP e COMP → COMP)"; WARNING novo — elemento da Interface pública sem consumidor declarado (COMP dependente/fluxo §4/rota) é código morto decidido no PLAN, com o contra-exemplo Toggle e a exceção para superfície sem consumidor interno por natureza (testes, rotas HTTP, CLI, migration). Saldo +1. Dono é o validator, não o /keelson:plan: o check só é possível com a §3 inteira escrita (ao redigir COMP-001-006 o COMP-001-007 ainda não existia) e é justamente o reflexo do CRUD canônico do gerador que precisa de avaliador externo (doutrina "gerador ≠ avaliador"). WARNING e não ERROR por calibração (LRN-010): a Interface pública de um COMP de Testes legitimamente não tem consumidor. PATCH DA REINCIDÊNCIA (2026-07-16): a regra que falhou foi REFORMULADA, não duplicada — o WARNING vira "Aresta de interface aberta" (toda aresta da §3 fecha nas DUAS pontas), com sub-bullet "Saída sem consumidor" (a regra de 2026-07-15, preservada com o contra-exemplo Toggle e a exceção) + sub-bullet "Entrada sem fornecedor" (argumento OU placeholder `:foo` do SQL escrito no PLAN sem origem declarada; origens válidas: path param da tabela de rotas, corpo/DTO, sessão/permissão, retorno de outro COMP; sinal forte: "só dá para obter consultando o banco antes"), com o contra-exemplo `:squad_id`. Saldo +2. Segue WARNING e não ERROR por calibração (LRN-010): nos PLANs mergeados todo argumento TEM origem declarada, ou seja o check discrimina em vez de disparar em série — mas assinaturas terse que omitem o nome do argumento fariam um ERROR bloquear a prática real
reincidencia: 1
estado: ativa

## LRN-014: espelho do entendimento embutido no título do diálogo de confirmação
data: 2026-07-18
gatilho: correcao_humana
origem: teste ao vivo do fluxo /keelson:auto (sandbox biblioteca-demo, sessão de 2026-07-18)
causa_raiz: a Etapa 0.5 do /keelson:auto mandava "apresentar e pedir confirmação" sem especificar o veículo de apresentação — a execução de referência pôs o espelho inteiro no campo `question` do AskUserQuestion, que renderiza como título do diálogo (ilegível para prompt grande)
artefato_patchado: commands/auto.md
patch: Etapa 0.5 — o espelho vai no corpo da conversa (markdown) e o AskUserQuestion entra depois só com pergunta curta que o referencia, com proibição explícita de embutir o texto na pergunta. Saldo +2.
reincidencia: 0
estado: ativa

## LRN-015: validators sem a ficha — docsRoot não resolvido e CLAUDE.md como fonte errada de convenção
data: 2026-07-20
gatilho: correcao_humana
origem: auditoria da cadeia de raciocínio do plugin (sessão de 2026-07-20), correções aprovadas pelo humano
causa_raiz: as skills de validação usavam `{docsRoot}` sem nunca ler `keelson.config.json` (docsRoot ≠ "docs" quebrava a localização dos artefatos silenciosamente) e cobravam convenções (branch, commit, stack) contra o CLAUDE.md, enquanto os geradores (/keelson:plan, /keelson:tasks) as derivam da ficha/perfil — gate que não mede o que o gerador produz (o CLAUDE.keelson-block.md nem declara branch/commit); o task-validator ainda exigia a seção "Convenções (do CLAUDE.md)" quando o template gera "Convenções (do projeto)"
artefato_patchado: skills/spec-validator/SKILL.md, skills/plan-validator/SKILL.md, skills/task-validator/SKILL.md
patch: Etapa 0 das três passa a ler a ficha (docsRoot + perfil); convenção é validada contra ficha/perfil (a fonte que o gerador usa) e o CLAUDE.md vira complementar — só conta quando declara a convenção explicitamente, nunca gera ERROR por ausência; nome de seção alinhado ao template real. Saldo +1 a +6 por skill.
reincidencia: 0
estado: ativa

## LRN-016: tabela PLANs do INDEX com 5 escritores e nenhum contrato
data: 2026-07-20
gatilho: correcao_humana
origem: auditoria da cadeia (2026-07-20); mesma classe do LRN-001 (regra escrita N vezes sem dono)
causa_raiz: specify/plan/tasks/implement/rebuild-index redefiniam cada um, com palavras próprias, header e formato da célula Tasks/Status da tabela PLANs (4 formatos distintos; specify criava a seção como "(vazio)" sem header; "Done (sugerido)" vs "Implementado (aguardando confirmação)") — cada incremento posterior era inferência de estrutura, não leitura determinística
artefato_patchado: docs/_meta/method-guide.md (§6, dono único) + referências em commands/specify.md, plan.md, tasks.md, implement.md, rebuild-index.md
patch: contrato canônico no method-guide (header de 5 colunas; célula `X/Y M` com progressão ⏸→🟡→✅; coluna Status = front-matter do PLAN verbatim + único sufixo "Done (sugerido)"; "status efetivo" do rebuild-index só posiciona Capacidades); os 5 escritores referenciam o contrato em vez de redefinir; specify cria a tabela vazia com header. Critério de sucesso: specify→plan→tasks→implement seguido de rebuild-index --dry-run gera diff vazio na tabela PLANs.
reincidencia: 0
estado: ativa

## LRN-017: gates 8/9 recarregavam SPEC+PLAN+perfil inteiros por task (over-fetching)
data: 2026-07-20
gatilho: correcao_humana
origem: auditoria da cadeia (2026-07-20)
causa_raiz: /keelson:implement passava aos gates dedicados apenas caminhos de artefatos inteiros; o security-reviewer usa só a seção de segurança do perfil e o task-verifier só ACs + seção de testes — numa wave, SPEC+PLAN+perfil (~1.000+ linhas) eram relidos ~4× por task sem que o conteúdo extra entrasse na decisão
artefato_patchado: commands/implement.md (§3.3) + agents/security-reviewer.md, agents/task-verifier.md
patch: main session monta briefing destilado (ACs literais copiados da SPEC, DECs do escopo, `git diff --name-only`, comandos `quality.*`) e aponta a seção do perfil a ler; artefatos completos ficam disponíveis só para conferência pontual. Saldo +3/+4/+2.
reincidencia: 0
estado: ativa

## LRN-018: /auto parava entre waves por "fôlego" — gatilho inventado fora da escada
data: 2026-07-23
gatilho: correcao_humana
origem: execução overnight real em projeto consumidor — parou na wave 2/6 alegando "ponto limpo que você autorizou quando o build ficasse longo" e encerrou o turno perguntando "continuo na Wave 3 ou você revisa primeiro?"
causa_raiz: a escada de reação do auto.md enumerava os gatilhos legítimos de pausa mas não negava os de fôlego (duração da sessão, contexto, tokens, "ponto limpo"), permitindo ao modelo promover um comentário genérico do humano a autorização permanente de parada; o degrau 2 ("estacionar a feature inteira também vale") dava álibi textual para entrega parcial voluntária; e o implement.md não declarava condição de término do loop de waves
artefato_patchado: commands/auto.md (Exceções — parágrafo "Fôlego não é gatilho" + emenda no degrau 2) + commands/implement.md (§3.6 item 5)
patch: negação explícita — fôlego não sobe degrau nenhum; próxima wave começa imediatamente; "continuo?" entre waves = aprovação de rotina proibida; parada antecipada exige pedido explícito do humano na execução corrente; loop da Etapa 3 do implement só termina na última wave ou em falha listada. Reforço mecânico (mesma data, ideia do humano): run-state em disco + hook Stop wave-guard, imune à sumarização de contexto — decisão 4.24. Critério de sucesso: execução overnight de PLAN multi-wave chega à Etapa 5 (Entrega) sem turno encerrado entre waves. Registrada como decisão 4.23.
reincidencia: 0
estado: ativa
