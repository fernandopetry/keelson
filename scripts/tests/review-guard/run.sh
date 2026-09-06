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
#   6–10. veredito no ledger (4.365/4.378): evento `gate` do code-reviewer com `diff_id:`
#      igual à identidade atual → silêncio; conteúdo editado depois do veredito, veredito
#      de outro gate, veredito de outra sessão e arquivo de código removido depois do
#      veredito → cutuca;
#   11–12. warroom (4.372): marcador `warroom.meta` DESTA sessão cala o gate 7 (a dívida
#      vai ao DEBT.md); marcador de outra sessão não cala;
#   13–22. contrato da identidade do diff (4.377 — marker = `diff-facts.sh --identity`):
#      conteúdo diferente com a mesma contagem cutuca de novo · diff idêntico silencia ·
#      untracked alterado cutuca (repo sem HEAD) · exclusão cutuca · rename puro silencia,
#      com e sem `diff.renames=false` (rename detection fixada) · rename editado cutuca ·
#      base movida reabre · alteração fora dos codePaths não reabre · mensagem sem a
#      opção do checklist e com o revisor independente;
#   23–25. `diff_id:` do veredito (4.378): identidade igual cala MESMO com arquivo mais
#      novo que o evento (hash vence mtime) · identidade de outro estado cutuca mesmo com
#      arquivo mais velho · evento legado sem `diff_id:` cai no fallback por mtime;
#   26–27. marca do despacho (4.379): parecer registrado depois de a árvore mudar carrega
#      a identidade da MARCA (estado entregue ao revisor) e o guard cutuca · registro
#      sem marca não ganha diff_id e cai no mtime.
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
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" mark gate code-reviewer meu-slug >/dev/null 2>&1
printf 'APROVADO — diff avulso\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D6" append gate code-reviewer meu-slug >/dev/null 2>&1
roda "$D6" "{\"stop_hook_active\": false, \"session_id\": \"sessao-eu\"}"
silencio "veredito-cobre-arvore"

# 7. Conteúdo de código editado DEPOIS do veredito → identidade muda → cutuca de novo (4.378)
D7="$TMP/c7"; repo "$D7"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D7" mark gate code-reviewer meu-slug >/dev/null 2>&1
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D7" append gate code-reviewer meu-slug >/dev/null 2>&1
seq 1 40 | sed 's/^/editada /' > "$D7/src/novo.php"
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

# 10. Arquivo de código removido DEPOIS do veredito → o estado revisado não é o da árvore → cutuca
D10="$TMP/c10"; repo "$D10"
( cd "$D10" && printf 'x;\n' > src/velho.php && git add src/velho.php \
  && git -c user.email=t@t -c user.name=t commit -q -m base )
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D10" mark gate code-reviewer meu-slug >/dev/null 2>&1
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D10" append gate code-reviewer meu-slug >/dev/null 2>&1
( cd "$D10" && git rm -q src/velho.php )
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

