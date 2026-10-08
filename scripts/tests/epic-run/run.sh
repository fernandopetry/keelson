#!/usr/bin/env bash
# run.sh — suíte de regressão do epic-run.sh (decisão 4.465).
#
# Roda o motor de verdade contra um repositório sintético com BRIEF épico, com um
# `claude` FALSO no PATH (script que registra argv + ambiente e, conforme FAKE_MODE,
# marca a próxima fatia da fila como entregue, trava, ou demora). Casos:
#   1. bash -n;
#   2. pré-voo recusa: estratégia por-fatia · árvore suja · claude ausente ·
#      thoughts/ não ignorado · fila já toda entregue · driver vivo;
#   3. dry-run não escreve nada;
#   4. revezamento completo: 3 fatias → fim "fila toda entregue", 3 invocações, RESUMO
#      com 3 seções, ambiente do filho LIMPO (ENTRYPOINT/SESSION_ID herdados não chegam),
#      flags obrigatórias presentes, status "parado";
#   5. fatia que não avança → fim "fatia 1 não avançou", 1 invocação só;
#   6. --max-fatias 1 → para no teto com a 2ª ainda pendente;
#   7. status durante a execução ("rodando · fatia 1") e stop → "pedido do Diretor",
#      filho morto, segundo launch recusado enquanto vivo e aceito depois.
#
# Uso: scripts/tests/epic-run/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX

HERE="$(cd "$(dirname "$0")" && pwd)"
ER="$HERE/../../epic-run.sh"
[ -f "$ER" ] || { echo "ERRO: epic-run.sh não encontrado" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
# shellcheck disable=SC2329  # invocada pelo trap
cleanup() { pkill -f "epic-run.sh $TMP" 2>/dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

fail=0; total=0
ok()   { total=$((total + 1)); echo "ok   $1"; }
bad()  { total=$((total + 1)); fail=$((fail + 1)); echo "FAIL $1"; [ $# -gt 1 ] && printf '%s\n' "$2" | sed 's/^/  /'; }
contem() { # nome texto esperado
  case "$2" in *"$3"*) ok "$1" ;; *) bad "$1: sem [$3]" "$2" ;; esac
}
nao_contem() {
  case "$2" in *"$3"*) bad "$1: contém [$3] e não devia" "$2" ;; *) ok "$1" ;; esac
}
espera_fim() { # dir [segundos] → 0 quando fim.txt existe
  i=0; while [ ! -f "$1/fim.txt" ] && [ "$i" -lt "${2:-60}" ]; do sleep 1; i=$((i + 1)); done
  [ -f "$1/fim.txt" ]
}

# ---------- claude falso ----------
BIN="$TMP/bin"; mkdir -p "$BIN"
cat > "$BIN/claude" <<'SH'
#!/usr/bin/env bash
# claude FALSO: registra argv e ambiente; conforme FAKE_MODE, avança a fila do BRIEF.
{
  printf 'argv:'; for a in "$@"; do printf ' [%s]' "$a"; done; printf '\n'
  printf 'env: EP=%s SID=%s CHILD=%s\n' "${CLAUDE_CODE_ENTRYPOINT-unset}" "${CLAUDE_CODE_SESSION_ID-unset}" "${CLAUDE_CODE_CHILD_SESSION-unset}"
} >> "$FAKE_LOG"
printf '{"type":"system","subtype":"init","session_id":"fake-%s"}\n' "$$"
printf '{"type":"assistant","message":{"content":[{"type":"text","text":"Entrega da fatia (fake %s)"}]}}\n' "$$"
case "${FAKE_MODE:-advance}" in
  stall) : ;;
  slow) sleep "${FAKE_SLEEP:-6}"; sed -i.bak '0,/| pendente |/s//| entregue (2026-10-08) |/' "$FAKE_BRIEF" 2>/dev/null || perl -0pi -e 's/\| pendente \|/| entregue (2026-10-08) |/' "$FAKE_BRIEF"; rm -f "$FAKE_BRIEF.bak" ;;
  *) perl -0pi -e 's/\| pendente \|/| entregue (2026-10-08) |/' "$FAKE_BRIEF" ;;
