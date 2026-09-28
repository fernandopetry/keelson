#!/usr/bin/env bash
# transcript-facts.sh — fatos mecânicos do TRANSCRIPT da sessão corrente (decisão 4.434),
# para os Stop hooks distinguirem "o que esta sessão fez" de "o que a branch carrega".
#
# Caso real (leitura de 12 sessões de um consumidor, 4.431): os stop-guards de gate 7/8
# cutucavam "N arquivos, ~M linhas" medindo a branch inteira contra main em sessão que não
# escreveu uma linha (update, triage, sessão ociosa); o jira-guard cutucava 3–4× durante o
# fan-out de scribes com o tracker-sync ainda em voo; o wave-guard cutucava a cada turno
# encerrado com subagent em background — ~20 turnos vazios por sessão, cada um pagando o
# cache read de um contexto de 500–790k. O transcript (.jsonl que o harness entrega em
# `transcript_path` no payload do Stop) responde às três perguntas de graça.
#
# Uso: transcript-facts.sh <transcript.jsonl> [--code-paths p1,p2,...] [--teto-min N]
# Saída (TSV, uma linha por fato):
#   escreveu_codigo<TAB>0|1<TAB><motivo>   1 quando ESTA sessão editou arquivo sob um dos
#                                          code paths (Edit/Write/NotebookEdit — sem
#                                          --code-paths, qualquer arquivo que não seja .md
#                                          nem thoughts/ conta), despachou
#                                          `keelson:developer`, ou rodou Bash que escreve na
#                                          árvore (git commit/merge/pull/rebase/cherry-pick/
#                                          revert/am/apply/checkout/switch/stash pop; `sed -i`;
#                                          redirecionamento `>` para arquivo sob um code path)
#   em_voo<TAB><id><TAB><tipo>             tarefa de SEGUNDO PLANO lançada (Agent com
#                                          run_in_background, "Async agent launched…
#                                          agentId: X"; Bash "Command running in background
#                                          with ID: X") ainda SEM a notificação de conclusão
#                                          (`<task-id>X</task-id>` em mensagem, attachment ou
#                                          queue-operation posterior) nem colhida por TaskOutput
#                                          (4.400); tipo = subagent_type do spawn ou `bash`.
#                                          Órfão NÃO conta (4.252 — calar exige prova de vida):
#                                          lançamento mais velho que --teto-min (default 90) ou
#                                          transcript do subagent (<sessão>/subagents/agent-<id>
#                                          .jsonl) parado há mais de 30 min sai da lista
#   agentes_em_voo<TAB>N                   contagem das linhas acima
# Exit: 0 fatos emitidos · 2 transcript ausente/ilegível (stdout vazio — o hook chamador
# volta ao comportamento anterior, nunca silencia por dúvida). Read-only. Bash 3.2 + python3.
set -u
LC_ALL=C; export LC_ALL
T="${1:-}"; shift 2>/dev/null || true
CP=""; TETO=90
while [ $# -gt 0 ]; do
  case "$1" in
    --code-paths) shift; CP="${1:-}" ;;
    --teto-min) shift; TETO="${1:-90}" ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$T" ] && [ -f "$T" ] && [ -r "$T" ] || exit 2
command -v python3 >/dev/null 2>&1 || exit 2
python3 - "$T" "$CP" "$TETO" <<'PY'
import json, os, re, sys, time
from datetime import datetime
path, cp_csv, teto_min = sys.argv[1], sys.argv[2], int(sys.argv[3] or 90)
sub_dir = os.path.join(path[:-len(".jsonl")] if path.endswith(".jsonl") else path, "subagents")
code_paths = [p.strip().strip("/") for p in cp_csv.split(",") if p.strip()]
GIT_RE = re.compile(r"\bgit\b[^|;&\n]*\b(commit|merge|pull|rebase|cherry-pick|revert|am|apply|checkout|switch)\b|\bgit\b[^|;&\n]*\bstash\s+pop\b")
SED_RE = re.compile(r"\bsed\s+(-[a-zA-Z]*i|--in-place)")
REDIR_RE = re.compile(r">>?\s*[\"']?([^\s\"'|;&]+)")
TASK_RE = re.compile(r"<task-id>([A-Za-z0-9_-]+)</task-id>")
AGENT_RE = re.compile(r"agentId:\s*([A-Za-z0-9_-]+)")
BASH_RE = re.compile(r"Command running in background with ID:\s*([A-Za-z0-9_-]+)")

