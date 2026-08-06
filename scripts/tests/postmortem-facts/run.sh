#!/usr/bin/env bash
# run.sh — suíte de regressão do postmortem-facts.sh (decisão 4.154).
#
# Regras provadas: versão do plugin extraída do plugin.json, janela de commits com
# --since (commits + diffstat), campo indisponível vira "-" declarado, ref inválida
# é exit 2.
#
# Uso: scripts/tests/postmortem-facts/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige git.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
PF="$HERE/../../postmortem-facts.sh"

[ -f "$PF" ] || { echo "ERRO: postmortem-facts.sh não encontrado" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

PR="$TMP/plugin"
mkdir -p "$PR/.claude-plugin"
printf '{\n  "name": "keelson",\n  "version": "9.9.9"\n}\n' > "$PR/.claude-plugin/plugin.json"

R="$TMP/repo"
mkdir -p "$R"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" checkout -qb main; }
git -C "$R" config user.email t@t
git -C "$R" config user.name t
printf '1\n' > "$R/a.txt"; git -C "$R" add -A; git -C "$R" commit -qm "first change"
printf '2\n' > "$R/b.txt"; git -C "$R" add -A; git -C "$R" commit -qm "second change"

total=$((total + 1))
got="$(bash "$PF" --repo "$R" --since HEAD~1 --plugin-root "$PR" 2>/dev/null)"; st=$?
v="$(printf '%s\n' "$got" | sed -n 's/^versao=//p')"
b="$(printf '%s\n' "$got" | sed -n 's/^branch=//p')"
c="$(printf '%s\n' "$got" | grep -c '^commit	')"
d="$(printf '%s\n' "$got" | sed -n 's/^diffstat=//p')"
if [ "$st" -eq 0 ] && [ "$v" = "9.9.9" ] && [ "$b" = "main" ] && [ "$c" = "1" ] \
   && printf '%s\n' "$got" | grep -q 'commit	.*	second change' && [ -n "$d" ] && [ "$d" != "-" ]; then
  echo "ok   janela"
else
  echo "FAIL janela (exit $st):"; printf '%s\n' "$got" | sed 's/^/  /'; fail=$((fail + 1))
fi

# sem --since: só cabeçalho
total=$((total + 1))
got="$(bash "$PF" --repo "$R" --plugin-root "$PR" 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && [ "$(printf '%s\n' "$got" | grep -c '^commit	')" = "0" ] \
   && printf '%s\n' "$got" | grep -q '^head='; then echo "ok   sem-since"
else echo "FAIL sem-since: [$got]"; fail=$((fail + 1)); fi

# fora de repo git: campos "-" declarados
R2="$TMP/sem-git"; mkdir -p "$R2"
total=$((total + 1))
got="$(bash "$PF" --repo "$R2" --plugin-root "$PR" 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && printf '%s\n' "$got" | grep -q '^branch=-$'; then echo "ok   sem-git-declarado"
else echo "FAIL sem-git-declarado: [$got]"; fail=$((fail + 1)); fi

# plugin-root sem plugin.json: versao=-
total=$((total + 1))
got="$(bash "$PF" --repo "$R" --plugin-root "$R2" 2>/dev/null)"; st=$?
if [ "$st" -eq 0 ] && printf '%s\n' "$got" | grep -q '^versao=-$'; then echo "ok   versao-indisponivel"
else echo "FAIL versao-indisponivel: [$got]"; fail=$((fail + 1)); fi

# ref inválida → exit 2
total=$((total + 1))
bash "$PF" --repo "$R" --since nao-existe --plugin-root "$PR" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   ref-invalida-exit-2" || { echo "FAIL ref-invalida-exit-2"; fail=$((fail + 1)); }

echo "---"
if [ "$fail" -gt 0 ]; then echo "postmortem-facts: $fail de $total casos falharam"; exit 1; fi
echo "postmortem-facts: $total casos verdes"
exit 0
