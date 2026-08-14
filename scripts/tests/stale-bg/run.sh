#!/usr/bin/env bash
# run.sh — suíte de regressão do stale-background-guard (decisão 4.206).
#
# O hook lê a tabela de processos via `ps` no PATH: a suíte injeta um shim de `ps`
# que devolve fixtures congeladas e fixa o PID "próprio" do hook pela costura
# KEELSON_STALE_GUARD_SELF_PID — todo o resto roda de verdade (stdin JSON, wrapper
# bash, heredoc Python). Casos inline (asserção por grep, saídas curtas):
#   1. multi-sessão: acusa o processo da própria sessão e o órfão (indeterminado),
#      ignora o provadamente de outra sessão, conta os ignorados;
#   2. raiz não identificável: degrada para o comportamento global (tudo com a marca);
#   3. mesa limpa: exit 0 silencioso;
#   4. stop_hook_active: exit 0 sem inspecionar;
#   5. tabela ilegível: fail-closed (cutuca, nunca "limpo");
#   6. ps quebrado: fail-closed do try/except.
#
# Uso: scripts/tests/stale-bg/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/stale-background-guard.sh"
FIX="$HERE/fixtures"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# Shim de ps: devolve a fixture apontada por KEELSON_FAKE_PS_TABLE (ou falha se vazia).
mkdir -p "$TMP/bin"
cat > "$TMP/bin/ps" <<'SH'
#!/bin/bash
[ -n "${KEELSON_FAKE_PS_TABLE:-}" ] || exit 1
cat "$KEELSON_FAKE_PS_TABLE"
SH
chmod +x "$TMP/bin/ps"

fail=0
total=0

roda() { # tabela self_pid stdin -> saída em $TMP/out, exit em $st
  PATH="$TMP/bin:$PATH" \
  KEELSON_FAKE_PS_TABLE="$1" \
  KEELSON_STALE_GUARD_SELF_PID="$2" \
    bash "$HOOK" > "$TMP/out" 2>"$TMP/err" <<< "$3"
  st=$?
}

contem() { # nome padrão — a saída DEVE conter
  total=$((total + 1))
  if grep -qF "$2" "$TMP/out"; then :; else
    echo "FAIL $1: saída não contém [$2]"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

nao_contem() { # nome padrão — a saída NÃO pode conter
  total=$((total + 1))
  if grep -qF "$2" "$TMP/out"; then
    echo "FAIL $1: saída contém [$2] e não devia"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

exit_eh() { # nome esperado
  total=$((total + 1))
  if [ "$st" -ne "$2" ]; then
    echo "FAIL $1: exit $st (esperado $2)"
    sed 's/^/  err: /' "$TMP/err"; fail=$((fail + 1))
  fi
}

# 1. Multi-sessão: self=500 (filho do claude 400). 410 é meu e velho → acusa;
#    310 desce do claude 300 (outra sessão) → ignorado e contado; 600 é órfão
#    (PPID 1, sem claude na cadeia) → indeterminado, acusa; 420 é curto → fora.
roda "$FIX/ps-multi-sessao.txt" 500 '{"stop_hook_active": false}'
exit_eh   "multi-sessao/exit" 0
contem    "multi-sessao/decision"      '"decision": "block"'
contem    "multi-sessao/meu"           'PID 410'
contem    "multi-sessao/orfao"         'PID 600'
contem    "multi-sessao/orfao-rotulo"  'INDETERMINADO'
nao_contem "multi-sessao/outra-sessao" 'PID 310'
contem    "multi-sessao/contador"      'outros 1 pertencem a outra'
contem    "multi-sessao/sondagem"      'LOOP DE SONDAGEM'

# 2. Raiz não identificável (self fora da tabela): sem prova de dono, degrada para o
#    comportamento global — 310, 410 e 600 entram, todos indeterminados.
roda "$FIX/ps-multi-sessao.txt" 99999 '{"stop_hook_active": false}'
exit_eh "sem-raiz/exit" 0
contem  "sem-raiz/310" 'PID 310'
contem  "sem-raiz/410" 'PID 410'
contem  "sem-raiz/600" 'PID 600'

# 3. Mesa limpa: nada velho → silêncio.
roda "$FIX/ps-limpo.txt" 500 '{"stop_hook_active": false}'
exit_eh "limpo/exit" 0
total=$((total + 1))
if [ -s "$TMP/out" ]; then
  echo "FAIL limpo/silencio: esperava saída vazia"; sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
fi

# 4. stop_hook_active: sai antes de inspecionar (a fixture suja não é lida).
roda "$FIX/ps-multi-sessao.txt" 500 '{"stop_hook_active": true}'
exit_eh "stop-active/exit" 0
total=$((total + 1))
if [ -s "$TMP/out" ]; then
  echo "FAIL stop-active/silencio: esperava saída vazia"; sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
fi

# 5. Tabela ilegível: parser sem NENHUMA linha válida cutuca (fail-closed).
roda "$FIX/ps-ilegivel.txt" 500 '{"stop_hook_active": false}'
exit_eh "ilegivel/exit" 0
contem  "ilegivel/decision" '"decision": "block"'
contem  "ilegivel/motivo"   'nao casou o formato'

# 6. ps quebrado (shim sem tabela → exit 1): fail-closed do try/except.
roda "" 500 '{"stop_hook_active": false}'
exit_eh "ps-quebrado/exit" 0
contem  "ps-quebrado/decision" '"decision": "block"'
contem  "ps-quebrado/motivo"   'NAO consegui inspecionar'

if [ "$fail" -gt 0 ]; then
  echo "stale-bg: $fail/$total asserções falharam"
  exit 1
fi
echo "stale-bg: $total asserções ok"
exit 0
