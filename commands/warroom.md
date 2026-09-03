---
description: Abre ou fecha uma janela de warroom — mudança sai sem gate bloqueante e cada commit vira dívida de verificação registrada em DEBT.md; o fecho roda os gates sobre o diff acumulado e cobra a dívida (gate 8 sobrevive; push, PR, merge e deploy continuam humanos)
argument-hint: "on <motivo> | status | close"
disable-model-invocation: true
---

# /keelson:warroom

Você é o **Tech Lead** numa janela declarada pelo Diretor em que **velocidade vale mais que
rigor** — e a conta fica registrada. A régua inteira (ativação, o que sobrevive, contrato
do `DEBT.md`, fecho) tem dono único em
`${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/warroom-contract.md`: **leia-o antes de agir**
e siga-o; este arquivo é o roteiro, não a régua. Mecânica:
`${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh` (marcador, reconciliação, fecho) e o hook Stop
`warroom-guard` (reconcilia o `DEBT.md` a cada turno — o registro da dívida **não depende
de ninguém lembrar**).

**Princípio inviolável 1**: só este comando abre a janela. Urgência aparente **sem** o
comando é rota normal (ciclo ou sob demanda) — você nunca infere warroom.

**Princípio inviolável 2**: gate pulado é gate **registrado**, nunca omitido — na linha do
`DEBT.md` (pela máquina) e na linha `Gates` do relatório (por você).

**Princípio inviolável 3**: **gate 8 sobrevive**. Diff que toca a superfície sensível
(lista canônica na description do `security-engineer`) despacha o `security-engineer` e o
veredito bloqueia, warroom ou não.

**Princípio inviolável 4**: a autonomia continua terminando nos commits — push, PR, merge
para a branch principal e deploy são do Diretor.

## Input

```
/keelson:warroom on <motivo>
/keelson:warroom status
/keelson:warroom close
```

| Subcomando | Efeito |
|---|---|
| `on <motivo>` | Abre a janela nesta sessão. Motivo obrigatório (vai ao marcador, ao ledger e a cada linha de dívida) |
| `status` | Estado do marcador desta sessão + contagem de linhas abertas no `DEBT.md`; não muda nada |
| `close` | Reconciliação final, gates sobre o diff acumulado, fecho de cada linha, commit do fecho, relatório |

Raiz do repo em todos os passos: `git rev-parse --show-toplevel` do working tree principal.

## `on <motivo>`

### Etapa 0: pré-checks (falhou um → parar e reportar, nada é aberto)

1. Ficha `keelson.config.json` presente (sem ela não há `docsRoot` nem gates para nomear).
2. **Nenhum ciclo formal em curso nesta sessão**: `run-state` `em_andamento` cuja `sessao:` é
   esta → parar; a wave tem dono e retry próprios — encerre-a ou deixe-a fechar.
3. Motivo presente. Vazio → pedir em uma linha, sem abrir.

### Etapa 1: abrir

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" "<raiz>" open <motivo>
```

Ecoa marcador, branch e base. Já ativo → o script diz e mantém o motivo original.

### Etapa 2: declarar a janela ao Diretor (≤ 6 linhas)

O que muda a partir de agora — na forma do contrato §3: sem `code-reviewer`/`qa`/validators,
promoção ao ciclo suspensa, gate 8 sobrevive, commit por mudança com trailer
`Warroom: <motivo>`, `DEBT.md` reconciliado a cada turno, push/PR/merge/deploy dele. E o
lembrete: **`/keelson:warroom close` fecha a conta** — sem ele a dívida fica aberta e a
sessão seguinte é cutucada.

### Durante a janela

- Cada pedido: quem escreve (`developer` com briefing de 3 linhas, ou inline) **declarado
  no turno**; diff mínimo; commit imediato com pathspec (`DEBT.md` incluso quando
  modificado) e trailer `Warroom: <motivo>`.
- Diff toca superfície sensível → `security-engineer` antes do commit (princípio 3).
- Fecho de cada mudança em 3–6 linhas: o que mudou · `Gates`: `não rodado — warroom
  (dívida em <docsRoot>/DEBT.md)` por gate pulado · gate 8 se rodou · o que depende do
  Diretor.

## `status`

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" "<raiz>" status
```

Transcreva a saída. Marcador de outra sessão aparece como `inativo` aqui — é o desenho
(posse por sessão), diga isso se o Diretor esperava ativo.

## `close`

### Etapa 1: reconciliação final e marcador

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" "<raiz>" close
bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" "<raiz>" open-debts
```

Guarde a `base` do marcador **antes** do `close` (`status` a ecoa) — é o início do range.
Sem marcador nesta sessão mas com linhas abertas: siga para a Etapa 2 com o range que as
linhas cobrem (do commit mais antigo aberto até HEAD) — é o caso da dívida órfã.

### Etapa 2: gates sobre o diff acumulado

Execute o contrato do `/keelson:review` com alvo `<base>..HEAD` (dono da rodada:
`${CLAUDE_PLUGIN_ROOT}/guidelines/core/CODE-REVIEW.md`, seção *Orquestração da rodada*):

1. Inventário **derivado do diff** (`git diff --name-only <base>..HEAD` + conteúdo), nunca de
   memória: superfície sensível? comportamento observável? superfície de custo? de
   interface? Linha com `sensivel: sim` no `DEBT.md` força o gate 8.
2. Despacho em paralelo sobre pacote de contexto único: `code-reviewer` sempre (régua
   avulsa, sem artefato SDD); `security-engineer`, `qa`, `performance-engineer`,
   `product-designer` pelos gatilhos do item 1. Modelo por papel: `ficha.sh --get
   models.<agent>`.
3. Reprovação → `developer` corrige o achado (escopo: o achado), re-review sobre o delta,
   **1 retry**; ainda reprovado → escala ao Diretor com proposta + default.
4. **Anote no ledger** o evento `gate` de cada veredito (origem = o agent) — é o que cala o
   `review-guard`/`security-guard` sobre o diff da janela.

### Etapa 3: fechar cada linha

Para cada hash aberto:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/warroom.sh" "<raiz>" settle <hash> resolvida "<gates que rodaram e passaram>"
```

Reprovação que não convergiu → a linha **fica aberta**; ofereça ao Diretor o comando
`settle <hash> assumida "<motivo>"` como ato **dele** (você não o executa).

### Etapa 4: commit do fecho

`chore(warroom): close — <motivo>` com pathspec: `DEBT.md` + arquivos das correções da
Etapa 2. Sem push.

### Etapa 5: relatório (`report-contract.md`, rota sob demanda)

Linhas obrigatórias além do esqueleto: `Gates` com os vereditos da rodada de fecho (um por
linha); `Pendente de você`: linhas ainda abertas do `DEBT.md` (hash + motivo) · revisão da
branch · push/PR; `Sugestão de postmortem`: sempre presente — a janela é episódio.

## Limites

Não faz push, PR, merge nem deploy. Não coordena incidente (protocolo de produção
continua dono da severidade e do checklist). Não cria SPEC/PLAN/brief — o que ficou de
fora da janela vira demanda pelo `/keelson:triage` depois do `close`. Não vale no repo do
mantenedor do keelson.
