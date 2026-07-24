#!/usr/bin/env bash
# desc-guard — hook Stop que impede encerrar o turno com uma description de
# comando ou skill do plugin acima do teto de 250 caracteres.
#
# Por que existe: o Claude Code (>= v2.1.86) impõe um limite de 250 caracteres na
# `description` de frontmatter de comandos e skills. Comando acima do teto some da
# lista de comandos SEM erro (ocultação silenciosa); skill acima do teto tem a
# description truncada na tela /skills. Um `/keelson:verify-handoff` ficou invisível
# por isso (LRN sobre o teto de 250). Este guard não depende do contexto do modelo:
# lê os .md do plugin em disco e cutuca se algum passar do teto.
#
# Escopo: só age no REPOSITÓRIO DE DESENVOLVIMENTO do keelson (onde os .md do plugin
# são editados — marcado por .claude-plugin/plugin.json com name "keelson" + commands/).
# Em projeto consumidor o plugin é read-only e não vive no cwd → o guard sai gracioso
# (exit 0) e nunca atrapalha o fluxo.
#
# Fallback gracioso: sem python3, sem cwd, fora do repo do plugin → exit 0.
# stop_hook_active evita loop: cutuca 1x por encerramento.

set -euo pipefail

input="$(cat)"

active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null || echo False)"
if [ "$active" = "True" ]; then
  exit 0
fi

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
  exit 0
fi

# Só o repo de desenvolvimento do keelson: precisa do manifesto do plugin e de commands/.
[ -f "$cwd/.claude-plugin/plugin.json" ] || exit 0
[ -d "$cwd/commands" ] || exit 0
grep -q '"name"[[:space:]]*:[[:space:]]*"keelson"' "$cwd/.claude-plugin/plugin.json" 2>/dev/null || exit 0

viol="$(cwd="$cwd" python3 - <<'PY' 2>/dev/null || true
import os, glob, re

cwd = os.environ["cwd"]
LIMIT = 250


def desc_len(path):
    try:
        with open(path, encoding="utf-8") as fh:
            txt = fh.read()
    except OSError:
        return None
    lines = txt.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"description:\s*(.*)$", line)
        if m:
            val = m.group(1)
            if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
                val = val[1:-1]
            return len(val)
    return None


targets = sorted(glob.glob(os.path.join(cwd, "commands", "*.md")))
targets += sorted(glob.glob(os.path.join(cwd, "skills", "*", "SKILL.md")))
for p in targets:
    n = desc_len(p)
    if n is not None and n > LIMIT:
        print(f"{n}\t{os.path.relpath(p, cwd)}")
PY
)"

if [ -z "$viol" ]; then
  exit 0
fi

lista="$(printf '%s\n' "$viol" | while IFS="$(printf '\t')" read -r n rel; do
  [ -n "$rel" ] || continue
  printf '    — %s (%s caracteres)\n' "$rel" "$n"
done)"

reason="Guarda de description (teto de 250): há artefato(s) do plugin cuja description de frontmatter passa de 250 caracteres. O Claude Code (>= v2.1.86) OCULTA da lista o comando nessa condição (sem erro) e trunca a description da skill na tela /skills.
${lista}

Encurte cada description para no máximo 250 caracteres, com os termos-gatilho no início; o detalhe completo fica no corpo do artefato. Depois encerre."

printf '%s' "$reason" | python3 -c 'import sys,json; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))' 2>/dev/null || exit 0

exit 0
