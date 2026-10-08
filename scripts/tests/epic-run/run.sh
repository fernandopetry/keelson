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
#   7. status durante a execução ("rodando · fatia 1"), stop gracioso (fatia em curso
#      entrega, próxima não lança) e stop --now (filho morto na hora); segundo launch
#      recusado enquanto vivo e aceito depois;
#   8. (4.466) fatia parcial RETOMÁVEL: em ciclo + run-state `encerrado — pausa` → launch
#      aceito, a sessão filha retoma e a fila avança (progresso = fila mudou);
#   9. (4.466) fatia parcial `encerrado — aguarda Diretor` → exit 5, classe aguarda-diretor;
#  10. (4.466) run em_andamento de dona MORTA (casa parada há 2 h, sem processo) → aceito;
#      dona possivelmente viva (casa tocada agora) → exit 6 posse-incerta; --force-claim
#      aceita e o prompt leva a confirmação (FORCE=1);
#  11. (4.466) falha de infraestrutura (saída ≠ 0, sem result) → nova tentativa após a
#      espera, teto por --retry; parada por decisão (saída 0 + result, fila parada) → não insiste;
#  12. (4.467) --notify: KEELSON_NOTIFY_CMD recebe (título, mensagem) no fim de cada fatia
#      e na parada; sem a flag, nenhuma chamada;
#  13. (4.467) watch: feed ao vivo imprime a fatia, a sessão filha, o texto do Tech Lead e
#      a parada, e sai sozinho; sem evento acima de --stale-min avisa POSSÍVEL TRAVAMENTO.
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
# shellcheck disable=SC2317,SC2329  # invocada só pelo trap (SC2317 no shellcheck do CI, SC2329 no 0.11)
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
avanca() { perl -0pi -e 's/\| (pendente|em ciclo \([^)]*\)) \|/| entregue (2026-10-08) |/' "$FAKE_BRIEF"; }
case "${FAKE_MODE:-advance}" in
  stall) : ;;                      # saída 0 + result, fila parada = parada por decisão
  fail) exit 1 ;;                  # saída ≠ 0, sem result = infraestrutura
  slow) sleep "${FAKE_SLEEP:-6}"; avanca ;;
  *) avanca ;;
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
contem "stall/motivo" "$(cat "$D/fim.txt" 2>/dev/null)" "fatia 1 não avançou (exit 0) — parada por decisão"
contem "stall/status mostra relatório" "$(bash "$ER" "$R" status anc)" "último relatório (fatia 1"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "1" ] && ok "stall/1 invocação só" || bad "stall/invocações = $n"
contem "stall/status" "$(bash "$ER" "$R" status anc)" "parado — fatia 1 não avançou"

# ---------- 6. teto de fatias ----------
R="$(mkrepo teto)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --max-fatias 1)"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "teto/fim.txt existe" || bad "teto/fim.txt não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "teto/motivo" "$(cat "$D/fim.txt" 2>/dev/null)" "teto de fatias (1) atingido — próxima: 2"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "1" ] && ok "teto/1 invocação" || bad "teto/invocações = $n"

