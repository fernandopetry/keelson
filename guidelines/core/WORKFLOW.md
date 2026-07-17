# Workflow (core)

> Princípios de **engenharia e orquestração** — agnósticos de linguagem. Complementa o
> `../_meta/QUALITY-CHARTER.md`: o Charter diz *o que é qualidade*; este documento diz
> *como trabalhar* para chegar lá. O **fluxo de artefatos** (spec → plan → tasks →
> código) é o **spec-driven development (SDD)** do keelson.
>
> Referências à stack (paths, comandos) vêm de `keelson.config.json`: caminhos de código
> em `codePaths`, caminhos sensíveis em `sensitiveGlobs`, comandos em `quality.*`, gates
> em `gates.*`, raiz de docs em `docsRoot`. **Nunca** assuma paths ou comandos fixos.

---

## Princípios fundamentais

- **Simplicidade primeiro:** faça cada mudança o mais simples possível; impacte o mínimo
  de código.
- **Sem preguiça:** encontre a causa raiz. Sem correção temporária, sem gambiarra —
  padrão de desenvolvedor sênior.
- **Impacto mínimo:** a mudança toca só o necessário (Charter Art. 6). Evite introduzir
  regressão.
- **Esforço proporcional:** calibre a profundidade de exploração, planejamento e
  verificação por **complexidade × risco**, não só por risco. Cortar redundância (provar
  a mesma coisa 2×, re-explorar o mesmo domínio, planejar em dobro) é cortar
  **desperdício**, não qualidade.
- **Reúso antes de criar:** antes de escrever helper, validação, conversão, componente ou
  abstração, procure o equivalente existente e reúse (Charter Art. 3). Reimplementar o que
  já existe — ou duplicar entre variações próximas (ex.: criar/atualizar) — é proibido.

---

## Comportamento do assistente (uso de ferramentas)

Ferramentas são para **descobrir o desconhecido**, não para confirmar o óbvio.

| Situação | Ação |
|----------|------|
| Pergunta conceitual | Responder direto |
| Informação já documentada (instruções do projeto, guidelines, mensagens anteriores) | Responder direto |
| Implementar feature | Ler guidelines primeiro; explorar código só se necessário |
| Corrigir bug | Ler o código relacionado |

**Hierarquia de consulta:** 1) instruções críticas do projeto → 2) Charter + perfil de
linguagem + doutrina de `core/` → 3) código existente (só quando os guidelines não cobrem
o caso específico).

---

## Orquestração

### 1. Planejamento à altura

- O modo de execução padrão é **autônomo**: planeje internamente, mas **não pause para
  aprovação** a menos que haja ambiguidade real ou risco de difícil reversão.
- Pause para o humano aprovar **só** quando há **decisão dele a tomar** ou trade-off
  arquitetural real — não por rotina.
- **Não duplique planejamento:** agente de plano **ou** modo de plano **ou** plano escrito
  — não os três para a mesma coisa. Caminho óbvio depois de explorar → implemente direto.
- Se algo der errado, **pare e replaneje** — não force o caminho.
- Escreva especificação detalhada antecipadamente **quando reduzir ambiguidade real**
  (contrato, modo de falha, segurança).

### 2. Subagentes e memo de exploração

- Use subagentes para manter o contexto principal limpo; **uma tarefa por subagente**.
- **Exploração em uma onda, concisa:** peça **caminhos + mecanismo**, não relatório
  extenso. Não re-explore o mesmo domínio em rodadas separadas.
- **Memo de exploração:** salve o resultado num arquivo local (gitignored) e reúse-o nas
  etapas seguintes em vez de re-explorar. Faltou um detalhe → **complemente** o memo.
  **Remova-o na closure** da tarefa.
- O memo é um **snapshot**: antes de **editar** um arquivo, releia o arquivo real
  (símbolos/linhas podem ter mudado).
- Para problemas **genuinamente complexos**, aí sim invista mais poder computacional
  (mais exploradores, verificação adversarial).

### 3. Verificação antes de concluir

- Nunca marque uma tarefa como concluída sem **provar** que funciona.
- **Forte e única, não redundante:** escolha a verificação que **prova o comportamento**
  (integração/E2E) e rode a suíte relevante (`quality.test`) **uma vez** ao final. Não
  prove a mesma coisa em várias ferramentas — escolha a mais forte e pare.
- Compare o comportamento entre a versão base e a sua mudança quando relevante.
- Pergunte-se: *"um engenheiro sênior aprovaria isto?"*

