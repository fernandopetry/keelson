#!/usr/bin/env bash
# epic-run.sh — revezamento das fatias de um BRIEF épico sem o Diretor entre elas
# (decisão 4.465). Motor do /keelson:auto-epic: cada fatia roda num processo
# `claude -p` próprio (contexto limpo, sessão própria), lendo o estado do disco pelo
# /keelson:continue; a fila do BRIEF épico é o único fato que decide a próxima.
#
# Uso: epic-run.sh <raiz> launch <BRIEF-epico> [--max-fatias N] [--timeout-min M]
#                                              [--model M] [--dry-run] [-- <args extras ao claude>]
#      epic-run.sh <raiz> status <slug-ancora>
#      epic-run.sh <raiz> stop   <slug-ancora>
#
#   launch   pré-voo mecânico (toda recusa é exit 3 com o motivo em stdout; nada é escrito):
#            BRIEF existe · estratégia `unica` (por-fatia depende de merge do Diretor,
#            4.190) · `epic-state.sh` na regra 4 (fatia entregue/nenhuma + próxima
#            pendente; qualquer outra regra ou `aviso` recusa, com o rótulo) · árvore limpa
#            (`git status --porcelain` vazio) · `claude` no PATH · `thoughts/` ignorado
#            (`git check-ignore`, 4.51) · nenhum run-state `em_andamento` do slug de
#            destino em casa alguma · nenhum driver vivo para o épico. Passou → cria
#            thoughts/local/epic-run/<slug-ancora>/ (driver.pid, status.tsv, launch.log)
#            e lança o laço DESACOPLADO (nohup + subshell: sobrevive ao fim do turno e ao
#            fechamento da janela que o lançou). Ecoa `revezamento: lançado · pid · dir`.
#            --dry-run só imprime o pré-voo e a próxima fatia.
#   _loop    (interno) por fatia: `claude -p "/keelson:continue <slug> …"` com
#            --output-format stream-json e o modo de permissão decidido pelo Diretor na
#            4.465 (sem prompts: a sessão filha não tem quem os responda) e ambiente
#            LIMPO — `env -u CLAUDE_CODE_ENTRYPOINT …`: o filho nasce `sdk-cli` (sinal da
#            sessão sem humano, 4.439) com id de sessão próprio; herdado, ele nasce com o
#            entrypoint da sessão-mãe e a guarda não arma. Saída em fatia-N.stream.jsonl;
#            texto do assistente em fatia-N.result.txt (python3; ausente, declarado) e
#            anexado ao RESUMO.md — é o resumo que a próxima retomada humana lê. Depois
#            de cada fatia relê a fila: a mesma fatia ainda pendente → `fatia N não
#            avançou` (escalação, degrau 3 ou falha — o motivo está no run-state/ledger
#            da sessão filha); regra 6 → `fila toda entregue`; 5 → `aguardando-produto`;
#            outra/aviso → rótulo. --max-fatias N para no teto; --timeout-min M mata a
#            fatia que passar do teto (0 = sem teto).
#            Fim: fim.txt (`<ts>\t<motivo>`), status.tsv `estado parado`, driver.pid removido.
#   status   uma linha: `revezamento: rodando · fatia N (<título>) · iniciada <ts> · último
#            evento há <M> min · wave X/Y` (wave do run-state em_andamento do slug de
#            destino, em qualquer casa; sem run → `forja`) · ou `revezamento: parado —
#            <motivo> (<ts>)` · ou `nenhum revezamento`. Linhas seguintes: dir e RESUMO.
#   stop     encerra o filho em voo e o driver; grava `pedido do Diretor` como motivo. A
#            fatia interrompida fica como o /keelson:continue a encontrar (run-state da
#            sessão filha, closures commitadas).
#
# Vocabulário da fila NUNCA muda (4.156): o motivo de parada vive aqui e no run-state,
# nunca num estado novo na tabela do BRIEF.
# Exit: 0 ok · 2 uso incorreto · 3 pré-voo recusou · 4 nada em andamento (status/stop).
# Bash 3.2-compatível; python3 opcional (extração do texto).

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ES="$HERE/epic-state.sh"
# Modo de permissão da sessão filha (decisão do Diretor, 4.465): sem humano para
# responder prompt, o filho roda sem perguntas. Sobrescrevível por KEELSON_EPIC_PERM.
PERM_FLAG="${KEELSON_EPIC_PERM:---dangerously-skip-permissions}"

