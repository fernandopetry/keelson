#!/usr/bin/env bash
# window-marker — hook Stop que mede a janela de contexto da sessão e a registra
# em disco (decisão 4.148). Nunca bloqueia, nunca renudgeia: é só um medidor.
#
# Por que existe: a dieta de contexto (4.103) tem meta medida (janela ≤600k) e a
# linha de duração do report (4.56) é "relógio medido, nunca estimativa" — mas a
# janela em si só existia como observação manual. Este hook lê o final do
# transcript a cada Stop e appenda uma linha com o tamanho atual da janela
# (input + cache) no log de janela da CASA DA SESSÃO (decisão 4.314, resolvida
# por scripts/session-dir.sh via session_id do payload: <casa>/window.log; sem
# session_id ou sem o resolvedor, o caminho legado
# thoughts/local/session-window.log); o report de fecho cita o pico quando o
# arquivo existe (dono da linha: report-contract.md), e a lacuna é nomeada
# quando não existe. Medido ou omitido — nunca estimado.
#
# Custo por papel (decisão 4.239, extensão da 4.148): o mesmo log ganha uma linha
# `<ts> agente=<tipo> tokens=<N>[ dur=<S>s][ tools=<N>]` por subagent concluído —
# extraída dos registros de resultado do Task no transcript (campos
# agentType/totalTokens e, quando o harness os traz, totalDurationMs e
# totalToolUseCount — decisão 4.354: a janela de cada subagent é medida aqui, fora
# do contexto do modelo, nunca pelo relógio à mão da main session), processando
# só o DELTA desde o último Stop (offset por transcript em
# .window-offset.<cksum>, AO LADO do log; o fecho move o log, nunca o offset —
# sem ele o próximo report herdaria os agentes já reportados). O formato do transcript
# é interno ao harness e pode mudar entre versões: linha que não parseia é
# ignorada em silêncio — telemetria degrada, nunca inventa.
#
# A linha `agente=` é carimbada com o instante do RETORNO do subagent (timestamp do
# registro no transcript, em horário de Brasília), não com o do Stop: é dele que o
# compositor deriva o despacho (retorno − dur) para agrupar janelas paralelas —
# registro sem timestamp cai no instante do Stop, como antes.
#
# Início do turno (decisão 4.354): a linha `janela=` ganha ` inicio=<ts>` com o
# timestamp (horário de Brasília) do primeiro registro de usuário do delta — o
# que abriu o turno que este Stop encerra (prompt humano ou notificação de
# agent). É o par que o context-cost.sh usa para medir a espera entre turnos
# (fim do turno anterior → início deste). Sem registro no delta, a linha sai
# como antes.
#
# Escopo: só age em projeto keelson (keelson.config.json na raiz ou thoughts/local/
# já existente) — fora disso, exit 0 sem tocar o filesystem.
#
# Fallback gracioso (doutrina dos hooks): sem python3, sem cwd, sem transcript →
# exit 0, nunca trava o fluxo. Append é operação segura sob concorrência.
# Bash 3.2-compatível.

set -u

input="$(cat)"

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
  exit 0
fi

# gate de projeto keelson — não poluir repositórios alheios
if [ ! -f "$cwd/keelson.config.json" ] && [ ! -d "$cwd/thoughts/local" ]; then
  exit 0
fi

transcript="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("transcript_path", ""))' 2>/dev/null || echo "")"
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

# janela atual = usage da última mensagem do assistant (input + cache_read +
# cache_creation). Só o final do transcript é lido — custo constante por Stop.
janela="$(tail -c 262144 "$transcript" 2>/dev/null | python3 -c '
import sys, json
best = None
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    usage = (obj.get("message") or {}).get("usage") or {}
    if not usage:
        continue
    total = 0
    for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"):
        v = usage.get(k)
        if isinstance(v, (int, float)):
            total += int(v)
    if total > 0:
        best = total
print(best if best is not None else "")
' 2>/dev/null || echo "")"

# casa da sessão (4.314): resolvida pelo session-dir.sh com o session_id do
# payload; sem id ou sem o resolvedor → caminho legado, comportamento antigo
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id", ""))' 2>/dev/null || echo "")"
SDS="$(cd "$(dirname "$0")/../scripts" 2>/dev/null && pwd)/session-dir.sh"
log=""
if [ -n "$sid" ] && [ -f "$SDS" ]; then
  log="$(KEELSON_SESSAO="$sid" bash "$SDS" "$cwd" window-log --create 2>/dev/null)" || log=""
