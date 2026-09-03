#!/usr/bin/env bash
# run.sh — suíte de regressão do review-guard (decisões 4.103/4.252/4.314).
#
# Roda o hook de verdade (stdin JSON, jq, repo git sintético sem base main —
# a detecção cai no working tree e os untracked entram). Foco: o silenciador de
# ciclo formal (run-state ativo → a rede da sessão livre cala) nos DOIS layouts:
#   1. controle positivo: diff acima do limiar, sem run-state → block, com a
#      contagem de linhas ÍNTEGRA na mensagem (repo sem HEAD: o `git diff
#      --numstat HEAD` falha e, sob pipefail, o `|| echo 0` empilhava um segundo
#      "0" — added_lines="0\n0" quebrava o limiar e a mensagem);
#   2. run-state LEGADO em andamento → silêncio;
#   3. run-state na casa da sessão (thoughts/local/sessions/*/ — 4.314) → silêncio;
#   4. run-state de OUTRA sessão (4.252) → NÃO silencia, block;
#   5. mudança trivial (abaixo do limiar) em repo sem HEAD → silêncio — o
#      added_lines malformado fazia o teste do limiar errar e cutucar à toa;
#   6–10. veredito no ledger (4.365): evento `gate` do code-reviewer mais novo que
#      todo arquivo de código → silêncio; arquivo editado depois do veredito, veredito
#      de outro gate, veredito de outra sessão e arquivo alterado ausente do disco →
#      cutuca (conservador);
#   11–12. warroom (4.372): marcador `warroom.meta` DESTA sessão cala o gate 7 (a dívida
#      vai ao DEBT.md); marcador de outra sessão não cala.
# Cada caso usa repo próprio (o anti-renudge de .git/ não vaza entre casos).
#
# Uso: scripts/tests/review-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/review-guard.sh"
LEDGER="$HERE/../../ledger.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "review-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

repo() { # $1 = dir — repo git com ficha e mudança de código acima do limiar
  mkdir -p "$1/src"
  ( cd "$1" && git init -q . )
  printf '{ "codePaths": { "backend": ["src"] } }\n' > "$1/keelson.config.json"
  i=0
  : > "$1/src/novo.php"
  while [ "$i" -lt 40 ]; do
    echo "linha $i;" >> "$1/src/novo.php"
    i=$((i + 1))
  done
}

run_state() { # dir-do-run-state slug sessao
  mkdir -p "$1"
  cat > "$1/run-state-$2.md" <<EOF
status: em_andamento
slug: $2
plan: PLAN-001
waves_concluidas: 1
waves_total: 3
retomada: wave 2 em curso
sessao: $3
EOF
}

roda() { # proj payload-json -> $TMP/out, $st
  printf '%s' "$2" | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO CLAUDE_PROJECT_DIR="$1" bash "$HOOK" > "$TMP/out" 2>/dev/null
  st=$?
}

contem() {
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then echo "ok   $1"; else
    echo "FAIL $1: saída não contém [$2]"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  fi
}

silencio() {
  total=$((total + 1))
  if [ "$st" -ne 0 ] || [ -s "$TMP/out" ]; then
    echo "FAIL $1: esperava silêncio (exit $st)"
    sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  else
    echo "ok   $1"
  fi
}

# 1. Controle positivo: mudança acima do limiar, sem run-state → cutuca,
#    e a contagem de linhas sai íntegra mesmo sem HEAD (untracked contam)
D1="$TMP/c1"; repo "$D1"
roda "$D1" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "positivo/decision" '"decision": "block"'
contem "positivo/gate"     'Gate de Code Review'
contem "positivo/linhas"   '~40 linha(s) adicionada(s)'

# 2. Run-state LEGADO em andamento → rede da sessão livre cala
D2="$TMP/c2"; repo "$D2"; run_state "$D2/thoughts/local" alfa desconhecida
roda "$D2" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "legado-silencia"