# ---------- 7. status em voo, stop, relançar ----------
R="$(mkrepo slow)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=slow FAKE_SLEEP=20 PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
D="$R/thoughts/local/epic-run/anc"
sleep 3
st_out="$(bash "$ER" "$R" status anc)"
contem "slow/status rodando" "$st_out" "revezamento: rodando · fatia 1 (Login · nova)"
contem "slow/status forja" "$st_out" "· forja ·"
out2="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st2=$?
[ "$st2" -eq 3 ] && ok "slow/relançar recusado em voo" || bad "slow/relançar exit $st2" "$out2"
contem "slow/relançar motivo" "$out2" "já em curso"
out3="$(bash "$ER" "$R" stop anc)"
contem "slow/stop gracioso ecoa" "$out3" "revezamento: parando"
contem "slow/status parando" "$(bash "$ER" "$R" status anc)" "PARANDO após esta fatia"
espera_fim "$D" 60 && ok "slow/fim após a fatia em curso" || bad "slow/fim não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "slow/motivo gracioso" "$(cat "$D/fim.txt" 2>/dev/null)" "pedido do Diretor (stop) — após a fatia 1; próxima: 2"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "1" ] && ok "slow/só 1 fatia rodou" || bad "slow/invocações = $n"
grep -q "| 1 | Login | anc | entregue" "$R/$BRIEF_REL" && ok "slow/fatia 1 entregue antes de parar" || bad "slow/fatia 1 não entregou"
grep -q "| 2 | Relatórios | anc | pendente" "$R/$BRIEF_REL" && ok "slow/fatia 2 ficou pendente" || bad "slow/fatia 2 mudou"
# --now: relança (a Entrega real commita o BRIEF; o claude falso não — commita aqui) e mata na hora
( cd "$R" && git -c user.email=t@t -c user.name=t commit -qam "fatia 1 (fake)" )
: > "$FAKE_LOG"
out="$(FAKE_MODE=slow FAKE_SLEEP=20 PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 0 ] && ok "now/relançado" || bad "now/relançar exit $st" "$out"
sleep 3
filho="$(awk -F'\t' '$1=="filho_pid"{print $2}' "$D/status.tsv")"
out3="$(bash "$ER" "$R" stop anc --now)"
contem "now/stop ecoa" "$out3" "pedido do Diretor"
sleep 1
if [ -n "$filho" ] && kill -0 "$filho" 2>/dev/null; then bad "now/filho ainda vivo ($filho)"; else ok "now/filho morto"; fi
contem "now/status parado" "$(bash "$ER" "$R" status anc)" "parado — pedido do Diretor (stop --now)"
( cd "$R" && git -c user.email=t@t -c user.name=t commit -qam "fatia (fake)" >/dev/null 2>&1 || true )
out4="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st4=$?
[ "$st4" -eq 0 ] && ok "slow/relançar aceito depois do stop" || bad "slow/relançar depois exit $st4" "$out4"
contem "nenhum/status" "$(bash "$ER" "$R" status outro 2>/dev/null)" "nenhum revezamento"

# ---------- 8–10. fatia parcial (4.466) ----------
mkparcial() { # nome → raiz com fatia 1 em ciclo (brief filho + PLAN + TASKs Done/Todo), commitada
  r="$(mkrepo "$1")"
  perl -0pi -e 's/\| 1 \| Login \| anc \| pendente \|/| 1 | Login | anc | em ciclo (docs\/anc\/briefs\/BRIEF-002.md) |/' "$r/$BRIEF_REL"
  d="$r/docs/anc"; mkdir -p "$d/plans" "$d/tasks"
  printf '# BRIEF-002: Login\n\n**Slug**: anc\n**Status**: Emitido\n**SPEC**: SPEC-002\n' > "$d/briefs/BRIEF-002.md"
  printf '# PLAN-002: Login\n\n**Status**: Approved\n\n## Cobertura\n\n**SPEC referenciada**: SPEC-002\n' > "$d/plans/PLAN-002-login.md"
  printf '# TASK-002-001: T1\n\n**Status**: Done\n' > "$d/tasks/TASK-002-001-t.md"
  printf '# TASK-002-002: T2\n\n**Status**: Todo\n' > "$d/tasks/TASK-002-002-t.md"
  ( cd "$r" && git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m "parcial" )
  printf '%s\n' "$r"
}
mkrun() { # raiz sid status-linha → casa de sessão com run-state do slug anc
  c="$1/thoughts/local/sessions/20261008-090000-$2"; mkdir -p "$c"
  printf 'sessao: %s\niniciada: 2026-10-08T09:00:00-0300\nestado: ativa\nslugs: anc\n' "$2" > "$c/session.meta"
  printf 'status: %s\nslug: anc\nplan: PLAN-002\nwaves_concluidas: 1\nwaves_total: 2\nretomada: wave 2\nsessao: %s\n' "$3" "$2" > "$c/run-state-anc.md"
  printf '%s\n' "$c"
}
export RUN_STATE_SESSAO="lancador-1"

