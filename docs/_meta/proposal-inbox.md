# Fila de propostas de consumidores (decisão 4.111)

Consumidores do keelson produzem propostas de melhoria do plugin (`PROPOSTA_PLUGIN`, via
`agile-coach` em modo consumidor) nos próprios ledgers — com diff literal, contra a versão
instalada. Esta fila é o **lado do mantenedor**: cada proposta que chega ao Diretor é
registrada aqui **antes do parecer**, e nenhuma entra em doutrina sem passar por esta fila.

**Contrato**:

- **Registrar na chegada**: a sessão que recebe postmortem/ledger/mensagem com propostas
  escreve a linha **antes** de emitir parecer — origem abstraída (4.72: só o id do
  registro no ledger de origem, ex. `LRN-031`, sem nome/paths do consumidor), 1 linha do
  padrão genérico, alvo no plugin.
- **Fechar na leva**: a leva que aplica/recusa atualiza o Estado — `aplicada (4.x)` com a
  decisão que a absorveu, ou `recusada (motivo curto)`. `recebida` que atravessa uma leva
  é pendência visível, não backlog silencioso.
- **Reincidência referencia a linha anterior** — é o sinal de que o elo falhou uma vez. A partir da **2ª reincidência**, a proposta chega com o **check mecânico/autocheck desenhado** ou com a justificativa de imecanizável (escada da 4.149 — dono: `learning-log.md`); proposta de texto-de-novo sem uma das duas volta para o proponente.
- A fila carrega **ponteiros, nunca texto de doutrina** — o dono da regra é o arquivo dela.

| Data | Origem | Padrão proposto | Alvo | Estado |
|---|---|---|---|---|
| 2026-08-04 | LRN-014 (reincidente ×1 — 1ª proposta de 2026-07-23 nunca aplicada) | Aresta entre TASKs irmãs da mesma wave tem dono declarado no Escopo | commands/tasks.md | aplicada (4.106) |
| 2026-08-04 | LRN-031 | Literal de comando/critério conferido na fonte real; invariante estrutural por símbolo, nunca por caminho | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-032 | Roteiro de gate 9 hierárquico inclui passo que cruza a fronteira do agrupamento | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-034 | Predicado de escopo nasce com fixture de dois pais e critério de mutação no gate 1 | commands/tasks.md | aplicada (4.107) |
| 2026-08-04 | LRN-035 | Superfície de API e schema do PLAN verificados contra a fonte real, nunca deduzidos | commands/plan.md | aplicada (4.108) |
| 2026-08-04 | LRN-036 | Fechamento de achado multi-sujeito re-lê o FR/AC de origem e cobre todos os sujeitos nomeados | guidelines/core/CODE-REVIEW.md | aplicada (4.109) |
| 2026-08-04 | LRN-037 | Ausência de prova conta para o teto de retry; "mecânico" vai na proposta da escalação | guidelines/core/CODE-REVIEW.md | aplicada (4.110) |
| 2026-08-04 | LRN-038 (2ª ocorrência — a 1ª virou workaround de projeto e nunca escalou) | `qa` recebe o grant `mcp__playwright__*` que a própria doutrina manda usar; a classe vira check mecânico | agents/qa.md · scripts/check-agents.sh | aplicada (4.105) |
| 2026-08-05 | relato do Diretor (sessão de consumidor — comando de retomada `implement <ID nu>` casava 9 arquivos, um por slug) | Artefato SDD citado fora do slug viaja com o caminho relativo; ID nu ambíguo na entrada para e lista | docs/_meta/conventions/sdd-conventions.md · commands/* | aplicada (4.124) |
| 2026-08-06 | LRN-043 | Lição persistida em `lessons.md` que nomeia arquivo-alvo da TASK vira item verificável do Critério de pronto na geração — nunca leitura voluntária | commands/tasks.md | aplicada (4.138) |
| 2026-08-06 | LRN-015 (reincidente ×1 — 1ª proposta de 2026-07 nunca aplicada; a ambiguidade prosa×critério que ela deixou decidiu o caso) | Pendência herdada de achado de gate entra no despacho como item explícito do Critério de pronto da TASK que a recebe, nunca como prosa no Contexto | commands/implement.md §3.2 | aplicada (4.140) |
| 2026-08-06 | LRN-034 (2ª reincidência — a regra da 4.107 foi cumprida nominalmente: 2 de 4 métodos com prova, 5 mutantes vivos com suíte verde) | Critério de mutação de predicado de escopo exige fechamento contável ("N métodos no Escopo, N provas"), nunca lista de instâncias; exemplo nomeado é ilustração não-exaustiva | commands/tasks.md (item (c) da 4.107) | aplicada (4.139 — reformulação do item (c)) |
| 2026-08-06 | LRN-044 | Critério herdado por extenso ganha endereço: nomeia arquivo+ação que o cumprem e o `Escopo > Inclui` o incorpora — senão vira TASK própria na mesma wave | commands/tasks.md | aplicada (4.138) |
| 2026-08-06 | LRN-045 | Gate cujo mecanismo de prova muta arquivos do diff trata a working tree como recurso exclusivo — worktree isolada, nunca a árvore de outro gate concorrente que também mute | guidelines/core/CODE-REVIEW.md | aplicada (4.134) |
| 2026-08-06 | LRN-046 | Regra que existe verbatim e reincide não ganha mais texto — vira autocheck: developer relê os comentários que introduziu no retry antes de reportar Done | agents/developer.md | aplicada (4.135) |
| 2026-08-06 | LRN-047 | Pacote do gate 9 por FEAT leva os achados dos gates 7/8 da wave e reconcilia o roteiro envelhecido antes do despacho | commands/implement.md | aplicada (4.140) |
| 2026-08-11 | LRN-031 (reincidente ×1 pós-4.107 — regra lida e não preveniu; 12 ocorrências no mesmo ciclo, 2 delas ensinariam o bug de volta) | Critério de gate 1 com `grep`/`rg` sem âncora de símbolo, sem fronteira de comentário/docblock e sem escopo a arquivo único vira fato de lint (WARNING); task-validator julga se a condição é estrutural e escala | scripts/artifact-lint.sh · docs/_meta/conventions/lint-contract.md (grupo TASK) · skills/task-validator | aplicada (4.161) |
| 2026-08-11 | LRN-048 | Verificação de AC que altera arquivo/símbolo compartilhado alcança os demais consumidores conhecidos (`--filter` da própria classe é insuficiente sozinho); dois critérios da mesma TASK nunca se contradizem sobre o mesmo arquivo | commands/tasks.md (bloco "resiste a contorno") | aplicada (4.162) |
| 2026-08-11 | LRN-049 (reincidência de LRN-005 gênese — regra de staging só alcançava o developer; colisão de índice chegou a pôr bypass de tenant na branch) | Commit por pathspec (`git commit -m "…" -- <arquivos>`) para todo ator que commita na working tree compartilhada, nunca `add`-depois-`commit`; dono único na convenção, developer.md cita | docs/_meta/conventions/sdd-conventions.md · agents/developer.md | aplicada (4.163) |
| 2026-08-11 | LRN-050 | Dado que atravessa 3+ camadas com decomposição nomeando só as duas pontas: a camada intermediária carrega item próprio no Escopo > Inclui de alguma task da wave, mesmo quando parece só repasse | commands/tasks.md (princípio 2, 4.106) | aplicada (4.164) |