fi
if [ -z "$log" ]; then
  mkdir -p "$cwd/thoughts/local" 2>/dev/null || exit 0
  log="$cwd/thoughts/local/session-window.log"
fi
ts="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"

# delta do transcript desde o último Stop (4.239/4.354): agentes concluídos e o
# início do turno. Lido ANTES de escrever a linha `janela=`, que carrega o início.
delta_out=""
offset=0
off_file=""
key="$(printf '%s' "$transcript" | cksum 2>/dev/null | awk '{print $1}')"
if [ -n "$key" ]; then
  off_file="$(dirname "$log")/.window-offset.$key"
  if [ -f "$off_file" ]; then
    offset="$(cat "$off_file" 2>/dev/null || echo 0)"
  fi
  case "$offset" in
    ''|*[!0-9]*) offset=0 ;;
  esac
  size="$(wc -c < "$transcript" 2>/dev/null | tr -d '[:space:]' || echo 0)"
  case "$size" in
    ''|*[!0-9]*) size=0 ;;
  esac
  # transcript menor que o offset conhecido = arquivo trocado/reescrito → recomeça
  [ "$size" -lt "$offset" ] && offset=0
  if [ "$size" -gt "$offset" ]; then
    # só linhas completas do delta contam; CONSUMED devolve até onde é seguro avançar
    # o offset (linha parcial no fim de um write fica para o próximo Stop).
    delta_out="$(tail -c +"$((offset + 1))" "$transcript" 2>/dev/null | python3 -c '
import sys, re
data = sys.stdin.buffer.read()
consumed = data.rfind(b"\n") + 1
import json
from datetime import datetime, timezone, timedelta

def local_iso(s):
    # transcript grava UTC ISO ("...Z" ou ±HH:MM); o log fala horário de Brasília,
    # como as marcas da Cronologia — sem zoneinfo, cai no -03:00 fixo (sem DST)
    try:
        dt = datetime.strptime(s[:19], "%Y-%m-%dT%H:%M:%S")
        rest = s[19:]
        m = re.search(r"([+-])(\d\d):?(\d\d)$", rest)
        if m:
            off = timedelta(hours=int(m.group(2)), minutes=int(m.group(3)))
            if m.group(1) == "-":
                off = -off
        else:
            off = timedelta(0)
        dt = dt.replace(tzinfo=timezone(off))
        try:
            from zoneinfo import ZoneInfo
            tz = ZoneInfo("America/Sao_Paulo")
        except Exception:
            tz = timezone(timedelta(hours=-3))
        return dt.astimezone(tz).strftime("%Y-%m-%dT%H:%M:%S%z")
    except Exception:
        return None

turno = None
for raw in data[:consumed].split(b"\n"):
    raw = raw.strip()
    if not raw:
        continue
    try:
        obj = json.loads(raw)
    except Exception:
        continue
    if turno is None and obj.get("type") == "user" and not obj.get("isSidechain"):
        tsv = obj.get("timestamp")
        if isinstance(tsv, str) and tsv:
            turno = local_iso(tsv)
            if turno:
                print("TURNO %s" % turno)
    tur = obj.get("toolUseResult")
    if not isinstance(tur, dict):
        continue
    tokens = tur.get("totalTokens")
    agent = tur.get("agentType")
    if isinstance(tokens, (int, float)) and tokens > 0 and isinstance(agent, str) and agent:
        dur = tur.get("totalDurationMs")
        tools = tur.get("totalToolUseCount")
        d = int(round(dur / 1000.0)) if isinstance(dur, (int, float)) and dur >= 0 else "-"
        c = int(tools) if isinstance(tools, (int, float)) and tools >= 0 else "-"
        # instante do RETORNO do subagent (timestamp do registro), não o do Stop:
        # é dele que o compositor deriva o despacho (retorno - dur) — 4.354
        r = obj.get("timestamp")
        r = local_iso(r) if isinstance(r, str) and r else None
        print("AGENTE %s %d %s %s %s" % (agent.replace(" ", "_"), int(tokens), d, c, r or "-"))
print("CONSUMED %d" % consumed)
' 2>/dev/null || echo "")"
  fi
fi

