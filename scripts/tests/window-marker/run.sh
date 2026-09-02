#!/usr/bin/env bash
# run.sh — suíte de regressão do window-marker (decisões 4.148/4.239/4.314).
#
# Roda o hook de verdade (stdin JSON, python3, transcript JSONL sintético).
# Regras provadas: linha `janela=` (input+cache da última mensagem) e linha
# `agente=` (toolUseResult do delta) no log; offset avança e o delta não
# re-reporta agente já visto; gate de projeto keelson (fora dele, nada é
# escrito); casa da sessão (4.314): payload com session_id → escreve em
# thoughts/local/sessions/<ts>-<sid8>/window.log (pasta criada com meta);
# sem session_id → caminho legado, comportamento antigo intacto. Campos medidos
# (decisão 4.354): registro com totalDurationMs/totalToolUseCount → `dur=<S>s`
# e `tools=<N>` ao fim da linha `agente=`, carimbada com o timestamp do RETORNO
# (horário de Brasília); registro sem os campos → linha antiga, byte-idêntica;
# primeiro registro de usuário do delta → ` inicio=<ts>` na linha `janela=`.
#
# Uso: scripts/tests/window-marker/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/window-marker.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v python3 >/dev/null 2>&1; then
  echo "window-marker: AVISO — python3 ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

roda() { # payload-json (o hook nunca ecoa nada; só interessa o estado em disco)
  printf '%s' "$1" | env -u CLAUDE_CODE_SESSION_ID -u KEELSON_SESSAO bash "$HOOK" >/dev/null 2>&1
}

transcript() { # $1 = caminho — JSONL com usage e um resultado de Task
  cat > "$1" <<'EOF'
{"message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":2000,"cache_creation_input_tokens":500}}}
{"toolUseResult":{"agentType":"keelson:developer","totalTokens":300000}}
{"message":{"usage":{"input_tokens":1500,"cache_read_input_tokens":2000}}}
EOF
}

# 1. Legado (sem session_id): projeto keelson → janela + agente no log antigo
D1="$TMP/c1"; mkdir -p "$D1/thoughts/local"
T1="$TMP/t1.jsonl"; transcript "$T1"
roda "{\"cwd\": \"$D1\", \"transcript_path\": \"$T1\"}"
LOG1="$D1/thoughts/local/session-window.log"
total=$((total + 1))
grep -q ' janela=3500$' "$LOG1" 2>/dev/null && ok legado-janela || falha "legado-janela: [$(cat "$LOG1" 2>/dev/null)]"
total=$((total + 1))
grep -q ' agente=keelson:developer tokens=300000$' "$LOG1" 2>/dev/null && ok legado-agente || falha legado-agente
total=$((total + 1))
ls "$D1/thoughts/local/".window-offset.* >/dev/null 2>&1 && ok legado-offset-criado || falha legado-offset-criado

# 2. Segundo Stop, mesmo transcript: janela re-appenda, agente NÃO duplica (delta)
roda "{\"cwd\": \"$D1\", \"transcript_path\": \"$T1\"}"
total=$((total + 1))
n="$(grep -c ' agente=' "$LOG1" 2>/dev/null)"
[ "$n" = "1" ] && ok delta-nao-duplica-agente || falha "delta-nao-duplica-agente: [$n]"
total=$((total + 1))
n="$(grep -c ' janela=' "$LOG1" 2>/dev/null)"
[ "$n" = "2" ] && ok janela-por-stop || falha "janela-por-stop: [$n]"

# 3. Fora de projeto keelson: nada é escrito
D3="$TMP/c3"; mkdir -p "$D3"
roda "{\"cwd\": \"$D3\", \"transcript_path\": \"$T1\"}"
total=$((total + 1))
[ ! -e "$D3/thoughts" ] && ok gate-projeto || falha gate-projeto

# 4. Casa da sessão (4.314): com session_id, escreve na pasta da sessão
D4="$TMP/c4"; mkdir -p "$D4/thoughts/local"
T4="$TMP/t4.jsonl"; transcript "$T4"
roda "{\"cwd\": \"$D4\", \"transcript_path\": \"$T4\", \"session_id\": \"sessao-w-12345678\"}"
SDIR4=""; for d in "$D4/thoughts/local/sessions/"*-sessaow1; do [ -d "$d" ] && SDIR4="$d" && break; done
total=$((total + 1))
[ -n "$SDIR4" ] && [ -f "$SDIR4/session.meta" ] && grep -qxF "sessao: sessao-w-12345678" "$SDIR4/session.meta" \
  && ok sessao-pasta-nasce || falha "sessao-pasta-nasce: [$SDIR4]"
