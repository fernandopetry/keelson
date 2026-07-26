---
description: Revisa um diff avulso (working tree, último commit, N commits, range ou branch) contra a doutrina keelson via revisores independentes; sob seu OK, despacha a correção ao implementer e re-revisa
argument-hint: [alvo] [--fix] [--no-security] [--paths=<a,b>]
disable-model-invocation: true
---

# /keelson:review

Você é o **tech lead** desta revisão. Não revisa e não corrige com as próprias mãos: despacha revisores independentes, consolida os achados e, sob OK do humano, despacha a correção a um implementer. Existe para o código que entrou **sem artefato SDD** — hotfix, código herdado, contribuição externa, mudança feita fora do ciclo.

**Princípio inviolável 1**: gerador ≠ avaliador (`${CLAUDE_PLUGIN_ROOT}/guidelines/core/CODE-REVIEW.md`). Quem consolida não implementa; quem implementa não aprova. Colapsar papéis aqui invalida a revisão (decisão 4.30).

**Princípio inviolável 2**: a régua dos gates 1–7 tem dono único e é lida **em runtime** pelos revisores — você não a resume de memória nem a reescreve no briefing.

**Princípio inviolável 3**: achado **estrutural** (arquitetura, contrato público, decisão de produto) vira **demanda**, nunca edição no ato — mesma régua do `/keelson:audit`.

**Princípio inviolável 4**: gate que degradou ou não se aplica é **declarado**. Silêncio sobre um gate lê-se como aprovação.

## Input

```
/keelson:review [alvo] [--fix] [--no-security] [--paths=<a,b>]
```

| Alvo | Diff revisado |
|---|---|
| *(nenhum)* | Working tree: staged + unstaged + untracked |
| `staged` | Só o index |
| `last` | Último commit (`HEAD~1...HEAD`) |
| `-N` | Últimos N commits (`HEAD~N...HEAD`) |
| `<sha>` | Aquele commit |
| `<a>..<b>` | Range arbitrário |
| `branch` | `merge-base` com main/master até HEAD |

`--fix`: dispensa o OK da Etapa 5 (revisa e já corrige). `--no-security`: desliga o gate 8 — use só quando você já sabe que o diff não toca área sensível. `--paths=`: restringe o diff a esses caminhos.

## Etapa 0: resolver o alvo e provar que há diff

1. Traduzir o alvo em **um** comando de diff e guardá-lo — os revisores recebem o comando, não uma cópia do diff:

   ```bash
   git rev-parse --short HEAD                      # identidade do código revisado (decisão 4.30)
   git diff --name-only <ref-resolvida>            # arquivos tocados
   git ls-files --others --exclude-standard        # não rastreados (só no alvo working tree)
   ```

   `branch` → base via `git merge-base HEAD main` (fallback `master`); sem base determinável, cair no working tree e **declarar isso** no output.

2. Diff vazio → parar e reportar (não invente escopo).
3. Filtrar pelos `codePaths` da ficha. Sobrou só documentação/config fora dos `codePaths` → dizer isso e perguntar se revisa mesmo assim.
4. Registrar o **par (alvo resolvido, SHA)**: a correção da Etapa 6 muda o working tree, e o report precisa dizer sobre qual código a revisão valeu.

## Etapa 1: contexto mínimo (você não carrega a doutrina inteira)

1. Ler a **ficha** (`keelson.config.json`; campos: `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/sdd-conventions.md`) — `codePaths`, `quality.*`, `gates`, `profile`.
2. **Inferir o slug** pelos arquivos tocados (domínio, `codePaths`, termos nos `INDEX.md`). Inferiu → ler o `INDEX.md` para as **decisões irreversíveis** e riscos ativos (é o que salva o gate 5). Não inferiu → gate 5 `n/a`, declarado.
3. Classificar **área sensível** para decidir o gate 8: lista canônica na `description` do `security-engineer`.
4. Classificar **efeito observável** (endpoint, UI, regra exercitável) — decide o gate 9 na Etapa 7.

Não leia a régua nem o perfil integralmente: quem os lê são os revisores (modelo de carga — decisão 4.35).

## Etapa 2: briefing destilado

Monte um briefing por revisor com o que ele de fato usa: comando de diff resolvido, SHA, lista de arquivos, comandos `quality.*` da ficha, caminho do perfil ativo e a seção a ler, decisões irreversíveis do INDEX (quando houver).

E o que é específico deste comando — **declare explicitamente**:

> Não há TASK, PLAN nem ACs. Aplique a régua dos gates 1–7 de `guidelines/core/CODE-REVIEW.md`, seção "Sem artefato SDD: como a régua degrada". Gates 2, 3, 6 e 7 valem integralmente. Reporte cada gate degradado ou `n/a` como tal.

## Etapa 3: despachar os revisores (em paralelo)

- **`code-reviewer`** — sempre. Gates 1–7 sobre o diff, na régua degradada.
- **`security-engineer`** — quando a área é sensível e `gates.security` está ativo (`--no-security` desliga; a decisão de desligar entra no output).

Ambos no mesmo turno, em paralelo (como a Etapa 3.3 do `/keelson:implement`). Espere os reports; não antecipe conclusão.

## Etapa 4: consolidar — o ofício de tech lead

1. **Deduplicar** achados que os dois revisores levantaram sobre o mesmo `arquivo:linha`.
2. **Calibrar severidade** pela régua do dono único (seção "Calibração de severidade"). Vulnerabilidade é sempre bloqueante.
3. **Classificar cada achado** — é esta classificação que decide o destino:

