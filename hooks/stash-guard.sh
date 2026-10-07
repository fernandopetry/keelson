#!/usr/bin/env bash
# stash-guard — hook PreToolUse (Bash) que nega `git stash` que MUTA a árvore de
# trabalho compartilhada (decisão 4.463): `push`/`save`/forma nua, `pop`, `apply`,
# `drop`, `clear`, `branch`.
#
# Por quê: a árvore principal tem leitores o tempo todo (outros agents, o humano,
# sessões paralelas) e a pilha de stash é UMA por repositório — `pop`/`apply`
# trazem o topo da pilha, que pode ser de outra sessão ou do humano; `push`/`drop`/
# `clear` apagam o que outro ator ainda lê. A comparação antes/depois que o
# developer precisa tem forma que não toca nada: `git stash create` (fotografa sem
# mover) + `git worktree add --detach`, ou `git diff > patch`. O hook cobre quem
# não leu a regra: mexer na pilha é ato DECLARADO do humano, nunca do modelo.
#
# Passam: `git stash create`, `git stash list`, `git stash show`, `git stash store`
# (nenhuma muta a árvore nem consome a pilha).
#
# Escape consciente e nomeado (mesma régua do noverify-guard): prefixar o comando
# com KEELSON_ALLOW_STASH=1 — o humano que sabe por que está mexendo na pilha diz
# isso no próprio comando, e o rastro fica no transcript.
#
# Texto citado não é execução (4.384): comando simples que começa por emissor de
# texto (printf/echo/grep/rg/sed) é dado — a absolvição cai se qualquer comando
# simples da linha é interpretador (bash/sh/zsh/eval/xargs/source/.).
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem input parseável
# ou qualquer erro → exit 0, nunca travar o fluxo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# Só interessa `git … stash` num comando simples (sem atravessar | ; &&).
RE='(^|[^A-Za-z0-9_./-])git[^|;&]*[[:space:]]stash([[:space:]"'"'"')]|$)'
printf '%s' "$cmd" | grep -Eq "$RE" || exit 0

# Subcomando do stash num segmento: primeira palavra depois de `stash` que não é
# opção, sem aspas/parênteses de fechamento (`$(git stash create)`, `"git stash pop"`);
# vazio = forma nua = push.
stash_sub() {
  printf '%s' "$1" \
    | sed -E 's/^.*[[:space:]]stash([[:space:]]+|$)//' \
    | awk '{ for (i = 1; i <= NF; i++) { w = $i; gsub(/[()"'"'"']/, "", w); if (w == "") continue; if (w !~ /^-/) { print w; exit } } }'
}

exec_hit=0; interp=0; sub_hit=""
while IFS= read -r seg; do
  first="$(printf '%s' "$seg" \
    | sed -E 's/^[[:space:]]*//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*//' \
    | awk '{print $1}')"
  case "$first" in bash|sh|zsh|eval|xargs|source|.) interp=1 ;; esac
  printf '%s' "$seg" | grep -Eq "$RE" || continue
  sub="$(stash_sub "$seg")"
  case "$sub" in create|list|show|store) continue ;; esac
  [ -n "$sub" ] || sub="push"
  case "$first" in printf|echo|grep|rg|sed) ;; *) exec_hit=1; sub_hit="$sub" ;; esac
done <<EOF
$(printf '%s' "$cmd" | tr '|;&' '\n')
EOF
if [ "$exec_hit" -eq 0 ]; then
  # Só texto citado — a absolvição cai com interpretador na linha, se o texto
  # citado carrega um stash que muta.
  [ "$interp" -eq 1 ] || exit 0
  mut=0
  while IFS= read -r seg; do
    printf '%s' "$seg" | grep -Eq "$RE" || continue
    sub="$(stash_sub "$seg")"
    case "$sub" in create|list|show|store) ;; *) mut=1 ;; esac
  done <<EOF
$(printf '%s' "$cmd" | tr '|;&' '\n')
EOF
  [ "$mut" -eq 1 ] || exit 0
  sub_hit="citado"
fi

# Escape nomeado: o humano assumiu o stash explicitamente.
case "$cmd" in
  *KEELSON_ALLOW_STASH=1*) exit 0 ;;
esac

reason="stash-guard (keelson, decisão 4.463): \`git stash ${sub_hit}\` muta a árvore de trabalho compartilhada — a pilha de stash é uma por repositório: pop/apply trazem o topo, que pode ser de outra sessão ou do humano; push/drop/clear apagam o que outro ator ainda lê. Comparar antes/depois sem tocar em nada: \`sha=\$(git stash create)\` + \`git worktree add --detach <casa>/tools/<nome> \"\$sha\"\`, ou \`git diff > <arquivo>.patch\` (agents/developer.md, protocolo de mutação). Se mexer na pilha for um ato consciente do humano, ele aprova repetindo o comando prefixado com KEELSON_ALLOW_STASH=1."
jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