die2() { echo "ERRO: $*" >&2; exit 2; }
recusa() { echo "pré-voo: recusado — $*"; exit 3; }
usage() { sed -n '2,/^# Bash 3.2-compat/p' "$0" | sed 's/^# \{0,1\}//'; }
agora() { TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z; }
mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
vivo() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
encerrar_pid() { # TERM, depois KILL se insistir
  vivo "$1" || return 0
  kill -TERM "$1" 2>/dev/null; sleep 2
  vivo "$1" && kill -KILL "$1" 2>/dev/null
  return 0
}

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
ROOT="$(cd "$ROOT" && pwd)"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

# ---------- leitura da fila (epic-state é o único leitor) ----------
estado_fila() { # <brief> → ES_REGRA ES_ROTULO ES_ESTRATEGIA ES_AVISO ES_PROX ES_PROX_SLUG ES_PROX_TITULO ES_OUT
  ES_OUT="$( cd "$ROOT" && bash "$ES" "$1" 2>/dev/null )" || ES_OUT=""
  ES_REGRA="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="regra"{print $2; exit}')"
  ES_ROTULO="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="regra"{print $3; exit}')"
  ES_ESTRATEGIA="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="epico"{print $4; exit}')"
  ES_AVISO="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="aviso"{print 1; exit}')"
  ES_PROX="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="fatia" && $4=="pendente"{print $2; exit}')"
  ES_PROX_SLUG="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="fatia" && $4=="pendente"{print $3; exit}')"
  ES_PROX_TITULO=""
  if [ -n "$ES_PROX" ]; then
    ES_PROX_TITULO="$(awk -F'|' -v n="$ES_PROX" '
      /^\|/ { a=$2; gsub(/^[ \t]+|[ \t]+$/, "", a); if (a == n) { t=$3; gsub(/^[ \t]+|[ \t]+$/, "", t); gsub(/\*\*/, "", t); print t; exit } }
    ' "$ROOT/$1")"
  fi
}

slug_ancora_de() { d="$(dirname "$1")"; d="$(dirname "$d")"; basename "$d"; }

