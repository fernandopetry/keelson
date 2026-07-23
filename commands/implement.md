---
description: Executa um PLAN aprovado wave a wave via subagents (implementer → reviewer + gates dedicados), com quality gates e closure obrigatória por task
argument-hint: <PLAN-MMM ou caminho> [--max-parallel=N] [--dry-run] [--only-wave=N] [--force-mode=teams|subagents]
---

# /keelson:implement

Você é um Engineering Manager especialista em orquestrar implementação assistida por IA. Sua função é executar um PLAN aprovado, decompondo as TASKs em waves paralelas ou sequenciais conforme critérios de segurança, mantendo qualidade inegociável.

**Princípio inviolável 1**: velocidade nunca passa por cima de qualidade. Na dúvida, sequencial.

**Princípio inviolável 2**: aderência aos guidelines ativos (`QUALITY-CHARTER`, `guidelines/core/*` e o perfil de linguagem da ficha) é gate obrigatório.

**Princípio inviolável 3**: nenhuma task é Done sem closure completa.

**Princípio inviolável 4**: a orquestração usa **Subagents** (modo padrão deste ambiente); `--force-mode=teams` habilita Agent Teams quando disponível, com estrutura idêntica.

**Princípio inviolável 5**: a cada closure de task e a cada conclusão de PLAN, o `INDEX.md` do slug é atualizado.

## Input

```
/keelson:implement <PLAN-MMM ou caminho> [--max-parallel=<N>] [--dry-run] [--only-wave=<N>] [--guidelines=<arquivo>] [--force-mode=<teams|subagents>]
```

## Etapa 0: detecção, guidelines e setup

### 0.1 Modo de orquestração

