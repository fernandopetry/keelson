#!/usr/bin/env bash
# run.sh — suíte de regressão do run-state.sh (decisão 4.151).
#
# Casos inline em diretório temporário. Regras provadas: chaves canônicas do
# sdd-conventions nascem exatas, incremento de wave, encerramento que o wave-guard
# reconhece (grep '^status: em_andamento' deixa de casar), remoção idempotente,
# posse (4.251): recusa de init/wave-done/close/remove sobre run em_andamento de
# terceiro, degradação com id desconhecido, FORCE=1, run encerrado liberado.
# O ambiente de sessão é sempre controlado pelo wrapper rs() — a suíte pode rodar
# dentro de uma sessão real onde CLAUDE_CODE_SESSION_ID existe.
#
# Uso: scripts/tests/run-state/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
RS="$HERE/../../run-state.sh"

[ -f "$RS" ] || { echo "ERRO: run-state.sh não encontrado em $RS" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()   { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$RS" || { echo "FAIL bash -n run-state.sh"; exit 1; }
echo "ok   bash -n run-state.sh"

R="$TMP/repo"; mkdir -p "$R"
F="$R/thoughts/local/run-state-meu-slug.md"

# rs — invocação com ambiente de sessão CONTROLADO (a suíte pode rodar dentro de
# uma sessão real, onde CLAUDE_CODE_SESSION_ID existe; o teste decide o id, nunca herda)
rs() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID -u RUN_STATE_SESSAO -u FORCE ${sess:+RUN_STATE_SESSAO="$sess"} bash "$RS" "$@"; }

# init escreve as chaves canônicas exatas (posse conhecida — 4.251)
total=$((total + 1))
rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md" 2>/dev/null
want="status: em_andamento
slug: meu-slug
plan: PLAN-002
waves_concluidas: 0
waves_total: 4
retomada: docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md
sessao: sessao-a"
if [ "$(cat "$F")" = "$want" ]; then ok init-canonico; else falha "init-canonico: $(cat "$F" 2>&1)"; fi

# sem fonte de id, sessao degrada a "desconhecida"
total=$((total + 1))
rs "" "$R" init outro-slug PLAN-003 2 "docs/outro-slug/INDEX.md" 2>/dev/null
if grep -q '^sessao: desconhecida$' "$R/thoughts/local/run-state-outro-slug.md"; then ok init-sem-fonte-desconhecida; else falha init-sem-fonte-desconhecida; fi
rs "" "$R" remove outro-slug 2>/dev/null

# o wave-guard reconhece o run ativo
total=$((total + 1))
if grep -q '^status: em_andamento' "$F"; then ok wave-guard-ve-ativo; else falha wave-guard-ve-ativo; fi

# wave-done incrementa e ecoa
total=$((total + 1))
got="$(rs sessao-a "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "1" ] && grep -q '^waves_concluidas: 1$' "$F"; then ok wave-done-1; else falha "wave-done-1: [$got]"; fi
total=$((total + 1))
got="$(rs sessao-a "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "2" ] && grep -q '^waves_concluidas: 2$' "$F"; then ok wave-done-2; else falha "wave-done-2: [$got]"; fi

# posse (4.251): outra sessão não toca run em_andamento de terceiro
total=$((total + 1))
rs sessao-b "$R" wave-done meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && grep -q '^waves_concluidas: 2$' "$F" && ok posse-wave-done-recusa || falha posse-wave-done-recusa
total=$((total + 1))
err="$(rs sessao-b "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>&1 >/dev/null)"; rc=$?
case "$rc:$err" in 2:*"posse de terceiro"*) ok posse-init-recusa ;; *) falha "posse-init-recusa: [$rc:$err]" ;; esac
total=$((total + 1))
rs sessao-b "$R" close meu-slug "tentativa alheia" >/dev/null 2>&1
[ $? -eq 2 ] && grep -q '^status: em_andamento' "$F" && ok posse-close-recusa || falha posse-close-recusa
total=$((total + 1))
rs sessao-b "$R" remove meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && [ -f "$F" ] && ok posse-remove-recusa || falha posse-remove-recusa