### 4. Exija elegância (equilibrada)

- Mudança não trivial: pause e pergunte *"existe uma forma mais elegante?"*.
- Se uma correção parecer gambiarra: *"sabendo tudo que sei agora, implemente a solução
  elegante"*.
- **Pule** isso em correções simples e óbvias — não superengenharia.
- Desafie o próprio trabalho antes de apresentá-lo.

### 5. Correção autônoma de bug

- Recebeu um relatório de bug: **apenas corrija**. Aponte para o log, o erro, o teste
  falhando — e resolva. Zero troca de contexto necessária do usuário.
- **Limite:** se após 3 tentativas o bug persistir, documente as hipóteses testadas e
  escale para o humano.

### 6. Quando escalar para o humano

**Sempre pergunte antes de** (ações destrutivas ou de difícil reversão — Charter Art. 6):

- Alterar schema de banco de dados
- Mudar configuração de produção
- Excluir arquivos ou dados
- Alterar regras de autenticação/autorização

**Escale quando** a solução exigir decisão de negócio, houver múltiplos caminhos válidos
com trade-off significativo, ou o contexto for insuficiente.

**Não adivinhe:** uma pergunta custa menos que um rollback.

---

## Fluxo de artefatos (SDD)

Toda tarefa não trivial segue o ciclo abaixo; cada etapa gera artefatos em
`<docsRoot>/<slug>/` e passa por um gate de validação automático.

```
/keelson:specify → /keelson:plan → /keelson:tasks → /keelson:implement
     (SPEC)            (PLAN)          (TASKs)            (código)
```

- **Não sabe como rotear uma demanda nova?** `/keelson:change "<descrição>"` faz a triagem.

### Execução de código (protocolo proporcional)

O modo padrão de codificar é o **protocolo do `/keelson:implement`**: escopo restrito,
testes cobrindo o comportamento, os **quality gates** como critério de pronto, e closure.
Aplicado em rigor **proporcional ao risco** da mudança:

| Mudança | Como executar |
|---|---|
| Feature nova / mudança de contrato | Ciclo SDD completo: `specify → plan → tasks → implement` |
| Risco (auth, segurança, migração/schema, breaking) ou que toque um slug com PLAN ativo | Protocolo formal: TASK avulsa + subagents (`task-implementer` → `task-reviewer`, mais `security-reviewer`/`task-verifier` quando aplicável) + closure no INDEX |
| Bug / refactor pequeno | Inline: implementa (escopo restrito) + testes + auto-revisão pelos gates + 1 linha no INDEX. Sem subagent nem TASK |
| Trivial (typo, copy, cor, espaçamento) | Direto no código, sem SDD |

**Multi-arquivo sozinho não é risco.** Uma mudança de lógica trivial que atravessa
camadas continua sendo "bug/refactor pequeno" — roteie pela **calibração de esforço**
(complexidade × risco), não pela contagem de arquivos.

### Os quality gates (proporcionais)

1. ACs cobertos por teste
2. Testes passando (`quality.test`)
3. Lint limpo (`quality.lint`)
4. Escopo respeitado
5. Decisões (DEC) respeitadas
6. Aderência ao Charter + perfil de linguagem + instruções do projeto
7. Code review (ver `./CODE-REVIEW.md`)
8. **Segurança** (`security-reviewer`, `./SECURITY.md`, rejeição imediata) — quando
   `gates.security` e a mudança é sensível (toca `sensitiveGlobs`)
9. **Comportamento verificado** (`task-verifier`) — quando `gates.screenVerify` e a
   mudança tem efeito observável

Para bug/refactor, o protocolo é o **modo de executar** — não exige criar SPEC/PLAN/TASK
formais.

**Gerador ≠ avaliador também na rota inline:** a auto-revisão pelos gates de julgamento
(escopo, aderência, review qualitativo) tende à autoindulgência. A prova de pronto é
**externa e falsificável** — teste cobrindo o comportamento; o auto-checklist não a
substitui. Mudança qualitativa sem teste possível (ex.: refactor de legibilidade) → 1
passada de **revisão independente com contexto limpo**, não o auto-checklist.

**Garantia determinística:** um hook de encerramento (`security-guard`) reforça o gate 8
— detecta mudança sensível (por conteúdo/path em `sensitiveGlobs`) e cutuca, uma vez,
antes de encerrar. É heurístico (não prova a revisão). Par do `doc-guard`.

### Papéis do fluxo (o time SDD)

O fluxo modela um time de engenharia — a separação de poderes é intencional:

