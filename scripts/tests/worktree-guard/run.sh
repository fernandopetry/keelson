#!/usr/bin/env bash
# run.sh — suíte de regressão do worktree-guard (decisões 4.30/4.385).
#
# Roda o hook de verdade (stdin JSON, jq, git) num repo temporário com uma
# worktree vinculada. CLAUDE_PROJECT_DIR aponta a worktree (a sessão) ou o
# checkout principal. Casos inline:
#   deny  — Edit/Write/NotebookEdit cujo alvo resolve para o CHECKOUT PRINCIPAL
#           (absoluto, relativo com cwd do principal, arquivo novo, diretório novo,
#           caminho com espaço, symlink físico para o principal);
#   allow — alvo dentro da worktree (absoluto, relativo com cwd da worktree,
#           arquivo novo); alvo fora de qualquer repo; alvo dentro do .git comum;
#           sessão no checkout principal (não é worktree vinculada); repo sem
#           worktree; input sem file_path; JSON inválido; input vazio.
#
# Uso: scripts/tests/worktree-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/worktree-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "worktree-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"   # macOS: /var → /private/var, o hook canoniza fisicamente

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n worktree-guard.sh"; exit 1; }
echo "ok   bash -n worktree-guard.sh"

MAIN="$TMP/main"; WT="$TMP/wt"
mkdir -p "$MAIN"
git -C "$MAIN" init -q 2>/dev/null || { echo "ERRO: git init falhou" >&2; exit 1; }
git -C "$MAIN" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf 'a\n' > "$MAIN/arquivo.txt"; mkdir -p "$MAIN/src"; printf 'b\n' > "$MAIN/src/x.txt"
git -C "$MAIN" add -A; git -C "$MAIN" -c user.email=t@t -c user.name=t commit -q -m files
if ! git -C "$MAIN" worktree add -q "$WT" -b feat 2>/dev/null; then
  echo "worktree-guard: AVISO — git worktree indisponível; pulando." >&2
  exit 0
fi

payload() { # file_path [cwd] [campo]
  campo="${3:-file_path}"
  if [ -n "${2:-}" ]; then jq -cn --arg f "$1" --arg c "$2" --arg k "$campo" '{tool_name:"Edit", cwd:$c, tool_input:{($k):$f}}'
  else jq -cn --arg f "$1" --arg k "$campo" '{tool_name:"Edit", tool_input:{($k):$f}}'; fi
}

decisao() { # proj payload → deny | allow | erro:<st>
  out="$(CLAUDE_PROJECT_DIR="$1" bash "$HOOK" 2>"$TMP/err" <<< "$2")"
  st=$?
  [ "$st" -eq 0 ] || { printf 'erro:%s' "$st"; return; }
  d="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
  if [ "$d" = "deny" ]; then printf 'deny'; elif [ -z "$out" ]; then printf 'allow'; else printf 'outro:%s' "$out"; fi
}

caso() { # nome esperado proj payload
  name="$1"; want="$2"
  total=$((total + 1))
  got="$(decisao "$3" "$4")"
  if [ "$got" = "$want" ]; then echo "ok   $name"
  else echo "FAIL $name: esperado $want, veio $got"; fail=$((fail + 1)); fi
}

# --- sessão na worktree: alvo no checkout principal → deny ---
caso principal-absoluto-deny        deny  "$WT" "$(payload "$MAIN/arquivo.txt")"
caso principal-subdir-deny          deny  "$WT" "$(payload "$MAIN/src/x.txt")"
caso principal-arquivo-novo-deny    deny  "$WT" "$(payload "$MAIN/novo.txt")"
caso principal-dir-novo-deny        deny  "$WT" "$(payload "$MAIN/novo/dir/novo.txt")"
caso principal-relativo-cwd-deny    deny  "$WT" "$(payload "src/x.txt" "$MAIN")"
mkdir -p "$MAIN/com espaco"; printf 'c\n' > "$MAIN/com espaco/f.txt"
caso principal-com-espaco-deny      deny  "$WT" "$(payload "$MAIN/com espaco/f.txt")"
caso notebook-path-deny             deny  "$WT" "$(payload "$MAIN/nb.ipynb" "" notebook_path)"
ln -s "$MAIN/src" "$WT/link-para-main" 2>/dev/null
if [ -L "$WT/link-para-main" ]; then
  caso symlink-fisico-para-principal-deny deny "$WT" "$(payload "$WT/link-para-main/x.txt")"
fi
caso raiz-principal-deny            deny  "$WT" "$(payload "$MAIN")"

# --- sessão na worktree: alvo legítimo → allow ---
caso worktree-absoluto-allow        allow "$WT" "$(payload "$WT/arquivo.txt")"
caso worktree-arquivo-novo-allow    allow "$WT" "$(payload "$WT/novo.txt")"
caso worktree-relativo-cwd-allow    allow "$WT" "$(payload "src/x.txt" "$WT")"
caso worktree-relativo-sem-cwd-allow allow "$WT" "$(payload "src/x.txt")"   # cwd do hook = fora → resolve fora do principal
caso fora-de-repo-allow             allow "$WT" "$(payload "$TMP/externo.txt")"
caso dentro-do-git-comum-allow      allow "$WT" "$(payload "$MAIN/.git/keelson-marker")"
caso outro-repo-allow               allow "$WT" "$(payload "$TMP/outro/repo/f.txt")"

# --- sessão no checkout principal: não é worktree vinculada → allow ---
caso principal-edita-principal-allow allow "$MAIN" "$(payload "$MAIN/arquivo.txt")"
caso principal-edita-worktree-allow  allow "$MAIN" "$(payload "$WT/arquivo.txt")"

# --- repo sem worktree ---
SOLO="$TMP/solo"; mkdir -p "$SOLO"; git -C "$SOLO" init -q; printf 'x\n' > "$SOLO/f.txt"
caso repo-comum-allow               allow "$SOLO" "$(payload "$SOLO/f.txt")"

# --- fallback gracioso ---
caso sem-file-path-allow            allow "$WT" '{"tool_name":"Edit","tool_input":{}}'
caso json-invalido-allow            allow "$WT" '{nao e json'
total=$((total + 1))
got="$(decisao "$WT" '')"
if [ "$got" = "allow" ]; then echo "ok   input-vazio-allow"; else echo "FAIL input-vazio-allow: $got"; fail=$((fail + 1)); fi

# deny nomeia a worktree, o principal e o alvo
total=$((total + 1))
out="$(CLAUDE_PROJECT_DIR="$WT" bash "$HOOK" 2>/dev/null <<< "$(payload "$MAIN/arquivo.txt")")"
r="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty')"
case "$r" in
  *"worktree $WT"*"CHECKOUT PRINCIPAL ($MAIN)"*"$MAIN/arquivo.txt"*) echo "ok   deny-nomeia-caminhos" ;;
  *) echo "FAIL deny-nomeia-caminhos: $r"; fail=$((fail + 1)) ;;
esac

git -C "$MAIN" worktree remove --force "$WT" >/dev/null 2>&1 || true

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "worktree-guard: $fail de $total casos falharam"
  exit 1
fi
echo "worktree-guard: $total casos verdes"
exit 0
