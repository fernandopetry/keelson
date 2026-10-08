#!/usr/bin/env bash
# epic-run.sh — revezamento das fatias de um BRIEF épico sem o Diretor entre elas
# (decisão 4.465). Motor do /keelson:auto-epic: cada fatia roda num processo
# `claude -p` próprio (contexto limpo, sessão própria), lendo o estado do disco pelo
# /keelson:continue; a fila do BRIEF épico é o único fato que decide a próxima.
#
# Uso: epic-run.sh <raiz> launch <BRIEF-epico> [--max-fatias N] [--timeout-min M] [--retry N]
#                       [--retry-wait-sec S] [--force-claim] [--notify] [--stale-min N]
#                       [--model M] [--dry-run] [-- <args extras ao claude>]
#      epic-run.sh <raiz> status <slug-ancora>
#      epic-run.sh <raiz> watch  <slug-ancora> [--stale-min N] [--heartbeat-sec S]
#      epic-run.sh <raiz> stop   <slug-ancora> [--now]
#
#   launch   pré-voo mecânico (nada é escrito numa recusa; a 1ª linha do stdout começa
#            com a classe): `pré-voo: recusado` (exit 3) · `pré-voo: aguarda-diretor`
#            (exit 5) · `pré-voo: posse-incerta` (exit 6). Recusa: BRIEF ausente ·
#            estratégia ≠ `unica` (fatia dependente de merge é ato do Diretor, 4.190) ·
#            fila na regra 1/5/6 ou com `aviso` · árvore suja · `claude` fora do PATH ·
#            `thoughts/` não ignorado (4.51) · driver vivo. Regra 4 (próxima pendente)
#            parte limpo. Regra 2/3 (fatia `em ciclo` parcial — 4.466) é RETOMÁVEL quando
#            o run-state mais recente do slug de destino está `encerrado — pausa…`/outro
#            motivo, ou não existe, ou está `em_andamento` de dona MORTA pela régua do
#            `claim --check` (4.396); `encerrado — aguarda Diretor: …` → aguarda-diretor
#            (a fatia parou por decisão sua: o /keelson:continue INTERATIVO a retoma com
#            você presente — nunca o revezamento); dona possivelmente viva → posse-incerta
#            (espere o limiar ou `--force-claim`, que leva ao filho a sua confirmação de
#            que a dona morreu — FORCE=1 é ato do humano, 4.431). Passou → cria
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
#            avançou` — o progresso é a FILA ter mudado (fatia retomada que entrega
#            também avança); regra 6 → `fila toda entregue`; 5 → `aguardando-produto`;
#            1/aviso → rótulo; 2/3 → a próxima sessão retoma a fatia parcial. Fila
#            parada com o filho saindo ≠ 0 ou SEM evento `result` é falha de
#            INFRAESTRUTURA (rede, API, processo morto): nova tentativa da MESMA fatia
#            após --retry-wait-sec (default 600) até --retry vezes (default 2); saída 0
#            com `result` e fila parada é parada por DECISÃO — não se insiste. Marca
#            `STOP` no dir (stop gracioso) é lida antes de lançar a próxima fatia.
#            --max-fatias N para no teto; --timeout-min M mata a fatia que passar do teto
#            (0 = sem teto).
#            Fim: fim.txt (`<ts>\t<motivo>`), status.tsv `estado parado`, driver.pid removido.
#   status   uma linha: `revezamento: rodando · fatia N (<título>) · iniciada <ts> · último
#            evento há <M> min · wave X/Y` (wave do run-state em_andamento do slug de
#            destino, em qualquer casa; sem run → `forja`) · ou `revezamento: parado —
#            <motivo> (<ts>)` · ou `nenhum revezamento`. Linhas seguintes: dir e RESUMO.
#   watch    feed AO VIVO no terminal, sem modelo e sem token (4.471): segue o
#            stream.jsonl da fatia em curso (troca de arquivo quando a próxima começa) e
#            imprime uma linha legível por evento — hora · ferramenta chamada com resumo
#            curto · trecho do texto do Tech Lead · avanço de wave lido do run-state ·
#            início/fim de sessão. Batimento: sem evento há --heartbeat-sec (default 30)
#            imprime "sem evento há N"; acima de --stale-min (default 10) avisa POSSÍVEL
#            TRAVAMENTO com o pid do filho e se está vivo. Sai sozinho quando o
#            revezamento para (imprime o motivo). Exige python3. Ctrl-C encerra só o watch.
#   --notify (launch) notificação do sistema nos marcos (4.471): fim de cada fatia (com o
#            resultado), parada do revezamento e filho mudo acima de --stale-min (default
#            15, uma vez por fatia). macOS `osascript`, Linux `notify-send`; a variável
#            KEELSON_NOTIFY_CMD (recebe título e mensagem como argumentos) substitui os
#            dois — é o gancho de teste e de integração. Sem canal → no-op silencioso.
#   stop     GRACIOSO por default: grava a marca `STOP`; a fatia em curso termina na
#            Entrega e a próxima não é lançada (ponto seguro = fronteira de fatia). `--now`
#            encerra o filho em voo e o driver na hora — a fatia fica como sessão que
#            caiu (retomável pelo launch ou pelo /keelson:continue). Motivo gravado:
#            `pedido do Diretor`.
#
# Vocabulário da fila NUNCA muda (4.156): o motivo de parada vive aqui e no run-state,
# nunca num estado novo na tabela do BRIEF.
# Exit: 0 ok · 2 uso incorreto · 3 pré-voo recusou · 4 nada em andamento (status/stop) ·
#       5 aguarda Diretor · 6 posse incerta.
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
aguarda() { echo "pré-voo: aguarda-diretor — $*"; exit 5; }
incerta() { echo "pré-voo: posse-incerta — $*"; exit 6; }
usage() { sed -n '2,/^# Bash 3.2-compat/p' "$0" | sed 's/^# \{0,1\}//'; }
agora() { TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z; }
# GNU primeiro: no Linux `stat -f %m` é ponto de montagem do filesystem (sai 0 com "/"),
# nunca falha e o fallback BSD jamais rodaria; no macOS `-c` é opção ilegal e cai no `-f`.
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
vivo() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
notificar() { # <título> <mensagem> — só quando o launch pediu --notify (status.tsv notify=1)
  [ "$(st_get notify 2>/dev/null)" = "1" ] || return 0
  if [ -n "${KEELSON_NOTIFY_CMD:-}" ]; then "$KEELSON_NOTIFY_CMD" "$1" "$2" >/dev/null 2>&1 || true
  elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$(printf '%s' "$2" | tr '"' "'")\" with title \"$(printf '%s' "$1" | tr '"' "'")\"" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then notify-send "$1" "$2" >/dev/null 2>&1 || true
  fi
  return 0
}
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
  ES_FILA="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="fatia"')"
  # fatia ATUAL: a `em ciclo` (regra 2/3 — retomada) ou, sem ela, a próxima pendente
  ES_ATUAL="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="fatia" && $4 ~ /^em ciclo/ {print $2; exit}')"
  ES_ATUAL_SLUG="$(printf '%s\n' "$ES_OUT" | awk -F'\t' '$1=="fatia" && $4 ~ /^em ciclo/ {print $3; exit}')"
  ES_ATUAL_MODO="retomada"
  if [ -z "$ES_ATUAL" ]; then ES_ATUAL="$ES_PROX"; ES_ATUAL_SLUG="$ES_PROX_SLUG"; ES_ATUAL_MODO="nova"; fi
  ES_ATUAL_TITULO=""
  if [ -n "$ES_ATUAL" ]; then
    ES_ATUAL_TITULO="$(awk -F'|' -v n="$ES_ATUAL" '
      /^\|/ { a=$2; gsub(/^[ \t]+|[ \t]+$/, "", a); if (a == n) { t=$3; gsub(/^[ \t]+|[ \t]+$/, "", t); gsub(/\*\*/, "", t); print t; exit } }
    ' "$ROOT/$1")"
  fi
  ES_PROX_TITULO="$ES_ATUAL_TITULO"
}