esac
printf '{"type":"result","session_id":"fake-%s","total_cost_usd":0.01,"duration_ms":10}\n' "$$"
exit 0
SH
chmod +x "$BIN/claude"
export FAKE_LOG="$TMP/fake.log"

# ---------- repositório sintético ----------
mkrepo() { # nome [estrategia] → ecoa raiz; fila com 3 fatias pendentes
  r="$TMP/$1"; mkdir -p "$r/docs/anc/briefs"
  {
    printf '# BRIEF épico: Plataforma\n\n**Slug**: anc\n**Status**: Emitido\n**Branch**: feat/anc-plataforma\n**Estratégia**: %s\n\n## Fila\n\n' "${2:-unica}"
    printf '| # | Fatia | Slug de destino | Estado |\n|---|---|---|---|\n'
    printf '| 1 | Login | anc | pendente |\n| 2 | Relatórios | anc | pendente |\n| 3 | Exportação | anc | pendente |\n'
  } > "$r/docs/anc/briefs/BRIEF-2026-10-08-plataforma-epic.md"
  printf 'thoughts/\n' > "$r/.gitignore"
  ( cd "$r" && git init -q && git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m init )
  printf '%s\n' "$r"
}
BRIEF_REL="docs/anc/briefs/BRIEF-2026-10-08-plataforma-epic.md"

bash -n "$ER" && ok "bash -n epic-run.sh" || bad "bash -n epic-run.sh"

# ---------- 2. pré-voo ----------
R="$(mkrepo pf-estrategia por-fatia)"
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 3 ] && ok "pré-voo/por-fatia exit 3" || bad "pré-voo/por-fatia exit $st" "$out"
contem "pré-voo/por-fatia motivo" "$out" "exige \`unica\`"

R="$(mkrepo pf-suja)"; echo x > "$R/sujo.txt"
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 3 ] && ok "pré-voo/árvore-suja exit 3" || bad "pré-voo/árvore-suja exit $st" "$out"
contem "pré-voo/árvore-suja motivo" "$out" "árvore suja"

R="$(mkrepo pf-semclaude)"
out="$(PATH="/usr/bin:/bin" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 3 ] && ok "pré-voo/claude-ausente exit 3" || bad "pré-voo/claude-ausente exit $st" "$out"
contem "pré-voo/claude-ausente motivo" "$out" "ausente no PATH"

R="$(mkrepo pf-ignore)"; : > "$R/.gitignore"; ( cd "$R" && git -c user.email=t@t -c user.name=t commit -qam "sem ignore" )
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 3 ] && ok "pré-voo/thoughts-não-ignorado exit 3" || bad "pré-voo/thoughts-não-ignorado exit $st" "$out"
contem "pré-voo/thoughts-não-ignorado motivo" "$out" ".gitignore"

R="$(mkrepo pf-entregue)"; perl -0pi -e 's/\| pendente \|/| entregue (2026-10-01) |/g' "$R/$BRIEF_REL"; ( cd "$R" && git -c user.email=t@t -c user.name=t commit -qam "entregue" )
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 3 ] && ok "pré-voo/fila-entregue exit 3" || bad "pré-voo/fila-entregue exit $st" "$out"
contem "pré-voo/fila-entregue motivo" "$out" "regra 6"

# ---------- 3. dry-run ----------
R="$(mkrepo dry)"
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st=$?
[ "$st" -eq 0 ] && ok "dry-run exit 0" || bad "dry-run exit $st" "$out"
contem "dry-run/próxima" "$out" "próxima fatia 1 (Login → anc)"
[ ! -d "$R/thoughts" ] && ok "dry-run não escreve" || bad "dry-run escreveu thoughts/"

