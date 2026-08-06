#!/usr/bin/env bash
# run.sh — suíte de regressão do run-state.sh (decisão 4.151).
#
# Casos inline em diretório temporário. Regras provadas: chaves canônicas do
# sdd-conventions nascem exatas, incremento de wave, encerramento que o wave-guard
# reconhece (grep '^status: em_andamento' deixa de casar), remoção idempotente.
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

# init escreve as chaves canônicas exatas
total=$((total + 1))
bash "$RS" "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md" 2>/dev/null
want="status: em_andamento
slug: meu-slug
plan: PLAN-002
waves_concluidas: 0
waves_total: 4
retomada: docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md"
if [ "$(cat "$F")" = "$want" ]; then ok init-canonico; else falha "init-canonico: $(cat "$F" 2>&1)"; fi

# o wave-guard reconhece o run ativo
total=$((total + 1))
if grep -q '^status: em_andamento' "$F"; then ok wave-guard-ve-ativo; else falha wave-guard-ve-ativo; fi

# wave-done incrementa e ecoa
total=$((total + 1))
got="$(bash "$RS" "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "1" ] && grep -q '^waves_concluidas: 1$' "$F"; then ok wave-done-1; else falha "wave-done-1: [$got]"; fi
total=$((total + 1))
got="$(bash "$RS" "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "2" ] && grep -q '^waves_concluidas: 2$' "$F"; then ok wave-done-2; else falha "wave-done-2: [$got]"; fi

# init sobre run ativo sobrescreve com aviso
total=$((total + 1))
err="$(bash "$RS" "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>&1 >/dev/null)"
case "$err" in
  *sobrescrevendo*) ok init-sobrescreve-avisando ;;
  *) falha "init-sobrescreve-avisando: [$err]" ;;
esac
total=$((total + 1))
if grep -q '^waves_concluidas: 0$' "$F"; then ok init-zera; else falha init-zera; fi

# close muda o status e o wave-guard deixa de casar
total=$((total + 1))
bash "$RS" "$R" close meu-slug "Entrega concluída" 2>/dev/null
if grep -q '^status: encerrado' "$F" && ! grep -q '^status: em_andamento' "$F"; then ok close-encerra; else falha close-encerra; fi
total=$((total + 1))
if grep -q 'Entrega conclu' "$F"; then ok close-motivo; else falha close-motivo; fi

# show e remove (idempotente)
total=$((total + 1))
got="$(bash "$RS" "$R" show meu-slug 2>/dev/null | sed -n 1p)"
if [ "$got" = "status: encerrado — Entrega concluída" ]; then ok show; else falha "show: [$got]"; fi
total=$((total + 1))
bash "$RS" "$R" remove meu-slug && bash "$RS" "$R" remove meu-slug && [ ! -f "$F" ] && ok remove-idempotente || falha remove-idempotente
total=$((total + 1))
got="$(bash "$RS" "$R" show meu-slug 2>/dev/null)"
if [ -z "$got" ]; then ok show-ausente-vazio; else falha "show-ausente-vazio: [$got]"; fi

# erros de uso
total=$((total + 1))
bash "$RS" "$R" wave-done meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok wave-done-sem-arquivo-exit-2 || falha wave-done-sem-arquivo-exit-2
total=$((total + 1))
bash "$RS" "$R" close meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok close-sem-motivo-exit-2 || falha close-sem-motivo-exit-2
total=$((total + 1))
bash "$RS" "$R" init meu-slug PLANO-X 4 "x" >/dev/null 2>&1
[ $? -eq 2 ] && ok init-plan-invalido-exit-2 || falha init-plan-invalido-exit-2
total=$((total + 1))
bash "$RS" "$TMP/nao-existe" show meu-slug >/dev/null 2>&1
[ $? -eq 2 ] && ok raiz-inexistente-exit-2 || falha raiz-inexistente-exit-2

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "run-state: $fail de $total casos falharam"
  exit 1
fi
echo "run-state: $total casos verdes"
exit 0
