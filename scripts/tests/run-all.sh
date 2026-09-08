#!/usr/bin/env bash
# run-all.sh — runner comum das suítes mecânicas (decisão 4.389).
#
# Descobre TODA suíte em scripts/tests/*/run.sh (nenhuma lista à mão: suíte nova entra
# sozinha, e a que ninguém registrou no CI deixa de existir como classe de defeito),
# roda cada uma até o fim (uma vermelha não esconde as seguintes), guarda o log por
# suíte e resume em tabela — status · duração · última linha. Com --junit emite JUnit
# XML (uma testcase por suíte, log em <system-out>, falha em <failure>) para o CI
# publicar; com --logs guarda os logs num diretório para artefato.
#
# Uso: scripts/tests/run-all.sh [--junit <arquivo.xml>] [--logs <dir>] [--only a,b,c]
# Exit: 0 todas verdes · 1 alguma vermelha · 2 uso incorreto.
# Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
JUNIT=""; LOGS=""; ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --junit) shift; [ $# -gt 0 ] || { echo "ERRO: --junit exige um arquivo" >&2; exit 2; }; JUNIT="$1" ;;
    --logs)  shift; [ $# -gt 0 ] || { echo "ERRO: --logs exige um diretório" >&2; exit 2; }; LOGS="$1" ;;
    --only)  shift; [ $# -gt 0 ] || { echo "ERRO: --only exige nomes separados por vírgula" >&2; exit 2; }; ONLY="$1" ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

[ -n "$LOGS" ] || LOGS="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
mkdir -p "$LOGS" || { echo "ERRO: não consegui criar $LOGS" >&2; exit 1; }

xml_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

total=0; failed=0; tsum=0
ROWS="$LOGS/.rows.tsv"; : > "$ROWS"
for r in "$HERE"/*/run.sh; do
  [ -f "$r" ] || continue
  name="$(basename "$(dirname "$r")")"
  if [ -n "$ONLY" ]; then case ",$ONLY," in *",$name,"*) ;; *) continue ;; esac; fi
  total=$((total + 1))
  log="$LOGS/$name.log"
  t0="$(date +%s)"
  bash "$r" > "$log" 2>&1
  st=$?
  dt=$(( $(date +%s) - t0 )); tsum=$((tsum + dt))
  last="$(tail -1 "$log" 2>/dev/null)"
  if [ "$st" -eq 0 ]; then status="ok"; else status="FAIL"; failed=$((failed + 1)); fi
  printf '%s\t%s\t%s\t%s\n' "$name" "$status" "$dt" "$last" >> "$ROWS"
  printf '%-18s %-4s %4ss  %s\n' "$name" "$status" "$dt" "$last"
done

echo "---"
echo "run-all: $total suíte(s) · $failed vermelha(s) · ${tsum}s somados · logs em $LOGS"

if [ -n "$JUNIT" ]; then
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<testsuite name="keelson-mechanical-suites" tests="%s" failures="%s" time="%s">\n' "$total" "$failed" "$tsum"
    while IFS="$(printf '\t')" read -r name status dt last; do
      [ -n "$name" ] || continue
      printf '  <testcase classname="scripts.tests" name="%s" time="%s">\n' "$name" "$dt"
      if [ "$status" = "FAIL" ]; then
        printf '    <failure message="%s">' "$(printf '%s' "$last" | xml_escape)"
        xml_escape < "$LOGS/$name.log"
        printf '</failure>\n'
      fi
      printf '    <system-out>'; tail -40 "$LOGS/$name.log" | xml_escape; printf '</system-out>\n'
      printf '  </testcase>\n'
    done < "$ROWS"
    printf '</testsuite>\n'
  } > "$JUNIT" || { echo "ERRO: não consegui escrever $JUNIT" >&2; exit 1; }
  echo "run-all: JUnit em $JUNIT"
fi

[ "$failed" -eq 0 ]
