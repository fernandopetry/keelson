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
- **Charter é versionado à parte** (`guidelines/_meta/QUALITY-CHARTER.md`): só muda quando
  os artigos mudam; cada perfil referencia a versão no frontmatter `charter:`.

## Ao mudar comando ou doutrina

- Comando novo/renomeado → sincronizar **3 lugares**: `commands/*.md` · tabela *Commands*
  do `README.md` · §3.x do `docs/_meta/method-guide.md`. Comando humano-only
  (`disable-model-invocation`) → também a nota do `templates/CLAUDE.keelson-block.md`.
- **Um dono por regra**: o core (`guidelines/core/`) diz *o quê* (agnóstico); o perfil diz
  *como* na linguagem. Não duplicar regra entre eles. Blocos compartilhados dos comandos
  têm dono único em `docs/_meta/conventions/` — `sdd-conventions.md` (convenções comuns,
  ex-§3.0), `index-contract.md` (artefatos/IDs + contrato/template/receita do INDEX, ex-§6)
  e `handoff-protocol.md` (handoff de verificação de tela, ex-§8); o `method-guide.md`
  segue guia humano, com os headings §3.0/§6/§8 preservados como ponteiros. A moldura dos
  validators vive em `skills/_shared/validator-protocol.md`; o `security-reviewer` **lê** o
  checklist de `guidelines/core/SECURITY.md` em runtime, não o replica (decisão 4.20) —
  mudou a regra, mude no dono, nunca copie no consumidor.
- Perfil com `reviewed: true` (ex.: `backend/php.md`) é revisado por humano: edição nele
  deve ser sinalizada na entrega para re-olhada humana.

## Registro e governança

- Decisão de processo/governança → entrada numerada em `docs/_meta/decisions.md` (§4.x,
  formato Problema/Decisão/Aplicação). Lição de processo → `learning-log.md` via
  `process-tuner`.
- Hooks são bash 3.2-compatível com **fallback gracioso** (sem `jq`/ficha → `exit 0`,
  nunca travar o fluxo) e anti-renudge por fingerprint. Validar com `bash -n` + teste
  sintético (repo temporário no scratchpad).

## Convenções

- Commits: conventional commits **em inglês** (`feat(scope): …`), referenciando a
  decisão quando houver (ex.: `(4.16)`).
- Docs e doutrina em **português**; `README.md` em **inglês**.
