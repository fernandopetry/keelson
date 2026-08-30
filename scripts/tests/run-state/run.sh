#!/usr/bin/env bash
# run.sh — suíte de regressão do run-state.sh (decisões 4.151/4.251/4.314).
#
# Casos inline em diretório temporário. Regras provadas: chaves canônicas do
# sdd-conventions nascem exatas NA CASA DA SESSÃO (4.314; sem id → caminho
# legado), incremento de wave, encerramento que o wave-guard reconhece,
# remoção idempotente cobrindo as duas casas, leitura dupla (run legado continua
# operável pela mesma sessão), absorção de run legado não-alheio no init, e
# posse (4.251) sobre run LEGADO — na casa nova a posse é estrutural: cada
# sessão só alcança a própria pasta (o guard de posse cross-sessão é o
# wave-guard, que vê as duas casas).
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
SD="$HERE/../../session-dir.sh"

[ -f "$RS" ] || { echo "ERRO: run-state.sh não encontrado em $RS" >&2; exit 1; }
[ -f "$SD" ] || { echo "ERRO: session-dir.sh não encontrado em $SD" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()   { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$RS" || { echo "FAIL bash -n run-state.sh"; exit 1; }
echo "ok   bash -n run-state.sh"

R="$TMP/repo"; mkdir -p "$R"

# rs — invocação com ambiente de sessão CONTROLADO (a suíte pode rodar dentro de
# uma sessão real, onde CLAUDE_CODE_SESSION_ID existe; o teste decide o id, nunca herda)
rs() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO -u RUN_STATE_SESSAO -u FORCE ${sess:+RUN_STATE_SESSAO="$sess"} bash "$RS" "$@"; }

# casas pré-criadas com --ts fixo (nome de pasta determinístico)
DA="$(env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO=sessao-a bash "$SD" "$R" dir --create --ts "2026-08-30T09:00:00-0300" 2>/dev/null)"
F="$DA/run-state-meu-slug.md"
F_LEG="$R/thoughts/local/run-state-meu-slug.md"

# init escreve as chaves canônicas exatas na casa da sessão (4.314 + posse 4.251)
total=$((total + 1))
rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md" 2>/dev/null
want="status: em_andamento
slug: meu-slug
plan: PLAN-002
waves_concluidas: 0
waves_total: 4
retomada: docs/meu-slug/INDEX.md + docs/meu-slug/tasks/TASK-002-INDEX.md
sessao: sessao-a"
if [ "$(cat "$F" 2>/dev/null)" = "$want" ]; then ok init-canonico-casa-sessao; else falha "init-canonico-casa-sessao: $(cat "$F" 2>&1)"; fi

# init registra o slug no session.meta da casa
total=$((total + 1))
if grep -q '^slugs:.*meu-slug' "$DA/session.meta" 2>/dev/null; then ok init-slug-no-meta; else falha init-slug-no-meta; fi

# sem fonte de id, sessao degrada a "desconhecida" e a casa é a LEGADA
total=$((total + 1))
rs "" "$R" init outro-slug PLAN-003 2 "docs/outro-slug/INDEX.md" 2>/dev/null
if grep -q '^sessao: desconhecida$' "$R/thoughts/local/run-state-outro-slug.md" 2>/dev/null; then ok init-sem-fonte-legado; else falha init-sem-fonte-legado; fi
rs "" "$R" remove outro-slug 2>/dev/null

# o wave-guard reconhece o run ativo (mesmo grep do hook)
total=$((total + 1))
if grep -q '^status: em_andamento' "$F"; then ok wave-guard-ve-ativo; else falha wave-guard-ve-ativo; fi

# wave-done incrementa e ecoa (na casa da sessão)
total=$((total + 1))
got="$(rs sessao-a "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "1" ] && grep -q '^waves_concluidas: 1$' "$F"; then ok wave-done-1; else falha "wave-done-1: [$got]"; fi
total=$((total + 1))
got="$(rs sessao-a "$R" wave-done meu-slug 2>/dev/null)"
if [ "$got" = "2" ] && grep -q '^waves_concluidas: 2$' "$F"; then ok wave-done-2; else falha "wave-done-2: [$got]"; fi

# posse estrutural (4.314): sessão B não alcança o run da casa da sessão A
total=$((total + 1))
err="$(rs sessao-b "$R" wave-done meu-slug 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 2 ] && grep -q '^waves_concluidas: 2$' "$F"; then ok posse-estrutural-wave-done; else falha "posse-estrutural-wave-done: [$rc:$err]"; fi

