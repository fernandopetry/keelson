# Workflow (core)

> Princípios de **engenharia e orquestração** — agnósticos de linguagem. Complementa o
> `../_meta/QUALITY-CHARTER.md`: o Charter diz *o que é qualidade*; este documento diz
> *como trabalhar* para chegar lá. O **fluxo de artefatos** (spec → plan → tasks →
> código) é o **spec-driven development (SDD)** do keelson.

---

## Princípios fundamentais

- **Simplicidade primeiro:** faça cada mudança o mais simples possível; impacte o mínimo
  de código.
- **Sem preguiça:** encontre a causa raiz. Sem correção temporária, sem gambiarra.
- **Impacto mínimo:** a mudança toca só o necessário (Charter Art. 6).
- **Esforço proporcional** a **complexidade × risco** (Charter, régua geral) — cortar
  redundância (provar a mesma coisa 2×, re-explorar o mesmo domínio, planejar em dobro)
  é cortar **desperdício**, não qualidade.
- **Reúso antes de criar** (Charter Art. 3) — inclusive entre variações próximas
  (ex.: criar/atualizar): reimplementar o que já existe é proibido.

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
  extenso; salve o resultado num **memo de exploração** e reúse-o nas etapas seguintes
  em vez de re-explorar (mecânica do memo: convenções comuns do SDD,
  `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`).
- Para problemas **genuinamente complexos**, aí sim invista mais poder computacional
  (mais exploradores, verificação adversarial).

### 3. Verificação antes de concluir

- Nunca marque uma tarefa como concluída sem **provar** que funciona.
- **Forte e única, não redundante** — regra completa no dono: `./TESTING.md`
  ("Verificação forte e única").
- Compare o comportamento entre a versão base e a sua mudança quando relevante.

### 4. Correção autônoma de bug

- Recebeu um relatório de bug: **apenas corrija**. Aponte para o log, o erro, o teste
  falhando — e resolva. Zero troca de contexto necessária do usuário.
- **Limite:** se após 3 tentativas o bug persistir, documente as hipóteses testadas e
  escale para o humano.

### 5. Quando escalar para o humano

A régua é a **reversibilidade** (Charter Art. 6): ação destrutiva ou de difícil reversão
(excluir dados/arquivos, `DROP`/`ALTER` destrutivo, config de produção, contrato público)
**sempre** espera resposta humana antes de ser aplicada. Mudança simples e reversível —
mesmo em área sensível (coluna nullable nova, permissão no padrão do catálogo) — segue
com a decisão registrada e os gates aplicáveis. Escale também quando a solução exigir
decisão de negócio ou trade-off significativo entre caminhos válidos.

**Mudança de schema faseada** — remoção/renome de campo consumido vira sequência
reversível: adicionar → migrar dados → mudar consumo → remover em deploy **posterior**.
Teste: o mesmo PR/deploy contém a remoção do legado **e** o código que parou de
consumi-lo → reprova (Charter Art. 6).

**Quando perguntar** depende do modo: humano presente (guiado/avulso) → na hora; fluxo
autônomo pós-largada → escada de reação do `/keelson:auto` (decidir e registrar →
estacionar p/ lote da Entrega → interromper em último caso). **Não adivinhe** no
irreversível: uma pergunta custa menos que um rollback.

---

## Fluxo de artefatos (SDD)

Toda tarefa não trivial segue o ciclo abaixo; cada etapa gera artefatos em
`<docsRoot>/<slug>/` e passa por um gate de validação automático.

```
/keelson:specify → /keelson:plan → /keelson:tasks → /keelson:implement
     (SPEC)            (PLAN)          (TASKs)            (código)
```

- **Não sabe como rotear uma demanda nova?** `/keelson:triage "<descrição>"` faz a triagem.

### Execução de código (protocolo proporcional)

O modo padrão de codificar é o **protocolo do `/keelson:implement`**: escopo restrito,
testes cobrindo o comportamento, os **quality gates** como critério de pronto, e closure.
Aplicado em rigor **proporcional ao risco** da mudança:

| Mudança | Como executar |
|---|---|
| Feature nova / mudança de contrato | Ciclo SDD completo: `specify → plan → tasks → implement` |
| Risco (auth, segurança, migração/schema, breaking) ou que toque um slug com PLAN ativo | Protocolo formal: TASK avulsa + subagents (`developer` → `code-reviewer`, mais `security-engineer`/`qa`/`performance-engineer` quando aplicável) + closure no INDEX |
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
8. **Segurança** (`security-engineer`, `./SECURITY.md`, rejeição imediata) — quando a
   mudança toca área sensível (lista canônica: description do `security-engineer`)
9. **Comportamento verificado** (`qa`) — quando a mudança tem efeito
   observável
10. **Performance** (`performance-engineer`, `./PERFORMANCE.md`) — quando o diff toca
    superfície de custo (lista canônica: description do `performance-engineer`); padrão
    patológico bloqueia, otimização sem medição é sugestão (Art. 8)
11. **Design/UX** (`product-designer`, `./DESIGN.md`) — quando o diff toca superfície
    de interface (lista canônica: description do `product-designer`); padrão descuidado
    do catálogo bloqueia, refinamento sem âncora no produto é sugestão (Art. 10)