# Subagents pela pasta `<transcript sem .jsonl>/subagents/` (decisão 4.437): spawn em
# background devolve toolUseResult SEM totalTokens/agentType (só "async_launched") e nunca
# virava linha `agente=` — tracker-sync 1 contado contra 8 reais, scribe 5 contra 12. A pasta
# tem 1 meta por spawn (foreground e background, aninhado incluído); tokens = soma do usage
# das mensagens do próprio subagent; dur = último − primeiro timestamp; tools = tool_use.
# Cada agentId entra no log UMA vez (`.window-agents.<key>`); agent ainda escrevendo (mtime
# < 60 s) fica para o próximo Stop. Com a pasta presente, as linhas de toolUseResult do delta
# são ignoradas (contariam o foreground duas vezes); sem a pasta, comportamento anterior.
agents_out=""
sub_dir="${transcript%.jsonl}/subagents"
if [ -d "$sub_dir" ] && [ -n "$key" ]; then
  seen_file="$(dirname "$log")/.window-agents.$key"
  [ -f "$seen_file" ] || : > "$seen_file" 2>/dev/null || true
  read -r -d '' AG_PY <<'PY2' || true
import glob, json, os, sys, time
from datetime import datetime, timezone, timedelta
sub_dir, seen_file = sys.argv[1], sys.argv[2]
try: seen = set(open(seen_file).read().split())
except Exception: seen = set()
agora = time.time()
def local_iso(ts):
    try:
        d = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(timezone(timedelta(hours=-3)))
        return d.strftime("%Y-%m-%dT%H:%M:%S%z")
    except Exception: return "-"
novos = []
for m in sorted(glob.glob(os.path.join(sub_dir, "agent-*.meta.json"))):
    aid = os.path.basename(m)[len("agent-"):-len(".meta.json")]
    if aid in seen: continue
    j = m[:-len(".meta.json")] + ".jsonl"
    if not os.path.isfile(j) or agora - os.path.getmtime(j) < 60: continue
    try: tipo = (json.load(open(m)).get("agentType") or "?").replace(" ", "_")
    except Exception: tipo = "?"
    first = last = None; tokens = 0; tools = 0; ids = set()
    for line in open(j, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line: continue
        try: e = json.loads(line)
        except Exception: continue
        ts = e.get("timestamp")
        if ts:
            first = first or ts; last = ts
        if e.get("type") == "assistant":
            msg = e.get("message") or {}; mid = msg.get("id"); u = msg.get("usage") or {}
            if u and mid not in ids:
                ids.add(mid)
                tokens += u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0) + u.get("output_tokens", 0)
            tools += sum(1 for b in msg.get("content") or [] if isinstance(b, dict) and b.get("type") == "tool_use")
    dur = "-"
    if first and last:
        try:
            f = lambda x: datetime.fromisoformat(x.replace("Z", "+00:00"))
            dur = int(round((f(last) - f(first)).total_seconds()))
        except Exception: dur = "-"
    print("AGENTE %s %d %s %d %s" % (tipo, tokens, dur, tools, local_iso(last) if last else "-"))
    novos.append(aid)
if novos:
    with open(seen_file, "a") as fh: fh.write("".join(a + "\n" for a in novos))
PY2
  agents_out="$(printf '%s' "$AG_PY" | python3 - "$sub_dir" "$seen_file" 2>/dev/null || echo "")"
fi

turno="$(printf '%s\n' "$delta_out" | awk '$1=="TURNO"{print $2; exit}')"
if [ -n "$janela" ]; then
  if [ -n "$turno" ]; then
    echo "${ts} janela=${janela} inicio=${turno}" >> "$log" 2>/dev/null || true
  else
    echo "${ts} janela=${janela}" >> "$log" 2>/dev/null || true
  fi
fi
if [ -n "$agents_out" ]; then
  delta_agents="$agents_out"
elif [ -d "$sub_dir" ]; then
  delta_agents=""   # pasta existe, nada novo terminado: nunca contar o foreground pelo toolUseResult
else
  delta_agents="$(printf '%s\n' "$delta_out" | awk '$1=="AGENTE"')"
fi
[ -n "$delta_out" ] || [ -n "$delta_agents" ] || exit 0

printf '%s\n' "$delta_agents" | while IFS=' ' read -r tag a b c d e; do
  [ "$tag" = "AGENTE" ] || continue
  lts="$ts"
  [ -n "$e" ] && [ "$e" != "-" ] && lts="$e"
  linha="${lts} agente=${a} tokens=${b}"
  [ -n "$c" ] && [ "$c" != "-" ] && linha="${linha} dur=${c}s"
  [ -n "$d" ] && [ "$d" != "-" ] && linha="${linha} tools=${d}"
  echo "$linha" >> "$log" 2>/dev/null || true
done
consumed="$(printf '%s\n' "$delta_out" | awk '$1=="CONSUMED"{print $2; exit}')"
case "$consumed" in
  ''|*[!0-9]*) exit 0 ;;
esac
[ -n "$off_file" ] && printf '%s' "$((offset + consumed))" > "$off_file" 2>/dev/null || true

exit 0