# leitura dupla (carência 4.314): run LEGADO segue operável pela mesma sessão
legado() { # slug sessao — escreve run legado em_andamento à mão (formato pré-4.314)
  mkdir -p "$R/thoughts/local"
  cat > "$R/thoughts/local/run-state-$1.md" <<EOF
status: em_andamento
slug: $1
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: docs/$1/INDEX.md
sessao: $2
EOF
}
legado slug-velho sessao-a
total=$((total + 1))
got="$(rs sessao-a "$R" wave-done slug-velho 2>/dev/null)"
if [ "$got" = "2" ] && grep -q '^waves_concluidas: 2$' "$R/thoughts/local/run-state-slug-velho.md"; then ok leitura-dupla-wave-done; else falha "leitura-dupla-wave-done: [$got]"; fi
total=$((total + 1))
rs sessao-a "$R" close slug-velho "Entrega concluída" 2>/dev/null
if grep -q '^status: encerrado' "$R/thoughts/local/run-state-slug-velho.md"; then ok leitura-dupla-close; else falha leitura-dupla-close; fi
rs sessao-a "$R" remove slug-velho 2>/dev/null

# posse (4.251) sobre run LEGADO: outra sessão não toca run em_andamento de terceiro
legado meu-slug-leg sessao-a
total=$((total + 1))
err="$(rs sessao-b "$R" wave-done meu-slug-leg 2>&1 >/dev/null)"; rc=$?
case "$rc:$err" in 2:*"posse de terceiro"*) ok posse-legado-recusa ;; *) falha "posse-legado-recusa: [$rc:$err]" ;; esac
total=$((total + 1))
rs sessao-b "$R" close meu-slug-leg "tentativa alheia" >/dev/null 2>&1
[ $? -eq 2 ] && grep -q '^status: em_andamento' "$R/thoughts/local/run-state-meu-slug-leg.md" && ok posse-legado-close-recusa || falha posse-legado-close-recusa
total=$((total + 1))
rs sessao-b "$R" remove meu-slug-leg >/dev/null 2>&1
[ $? -eq 2 ] && [ -f "$R/thoughts/local/run-state-meu-slug-leg.md" ] && ok posse-legado-remove-recusa || falha posse-legado-remove-recusa

# posse degrada quando o chamador não tem id (nunca bloqueio cego)
total=$((total + 1))
err="$(rs "" "$R" init meu-slug-leg PLAN-001 3 "docs/meu-slug-leg/INDEX.md" 2>&1 >/dev/null)"
case "$err" in *sobrescrevendo*) ok posse-degrada-sem-id ;; *) falha "posse-degrada-sem-id: [$err]" ;; esac
rs "" "$R" remove meu-slug-leg 2>/dev/null

# FORCE=1 assume a posse de run legado alheio de propósito
legado meu-slug-leg sessao-a
total=$((total + 1))
err="$(env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO RUN_STATE_SESSAO=sessao-b FORCE=1 bash "$RS" "$R" close meu-slug-leg "assumido" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && grep -q '^status: encerrado' "$R/thoughts/local/run-state-meu-slug-leg.md"; then ok posse-force-assume; else falha "posse-force-assume: [$rc:$err]"; fi
rs sessao-b "$R" remove meu-slug-leg 2>/dev/null

# absorção (4.314): init da MESMA sessão com run legado em_andamento do slug →
# o legado é removido com aviso (nunca fica órfão re-acusando no wave-guard)
legado meu-slug sessao-a
total=$((total + 1))
err="$(rs sessao-a "$R" init meu-slug PLAN-002 4 "docs/meu-slug/INDEX.md" 2>&1 >/dev/null)"
case "$err" in *"absorvendo run legado"*) ok init-absorve-legado ;; *) falha "init-absorve-legado: [$err]" ;; esac
total=$((total + 1))
[ ! -f "$F_LEG" ] && grep -q '^status: em_andamento' "$F" && ok init-absorve-remove-orfao || falha init-absorve-remove-orfao

# init sobre run ativo da MESMA sessão sobrescreve com aviso e zera
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

# show e remove (idempotente; remove cobre a casa da sessão E resíduo legado)
total=$((total + 1))
got="$(rs sessao-a "$R" show meu-slug 2>/dev/null | sed -n 1p)"
if [ "$got" = "status: encerrado — Entrega concluída" ]; then ok show; else falha "show: [$got]"; fi
total=$((total + 1))
touch "$F_LEG"
rs sessao-a "$R" remove meu-slug && rs sessao-a "$R" remove meu-slug && [ ! -f "$F" ] && [ ! -f "$F_LEG" ] && ok remove-ambas-casas-idempotente || falha remove-ambas-casas-idempotente
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