# 8. pausa dentro da sessão da fatia → retomável; a filha avança a fila (em ciclo → entregue)
R="$(mkparcial p8)"; mkrun "$R" "sess-pausa" "encerrado — pausa: TASK-002-001 closure (wave 1 de 2)" >/dev/null
: > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st=$?
[ "$st" -eq 0 ] && ok "parcial-pausa/dry-run aceito" || bad "parcial-pausa/dry-run exit $st" "$out"
contem "parcial-pausa/retomar" "$out" "retomar fatia 1 (Login → anc)"
contem "parcial-pausa/motivo" "$out" "encerrado — pausa"
out="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "parcial-pausa/fim.txt existe" || bad "parcial-pausa/fim não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "parcial-pausa/fila toda entregue" "$(cat "$D/fim.txt" 2>/dev/null)" "fila toda entregue"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "3" ] && ok "parcial-pausa/3 sessões (1 retomada + 2 novas)" || bad "parcial-pausa/invocações = $n" "$(cat "$FAKE_LOG")"
contem "parcial-pausa/modo no status.tsv" "$(cat "$D/launch.log")" "retomada · tentativa 1"

# 9. aguarda Diretor → exit 5
R="$(mkparcial p9)"; mkrun "$R" "sess-ag" "encerrado — aguarda Diretor: parte estacionada que a fatia 2 consome" >/dev/null
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL")"; st=$?
[ "$st" -eq 5 ] && ok "aguarda/exit 5" || bad "aguarda/exit $st" "$out"
contem "aguarda/classe" "$out" "pré-voo: aguarda-diretor"
contem "aguarda/aponta continue" "$out" "retome pelo /keelson:continue anc com você presente"
[ ! -d "$R/thoughts/local/epic-run" ] && ok "aguarda/nada escrito" || bad "aguarda/escreveu"

# 10. run em_andamento: dona morta (casa parada há 2 h) → aceito; dona recente → posse-incerta; --force-claim → aceito
R="$(mkparcial p10)"; c="$(mkrun "$R" "sess-morta" "em_andamento")"
find "$c" -type f -exec touch -t "$(date -v-2H +%Y%m%d%H%M 2>/dev/null || date -d '2 hours ago' +%Y%m%d%H%M)" {} +
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st=$?
[ "$st" -eq 0 ] && ok "dona-morta/aceito" || bad "dona-morta/exit $st" "$out"
contem "dona-morta/motivo" "$out" "run em andamento de sessão morta"
touch "$c/run-state-anc.md"
out="$(PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --dry-run)"; st=$?
[ "$st" -eq 6 ] && ok "dona-viva/exit 6" || bad "dona-viva/exit $st" "$out"
contem "dona-viva/classe" "$out" "pré-voo: posse-incerta"
: > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --force-claim --max-fatias 1)"; st=$?
[ "$st" -eq 0 ] && ok "force-claim/aceito" || bad "force-claim/exit $st" "$out"
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "force-claim/fim" || bad "force-claim/fim não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "force-claim/prompt leva FORCE=1" "$(cat "$FAKE_LOG")" "use FORCE=1 no claim"

# 11. infraestrutura: nova tentativa após a espera, teto por --retry; decisão não insiste
R="$(mkrepo infra)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=fail PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --retry 1 --retry-wait-sec 1)"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 90 && ok "infra/fim.txt existe" || bad "infra/fim não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
contem "infra/motivo" "$(cat "$D/fim.txt" 2>/dev/null)" "fatia 1 falhou 2 vez(es) por infraestrutura (último exit 1)"
n="$(grep -c '^argv:' "$FAKE_LOG")"; [ "$n" = "2" ] && ok "infra/2 tentativas" || bad "infra/invocações = $n"
contem "infra/log da espera" "$(cat "$D/launch.log")" "nova tentativa 2/2 em 1s"