# posse degrada quando um dos lados é desconhecida (nunca bloqueio cego)
total=$((total + 1))
err="$(rs "" "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md" 2>&1 >/dev/null)"
case "$err" in *sobrescrevendo*) ok posse-degrada-sem-id ;; *) falha "posse-degrada-sem-id: [$err]" ;; esac
rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md" 2>/dev/null

# FORCE=1 assume a posse de propósito
total=$((total + 1))
err="$(env -u CLAUDE_CODE_SESSION_ID -u RUN_STATE_SESSAO RUN_STATE_SESSAO=sessao-b FORCE=1 bash "$RS" "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && grep -q '^sessao: sessao-b$' "$F"; then ok posse-force-assume; else falha "posse-force-assume: [$rc:$err]"; fi
# devolve a posse à sessao-a para os casos seguintes
env -u CLAUDE_CODE_SESSION_ID RUN_STATE_SESSAO=sessao-a FORCE=1 bash "$RS" "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" >/dev/null 2>&1

# init sobre run ativo da MESMA sessão sobrescreve com aviso
total=$((total + 1))
err="$(rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>&1 >/dev/null)"
case "$err" in
  *sobrescrevendo*) ok init-sobrescreve-avisando ;;
  *) falha "init-sobrescreve-avisando: [$err]" ;;
esac
total=$((total + 1))
if grep -q '^waves_concluidas: 0$' "$F"; then ok init-zera; else falha init-zera; fi

# close muda o status e o wave-guard deixa de casar
total=$((total + 1))
rs sessao-a "$R" close meu-slug "Entrega concluída" 2>/dev/null
if grep -q '^status: encerrado' "$F" && ! grep -q '^status: em_andamento' "$F"; then ok close-encerra; else falha close-encerra; fi
total=$((total + 1))
if grep -q 'Entrega conclu' "$F"; then ok close-motivo; else falha close-motivo; fi

# run encerrado deixa de ter posse defendida (outra sessão pode remover/re-init)
total=$((total + 1))
if rs sessao-b "$R" remove meu-slug >/dev/null 2>&1 && [ ! -f "$F" ]; then ok posse-encerrado-liberado; else falha posse-encerrado-liberado; fi
rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>/dev/null
rs sessao-a "$R" close meu-slug "Entrega concluída" 2>/dev/null

# show e remove (idempotente)
total=$((total + 1))
got="$(rs sessao-a "$R" show meu-slug 2>/dev/null | sed -n 1p)"
if [ "$got" = "status: encerrado — Entrega concluída" ]; then ok show; else falha "show: [$got]"; fi
total=$((total + 1))
rs sessao-a "$R" remove meu-slug && rs sessao-a "$R" remove meu-slug && [ ! -f "$F" ] && ok remove-idempotente || falha remove-idempotente
total=$((total + 1))
got="$(rs sessao-a "$R" show meu-slug 2>/dev/null)"
if [ -z "$got" ]; then ok show-ausente-vazio; else falha "show-ausente-vazio: [$got]"; fi

# erros de uso
total=$((total + 1))
rs sessao-a "$R" wave-done meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok wave-done-sem-arquivo-exit-2 || falha wave-done-sem-arquivo-exit-2
total=$((total + 1))
rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>/dev/null
rs sessao-a "$R" close meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok close-sem-motivo-exit-2 || falha close-sem-motivo-exit-2
rs sessao-a "$R" remove meu-slug 2>/dev/null
total=$((total + 1))
rs sessao-a "$R" init meu-slug PLANO-X 4 "x" >/dev/null 2>&1
[ $? -eq 2 ] && ok init-plan-invalido-exit-2 || falha init-plan-invalido-exit-2
total=$((total + 1))
rs sessao-a "$TMP/nao-existe" show meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok raiz-inexistente-exit-2 || falha raiz-inexistente-exit-2

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "run-state: $fail de $total casos falharam"
  exit 1
fi
echo "run-state: $total casos verdes"
exit 0
