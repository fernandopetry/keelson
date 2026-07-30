# keelson — repo de desenvolvimento do plugin

Este repositório **é** o plugin (a raiz é o pacote). Não é um projeto consumidor — aqui se desenvolve
o keelson; a doutrina que os consumidores recebem vive em `guidelines/` e o bloco
injetado neles em `templates/CLAUDE.keelson-block.md`.

## Versionamento

- **Versão do plugin** vive em **3 lugares, sempre sincronizados**:
  `.claude-plugin/plugin.json` · `.claude-plugin/marketplace.json` (`metadata.version`) ·
  seção *Status* do `README.md`.
- Regra (0.x): capacidade nova ou quebra (comando novo, rename, doutrina nova) → **minor**;
  correção/ajuste fino → **patch**. Bump uma vez por leva de release, não por commit.
- **Bump sem entrada no `CHANGELOG.md` é release incompleto** (decisão 4.48): a mesma leva
  que mexe nos 3 lugares escreve a entrada. Formato: `## [X.Y.Z] — AAAA-MM-DD`, linha de
  âncora (`Decisão 4.x · <hash do commit de bump>`; `Charter A.B.C` quando ele mudou) e
  bullets sob `Added` / `Changed` / `Fixed` / `Removed`, em **inglês** (é a face pública do
  pacote, como o `README.md`). Escreva pelo efeito no consumidor — o *porquê* fica na
  decisão, a uma referência de distância. O `Status` do README traz só a manchete atual e
  aponta para o CHANGELOG; não volta a acumular prosa histórica.
- **Charter é versionado à parte** (`guidelines/_meta/QUALITY-CHARTER.md`): só muda quando
  os artigos mudam; cada perfil referencia a versão no frontmatter `charter:`.
- **Sessões paralelas colidem em §4.x e versão** (caso real: duas "4.60" no mesmo dia —
  decisão 4.63): antes de numerar decisão ou bumpar, `git fetch` e confira o topo da main.
  O hook `scripts/git-hooks/pre-commit` bloqueia commit na `main` atrás do `origin/main` —
  ative uma vez por clone: `git config core.hooksPath scripts/git-hooks`.

## Ao mudar comando ou doutrina

- Comando novo/renomeado → sincronizar **3 lugares**: `commands/*.md` · tabela *Commands*
  do `README.md` · §3.x do `docs/_meta/method-guide.md`. Comando humano-only
  (`disable-model-invocation`) → também a nota do `templates/CLAUDE.keelson-block.md`.
- Agent novo/renomeado → sincronizar: `agents/*.md` (arquivo + `name:` + `# Subagent:`) ·
  tabela §5 do `method-guide.md` · comentário de `agents/` no `README.md` · §2/§3 do
  `decisions.md` (convenção de nomes) — e a description declara **todos** os invocadores.
- **Um dono por regra**: o core (`guidelines/core/`) diz *o quê* (agnóstico); o perfil diz
  *como* na linguagem. Não duplicar regra entre eles. Blocos compartilhados dos comandos
  têm dono único em `docs/_meta/conventions/` — `sdd-conventions.md` (convenções comuns,
  ex-§3.0), `index-contract.md` (artefatos/IDs + contrato/template/receita do INDEX, ex-§6)
  e `handoff-protocol.md` (handoff de verificação de tela, ex-§8); o `method-guide.md`
  segue guia humano, com os headings §3.0/§6/§8 preservados como ponteiros. A moldura dos
  validators vive em `skills/_shared/validator-protocol.md`; a **régua dos gates 1–7**
  (o que cada gate exige, degradação sem artefato SDD, calibração de severidade) tem dono
  único em `guidelines/core/CODE-REVIEW.md`, executada sempre pelo `code-reviewer` —
  no ciclo (`/keelson:implement`) e em diff avulso (`/keelson:review`, decisão 4.36); o `security-engineer` **lê** o
  checklist de `guidelines/core/SECURITY.md` em runtime, não o replica (decisão 4.20) —
  mudou a regra, mude no dono, nunca copie no consumidor.
- Perfil com `reviewed: true` (ex.: `backend/php.md`) é revisado por humano: edição nele
  deve ser sinalizada na entrega para re-olhada humana.

## Modelo de time e contrato do Diretor (decisões 4.37–4.41 — dono do detalhe: `docs/_meta/decisions.md`)

- O keelson simula um **time real** — desde a 4.40, os IDs dos agents **são** os nomes
  dos papéis. Elenco: **Diretor** = humano · **Tech Lead** = main session · agents
  `po` (dono da demanda) · `pm` (decompõe épico — nunca abaixo do PO; 4.39) ·
  `developer` · `code-reviewer` · `qa` · `security-engineer` · `product-analyst`
  (sob o PO) · `agile-coach` · `staff-engineer`. Validators ficam **fora da metáfora**
  (ferramentas do time, não pessoas). Histórico (decisions.md, learning-log.md) e
  `generated-by:` de perfis gerados mantêm os IDs antigos — de-para na 4.40.
- **Contrato Diretor–PO**: o Diretor emite intenção (**brief**, artefato-âncora), não
  aprova artefatos de rotina. O PO valida tudo **contra o brief** (nunca contra a própria
  opinião), devolve a interpretação em ~5 linhas e segue **sem esperar** (janela de veto);
  escala por exceção (ambiguidade que muda o resultado · expansão/conflito de escopo ·
  ação irreversível/externa · conflito com diretriz anterior), sempre com proposta +
  default; registra **decisões tomadas em nome do Diretor**; entrega **relatório de
  aceitação** (alinhamento ao brief ≠ QA, que prova que funciona).
- **A autonomia termina nos commits**: PR, merge e deploy são atos do Diretor (pode haver
  outras sessões na mesma base).
- **Sinais laterais com contrato** (gatilho + rota + registro): furo no plano
  (Developer → Tech Lead; contornar em silêncio é violação de gate) · cenário ambíguo
  pré-código (QA → PO) · achado fora de escopo (Reviewer/QA → Tech Lead) · escalação e
  aceitação (PO → Diretor). Boletim entre waves narrado em linguagem de time, fechando
  com o estado de pendência do Diretor.

## Registro e governança

- Decisão de processo/governança → entrada numerada em `docs/_meta/decisions.md` (§4.x,
  formato Problema/Decisão/Aplicação). Lição de processo → `learning-log.md` via
  `agile-coach`.
- Hooks são bash 3.2-compatível com **fallback gracioso** (sem `jq`/ficha → `exit 0`,
  nunca travar o fluxo) e anti-renudge por fingerprint. Validar com `bash -n` + teste
  sintético (repo temporário no scratchpad).

## Convenções

- Commits: conventional commits **em inglês** (`feat(scope): …`), referenciando a
  decisão quando houver (ex.: `(4.16)`).
- Docs e doutrina em **português**; `README.md` em **inglês**.
