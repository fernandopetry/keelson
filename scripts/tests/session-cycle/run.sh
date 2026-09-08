#!/usr/bin/env bash
# run.sh — integração do CICLO DE SESSÃO (decisão 4.387): os escritores canônicos
# (session-dir.sh, run-state.sh, ledger.sh) e os leitores (hooks wave-guard,
# review-guard, compact-anchor) encadeados numa sessão só, num repo temporário,
# como o /keelson:auto os usa. As suítes unitárias provam cada peça; aqui o que se
# prova é o ESTADO CONSISTENTE entre elas ao longo do ciclo:
#   largada  — run-state open cria a casa da sessão com o slug no manifest; o
#              wave-guard bloqueia o Stop (1× por estado);
#   promoção — init promove o run (plan/waves_total) mantendo a posse;
#   revisão  — mark do despacho → append consome a marca (diff_id); com run MEU em
#              andamento o review-guard silencia (4.252 — o gate do ciclo cobre);
#              após o close ele volta: silencia com veredito que cobre a árvore,
#              cutuca após edição posterior, silencia com novo mark+append;
#   waves    — wave-done reabre a cutucada do wave-guard (estado mudou);
#   retomada — compact-anchor (SessionStart compact) reflete slug, waves e
#              contagem do ledger da PRÓPRIA sessão;
#   fecho    — close silencia o wave-guard; archive move os eventos preservando
#              --keep; `last` ainda enxerga o arquivado; mark-reported fecha a
#              casa; gc não toca casa jovem, lista e remove a velha com --apply;
#   concorrência — archive simultâneo a append: nenhum evento se perde (o novo
#              fica ativo ou arquivado, nunca some); falha de escrita no ledger
#              → erro nomeado na hora (exit 2), sem arquivo parcial, e o append
#              seguinte funciona.
# Fronteira declarada: wave-done é read-modify-write com UM escritor por contrato
# (posse 4.251 — o Tech Lead da sessão); wave-done concorrente perde incremento e
# não é cenário do ciclo — fica fora desta suíte.
#
# Uso: scripts/tests/session-cycle/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SC="$HERE/../.."; HK="$HERE/../../../hooks"
for f in "$SC/session-dir.sh" "$SC/run-state.sh" "$SC/ledger.sh" "$SC/diff-facts.sh" "$HK/wave-guard.sh" "$HK/review-guard.sh" "$HK/compact-anchor.sh"; do
  [ -f "$f" ] || { echo "ERRO: não encontrado: $f" >&2; exit 1; }