run_state_vivo() { # <slug> → ecoa o run em_andamento (qualquer casa) ou falha
  for f in "$ROOT"/thoughts/local/run-state-"$1".md "$ROOT"/thoughts/local/sessions/*/run-state-"$1".md; do
    [ -f "$f" ] || continue
    grep -q '^status: em_andamento' "$f" 2>/dev/null && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

st_set() { # chave valor → regrava a chave em status.tsv
  f="$DIR/status.tsv"; [ -f "$f" ] || : > "$f"
  awk -F'\t' -v k="$1" '$1 != k' "$f" > "$f.$$" 2>/dev/null
  printf '%s\t%s\n' "$1" "$2" >> "$f.$$"
  mv -f "$f.$$" "$f"
}
st_get() { awk -F'\t' -v k="$1" '$1==k{print $2; exit}' "$DIR/status.tsv" 2>/dev/null; }

finalizar() { # <motivo>
  ts="$(agora)"
  printf '%s\t%s\n' "$ts" "$1" > "$DIR/fim.txt"
  st_set estado parado; st_set motivo "$1"; st_set fim "$ts"
  rm -f "$DIR/driver.pid"
  echo "[$ts] parado — $1" >> "$DIR/launch.log"
}

case "$ACTION" in
# =====================================================================================
launch|_loop)
  BRIEF="${1:-}"; [ -n "$BRIEF" ] || die2 "launch exige o caminho do BRIEF épico (relativo à raiz)"
  shift
  case "$BRIEF" in /*) BRIEF="${BRIEF#"$ROOT"/}" ;; esac
  MAX=0; TMIN=0; MODEL=""; DRY=0; EXTRA=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --max-fatias) shift; MAX="${1:-0}" ;;
      --timeout-min) shift; TMIN="${1:-0}" ;;
      --model) shift; MODEL="${1:-}" ;;
      --dry-run) DRY=1 ;;
      --) shift; EXTRA="$*"; break ;;
      *) die2 "opção desconhecida: $1" ;;
    esac
    shift
  done
  case "$MAX$TMIN" in *[!0-9]*) die2 "--max-fatias e --timeout-min exigem inteiro" ;; esac
  [ -f "$ROOT/$BRIEF" ] || recusa "BRIEF épico não existe: $BRIEF"
  [ -f "$ES" ] || die2 "epic-state.sh ausente ao lado deste script"
  SLUG="$(slug_ancora_de "$BRIEF")"
  DIR="$ROOT/thoughts/local/epic-run/$SLUG"

  if [ "$ACTION" = "launch" ]; then
    estado_fila "$BRIEF"
    [ -n "$ES_OUT" ] || recusa "epic-state.sh não leu a fila de $BRIEF"
    [ -z "$ES_AVISO" ] || recusa "fila com estado fora do vocabulário (aviso do epic-state) — corrija a fila antes"
    case "$ES_ESTRATEGIA" in
      unica|"") : ;;
      *) recusa "estratégia \`$ES_ESTRATEGIA\` — o revezamento exige \`unica\` (fatia dependente de merge é ato do Diretor, 4.190)" ;;
    esac
    [ "$ES_REGRA" = "4" ] || recusa "fila na regra ${ES_REGRA:--} (${ES_ROTULO:-sem rótulo}) — o revezamento só larga com a próxima fatia pendente e nada em ciclo"
    [ -n "$ES_PROX" ] || recusa "nenhuma fatia pendente"
    git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1 || recusa "raiz não é repositório git"
    [ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ] || recusa "árvore suja — commite ou descarte antes (a fatia nasce de HEAD)"
    command -v claude >/dev/null 2>&1 || recusa "CLI \`claude\` ausente no PATH"
    git -C "$ROOT" check-ignore -q "thoughts/local/epic-run/$SLUG/x" 2>/dev/null \
      || recusa "thoughts/ não está no .gitignore — rode /keelson:init (Etapa 5.5) antes"
    if rs="$(run_state_vivo "$ES_PROX_SLUG")"; then
      recusa "run em andamento para \`$ES_PROX_SLUG\` (${rs#"$ROOT"/}) — retome pelo /keelson:continue ou encerre antes"
    fi
    if [ -f "$DIR/driver.pid" ] && vivo "$(cat "$DIR/driver.pid" 2>/dev/null)"; then
      recusa "revezamento já em curso para \`$SLUG\` (pid $(cat "$DIR/driver.pid")) — \`status\`/\`stop\` antes"
    fi
    echo "pré-voo: ok · épico $SLUG · estratégia ${ES_ESTRATEGIA:-unica} · próxima fatia $ES_PROX ($ES_PROX_TITULO → $ES_PROX_SLUG)"
    echo "permissões da sessão filha: $PERM_FLAG (decisão do Diretor, 4.465)"
    [ "$DRY" -eq 1 ] && { echo "dry-run: nada lançado"; exit 0; }
    mkdir -p "$DIR" || die2 "não criou $DIR"
    rm -f "$DIR/fim.txt"
    : > "$DIR/status.tsv"
    st_set estado lancando; st_set brief "$BRIEF"; st_set lancado "$(agora)"
    st_set max_fatias "$MAX"; st_set timeout_min "$TMIN"
    (
      # desacoplado: o subshell morre logo e o laço é reparentado — sobrevive ao turno e à janela
      # shellcheck disable=SC2086
      nohup bash "$0" "$ROOT" _loop "$BRIEF" --max-fatias "$MAX" --timeout-min "$TMIN" \
        ${MODEL:+--model "$MODEL"} -- $EXTRA >> "$DIR/launch.log" 2>&1 &
      echo $! > "$DIR/driver.pid"
    )
    sleep 1
    pid="$(cat "$DIR/driver.pid" 2>/dev/null)"
    echo "revezamento: lançado · pid ${pid:-?} · dir ${DIR#"$ROOT"/}"
    echo "acompanhe: epic-run.sh <raiz> status $SLUG · pare: epic-run.sh <raiz> stop $SLUG"
    exit 0
  fi

  # ---------- _loop (processo desacoplado) ----------
  [ -d "$DIR" ] || die2 "dir do revezamento ausente: $DIR"
  echo $$ > "$DIR/driver.pid"
  trap 'finalizar "driver encerrado por sinal"; exit 0' TERM INT HUP
  n=0
  while :; do
    estado_fila "$BRIEF"
    if [ -n "$ES_AVISO" ]; then finalizar "fila com estado fora do vocabulário (aviso do epic-state)"; break; fi
    case "$ES_REGRA" in
      4) : ;;
      6) finalizar "fila toda entregue"; break ;;
      5) finalizar "próxima fatia aguardando-produto — ${ES_ROTULO}"; break ;;
      *) finalizar "fila na regra ${ES_REGRA:--} — ${ES_ROTULO:-sem rótulo}"; break ;;
    esac
    [ -n "$ES_PROX" ] || { finalizar "nenhuma fatia pendente"; break; }
    n=$((n + 1))
    if [ "$MAX" -gt 0 ] && [ "$n" -gt "$MAX" ]; then finalizar "teto de fatias ($MAX) atingido — próxima pendente: $ES_PROX"; break; fi
    ts="$(agora)"
    st_set estado rodando; st_set fatia "$ES_PROX"; st_set titulo "$ES_PROX_TITULO"
    st_set slug_destino "$ES_PROX_SLUG"; st_set iniciada "$ts"; st_set log "fatia-$ES_PROX.stream.jsonl"
    echo "[$ts] fatia $ES_PROX ($ES_PROX_TITULO → $ES_PROX_SLUG) — lançando claude -p" >> "$DIR/launch.log"
    prompt="/keelson:continue $SLUG
Esta sessão não tem humano interativo: é a fatia $ES_PROX do revezamento do /keelson:auto-epic (regra da sessão sem humano: sdd-conventions.md, \"Sessão sem humano\"). Confirme a fatia proposta como default e execute a rota nesta sessão até a Entrega. Não abra PR, não mergeie."
    (
      # shellcheck disable=SC2086
      cd "$ROOT" && exec env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_CHILD_SESSION \
        -u CLAUDE_PID -u CLAUDECODE \
        claude -p "$prompt" --output-format stream-json --verbose $PERM_FLAG \
        ${MODEL:+--model "$MODEL"} $EXTRA
    ) > "$DIR/fatia-$ES_PROX.stream.jsonl" 2> "$DIR/fatia-$ES_PROX.stderr.log" &
    child=$!
    st_set filho_pid "$child"
    secs=0; rc=""
    while vivo "$child"; do
      if [ "$TMIN" -gt 0 ] && [ "$secs" -ge $((TMIN * 60)) ]; then
        encerrar_pid "$child"; wait "$child" 2>/dev/null; rc=124
        echo "[$(agora)] fatia $ES_PROX — teto de $TMIN min: filho encerrado" >> "$DIR/launch.log"
        break
      fi
      sleep 5; secs=$((secs + 5))
    done
    if [ -z "$rc" ]; then wait "$child"; rc=$?; fi
    st_set filho_pid ""
    res="$DIR/fatia-$ES_PROX.result.txt"
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$DIR/fatia-$ES_PROX.stream.jsonl" > "$res" 2>/dev/null <<'PY' || : > "$res"
import json, sys
out = []
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    line = line.strip()
    if not line: continue
    try: ev = json.loads(line)
    except Exception: continue
    if ev.get("type") == "assistant":
        for b in (ev.get("message") or {}).get("content") or []:
            if isinstance(b, dict) and b.get("type") == "text" and b.get("text"):
                out.append(b["text"])
    elif ev.get("type") == "result":
        out.append("\n[result] session=%s cost_usd=%s duration_ms=%s" % (
            ev.get("session_id"), ev.get("total_cost_usd"), ev.get("duration_ms")))
sys.stdout.write("\n\n".join(out))
PY
    else
      printf 'python3 ausente — texto não extraído; stream em %s\n' "fatia-$ES_PROX.stream.jsonl" > "$res"
    fi
    {
      printf '\n## Fatia %s — %s — %s → %s — exit %s\n\n' "$ES_PROX" "$ES_PROX_TITULO" "$ts" "$(agora)" "$rc"
      cat "$res"; printf '\n'
    } >> "$DIR/RESUMO.md"
    echo "[$(agora)] fatia $ES_PROX — claude saiu com $rc" >> "$DIR/launch.log"
    antes="$ES_PROX"
    estado_fila "$BRIEF"
    if [ "$ES_PROX" = "$antes" ]; then
      finalizar "fatia $antes não avançou (exit $rc) — motivo no run-state/ledger da sessão filha e em fatia-$antes.result.txt"
      break
    fi
  done
  exit 0
  ;;
# =====================================================================================
status)
  SLUG="${1:-}"; [ -n "$SLUG" ] || die2 "status exige o slug-âncora"
  DIR="$ROOT/thoughts/local/epic-run/$SLUG"
  [ -f "$DIR/status.tsv" ] || { echo "nenhum revezamento para \`$SLUG\`"; exit 4; }
  estado="$(st_get estado)"; pid="$(cat "$DIR/driver.pid" 2>/dev/null)"
  if [ "$estado" = "rodando" ] || [ "$estado" = "lancando" ]; then
    if ! vivo "$pid"; then
      echo "revezamento: morto — driver (pid ${pid:-?}) sumiu sem registrar fim · fatia $(st_get fatia) ($(st_get titulo)) · iniciada $(st_get iniciada)"
      echo "dir: ${DIR#"$ROOT"/} · retome pelo /keelson:continue $SLUG"
      exit 0
    fi
    log="$DIR/$(st_get log)"
    if [ -f "$log" ]; then idade=$(( ( $(date +%s) - $(mtime "$log") ) / 60 )); else idade="?"; fi
    wave="forja"
    if rs="$(run_state_vivo "$(st_get slug_destino)")"; then
      wc_="$(sed -n 's/^waves_concluidas:[ 	]*//p' "$rs" | head -1)"; wt_="$(sed -n 's/^waves_total:[ 	]*//p' "$rs" | head -1)"
      [ "${wt_:-0}" = "0" ] || wave="wave ${wc_:-0}/${wt_}"
    fi
    echo "revezamento: rodando · fatia $(st_get fatia) ($(st_get titulo)) · iniciada $(st_get iniciada) · último evento há ${idade} min · ${wave} · driver pid $pid"
  else
    echo "revezamento: parado — $(st_get motivo) ($(st_get fim))"
  fi
  echo "dir: ${DIR#"$ROOT"/} · resumo: ${DIR#"$ROOT"/}/RESUMO.md"
  exit 0
  ;;
# =====================================================================================
stop)
  SLUG="${1:-}"; [ -n "$SLUG" ] || die2 "stop exige o slug-âncora"
  DIR="$ROOT/thoughts/local/epic-run/$SLUG"
  pid="$(cat "$DIR/driver.pid" 2>/dev/null)"
  vivo "$pid" || { echo "nenhum revezamento em curso para \`$SLUG\`"; exit 4; }
  filho="$(st_get filho_pid)"
  encerrar_pid "$pid"          # o trap do driver registra o fim
  encerrar_pid "$filho"
  finalizar "pedido do Diretor (stop)"
  echo "revezamento: parado — pedido do Diretor · fatia $(st_get fatia) interrompida · retome pelo /keelson:continue $SLUG"
  exit 0
  ;;
*) die2 "ação desconhecida: $ACTION" ;;
esac