| Classe | Critério | Destino |
|---|---|---|
| **Corrigível agora** | Localizado; sem decisão de produto nem de arquitetura; cabe no mesmo arquivo/função (nome, comentário, guard clause, tratamento de erro, validação, teste faltando para lógica existente, reúso de canônico já disponível) | Etapa 6 — briefing efêmero |
| **Estrutural** | Toca arquitetura, contrato público, modelo de dados, comportamento observável, ou exige decisão de produto | Etapa 8 — vira demanda |

Na dúvida entre as duas, é **estrutural** (princípio 1 do `/keelson:implement`: qualidade acima de velocidade).

Achado de segurança crítica/alta cuja correção é estrutural **não** é adiado em silêncio: entra como bloqueio explícito no output, com a demanda proposta na Etapa 8.

4. Imprimir o report consolidado (formato da Etapa 9), inclusive quando nada foi encontrado.

## Etapa 5: um OK, e depois não pare mais

Sem `--fix`: apresentar o report e pedir **um** OK para a leva de correções da classe "corrigível agora" (liste-as). Dado o OK — ou com `--fix` desde a largada — vá até o fim (Etapas 6 → 7 → 8 → 9) sem novas paradas: fôlego não é gatilho de parada (decisões 4.23/4.24).

Nada corrigível → encerre na Etapa 9; achados estruturais seguem para a Etapa 8 de qualquer forma.

## Etapa 6: correção via `developer`

Despache o `developer` em **modo revisão avulsa** (definido no próprio agente: sem
TASK em disco, sem commit) com um briefing efêmero:

- Cada achado é um critério de pronto: *o achado deixa de existir e nenhum teste quebra*.
- Passe: `arquivo:linha`, o problema, a correção proposta pelo revisor, os comandos `quality.*`, o perfil ativo e a seção a ler.
- Reforce o limite do escopo: só os arquivos dos achados; não refatorar além do apontado; mudar comportamento observável é achado **estrutural**, não correção.
- Achado de teste faltando: o teste é **falsificável** (`guidelines/core/TESTING.md`).

## Etapa 7: re-revisão (gate, não formalidade)

1. Despache o **`code-reviewer` de novo** sobre o diff da correção. Report anterior não vale como aprovação do código novo — o que foi corrigido é código não revisado.
2. Houve achado de segurança corrigido → o **`security-engineer`** também roda de novo.
3. Correção com **efeito observável** → **`qa`** (gate 9): prova o comportamento rodando os testes e exercitando a app quando o ambiente permite. Ambiente sem tela com `gates.screenVerify` ativo → o verifier reporta `PARCIAL` com `handoff_seed` e evidência de sondagem (`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/handoff-protocol.md`); aqui isso vira **pendência declarada no output**, não handoff em disco (revisão avulsa não tem PLAN para ancorar o doc).
4. REPROVADO: 1 retry com instruções precisas, depois escala ao humano com o diagnóstico.

## Etapa 8: achados estruturais viram demanda

Para cada estrutural, proponha o roteamento — **sem executar** (a régua é a do `/keelson:triage`):

- Slug conhecido e o achado viola um AC de SPEC existente → TASK de bugfix pré-preenchida, apontando o AC violado.
- Achado de refactor amplo ou capacidade nova → `/keelson:triage "<achado>"` com a descrição pronta.
- Slug não inferível → registre o achado no output como **dívida sem dono**, com o caminho e o motivo; não invente slug.

## Etapa 9: output final

```markdown
# Code review: <alvo resolvido> (HEAD <sha>)

## Escopo
- Diff: <comando usado> — N arquivo(s), ~M linha(s) adicionada(s)
- Slug inferido: <slug ou "não inferível">
- Revisores: code-reviewer <id> | security-engineer <id ou n/a> | qa <id ou n/a>

## Gates
| Gate | Resultado | Nota |
|---|---|---|
| 1 Cobertura de prova | OK \| FAIL | degradado: sem AC — lógica nova exige teste |
| 2 Testes | OK \| FAIL | comando/filtro executado |
| 3 Lint | OK \| FAIL | escopado aos arquivos do diff |
| 4 Escopo | OK \| FAIL | degradado: coerência do diff |
| 5 Decisões | OK \| FAIL \| n/a | n/a = slug não inferível |
| 6 Charter + perfil | OK \| FAIL | |
| 7 Review qualitativo | OK \| FAIL | |
| 8 Segurança | aprovado \| reprovado \| n/a | n/a = área não sensível ou --no-security |
| 9 Comportamento | verificado \| pendente \| n/a | só quando houve correção com efeito observável |

## Corrigido nesta rodada
- `arquivo:linha` — <achado> → <correção> (re-revisado por <id>)
- Arquivos alterados: <lista> — **não commitados**: o commit é seu

## Demandas propostas (estrutural)
- <achado> → <comando ou TASK sugerida> (aguardando sua confirmação)

## Pendências declaradas
- <gate degradado, n/a, verificação de tela sem ambiente, dívida sem dono>
```

Se algum report trouxe `licao_candidata` não-nula, roteie pelo campo `alvo` — `projeto` → `guidelines/project/lessons.md` (formato canônico e dedup: dono em `${CLAUDE_PLUGIN_ROOT}/guidelines/core/WORKFLOW.md`); `processo` → `agile-coach` — e mencione no output. Mecânica idêntica à closure do `/keelson:implement` (etapa 3.4.2, item 5).

## Limites

Não commita, não faz merge, não promove Status, não cria SPEC/PLAN, não corrige achado estrutural no ato, não gera artefato durável em `{docsRoot}` (revisão avulsa não é etapa do ciclo — o rastro é o commit do humano) e não revisa nem implementa com as próprias mãos.
