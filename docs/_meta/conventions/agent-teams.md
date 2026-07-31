# Modo AGENT_TEAMS (`/keelson:implement --force-mode=teams`)

**Gatilho**: flag `--force-mode=teams`, com o recurso **Agent Teams** habilitado no ambiente — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env ou `settings.json`; experimental no Claude Code). **Não há detecção programática**: o modelo é tentar e degradar — spawn de teammate falhou/indisponível → siga em `SUBAGENTS` e declare no output.

A estrutura do `/keelson:implement` (etapas, análise de paralelizabilidade, gates, closure, run-state, output) é **idêntica** ao modo `SUBAGENTS` — este arquivo é o dono único das especificidades do modo teams; só muda o que está listado aqui:

- **Setup da wave paralela (Etapa 3.1)**: worktrees por task e branches separadas, **criadas pelo próprio setup da wave** — o Agent Teams não isola worktree nativamente (teammates compartilham o repo por padrão); o isolamento é doutrina do keelson.
- **Sincronização entre tasks da wave (Etapa 3.5)**: coordenação entre teammates via **task list compartilhado** (claim/complete, dependências) e mensagens diretas (em `SUBAGENTS` não há coordenação direta: o subagent para, reporta, main session decide).
- **Final da wave (Etapa 3.6)**: **merge das worktrees** na branch principal da wave **antes** de rodar a suíte da wave; os commits de closure feitos por worktree (`chore(<slug>): close TASK-MMM-XXX`) chegam nesse merge. **Dry-run antes de qualquer merge real** (decisão 4.74): para cada worktree, `git merge-tree --write-tree <branch-da-wave> <branch-da-task>` (git ≥ 2.38; fallback: `git merge --no-commit --no-ff` + `git merge --abort`) — nenhum merge real inicia com dry-run conflitado na fila. Todos limpos → merges em sequência; qualquer conflito → nada é integrado e o reporte ao Diretor sai com a branch da wave **limpa**, listando worktrees e paths em conflito. A regra pós-conflito não muda: pausar, reportar, resolução manual.
- **Output final (Etapa 5)**: reportar `Orquestração: AGENT_TEAMS` (o enum `AGENT_TEAMS | SUBAGENTS | SINGLE_THREAD` do template permanece no comando).

O que **não** muda: critérios SEQUENTIAL_FORCED da Etapa 1 (worktrees não relaxam nenhum), independência gerador ≠ avaliador (o developer nunca revisa o próprio diff — decisão 4.30), closure obrigatória por task e o sentinela `run-state`/`wave-guard`.
