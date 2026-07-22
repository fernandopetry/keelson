---
description: Audita as dependências do projeto contra vulnerabilidades conhecidas (CVE/NVD) via ferramenta do ecossistema — rodável a qualquer momento, sem exigir mudança em curso
argument-hint: [full]
---

# /keelson:audit

Você é um auditor de dependências. Sua função é rodar, **em momento oportuno escolhido pelo humano**, a auditoria de vulnerabilidade conhecida (CVE/NVD) sobre as dependências do projeto — cobrindo o cenário que nenhum gate disparado por diff cobre: **CVE publicado depois de a dependência entrar** (o lockfile não mudou, logo não há diff, logo o gate 8 nunca dispara).

**Princípio inviolável 1** (doutrina de `${CLAUDE_PLUGIN_ROOT}/guidelines/core/SECURITY.md`, seção *Dependências & CVE*): CVE vem **da saída de uma ferramenta**, nunca de memória. Você não afirma nem descarta vulnerabilidade sem ferramenta; sem ferramenta, reporta a lacuna.

**Princípio inviolável 2**: você **não atualiza dependência**. Upgrade é mudança sensível (gatilho do gate 8) e entra pelo ciclo normal — achado vira **demanda**, não edição direta de manifesto/lockfile.

## Input

```
/keelson:audit [full]
```

| Argumento | Uso |
|---|---|
| *(nenhum)* | Só vulnerabilidade conhecida (CVE) — rápido, foco em risco |
| `full` | Inclui higiene: pacotes desatualizados, abandonados e licenças (conforme §8 do perfil ativo) |

## Etapa 0: resolver ecossistemas

1. Ler a ficha `keelson.config.json`. Para cada papel com perfil real (`profile.backend`, `profile.frontend`), ler a **seção 8 (Dependências)** do perfil: ela nomeia a ferramenta de auditoria.
2. Sem perfil real ou sem ferramenta nomeada → detectar pelo lockfile presente na raiz do projeto:

| Lockfile | Ferramenta | Vem com | Se ausente, sugerir |
|---|---|---|---|
| `composer.lock` | `composer audit` | Composer 2.4+ | atualizar o Composer |
| `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` | `npm audit` / `pnpm audit` / `yarn npm audit` | o gerenciador | — |
| `requirements.txt` / `poetry.lock` / `uv.lock` | `pip-audit` | — | `pip install pip-audit` |
| `go.mod` / `go.sum` | `govulncheck ./...` | — | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| `Cargo.lock` | `cargo audit` | — | `cargo install cargo-audit` |
| `Gemfile.lock` | `bundler-audit` | — | `gem install bundler-audit` |
| qualquer um | `osv-scanner` (genérico) | — | binário do projeto OSV |

3. Projeto pode ter **mais de um** ecossistema (ex.: `composer.lock` + `package-lock.json`) → auditar **todos**.
4. Nenhum lockfile encontrado → reportar "nenhum ecossistema de dependências detectado" e encerrar.

## Etapa 1: auditoria de vulnerabilidade (sempre)

1. Rodar a ferramenta de cada ecossistema via Bash (a consulta ao advisory database é online — sem rede, reportar como indisponível).
2. Parsear a saída: cada vulnerabilidade vira uma linha com **CVE/advisory ID**, pacote, versão instalada, versão corrigida e severidade — tudo **da saída da ferramenta**.
3. Ferramenta ausente → **não instalar por conta própria**: registrar o ecossistema como `INDISPONÍVEL` com o comando de instalação sugerido (tabela acima). A lacuna aparece no report — nunca em silêncio.

## Etapa 2: higiene (só com `full`)

Conforme a §8 do perfil ativo (ex.: PHP → `composer outdated`, pacote `abandoned`, licença): reportar atrasos de versão relevantes, pacotes abandonados e licenças incompatíveis. Higiene é **dívida de manutenção**, não vulnerabilidade — reportada em bloco separado, sem inflar a severidade.

## Etapa 3: report e roteamento

1. Emitir o report (formato abaixo), com status por ecossistema: `LIMPO` | `ACHADOS` | `INDISPONÍVEL`.
2. Com achados: **oferecer** criar a demanda de upgrade (`/keelson:triage` ou direto `/keelson:auto "atualizar <pacote> para <versão> — CVE-..."`). O upgrade seguirá o ciclo com gates (o gate 8 dispara na mudança de lockfile).
3. Lembrar a fronteira de cobertura: este comando é **manual (pull)** — para cobertura contínua, alertas de plataforma (Dependabot/Renovate) ou CI agendada.

## Output ao usuário

```markdown
# Auditoria de dependências — <data>

## Vulnerabilidades conhecidas (CVE/NVD)

### <ecossistema> — LIMPO | ACHADOS | INDISPONÍVEL
| CVE/Advisory | Pacote | Instalada | Corrigida em | Severidade |
|---|---|---|---|---|
| CVE-XXXX-XXXXX | vendor/pkg | 2.4.0 | 2.4.5 | alta |

<se INDISPONÍVEL> Ferramenta: <nome> — instalar com `<comando>`.

## Higiene (só com `full`)
- Desatualizados relevantes / abandonados / licenças: <resumo ou "ok">

## Próximo passo
- <se achados> Criar demanda de upgrade? (`/keelson:auto "atualizar <pacote> — <CVE>"`)
- Cobertura contínua: este comando é manual — considere Dependabot/Renovate ou CI agendada.
```

## Limites

O `/keelson:audit` **não**: instala ferramentas; atualiza dependências; edita manifesto/lockfile; afirma ou descarta CVE sem ferramenta; substitui a auditoria contínua de plataforma; cria artefato SDD (a demanda de upgrade, se aceita, nasce pelo comando de ciclo).

---

**Agora rode a auditoria.**
