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
# `<ts> agente=<tipo> tokens=<N>` por subagent concluído — extraída dos registros
# de resultado do Task no transcript (campos agentType/totalTokens), processando
# só o DELTA desde o último Stop (offset por transcript em
# .window-offset.<cksum>, AO LADO do log; o fecho move o log, nunca o offset —
# sem ele o próximo report herdaria os agentes já reportados). O formato do transcript
# é interno ao harness e pode mudar entre versões: linha que não parseia é
# ignorada em silêncio — telemetria degrada, nunca inventa.
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

if [ -n "$janela" ]; then
  echo "${ts} janela=${janela}" >> "$log" 2>/dev/null || true
fi

# custo por papel (4.239): processa só o delta do transcript desde o último Stop.
key="$(printf '%s' "$transcript" | cksum 2>/dev/null | awk '{print $1}')"
[ -n "$key" ] || exit 0
off_file="$(dirname "$log")/.window-offset.$key"
offset=0
if [ -f "$off_file" ]; then
  offset="$(cat "$off_file" 2>/dev/null || echo 0)"
fi
case "$offset" in
  ''|*[!0-9]*) offset=0 ;;
esac
size="$(wc -c < "$transcript" 2>/dev/null | tr -d '[:space:]' || echo 0)"
case "$size" in
  ''|*[!0-9]*) exit 0 ;;
esac
# transcript menor que o offset conhecido = arquivo trocado/reescrito → recomeça
[ "$size" -lt "$offset" ] && offset=0
[ "$size" -gt "$offset" ] || exit 0

# só linhas completas do delta contam; CONSUMED devolve até onde é seguro avançar
# o offset (linha parcial no fim de um write fica para o próximo Stop).
delta_out="$(tail -c +"$((offset + 1))" "$transcript" 2>/dev/null | python3 -c '
import sys
data = sys.stdin.buffer.read()
consumed = data.rfind(b"\n") + 1
import json
for raw in data[:consumed].split(b"\n"):
    raw = raw.strip()
    if not raw:
        continue
    try:
        obj = json.loads(raw)
    except Exception:
        continue
    tur = obj.get("toolUseResult")
    if not isinstance(tur, dict):
        continue
    tokens = tur.get("totalTokens")
    agent = tur.get("agentType")
    if isinstance(tokens, (int, float)) and tokens > 0 and isinstance(agent, str) and agent:
        print("AGENTE %s %d" % (agent.replace(" ", "_"), int(tokens)))
print("CONSUMED %d" % consumed)
' 2>/dev/null || echo "")"
[ -n "$delta_out" ] || exit 0

consumed=""
printf '%s\n' "$delta_out" | while IFS=' ' read -r tag a b; do
  [ "$tag" = "AGENTE" ] || continue
  echo "${ts} agente=${a} tokens=${b}" >> "$log" 2>/dev/null || true
done
consumed="$(printf '%s\n' "$delta_out" | awk '$1=="CONSUMED"{print $2; exit}')"
case "$consumed" in
  ''|*[!0-9]*) exit 0 ;;
esac
printf '%s' "$((offset + consumed))" > "$off_file" 2>/dev/null || true

exit 0
