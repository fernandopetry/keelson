#!/usr/bin/env bash
# run.sh — suíte de regressão do ledger.sh (decisões 4.76/4.151).
#
# Casos inline em diretório temporário, com --ts fixo (determinismo). Regras provadas:
# nome ordenável canônico, cabeçalho, catálogo fechado de tipos, sufixo de colisão,
# list/count, arquivamento preservando pendentes.
#
# Uso: scripts/tests/ledger/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LG="$HERE/../../ledger.sh"

[ -f "$LG" ] || { echo "ERRO: ledger.sh não encontrado em $LG" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$LG" || { echo "FAIL bash -n ledger.sh"; exit 1; }
echo "ok   bash -n ledger.sh"

R="$TMP/repo"; mkdir -p "$R"
LD="$R/thoughts/local/session-ledger"
TS1="2026-08-06T14:23:10-0300"

# append cria nome e cabeçalho canônicos e ecoa o caminho
total=$((total + 1))
f="$(printf 'TASK-003 aprovada no retry (gate 4)\n' | bash "$LG" "$R" append gate code-reviewer meu-slug --ref docs/meu-slug/tasks/TASK-003.md --ts "$TS1" 2>/dev/null)"
if [ "$f" = "$LD/20260806-142310-gate-code-reviewer.md" ]; then ok append-nome; else falha "append-nome: [$f]"; fi
total=$((total + 1))
want="ts: $TS1 · tipo: gate · origem: code-reviewer · slug: meu-slug
TASK-003 aprovada no retry (gate 4)
ref: docs/meu-slug/tasks/TASK-003.md"
if [ "$(cat "$f" 2>/dev/null)" = "$want" ]; then ok append-corpo; else falha "append-corpo: [$(cat "$f" 2>/dev/null)]"; fi

# linha ts: duplicada no stdin (formato pré-4.151) é descartada — o cabeçalho é do
# script (4.156). Repo próprio para não poluir as contagens dos casos seguintes.
total=$((total + 1))
RTS="$TMP/repo-ts"; mkdir -p "$RTS"
fts="$(printf 'ts: 2026-01-01T00:00:00-0300 · tipo: gate · origem: qa · slug: meu-slug\ncorpo real do evento\n' | bash "$LG" "$RTS" append gate qa meu-slug --ts "2026-08-06T14:23:11-0300" 2>/dev/null)"
want="ts: 2026-08-06T14:23:11-0300 · tipo: gate · origem: qa · slug: meu-slug
corpo real do evento"
if [ "$(cat "$fts" 2>/dev/null)" = "$want" ]; then ok append-ts-duplicado-descartado; else falha "append-ts-duplicado-descartado: [$(cat "$fts" 2>/dev/null)]"; fi

# colisão de segundo ganha sufixo
total=$((total + 1))
f2="$(printf 'segundo evento no mesmo segundo\n' | bash "$LG" "$R" append gate code-reviewer meu-slug --ts "$TS1" 2>/dev/null)"
if [ "$f2" = "$LD/20260806-142310-gate-code-reviewer-2.md" ]; then ok append-colisao; else falha "append-colisao: [$f2]"; fi

# tipo fora do catálogo fechado
total=$((total + 1))
printf 'x\n' | bash "$LG" "$R" append relatorio qa meu-slug --ts "$TS1" >/dev/null 2>&1
[ $? -eq 2 ] && ok tipo-invalido-exit-2 || falha tipo-invalido-exit-2

# mais eventos para list/count/archive
printf 'largada da demanda\n' | bash "$LG" "$R" append marco tech-lead meu-slug --ts "2026-08-06T09:00:00-0300" >/dev/null 2>&1
printf 'handoff de tela pendente\n' | bash "$LG" "$R" append pendencia qa meu-slug --ts "2026-08-06T15:00:00-0300" >/dev/null 2>&1

# list ativo, ordenado
total=$((total + 1))
got="$(bash "$LG" "$R" list 2>/dev/null | sed "s|$LD/||")"
want="20260806-090000-marco-tech-lead.md
20260806-142310-gate-code-reviewer-2.md
20260806-142310-gate-code-reviewer.md
20260806-150000-pendencia-qa.md"
if [ "$got" = "$want" ]; then ok list-ordenado; else falha "list-ordenado: [$got]"; fi

# count por tipo
total=$((total + 1))
got="$(bash "$LG" "$R" count 2>/dev/null)"
want="gate	2
marco	1
pendencia	1"
if [ "$got" = "$want" ]; then ok count-por-tipo; else falha "count-por-tipo: [$got]"; fi

# archive preserva o pendente indicado
total=$((total + 1))
msg="$(bash "$LG" "$R" archive --keep 20260806-150000-pendencia-qa.md --ts "2026-08-06T18:00:00-0300" 2>/dev/null)"
case "$msg" in
  "ledger: 3 evento(s) arquivado(s) em $LD/reported-20260806-180000 · 1 pendente(s) preservado(s)") ok archive-keep ;;
  *) falha "archive-keep: [$msg]" ;;
esac
total=$((total + 1))
ativos="$(bash "$LG" "$R" list 2>/dev/null | sed "s|$LD/||")"
if [ "$ativos" = "20260806-150000-pendencia-qa.md" ]; then ok archive-pendente-fica; else falha "archive-pendente-fica: [$ativos]"; fi
total=$((total + 1))
arq="$(bash "$LG" "$R" list --archived 2>/dev/null | grep -c '')"
if [ "$arq" = "3" ]; then ok archive-movidos; else falha "archive-movidos: [$arq]"; fi

# archive sem nada a mover
bash "$LG" "$R" archive --keep 20260806-150000-pendencia-qa.md --ts "2026-08-06T19:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
bash "$LG" "$R" archive --ts "2026-08-06T20:00:00-0300" >/dev/null 2>&1 && \
  msg="$(bash "$LG" "$R" archive --ts "2026-08-06T21:00:00-0300" 2>/dev/null)" && \
  [ "$msg" = "ledger: nada a arquivar." ] && ok archive-vazio || falha "archive-vazio: [$msg]"

# ledger inexistente: list/count vazios, exit 0 (nunca é gate)
R2="$TMP/repo2"; mkdir -p "$R2"
total=$((total + 1))
got="$(bash "$LG" "$R2" list 2>/dev/null)"; st=$?
if [ -z "$got" ] && [ "$st" -eq 0 ]; then ok list-vazio-exit-0; else falha list-vazio-exit-0; fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "ledger: $fail de $total casos falharam"
  exit 1
fi
echo "ledger: $total casos verdes"
exit 0