# ---- Contrato da identidade do diff (decisão 4.377) — casos 13–22 ----
w40() { seq 1 40 | sed 's/^/linha /'; }
repo_base() { # $1 dir · $2 files · $3 lines — repo com main (commit base) e branch feature
  mkdir -p "$1/src" "$1/docs"
  ( cd "$1" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
  printf '{ "codePaths": { "backend": ["src"] }, "gates": { "reviewThreshold": { "files": %s, "lines": %s } } }\n' "$2" "$3" > "$1/keelson.config.json"
  w40 > "$1/src/base.php"
  printf 'doc\n' > "$1/docs/leia.md"
  ( cd "$1" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m base && git checkout -qb feature )
}
nao_contem() {
  total=$((total + 1))
  if grep -qF -- "$2" "$TMP/out"; then
    echo "FAIL $1: saída contém [$2]"; sed 's/^/  out: /' "$TMP/out"; fail=$((fail + 1))
  else echo "ok   $1"; fi
}
P='{"stop_hook_active": false, "session_id": "sessao-eu"}'

# 13. (a) conteúdo diferente com a MESMA contagem → cutuca de novo (o fingerprint antigo calava)
D13="$TMP/c13"; repo_base "$D13" 1 1
{ w40; echo 'value = 1;'; } > "$D13/src/base.php"
roda "$D13" "$P"; contem "conteudo/1a-cutucada" '"decision": "block"'
{ w40; echo 'value = 2;'; } > "$D13/src/base.php"
roda "$D13" "$P"; contem "conteudo/mesmo-tamanho-cutuca-de-novo" '"decision": "block"'

# 14. (b) diff idêntico → a 2ª execução silencia (anti-renudge preservado)
D14="$TMP/c14"; repo_base "$D14" 1 1
{ w40; echo 'value = 1;'; } > "$D14/src/base.php"
roda "$D14" "$P"; contem "identico/1a-cutucada" '"decision": "block"'
roda "$D14" "$P"; silencio "identico/2a-silencia"

# 15. (c)+(g) untracked em repo SEM HEAD: cutuca, silencia no mesmo estado, conteúdo novo
#     com as mesmas 40 linhas cutuca de novo
D15="$TMP/c15"; repo "$D15"
roda "$D15" "$P"; contem "untracked/1a-cutucada" '"decision": "block"'
roda "$D15" "$P"; silencio "untracked/sem-head-marker-silencia"
seq 1 40 | sed 's/^/outra linha /' > "$D15/src/novo.php"
roda "$D15" "$P"; contem "untracked/conteudo-novo-cutuca" '"decision": "block"'

# 16. (d) exclusão de arquivo de código acima do limiar → cutuca
D16="$TMP/c16"; repo_base "$D16" 1 1
( cd "$D16" && git rm -q src/base.php )
roda "$D16" "$P"; contem "exclusao/cutuca" '"decision": "block"'

# 17. (d) rename puro com limiar default (2/30) → silêncio: 1 arquivo, 0 linhas
D17="$TMP/c17"; repo_base "$D17" 2 30
( cd "$D17" && git mv src/base.php src/renomeado.php )
roda "$D17" "$P"; silencio "rename-puro/silencia"

# 18. (d) rename + edição acima do limiar → cutuca (só as linhas editadas contam)
D18="$TMP/c18"; repo_base "$D18" 2 30
( cd "$D18" && git mv src/base.php src/renomeado.php )
{ w40; seq 41 80 | sed 's/^/linha /'; } > "$D18/src/renomeado.php"
roda "$D18" "$P"; contem "rename-editado/cutuca" '"decision": "block"'

# 19. (h) rename puro com diff.renames=false na config do usuário → silêncio igual
D19="$TMP/c19"; repo_base "$D19" 2 30
( cd "$D19" && git config diff.renames false && git mv src/base.php src/renomeado.php )
roda "$D19" "$P"; silencio "rename-puro/config-renames-false-silencia"

# 20. (e) base movida: cutuca, silencia, main avança fora do escopo, feature mescla → reabre
D20="$TMP/c20"; repo_base "$D20" 1 1
{ w40; echo 'value = 1;'; } > "$D20/src/base.php"
( cd "$D20" && git -c user.email=t@t -c user.name=t commit -q -am feat )
roda "$D20" "$P"; contem "base/1a-cutucada" '"decision": "block"'
roda "$D20" "$P"; silencio "base/2a-silencia"
( cd "$D20" && git checkout -q main && printf 'mais doc\n' >> docs/leia.md \
  && git -c user.email=t@t -c user.name=t commit -q -am docs && git checkout -q feature \
  && git -c user.email=t@t -c user.name=t merge -q --no-edit main )
roda "$D20" "$P"; contem "base/movida-reabre" '"decision": "block"'

# 21. (f) alteração fora do escopo do guard não reabre a cutucada
D21="$TMP/c21"; repo_base "$D21" 1 1
{ w40; echo 'value = 1;'; } > "$D21/src/base.php"
roda "$D21" "$P"; contem "escopo/1a-cutucada" '"decision": "block"'
roda "$D21" "$P"; silencio "escopo/2a-silencia"
printf 'mais doc\n' >> "$D21/docs/leia.md"
roda "$D21" "$P"; silencio "escopo/fora-nao-reabre"

# 22. Mensagem: sem a opção do checklist (sedimento da 4.15 que a 4.36 diagnosticou) e
#     com o revisor independente
D22="$TMP/c22"; repo "$D22"
roda "$D22" "$P"
nao_contem "mensagem/sem-checklist" 'aplique o checklist'
contem "mensagem/code-reviewer" 'code-reviewer'

# ---- diff_id do veredito (decisão 4.378) — casos 23–25 ----
# 23. Veredito com identidade igual cala MESMO com arquivo mais novo que o evento (hash vence mtime)
D23="$TMP/c23"; repo "$D23"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D23" mark gate code-reviewer meu-slug >/dev/null 2>&1
ev="$(printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D23" append gate code-reviewer meu-slug 2>/dev/null)"
touch -t 202601010000 "$ev"; touch "$D23/src/novo.php"
roda "$D23" "$P"; silencio "diffid/hash-vence-mtime"
grep -q '^diff_id: [0-9a-f]\{40\}$' "$ev" && { total=$((total + 1)); echo "ok   diffid/evento-medido"; } \
  || { total=$((total + 1)); echo "FAIL diffid/evento-medido: sem diff_id em $ev"; fail=$((fail + 1)); }

