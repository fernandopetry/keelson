#!/usr/bin/env bash
# map-check.sh — checagem mecânica do MAP.md de um slug (decisão 4.104).
# Contrato e catálogo de checks: docs/_meta/conventions/map-contract.md (§4).
#
# Uso: map-check.sh <dir-do-slug>       # {docsRoot}/<slug>, já resolvido pelo chamador
#
# Saída: SEVERIDADE<TAB>check<TAB>detalhe  (formato do graph.sh)
# Checks: map-forma (WARNING) · map-ancora (WARNING) · map-frescor (WARNING) · map-teto (INFO)
# Exit: 0 normal (o catálogo não tem ERROR) · 2 uso incorreto.
#
# Princípios (irmãos do graph.sh, 4.82): read-only; bash 3.2 + awk POSIX + git, sem
# dependências novas; na dúvida degrada em silêncio — falso-positivo em MAP legítimo é
# o pior defeito desta camada. MAP ausente é opcional por contrato → exit 0 sem ruído.
# Fora de repo git (ou sem git): map-frescor degrada em silêncio; os demais rodam com a
# raiz aproximada pelo cwd.

set -u
LC_ALL=C
export LC_ALL

dir="${1:-}"
if [ -z "$dir" ]; then
  echo "uso: map-check.sh <dir-do-slug>" >&2
  exit 2
fi
if [ ! -d "$dir" ]; then
  echo "map-check: diretório não encontrado: $dir" >&2
  exit 2
fi

map="$dir/MAP.md"
[ -f "$map" ] || exit 0

# Raiz do repo — as âncoras do MAP são relativas a ela (map-contract §2).
have_git=0
root=""
if command -v git >/dev/null 2>&1; then
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$root" ] && have_git=1
fi
[ -n "$root" ] || root="$PWD"

# Fase 1 (awk POSIX): forma + teto + extração das entradas parseáveis.
# Stream interno: linhas "E<TAB>nr<TAB>data<TAB>caminho<TAB>linha1" (entrada válida)
# intercaladas com achados prontos ("WARNING<TAB>map-forma..." / "INFO<TAB>map-teto...").
# A fase 2 (shell) resolve filesystem e git por entrada, preservando a ordem do arquivo.
awk '
  function flush_teto() {
    if (sec != "" && cnt > 40)
      printf "INFO\tmap-teto\tsecao \"%s\" com %d entradas (teto ~40) - virou documentacao de outro tipo? (map-contract §1)\n", sec, cnt
  }
  /^## /  { flush_teto(); sec = substr($0, 4); cnt = 0; next }
  /^- \[/ {
    line = $0
    # Sintaxe canonica (map-contract §2):
    # - [YYYY-MM-DD · origem] fato — caminho:linha[-linha][ @ "hint"]
    if (line !~ /^- \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] · [^]]+\] .+ — [^ ]+:[0-9]+(-[0-9]+)?( @ "[^"]*")?$/) {
      printf "WARNING\tmap-forma\tlinha %d: entrada fora da sintaxe canonica (data/origem/ancora) - map-contract §2\n", NR
      next
    }
    cnt = cnt + 1
    data = substr(line, 4, 10)
    # Remove o hint (se houver) e captura a ancora apos o ULTIMO " — ".
    sub(/ @ "[^"]*"$/, "", line)
    if (match(line, / — [^ ]+:[0-9]+(-[0-9]+)?$/) == 0) next
    anchor = substr(line, RSTART)
    sub(/^ — /, "", anchor)
    # caminho = antes do ultimo ":"; linha1 = digitos apos ele (ate "-" ou fim)
    n = split(anchor, parts, ":")
    lspec = parts[n]
    path = substr(anchor, 1, length(anchor) - length(lspec) - 1)
    split(lspec, lr, "-")
    l1 = lr[1]
    printf "E\t%d\t%s\t%s\t%s\n", NR, data, path, l1
  }
  END { flush_teto() }
' "$map" | while IFS='	' read -r tag nr data path l1; do
  case "$tag" in
    E)
      f="$root/$path"
      if [ ! -f "$f" ]; then
        printf 'WARNING\tmap-ancora\tlinha %s: %s nao existe no repo (map-contract §4)\n' "$nr" "$path"
        continue
      fi
      total="$(wc -l < "$f" 2>/dev/null | tr -d ' 	' || echo 0)"
      case "$total" in ''|*[!0-9]*) total=0 ;; esac
      if [ "$l1" -gt "$total" ] 2>/dev/null; then
        printf 'WARNING\tmap-ancora\tlinha %s: %s tem %s linhas; ancora aponta :%s\n' "$nr" "$path" "$total" "$l1"
        continue
      fi
      if [ "$have_git" = 1 ]; then
        last="$(git -C "$root" log -1 --format=%ci -- "$path" 2>/dev/null | cut -c1-10 || true)"
        if [ -n "$last" ] && [ "$last" \> "$data" ]; then
          printf 'WARNING\tmap-frescor\tlinha %s: %s mudou em %s, entrada verificada em %s - possivelmente-stale (re-verifique no proximo consumo)\n' "$nr" "$path" "$last" "$data"
        fi
      fi
      ;;
    *)
      # achado pronto da fase 1 (map-forma / map-teto) — repassa intacto
      rest=""
      [ -n "$data" ] && rest="	$data"
      [ -n "$path" ] && rest="$rest	$path"
      [ -n "$l1" ] && rest="$rest	$l1"
      printf '%s\t%s%s\n' "$tag" "$nr" "$rest"
      ;;
  esac
done

exit 0
