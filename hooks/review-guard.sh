#!/usr/bin/env bash
# review-guard — hook Stop que reforça o GATE 7 (code review) do keelson.
#
# LÊ A FICHA `keelson.config.json` na raiz do projeto (via jq) para se
# parametrizar — nada de caminho de código hardcoded. Da ficha extrai:
#   - gates.review          → se `false`, o hook sai sem cutucar (default: ligado);
#   - codePaths.*           → onde vive o código deste projeto;
#   - gates.reviewThreshold → limiar opcional { files, lines } (default: 2 / 30).
# Detecta mudança de código NA BRANCH acima do limiar e bloqueia o encerramento
# UMA vez, lembrando de aplicar o code review — revisão INDEPENDENTE: /keelson:review
# ou o agent `code-reviewer`. Checklist aplicado por quem escreveu não fecha o gate 7
# (gerador ≠ avaliador, 4.36; a opção sobrevivera da 4.15 e saiu na 4.377).
#
# Limiar (Charter Art. 6 — rigor proporcional): mudança trivial passa sem cutucar.
# Dispara quando arquivos de código alterados ≥ `files` OU linhas adicionadas ≥ `lines`.
# Rename detection é FIXADA (-M, origem do rename no pathspec): rename puro conta 1
# arquivo com 0 linhas em qualquer config de git do usuário (4.377).
#
# Como o security-guard: compara o diff da BRANCH contra a base (merge-base com
# main/master) e filtra pelos `codePaths` da ficha; sem base determinável, cai no
# working tree (git status) e registra isso na mensagem.
#
# Fallback gracioso: sem `jq` ou sem a ficha, o hook NÃO trava o fluxo — emite
# aviso em stderr e sai 0. `stop_hook_active` evita loop dentro do mesmo turno;
# um marcador em .git/ evita re-cutucar em turnos seguintes enquanto a IDENTIDADE do
# diff de código for a mesma — base + conteúdo exato de cada arquivo, via
# `scripts/diff-facts.sh --identity` (4.377): tamanho igual com conteúdo diferente
# cutuca de novo; mudança fora dos codePaths não reabre. O marker guarda o último estado
# AVISADO; o ledger (abaixo) guarda o último estado REVISADO — cutucar nunca equivale a
# registrar revisão. E veredito do code-reviewer já registrado no ledger da sessão
# (evento `gate`, 4.76) mais novo que todo arquivo de código alterado cala o hook
# (decisão 4.365): no modo sob demanda o commit é do Diretor e o diff cumulativo
# cresce a cada correção — sem essa consulta, cada re-review genuíno re-disparava.
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

# Ciclo formal em andamento → os gates têm dono (rodada da wave no /keelson:implement,
# inventário 4.92); este hook é a rede da SESSÃO LIVRE, não um segundo cobrador
# (decisão 4.103). run-state ativo DESTA sessão → silêncio. Posse (4.252): run de
# OUTRA sessão (campo `sessao:` ≠ session_id do payload) não silencia a rede desta;
# dono desconhecido/formato antigo/sem session_id → silêncio como antes (nunca
# reativar nudge por dúvida).
session_id="$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")"
# casa da sessão (4.314) + caminho legado
for rs in "$proj"/thoughts/local/run-state-*.md "$proj"/thoughts/local/sessions/*/run-state-*.md; do
  [ -f "$rs" ] || continue
  grep -q "^status: em_andamento" "$rs" 2>/dev/null || continue
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$rs" 2>/dev/null | sed -n 1p)"
  if [ -n "$session_id" ] && [ -n "$dono" ] && [ "$dono" != "desconhecida" ] && [ "$dono" != "$session_id" ]; then
    continue
  fi
  exit 0
done

# Warroom ativo NESTA sessão (decisão 4.372): o gate 7 não bloqueia — cada commit vira
# linha de dívida em DEBT.md (warroom-guard) e a cobrança é no fecho da janela. Mesma
# régua de posse do run-state: marcador de OUTRA sessão não cala esta; legado sem dono
# (`sessao: desconhecida`) cala como antes. O security-guard NÃO tem este silenciador —
# gate 8 sobrevive ao warroom.
for wm in "$proj"/thoughts/local/warroom.meta "$proj"/thoughts/local/sessions/*/warroom.meta; do
  [ -f "$wm" ] || continue
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$wm" 2>/dev/null | sed -n 1p)"
  if [ -n "$session_id" ] && [ -n "$dono" ] && [ "$dono" != "desconhecida" ] && [ "$dono" != "$session_id" ]; then
    continue
  fi
  exit 0
done

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

