#!/usr/bin/env bash
# run.sh — suíte de regressão do security-guard (decisões 4.103/4.252/4.314).
#
# Roda o hook de verdade (stdin JSON, jq, repo git sintético sem base main —
# a detecção cai no working tree e os untracked entram). Foco: o silenciador de
# ciclo formal (run-state ativo → a rede da sessão livre cala) nos DOIS layouts:
#   1. controle positivo: mudança sensível (sensitiveGlobs + conteúdo), sem
#      run-state → block;
#   2. run-state LEGADO em andamento → silêncio;
#   3. run-state na casa da sessão (thoughts/local/sessions/*/ — 4.314) → silêncio;
#   4. run-state de OUTRA sessão (4.252) → NÃO silencia, block;
#   5–7. veredito no ledger (4.365/4.378): evento `gate` do security-engineer com
#      `diff_id:` igual à identidade atual → silêncio; conteúdo editado depois do
#      veredito e veredito de outro gate → cutuca;
#   8–12. contrato da identidade do diff (4.377 — marker = `diff-facts.sh --identity`):
#      linha neutra alterada num arquivo sensível cutuca de novo mesmo com o mesmo
#      tamanho · diff idêntico silencia · alteração fora dos sensitiveGlobs não reabre ·
#      rename puro de arquivo com conteúdo sensível silencia, com e sem
#      `diff.renames=false` (rename detection fixada);
#   13–15. `diff_id:` do veredito (4.378): identidade igual cala mesmo com arquivo mais
#      novo que o evento · identidade de outro estado cutuca · evento sem `diff_id:` cai
#      no fallback por mtime;
#   16. marca do despacho (4.379): parecer registrado após a árvore mudar carrega a
#      identidade da marca e o guard cutuca;
#   17. arquivo sensível que SAI dos sensitiveGlobs cutuca como exclusão (4.380).
# Cada caso usa repo próprio (o anti-renudge de .git/ não vaza entre casos).
#
# Uso: scripts/tests/security-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/security-guard.sh"
LEDGER="$HERE/../../ledger.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "security-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

