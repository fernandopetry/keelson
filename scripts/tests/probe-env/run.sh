#!/usr/bin/env bash
# run.sh — suíte de regressão do probe-env.sh (decisão 4.154).
#
# Casos com servidor HTTP real (python3 http.server em porta livre) e porta fechada
# determinística (127.0.0.1:1). Regras provadas: causas nomeadas do catálogo
# (credencial_ausente/placeholder, app_fora_do_ar, ok), evidência literal, formato
# flat legado, seleção de realm, boot da 4.71 (tentado e registrado), senha nunca
# ecoada na saída.
#
# Uso: scripts/tests/probe-env/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige python3+curl.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
PE="$HERE/../../probe-env.sh"

[ -f "$PE" ] || { echo "ERRO: probe-env.sh não encontrado" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: a suíte exige python3" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERRO: a suíte exige curl" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
SRV_PID=""
# o wait após o kill engole a notificação "Terminated" do job do servidor
trap '{ [ -n "$SRV_PID" ] && kill "$SRV_PID" && wait "$SRV_PID"; } 2>/dev/null; rm -rf "$TMP"' EXIT

fail=0
total=0

getline() { printf '%s\n' "$1" | sed -n "s/^$2=//p" | sed -n 1p; }

mkroot() { r="$TMP/$1"; mkdir -p "$r"; printf '%s\n' "$r"; }

# ---- servidor de pé numa porta livre ----
PORT="$(python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
)"
( cd "$TMP" && exec python3 -m http.server "$PORT" --bind 127.0.0.1 ) >/dev/null 2>&1 &
SRV_PID=$!
sleep 1

R="$(mkroot up)"
cat > "$R/keelson.local.json" <<EOF
{ "screenVerify": { "defaultRealm": "admin", "realms": {
  "admin":  { "baseUrl": "http://127.0.0.1:$PORT", "login": { "path": "/login", "username": "dev", "password": "segredo-nunca-ecoa" } } } } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R" 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && [ "$(getline "$got" causa)" = "ok" ] && [ "$(getline "$got" realm)" = "admin" ] \
   && [ "$(getline "$got" probe)" = "200" ]; then echo "ok   app-de-pe"
else echo "FAIL app-de-pe (exit $st): [$got]"; fail=$((fail + 1)); fi

# senha nunca aparece na saída
total=$((total + 1))
case "$got" in
  *segredo-nunca-ecoa*) echo "FAIL senha-nao-ecoa"; fail=$((fail + 1)) ;;
  *) echo "ok   senha-nao-ecoa" ;;
esac

# ---- app fora do ar (porta 1: connection refused determinístico) ----
R2="$(mkroot down)"
cat > "$R2/keelson.local.json" <<'EOF'
{ "screenVerify": { "realms": {
  "admin": { "baseUrl": "http://127.0.0.1:1", "login": { "path": "/l", "username": "dev", "password": "x" } } } } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R2" --timeout 3 2>/dev/null)"; st=$?
ev="$(printf '%s\n' "$got" | grep '^evidencia=' | head -1)"
if [ "$st" -eq 1 ] && [ "$(getline "$got" causa)" = "app_fora_do_ar" ] && [ -n "$ev" ]; then echo "ok   fora-do-ar"
else echo "FAIL fora-do-ar (exit $st): [$got]"; fail=$((fail + 1)); fi

# ---- fora do ar com quality.boot declarado (4.71): boot tentado e registrado ----
cat > "$R2/keelson.config.json" <<'EOF'
{ "docsRoot": "docs", "quality": { "boot": "true" } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R2" --boot --boot-wait 0 --timeout 3 2>/dev/null)"; st=$?
case "$got" in
  *"boot tentado (4.71)"*"re-sondagem"*)
    [ "$st" -eq 1 ] && [ "$(getline "$got" causa)" = "app_fora_do_ar" ] && echo "ok   boot-registrado" \
      || { echo "FAIL boot-registrado (exit $st)"; fail=$((fail + 1)); } ;;
  *) echo "FAIL boot-registrado: [$got]"; fail=$((fail + 1)) ;;
esac

