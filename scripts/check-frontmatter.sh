#!/usr/bin/env bash
# check-frontmatter.sh — frontmatter de todo .md é YAML válido (decisão 4.211).
#
# O que este script prova: em cada .md cujo primeiro caractere de linha 1 é `---`,
# o bloco até o próximo `---` parseia como YAML. A classe que motivou o check
# (reincidente em campo: renderização do GitHub quebrada) é o escalar sem aspas
# contendo ": " — mas a prova preferida é o parser inteiro, não a classe.
#
# Camadas (mesmo padrão do shellcheck, 4.208):
#   - python3 + PyYAML disponíveis → parse estrito de cada bloco (prova real);
#   - ausentes → heurística (valor de chave de topo sem aspas contendo ": ") com
#     aviso — o CI, que sempre tem o parser, é a prova real.
#
# Enumeração: `git ls-files '*.md'` quando a raiz é repo git (nunca enxerga
# worktrees untracked); raiz sem git (fixtures de suíte) → find com poda de
# .git/.claude/worktrees/.harness-eval/.wiki.
#
# Uso: check-frontmatter.sh [--root <dir>] [arquivo.md ...]
#   Sem arquivos: varre a raiz inteira. Com arquivos: só eles (modo pre-commit).
# Exit: 0 tudo válido · 1 frontmatter inválido · 2 uso incorreto.
# Bash 3.2-compatível, read-only.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

ROOT=""
FILES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "uso: check-frontmatter.sh [--root <dir>] [arquivo...]" >&2; exit 2; }
            ROOT="$2"; shift 2 ;;
    -*) echo "uso: check-frontmatter.sh [--root <dir>] [arquivo...]" >&2; exit 2 ;;
    *)  FILES="$FILES$1
"; shift ;;
  esac
done
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
[ -d "$ROOT" ] || { echo "ERRO: raiz inexistente: $ROOT" >&2; exit 2; }

if [ -z "$FILES" ]; then
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    # --others --exclude-standard: pega também untracked não-ignorados (fixture
    # recém-criada conta; worktrees/.harness-eval ficam fora via .gitignore).
    FILES="$(git -C "$ROOT" ls-files --cached --others --exclude-standard -- '*.md' 2>/dev/null)"
  else
    FILES="$(find "$ROOT" \( -name .git -o -path '*/.claude/worktrees' \
      -o -name .harness-eval -o -name .wiki \) -prune -o -name '*.md' -print \
      | sed "s|^$ROOT/||")"
  fi
fi

# Só interessam arquivos que abrem com frontmatter.
cands=""
n_cand=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in scripts/tests/*/fixtures/*) continue ;; esac  # defeito plantado é da suíte
  [ -f "$ROOT/$f" ] || continue
  first="$(head -1 "$ROOT/$f" 2>/dev/null)"
  [ "$first" = "---" ] || continue
  cands="$cands$f
"
  n_cand=$((n_cand + 1))
done <<EOF_FILES
$FILES
EOF_FILES

if [ "$n_cand" -eq 0 ]; then
  echo "check-frontmatter: ok — nenhum .md com frontmatter no escopo."
  exit 0
fi

strict=0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  strict=1
fi

fails=0
if [ "$strict" -eq 1 ]; then
  out="$(printf '%s' "$cands" | python3 -c '
import sys, yaml
root = sys.argv[1]
bad = 0
for rel in sys.stdin.read().splitlines():
    if not rel:
        continue
    try:
        lines = open(f"{root}/{rel}", encoding="utf-8", errors="replace").read().split("\n")
    except OSError as e:
        print(f"ERRO: {rel}: ilegível: {e}"); bad += 1; continue
    try:
        end = lines[1:].index("---") + 1
    except ValueError:
        print(f"ERRO: {rel}: frontmatter sem fechamento (---)"); bad += 1; continue
    block = "\n".join(lines[1:end])
    try:
        yaml.safe_load(block)
    except yaml.YAMLError as e:
        msg = str(e).split("\n")[0]
        print(f"ERRO: {rel}: YAML inválido: {msg}"); bad += 1
sys.exit(1 if bad else 0)
' "$ROOT")" || true
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
    fails="$(printf '%s\n' "$out" | grep -c '^ERRO:')"
  fi
else
  echo "check-frontmatter: aviso — python3/PyYAML ausentes; só a heurística roda (o CI é a prova real)." >&2
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    hit="$(awk 'NR==1{next} /^---$/{exit}
      /^[A-Za-z-]+:[ \t]+[^"'\''| >]/ {
        v=$0; sub(/^[A-Za-z-]+:[ \t]+/, "", v)
        if (v ~ /: /) { print NR": "$0; exit }
      }' "$ROOT/$f")"
    if [ -n "$hit" ]; then
      echo "ERRO: $f: valor sem aspas contém \": \" (linha $hit)"
      fails=$((fails + 1))
    fi
  done <<EOF_CANDS
$cands
EOF_CANDS
fi

if [ "$fails" -gt 0 ]; then
  echo "check-frontmatter: $fails frontmatter(s) inválido(s) em $n_cand arquivo(s) com frontmatter." >&2
  exit 1
fi
echo "check-frontmatter: ok — $n_cand frontmatter(s) válidos."
exit 0
