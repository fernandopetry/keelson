#!/usr/bin/env bash
# run.sh — suíte de regressão do noverify-guard (decisões 4.66/4.384).
#
# Roda o hook de verdade (stdin JSON, jq). Casos inline, asserção pelo campo
# permissionDecision (deny) ou silêncio (allow):
#   deny  — commit/push com --no-verify; encadeado com && ; |; via `bash -c`;
#           texto emitido por printf/echo e entregue a um interpretador (`| bash`,
#           `| sh`, `eval`, `xargs`) — a absolvição de texto cai com interpretador;
#   allow — commit/push normais; a flag noutro comando do pipeline; escape
#           KEELSON_ALLOW_NO_VERIFY=1; TEXTO CITADO por printf/echo/grep/rg/sed
#           (4.384 — falso positivo reproduzido em sessão do mantenedor: a linha
#           que só imprime o literal era negada); input vazio; JSON inválido;
#           comando ausente.
#
# Uso: scripts/tests/noverify/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/noverify-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "noverify: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n noverify-guard.sh"; exit 1; }
echo "ok   bash -n noverify-guard.sh"

# payload <comando> → JSON de PreToolUse(Bash) com o comando (jq escapa)
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

# --- deny: execução real ---
caso commit-deny            deny  'git commit -m "x" --no-verify'
caso push-deny              deny  'git push --no-verify origin main'
caso encadeado-and-deny     deny  'echo pronto && git commit -m x --no-verify'
caso encadeado-semi-deny    deny  'npm test; git commit --no-verify -m x'
caso env-prefixo-deny       deny  'GIT_AUTHOR_NAME=x git commit --no-verify -m x'
caso bash-c-deny            deny  'bash -c "git commit -m x --no-verify"'
caso printf-pipe-bash-deny  deny  "printf '%s\\n' 'git commit --no-verify' | bash"
caso echo-pipe-sh-deny      deny  'echo "git push --no-verify" | sh'
caso eval-deny              deny  'eval "git commit -m x --no-verify"'
caso xargs-deny             deny  'echo x | xargs git commit --no-verify -m'

# --- allow: sem contorno ---
caso commit-normal-allow    allow 'git commit -m "feat: x"'
caso push-normal-allow      allow 'git push origin main'
caso outro-comando-pipeline allow 'grep -r no-verify docs | git commit -m x'
caso outra-flag-allow       allow 'git commit -m x --no-edit'
caso escape-allow           allow 'KEELSON_ALLOW_NO_VERIFY=1 git commit -m x --no-verify'

# --- allow: texto citado (4.384) ---
caso printf-literal-allow   allow "printf '%s\\n' 'git commit --no-verify'"
caso echo-literal-allow     allow 'echo "nunca use git commit --no-verify"'
caso grep-literal-allow     allow "grep -rn 'git commit --no-verify' docs/"
caso rg-literal-allow       allow "rg 'git push --no-verify' ."
caso sed-literal-allow      allow "sed -n '/git commit --no-verify/p' TESTING.md"
caso printf-pipe-jq-allow   allow "printf '%s' 'git commit --no-verify' | jq -R ."

# --- allow: input degradado (fallback gracioso) ---
total=$((total + 1))
got="$(decisao '')"
if [ "$got" = "allow" ]; then echo "ok   input-vazio-allow"; else echo "FAIL input-vazio-allow: $got"; fail=$((fail + 1)); fi
total=$((total + 1))
got="$(decisao '{nao e json')"
if [ "$got" = "allow" ]; then echo "ok   json-invalido-allow"; else echo "FAIL json-invalido-allow: $got"; fail=$((fail + 1)); fi
total=$((total + 1))
got="$(decisao '{"tool_name":"Bash","tool_input":{}}')"
if [ "$got" = "allow" ]; then echo "ok   sem-comando-allow"; else echo "FAIL sem-comando-allow: $got"; fail=$((fail + 1)); fi

# deny cita o escape nomeado
total=$((total + 1))
out="$(bash "$HOOK" 2>/dev/null <<< "$(payload 'git commit -m x --no-verify')")"
if printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q 'KEELSON_ALLOW_NO_VERIFY=1'; then
  echo "ok   deny-cita-escape"
else echo "FAIL deny-cita-escape"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "noverify: $fail de $total casos falharam"
  exit 1
fi
echo "noverify: $total casos verdes"
exit 0
