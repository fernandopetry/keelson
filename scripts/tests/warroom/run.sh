#!/usr/bin/env bash
# run.sh — suíte de regressão do modo warroom (decisão 4.372): scripts/warroom.sh +
# hooks/warroom-guard.sh, com repo git sintético e ficha mínima.
#
# O que prova (cada caso em repo próprio — o anti-renudge de .git/ não vaza):
#   1. open cria o marcador NA CASA DA SESSÃO (mesma casa do ledger) + evento `marco`;
#      status ecoa `ativo`; open repetido é idempotente.
#   2. reconcile: commit feito na janela vira UMA linha aberta no DEBT.md, com hash,
#      gates e arquivos; 2ª chamada não duplica (fonte é o git, idempotente);
#      arquivo sob `sensitiveGlobs` marca `sensivel: sim`.
#   3. hook Stop com warroom ativo → reconcilia em silêncio (exit 0, sem output) —
#      commit feito "pelo humano no terminal" entra no DEBT.md sem ninguém pedir.
#   4. close remove o marcador, registra `marco` de fecho e `pendencia` quando sobra
#      linha aberta.
#   5. hook Stop com warroom INATIVO e dívida aberta → block 1×; mesmo conjunto → silêncio;
#      settle muda o conjunto → cutuca de novo; tudo fechado → silêncio.
#   6. settle: `[ ]` → `[x]` com estado e nota; hash inexistente → exit 2.
#   7. controle de posse: marcador de OUTRA sessão não é "ativo" para esta.
#   8. degradação: sem ficha o hook sai 0 em silêncio; reconcile sem marcador → novas: 0.
#
# Uso: scripts/tests/warroom/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
W="$HERE/../../warroom.sh"
HOOK="$HERE/../../../hooks/warroom-guard.sh"

