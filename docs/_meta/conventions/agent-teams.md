# Modo AGENT_TEAMS (`/keelson:implement --force-mode=teams`)

**Gatilho**: flag `--force-mode=teams`, quando o ambiente suportar (ex.: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Sem suporte → siga em `SUBAGENTS` e declare no output.

A estrutura do `/keelson:implement` (etapas, análise de paralelizabilidade, gates, closure, run-state, output) é **idêntica** ao modo `SUBAGENTS` — este arquivo é o dono único das especificidades do modo teams; só muda o que está listado aqui:

- **Setup da wave paralela (Etapa 3.1)**: worktrees por task, branches separadas, teammates com peer-to-peer.
- **Sincronização entre tasks da wave (Etapa 3.5)**: task list compartilhado e coordenação peer-to-peer entre teammates (em `SUBAGENTS` não há peer-to-peer: o subagent para, reporta, main session decide).
- **Final da wave (Etapa 3.6)**: **merge das worktrees** na branch principal da wave **antes** de rodar a suíte da wave; os commits de closure feitos por worktree (`chore(<slug>): close TASK-MMM-XXX`) chegam nesse merge. Conflito de merge → regra do implement: pausar, reportar, resolução manual.
- **Output final (Etapa 5)**: reportar `Orquestração: AGENT_TEAMS` (o enum `AGENT_TEAMS | SUBAGENTS | SINGLE_THREAD` do template permanece no comando).

O que **não** muda: critérios SEQUENTIAL_FORCED da Etapa 1 (worktrees não relaxam nenhum), independência gerador ≠ avaliador (o developer nunca revisa o próprio diff — decisão 4.30), closure obrigatória por task e o sentinela `run-state`/`wave-guard`.