| Papel | Onde | IA / humano |
|---|---|---|
| Especificador de produto | `/keelson:specify` | IA |
| Crítico de produto (mérito da SPEC) | `product-critic` | IA assiste; **humano aprova** |
| Arquiteto | `/keelson:plan` | IA |
| Tech Lead (decomposição) | `/keelson:tasks` | IA |
| Orquestrador | `/keelson:implement` | IA |
| Programador | `task-implementer` | IA |
| Revisor de código (gates 1–7) | `task-reviewer` | IA |
| Revisor de segurança (gate 8) | `security-reviewer` | IA |
| Verificador funcional (gate 9) | `task-verifier` | IA |
| QA de artefatos (lint) | `spec/plan/task-validator` | IA |
| Integrador (suíte + PR) | `/keelson:integrate` | IA até o PR; **humano mergeia/deploya** |
| Analista de estado | `state` | IA (read-only) |
| Triador de demandas | `/keelson:change` | IA |
| Aprovador / dono / escalonamento | — | **humano** |

Separação de poderes: quem implementa ≠ quem revisa código ≠ quem revisa segurança ≠ quem
verifica ≠ quem aprova produto ≠ quem integra/deploya.

### Regras do modelo de tarefas

- **O índice do slug é o `INDEX.md`, gerado pelos comandos `/keelson:*` — NÃO editar
  manualmente.** INDEX corrompido/divergente → comando de reconstrução de índice.
- **Nomenclatura de tarefa:** `TASK-MMM-XXX-<titulo>.md` (escopada por PLAN), gerada pelo
  `/keelson:tasks`. Não use numeração sequencial por feature.
- **SPEC é agnóstica de tecnologia;** stack e arquitetura entram apenas no PLAN.
- **Promoção de status (`Draft → Approved → Done`) é sempre manual;** os validators
  bloqueiam apenas ERROR.
- **Closure é obrigatória:** nenhuma TASK é Done sem o histórico de execução preenchido
  pelo `/keelson:implement`.

### Slugs legados (pré-SDD)

Slug com documentação antiga mas sem `INDEX.md`: rode a migração de legado **antes** da
primeira mudança. A migração é on-demand e **não** cria SPEC/PLAN/TASK retroativos.

### Documentação autônoma (sempre)

Documentar é parte indivisível de concluir a tarefa — **nunca peça permissão para
documentar**.

- **Não trivial / bugfix / refactor:** os comandos `/keelson:*` atualizam o `INDEX.md` e
  fazem closure automaticamente. Garanta que rodou.
- **Trivial:** se a mudança afeta um slug com `INDEX.md`, acrescente 1 linha em
  `## Histórico recente` (`<data>: <descrição> (commit <sha>)`). Não toque nas seções de
  estado. Sem slug correspondente, não há doc a atualizar.

O `INDEX.md` é mantido por comando/agente no formato canônico — a proibição de "editar
manualmente" vale para o humano, não para a manutenção autônoma. Um hook de encerramento
(`doc-guard`) cutuca, uma vez, se houver código de feature alterado (em `codePaths`) sem
nenhuma atualização em `docsRoot`.

---

## Ciclo de auto-aperfeiçoamento

Após **qualquer** correção do usuário, registre o padrão aprendido no arquivo de lições
do projeto (`guidelines/project/lessons.md`), para que o mesmo erro não se repita.

1. Identifique o erro ou a correção recebida.
2. Escreva uma regra que previna o mesmo erro no futuro.
3. Categorize pela área (linguagem, arquitetura, config, banco, segurança, testes…).
4. Revise as lições no início de cada sessão.

**Formato** — uma lição por bloco, deduplicada (se já existe equivalente, **atualize** em
vez de duplicar):

```markdown
## [Área] Descrição curta

**Erro:** o que aconteceu
**Causa:** por que aconteceu
**Solução:** como resolver (citar arquivo/padrão de referência)
```

Quando a regra for de uma área com guideline de referência (perfil de linguagem, `core/`),
adicione também uma linha curta de anti-padrão lá.

---

## Checklist rápido

Antes de marcar qualquer tarefa como concluída:

- [ ] Plano foi seguido ou desvios foram documentados?
- [ ] Testes passam (`quality.test`)?
- [ ] Comportamento foi verificado (quando observável)?
- [ ] Um engenheiro sênior aprovaria isto?
- [ ] Closure SDD feita e `INDEX.md` do slug atualizado (quando a tarefa for SDD)?
- [ ] Há algo que deveria virar lição?