Gatilhos e condições dos gates 8–11: detalhe operacional do `/keelson:implement`.

Para bug/refactor, o protocolo é o **modo de executar** — não exige criar SPEC/PLAN/TASK
formais.

**Gerador ≠ avaliador também na rota inline** (Charter, régua geral): mudança
qualitativa sem teste possível (ex.: refactor de legibilidade) → 1 passada de **revisão
independente com contexto limpo**, não o auto-checklist.

**Garantia determinística:** um hook de encerramento (`security-guard`) reforça o gate 8
— detecta mudança sensível (por conteúdo/path em `sensitiveGlobs`) e cutuca, uma vez,
antes de encerrar. É heurístico (não prova a revisão). Par do `doc-guard`.

### Papéis do fluxo (o time SDD)

O fluxo modela um time de engenharia (contrato Diretor–PO, decisões 4.37/4.38) — os
papéis operacionais vivem nas descriptions dos comandos e agents; a main session é o
**Tech Lead** e o humano é o **Diretor**. Separação de poderes: quem implementa ≠ quem
revisa código ≠ quem revisa segurança ≠ quem verifica ≠ quem aprova produto ≠ quem
integra/deploya. **Aprovação de produto**: no ciclo com BRIEF, é do `po` — contra o
brief, nunca contra a própria opinião; sem brief (fluxo avulso) ou no `/keelson:guided`,
é humana. As fronteiras **sempre humanas**: veto e escalação (o Diretor), abrir PR,
mergear para a branch principal e deployar — a autonomia termina no push da branch de
trabalho. Exceção declarada no dono da regra (`sdd-conventions.md`, item "Merge, PR e
deploy são humanos"): o `/keelson:merge`, invocado pelo Diretor, mescla branches para
dentro da branch de trabalho corrente — nunca para a principal.

### Regras do modelo de tarefas

- **O índice do slug é o `INDEX.md`, gerado pelos comandos `/keelson:*` — NÃO editar
  manualmente.** INDEX corrompido/divergente → comando de reconstrução de índice.
- **Nomenclatura de tarefa:** `TASK-MMM-XXX-<titulo>.md` (escopada por PLAN), gerada pelo
  `/keelson:tasks`. Não use numeração sequencial por feature.
- **SPEC é agnóstica de tecnologia;** stack e arquitetura entram apenas no PLAN.
- **Promoção de status (`Draft → Approved → Done`) nunca é feita por validator** — ele
  apenas bloqueia ERROR. Quem promove: no ciclo com BRIEF (modo autônomo), a main
  session, pelo veredito `APROVAR` do `po` (decisão 4.38); sem brief ou no
  `/keelson:guided`, o humano.
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

**Formato canônico** — uma lição por bloco, deduplicada (se já existe equivalente,
**atualize** em vez de duplicar — e atualizar **é** o evento de confirmação: incremente
`confirmada`):

```markdown
## [Área] Descrição curta

**Erro:** o que aconteceu
**Causa:** por que aconteceu
**Solução:** como resolver (citar arquivo/padrão de referência)
**Validade:** <condição verificável que a mantém válida — ex.: "enquanto <lib> < 3.0"> | indeterminada
**Estado:** ativa | em-observacao | revogada
**Contadores:** confirmada N · contestada N
```

**Ciclo de vida** (decisão 4.221) — o estado governa a força da lição:

- **Nascimento**: lição de **defeito real** (achado de gate, correção do usuário) nasce
  `ativa` — o defeito é a evidência. Lição de origem **opinativa** (sugestão sem defeito
  observado, importada de outro projeto) nasce `em-observacao`.
- **Força por estado**: só `ativa` vale como regra (critério de TASK, gate 7);
  `em-observacao` é contexto de leitura, nunca obrigação; `revogada` não vale.
- **Promoção**: `confirmada ≥ 1` (a lição pegou/evitou o mesmo erro de novo, ou o
  dedupe a atualizou) promove `em-observacao` → `ativa`.
- **Contestação** (a escada simétrica): lição que bloqueou caso legítimo, contornada
  com razão declarada, incrementa `contestada` — 1ª → **reformule** a lição (nunca
  duplique nem crie exceção ao lado); 2ª → **revogue**. O sinal chega pelo report do
  developer (`licao_contestada`) e é roteado no fecho, como `licao_candidata`.
- **Revogação**: mova o bloco para a seção `## Revogadas` no fim do arquivo, reduzido a
  1 linha — `- [Área] título — <motivo> (revogada em <data>; histórico no git)`. O
  conteúdo integral vive no histórico de commits; a seção ativa fica limpa e a
  reincidência de lição revogada continua detectável.
- **Eixos ortogonais**: `Estado` é a vida da lição; "em vigor | pendente de merge"
  (decisão 4.71) é o vigor da *escrita* — lição `ativa` numa branch não mergeada segue
  pendente de merge.

Auditoria periódica do acervo (retrofit de formato, origem via git, validade expirada,
sedimento): `/keelson:lessons-audit`.

Quando a regra for de uma área com guideline de referência (perfil de linguagem, `core/`),
adicione também uma linha curta de anti-padrão lá.
