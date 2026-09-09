#!/usr/bin/env bash
# check-templates.sh — sincronia dos templates canônicos dos artefatos SDD (decisão 4.405).
#
# O que a doutrina exige (CLAUDE.md, "Ao mudar comando ou doutrina") e este script prova:
#   1. templates/artifacts/{SPEC,PLAN,TASK,TASK-INDEX}.md existem e não estão vazios;
#   2. dono único da forma: nenhum commands/*.md carrega segunda cópia do esqueleto
#      (linha de heading raiz do artefato — `# SPEC-NNN:`, `# PLAN-MMM:`,
#      `# TASK-MMM-XXX:`, `# Índice de tarefas do PLAN-MMM` — fora de templates/);
#   3. o comando gerador aponta o template pelo caminho (specify → SPEC, plan → PLAN,
#      tasks → TASK e TASK-INDEX);
#   4. template ⇄ lint: cada template de SPEC/PLAN/TASK, copiado com nome de artefato
#      real, passa por scripts/artifact-lint.sh SEM nenhum `*-secao-ausente` — o
#      esqueleto que o scribe reproduz tem todo heading que o lint exige. Os demais
#      achados do lint (placeholders de enum/data) são esperados e ignorados.
#
# Limite honesto: prova headings, não conteúdo — a régua de cada seção segue humana
# (validators) e comportamental (evals).
#
# Uso: check-templates.sh [--root <dir>]   (default: raiz do repo via git)
# Exit: 0 tudo certo · 1 violações · 2 uso incorreto / dependência ausente.
# Bash 3.2-compatível, POSIX grep/sed/awk, read-only (escreve só em mktemp).

set -u
LC_ALL=C
export LC_ALL

ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "ERRO: --root exige valor" >&2; exit 2; }; ROOT="$2"; shift 2 ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: fora de repo git e sem --root" >&2; exit 2; }
fi
[ -d "$ROOT" ] || { echo "ERRO: raiz inexistente: $ROOT" >&2; exit 2; }
TPL="$ROOT/templates/artifacts"
LINT="$ROOT/scripts/artifact-lint.sh"
[ -f "$LINT" ] || { echo "ERRO: scripts/artifact-lint.sh ausente em $ROOT" >&2; exit 2; }

fail=0
viol() { echo "VIOLACAO: $*"; fail=1; }

# 1. existência
for t in SPEC PLAN TASK TASK-INDEX; do
  f="$TPL/$t.md"
  if [ ! -s "$f" ]; then viol "template ausente ou vazio: templates/artifacts/$t.md"; fi
done

# 2. dono único: esqueleto não mora em comando nenhum
if [ -d "$ROOT/commands" ]; then
  dup="$(grep -n -E '^# (SPEC-NNN:|PLAN-MMM:|TASK-MMM-XXX:|Índice de tarefas do PLAN-MMM)' "$ROOT"/commands/*.md 2>/dev/null || true)"
  if [ -n "$dup" ]; then
    printf '%s\n' "$dup" | while IFS= read -r l; do
      viol "segunda cópia do esqueleto num comando (dono é templates/artifacts/): ${l#"$ROOT"/}"
    done
    fail=1
  fi
fi

# 3. ponteiro do comando gerador ao template
ptr() { # $1 comando  $2 template
  c="$ROOT/commands/$1.md"
  [ -f "$c" ] || return 0
  grep -q "templates/artifacts/$2.md" "$c" || viol "commands/$1.md não aponta templates/artifacts/$2.md"
}
ptr specify SPEC
ptr plan PLAN
ptr tasks TASK
ptr tasks TASK-INDEX

# 4. template ⇄ lint (headings obrigatórios presentes)
TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/specs" "$TMP/plans" "$TMP/tasks"
lintcheck() { # $1 template  $2 destino relativo
  src="$TPL/$1.md"
  [ -s "$src" ] || return 0
  cp "$src" "$TMP/$2"
  out="$(bash "$LINT" "$TMP/$2" 2>&1 || true)"
  miss="$(printf '%s\n' "$out" | grep -- '-secao-ausente' || true)"
  if [ -n "$miss" ]; then
    printf '%s\n' "$miss" | while IFS= read -r l; do
      viol "templates/artifacts/$1.md sem heading que o lint exige: $l"
    done
    fail=1
  fi
}
lintcheck SPEC specs/SPEC-000-template.md
lintcheck PLAN plans/PLAN-000-template.md
lintcheck TASK tasks/TASK-000-001-template.md

if [ "$fail" -eq 0 ]; then
  echo "check-templates: ok (4 templates · dono único · ponteiros · headings do lint)"
  exit 0
fi
exit 1