run_state_recente() { # <slug> → ecoa o run-state MAIS RECENTE do slug (qualquer status, qualquer casa) ou nada
  # shellcheck disable=SC2012
  ls -t "$ROOT"/thoughts/local/run-state-"$1".md "$ROOT"/thoughts/local/sessions/*/run-state-"$1".md 2>/dev/null | head -1
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
  notificar "keelson · ${SLUG:-épico}" "revezamento parado — $1"
}

case "$ACTION" in
# =====================================================================================
launch|_loop)
  BRIEF="${1:-}"; [ -n "$BRIEF" ] || die2 "launch exige o caminho do BRIEF épico (relativo à raiz)"
  shift
  case "$BRIEF" in /*) BRIEF="${BRIEF#"$ROOT"/}" ;; esac
  MAX=0; TMIN=0; MODEL=""; DRY=0; EXTRA=""; RETRY=2; RWAIT=600; FORCE_CLAIM=0; NOTIFY=0; STALE=15
  while [ $# -gt 0 ]; do
    case "$1" in
      --notify) NOTIFY=1 ;;
      --stale-min) shift; STALE="${1:-15}" ;;
      --max-fatias) shift; MAX="${1:-0}" ;;
      --timeout-min) shift; TMIN="${1:-0}" ;;
      --retry) shift; RETRY="${1:-0}" ;;
      --retry-wait-sec) shift; RWAIT="${1:-600}" ;;
      --force-claim) FORCE_CLAIM=1 ;;
      --model) shift; MODEL="${1:-}" ;;
      --dry-run) DRY=1 ;;
      --) shift; EXTRA="$*"; break ;;
      *) die2 "opção desconhecida: $1" ;;
    esac
    shift
  done
  case "$MAX$TMIN$RETRY$RWAIT$STALE" in *[!0-9]*) die2 "--max-fatias, --timeout-min, --retry, --retry-wait-sec e --stale-min exigem inteiro" ;; esac
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
    case "$ES_REGRA" in
      4) : ;;
      2|3) : ;;   # fatia em ciclo parcial / fila desatualizada — retomável (4.466), julgada abaixo
      6) recusa "fila na regra 6 (${ES_ROTULO}) — nada a revezar; o PR do épico é o /keelson:integrate" ;;
      5) recusa "fila na regra 5 (${ES_ROTULO}) — a próxima fatia aguarda produto" ;;
      1) recusa "fila na regra 1 (${ES_ROTULO}) — a forja da fatia aguarda produto: /keelson:brief" ;;
      *) recusa "fila na regra ${ES_REGRA:--} (${ES_ROTULO:-sem rótulo})" ;;
    esac
    [ -n "$ES_ATUAL" ] || recusa "nenhuma fatia pendente nem em ciclo"
    git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1 || recusa "raiz não é repositório git"
    [ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ] || recusa "árvore suja — commite ou descarte antes (a fatia nasce de HEAD)"
    command -v claude >/dev/null 2>&1 || recusa "CLI \`claude\` ausente no PATH"
    git -C "$ROOT" check-ignore -q "thoughts/local/epic-run/$SLUG/x" 2>/dev/null \
      || recusa "thoughts/ não está no .gitignore — rode /keelson:init (Etapa 5.5) antes"
    if [ -f "$DIR/driver.pid" ] && vivo "$(cat "$DIR/driver.pid" 2>/dev/null)"; then
      recusa "revezamento já em curso para \`$SLUG\` (pid $(cat "$DIR/driver.pid")) — \`status\`/\`stop\` antes"
    fi
    # Fatia parcial (4.466): o run-state do slug de destino diz POR QUE ela parou.
    RETOMADA=""
    if rs="$(run_state_vivo "$ES_ATUAL_SLUG")"; then
      posse="$(cd "$ROOT" && bash "$HERE/run-state.sh" "$ROOT" claim "$ES_ATUAL_SLUG" --check 2>/dev/null)"; pst=$?
      case "$posse" in
        "posse: assumivel"*) RETOMADA="run em andamento de sessão morta (${posse#posse: assumivel · }) — o continue da sessão filha assume a posse (4.396)" ;;
        "posse: propria"*)   recusa "run em andamento DESTA sessão para \`$ES_ATUAL_SLUG\` (${rs#"$ROOT"/}) — termine ou encerre aqui" ;;
        *) if [ "$FORCE_CLAIM" -eq 1 ]; then
             RETOMADA="posse forçada pelo Diretor (--force-claim): ${posse#posse: }"
           else
             incerta "run em andamento para \`$ES_ATUAL_SLUG\` (${rs#"$ROOT"/}): ${posse#posse: recusada · } — espere o limiar, confirme a morte da dona com --force-claim, ou retome pelo /keelson:continue (exit claim $pst)"
           fi ;;
      esac
    elif [ "$ES_ATUAL_MODO" = "retomada" ]; then
      rr="$(run_state_recente "$ES_ATUAL_SLUG")"
      if [ -n "$rr" ]; then
        motivo_rs="$(sed -n 's/^status:[ 	]*//p' "$rr" | head -1)"
        case "$motivo_rs" in
          *"aguarda Diretor"*|*"degrau 3"*)
            # shellcheck disable=SC2012
            ult="$(ls -t "$DIR"/fatia-*.result.txt 2>/dev/null | head -1)"
            aguarda "a fatia $ES_ATUAL ($ES_ATUAL_TITULO) parou por decisão sua — run ${rr#"$ROOT"/}: \`$motivo_rs\`${ult:+ · último relatório: ${ult#"$ROOT"/}} — retome pelo /keelson:continue $SLUG com você presente; depois relance o revezamento" ;;
          *) RETOMADA="run ${rr#"$ROOT"/} \`$motivo_rs\` — retomável pelo continue da sessão filha" ;;
        esac
      else
        RETOMADA="fatia em ciclo sem run-state nesta máquina — o continue da sessão filha deriva o ponto dos artefatos commitados"
      fi
    fi
    if [ "$ES_ATUAL_MODO" = "retomada" ]; then
      echo "pré-voo: ok · épico $SLUG · estratégia ${ES_ESTRATEGIA:-unica} · retomar fatia $ES_ATUAL ($ES_ATUAL_TITULO → $ES_ATUAL_SLUG) · $RETOMADA"
    else
      echo "pré-voo: ok · épico $SLUG · estratégia ${ES_ESTRATEGIA:-unica} · próxima fatia $ES_ATUAL ($ES_ATUAL_TITULO → $ES_ATUAL_SLUG)"
    fi
    echo "permissões da sessão filha: $PERM_FLAG (decisão do Diretor, 4.465)"
    [ "$DRY" -eq 1 ] && { echo "dry-run: nada lançado"; exit 0; }
    mkdir -p "$DIR" || die2 "não criou $DIR"
    rm -f "$DIR/fim.txt" "$DIR/STOP"
    : > "$DIR/status.tsv"
    st_set estado lancando; st_set brief "$BRIEF"; st_set lancado "$(agora)"
    st_set max_fatias "$MAX"; st_set timeout_min "$TMIN"; st_set retry "$RETRY"; st_set force_claim "$FORCE_CLAIM"
    st_set notify "$NOTIFY"; st_set stale_min "$STALE"
    FC_FLAG=""; [ "$FORCE_CLAIM" -eq 1 ] && FC_FLAG="--force-claim"
    NF_FLAG=""; [ "$NOTIFY" -eq 1 ] && NF_FLAG="--notify"
    (
      # desacoplado: o subshell morre logo e o laço é reparentado — sobrevive ao turno e à janela
      # shellcheck disable=SC2086
      nohup bash "$0" "$ROOT" _loop "$BRIEF" --max-fatias "$MAX" --timeout-min "$TMIN" --retry "$RETRY" \
        --retry-wait-sec "$RWAIT" --stale-min "$STALE" ${FC_FLAG:+"$FC_FLAG"} ${NF_FLAG:+"$NF_FLAG"} \
        ${MODEL:+--model "$MODEL"} -- $EXTRA >> "$DIR/launch.log" 2>&1 &
      echo $! > "$DIR/driver.pid"
    )
    sleep 1
    pid="$(cat "$DIR/driver.pid" 2>/dev/null)"
    echo "revezamento: lançado · pid ${pid:-?} · dir ${DIR#"$ROOT"/}"
    echo "acompanhe: epic-run.sh <raiz> status $SLUG · ao vivo: epic-run.sh <raiz> watch $SLUG · pare: epic-run.sh <raiz> stop $SLUG"
    exit 0
  fi

  # ---------- _loop (processo desacoplado) ----------
  [ -d "$DIR" ] || die2 "dir do revezamento ausente: $DIR"
  echo $$ > "$DIR/driver.pid"
  trap 'finalizar "driver encerrado por sinal"; exit 0' TERM INT HUP
  n=0; tent=0; ultima=""
  while :; do
    estado_fila "$BRIEF"
    if [ -n "$ES_AVISO" ]; then finalizar "fila com estado fora do vocabulário (aviso do epic-state)"; break; fi
    case "$ES_REGRA" in
      4|2|3) : ;;
      6) finalizar "fila toda entregue"; break ;;
      5) finalizar "próxima fatia aguardando-produto — ${ES_ROTULO}"; break ;;
      *) finalizar "fila na regra ${ES_REGRA:--} — ${ES_ROTULO:-sem rótulo}"; break ;;
    esac
    [ -n "$ES_ATUAL" ] || { finalizar "nenhuma fatia pendente nem em ciclo"; break; }
    if [ -f "$DIR/STOP" ]; then rm -f "$DIR/STOP"; finalizar "pedido do Diretor (stop)${ultima:+ — após a fatia $ultima}; próxima: $ES_ATUAL"; break; fi
    if [ "$tent" -eq 0 ]; then
      n=$((n + 1))
      if [ "$MAX" -gt 0 ] && [ "$n" -gt "$MAX" ]; then finalizar "teto de fatias ($MAX) atingido — próxima: $ES_ATUAL"; break; fi
    fi
    ts="$(agora)"
    st_set estado rodando; st_set fatia "$ES_ATUAL"; st_set titulo "$ES_ATUAL_TITULO"; st_set modo "$ES_ATUAL_MODO"
    st_set slug_destino "$ES_ATUAL_SLUG"; st_set iniciada "$ts"; st_set log "fatia-$ES_ATUAL.stream.jsonl"; st_set tentativa "$((tent + 1))"
    echo "[$ts] fatia $ES_ATUAL ($ES_ATUAL_TITULO → $ES_ATUAL_SLUG · $ES_ATUAL_MODO · tentativa $((tent + 1))) — lançando claude -p" >> "$DIR/launch.log"
    prompt="/keelson:continue $SLUG
