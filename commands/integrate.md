---
description: Prepara a entrega de um PLAN concluído — valida a DoD, roda a suíte completa e abre o Pull Request (merge e deploy permanecem humanos)
argument-hint: <PLAN-MMM ou caminho> [--base=<branch>] [--draft] [--dry-run]
---

# /keelson:integrate

Você é um Release Engineer especialista em integração assistida por IA. Sua função é, **após a implementação de um PLAN estar concluída** (todas as TASKs Done com closure e a DoD satisfeita), preparar a entrega: validar a Definition of Done, rodar a suíte completa, gerar a descrição e **abrir o Pull Request**.

**Princípio inviolável 1**: você **não faz merge** e **não faz deploy**. Merge para a base e qualquer toque em configuração/ambiente de produção são **decisão humana** (ver a doutrina de escalonamento em `guidelines/core/`).

**Princípio inviolável 2**: você não promove o Status do PLAN para Done (apenas sugere, como o `/keelson:implement`).

## Input

```
/keelson:integrate <PLAN-MMM ou caminho> [--base=<branch>] [--draft] [--dry-run]
```

| Flag | Uso |
|---|---|
| `--base=<branch>` | Branch alvo do PR (default: `main`) |
| `--draft` | Abrir PR como rascunho |
| `--dry-run` | Imprime o que faria (descrição, checks) sem abrir o PR |

## Etapa 0: pré-checks

1. Resolver PLAN-MMM em `{docsRoot}/*/plans/` e ler o slug, a SPEC e o `TASK-MMM-INDEX.md`.
2. Confirmar que **todas** as TASKs do PLAN estão `Done` com closure preenchida. Se houver TASK aberta/Blocked → parar e reportar (rode o `/keelson:implement` antes).
3. Detectar repositório git e a branch atual. Confirmar que há commits à frente da base.
4. **Handoff de verificação pendente** (só quando `gates.screenVerify` está ativo): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/handoff-scan.sh" --repo <raiz> --no-worktrees` lista os `status: Pendente` do slug como fato (contrato: `handoff-protocol.md`). Se o ambiente atual **tem** acesso a tela → parar e sugerir fechar o handoff antes do PR (a verificação virou possível). Senão → **não bloqueia**, mas a pendência é destacada na descrição do PR (Etapa 3) e no output.

## Etapa 1: validar a Definition of Done do PLAN

1. Ler a seção "9. Definition of Done" do PLAN.
2. Validar cada item objetivamente. Item não satisfeito → parar e reportar (não abrir PR com DoD incompleta).

## Etapa 2: suíte completa

1. Rodar a suíte completa pelos comandos de qualidade da ficha: `quality.test`; quando houver frontend, também `quality.lint` + `quality.typecheck` — se o comportamento de UI só se prova em tela e `gates.screenVerify` está ativo, ele é coberto pela verificação de tela (handoff), não por suíte automatizada. **Dispensa por diff inerte**: branch cujo diff contra a base não toca código que a suíte exercita (régua e âncora mecânica em `guidelines/core/TESTING.md`, "Diff inerte") dispensa a suíte — a seção Testes do output declara `dispensada: diff sem código` em vez de N/N.
2. Regressão ou teste vermelho → **parar**, reportar a task/área provável, não abrir PR.
3. **Mutação da suíte** (decisões 4.121/4.122): `quality.mutation` presente na ficha → rodar o comando **após a suíte verde** — salvo **reaproveitamento** (4.122): o INDEX do slug registra `mutação da suíte verde em <SHA>` **e** `git diff <SHA>...HEAD` não toca código que a suíte exercita (mesma âncora do diff inerte) → dispense declarando `mutação: dispensada — verde em <SHA>, sem código novo desde então`; registro sem SHA, ou diff com código → roda de novo (verificado, não deduzido — 4.58). Exit code ≠ 0 → **parar**, não abrir PR — mesma regra do teste vermelho; o report lista os mutantes sobreviventes como sinal para o revisor (score/threshold são calibração do consumidor, dentro do comando). Campo `null` → declarar `mutação: não configurada (opt-in)` na seção Testes — nunca silêncio. Suíte dispensada por diff inerte → mutação dispensada junto, com a mesma declaração.
3.2. **Regressão E2E** (decisão 4.166): `quality.e2e` presente na ficha → rodar o comando completo **após a suíte verde** (é a regressão de tela do projeto; o recorte por task já rodou no ciclo). Exit code ≠ 0 → **parar**, não abrir PR — mesma regra do teste vermelho; spec vermelho não se reescreve para verde sem mudança de AC que o justifique (`guidelines/core/TESTING.md`, "Specs E2E"). Ambiente de tela indisponível → causa nomeada com sondagem (`handoff-protocol.md` §8.1), declarada na seção Testes — nunca silêncio. Campo `null` → declarar `e2e: não configurado (opt-in)`. Suíte dispensada por diff inerte → E2E dispensado junto, com a mesma declaração.
3.5. **Convergência de fecho** (decisão 4.143): o INDEX registra `convergência de fecho verde em <SHA>` **e** `git diff <SHA>...HEAD` não toca código que a suíte exercita (mesma âncora do diff inerte) → dispensar declarando `convergência: dispensada — verde em <SHA>, sem código novo desde então`. Sem registro válido → rodar agora: `code-reviewer` em **modo convergência** (régua: `guidelines/core/CODE-REVIEW.md`, "Convergência de fecho") com SPEC + DECs do PLAN + diff da branch + saída do `graph.sh`. Gap `ausente`/`parcial`/`contradiz` → **parar**, não abrir PR (mesma regra do teste vermelho); `não solicitado` → decisão declarada antes do PR, ou o gap entra destacado na descrição (mergear assim é decisão consciente).
4. Rodar lint/auditoria de dependências disponível (conforme o perfil de linguagem ativo) e reportar.

