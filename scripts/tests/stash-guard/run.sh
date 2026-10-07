#!/usr/bin/env bash
# run.sh — suíte de regressão do stash-guard (decisão 4.463).
#
# Roda o hook de verdade (stdin JSON, jq). Casos inline, asserção pelo campo
# permissionDecision (deny) ou silêncio (allow):
#   deny  — stash nu, push, save, pop, apply, drop, clear, branch; com opções antes
#           do subcomando (-u, -m); `git -C dir stash pop`; encadeado com && ; |;
#           via `bash -c`; texto emitido por printf/echo e entregue a um
#           interpretador (`| bash`, `eval`) — a absolvição de texto cai com
#           interpretador;
#   allow — create, list, show, store (não mutam nem consomem a pilha); `git stash`
#           noutro comando do pipeline que só imprime; escape KEELSON_ALLOW_STASH=1;
#           TEXTO CITADO por printf/echo/grep/rg/sed (4.384); `stash` como palavra
#           solta fora de `git`; input vazio; JSON inválido; comando ausente.
#
# Uso: scripts/tests/stash-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/stash-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "stash-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n stash-guard.sh"; exit 1; }
echo "ok   bash -n stash-guard.sh"

payload() { jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}'; }

decisao() { # stdin-json → "deny" | "allow" | "erro:<exit>"
  out="$(bash "$HOOK" 2>"$TMP/err" <<< "$1")"
  st=$?
  [ "$st" -eq 0 ] || { printf 'erro:%s' "$st"; return; }
  d="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
  if [ "$d" = "deny" ]; then printf 'deny'; elif [ -z "$out" ]; then printf 'allow'; else printf 'outro:%s' "$out"; fi
}

caso() { # nome esperado comando
  name="$1"; want="$2"; cmd="$3"
  total=$((total + 1))
  got="$(decisao "$(payload "$cmd")")"
  if [ "$got" = "$want" ]; then echo "ok   $name"
  else echo "FAIL $name: esperado $want, veio $got"; fail=$((fail + 1)); fi
}

# --- deny: muta a árvore ou consome a pilha ---
caso nu-deny                deny  'git stash'
caso push-deny              deny  'git stash push -m "wip"'
caso save-deny              deny  'git stash save wip'
caso pop-deny               deny  'git stash pop'
caso apply-deny             deny  'git stash apply stash@{0}'
caso drop-deny              deny  'git stash drop'
caso clear-deny             deny  'git stash clear'
caso branch-deny            deny  'git stash branch fix-x'
caso opcao-antes-deny       deny  'git stash -u'
caso dash-C-deny            deny  'git -C /tmp/x stash pop'
caso encadeado-and-deny     deny  'npm test && git stash pop'
caso encadeado-semi-deny    deny  'git stash; npm test; git stash pop'
caso pipeline-deny          deny  'git stash pop | tee out.log'
caso env-prefixo-deny       deny  'GIT_DIR=.git git stash push'
caso bash-c-deny            deny  'bash -c "git stash pop"'
caso printf-pipe-bash-deny  deny  "printf '%s\\n' 'git stash pop' | bash"
caso eval-deny              deny  'eval "git stash"'
caso xargs-deny             deny  'echo pop | xargs git stash'

# --- allow: não muta nem consome ---
caso create-allow           allow 'sha=$(git stash create)'
caso list-allow             allow 'git stash list'
caso show-allow             allow 'git stash show -p stash@{0}'
caso store-allow            allow 'git stash store -m x "$sha"'
caso create-worktree-allow  allow 'sha=$(git stash create); git worktree add --detach /tmp/mut "$sha"'
caso escape-allow           allow 'KEELSON_ALLOW_STASH=1 git stash pop'
caso outro-git-allow        allow 'git status && git diff --stat'
caso palavra-solta-allow    allow 'grep -rn stash docs/'
caso diff-patch-allow       allow 'git diff > /tmp/antes.patch'

# --- allow: texto citado (4.384) ---
caso printf-literal-allow   allow "printf '%s\\n' 'git stash pop'"
caso echo-literal-allow     allow 'echo "nunca use git stash pop na árvore principal"'
caso grep-literal-allow     allow 'grep -n "git stash pop" agents/developer.md'
caso sed-literal-allow      allow 'sed -n "/git stash apply/p" docs/x.md'

# --- allow: degradação graciosa ---
total=$((total + 1))
got="$(decisao '')"
if [ "$got" = "allow" ]; then echo "ok   input-vazio-allow"; else echo "FAIL input-vazio-allow: veio $got"; fail=$((fail + 1)); fi
total=$((total + 1))
got="$(decisao '{nao-e-json')"
if [ "$got" = "allow" ]; then echo "ok   json-invalido-allow"; else echo "FAIL json-invalido-allow: veio $got"; fail=$((fail + 1)); fi
total=$((total + 1))
got="$(decisao '{"tool_name":"Bash","tool_input":{}}')"
if [ "$got" = "allow" ]; then echo "ok   comando-ausente-allow"; else echo "FAIL comando-ausente-allow: veio $got"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "stash-guard: $fail de $total casos falharam"
  exit 1
fi
echo "stash-guard: $total casos verdes"
exit 0