# 24. Veredito com identidade de OUTRO estado cutuca mesmo com arquivo mais velho que o evento
D24="$TMP/c24"; repo "$D24"
touch -t 202601010000 "$D24/src/novo.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D24" append gate code-reviewer meu-slug \
  --diff-id 0123456789abcdef0123456789abcdef01234567 >/dev/null 2>&1
roda "$D24" "$P"; contem "diffid/estado-alheio-cutuca" '"decision": "block"'

# 25. Evento legado sem diff_id → fallback por mtime: evento mais novo que os arquivos cala
D25="$TMP/c25"; repo "$D25"
touch -t 202601010000 "$D25/src/novo.php"
printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D25" append gate code-reviewer meu-slug --diff-id none >/dev/null 2>&1
roda "$D25" "$P"; silencio "diffid/legado-mtime-fallback"

# 26. (P1, 4.379) marca em A, árvore vai a B antes do registro, parecer de A registrado →
#     o evento carrega a identidade de A (da marca) e o guard cutuca sobre B
D26="$TMP/c26"; repo "$D26"
KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D26" mark gate code-reviewer meu-slug >/dev/null 2>&1
seq 1 40 | sed 's/^/estado B /' > "$D26/src/novo.php"
ev="$(printf 'APROVADO (parecer sobre A)\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D26" append gate code-reviewer meu-slug 2>/dev/null)"
roda "$D26" "$P"; contem "diffid/marca-em-A-arvore-em-B-cutuca" '"decision": "block"'
grep -q '^diff_id_nota:' "$ev" 2>/dev/null && { total=$((total + 1)); echo "ok   diffid/nota-arvore-mudou"; } \
  || { total=$((total + 1)); echo "FAIL diffid/nota-arvore-mudou: sem nota em $ev"; fail=$((fail + 1)); }

# 27. (P1) sem marca no despacho → sem diff_id → o guard cai no mtime (arquivo mais novo que o evento cutuca)
D27="$TMP/c27"; repo "$D27"
ev="$(printf 'APROVADO\n' | KEELSON_SESSAO=sessao-eu bash "$LEDGER" "$D27" append gate code-reviewer meu-slug 2>/dev/null)"
touch -t 202601010000 "$ev"; touch "$D27/src/novo.php"
roda "$D27" "$P"; contem "diffid/sem-marca-mtime-cutuca" '"decision": "block"'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "review-guard: $fail de $total casos falharam"
  exit 1
fi
echo "review-guard: $total casos verdes"
exit 0