# ---------- 12. --notify (4.467) ----------
cat > "$BIN/notify-fake" <<'SH'
#!/usr/bin/env bash
printf '%s|%s\n' "$1" "$2" >> "$NOTIFY_LOG"
SH
chmod +x "$BIN/notify-fake"
export NOTIFY_LOG="$TMP/notify.log"; : > "$NOTIFY_LOG"
R="$(mkrepo notify)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(KEELSON_NOTIFY_CMD="$BIN/notify-fake" FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --notify)"; st=$?
D="$R/thoughts/local/epic-run/anc"
espera_fim "$D" 60 && ok "notify/fim" || bad "notify/fim não apareceu" "$(cat "$D/launch.log" 2>/dev/null)"
n="$(grep -c 'entregue — fila avançou' "$NOTIFY_LOG")"; [ "$n" = "3" ] && ok "notify/3 fatias notificadas" || bad "notify/entregues = $n" "$(cat "$NOTIFY_LOG")"
contem "notify/parada notificada" "$(cat "$NOTIFY_LOG")" "revezamento parado — fila toda entregue"
contem "notify/título" "$(cat "$NOTIFY_LOG")" "keelson · anc|"
: > "$NOTIFY_LOG"
R="$(mkrepo nonotify)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(KEELSON_NOTIFY_CMD="$BIN/notify-fake" FAKE_MODE=advance PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --max-fatias 1)"; st=$?
D="$R/thoughts/local/epic-run/anc"; espera_fim "$D" 60 >/dev/null
[ ! -s "$NOTIFY_LOG" ] && ok "notify/sem flag não notifica" || bad "notify/notificou sem flag" "$(cat "$NOTIFY_LOG")"

# ---------- 13. watch (4.467) ----------
R="$(mkrepo watch)"; : > "$FAKE_LOG"; export FAKE_BRIEF="$R/$BRIEF_REL"
out="$(FAKE_MODE=slow FAKE_SLEEP=65 PATH="$BIN:$PATH" bash "$ER" "$R" launch "$BRIEF_REL" --max-fatias 1)"; st=$?
D="$R/thoughts/local/epic-run/anc"
sleep 2
bash "$ER" "$R" watch anc --heartbeat-sec 1 --stale-min 1 > "$TMP/watch.out" 2>&1 &
WPID=$!
espera_fim "$D" 120 >/dev/null
i=0; while kill -0 "$WPID" 2>/dev/null && [ "$i" -lt 15 ]; do sleep 1; i=$((i + 1)); done
if kill -0 "$WPID" 2>/dev/null; then bad "watch/não saiu sozinho" "$(cat "$TMP/watch.out")"; kill "$WPID" 2>/dev/null; else ok "watch/saiu ao parar"; fi
w="$(cat "$TMP/watch.out")"
contem "watch/cabeçalho" "$w" "watch - revezamento de anc"
contem "watch/fatia" "$w" "== fatia 1 (Login - nova)"
contem "watch/sessão filha" "$w" "sessao filha fake-"
contem "watch/texto do TL" "$w" "TL: Entrega da fatia (fake"
contem "watch/batimento" "$w" "... sem evento ha"
contem "watch/travamento" "$w" "!! POSSIVEL TRAVAMENTO: sem evento ha 1min - filho pid"
contem "watch/parada" "$w" "= revezamento parado - teto de fatias (1) atingido"
contem "nenhum/watch" "$(bash "$ER" "$R" watch outro 2>/dev/null)" "nenhum revezamento"

if [ "$fail" -gt 0 ]; then echo "epic-run: $fail/$total asserções falharam"; exit 1; fi
echo "epic-run: $total asserções ok"
exit 0