# 3. Run-state na casa da sessão (4.314) → mesmo silêncio
D3="$TMP/c3"; repo "$D3"
run_state "$D3/thoughts/local/sessions/20260830-100000-sessaoeu" beta sessao-eu
roda "$D3" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "sessao-silencia"

# 4. Run-state de OUTRA sessão (4.252) → não silencia a rede desta
D4="$TMP/c4"; repo "$D4"
run_state "$D4/thoughts/local/sessions/20260830-100000-sessoutr" gama sessao-outra
roda "$D4" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "alheio/decision" '"decision": "block"'

# 5. Mudança trivial (1 arquivo, 5 linhas — abaixo de 2/30) em repo sem HEAD → silêncio
D5="$TMP/c5"; mkdir -p "$D5/src"
( cd "$D5" && git init -q . )
printf '{ "codePaths": { "backend": ["src"] } }\n' > "$D5/keelson.config.json"
printf 'a;\nb;\nc;\nd;\ne;\n' > "$D5/src/pequeno.php"
roda "$D5" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "trivial-sem-head"

# 6. Veredito do code-reviewer no ledger da sessão mais novo que os arquivos → silêncio (4.365)
D6="$TMP/c6"; repo "$D6"
touch -t 202601010000 "$D6/src/novo.php"
printf 'APROVADO — diff avulso\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D6" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "veredito-cobre-arvore"

# 7. Arquivo de código editado DEPOIS do veredito → cutuca de novo
D7="$TMP/c7"; repo "$D7"
ev="$(printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D7" append gate code-reviewer meu-slug 2>/dev/null)"
touch -t 202601010000 "$ev"
roda "$D7" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "pos-veredito/decision" '"decision": "block"'

# 8. Veredito de OUTRO gate (qa) não cala o review-guard
D8="$TMP/c8"; repo "$D8"
touch -t 202601010000 "$D8/src/novo.php"
printf 'PASSOU\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D8" append gate qa meu-slug >/dev/null 2>&1
roda "$D8" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "outro-gate/decision" '"decision": "block"'

# 9. Veredito na casa de OUTRA sessão não cala esta
D9="$TMP/c9"; repo "$D9"
touch -t 202601010000 "$D9/src/novo.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-outra bash "$LEDGER" "$D9" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D9" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "sessao-alheia/decision" '"decision": "block"'

# 10. Arquivo alterado que não existe mais no disco conta como mais novo (conservador)
D10="$TMP/c10"; repo "$D10"
( cd "$D10" && printf 'x;\n' > src/velho.php && git add src/velho.php \
  && git -c user.email=t@t -c user.name=t commit -q -m base && git rm -q src/velho.php )
touch -t 202601010000 "$D10/src/novo.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D10" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D10" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "ausente/decision" '"decision": "block"'

# 11. Warroom ativo NESTA sessão (4.372) → gate 7 não cutuca (a dívida vai ao DEBT.md)
D11="$TMP/c11"; repo "$D11"
mkdir -p "$D11/thoughts/local/sessions/20260903-100000-sessaoeu"
printf 'inicio: 2026-09-03T10:00:00-0300\nmotivo: incidente\nbranch: main\nbase: abc\nsessao: sessao-eu\n' \
  > "$D11/thoughts/local/sessions/20260903-100000-sessaoeu/warroom.meta"
roda "$D11" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "warroom-desta-sessao-silencia"

# 12. Warroom de OUTRA sessão não cala esta (posse, 4.252)
D12="$TMP/c12"; repo "$D12"
mkdir -p "$D12/thoughts/local/sessions/20260903-100000-sessoutr"
printf 'inicio: 2026-09-03T10:00:00-0300\nmotivo: incidente\nbranch: main\nbase: abc\nsessao: sessao-outra\n' \
  > "$D12/thoughts/local/sessions/20260903-100000-sessoutr/warroom.meta"
roda "$D12" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "warroom-alheio/decision" '"decision": "block"'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "review-guard: $fail de $total casos falharam"
  exit 1
fi
echo "review-guard: $total casos verdes"
exit 0