done
command -v python3 >/dev/null 2>&1 || { echo "session-cycle: AVISO — python3 ausente (hooks degradam); pulando." >&2; exit 0; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

SID="sessaoab-1111-2222-3333"      # sid8 = sessaoab
R="$TMP/repo"; SLUG="pagamentos"; T0="2026-09-07T10:00:00-0300"
mkdir -p "$R/src"
( cd "$R" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
printf '{ "codePaths": { "backend": ["src"] }, "sensitiveGlobs": ["src/**"] }\n' > "$R/keelson.config.json"
printf 'a\n' > "$R/src/a.php"
( cd "$R" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m base && git checkout -qb feat )
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do printf 'linha %s\n' "$i" >> "$R/src/a.php"; done

# escritores: identidade da sessão pelo ambiente (o que o comando faz)
S() { env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$SID" RUN_STATE_SESSAO="$SID" bash "$@"; }
# hooks: identidade pelo payload (o que o harness faz)
H() { # hook payload → $TMP/out, $st
  printf '%s' "$2" | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO CLAUDE_PROJECT_DIR="$R" bash "$HK/$1" > "$TMP/out" 2>"$TMP/err"; st=$?
}
STOP="{\"stop_hook_active\": false, \"cwd\": \"$R\", \"session_id\": \"$SID\"}"
COMPACT="{\"source\": \"compact\", \"cwd\": \"$R\", \"session_id\": \"$SID\"}"
bloqueia() { total=$((total + 1)); if [ "$st" -eq 0 ] && grep -q '"decision": "block"' "$TMP/out"; then ok "$1"; else falha "$1: exit=$st $(head -c 300 "$TMP/out")"; fi; }
silencia() { total=$((total + 1)); if [ "$st" -eq 0 ] && [ ! -s "$TMP/out" ]; then ok "$1"; else falha "$1: exit=$st $(head -c 300 "$TMP/out")"; fi; }
contem()  { total=$((total + 1)); if grep -qF -- "$2" "$TMP/out"; then ok "$1"; else falha "$1: sem [$2] em $(head -c 300 "$TMP/out")"; fi; }

# --- largada ---
S "$SC/run-state.sh" "$R" open "$SLUG" "largada do auto" >/dev/null 2>&1
HOME_DIR="$(S "$SC/session-dir.sh" "$R" dir 2>/dev/null)"
total=$((total + 1))
if [ -d "$HOME_DIR" ] && [ -f "$HOME_DIR/run-state-$SLUG.md" ] && grep -q "^slugs: $SLUG" "$HOME_DIR/session.meta" && grep -q "^sessao: $SID" "$HOME_DIR/session.meta"; then ok open-cria-casa-com-slug-e-posse
else falha "open-cria-casa-com-slug-e-posse: $HOME_DIR $(cat "$HOME_DIR/session.meta" 2>/dev/null)"; fi
total=$((total + 1))
if grep -q '^plan: —' "$HOME_DIR/run-state-$SLUG.md" && grep -q '^waves_total: 0' "$HOME_DIR/run-state-$SLUG.md" && grep -q "^sessao: $SID" "$HOME_DIR/run-state-$SLUG.md"; then ok open-lacuna-canonica-e-posse
else falha "open-lacuna-canonica-e-posse: $(cat "$HOME_DIR/run-state-$SLUG.md")"; fi
H wave-guard.sh "$STOP"; bloqueia largada-wave-guard-bloqueia
H wave-guard.sh "$STOP"; silencia largada-mesmo-estado-nao-recutuca

# --- promoção pelo init ---
S "$SC/run-state.sh" "$R" init "$SLUG" PLAN-001 2 "wave 1 em curso" >/dev/null 2>&1
total=$((total + 1))
if grep -q '^plan: PLAN-001' "$HOME_DIR/run-state-$SLUG.md" && grep -q '^waves_total: 2' "$HOME_DIR/run-state-$SLUG.md" && grep -q '^waves_concluidas: 0' "$HOME_DIR/run-state-$SLUG.md" && grep -q "^sessao: $SID" "$HOME_DIR/run-state-$SLUG.md"; then ok init-promove-mantendo-posse
else falha "init-promove-mantendo-posse: $(cat "$HOME_DIR/run-state-$SLUG.md")"; fi
total=$((total + 1))
if [ "$(find "$R/thoughts/local/sessions" -name "run-state-*.md" | wc -l | tr -d ' ')" = "1" ]; then ok init-nao-duplica-run; else falha init-nao-duplica-run; fi
H wave-guard.sh "$STOP"; bloqueia promocao-muda-estado-recutuca

# --- revisão: mark → append → review-guard ---
LD="$(S "$SC/session-dir.sh" "$R" ledger-dir 2>/dev/null)"
H review-guard.sh "$STOP"; silencia run-meu-em-andamento-review-guard-silencia   # 4.252: o gate do ciclo cobre
mk="$(S "$SC/ledger.sh" "$R" mark gate code-reviewer "$SLUG" --ts "$T0" 2>/dev/null)"
ev1="$(printf 'APROVADO — gates 1-7 verdes\n' | S "$SC/ledger.sh" "$R" append gate code-reviewer "$SLUG" --ts "$T0" 2>/dev/null)"
total=$((total + 1))
if [ -f "$ev1" ] && [ "$(dirname "$ev1")" = "$LD" ] && grep -q '^diff_id: ' "$ev1" && [ ! -f "$mk" ]; then ok mark-consumida-diff-id-na-casa
else falha "mark-consumida-diff-id-na-casa: ev=$ev1 ld=$LD mark=$([ -f "$mk" ] && echo presente || echo ausente)"; fi
printf 'edicao pos-veredito\n' >> "$R/src/a.php"
S "$SC/ledger.sh" "$R" mark gate code-reviewer "$SLUG" --ts "2026-09-07T10:05:00-0300" >/dev/null 2>&1
ev2="$(printf 'APROVADO no retry\n' | S "$SC/ledger.sh" "$R" append gate code-reviewer "$SLUG" --ts "2026-09-07T10:05:00-0300" 2>/dev/null)"
total=$((total + 1))
if [ "$(S "$SC/ledger.sh" "$R" last gate code-reviewer 2>/dev/null)" = "$ev2" ]; then ok last-e-o-mais-recente; else falha "last-e-o-mais-recente"; fi

# --- waves ---
S "$SC/run-state.sh" "$R" wave-done "$SLUG" >/dev/null 2>&1
H wave-guard.sh "$STOP"; bloqueia wave-done-reabre-cutucada
H wave-guard.sh "$STOP"; silencia wave-done-mesmo-estado-nao-recutuca
printf 'wave 1 fechada\n' | S "$SC/ledger.sh" "$R" append marco tech-lead "$SLUG" --ts "2026-09-07T10:10:00-0300" >/dev/null 2>&1
printf 'handoff de tela pendente\n' | S "$SC/ledger.sh" "$R" append pendencia qa "$SLUG" --ts "2026-09-07T10:11:00-0300" >/dev/null 2>&1

# --- retomada pós-compactação ---
H compact-anchor.sh "$COMPACT"
contem compact-reflete-slug "slug: $SLUG"
contem compact-reflete-waves "waves_concluidas: 1"
contem compact-conta-ledger-da-sessao "4 evento(s) ativo(s)"
total=$((total + 1))
if [ "$(S "$SC/ledger.sh" "$R" count 2>/dev/null | awk '{s+=$NF} END{print s+0}')" = "4" ] || [ "$(S "$SC/ledger.sh" "$R" list 2>/dev/null | wc -l | tr -d ' ')" = "4" ]; then ok count-consistente-com-list
else falha "count-consistente-com-list: $(S "$SC/ledger.sh" "$R" count 2>/dev/null | tr '\n' ' ')"; fi

# --- fecho ---
S "$SC/run-state.sh" "$R" wave-done "$SLUG" >/dev/null 2>&1
S "$SC/run-state.sh" "$R" close "$SLUG" "Entrega concluída" >/dev/null 2>&1
H wave-guard.sh "$STOP"; silencia close-silencia-wave-guard
# run encerrado: o review-guard volta a vigiar — veredito no ledger cobre a árvore; edição posterior reabre; novo veredito fecha
H review-guard.sh "$STOP"; silencia pos-close-veredito-cobre-arvore-silencia
printf 'edicao apos o fecho\n' >> "$R/src/a.php"
H review-guard.sh "$STOP"; bloqueia pos-close-edicao-recutuca
S "$SC/ledger.sh" "$R" mark gate code-reviewer "$SLUG" --ts "2026-09-07T10:40:00-0300" >/dev/null 2>&1
ev3="$(printf 'APROVADO pos-fecho\n' | S "$SC/ledger.sh" "$R" append gate code-reviewer "$SLUG" --ts "2026-09-07T10:40:00-0300" 2>/dev/null)"
H review-guard.sh "$STOP"; silencia pos-close-novo-veredito-silencia
pend="$(S "$SC/ledger.sh" "$R" list 2>/dev/null | grep pendencia-qa)"
S "$SC/ledger.sh" "$R" archive --keep "$pend" --ts "2026-09-07T11:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
ativos="$(S "$SC/ledger.sh" "$R" list 2>/dev/null)"
arqs="$(S "$SC/ledger.sh" "$R" list --archived 2>/dev/null | wc -l | tr -d ' ')"
if [ "$ativos" = "$pend" ] && [ "$arqs" = "4" ] && [ -d "$LD/reported-20260907-110000" ]; then ok archive-preserva-pendencia
else falha "archive-preserva-pendencia: ativos=[$ativos] arquivados=$arqs"; fi
total=$((total + 1))
if [ "$(S "$SC/ledger.sh" "$R" last gate code-reviewer 2>/dev/null)" = "$LD/reported-20260907-110000/$(basename "$ev3")" ]; then ok last-enxerga-arquivado
else falha "last-enxerga-arquivado: $(S "$SC/ledger.sh" "$R" last gate code-reviewer 2>/dev/null)"; fi
H compact-anchor.sh "$COMPACT"; contem compact-pos-archive-conta-so-ativos "1 evento(s) ativo(s)"
S "$SC/run-state.sh" "$R" remove "$SLUG" >/dev/null 2>&1
S "$SC/session-dir.sh" "$R" mark-reported --ts "2026-09-07T11:30:00-0300" >/dev/null 2>&1
total=$((total + 1))
if grep -q '^estado: reportada' "$HOME_DIR/session.meta" && grep -q '^reportada_em: 2026-09-07T11:30:00-0300' "$HOME_DIR/session.meta" && [ ! -f "$HOME_DIR/run-state-$SLUG.md" ]; then ok mark-reported-fecha-casa
else falha "mark-reported-fecha-casa: $(cat "$HOME_DIR/session.meta")"; fi
H compact-anchor.sh "$COMPACT"; contem compact-sem-run-ainda-ve-ledger "1 evento(s) ativo(s)"

# --- gc: casa jovem intocada; pendência ativa segura; velha e limpa sai com --apply ---
GC() { env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="outra-sessao-9999" bash "$SC/session-dir.sh" "$R" gc "$@" 2>/dev/null; }
total=$((total + 1))
g="$(GC --ts "2026-09-08T00:00:00-0300")"
if ! printf '%s' "$g" | grep -q "^elegivel: $HOME_DIR" && printf '%s' "$g" | grep -q "^mantida: $HOME_DIR"; then ok gc-casa-jovem-mantida; else falha "gc-casa-jovem-mantida: $g"; fi
total=$((total + 1))
g="$(GC --ts "2026-10-30T00:00:00-0300")"
if printf '%s' "$g" | grep -q "^mantida: $HOME_DIR · ledger com evento ativo"; then ok gc-pendencia-ativa-segura-casa; else falha "gc-pendencia-ativa-segura-casa: $g"; fi
S "$SC/ledger.sh" "$R" archive --ts "2026-09-07T12:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
if GC --ts "2026-10-30T00:00:00-0300" | grep -q "^elegivel: $HOME_DIR · reportada há"; then ok gc-velha-e-limpa-elegivel; else falha "gc-velha-e-limpa-elegivel: $(GC --ts 2026-10-30T00:00:00-0300)"; fi
total=$((total + 1))
if [ -d "$HOME_DIR" ] && GC --ts "2026-10-30T00:00:00-0300" >/dev/null && [ -d "$HOME_DIR" ]; then ok gc-report-only-nao-remove; else falha gc-report-only-nao-remove; fi
GC --apply --ts "2026-10-30T00:00:00-0300" >/dev/null
total=$((total + 1))
if [ ! -d "$HOME_DIR" ] && [ "$(S "$SC/ledger.sh" "$R" count 2>/dev/null | wc -l | tr -d ' ')" = "0" ]; then ok gc-apply-remove-casa-e-ledger; else falha gc-apply-remove-casa-e-ledger; fi

# --- concorrência: archive simultâneo a append ---
R2="$TMP/repo2"; mkdir -p "$R2"; git -C "$R2" init -q
S2() { env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$SID" bash "$@"; }
for i in 1 2 3 4 5; do printf 'evento %s\n' "$i" | S2 "$SC/ledger.sh" "$R2" append marco tech-lead x --ts "2026-09-07T10:0$i:00-0300" >/dev/null 2>&1; done
mkfifo "$TMP/fifo-c" 2>/dev/null
if [ -p "$TMP/fifo-c" ]; then
  ( S2 "$SC/ledger.sh" "$R2" append gate qa x --ts "2026-09-07T10:09:00-0300" < "$TMP/fifo-c" > "$TMP/race-ev" 2>/dev/null ) &
  pa=$!
  sleep 0.2
  ( S2 "$SC/ledger.sh" "$R2" archive --ts "2026-09-07T11:00:00-0300" >/dev/null 2>&1 ) &
  pb=$!
  printf 'corpo do evento em corrida\n' > "$TMP/fifo-c"
  wait "$pa" "$pb"
  LD2="$(S2 "$SC/session-dir.sh" "$R2" ledger-dir 2>/dev/null)"
  nact="$(S2 "$SC/ledger.sh" "$R2" list 2>/dev/null | wc -l | tr -d ' ')"
  narq="$(S2 "$SC/ledger.sh" "$R2" list --archived 2>/dev/null | wc -l | tr -d ' ')"
  total=$((total + 1))
  if [ "$((nact + narq))" = "6" ] && [ "$(find "$LD2" -name '*-gate-qa*.md' | wc -l | tr -d ' ')" = "1" ] && grep -qx 'corpo do evento em corrida' "$(find "$LD2" -name '*-gate-qa*.md')"; then ok archive-concorrente-nao-perde-evento
  else falha "archive-concorrente-nao-perde-evento: ativos=$nact arquivados=$narq"; fi
else
  echo "ok   archive-concorrente (mkfifo indisponível — pulado)"
fi

# --- falha de escrita: erro nomeado, sem parcial, retomada limpa ---
if [ "$(id -u)" != "0" ]; then
  R3="$TMP/repo3"; mkdir -p "$R3"; git -C "$R3" init -q
  printf 'primeiro\n' | S2 "$SC/ledger.sh" "$R3" append marco tech-lead x --ts "$T0" >/dev/null 2>&1
  LD3="$(S2 "$SC/session-dir.sh" "$R3" ledger-dir 2>/dev/null)"
  chmod 555 "$LD3"
  out="$(printf 'segundo\n' | S2 "$SC/ledger.sh" "$R3" append marco tech-lead x --ts "2026-09-07T10:01:00-0300" 2>&1 >/dev/null)"; st=$?
  chmod 755 "$LD3"
  total=$((total + 1))
  if [ "$st" -eq 2 ] && printf '%s' "$out" | grep -q 'não consegui escrever' && [ "$(find "$LD3" -name '*.md' | wc -l | tr -d ' ')" = "1" ]; then ok falha-de-escrita-erro-nomeado-sem-parcial
  else falha "falha-de-escrita-erro-nomeado-sem-parcial: exit=$st [$out] arquivos=$(find "$LD3" -name '*.md' | wc -l)"; fi
  total=$((total + 1))
  f3="$(printf 'terceiro\n' | S2 "$SC/ledger.sh" "$R3" append marco tech-lead x --ts "2026-09-07T10:02:00-0300" 2>/dev/null)"
  if [ -f "$f3" ] && grep -qx terceiro "$f3"; then ok retomada-apos-falha-de-escrita; else falha "retomada-apos-falha-de-escrita: [$f3]"; fi
else
  echo "ok   falha-de-escrita (root ignora permissão — pulado)"
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "session-cycle: $fail de $total casos falharam"
  exit 1
fi
echo "session-cycle: $total casos verdes"
exit 0
