#!/usr/bin/env bash
# check-doctrine.sh — a doutrina embarcada cita a decisão e para (decisão 4.442).
#
# O que este script prova: nenhum texto que o consumidor carrega em runtime — nem a
# mensagem que um hook entrega ao modelo — traz história no lugar de regra. O caso, o
# número medido, o contador de reincidência, a genealogia da decisão, a comparação com
# a versão anterior e a versão pinada de plugin/harness moram em `docs/_meta/decisions.md`;
# a doutrina cita `(4.NNN)` e segue. É a régua do CLAUDE.md ("escreva pelo efeito; o
# porquê fica na decisão, a uma referência de distância") virando fato mecânico, depois
# da auditoria de 2026-09-28 (4.441) ter medido 46 narrativas inline e 34 parágrafos
# com 5+ decisões coladas por "E …".
#
# Classes (uma linha de achado por ocorrência; qualquer achado é exit 1):
#   narrativa    — "caso real" (com ou sem "de campo", maiúscula ou não)
#   reincidencia — "2ª reincidência/ocorrência/forma/camada", "Nª reincidência",
#                  "reincidência da classe"
#   migracao     — "desde a 4.NNN", "desde a 0.x.y", "desde o Claude Code",
#                  "deixou/deixaram de contar|existir|ser|valer|absolver|escrever",
#                  "ex-§", "ex-`…`" (nome antigo de check/seção)
#   versao       — "Claude Code ≥N", ">= v2.N", "plugin 0.x.y" (pin de harness/plugin)
#   linha-monolito   — linha acima de 4000 bytes (parágrafo que nenhuma leitura cabe;
#                  o teto desce a 3000 quando as duas linhas de sdd-conventions.md que
#                  ainda passam de 3500 drenarem na leva com eval — gatilho na 4.442)
#   monolito-cresceu — arquivo com MAIS linhas acima de 1500 bytes do que a baseline
#                  registra (catraca: monolito novo não entra; os existentes drenam nas
#                  levas com eval — 4.441 b). Baseline: scripts/doctrine-baseline.tsv
#                  (`caminho<TAB>n`, só arquivos com n>0); ausente = zero para todos.
#                  `--write-baseline` regrava a partir do estado atual (ato deliberado,
#                  nunca do pre-commit).
#
# Superfícies (via `git ls-files` — nunca `find .`): CLAUDE.md · commands/*.md ·
# agents/*.md · skills/**/*.md · guidelines/core/*.md · guidelines/_meta/*.md ·
# templates/**/*.md · docs/_meta/conventions/*.md · hooks/*.sh · .claude/hooks/*.sh.
# Em .sh só linhas que não são comentário contam (comentário é registro do mantenedor;
# string de `reason=`/echo é o que chega ao modelo). Perfis de linguagem
# (guidelines/backend, guidelines/frontend) ficam fora: "deixou de existir no PHP 8"
# é conteúdo técnico por versão, não história de doutrina. decisions.md, learning-log,
# proposal-inbox, CHANGELOG, evals/ e os testes são registro, nunca varridos.
#
# Falso-positivo em doutrina legítima é o pior defeito desta camada (4.82): as
# classes são as que a auditoria provou sem falso-positivo na árvore limpa. O que não
# é gregável sem ruído — identificador de consumidor (4.72), "revoga", hash de commit
# (`a1b2c3d` é SHA ilustrativo de report) — segue com o revisor humano.
#
# Uso: check-doctrine.sh [--root <dir>] [--write-baseline]
# Exit: 0 tudo certo · 1 achado(s) · 2 uso incorreto.
# Bash 3.2-compatível, POSIX awk, read-only (exceto --write-baseline).

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

ROOT=""
WRITE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "uso: check-doctrine.sh [--root <dir>] [--write-baseline]" >&2; exit 2; }
            ROOT="$2"; shift 2 ;;
    --write-baseline) WRITE=1; shift ;;
    *) echo "uso: check-doctrine.sh [--root <dir>] [--write-baseline]" >&2; exit 2 ;;
  esac
done
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "ERRO: fora de repo git e sem --root" >&2; exit 2; }
fi
[ -d "$ROOT" ] || { echo "ERRO: raiz inexistente: $ROOT" >&2; exit 2; }

BASELINE="$ROOT/scripts/doctrine-baseline.tsv"
LONG=1500   # bytes — catraca por arquivo
HARD=4000   # bytes — achado sempre

surfaces="$(git -C "$ROOT" ls-files -- \
  'CLAUDE.md' 'commands/*.md' 'agents/*.md' 'skills/*.md' 'skills/**/*.md' \
  'guidelines/core/*.md' 'guidelines/_meta/*.md' 'templates/*.md' 'templates/**/*.md' \
  'docs/_meta/conventions/*.md' 'hooks/*.sh' '.claude/hooks/*.sh' 2>/dev/null)"
[ -n "$surfaces" ] || { echo "ERRO: nenhuma superfície encontrada em $ROOT" >&2; exit 2; }

