#!/usr/bin/env bash
# review-guard — hook Stop que reforça o GATE 7 (code review) do keelson.
#
# LÊ A FICHA `keelson.config.json` na raiz do projeto (via jq) para se
# parametrizar — nada de caminho de código hardcoded. Da ficha extrai:
#   - gates.review          → se `false`, o hook sai sem cutucar (default: ligado);
#   - codePaths.*           → onde vive o código deste projeto;
#   - gates.reviewThreshold → limiar opcional { files, lines } (default: 2 / 30).
# Detecta mudança de código NA BRANCH acima do limiar e bloqueia o encerramento
# UMA vez, lembrando de aplicar o code review (o agent `task-reviewer` OU o
# checklist de `guidelines/core/CODE-REVIEW.md` + o perfil ativo).
#
# Limiar (Charter Art. 6 — rigor proporcional): mudança trivial passa sem cutucar.
# Dispara quando arquivos de código alterados ≥ `files` OU linhas adicionadas ≥ `lines`.
#
# Como o security-guard: compara o diff da BRANCH contra a base (merge-base com
# main/master) e filtra pelos `codePaths` da ficha; sem base determinável, cai no
# working tree (git status) e registra isso na mensagem.
#
# Fallback gracioso: sem `jq` ou sem a ficha, o hook NÃO trava o fluxo — emite
# aviso em stderr e sai 0. `stop_hook_active` evita loop dentro do mesmo turno;
# um marcador em .git/ evita re-cutucar em turnos seguintes enquanto o diff de
# código for o mesmo.
#
# Natureza: a DETECÇÃO é determinística (diff acima do limiar). Não prova que a
# revisão rodou — cutuca para forçá-la.

set -euo pipefail

input="$(cat)"

# Raiz do projeto (fornecida pelo Claude Code; fallback para git/pwd).
proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
config="$proj/keelson.config.json"

# --- Fallback gracioso: sem jq, não trava o fluxo. ---
if ! command -v jq >/dev/null 2>&1; then
  echo "review-guard: jq não encontrado; guarda de code review desativada nesta execução." >&2
  exit 0
fi

# --- Fallback gracioso: sem a ficha, não trava o fluxo. ---
if [ ! -f "$config" ]; then
  echo "review-guard: keelson.config.json não encontrado em $proj; guarda desativada nesta execução." >&2
  exit 0
fi

# Evita loop.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

# gates.review desligado na ficha → não cutuca (default: ligado quando ausente).
# Obs.: `//` do jq trata `false` como vazio, então NÃO serve aqui — testamos == false.
rev_gate="$(jq -r 'if .gates.review == false then "off" else "on" end' "$config" 2>/dev/null || echo on)"
[ "$rev_gate" = "off" ] && exit 0

# Paths de código vindos da ficha. Sem eles, nada a vigiar.
code_paths="$(jq -r '((.codePaths.backend // []) + (.codePaths.frontend // []))[]?' "$config" 2>/dev/null || true)"
[ -z "$code_paths" ] && exit 0

# Limiar (Art. 6): dispara com arquivos ≥ files OU linhas adicionadas ≥ lines.
th_files="$(jq -r '.gates.reviewThreshold.files // 2' "$config" 2>/dev/null || echo 2)"
th_lines="$(jq -r '.gates.reviewThreshold.lines // 30' "$config" 2>/dev/null || echo 30)"
case "$th_files" in ''|*[!0-9]*) th_files=2 ;; esac
case "$th_lines" in ''|*[!0-9]*) th_lines=30 ;; esac

cd "$proj" 2>/dev/null || exit 0

# --- Determina a base da branch (mesmo mecanismo do security-guard) ---
base=""
for b in main master origin/main origin/master; do
  if git rev-parse --verify -q "$b" >/dev/null 2>&1; then
    base="$(git merge-base HEAD "$b" 2>/dev/null || true)"
    [ -n "$base" ] && break
  fi