[ -f "$W" ] || { echo "ERRO: script não encontrado em $W" >&2; exit 1; }
[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "warroom: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

repo() { # dir → repo git com ficha e 1 commit base
  mkdir -p "$1/src"
  ( cd "$1" && git init -q . && git config user.email t@t && git config user.name t )
  printf '{ "docsRoot": "docs", "codePaths": { "backend": ["src"] }, "sensitiveGlobs": ["src/auth/**"] }\n' > "$1/keelson.config.json"
  printf 'thoughts/\n' > "$1/.gitignore"
  echo base > "$1/src/base.php"
  ( cd "$1" && git add -A && git commit -qm "chore: base" )
}

commit() { # dir arquivo msg
  mkdir -p "$(dirname "$1/$2")"
  echo "conteudo $RANDOM" > "$1/$2"
  ( cd "$1" && git add -A && git commit -qm "$3" )
}

wr() { # sessao dir ação args…
  sess="$1"; shift
  env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$W" "$@"
}

hook() { # dir sessao → $TMP/out, $st
  printf '{"stop_hook_active": false, "session_id": "%s"}' "$2" \
    | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO CLAUDE_PROJECT_DIR="$1" bash "$HOOK" > "$TMP/out" 2>/dev/null
  st=$?
}

ok()   { total=$((total + 1)); echo "ok   $1"; }
bad()  { total=$((total + 1)); fail=$((fail + 1)); echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  /'; }
contem()   { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1: não contém [$3]" "$2"; fi; }
naocontem(){ if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1: contém [$3]" "$2"; else ok "$1"; fi; }
silencio() { if [ "$st" -eq 0 ] && [ ! -s "$TMP/out" ]; then ok "$1"; else bad "$1: esperava silêncio (exit $st)" "$(cat "$TMP/out")"; fi; }
bloqueia() { if grep -q '"decision": "block"' "$TMP/out"; then ok "$1"; else bad "$1: esperava block" "$(cat "$TMP/out")"; fi; }

# ---------- 1. open / status / idempotência ----------
D1="$TMP/c1"; repo "$D1"
out="$(wr s1 "$D1" open incidente pagamento)"
contem "open/ativo" "$out" "warroom: ATIVO"
marker="$(find "$D1/thoughts/local/sessions" -name warroom.meta 2>/dev/null | head -1)"
if [ -n "$marker" ]; then ok "open/marcador-na-casa-da-sessao"; else bad "open/marcador-na-casa-da-sessao" "$(find "$D1/thoughts" -type f)"; fi
ledger="$(find "$D1/thoughts/local/sessions" -name '*-marco-warroom.md' 2>/dev/null | head -1)"
if [ -n "$ledger" ] && [ "$(dirname "$(dirname "$ledger")")" = "$(dirname "$marker")" ]; then ok "open/ledger-marco-mesma-casa"; else bad "open/ledger-marco-mesma-casa" "marker=$marker ledger=$ledger"; fi
out="$(wr s1 "$D1" status)"
contem "status/ativo" "$out" "ativo"
out="$(wr s1 "$D1" open outro motivo)"
contem "open/idempotente" "$out" "já ativo"
contem "open/idempotente-mantem-motivo" "$(cat "$marker")" "motivo: incidente pagamento"

# ---------- 2. reconcile ----------
commit "$D1" src/b.php "fix: b"
out="$(wr s1 "$D1" reconcile)"
contem "reconcile/novas-1" "$out" "novas: 1"
h="$(cd "$D1" && git rev-parse --short=7 HEAD)"
debt="$(cat "$D1/docs/DEBT.md")"
contem "reconcile/linha-hash"   "$debt" "- [ ] \`$h\`"
contem "reconcile/gates"        "$debt" "gates não rodados: 1-7 (tests+review), 8 (security), 9 (qa)"
contem "reconcile/arquivo"      "$debt" "src/b.php"
contem "reconcile/motivo"       "$debt" "motivo: incidente pagamento"
naocontem "reconcile/nao-sensivel" "$debt" "sensivel: sim"
out="$(wr s1 "$D1" reconcile)"
contem "reconcile/idempotente" "$out" "novas: 0"
n="$(grep -c '^- \[ \]' "$D1/docs/DEBT.md")"
[ "$n" -eq 1 ] && ok "reconcile/uma-linha" || bad "reconcile/uma-linha: $n"
commit "$D1" src/auth/token.php "fix: auth"
wr s1 "$D1" reconcile >/dev/null
hs="$(cd "$D1" && git rev-parse --short=7 HEAD)"
linha="$(grep "\`$hs\`" "$D1/docs/DEBT.md")"
contem "reconcile/sensivel-sim" "$linha" "sensivel: sim"

# ---------- 3. hook com warroom ativo: reconcilia em silêncio ----------
commit "$D1" src/c.php "fix: c (commit do humano)"
hook "$D1" s1
silencio "hook-ativo/silencio"
hc="$(cd "$D1" && git rev-parse --short=7 HEAD)"
grep -q "\`$hc\`" "$D1/docs/DEBT.md" && ok "hook-ativo/commit-entrou-no-debt" || bad "hook-ativo/commit-entrou-no-debt" "$(cat "$D1/docs/DEBT.md")"

# ---------- 4. close ----------
out="$(wr s1 "$D1" close)"
contem "close/fechado" "$out" "warroom: FECHADO"
contem "close/divida-aberta-3" "$out" "dívida aberta: 3 linha(s)"
[ -f "$marker" ] && bad "close/marcador-removido" || ok "close/marcador-removido"
find "$D1/thoughts/local/sessions" -name '*-pendencia-warroom.md' | grep -q . && ok "close/pendencia-no-ledger" || bad "close/pendencia-no-ledger" "$(find "$D1/thoughts -type f")"
nm="$(find "$D1/thoughts/local/sessions" -name '*-marco-warroom*.md' | wc -l | tr -d ' ')"
[ "$nm" -eq 2 ] && ok "close/dois-marcos" || bad "close/dois-marcos: $nm"
out="$(wr s1 "$D1" status)"
contem "status/inativo" "$out" "inativo"
contem "status/divida" "$out" "dívida aberta: 3 linha(s)"

# ---------- 5. hook inativo com dívida: cutuca 1× por conjunto ----------
hook "$D1" s1
bloqueia "hook-inativo/block"
contem "hook-inativo/conta" "$(cat "$TMP/out")" "3 commit(s)"
contem "hook-inativo/remedio" "$(cat "$TMP/out")" "/keelson:warroom close"
hook "$D1" s1
silencio "hook-inativo/anti-renudge"
out="$(wr s1 "$D1" settle "$h" resolvida "review + suíte verdes")"
contem "settle/ok" "$out" "settle: $h → resolvida"
hook "$D1" s1
bloqueia "hook-inativo/conjunto-mudou-recutuca"
contem "hook-inativo/conta-2" "$(cat "$TMP/out")" "2 commit(s)"
wr s1 "$D1" settle "$hs" assumida "hotfix já em produção, gate 8 rodado à mão" >/dev/null
wr s1 "$D1" settle "$hc" resolvida "gates da rodada de fecho" >/dev/null
hook "$D1" s1
silencio "hook-inativo/tudo-fechado"

# ---------- 6. settle ----------
linha="$(grep "\`$h\`" "$D1/docs/DEBT.md")"
contem "settle/x" "$linha" "- [x] \`$h\`"
contem "settle/estado-nota" "$linha" "fecho: resolvida — review + suíte verdes"
out="$(wr s1 "$D1" settle deadbee resolvida nota 2>&1)"; st=$?
[ "$st" -eq 2 ] && ok "settle/hash-inexistente-exit-2" || bad "settle/hash-inexistente-exit-2: exit $st" "$out"
out="$(wr s1 "$D1" settle "$h" perdoada nota 2>&1)"; st=$?
[ "$st" -eq 2 ] && ok "settle/estado-invalido-exit-2" || bad "settle/estado-invalido-exit-2: exit $st" "$out"

# ---------- 7. posse: marcador de outra sessão não é desta ----------
D7="$TMP/c7"; repo "$D7"
wr outra "$D7" open janela alheia >/dev/null
out="$(wr minha "$D7" status)"
contem "posse/inativo-para-esta-sessao" "$out" "inativo"
commit "$D7" src/x.php "fix: x"
hook "$D7" minha
silencio "posse/hook-desta-sessao-nao-reconcilia"
[ -f "$D7/docs/DEBT.md" ] && bad "posse/debt-nao-criado" || ok "posse/debt-nao-criado"

# ---------- 8. degradação ----------
D8="$TMP/c8"; repo "$D8"; rm "$D8/keelson.config.json"
hook "$D8" s8
silencio "degrada/sem-ficha-silencio"
out="$(wr s8 "$D8" reconcile)"
contem "degrada/sem-marcador-novas-0" "$out" "novas: 0"

echo
echo "warroom: $((total - fail))/$total ok"
[ "$fail" -eq 0 ]