# ledger.sh resolvido ANTES do cd (o $0 pode ser relativo); ausente → a consulta ao
# veredito registrado (abaixo) é pulada e o hook se comporta como sempre.
SCRIPTS_DIR="$(cd "$(dirname "$0")/../scripts" 2>/dev/null && pwd || true)"
LEDGER="$SCRIPTS_DIR/ledger.sh"
# diff-facts.sh --identity (4.377): identidade do diff para o marker anti-renudge.
DIFF_FACTS="$SCRIPTS_DIR/diff-facts.sh"

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
rename_src=""
if [ -n "$base" ]; then
  # Rename detection fixada (-M, 4.377): a lista traz o DESTINO do rename e `rename_src`
  # guarda a origem — ela entra no pathspec do numstat para o git ver o rename (0 linhas
  # num rename puro) em vez de um arquivo novo inteiro; sem isso a contagem dependia de
  # `diff.renames` do usuário e do pathspec. quotePath=false: nome não-ASCII sai cru.
  ns="$(git -c core.quotePath=false diff --name-status -M "$base" 2>/dev/null || true)"
  changed="$(printf '%s\n' "$ns" | awk -F'\t' 'NF >= 2 { print $NF }')"
  rename_src="$(printf '%s\n' "$ns" | awk -F'\t' '$1 ~ /^[RC]/ && NF >= 3 { print $2 }')"
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
  # sob pipefail, git sem HEAD (repo sem commit) falha o pipeline e um `|| echo 0`
  # empilharia um segundo valor sobre o "0" que o awk já emitiu — added_lines
  # multiline quebrava o teste do limiar em silêncio
  spec_arr=("${code_arr[@]}")
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    spec_arr+=("$f")
  done <<< "$rename_src"
  added_lines="$(git -c core.quotePath=false diff --numstat -M "$diff_ref" -- "${spec_arr[@]}" 2>/dev/null \
    | awk '$1 != "-" { s += $1 } END { print s + 0 }' || true)"
  case "$added_lines" in ''|*[!0-9]*) added_lines=0 ;; esac
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

# Veredito já registrado cobre a árvore (decisão 4.365): o code-reviewer que revisou
# ESTE estado do diff deixou evento `gate` no ledger da sessão (4.76 — escrito pelo
# Tech Lead ao receber o report). Se nenhum arquivo de código alterado é mais novo que o
# veredito mais recente, a revisão cobre o que está na árvore → silêncio. No modo sob
# demanda não há commit para ancorar o marcador (4.91) e o diff cumulativo cresce a cada
# correção: sem esta consulta, cada rodada genuína de re-review re-disparava a cutucada.
# Arquivo alterado que não existe mais no disco conta como mais novo (conservador).
# Sem ledger, sem evento do agent ou sem o script → comportamento de sempre.
if [ -f "$LEDGER" ]; then
  verdict="$(KEELSON_SESSAO="$session_id" bash "$LEDGER" "$proj" last gate code-reviewer 2>/dev/null || true)"
  if [ -n "$verdict" ] && [ -f "$verdict" ]; then
    newer=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      if [ ! -e "$f" ] || [ "$f" -nt "$verdict" ]; then newer=1; break; fi
    done <<< "$code_files"
    [ "$newer" -eq 0 ] && exit 0
  fi
fi

# Anti-renudge entre turnos: stop_hook_active só cobre o turno atual.
git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-review-guard.last"
  # Identidade do diff (4.377): base + conteúdo exato dos arquivos de código (rastreados,
  # novos ou ausentes) — o mesmo estado nunca cutuca duas vezes, estado novo cutuca de
  # novo mesmo com tamanho igual. Script ausente → forma antiga (lista + contagens).
  if [ -f "$DIFF_FACTS" ]; then
    fingerprint="$(printf '%s\n' "$code_files" "$rename_src" | bash "$DIFF_FACTS" --identity --base "$diff_ref" --repo "$proj" 2>/dev/null || true)"
  fi
  [ -n "$fingerprint" ] || fingerprint="$(printf '%s\n%s\n%s' "$code_files" "$file_count" "$added_lines" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

reason="$(cat <<EOF
Gate de Code Review (keelson, gate 7): há mudança de código acima do limiar (${file_count} arquivo(s) de código, ~${added_lines} linha(s) adicionada(s); limiar: ${th_files} arquivos ou ${th_lines} linhas) nos codePaths da ficha.

Antes de encerrar, aplique o code review — revisão INDEPENDENTE, nunca de quem escreveu o código (régua gerador ≠ avaliador de guidelines/core/CODE-REVIEW.md):
- Despache o code-reviewer sobre o diff (rota que a sessão executa) OU peça ao Diretor o /keelson:review (revisores independentes; comando humano-only). Checklist aplicado por quem escreveu não fecha o gate 7.

Se esta mudança JÁ passou por code review (ex.: fluxo /keelson:implement com reviewer), pode encerrar — este aviso não se repetirá para esta mesma mudança. Se o que mudou desde o último veredito é só o delta de uma correção de achados, a re-verificação é sobre o delta — e delta só de comentário/doc re-checa com o próprio revisor, sem rodada nova completa (régua de convergência: guidelines/core/CODE-REVIEW.md, decisão 4.88).${base_note}
EOF
)"
if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi
jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
exit 0