# ---------- 4. revezamento completo ----------
R="$(mkrepo full)"; : > "$FAKE_LOG"
export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(CLAUDE_CODE_ENTRYPOINT=claude-desktop CLAUDE_CODE_SESSION_ID=pai-1234 FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 0 ] && ok "full/launch exit 0" || bad "full/launch exit $st" "$out"
contem "full/launch ecoa" "$out" "revezamento: lançado"
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "full/fim.txt existe" || bad "full/fim.txt não apareceu em 60 s" "$(cat "$D/launch.log" 2>/dev/null)"
fim="$(cat "$D/fim.txt" 2>/dev/null)"
contem "full/motivo" "$fim" "fila toda entregue"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "3" ] && ok "full/3 invocações" || bad "full/invocações = $n" "$(cat "$FAKE_LOG")"
n="$(grep -c '^## Fatia ' "$D/RESUMO.md" 2>/dev/null)"; [ "$n" = "3" ] && ok "full/RESUMO 3 seções" || bad "full/RESUMO seções = $n"
contem "full/RESUMO texto" "$(cat "$D/RESUMO.md")" "Entrega da fatia (fake"
log="$(cat "$FAKE_LOG")"
contem "full/env limpo EP" "$log" "EP=unset"
contem "full/env limpo SID" "$log" "SID=unset"
nao_contem "full/env sem herança" "$log" "claude-desktop"
contem "full/flag -p" "$log" "[-p] [/keelson:continue anc"
contem "full/flag stream-json" "$log" "[stream-json]"
contem "full/flag permissão" "$log" "[--dangerously-skip-permissions]"
contem "full/prompt nomeia o modo" "$log" "não tem humano interativo"
st_out="$(bash "$ER" "$R" status anc)"
contem "full/status parado" "$st_out" "revezamento: parado — fila toda entregue"
[ ! -f "$D/driver.pid" ] && ok "full/driver.pid removido" || bad "full/driver.pid ficou"
grep -q "| 3 | Exportação | anc | entregue" "$R/$BRIEF_REL" && ok "full/fila avançou até a 3" || bad "full/fila não avançou" "$(cat "$R/$BRIEF_REL")"

# ---------- 5. fatia que não avança ----------
R="$(mkrepo stall)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=stall PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "stall/fim.txt existe" || bad "stall/fim.txt não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "stall/motivo" "$(cat "$D/fim.txt" 2>/dev/null)" "fatia 1 não avançou (exit 0)"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "1" ] && ok "stall/1 invocação só" || bad "stall/invocações = $n"
contem "stall/status" "$(bash "$ER" "$R" status anc)" "parado — fatia 1 não avançou"

# ---------- 6. teto de fatias ----------
R="$(mkrepo teto)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --max-fatias 1)"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "teto/fim.txt existe" || bad "teto/fim.txt não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "teto/motivo" "$(cat "$D/fim.txt" 2>/dev/null)" "teto de fatias (1) atingido — próxima pendente: 2"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "1" ] && ok "teto/1 invocação" || bad "teto/invocações = $n"

# ---------- 7. status em voo, stop, relançar ----------
R="$(mkrepo slow)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=slow FAKE_SLEEP=20 PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
D="$R/thoughts/local/epic-run/anc"
sleep 3
st_out="$(bash "$ER" "$R" status anc)"
contem "slow/status rodando" "$st_out" "revezamento: rodando · fatia 1 (Login)"
contem "slow/status forja" "$st_out" "· forja ·"
out2="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st2=$?
[ "$st2" -eq 3 ] && ok "slow/relançar recusado em voo" || bad "slow/relançar exit $st2" "$out2"
contem "slow/relançar motivo" "$out2" "já em curso"
filho="$(awk -F'\t' '$1=="filho_pid"{print $2}' "$D/status.tsv")"
out3="$(bash "$ER" "$R" stop anc)"
contem "slow/stop ecoa" "$out3" "pedido do Diretor"
sleep 1
if [ -n "$filho" ] && kill -0 "$filho" 2>/dev/null; then bad "slow/filho ainda vivo ($filho)"; else ok "slow/filho morto"; fi
contem "slow/status parado" "$(bash "$ER" "$R" status anc)" "parado — pedido do Diretor"
out4="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st4=$?
[ "$st4" -eq 0 ] && ok "slow/relançar aceito depois do stop" || bad "slow/relançar depois exit $st4" "$out4"
contem "nenhum/status" "$(bash "$ER" "$R" status outro 2>/dev/null)" "nenhum revezamento"

if [ "$fail" -gt 0 ]; then echo "epic-run: $fail/$total asserções falharam"; exit 1; fi
echo "epic-run: $total asserções ok"
exit 0