total=$((total + 1))
grep -q ' janela=3500$' "$SDIR4/window.log" 2>/dev/null && ok sessao-janela || falha "sessao-janela: [$(cat "$SDIR4/window.log" 2>/dev/null)]"
total=$((total + 1))
grep -q ' agente=keelson:developer tokens=300000$' "$SDIR4/window.log" 2>/dev/null && ok sessao-agente || falha sessao-agente
total=$((total + 1))
[ ! -f "$D4/thoughts/local/session-window.log" ] && ok sessao-nao-escreve-legado || falha sessao-nao-escreve-legado
# offset mora ao lado do log da sessão (o fecho move o log, nunca o offset)
total=$((total + 1))
ls "$SDIR4/".window-offset.* >/dev/null 2>&1 && ok sessao-offset-ao-lado || falha sessao-offset-ao-lado
# delta continua valendo na casa nova
roda "{\"cwd\": \"$D4\", \"transcript_path\": \"$T4\", \"session_id\": \"sessao-w-12345678\"}"
total=$((total + 1))
n="$(grep -c ' agente=' "$SDIR4/window.log" 2>/dev/null)"
[ "$n" = "1" ] && ok sessao-delta-nao-duplica || falha "sessao-delta-nao-duplica: [$n]"

# 5. Campos medidos (4.354): dur/tools do registro, ts do retorno, inicio do turno
D5="$TMP/c5"; mkdir -p "$D5/thoughts/local"
T5="$TMP/t5.jsonl"
cat > "$T5" <<'EOF'
{"type":"user","timestamp":"2026-08-02T01:19:47.529Z","message":{"role":"user","content":"prompt que abre o turno"}}
{"type":"assistant","timestamp":"2026-08-02T01:19:50.000Z","message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":2000,"cache_creation_input_tokens":500}}}
{"type":"user","timestamp":"2026-08-02T01:25:00.000Z","toolUseResult":{"agentType":"keelson:developer","totalTokens":300000,"totalDurationMs":3132,"totalToolUseCount":7}}
{"type":"user","timestamp":"2026-08-02T01:26:00.000Z","toolUseResult":{"agentType":"keelson:po","totalTokens":20000}}
{"type":"user","isSidechain":true,"timestamp":"2026-08-02T01:27:00.000Z","message":{"role":"user","content":"registro de sidechain nunca abre turno"}}
EOF
roda "{\"cwd\": \"$D5\", \"transcript_path\": \"$T5\"}"
LOG5="$D5/thoughts/local/session-window.log"
total=$((total + 1))
grep -q ' janela=3500 inicio=2026-08-01T22:19:47-0300$' "$LOG5" 2>/dev/null && ok janela-com-inicio-do-turno || falha "janela-com-inicio-do-turno: [$(cat "$LOG5" 2>/dev/null)]"
total=$((total + 1))
grep -q '^2026-08-01T22:25:00-0300 agente=keelson:developer tokens=300000 dur=3s tools=7$' "$LOG5" 2>/dev/null && ok agente-dur-tools-ts-do-retorno || falha "agente-dur-tools-ts-do-retorno: [$(grep agente= "$LOG5" 2>/dev/null)]"
total=$((total + 1))
grep -q '^2026-08-01T22:26:00-0300 agente=keelson:po tokens=20000$' "$LOG5" 2>/dev/null && ok agente-sem-medida-linha-antiga || falha "agente-sem-medida-linha-antiga: [$(grep 'agente=keelson:po' "$LOG5" 2>/dev/null)]"
# 2º Stop sem delta: janela sem inicio (nenhum registro novo), nada duplica
roda "{\"cwd\": \"$D5\", \"transcript_path\": \"$T5\"}"
total=$((total + 1))
n="$(grep -c ' janela=3500$' "$LOG5" 2>/dev/null)"
[ "$n" = "1" ] && ok janela-sem-delta-sem-inicio || falha "janela-sem-delta-sem-inicio: [$n]"
total=$((total + 1))
n="$(grep -c ' agente=' "$LOG5" 2>/dev/null)"
[ "$n" = "2" ] && ok medidos-nao-duplicam || falha "medidos-nao-duplicam: [$n]"

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "window-marker: $fail de $total casos falharam"
  exit 1
fi
echo "window-marker: $total casos verdes"
exit 0
