#!/usr/bin/env bash
# run.sh — suíte de regressão do ficha.sh (decisão 4.151).
#
# Casos inline (asserção direta, sem expected/ — as saídas são de 1–3 linhas):
# fixture "completa" cobre o caminho feliz de cada ação; "legada" cobre o atalho
# booleano do screenVerify e campos ausentes; "quebrada" cobre JSON inválido.
# O fallback jq é exercitado com um PATH sintético sem python3 (pulado com aviso
# quando não há jq no ambiente); a degradação "sem parser" usa PATH sem os dois.
#
# Uso: scripts/tests/ficha/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/../../ficha.sh"
FIX="$HERE/fixtures"

[ -f "$FICHA_SH" ] || { echo "ERRO: ficha.sh não encontrado em $FICHA_SH" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

check() { # nome exit-esperado saida-esperada -- args...
  name="$1"; wantexit="$2"; want="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  total=$((total + 1))
  got="$(bash "$FICHA_SH" "$@" 2>"$TMP/err")"
  st=$?
  if [ "$st" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $st (esperado $wantexit)"
    sed 's/^/  stderr: /' "$TMP/err"
    fail=$((fail + 1)); return
  fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $name: saída divergente"
    printf '  esperado: [%s]\n  obtido:   [%s]\n' "$want" "$got"
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

bash -n "$FICHA_SH" || { echo "FAIL bash -n ficha.sh"; exit 1; }
echo "ok   bash -n ficha.sh"

C="$FIX/completa"
L="$FIX/legada"
Q="$FIX/quebrada"

# --get: escalar, boolean, null, ausente, default, array, objeto, aninhado
check get-docsroot        0 "docs"            -- "$C" --get docsRoot
check get-quality-test    0 "composer test"   -- "$C" --get quality.test
check get-null            0 ""                -- "$C" --get quality.typecheck
check get-ausente         0 ""                -- "$C" --get quality.naoexiste
check get-default         0 "fallback"        -- "$C" --get quality.typecheck --default fallback
check get-default-vivo    0 "composer test"   -- "$C" --get quality.test --default outro
check get-bool-true       0 "true"            -- "$C" --get gates.security
check get-bool-false      0 "false"           -- "$C" --get jira.enabled
check get-array           0 "src
app"                                          -- "$C" --get codePaths.backend
check get-aninhado        0 "2"               -- "$C" --get gates.reviewThreshold.files
check get-ausente-legada  0 ""                -- "$L" --get docsRoot
check get-default-legada  0 "docs"            -- "$L" --get docsRoot --default docs

# --screen-verify: objeto completo, atalho booleano legado, campo ausente
check sv-objeto 0 "enabled=true
method=skill:screen-verify
artifactsDir=thoughts/screen-verify"          -- "$C" --screen-verify
check sv-legado-bool 0 "enabled=true
method=
artifactsDir=thoughts/screen-verify"          -- "$L" --screen-verify

# --resolve-profile: prefixo plugin:, caminho relativo, campo ausente
check prof-plugin  0 "/pr/guidelines/backend/php.md" -- "$C" --resolve-profile backend --plugin-root /pr
check prof-rel     0 "$C/guidelines/project/frontend/vue-3.md" -- "$C" --resolve-profile frontend
check prof-ausente 0 ""                       -- "$L" --resolve-profile backend

# prefixo plugin: sem plugin-root → degradado (exit 3, nunca caminho inventado)
total=$((total + 1))
if CLAUDE_PLUGIN_ROOT="" bash "$FICHA_SH" "$C" --resolve-profile backend >/dev/null 2>&1; then
  echo "FAIL prof-sem-root: exit 0 (esperado 3)"; fail=$((fail + 1))
else
  st=$?
  if [ "$st" -eq 3 ]; then echo "ok   prof-sem-root"
  else echo "FAIL prof-sem-root: exit $st (esperado 3)"; fail=$((fail + 1)); fi
fi

# degradações e uso incorreto
total=$((total + 1))
bash "$FICHA_SH" "$TMP" --get docsRoot >/dev/null 2>&1
st=$?
if [ "$st" -eq 3 ]; then echo "ok   ficha-ausente-exit-3"
else echo "FAIL ficha-ausente-exit-3: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$FICHA_SH" "$Q" --get docsRoot >/dev/null 2>&1
st=$?
if [ "$st" -eq 3 ]; then echo "ok   json-invalido-exit-3"
else echo "FAIL json-invalido-exit-3: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$FICHA_SH" "$C" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-acao-exit-2"
else echo "FAIL sem-acao-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$FICHA_SH" "$C" --get docsRoot --screen-verify >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   duas-acoes-exit-2"
else echo "FAIL duas-acoes-exit-2: exit $st"; fail=$((fail + 1)); fi

# PATH sintético: só as ferramentas que o script usa, sem python3/jq → exit 3
mkdir -p "$TMP/bin-vazio"
for t in bash sed mktemp rm; do
  src="$(command -v "$t" 2>/dev/null || true)"
  [ -n "$src" ] && ln -s "$src" "$TMP/bin-vazio/$t"
done
total=$((total + 1))
PATH="$TMP/bin-vazio" bash "$FICHA_SH" "$C" --get docsRoot >/dev/null 2>&1
st=$?
if [ "$st" -eq 3 ]; then echo "ok   sem-parser-exit-3"
else echo "FAIL sem-parser-exit-3: exit $st (esperado 3)"; fail=$((fail + 1)); fi

# fallback jq: PATH sintético com jq e sem python3 (pulado se jq não existe aqui)
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$TMP/bin-jq"
  for t in bash sed mktemp rm jq; do
    src="$(command -v "$t" 2>/dev/null || true)"
    [ -n "$src" ] && ln -s "$src" "$TMP/bin-jq/$t"
  done
  total=$((total + 1))
  got="$(PATH="$TMP/bin-jq" bash "$FICHA_SH" "$C" --get codePaths.backend 2>/dev/null)"
  if [ "$got" = "src
app" ]; then echo "ok   jq-fallback-array"
  else echo "FAIL jq-fallback-array: [$got]"; fail=$((fail + 1)); fi
  total=$((total + 1))
  got="$(PATH="$TMP/bin-jq" bash "$FICHA_SH" "$L" --screen-verify 2>/dev/null)"
  if [ "$got" = "enabled=true
method=
artifactsDir=thoughts/screen-verify" ]; then echo "ok   jq-fallback-screen-legado"
  else echo "FAIL jq-fallback-screen-legado: [$got]"; fail=$((fail + 1)); fi
else
  echo "skip jq-fallback (jq ausente neste ambiente)"
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "ficha: $fail de $total casos falharam"
  exit 1
fi
echo "ficha: $total casos verdes"
exit 0