repo() { # $1 = dir — repo git com ficha e mudança sensível (glob + conteúdo)
  mkdir -p "$1/src"
  ( cd "$1" && git init -q . )
  printf '{ "sensitiveGlobs": ["src/**"] }\n' > "$1/keelson.config.json"
  printf '<?php $senha = password_hash($password, PASSWORD_ARGON2ID);\n' > "$1/src/auth.php"
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

# 1. Controle positivo: mudança sensível, sem run-state → cutuca
D1="$TMP/c1"; repo "$D1"
roda "$D1" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "positivo/decision" '"decision": "block"'
contem "positivo/gate"     'Gate de Segurança'

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

# 5. Veredito do security-engineer no ledger da sessão mais novo que os arquivos → silêncio (4.365)
D5="$TMP/c5"; repo "$D5"
touch -t 202601010000 "$D5/src/auth.php"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D5" mark gate security-engineer meu-slug >/dev/null 2>&1
printf 'APROVADO — sem achado\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D5" append gate security-engineer meu-slug >/dev/null 2>&1
roda "$D5" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "veredito-cobre-arvore"

# 6. Conteúdo sensível editado DEPOIS do veredito → identidade muda → cutuca de novo (4.378)
D6="$TMP/c6"; repo "$D6"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" mark gate security-engineer meu-slug >/dev/null 2>&1
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" append gate security-engineer meu-slug >/dev/null 2>&1
printf '<?php $senha = password_hash($outra, PASSWORD_ARGON2ID);\n' > "$D6/src/auth.php"
roda "$D6" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "pos-veredito/decision" '"decision": "block"'

# 7. Veredito de OUTRO gate (code-reviewer) não cala o security-guard
D7="$TMP/c7"; repo "$D7"
touch -t 202601010000 "$D7/src/auth.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D7" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D7" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
contem "outro-gate/decision" '"decision": "block"'

# ---- Contrato da identidade do diff (decisão 4.377) — casos 8–12 ----
P='{"stop_hook_active": false, "session_id": "sessao-eu"}'
repo_base() { # $1 dir — repo com main (commit base) e branch feature; sensitiveGlobs src/**
  mkdir -p "$1/src/auth" "$1/src/core" "$1/docs"
  ( cd "$1" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
  printf '{ "sensitiveGlobs": ["src/**"] }\n' > "$1/keelson.config.json"
  printf '<?php\n$x = 0;\n' > "$1/src/auth/login.php"
  printf '<?php $password = "x";\n' > "$1/src/core/conf.php"
  printf 'doc\n' > "$1/docs/leia.md"
  ( cd "$1" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m base && git checkout -qb feature )
}

# 8. (a) path sensível (auth/) com linha neutra: cutuca; conteúdo novo com o MESMO tamanho cutuca de novo
D8="$TMP/c8"; repo_base "$D8"
printf '<?php\n$x = 1;\n' > "$D8/src/auth/login.php"
roda "$D8" "$P"; contem "conteudo/1a-cutucada" '"decision": "block"'
printf '<?php\n$x = 2;\n' > "$D8/src/auth/login.php"
roda "$D8" "$P"; contem "conteudo/mesmo-tamanho-cutuca-de-novo" '"decision": "block"'

# 9. (b) diff idêntico → a 2ª execução silencia
D9="$TMP/c9"; repo_base "$D9"
printf '<?php\n$x = 1;\n' > "$D9/src/auth/login.php"
roda "$D9" "$P"; contem "identico/1a-cutucada" '"decision": "block"'
roda "$D9" "$P"; silencio "identico/2a-silencia"

# 10. (f) alteração fora dos sensitiveGlobs não reabre
D10="$TMP/c10"; repo_base "$D10"
printf '<?php\n$x = 1;\n' > "$D10/src/auth/login.php"
roda "$D10" "$P"; contem "escopo/1a-cutucada" '"decision": "block"'
printf 'mais doc\n' >> "$D10/docs/leia.md"
roda "$D10" "$P"; silencio "escopo/fora-nao-reabre"

# 11. (d)+(h) rename puro de arquivo com conteúdo sensível, com diff.renames=false → silêncio
#     (antes: a listagem virava D+A e o "+password" do arquivo inteiro cutucava)
D11="$TMP/c11"; repo_base "$D11"
( cd "$D11" && git config diff.renames false && git mv src/core/conf.php src/core/settings.php )
roda "$D11" "$P"; silencio "rename-puro/config-renames-false-silencia"

# 12. (d) rename puro com config default → silêncio igual
D12="$TMP/c12"; repo_base "$D12"
( cd "$D12" && git mv src/core/conf.php src/core/settings.php )
roda "$D12" "$P"; silencio "rename-puro/silencia"

# ---- diff_id do veredito (decisão 4.378) — casos 13–15 ----
# 13. Identidade igual cala MESMO com arquivo mais novo que o evento (hash vence mtime)
D13="$TMP/c13"; repo "$D13"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D13" mark gate security-engineer meu-slug >/dev/null 2>&1
ev="$(printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D13" append gate security-engineer meu-slug 2>/dev/null)"
touch -t 202601010000 "$ev"; touch "$D13/src/auth.php"
roda "$D13" "$P"; silencio "diffid/hash-vence-mtime"

# 14. Identidade de OUTRO estado cutuca mesmo com arquivo mais velho que o evento
D14="$TMP/c14"; repo "$D14"
touch -t 202601010000 "$D14/src/auth.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D14" append gate security-engineer meu-slug \
  --diff-id 0123456789abcdef0123456789abcdef01234567 >/dev/null 2>&1
roda "$D14" "$P"; contem "diffid/estado-alheio-cutuca" '"decision": "block"'

# 15. Evento legado sem diff_id → fallback por mtime: evento mais novo que os arquivos cala
D15="$TMP/c15"; repo "$D15"
touch -t 202601010000 "$D15/src/auth.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D15" append gate security-engineer meu-slug --diff-id none >/dev/null 2>&1
roda "$D15" "$P"; silencio "diffid/legado-mtime-fallback"

# 16. (P1, 4.379) marca em A, árvore vai a B, parecer de A registrado → cutuca sobre B
D16="$TMP/c16"; repo "$D16"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D16" mark gate security-engineer meu-slug >/dev/null 2>&1
printf '<?php $senha = password_hash($estadoB, PASSWORD_ARGON2ID);\n' > "$D16/src/auth.php"
printf 'APROVADO (parecer sobre A)\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D16" append gate security-engineer meu-slug >/dev/null 2>&1
roda "$D16" "$P"; contem "diffid/marca-em-A-arvore-em-B-cutuca" '"decision": "block"'

# 17. (4.380) arquivo sensível que SAI dos sensitiveGlobs é exclusão para o guard → cutuca
#     (a origem passa pelo filtro de caminho: auth/login)
D17="$TMP/c17"; repo_base "$D17"
( cd "$D17" && git mv src/auth/login.php docs/login.php )
roda "$D17" "$P"; contem "rename-sai-do-escopo/cutuca" '"decision": "block"'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "security-guard: $fail de $total casos falharam"
  exit 1
fi
echo "security-guard: $total casos verdes"
exit 0
