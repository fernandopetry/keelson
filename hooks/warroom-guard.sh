#!/usr/bin/env bash
# warroom-guard — hook Stop do modo warroom (decisão 4.372).
#
# Duas funções, nunca as duas no mesmo turno:
#   1. Warroom ATIVO nesta sessão (marcador `warroom.meta` na casa da sessão, 4.314)
#      → reconcilia `{docsRoot}/DEBT.md` a partir do git (scripts/warroom.sh reconcile):
#      cada commit da branch desde a base da janela que ainda não está listado vira
#      linha aberta de dívida. É por isso que o DEBT.md não depende de ninguém
#      lembrar — a fonte é `git log`, e roda a cada fim de turno. Silencioso, nunca
#      bloqueia (a régua do modo é sair rápido).
#   2. Warroom INATIVO e DEBT.md com linha aberta → cutuca UMA vez (por conjunto de
#      linhas abertas) lembrando que há dívida de verificação a cobrar — com
#      `/keelson:warroom close` (gates sobre o diff acumulado) ou `warroom.sh settle`.
#      Dívida registrada e nunca cobrada é o risco nomeado da decisão; esta cutucada é
#      a mitigação mecânica dele.
#
# Fallback gracioso (padrão dos hooks do keelson): sem jq, sem ficha, sem git ou sem o
# script → exit 0, nunca travar o fluxo. `stop_hook_active` evita loop no turno;
# marcador em .git/ evita re-cutucar enquanto o conjunto de dívidas abertas for o
# mesmo. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -f "$proj/keelson.config.json" ] || exit 0

WARROOM="$(cd "$(dirname "$0")/../scripts" 2>/dev/null && pwd || true)/warroom.sh"
[ -f "$WARROOM" ] || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")"

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
cd "$proj" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

status="$(KEELSON_SESSAO="$session_id" bash "$WARROOM" "$proj" status 2>/dev/null | sed -n 1p || true)"

# --- 1. ativo → reconcilia em silêncio ---
if [ "$status" = "ativo" ]; then
  KEELSON_SESSAO="$session_id" bash "$WARROOM" "$proj" reconcile >/dev/null 2>&1 || true
  exit 0
fi

# --- 2. inativo → dívida aberta cutuca 1× por conjunto ---
abertas="$(KEELSON_SESSAO="$session_id" bash "$WARROOM" "$proj" open-debts 2>/dev/null || true)"
[ -n "$abertas" ] || exit 0

n="$(printf '%s\n' "$abertas" | wc -l | tr -d ' ')"
hashes="$(printf '%s\n' "$abertas" | sed -n 's/^- \[ \] `\([0-9a-f]*\)`.*/\1/p' | tr '\n' ' ')"

git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-warroom-guard.last"
  fingerprint="$(printf '%s' "$hashes" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

droot="$(jq -r '.docsRoot // "docs"' "$proj/keelson.config.json" 2>/dev/null || echo docs)"
reason="$(cat <<EOF
Dívida de verificação do warroom (keelson, decisão 4.372): ${n} commit(s) saíram sem gate numa janela de warroom e continuam abertos em ${droot}/DEBT.md — ${hashes}.

Antes de encerrar, declare a dívida no relatório de fecho (linha "Pendente de você") e proponha ao Diretor a cobrança:
- /keelson:warroom close — roda os gates sobre o diff acumulado e fecha cada linha como resolvida ou assumida (humano-only: sugira, não invoque);
- ou, linha a linha, \`scripts/warroom.sh <raiz> settle <hash> resolvida|assumida <nota>\` após os gates rodarem.

Dívida registrada e nunca cobrada é dívida perdoada; este aviso não se repete enquanto o conjunto de linhas abertas for o mesmo.
EOF
)"
if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi
jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
exit 0