# Uma passada awk por arquivo: classes textuais + contagem de linhas longas.
# Saída: "A<TAB>arquivo:linha: classe — trecho" para achado; "N<TAB>arquivo<TAB>n" para a
# contagem de linhas > LONG (sempre, mesmo zero).
scan() { # $1 = arquivo relativo
  awk -v FILE="$1" -v LONG="$LONG" -v HARD="$HARD" '
    BEGIN {
      sh = (FILE ~ /\.sh$/)
      n_long = 0
      re["narrativa"]    = "[Cc]aso real"
      re["reincidencia"] = "[0-9]ª (reincid(ê|e)ncia|ocorr(ê|e)ncia|forma|camada)( da (classe|fam(í|i)lia|4\\.)|, agora)|Nª reincid|reincid(ê|e)ncia da classe"
      re["migracao"]     = "desde a 4\\.[0-9]+|desde a 0\\.[0-9]+\\.[0-9]+|desde o Claude Code|(deixou|deixaram) de (contar|existir|ser|valer|absolver|escrever)|[Ee]x-§|ex-`"
      re["versao"]       = "Claude Code ≥ ?[0-9]|>= ?v?2\\.[0-9]|plugin 0\\.[0-9]+\\.[0-9]+"
      order = "narrativa reincidencia migracao versao"
      nk = split(order, keys, " ")
    }
    {
      line = $0
      if (sh && line ~ /^[ \t]*#/) next
      if (sh && line ~ /^[ \t]*$/) next
      len = length(line)
      if (len > LONG) n_long++
      if (len > HARD) printf "A\t%s:%d: linha-monolito — %d bytes (teto %d)\n", FILE, NR, len, HARD
      for (i = 1; i <= nk; i++) {
        k = keys[i]
        if (match(line, re[k])) {
          s = RSTART - 40; if (s < 1) s = 1
          trecho = substr(line, s, RLENGTH + 80)
          gsub(/\t/, " ", trecho)
          printf "A\t%s:%d: %s — …%s…\n", FILE, NR, k, trecho
        }
      }
    }
    END { printf "N\t%s\t%d\n", FILE, n_long }
  ' "$ROOT/$1"
}

TMP="$(mktemp -t check-doctrine.XXXXXX)" || { echo "ERRO: mktemp falhou" >&2; exit 2; }
trap 'rm -f "$TMP"' EXIT
printf '%s\n' "$surfaces" | while IFS= read -r f; do
  [ -f "$ROOT/$f" ] || continue
  scan "$f"
done > "$TMP"

if [ "$WRITE" -eq 1 ]; then
  awk -F'\t' '$1 == "N" && $3 > 0 { printf "%s\t%s\n", $2, $3 }' "$TMP" | sort > "$BASELINE"
  echo "check-doctrine: baseline regravada em scripts/doctrine-baseline.tsv ($(wc -l < "$BASELINE" | tr -d ' ') arquivo(s) com linha > $LONG bytes)"
  exit 0
fi

achados="$(awk -F'\t' '$1 == "A" { print $2 }' "$TMP")"

# Catraca contra a baseline.
cresceu="$(awk -F'\t' -v B="$BASELINE" -v LONG="$LONG" '
  BEGIN { while ((getline l < B) > 0) { split(l, p, "\t"); base[p[1]] = p[2] + 0 } }
  $1 == "N" { n = $3 + 0; b = ($2 in base) ? base[$2] : 0
              if (n > b) printf "%s: monolito-cresceu — %d linha(s) > %d bytes (baseline %d)\n", $2, n, LONG, b
              else if (n < b) folga++ }
  END { if (folga > 0) printf "INFO\t%d arquivo(s) abaixo da baseline — aperte com --write-baseline\n", folga }
' "$TMP")"
info="$(printf '%s\n' "$cresceu" | awk -F'\t' '$1 == "INFO" { print $2 }')"
cresceu="$(printf '%s\n' "$cresceu" | awk -F'\t' '$1 != "INFO" && NF > 0')"

n_files="$(printf '%s\n' "$surfaces" | awk 'NF' | wc -l | tr -d ' ')"
total=0
if [ -n "$achados" ]; then printf '%s\n' "$achados" | sort; total=$((total + $(printf '%s\n' "$achados" | wc -l | tr -d ' '))); fi
if [ -n "$cresceu" ]; then printf '%s\n' "$cresceu" | sort; total=$((total + $(printf '%s\n' "$cresceu" | wc -l | tr -d ' '))); fi
[ -z "$info" ] || echo "check-doctrine: $info"

if [ "$total" -gt 0 ]; then
  echo "check-doctrine: $total achado(s) em $n_files arquivo(s) varridos — o caso e o número vão para a decisão; a doutrina cita (4.442)."
  exit 1
fi
echo "check-doctrine: ok — $n_files arquivo(s) varridos, nenhuma narrativa, genealogia, versão pinada ou monolito novo."
exit 0