Esta sessão não tem humano interativo: é a fatia $ES_ATUAL do revezamento do /keelson:auto-epic (regra da sessão sem humano: sdd-conventions.md, \"Sessão sem humano\"). Confirme a proposta como default e execute a rota nesta sessão até a Entrega. Não abra PR, não mergeie."
    [ "$FORCE_CLAIM" -eq 1 ] && prompt="$prompt
O Diretor confirmou que a sessão dona do run em andamento morreu: ao assumir a posse, use FORCE=1 no claim (4.431)."
    fila_antes="$ES_FILA"
    (
      # shellcheck disable=SC2086
      cd "$ROOT" && exec env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_CHILD_SESSION \
        -u CLAUDE_PID -u CLAUDECODE \
        claude -p "$prompt" --output-format stream-json --verbose $PERM_FLAG \
        ${MODEL:+--model "$MODEL"} $EXTRA
    ) > "$DIR/fatia-$ES_PROX.stream.jsonl" 2> "$DIR/fatia-$ES_PROX.stderr.log" &
    child=$!
    st_set filho_pid "$child"
    secs=0; rc=""; mudo_avisado=0
    while vivo "$child"; do
      if [ "$mudo_avisado" -eq 0 ] && [ "$STALE" -gt 0 ] && [ -f "$DIR/fatia-$ES_ATUAL.stream.jsonl" ]; then
        idade=$(( ( $(date +%s) - $(mtime "$DIR/fatia-$ES_ATUAL.stream.jsonl") ) / 60 ))
        if [ "$idade" -ge "$STALE" ]; then
          mudo_avisado=1
          echo "[$(agora)] fatia $ES_ATUAL — sem evento há ${idade} min (filho pid $child vivo) — possível travamento" >> "$DIR/launch.log"
          notificar "keelson · $SLUG" "fatia $ES_ATUAL sem evento há ${idade} min — possível travamento (pid $child)"
        fi
      fi
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
out = []; result = None
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
        # um Stop hook que cutuca no fim faz o stream emitir mais de um `result`: fica o último
        result = "\n[result] session=%s cost_usd=%s duration_ms=%s" % (
            ev.get("session_id"), ev.get("total_cost_usd"), ev.get("duration_ms"))
if result: out.append(result)
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
    antes="$ES_ATUAL"
    estado_fila "$BRIEF"
    if [ "$ES_FILA" != "$fila_antes" ]; then
      tent=0; ultima="$antes"
      notificar "keelson · $SLUG" "fatia $antes ($ES_ATUAL_TITULO) entregue — fila avançou"
      continue
    fi
    # fila parada: infraestrutura (saída ≠ 0 ou sem evento result) tenta de novo; decisão não insiste
    if [ "$rc" -ne 0 ] || ! grep -q '"type":"result"' "$DIR/fatia-$antes.stream.jsonl" 2>/dev/null; then
      if [ "$tent" -lt "$RETRY" ]; then
        tent=$((tent + 1))
        echo "[$(agora)] fatia $antes — falha de infraestrutura (exit $rc); nova tentativa $((tent + 1))/$((RETRY + 1)) em ${RWAIT}s" >> "$DIR/launch.log"
        st_set estado aguardando_retry; st_set proxima_tentativa_em "${RWAIT}s"
        w=0; while [ "$w" -lt "$RWAIT" ]; do [ -f "$DIR/STOP" ] && break; sleep 5; w=$((w + 5)); done
        continue
      fi
      finalizar "fatia $antes falhou $((tent + 1)) vez(es) por infraestrutura (último exit $rc) — veja fatia-$antes.stderr.log; relance quando a causa passar"
      break
    fi
    finalizar "fatia $antes não avançou (exit $rc) — parada por decisão: motivo no run-state da sessão filha e em fatia-$antes.result.txt"
    break
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
    parando=""; [ -f "$DIR/STOP" ] && parando=" · PARANDO após esta fatia (stop gracioso)"
    echo "revezamento: rodando · fatia $(st_get fatia) ($(st_get titulo) · $(st_get modo)) · iniciada $(st_get iniciada) · último evento há ${idade} min · ${wave} · driver pid $pid${parando}"
  elif [ "$estado" = "aguardando_retry" ]; then
    echo "revezamento: aguardando nova tentativa da fatia $(st_get fatia) (falha de infraestrutura; próxima em $(st_get proxima_tentativa_em)) · driver pid $pid"
  else
    echo "revezamento: parado — $(st_get motivo) ($(st_get fim))"
    case "$(st_get motivo)" in
      *"não avançou"*|*"falhou"*)
        f="$(st_get fatia)"; r="$DIR/fatia-$f.result.txt"
        if [ -s "$r" ]; then echo "último relatório (fatia $f, fim):"; tail -n 15 "$r" | sed 's/^/  /'; fi ;;
    esac
  fi
  echo "dir: ${DIR#"$ROOT"/} · resumo: ${DIR#"$ROOT"/}/RESUMO.md"
  exit 0
  ;;
