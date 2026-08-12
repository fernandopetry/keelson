#!/usr/bin/env bash
# window-marker — hook Stop que mede a janela de contexto da sessão e a registra
# em disco (decisão 4.148). Nunca bloqueia, nunca renudgeia: é só um medidor.
#
# Por que existe: a dieta de contexto (4.103) tem meta medida (janela ≤600k) e a
# linha de duração do report (4.56) é "relógio medido, nunca estimativa" — mas a
# janela em si só existia como observação manual. Este hook lê o final do
# transcript a cada Stop e appenda uma linha com o tamanho atual da janela
# (input + cache) em thoughts/local/session-window.log; o report de fecho cita o
# pico quando o arquivo existe (dono da linha: report-contract.md), e a lacuna é
# nomeada quando não existe. Medido ou omitido — nunca estimado.
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

[ -n "$janela" ] || exit 0

mkdir -p "$cwd/thoughts/local" 2>/dev/null || exit 0
ts="$(TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
echo "${ts} janela=${janela}" >> "$cwd/thoughts/local/session-window.log" 2>/dev/null || true

exit 0
