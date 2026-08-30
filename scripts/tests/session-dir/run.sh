#!/usr/bin/env bash
# run.sh — suíte de regressão do session-dir.sh (decisão 4.314).
#
# Casos inline em diretório temporário, com --ts fixo (determinismo) e ambiente
# de sessão SEMPRE controlado (a suíte pode rodar dentro de uma sessão real onde
# CLAUDE_CODE_SESSION_ID existe). Regras provadas: modo legado sem id (dir,
# ledger-dir e window-log colapsam nos caminhos antigos), criação idempotente com
# session.meta canônico, resolução por meta (colisão de sid8 não confunde),
# registro dedupado de slugs, show, e "desconhecida" força o legado.
#
# Uso: scripts/tests/session-dir/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SD="$HERE/../../session-dir.sh"

[ -f "$SD" ] || { echo "ERRO: session-dir.sh não encontrado em $SD" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$SD" || { echo "FAIL bash -n session-dir.sh"; exit 1; }
echo "ok   bash -n session-dir.sh"

R="$TMP/repo"; mkdir -p "$R"
TS1="2026-08-30T10:00:00-0300"

# sd — invocação com ambiente de sessão controlado
sd() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$SD" "$@"; }

# sem id de sessão → modo legado nos três subcomandos
total=$((total + 1))
got="$(sd "" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok legado-dir || falha "legado-dir: [$got]"
total=$((total + 1))
got="$(sd "" "$R" ledger-dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local/session-ledger" ] && ok legado-ledger-dir || falha "legado-ledger-dir: [$got]"
total=$((total + 1))
got="$(sd "" "$R" window-log 2>/dev/null)"
[ "$got" = "$R/thoughts/local/session-window.log" ] && ok legado-window-log || falha "legado-window-log: [$got]"

# "desconhecida" também força o legado (é o valor de degradação do run-state)
total=$((total + 1))
got="$(sd "desconhecida" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok desconhecida-legado || falha "desconhecida-legado: [$got]"

# sem --create, sessão sem pasta → também cai no legado (leitor lê onde os dados estão)
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok sem-pasta-cai-no-legado || falha "sem-pasta-cai-no-legado: [$got]"

# --create nasce a pasta com o session.meta canônico
total=$((total + 1))
D="$R/thoughts/local/sessions/20260830-100000-sessaoa1"
got="$(sd "sessao-a-11112222" "$R" dir --create --ts "$TS1" 2>/dev/null)"
[ "$got" = "$D" ] && [ -d "$D" ] && ok create-nome || falha "create-nome: [$got]"
total=$((total + 1))
want="sessao: sessao-a-11112222
iniciada: $TS1
estado: ativa
slugs:"
[ "$(cat "$D/session.meta" 2>/dev/null)" = "$want" ] && ok create-meta || falha "create-meta: [$(cat "$D/session.meta" 2>/dev/null)]"

# criação é idempotente: segundo --create (mesmo com outro --ts) resolve a existente
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" dir --create --ts "2026-08-30T11:00:00-0300" 2>/dev/null)"
[ "$got" = "$D" ] && ok create-idempotente || falha "create-idempotente: [$got]"
total=$((total + 1))
n=0; for d in "$R/thoughts/local/sessions"/*; do [ -d "$d" ] && n=$((n + 1)); done
[ "$n" = "1" ] && ok create-sem-duplicata || falha "create-sem-duplicata: [$n]"

# ledger-dir e window-log da casa nova
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" ledger-dir --create 2>/dev/null)"
[ "$got" = "$D/ledger" ] && [ -d "$D/ledger" ] && ok novo-ledger-dir || falha "novo-ledger-dir: [$got]"
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" window-log 2>/dev/null)"
[ "$got" = "$D/window.log" ] && ok novo-window-log || falha "novo-window-log: [$got]"

# --slug registra na linha slugs: com dedup
sd "sessao-a-11112222" "$R" dir --slug alfa >/dev/null 2>&1
sd "sessao-a-11112222" "$R" dir --slug beta >/dev/null 2>&1
sd "sessao-a-11112222" "$R" dir --slug alfa >/dev/null 2>&1
total=$((total + 1))
got="$(sed -n 's/^slugs:[ 	]*//p' "$D/session.meta")"
[ "$got" = "alfa beta" ] && ok slug-dedup || falha "slug-dedup: [$got]"

# colisão de sid8: outra sessão com o MESMO prefixo não resolve a pasta alheia
total=$((total + 1))
got="$(sd "sessao-a-11119999" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok colisao-sid8-nao-confunde || falha "colisao-sid8-nao-confunde: [$got]"
total=$((total + 1))
D2="$(sd "sessao-a-11119999" "$R" dir --create --ts "2026-08-30T12:00:00-0300" 2>/dev/null)"
[ "$D2" != "$D" ] && [ -d "$D2" ] && grep -qxF "sessao: sessao-a-11119999" "$D2/session.meta" && ok colisao-cria-propria || falha "colisao-cria-propria: [$D2]"

# show imprime o meta da sessão corrente; nada sem pasta
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" show 2>/dev/null | sed -n 1p)"
[ "$got" = "sessao: sessao-a-11112222" ] && ok show || falha "show: [$got]"
total=$((total + 1))
got="$(sd "sessao-c-inexistente" "$R" show 2>/dev/null)"
[ -z "$got" ] && ok show-ausente-vazio || falha "show-ausente-vazio: [$got]"

# CLAUDE_CODE_SESSION_ID é a fonte quando KEELSON_SESSAO não está definida
total=$((total + 1))
got="$(env -u KEELSON_SESSAO CLAUDE_CODE_SESSION_ID="sessao-a-11112222" bash "$SD" "$R" dir 2>/dev/null)"
[ "$got" = "$D" ] && ok fonte-env-harness || falha "fonte-env-harness: [$got]"

# erros de uso
total=$((total + 1))
sd "x" "$TMP/nao-existe" dir >/dev/null 2>&1
[ $? -eq 2 ] && ok raiz-inexistente-exit-2 || falha raiz-inexistente-exit-2
total=$((total + 1))
sd "x" "$R" acao-invalida >/dev/null 2>&1
[ $? -eq 2 ] && ok acao-invalida-exit-2 || falha acao-invalida-exit-2
total=$((total + 1))
sd "x" "$R" dir --ts "nao-e-iso" --create >/dev/null 2>&1
[ $? -eq 2 ] && ok ts-ilegivel-exit-2 || falha ts-ilegivel-exit-2

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "session-dir: $fail de $total casos falharam"
  exit 1
fi
echo "session-dir: $total casos verdes"
exit 0