# =====================================================================================
watch)
  SLUG="${1:-}"; [ -n "$SLUG" ] || die2 "watch exige o slug-âncora"
  shift; WSTALE=10; HB=30
  while [ $# -gt 0 ]; do
    case "$1" in
      --stale-min) shift; WSTALE="${1:-10}" ;;
      --heartbeat-sec) shift; HB="${1:-30}" ;;
      *) die2 "opção desconhecida: $1" ;;
    esac
    shift
  done
  case "$WSTALE$HB" in *[!0-9]*) die2 "--stale-min e --heartbeat-sec exigem inteiro" ;; esac
  DIR="$ROOT/thoughts/local/epic-run/$SLUG"
  [ -f "$DIR/status.tsv" ] || { echo "nenhum revezamento para \`$SLUG\`"; exit 4; }
  command -v python3 >/dev/null 2>&1 || die2 "watch exige python3"
  exec python3 - "$DIR" "$ROOT" "$WSTALE" "$HB" <<'PYW'
import json, os, sys, time, glob
D, ROOT, STALE, HB = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])

def st():
    d = {}
    try:
        for line in open(os.path.join(D, "status.tsv"), encoding="utf-8"):
            k, _, v = line.rstrip("\n").partition("\t"); d[k] = v
    except OSError: pass
    return d