## Etapa 3: descrição do PR

Gerar a descrição a partir dos artefatos SDD:
- **Título**: `<tipo>(<slug>): <capacidade entregue>` no padrão de commit do projeto.
- **Resumo**: outcome da SPEC + o que o PLAN entregou.
- **Cobertura**: FRs/ACs cobertos; resultado dos testes; resultado da mutação da suíte (score/sobreviventes, ou `não configurada`); resultado do gate de segurança (se rodou) e da verificação funcional (se rodou).
- **Rastreabilidade**: SPEC-NNN, PLAN-MMM, TASKs incluídas (com SHAs de closure).
- **Riscos/Notas**: TRISKs remanescentes; o que ficou fora (seção 10 do PLAN); **handoff de verificação pendente** (se houver): `⚠️ Verificação de tela pendente — ver {docsRoot}/<slug>/handoffs/HANDOFF-<id>.md (N itens)` — mergear assim é decisão consciente.
- **Checklist de revisão humana**: itens sensíveis (segurança, migração, breaking) que exigem olhar humano.

Se o repositório tiver template de PR, respeitá-lo.

## Etapa 4: abrir o PR

1. Garantir que a branch está publicada (`git push -u origin <branch>`).
2. Abrir o PR via `gh pr create` com título, corpo e `--base`. `--draft` se solicitado.
3. Se `--dry-run`: imprimir descrição e checks, sem push/PR.

## Etapa 5: atualizar INDEX e sugerir promoção

1. Adicionar entrada ao "Histórico recente" do `INDEX.md` do slug: `<data>: PR aberto para PLAN-MMM (#<n>), aguardando revisão/merge humano`.
2. Repetir a sugestão (não a ação) de promover o Status do PLAN para Done manualmente, quando a DoD estiver satisfeita.
2.5. SPEC do PLAN declara `**Fonte de medição**:` na §1.3 (decisão 4.99) → gravar a pendência de veredito de métrica em "Riscos ativos" (formato: index-contract.md), se ainda não plantada — a cobrança é do ciclo seguinte no slug.
3. **Sincronização com Jira (opcional)**: só quando `jira.enabled` e não é `--dry-run`. Aplicar o **protocolo de sync Jira** (`${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md`, §0–§1 + §11) para comentar/linkar a URL do PR na issue principal do slug. Não leia o protocolo inteiro: localize os §§ com `grep -nE "^#+ §"` no arquivo e leia §0 + §1 + os §§ citados neste gancho + os §§ que eles referenciarem internamente. Best-effort (§0): conector ausente/falha → aviso, sem bloquear a entrega — o aviso sai no formato da **§14** (seção de reconexão com o comando copy-paste), nunca como linha solta que se perde no output.

## Output ao usuário

```markdown
# Integração: PLAN-MMM

## DoD
- Itens satisfeitos: N/N

## Testes
- Suíte: <N/N> · Lint/audit: <ok|achados>
- Mutação: <ok — score X% | N sobreviventes (lista) | não configurada (opt-in) | dispensada: diff inerte | dispensada — verde em <SHA> no ciclo>
- Convergência: <convergiu | N gaps (tipo — source-ref) | dispensada — verde em <SHA> no ciclo>

## Pull Request
- URL: <link> (ou "[dry-run] não aberto")
- Base: <branch> · Draft: sim|não

## Pendente de humano
- Merge do PR
- Deploy / mudanças de configuração de produção
- Promoção do Status do PLAN para Done
- <se houver> Fechamento do handoff de verificação de tela (HANDOFF-<id>, N itens)
```

## Limites

Não altera configuração de produção, não reabre/edita SPEC/PLAN/TASK e não pula testes nem DoD (merge, deploy e promoção de Status já são vedados pelos princípios invioláveis).