# ---- boot ausente na ficha: sondagem que falhou basta, declarado ----
R2b="$(mkroot down-sem-boot)"
cp "$R2/keelson.local.json" "$R2b/"
total=$((total + 1))
got="$(bash "$PE" "$R2b" --boot --timeout 3 2>/dev/null)"; st=$?
case "$got" in
  *"quality.boot: null/ausente"*) [ "$st" -eq 1 ] && echo "ok   boot-null-declarado" || { echo "FAIL boot-null-declarado"; fail=$((fail + 1)); } ;;
  *) echo "FAIL boot-null-declarado: [$got]"; fail=$((fail + 1)) ;;
esac

# ---- credencial: arquivo ausente, placeholder, realm inexistente, ambíguo, flat ----
R3="$(mkroot sem-local)"
total=$((total + 1))
got="$(bash "$PE" "$R3" 2>/dev/null)"; st=$?
[ "$st" -eq 1 ] && [ "$(getline "$got" causa)" = "credencial_ausente" ] && echo "ok   local-ausente" \
  || { echo "FAIL local-ausente (exit $st): [$got]"; fail=$((fail + 1)); }

R4="$(mkroot placeholder)"
cat > "$R4/keelson.local.json" <<'EOF'
{ "screenVerify": { "realms": {
  "admin": { "baseUrl": "http://127.0.0.1:9", "login": { "path": "/l", "username": "<user de dev>", "password": "" } } } } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R4" 2>/dev/null)"; st=$?
case "$got" in
  *"login.username(placeholder)"*"login.password(vazio)"*)
    [ "$st" -eq 1 ] && [ "$(getline "$got" causa)" = "credencial_placeholder" ] && echo "ok   placeholder" \
      || { echo "FAIL placeholder (exit $st)"; fail=$((fail + 1)); } ;;
  *) echo "FAIL placeholder: [$got]"; fail=$((fail + 1)) ;;
esac

total=$((total + 1))
got="$(bash "$PE" "$R4" --realm portal 2>/dev/null)"; st=$?
case "$got" in
  *'realm "portal" não existe'*) [ "$st" -eq 1 ] && echo "ok   realm-inexistente" || { echo "FAIL realm-inexistente"; fail=$((fail + 1)); } ;;
  *) echo "FAIL realm-inexistente: [$got]"; fail=$((fail + 1)) ;;
esac

R5="$(mkroot ambiguo)"
cat > "$R5/keelson.local.json" <<'EOF'
{ "screenVerify": { "realms": {
  "a": { "baseUrl": "http://127.0.0.1:9", "login": { "username": "u", "password": "p" } },
  "b": { "baseUrl": "http://127.0.0.1:9", "login": { "username": "u", "password": "p" } } } } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R5" 2>/dev/null)"; st=$?
case "$got" in
  *"vários realms sem defaultRealm"*) [ "$st" -eq 1 ] && echo "ok   ambiguo" || { echo "FAIL ambiguo"; fail=$((fail + 1)); } ;;
  *) echo "FAIL ambiguo: [$got]"; fail=$((fail + 1)) ;;
esac

R6="$(mkroot flat)"
cat > "$R6/keelson.local.json" <<EOF
{ "screenVerify": { "baseUrl": "http://127.0.0.1:$PORT", "login": { "path": "/l", "username": "dev", "password": "x" } } }
EOF
total=$((total + 1))
got="$(bash "$PE" "$R6" 2>/dev/null)"; st=$?
[ "$st" -eq 0 ] && [ "$(getline "$got" realm)" = "default" ] && [ "$(getline "$got" causa)" = "ok" ] && echo "ok   flat-legado" \
  || { echo "FAIL flat-legado (exit $st): [$got]"; fail=$((fail + 1)); }

# ---- uso incorreto ----
total=$((total + 1))
bash "$PE" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   sem-arg-exit-2" || { echo "FAIL sem-arg-exit-2"; fail=$((fail + 1)); }

echo "---"
if [ "$fail" -gt 0 ]; then echo "probe-env: $fail de $total casos falharam"; exit 1; fi
echo "probe-env: $total casos verdes"
exit 0