def hora(): return time.strftime("%H:%M:%S")
def say(txt): print("%s  %s" % (hora(), txt), flush=True)
def vivo(pid):
    try: os.kill(int(pid), 0); return True
    except Exception: return False
def wave(slug):
    for f in glob.glob(os.path.join(ROOT, "thoughts/local/run-state-%s.md" % slug)) + \
             glob.glob(os.path.join(ROOT, "thoughts/local/sessions/*/run-state-%s.md" % slug)):
        try: txt = open(f, encoding="utf-8").read()
        except OSError: continue
        if "status: em_andamento" not in txt: continue
        wc = wt = ""
        for l in txt.splitlines():
            if l.startswith("waves_concluidas:"): wc = l.split(":", 1)[1].strip()
            if l.startswith("waves_total:"): wt = l.split(":", 1)[1].strip()
        return (wc, wt)
    return None

def resumo_tool(name, inp):
    inp = inp or {}
    if name == "Bash": return (inp.get("description") or inp.get("command") or "")[:110]
    for k in ("file_path", "path", "pattern", "description", "prompt", "skill", "command"):
        if inp.get(k): return str(inp[k])[:110]
    return ""

def evento(ev):
    t = ev.get("type")
    if t == "system" and ev.get("subtype") == "init":
        say("> sessao filha %s iniciada" % str(ev.get("session_id", ""))[:8])
    elif t == "assistant":
        for b in (ev.get("message") or {}).get("content") or []:
            if not isinstance(b, dict): continue
            if b.get("type") == "text" and b.get("text"):
                txt = " ".join(b["text"].split())
                say("TL: " + (txt[:160] + ("..." if len(txt) > 160 else "")))
            elif b.get("type") == "tool_use":
                nome = b.get("name", "?"); r = resumo_tool(nome, b.get("input"))
                say("[%s] %s" % (nome, r))
    elif t == "result":
        say("= sessao filha encerrou - custo US$%s - %s s" % (ev.get("total_cost_usd"), (ev.get("duration_ms") or 0) // 1000))

say("watch - revezamento de %s (Ctrl-C encerra so o watch)" % os.path.basename(D))
cur = None; fh = None; last_ev = time.time(); last_hb = time.time(); last_wave = None; stale_said = False; fatia_said = None
while True:
    s = st()
    estado = s.get("estado", "")
    if estado == "parado":
        say("= revezamento parado - %s" % s.get("motivo", "")); break
    log = s.get("log", "")
    path = os.path.join(D, log) if log else None
    if estado == "rodando" and s.get("fatia") and fatia_said != s.get("fatia"):
        fatia_said = s.get("fatia")
        say("== fatia %s (%s - %s) - iniciada %s" % (fatia_said, s.get("titulo", ""), s.get("modo", ""), s.get("iniciada", "")))
        last_ev = time.time(); stale_said = False
    if estado == "aguardando_retry":
        say("~ aguardando nova tentativa da fatia %s (falha de infraestrutura)" % s.get("fatia", "")); time.sleep(HB); continue
    if path and path != cur and os.path.exists(path):
        if fh: fh.close()
        fh = open(path, encoding="utf-8", errors="replace"); cur = path
    got = False
    if fh:
        while True:
            pos = fh.tell(); line = fh.readline()
            if not line: break
            if not line.endswith("\n"): fh.seek(pos); break
            got = True; last_ev = time.time(); stale_said = False
            try: evento(json.loads(line))
            except Exception: pass
    w = wave(s.get("slug_destino", ""))
    if w and w != last_wave:
        last_wave = w
        if w[1] not in ("", "0"): say("~ wave %s/%s" % w)
    if not got:
        quiet = time.time() - last_ev
        if time.time() - last_hb >= HB and quiet >= HB:
            last_hb = time.time()
            m, sec = int(quiet // 60), int(quiet % 60)
            if quiet >= STALE * 60 and not stale_said:
                stale_said = True
                pid = s.get("filho_pid", ""); say("!! POSSIVEL TRAVAMENTO: sem evento ha %dmin - filho pid %s %s" % (m, pid or "?", "vivo" if pid and vivo(pid) else "ausente"))
            else:
                say("... sem evento ha %dmin%02ds" % (m, sec))
        time.sleep(1)
PYW
  ;;
# =====================================================================================
stop)
  SLUG="${1:-}"; [ -n "$SLUG" ] || die2 "stop exige o slug-âncora"
  shift; NOW=0
  while [ $# -gt 0 ]; do case "$1" in --now) NOW=1 ;; *) die2 "opção desconhecida: $1" ;; esac; shift; done
  DIR="$ROOT/thoughts/local/epic-run/$SLUG"
  pid="$(cat "$DIR/driver.pid" 2>/dev/null)"
  vivo "$pid" || { echo "nenhum revezamento em curso para \`$SLUG\`"; exit 4; }
  if [ "$NOW" -eq 0 ]; then
    : > "$DIR/STOP"
    echo "revezamento: parando — a fatia $(st_get fatia) ($(st_get titulo)) termina na Entrega e a próxima não é lançada · \`stop --now\` interrompe agora"
    exit 0
  fi
  filho="$(st_get filho_pid)"
  encerrar_pid "$pid"          # o trap do driver registra o fim
  encerrar_pid "$filho"
  finalizar "pedido do Diretor (stop --now)"
  echo "revezamento: parado — pedido do Diretor · fatia $(st_get fatia) interrompida no meio · retomável por /keelson:auto-epic $SLUG ou /keelson:continue $SLUG"
  exit 0
  ;;
*) die2 "ação desconhecida: $ACTION" ;;
esac
