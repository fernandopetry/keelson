---
name: harness-audit
description: "Ferramenta do MANTENEDOR (fora do pacote — decisão 4.182): auditoria recorrente da doutrina do keelson (CLAUDE.md, commands/, agents/, skills/, guidelines/, conventions/, templates/) em duas camadas — ponteiros mecânicos via scripts/check-refs.sh e juízes duplos cegos de poda com a régua 4.160 e plants de controle (4.186). Report-only: aplicar corte é leva própria. Ativar quando o Diretor pedir auditoria do harness, poda/simplificação da doutrina, ou revisão de redundância/utilidade das instruções."
---

# Skill: harness-audit

Auditoria interna do harness do keelson. Esta skill é um **protocolo de rodada** — a régua
de poda tem dono (`CLAUDE.md` §Registro e governança, bullet 4.160) e o fato mecânico tem
motor (`scripts/check-refs.sh`); ela só impõe a sequência e as cegueiras. **Report-only**:
a rodada termina no relatório; aplicar corte é leva própria com análise de impacto (4.181).

## Rodada

1. **Fato mecânico primeiro** (4.82). Rode `bash scripts/check-refs.sh` e cite a saída como
   fato — ponteiro quebrado é defeito objetivo, não vai para os juízes.

2. **Baralho de superfícies.** Enumere por `git ls-files` (nunca `find .` — worktrees sob
   `.claude/` são cópia integral do repo e contaminariam o juízo de redundância):
   `CLAUDE.md` · `commands/*.md` · `agents/*.md` · `skills/**/*.md` · `guidelines/**/*.md` ·
   `docs/_meta/conventions/*.md` · `templates/*.md`. Copie as superfícies para
   `.harness-eval/runs/<AAAA-MM-DD>-interno/deck/` e anote quais perfis têm
   `reviewed: true` (poda aplicada neles exigirá re-olhada humana).

3. **Plants só na cópia** (4.186). Plante no deck 2 controles SLIM (teoria genérica sem
   delta do repo) e 1 controle KEEP (política com consequência concreta, nunca cópia
   verbatim de superfície existente); gabarito em `plants-key.json` no run dir.
   **Invariante: a árvore versionada nunca recebe plant** — o fecho da rodada confirma
   `git status` limpo e o relatório o declara.

4. **Juízes duplos, segundo cego.** Dois subagents pontuam cada superfície do deck; o
   Judge2 não lê o score do Judge1 nem o `plants-key.json`. Régua primária: os três testes
   da 4.160 (**no-op** · **sedimento** · **leading word** — leia no dono, não reproduza de
   memória). Lentes complementares: redundância (custo de redescoberta 0–3; custo ≥ 2
   nunca é redundante) e utilidade (deletar muda o comportamento?). Dono único conta:
   frase que duplica regra de outro dono é achado mesmo sendo útil. Ambos registram
   `model: <id>` — utilidade é sensível a modelo.

5. **Merge com gates.** Veredito por superfície: `KEEP` · `MIXED` (com KEEP/CUT nomeados e
   acionáveis por seção) · `SLIM` · `HOLD`. Desacordo ou incerteza → sempre `HOLD`. Juiz
   que errar mais de 1 família de plant invalida a banda de corte da rodada (vira tudo
   `HOLD`; o relatório diz o porquê). Corte grande sugerido → recomendar re-julgamento em
   segundo modelo antes de qualquer leva de aplicação.

## Entrega

Relatório no run dir + resumo ao Diretor: saída do check-refs · contagens por veredito ·
achados acionáveis (SLIM/MIXED com evidência) · status dos plants · confirmação de árvore
limpa. Aplicação, se o Diretor pedir: leva própria com 4.181 (impact-scout quando tocar a
malha), escalação com proposta + default, e re-olhada humana para perfil `reviewed: true`.