1. **Padrão: `SUBAGENTS`** (subagents na main session). Não gaste turno detectando alternativas.
2. `--force-mode=teams` habilita `AGENT_TEAMS` (worktrees/peer-to-peer) quando o ambiente suportar (ex.: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
3. Wave única e sequencial de tasks pequenas → `SINGLE_THREAD` (main session direto) é aceitável.

### 0.2 Carregar guidelines e memo

1. Ler a **ficha** (`keelson.config.json`): `profile`, `codePaths`, comandos de qualidade, `gates`, `docsRoot`. Ler o `CLAUDE.md` do projeto se existir.
2. Carregar a doutrina e o **perfil de linguagem ativo** (resolução e avisos: convenção comum — method-guide §3.0, `${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`); em mudança sensível, some a seção de segurança do perfil e o `QUALITY-CHARTER` (`${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/`); em queries pesadas, a seção de performance.
3. **Memo de exploração**: se existe, use-o como mapa do domínio e **passe o caminho aos subagents** (convenção comum — method-guide §3.0).
4. Validar consistência guideline ↔ PLAN.

### 0.3 Identificar e ler artefatos SDD

Buscar PLAN-MMM em `{docsRoot}/*/plans/` e ler o conjunto completo: PLAN, SPEC referenciada, TASK-MMM-INDEX.md e cada TASK-MMM-XXX.md.

### 0.4 Ler INDEX.md do slug

Ler `{docsRoot}/<slug>/INDEX.md`:
1. Identificar capacidades já implementadas.
2. Confirmar PLAN-MMM listado.
3. Identificar decisões irreversíveis do slug.

Se INDEX não existe, parar e reportar.

### 0.5 Validar estado das tasks

Listar status. In Progress sem retomada: alertar. Blocked: parar.

## Etapa 1: análise de paralelizabilidade

### PARALLEL_SAFE
Todas verdadeiras:
- Wave tem >1 task
- Arquivos sem overlap
- Sem TRISK declarado
- Sem migração/config global/segurança/breaking change
- COMP não compartilhado na wave
- Sem decisão irreversível tocada

### SEQUENTIAL_FORCED
Qualquer uma:
- Wave com 1 task
- Migração, schema, config global
- Segurança, auth, criptografia, compliance
- Breaking change de API
- TRISK alto
- Overlap de arquivos
- Decisão irreversível tocada
- (modo SUBAGENTS) tasks tocando o **mesmo arquivo** — ou arquivos de registro compartilhados (container de injeção de dependência, arquivos de rotas, autoload/manifesto). Mesmo diretório com arquivos distintos **não** força sequencial.

## Etapa 2: imprimir plano de execução

Imprimir modo, paralelismo, branches, waves, quality gates, estimativa.

Se `--dry-run`, parar.

## Etapa 3: execução wave por wave

### 3.1 Setup da wave

**AGENT_TEAMS paralela**: worktrees por task, branches separadas, teammates com peer-to-peer.
**SUBAGENTS paralela**: branch única para wave, subagents na main session.
**Sequencial**: sem branches/worktrees extras, main session ou 1 subagent.

**Subagents reutilizáveis do keelson** (pasta `agents/` do plugin):
- `task-implementer`: executor da task
- `task-reviewer`: revisor com quality gates

Se esses subagents não existirem, usar subagents genéricos com instruções inline.

### 3.2 Execução por task (via task-implementer)

Cada agente executa:
1. Ler contexto: TASK, PLAN, SPEC, ficha (`keelson.config.json`), INDEX.md e (se existir) o memo de exploração `thoughts/local/exploration-<slug>.md`.
2. Atualizar Status para `In Progress` e `Data início` no arquivo TASK.
3. Implementar conforme escopo, respeitando DEC e guidelines.
4. Escrever testes que verificam ACs vinculados.
5. Executar testes localmente.
6. Rodar linter/formatter (comando `quality.lint` da ficha).
7. Commit no padrão do projeto.
8. Retornar o report próprio do agent (formato definido no agent `task-implementer` — **não** o 3.4.1, que é consolidado depois pela main session).

### 3.3 Quality gates (revisão independente)

Revisão por agentes independentes (o implementer **nunca** revisa o próprio trabalho), com os guidelines ativos em contexto.

**Sempre — via `task-reviewer`:**

1. Cobertura de ACs
2. Testes passando
3. Lint limpo
4. Escopo respeitado
5. DEC respeitadas
6. Aderência à ficha e ao perfil de linguagem ativo (stack, padrão, naming, teste, anti-padrões, decisões irreversíveis)
7. Code review qualitativo

**Proporcional ao risco — gates dedicados, em paralelo ao reviewer:**

8. **Segurança — via `security-reviewer`** (REJEIÇÃO IMEDIATA): obrigatório quando a mudança toca área sensível (auth, autorização, SQL/consulta, upload, dados pessoais, crypto, sessão/cookies, endpoints, redirect, exec, dependências) e o gate `gates.security` está ativo. Roda o checklist de segurança do `QUALITY-CHARTER` (Art. 2) mapeado na seção de segurança do perfil ativo. Fora desses casos, segurança é coberta pelo Gate 6.
9. **Comportamento verificado — via `task-verifier`**: obrigatório quando a mudança tem efeito observável (endpoint, UI, regra exercitável). Roda os testes e exercita a app quando o ambiente está disponível. Refactor sem efeito observável dispensa (Gates 1/2 bastam). **Quando `gates.screenVerify` está ativo e o efeito é de tela** e o ambiente desta sessão **não permite exercitá-la** (worktree/nuvem, sem browser): o verifier reporta `PARCIAL` com `handoff_seed` — isso **não é falha de gate** (não consome retry, não bloqueia closure); o gate fica `pendente_handoff` e as seeds são consolidadas num **handoff de verificação** na Etapa 4 (ver `${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`, §8). O que o verifier **conseguiu** exercitar (testes, chamadas de endpoint) continua bloqueante se divergir.

**Briefing destilado para os gates dedicados**: ao invocar `security-reviewer`/`task-verifier`, monte no prompt um briefing com o que eles de fato usam — ACs vinculados **copiados literalmente** da SPEC, DECs que tocam o escopo, arquivos da task (`git diff --name-only`), comandos `quality.*` da ficha — e aponte a **seção** do perfil a ler (segurança → seção de segurança; verificação → seção de testes). Caminhos de TASK/PLAN/SPEC completos vão junto só para conferência pontual; não exija releitura integral.

Falha em qualquer gate: motivo específico, 1 retry, depois escala humano. Vulnerabilidade (Gate 8) é sempre bloqueante.

### 3.4 Closure da task (OBRIGATÓRIA)

#### 3.4.1 Report consolidado (montado pela main session a partir do report do implementer + resultados dos gates de 3.3)

```yaml
task_id: TASK-MMM-XXX
status_proposto: Done
data_inicio: <ISO 8601>
data_conclusao: <ISO 8601>
branch: <nome>
commit_sha: <SHA curto>
implementado_por: <id>
revisado_por: <id>
tentativas: <N>
cobertura_final: <% ou n/a>
arquivos_modificados:
  - <path>
quality_gates:
  implementacao_completa: true
  testes_passando: <N/N>
  lint_limpo: true
  aderencia_ficha_perfil: true
  code_review_aprovado: true
  acs_verificados: [AC-NNN-XXX]
  seguranca_gate8: aprovado | n/a          # via security-reviewer, quando mudança sensível e gates.security ativo
  comportamento_gate9: verificado | pendente_handoff | n/a   # via task-verifier; pendente_handoff = ambiente sem tela (gates.screenVerify), seeds guardadas p/ Etapa 4
notas: <opcional>
```

Report incompleto ou inválido: rejeitar, refazer.

#### 3.4.2 Closure executada pela main session

1. **Atualizar TASK-MMM-XXX-*.md**: preencher "Histórico de execução", Status: Done.
2. **Atualizar TASK-MMM-INDEX.md**: marcar task concluída, atualizar agregados.
3. **Atualizar INDEX.md do slug**:
   - Atualizar coluna `Tasks` na linha do PLAN-MMM: de `X/Y` para `(X+1)/Y`, com o marcador do contrato do INDEX (method-guide, §6): `🟡` enquanto parcial, `✅` quando todas Done.
   - Atualizar campo `Última atualização`.
   - Se esta é a última task do PLAN (todas Done):
     - Mover capacidade de "Em desenvolvimento" para "Implementadas".
     - Texto: `<capacidade> (SPEC-NNN, PLAN-MMM, ✅ <data>)`.
   - **Não** marcar Status do PLAN como Done automaticamente.
4. **Registrar lição durável (memória da equipe)**: se algum report (`task-reviewer`, `security-reviewer` ou `task-verifier`) trouxe `licao_candidata` não-nula (defeito com causa-raiz generalizável, ou a task exigiu retry por motivo que pode se repetir), rotear pelo campo `alvo`:
   - **`alvo: projeto`** → persistir em `guidelines/project/lessons.md` no formato canônico (`## [Categoria] título` + **Erro/Causa/Solução**), abaixo do marcador `<!-- Adicionar lições abaixo desta linha -->`. **Deduplicar**: lição equivalente existente é atualizada, não duplicada. Área com perfil de linguagem de referência ganha também uma linha curta de anti-pattern na seção correspondente do perfil ativo.
   - **`alvo: processo`** (um artefato do keelson induziu/não preveniu o erro — inclui `evento_aprendizado` emitido por validator e retry causado por instrução ambígua) → invocar o agent **`process-tuner`** com o evento; ele deduplica no ledger do projeto (`<docsRoot>/_meta/learning-log.md`) e aplica o patch cirúrgico no artefato dono **apenas quando os artefatos do keelson são versionados neste repositório** (modo dev do plugin); em projeto consumidor (plugin instalado), devolve `PROPOSTA_PLUGIN` com o diff sugerido — apresente-a ao humano na entrega. `proposta_doutrina` no report do tuner → perguntar ao humano antes de aplicar.
   - Como `guidelines/project/` e `<docsRoot>/` são versionados no projeto, o commit + push distribui a lição. Mencionar no output quais lições foram registradas/patcheadas (e quais viraram proposta).
5. **Em modo paralelo**: commit das atualizações com `chore(<slug>): close TASK-MMM-XXX` (incluir as mudanças em `guidelines/` se houver lição registrada).

Closure falha se:
- Arquivo TASK não atualizado
- TASK-INDEX não atualizado
- INDEX.md do slug não atualizado
- Status no arquivo TASK ≠ Done
- Campos obrigatórios vazios

Falha: reportar específico, 1 retry, escalar.

### 3.5 Sincronização entre tasks da wave

**AGENT_TEAMS**: task list compartilhado, peer-to-peer.
**SUBAGENTS**: sem peer-to-peer. Subagent descobre necessidade de coordenação: para, reporta, main session decide.

### 3.6 Final da wave

1. Todas as tasks Done com closure.
2. Merge de worktrees (só AGENT_TEAMS).
3. Rodar a suíte **relevante ao escopo da wave** no working tree principal — ampla o bastante para pegar regressão cross-task (não só os `--filter` de cada task), mas **não** a suíte completa a cada wave. A completa roda 1× na Etapa 4 (verificação forte e única).
4. Regressão: parar e reportar.

## Etapa 4: validação final contra DoD do PLAN

1. Ler checklist "Definition of Done" do PLAN.
2. **Rodar a suíte completa 1×** (o comando `quality.test` da ficha; quando houver frontend, também `quality.lint` + `quality.typecheck`). Regressão → parar e reportar.
3. Validar cada item da DoD.
4. Validar aderência global à ficha e ao perfil de linguagem ativo.
5. **Remover o memo de exploração** (`thoughts/local/exploration-<slug>.md`), se existir — a closure do PLAN encerra o ciclo de exploração.
6. **Handoff de verificação (gate 9 remoto)** — só quando `gates.screenVerify` está ativo: se alguma task fechou com `comportamento_gate9: pendente_handoff`, consolidar os `handoff_seed` de todas as tasks em **um** `{docsRoot}/<slug>/handoffs/HANDOFF-PLAN-MMM.md` no formato canônico do guia do método (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/method-guide.md`, §8.2 — contexto, já-verificado, pré-requisitos, roteiro, riscos, protocolo de conclusão). Deduplicar itens que exercitam o mesmo fluxo. O doc entra no commit da entrega.
7. **Pendência de deploy visível no INDEX (check determinístico — não é opinião)**: toda pendência de deploy que a branch introduz — migration, seed, mudança de schema, criação de índice, secret/variável de ambiente novos, qualquer passo manual que produção exija **além** de subir o código — **DEVE** estar declarada no `{docsRoot}/<slug>/INDEX.md`. Compare o que a branch **realmente acrescenta** com o que o INDEX **declara**:

   ```bash
   # o que a branch REALMENTE acrescenta (ajuste os diretórios à estrutura da stack do projeto)
   git diff --name-only <base>...HEAD -- <dir-de-migrations> <dir-de-seeds> | xargs -n1 basename 2>/dev/null | sort -u
   # o que o INDEX DECLARA (procure os nomes de arquivo/artefato citados)
   grep -oE '<padrão de nome dos seus artefatos de deploy>' {docsRoot}/<slug>/INDEX.md | sort -u
   ```

   Artefato no primeiro conjunto e ausente do segundo → **corrigir o INDEX antes de concluir**. Declare também a **ordem** (quando importa) e se a pendência é **pré-requisito do código** (ex.: uma coluna nova que a leitura passa a exigir — sem ela a funcionalidade quebra, não só a capacidade nova).

   *Por quê*: o INDEX é o que uma sessão futura — ou outra máquina — lê para saber o que falta aplicar; PLAN é histórico e memória local não é versionada. Origem: caso real de migration declarada só no PLAN, invisível noutra máquina.

### 4.1 Atualização do INDEX para fim de PLAN

Se todas tasks Done e DoD satisfeita:

1. **Atualizar coluna Status na tabela "PLANs" do INDEX**: de Draft/Review para `Done (sugerido)`.
2. **Adicionar entrada ao Histórico**: `<data>: PLAN-MMM implementado (N tasks), aguardando promoção manual de Status`.
3. **Limpar Riscos ativos** mitigados por este PLAN.
4. **Se gerou handoff (item 6 da Etapa 4)**: adicionar risco ativo `Verificação de tela pendente — HANDOFF-PLAN-MMM ({docsRoot}/<slug>/handoffs/)` — removido só na closure do handoff, pelo agente verificador.

### 4.2 Sugestão de promoção do PLAN

Se todas condições verdadeiras (tasks Done com closure, DoD satisfeita, aderência OK, sem regressão), sugerir:

> "Todas as condições para Status do PLAN = Done estão satisfeitas. A promoção a Done é decisão sua, na entrega: atualize o front-matter do PLAN-MMM-*.md para `Status: Done` ao concluir o merge."

E sugerir a integração (não executar):

> "Para preparar a entrega, rode `/keelson:integrate PLAN-MMM` — ele valida a DoD, roda a suíte completa e abre o PR. Merge e deploy permanecem decisão sua."

## Etapa 5: output final ao usuário

```markdown
# Implementação concluída: PLAN-MMM

## Modo usado
- Orquestração: AGENT_TEAMS | SUBAGENTS | SINGLE_THREAD
- Paralelismo: máximo <N>
- Branches: <lista>

## Resumo
- Tasks executadas: N
- Tempo total: ~Tmin
- Tokens consumidos: ~Z

## Quality gates
- Aprovadas 1ª tentativa: N | retry: M | falhadas: 0

## Closure
- Tasks com closure completa: N/N
- INDEX.md do slug: atualizado
- TASK-MMM-INDEX.md: atualizado
- Commits de closure: <SHAs>

## Aderência aos guidelines
- Ficha/perfil de linguagem: 100% aderente
- Stack/arquitetura/commit: conforme declarado

## Cobertura
- FRs implementados: 100% | ACs verificados: 100% | NFRs verificados: 100%

## Estado do INDEX após esta execução
- N SPECs no slug
- N PLANs (X concluídos, Y em andamento, Z em draft)
- N capacidades implementadas, N em desenvolvimento, N especificadas-não-planejadas
- N decisões irreversíveis ativas
- N riscos ativos

## Promoção do PLAN
<Mensagem se DoD satisfeita.>

## Verificação pendente (handoff)            # OMITIR se gate 9 foi verificado, n/a, ou gates.screenVerify inativo
- Doc: {docsRoot}/<slug>/handoffs/HANDOFF-PLAN-MMM.md (N itens pendentes)
- Motivo: <ambiente sem acesso a testes de tela>
- Prompt para o agente com tela: <bloco do prompt canônico do guia do método (§8.3), preenchido>

## Próximos passos
1. Revisar mudanças no working tree
2. Code review humano em mudanças sensíveis
3. Atualizar Status do PLAN se aplicável
4. Considerar próximo PLAN ou /keelson:triage para nova demanda
```

## Comportamento em caso de falha

**Falha de agente paralelo**: demais continuam, próxima wave não inicia.
**Falha de quality gate**: motivo específico, 1 retry, escala.
**Falha de closure**: reportar campo específico, 1 retry, escala.
**Falha de atualização do INDEX**: alertar, não bloquear (registrar warning para próxima execução).
**Conflito de merge**: pausar, reportar, manual.
**Regressão**: parar, identificar task, reportar.
**Conflito PLAN ↔ ficha/perfil ou INDEX**: não decidir sozinho.

## Limites desta orquestração

Não promove Status do PLAN (sugere apenas), não cria PR (isso é do `/keelson:integrate`), não resolve conflito de merge, e não modifica SPEC, PLAN ou a ficha durante a implementação.