def sob_code_path(p):
    if not p: return False
    p = p.replace("\\", "/")
    if not code_paths:
        # sem code paths declarados: artefato (.md) e transitório (thoughts/) não são código
        return not (p.endswith(".md") or p.startswith("thoughts/") or "/thoughts/" in p)
    for cp in code_paths:
        if p == cp or p.startswith(cp + "/") or ("/" + cp + "/") in p:
            return True
    return False

def textos(content):
    if isinstance(content, str): return [content]
    out = []
    for b in content or []:
        if isinstance(b, dict):
            if b.get("type") == "text" and b.get("text"): out.append(b["text"])
            if b.get("type") == "tool_result":
                c = b.get("content")
                if isinstance(c, str): out.append(c)
                elif isinstance(c, list):
                    out.extend(x.get("text", "") for x in c if isinstance(x, dict))
    return out

escreveu = 0; motivo = "-"
uses = {}          # tool_use id -> (name, input)
lancados = {}      # background task id -> tipo
notificados = set()
try:
    f = open(path, encoding="utf-8", errors="replace")
except Exception:
    sys.exit(2)
for line in f:
    line = line.strip()
    if not line: continue
    try: e = json.loads(line)
    except Exception: continue
    t = e.get("type")
    msg = e.get("message") or {}
    if t == "assistant":
        for b in msg.get("content") or []:
            if not isinstance(b, dict) or b.get("type") != "tool_use": continue
            name = b.get("name") or ""; inp = b.get("input") or {}
            uses[b.get("id")] = (name, inp)
            if not escreveu:
                if name in ("Edit", "Write", "NotebookEdit"):
                    if sob_code_path(inp.get("file_path") or inp.get("notebook_path") or ""):
                        escreveu, motivo = 1, "edit"
                elif name in ("Agent", "Task") and inp.get("subagent_type") == "keelson:developer":
                    escreveu, motivo = 1, "developer"
                elif name == "Bash":
                    cmd = inp.get("command") or ""
                    if GIT_RE.search(cmd):
                        escreveu, motivo = 1, "git"
                    elif SED_RE.search(cmd) or any(sob_code_path(m) for m in REDIR_RE.findall(cmd)):
                        escreveu, motivo = 1, "bash-escreve"
            if name == "TaskOutput":
                tid = inp.get("task_id") or inp.get("taskId")
                if tid: notificados.add(tid)
    elif t == "queue-operation":
        for m in TASK_RE.finditer(e.get("content") or ""): notificados.add(m.group(1))
    elif t == "user":
        for b in msg.get("content") or [] if not isinstance(msg.get("content"), str) else []:
            if isinstance(b, dict) and b.get("type") == "tool_result":
                txt = " ".join(textos([b]))
                tid = b.get("tool_use_id")
                ts = e.get("timestamp") or ""
                m = AGENT_RE.search(txt) if "Async agent launched" in txt else None
                if m:
                    lancados[m.group(1)] = ((uses.get(tid, ("", {}))[1] or {}).get("subagent_type") or "agent", ts)
                m = BASH_RE.search(txt)
                if m: lancados[m.group(1)] = ("bash", ts)
        for txt in textos(msg.get("content")):
            for m in TASK_RE.finditer(txt): notificados.add(m.group(1))
    elif t == "attachment":
        a = e.get("attachment") or {}
        for m in TASK_RE.finditer(a.get("prompt") or ""): notificados.add(m.group(1))
print(f"escreveu_codigo\t{escreveu}\t{motivo}")
agora = time.time()
def idade_min(ts):
    try: return (agora - datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()) / 60
    except Exception: return None
n = 0
for tid, (tipo, ts) in lancados.items():
    if tid in notificados: continue
    # prova de vida (4.252): lançamento dentro do teto E, quando o transcript do subagent
    # existe, tocado há ≤ 30 min — órfão de sessão morta nunca cala um guard
    im = idade_min(ts)
    if im is not None and im > teto_min: continue
    sj = os.path.join(sub_dir, f"agent-{tid}.jsonl")
    if os.path.isfile(sj) and (agora - os.path.getmtime(sj)) / 60 > 30: continue
    print(f"em_voo\t{tid}\t{tipo}"); n += 1
print(f"agentes_em_voo\t{n}")
PY
