#!/usr/bin/env bash
# run.sh — suíte de regressão do check-mermaid.sh (contrato: cabeçalho do script, 4.248).
#
# Cinco casos, todos com o curl interceptado por shim (determinismo — a suíte nunca
# toca a rede; a integração real com o renderizador é provada pela rodada do check
# no CI, que tem rede): bloco válido renderiza ok; a classe do caso real 784ba51
# (`&quot;` no rótulo — controle positivo 4.186, o erro literal de campo) é ERRO
# offline sem gastar render; resposta 400 do renderizador é ERRO de parse; rede
# indisponível degrada com AVISO e sai 0; página sem bloco sai limpa.
#
# Uso: scripts/tests/mermaid/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../../check-mermaid.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$CHECK" ] || { echo "ERRO: check-mermaid.sh não encontrado em $CHECK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# Shim de curl: emula a invocação do check (curl -sS --max-time N -o <arquivo> -w '%{http_code}' <url>).
# Modo via KEELSON_TEST_CURL_MODE: svg → 200 com SVG · p400 → 400 com texto de parse · fail → exit 6.
mkdir -p "$TMP/shim"
cat > "$TMP/shim/curl" <<'EOF_SHIM'
#!/usr/bin/env bash
out=""
prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  prev="$a"
done
case "${KEELSON_TEST_CURL_MODE:-svg}" in
  svg)  [ -n "$out" ] && printf '<svg xmlns="http://www.w3.org/2000/svg"></svg>' > "$out"
        printf '200'; exit 0 ;;
  p400) [ -n "$out" ] && printf 'Parse error on line 2' > "$out"
        printf '400'; exit 0 ;;
  fail) exit 6 ;;
esac
EOF_SHIM
chmod +x "$TMP/shim/curl"

fail=0
total=0

runcase() { # $1 = nome do caso, $2 = fixture, $3 = exit esperado, $4 = modo do shim
  nome="$1"; fx="$2"; want="$3"; modo="$4"
  total=$((total + 1))
  tree="$TMP/$nome"
  mkdir -p "$tree"
  cp -R "$FIX/$fx/tree/." "$tree/"
  out="$(KEELSON_TEST_CURL_MODE="$modo" PATH="$TMP/shim:$PATH" bash "$CHECK" --root "$tree" 2>&1)"
  got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FALHA [$nome]: exit $got (esperado $want)" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  if ! printf '%s\n' "$out" | diff -u "$EXP/$nome.out" - >/dev/null 2>&1; then
    echo "FALHA [$nome]: saída diverge do esperado" >&2
    printf '%s\n' "$out" | diff -u "$EXP/$nome.out" - | sed 's/^/    /' >&2
    fail=$((fail + 1))
    return
  fi
  echo "ok [$nome]"
}

runcase valid       valid       0 svg
runcase entity      entity      1 svg
runcase parse-error parse-error 1 p400
runcase net-fail    net-fail    0 fail
runcase no-blocks   no-blocks   0 svg

if [ "$fail" -gt 0 ]; then
  echo "suite mermaid: $fail de $total caso(s) falharam." >&2
  exit 1
fi
echo "suite mermaid: $total caso(s) verdes."
exit 0
