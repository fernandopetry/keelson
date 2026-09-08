#!/usr/bin/env bash
# run.sh — suíte de regressão do desc-guard (decisões 4.29/4.385).
#
# Roda o hook de verdade (stdin JSON, python3) num repo de plugin SINTÉTICO
# (.claude-plugin/plugin.json com name keelson + commands/). Casos inline:
#   fronteiras exatas 250/251 (commands e skills) e 350/351 (agents); aspas não
#   contam; code points (não bytes); escalar multilinha `>-`, `|` e continuação
#   indentada medidos pelo TEXTO (4.385 — o marcador sozinho passava); consumidor
#   sem manifesto → silêncio; stop_hook_active → silêncio; cwd ausente → silêncio;
#   o bloqueio nomeia o arquivo, a contagem e o teto.
#
# Uso: scripts/tests/desc-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/desc-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "desc-guard: AVISO — python3 ausente, o hook degrada e a suíte não prova nada; pulando." >&2; exit 0; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n desc-guard.sh"; exit 1; }
echo "ok   bash -n desc-guard.sh"

PLUG="$TMP/plugin"
reset_plugin() {
  rm -rf "$PLUG"
  mkdir -p "$PLUG/.claude-plugin" "$PLUG/commands" "$PLUG/skills/uma" "$PLUG/agents"
  printf '{ "name": "keelson", "version": "0.0.0" }\n' > "$PLUG/.claude-plugin/plugin.json"
}

# repeat <char> <n>
rep() { python3 -c 'import sys; print(sys.argv[1]*int(sys.argv[2]), end="")' "$1" "$2"; }

# frontmatter <arquivo> <descricao-literal-yaml>
fm() { printf -- '---\nname: x\ndescription: %s\n---\n\ncorpo\n' "$2" > "$1"; }

payload() { printf '{"cwd": "%s", "stop_hook_active": false}' "$1"; }

decisao() { # payload → block | allow | erro:<st>
  out="$(bash "$HOOK" 2>"$TMP/err" <<< "$1")"
  st=$?
  [ "$st" -eq 0 ] || { printf 'erro:%s' "$st"; return; }
  if [ -z "$out" ]; then printf 'allow'
  elif printf '%s' "$out" | python3 -c 'import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get("decision")=="block" else 1)' 2>/dev/null; then printf 'block'
  else printf 'outro:%s' "$out"; fi
}

caso() { # nome esperado [payload]
  name="$1"; want="$2"; pl="${3:-$(payload "$PLUG")}"
  total=$((total + 1))
  got="$(decisao "$pl")"
  if [ "$got" = "$want" ]; then echo "ok   $name"
  else echo "FAIL $name: esperado $want, veio $got"; fail=$((fail + 1)); fi
}

# --- fronteiras ---
reset_plugin; fm "$PLUG/commands/a.md" "$(rep a 250)"; caso command-250-allow allow
reset_plugin; fm "$PLUG/commands/a.md" "$(rep a 251)"; caso command-251-block block
reset_plugin; fm "$PLUG/skills/uma/SKILL.md" "$(rep a 250)"; caso skill-250-allow allow
reset_plugin; fm "$PLUG/skills/uma/SKILL.md" "$(rep a 251)"; caso skill-251-block block
reset_plugin; fm "$PLUG/agents/a.md" "$(rep a 350)"; caso agent-350-allow allow
reset_plugin; fm "$PLUG/agents/a.md" "$(rep a 351)"; caso agent-351-block block
reset_plugin; fm "$PLUG/agents/a.md" "$(rep a 251)"; caso agent-251-allow-teto-proprio allow

# --- aspas e code points ---
reset_plugin; fm "$PLUG/commands/a.md" "\"$(rep a 250)\""; caso aspas-duplas-nao-contam allow
reset_plugin; fm "$PLUG/commands/a.md" "'$(rep a 250)'"; caso aspas-simples-nao-contam allow
reset_plugin; fm "$PLUG/commands/a.md" "\"$(rep a 251)\""; caso aspas-251-block block
reset_plugin; fm "$PLUG/commands/a.md" "$(rep é 250)"; caso unicode-250-code-points-allow allow
reset_plugin; fm "$PLUG/commands/a.md" "$(rep é 251)"; caso unicode-251-block block

# --- escalar multilinha (4.385) ---
reset_plugin
printf -- '---\nname: x\ndescription: >-\n  %s\n  %s\n---\n\ncorpo\n' "$(rep a 125)" "$(rep b 125)" > "$PLUG/commands/a.md"
caso folded-251-block block            # 125 + espaço + 125 = 251
reset_plugin
printf -- '---\nname: x\ndescription: >-\n  %s\n  %s\n---\n\ncorpo\n' "$(rep a 125)" "$(rep b 124)" > "$PLUG/commands/a.md"
caso folded-250-allow allow
reset_plugin
printf -- '---\nname: x\ndescription: |\n  %s\n  %s\n---\n\ncorpo\n' "$(rep a 125)" "$(rep b 125)" > "$PLUG/commands/a.md"
caso literal-251-block block           # 125 + quebra + 125 = 251
reset_plugin
printf -- '---\nname: x\ndescription: %s\n  %s\n---\n\ncorpo\n' "$(rep a 125)" "$(rep b 125)" > "$PLUG/commands/a.md"
caso continuacao-indentada-251-block block
reset_plugin
printf -- '---\nname: x\ndescription: >-\n  %s\n\n---\n\ncorpo\n' "$(rep a 251)" > "$PLUG/commands/a.md"
caso folded-linha-vazia-final-251-block block
reset_plugin
printf -- '---\nname: x\ndescription: >-\n  %s\nother: y\n---\n\ncorpo\n' "$(rep a 250)" > "$PLUG/commands/a.md"
caso folded-para-no-proximo-campo-allow allow

# --- mensagem nomeia arquivo, contagem e teto ---
reset_plugin; fm "$PLUG/commands/longo.md" "$(rep a 260)"
total=$((total + 1))
out="$(bash "$HOOK" 2>/dev/null <<< "$(payload "$PLUG")")"
if printf '%s' "$out" | grep -q 'commands/longo.md (260 caracteres; teto 250)'; then echo "ok   mensagem-nomeia-arquivo"
else echo "FAIL mensagem-nomeia-arquivo: $out"; fail=$((fail + 1)); fi

# --- escopo e fallback gracioso ---
reset_plugin; fm "$PLUG/commands/a.md" "$(rep a 300)"
caso stop-hook-active-allow allow "$(printf '{"cwd": "%s", "stop_hook_active": true}' "$PLUG")"
caso cwd-ausente-allow allow '{"stop_hook_active": false}'
caso cwd-inexistente-allow allow "$(payload "$TMP/nao-existe")"
caso json-invalido-allow allow '{nao e json'
CONS="$TMP/consumidor"; mkdir -p "$CONS/commands"; fm "$CONS/commands/a.md" "$(rep a 300)"
caso consumidor-sem-manifesto-allow allow "$(payload "$CONS")"
mkdir -p "$CONS/.claude-plugin"; printf '{ "name": "outro" }\n' > "$CONS/.claude-plugin/plugin.json"
caso manifesto-de-outro-plugin-allow allow "$(payload "$CONS")"
reset_plugin; printf 'sem frontmatter\n' > "$PLUG/commands/a.md"; caso sem-frontmatter-allow allow
reset_plugin; printf -- '---\nname: x\n---\n' > "$PLUG/commands/a.md"; caso sem-description-allow allow

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "desc-guard: $fail de $total casos falharam"
  exit 1
fi
echo "desc-guard: $total casos verdes"
exit 0