done

base_note=""
if [ -n "$base" ]; then
  changed="$(git diff --name-only "$base" 2>/dev/null || true)"
  diff_ref="$base"
else
  changed="$(git status --porcelain -uall 2>/dev/null | sed -E 's/^.{2} //; s/^.* -> //' || true)"
  diff_ref="HEAD"
  base_note=$'\n\n(Observação: não foi possível determinar a base da branch (main/master). A detecção caiu no working tree — git status — em vez do diff da branch.)'
fi

# Arquivos novos (não rastreados) entram na análise nos dois modos.
untracked_all="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
changed="$(printf '%s\n%s\n' "$changed" "$untracked_all" | sed '/^$/d' | sort -u)"
[ -z "$changed" ] && exit 0

# path_has_prefix <lista-de-prefixos-multilinha> <arquivo> — true se o arquivo
# está sob algum dos prefixos (igual a ele ou dentro dele).
path_has_prefix() {
  local prefixes="$1" file="$2" p
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    p="${p%/}"
    [ "$file" = "$p" ] && return 0
    case "$file" in
      "$p"/*) return 0 ;;
    esac
  done <<< "$prefixes"
  return 1
}

# Filtra os arquivos alterados pelos codePaths.
code_files=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  path_has_prefix "$code_paths" "$f" && code_files="${code_files}${f}"$'\n'
done <<< "$changed"
code_files="$(printf '%s' "$code_files" | sed '/^$/d')"
[ -z "$code_files" ] && exit 0

# --- Mede o tamanho da mudança (arquivos + linhas adicionadas) ---
file_count="$(printf '%s\n' "$code_files" | sed '/^$/d' | wc -l | tr -d ' ')"

code_arr=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  code_arr+=("$f")
done <<< "$code_files"

added_lines=0
if [ "${#code_arr[@]}" -gt 0 ]; then
  added_lines="$(git diff --numstat "$diff_ref" -- "${code_arr[@]}" 2>/dev/null \
    | awk '$1 != "-" { s += $1 } END { print s + 0 }' || echo 0)"
fi
# Arquivos novos (não rastreados) não aparecem no diff — conta as linhas deles.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if printf '%s\n' "$untracked_all" | grep -Fxq -- "$f" 2>/dev/null; then
    [ -f "$f" ] && added_lines=$(( added_lines + $(wc -l < "$f" 2>/dev/null || echo 0) ))
  fi
done <<< "$code_files"

# Abaixo do limiar em ambas as dimensões → trivial, passa sem cutucar (Art. 6).
if [ "$file_count" -lt "$th_files" ] && [ "$added_lines" -lt "$th_lines" ]; then
  exit 0
fi

# Anti-renudge entre turnos: stop_hook_active só cobre o turno atual.
git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-review-guard.last"
  fingerprint="$(printf '%s\n%s\n%s' "$code_files" "$file_count" "$added_lines" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

reason="$(cat <<EOF
Gate de Code Review (keelson, gate 7): há mudança de código acima do limiar (${file_count} arquivo(s) de código, ~${added_lines} linha(s) adicionada(s); limiar: ${th_files} arquivos ou ${th_lines} linhas) nos codePaths da ficha.

Antes de encerrar, aplique o code review:
- Rode o task-reviewer sobre o diff OU aplique o checklist de guidelines/core/CODE-REVIEW.md (e o perfil de linguagem ativo).
- Confirme: limites/responsabilidade única respeitados; sem reimplementação de utilitário existente (DRY); nomes pela intenção; sem abstração especulativa; condicionais e assinaturas saudáveis; tratamento de erro presente; sem código morto.

Se esta mudança JÁ passou por code review (ex.: fluxo /keelson:implement com reviewer), pode encerrar — este aviso não se repetirá para esta mesma mudança.${base_note}
EOF
)"
if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi
jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
exit 0
