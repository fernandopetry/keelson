#!/usr/bin/env bash
# run.sh — suíte do registro dos hooks em hooks/hooks.json (decisão 4.385).
#
# Um hook correto e testado que não está registrado — ou está no evento/matcher
# errado — nunca roda no consumidor, e nenhuma suíte de hook prova isso: elas
# executam o .sh diretamente. Esta suíte lê o manifesto de verdade (jq) e prova:
#   1. JSON válido com a chave "hooks";
#   2. todo hooks/*.sh está registrado EXATAMENTE uma vez, e todo comando
#      registrado aponta para um hooks/*.sh existente e executável;
#   3. a forma do comando é a canônica ("${CLAUDE_PLUGIN_ROOT}"/hooks/<nome>.sh)
#      com type "command" e timeout numérico;
#   4. a tabela congelada evento/matcher por hook (mudar um hook de evento é
#      decisão explícita, nunca efeito colateral — mesma régua do catálogo do lint).
#
# Uso: scripts/tests/hooks-manifest/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
MAN="$ROOT/hooks/hooks.json"

[ -f "$MAN" ] || { echo "ERRO: manifesto não encontrado em $MAN" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "hooks-manifest: AVISO — jq ausente; pulando." >&2
  exit 0
fi

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

# 1. JSON válido
total=$((total + 1))
if jq -e '.hooks | type == "object"' "$MAN" >/dev/null 2>&1; then ok json-valido-com-hooks; else falha json-valido-com-hooks; exit 1; fi

# registros: "<evento>\t<matcher|->\t<type>\t<command>\t<timeout>"
regs="$(jq -r '.hooks | to_entries[] | .key as $ev | .value[] | (.matcher // "-") as $m | .hooks[] | [$ev, $m, (.type // "-"), (.command // "-"), ((.timeout // "-") | tostring)] | @tsv' "$MAN")"

# 2. cobertura nos dois sentidos
total=$((total + 1))
missing=""
for f in "$ROOT"/hooks/*.sh; do
  b="$(basename "$f")"
  n="$(printf '%s\n' "$regs" | awk -F'\t' -v b="$b" '$4 ~ ("/hooks/" b "$")' | wc -l | tr -d ' ')"
  [ "$n" = "1" ] || missing="$missing $b($n)"
done
if [ -z "$missing" ]; then ok todo-hook-registrado-uma-vez; else falha "todo-hook-registrado-uma-vez:$missing"; fi

total=$((total + 1))
bad=""
# shellcheck disable=SC2034  # ev/m entram no split do @tsv; a tabela congelada os prova abaixo
while IFS="$(printf '\t')" read -r ev m ty cmd to; do
  [ -n "$cmd" ] || continue
  case "$cmd" in
    '"${CLAUDE_PLUGIN_ROOT}"/hooks/'*.sh) rel="$(printf '%s' "$cmd" | sed 's|^"\${CLAUDE_PLUGIN_ROOT}"/||')" ;;
    *) bad="$bad [forma:$cmd]"; continue ;;
  esac
  [ -f "$ROOT/$rel" ] || bad="$bad [ausente:$rel]"
  [ -x "$ROOT/$rel" ] || bad="$bad [sem-exec:$rel]"
  [ "$ty" = "command" ] || bad="$bad [type:$rel=$ty]"
  case "$to" in ''|*[!0-9]*) bad="$bad [timeout:$rel=$to]" ;; esac
done <<EOF
$regs
EOF
if [ -z "$bad" ]; then ok comando-canonico-existente-executavel-timeout; else falha "comando-canonico-existente-executavel-timeout:$bad"; fi

# 4. tabela congelada evento/matcher por hook
expect="PreToolUse	Edit|Write|NotebookEdit	worktree-guard.sh
PreToolUse	Task|Agent	agent-guard.sh
PreToolUse	Bash	noverify-guard.sh
Stop	-	doc-guard.sh
Stop	-	security-guard.sh
Stop	-	review-guard.sh
Stop	-	warroom-guard.sh
Stop	-	stale-background-guard.sh
Stop	-	wave-guard.sh
Stop	-	desc-guard.sh
Stop	-	jira-guard.sh
Stop	-	window-marker.sh
SessionStart	compact	compact-anchor.sh"
got="$(printf '%s\n' "$regs" | awk -F'\t' '{ n=$4; sub(/.*\//, "", n); print $1 "\t" $2 "\t" n }')"
total=$((total + 1))
if [ "$got" = "$expect" ]; then ok tabela-evento-matcher-congelada
else
  falha tabela-evento-matcher-congelada
  diff <(printf '%s\n' "$expect") <(printf '%s\n' "$got") | sed 's/^/  /'
fi

# Stop hooks: um único grupo (ordem de execução declarada, sem matcher)
total=$((total + 1))
ngrp="$(jq -r '.hooks.Stop | length' "$MAN")"
if [ "$ngrp" = "1" ]; then ok stop-um-grupo-ordenado; else falha "stop-um-grupo-ordenado: $ngrp grupos"; fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "hooks-manifest: $fail de $total casos falharam"
  exit 1
fi
echo "hooks-manifest: $total casos verdes"
exit 0
