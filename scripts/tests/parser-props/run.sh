#!/usr/bin/env bash
# run.sh — propriedades dos parsers (decisão 4.388): graph.sh, artifact-lint.sh e
# index-check.sh sob TRANSFORMAÇÕES INÓCUAS de arquivo — as que o graph-contract §1
# declara toleradas (CRLF/BOM, espaços, crase e negrito em volta do ID) e as que
# nenhuma régua proíbe (espaço em fim de linha, linha em branco dobrada, ordem de
# criação dos arquivos). Bases: o slug do corpus (4.260) e três fixtures do grafo
# (válida, avulsa, legada). Propriedades provadas, para cada base × transformação:
#   invariância — grafo (nós e arestas, sem a coluna de origem, que muda de linha
#     legitimamente), achados do --check, do lint e do index-check IDÊNTICOS aos da
#     base: transformação visual nunca cria ERROR nem WARNING;
#   preservação de diagnóstico — ciclo plantado continua `ciclo-task`, referência
#     removida continua `ref-quebrada`, prosa em campo de aresta continua só
#     `nao-parseavel` (sem ERROR novo) — sob TODAS as transformações;
#   determinismo — duas execuções byte-idênticas.
# Fronteira declarada: bullet `*` no lugar de `-` NÃO é variação inócua — o contrato
# fixa `- ` e os templates só geram essa forma; sob `*` o extrator não vê os FRs e o
# --check cascateia em `ref-quebrada` (24 ERRORs no corpus). Não é transformação
# desta suíte; se um dia for aceita, entra aqui como caso, nunca por acidente.
#
# Uso: scripts/tests/parser-props/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SC="$HERE/../.."
GRAPH="$SC/graph.sh"; LINT="$SC/artifact-lint.sh"; IDX="$SC/index-check.sh"
for f in "$GRAPH" "$LINT" "$IDX"; do [ -f "$f" ] || { echo "ERRO: não encontrado: $f" >&2; exit 1; }; done

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

BASES="corpus:$HERE/../corpus/fixtures/corpus valido:$HERE/../graph/fixtures/valido avulso:$HERE/../graph/fixtures/valido-avulso legado:$HERE/../graph/fixtures/valido-legado"
TRANSFORMS="crlf bom crlf-bom trailing-ws fields blank-lines reverse-order"

# --- transformações (aplicadas a uma cópia; nunca à fixture) ---
md_files() { find "$1" -name '*.md' | sort; }
# idempotentes: fixture que JÁ tem CRLF/BOM (valido-legado) não ganha CR duplo nem BOM duplo
t_crlf()        { for f in $(md_files "$1"); do sed 's/\r$//; s/$/\r/' "$f" > "$f.n" && mv "$f.n" "$f"; done; }
t_bom()         { for f in $(md_files "$1"); do { printf '\357\273\277'; sed '1s/^\xef\xbb\xbf//' "$f"; } > "$f.n" && mv "$f.n" "$f"; done; }
t_crlf_bom()    { t_crlf "$1"; t_bom "$1"; }
t_trailing_ws() { for f in $(md_files "$1"); do sed -E 's/(\r?)$/   \1/' "$f" > "$f.n" && mv "$f.n" "$f"; done; }   # espaço ANTES do CR, quando há
t_fields() { # espaços + crase + negrito nos campos de aresta (graph-contract §1)
  for f in $(md_files "$1"); do
    sed -E \
      -e 's/^(\*\*Realiza \(FRs\)\*\*:)[[:space:]]*([A-Z].*[^[:space:]])[[:space:]]*$/\1   `\2`  /' \
      -e 's/^(\*\*Realiza\*\*:)[[:space:]]*([A-Z].*[^[:space:]])[[:space:]]*$/\1  **\2**/' \
      -e 's/^(- \*\*Depende de\*\*:)[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1     \2   /' \
      -e 's/^(- \*\*Bloqueia\*\*:)[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1 `\2`/' \
      -e 's/^(\*\*Pertence a\*\*:)[[:space:]]*(PLAN-[0-9]+)[[:space:]]*$/\1 **\2**/' \
      -e 's/^(\*\*Componente\*\*:)[[:space:]]*(COMP-[0-9-]+)[[:space:]]*$/\1   `\2`/' \
      -e 's/^(\*\*SPEC referenciada\*\*:)[[:space:]]*(SPEC-[0-9]+)[[:space:]]*$/\1  **\2**  /' \
      "$f" > "$f.n" && mv "$f.n" "$f"
  done
}
t_blank_lines() { for f in $(md_files "$1"); do awk '{ print } /^[[:space:]]*$/ { print "" }' "$f" > "$f.n" && mv "$f.n" "$f"; done; }
t_reverse_order() { # recria a árvore copiando os arquivos em ordem inversa (ordem de criação ≠ ordem lexical)
  src="$1.src"; mv "$1" "$src"; mkdir -p "$1"
  for f in $(md_files "$src" | sort -r); do rel="${f#"$src"/}"; mkdir -p "$1/$(dirname "$rel")"; cp "$f" "$1/$rel"; done
  rm -rf "$src"
}
apply() { # transformação dir
  case "$1" in
    crlf) t_crlf "$2" ;; bom) t_bom "$2" ;; crlf-bom) t_crlf_bom "$2" ;;
    trailing-ws) t_trailing_ws "$2" ;; fields) t_fields "$2" ;; blank-lines) t_blank_lines "$2" ;;
    reverse-order) t_reverse_order "$2" ;;
  esac
}

# --- observações (a coluna de origem arquivo:linha muda legitimamente e sai da comparação) ---
graph_norm() { ( cd "$1" && bash "$GRAPH" "$2" --format=tsv 2>/dev/null ) | awk -F'\t' 'BEGIN{OFS="\t"} $1=="edge"{print $1,$2,$3,$4; next} $1=="node"{print $1,$2,$3,$4,$5,$6; next} $1=="warn"{print $1,$2,$4,$5; next} {print}' | sort; }
graph_check() { ( cd "$1" && bash "$GRAPH" "$2" --check 2>/dev/null ) | sed -E 's/, [a-z]+\/[^)]*:[0-9]+\)/)/' | sort; }
lint_out()    { ( cd "$1" && bash "$LINT" "$2" 2>/dev/null ) | sort; }
idx_out()     { ( cd "$1" && bash "$IDX" "$2" 2>/dev/null ) | sed "s|	$2 sem INDEX.md|	DIR sem INDEX.md|" | sort; }

# --- plantas de diagnóstico (aplicadas ANTES da transformação, na cópia) ---
# invocadas por nome (plant_$pl) no laço abaixo
# shellcheck disable=SC2317,SC2329
plant_cycle() { # TASK-x depende da última TASK: A -> ... -> A
  first="$(find "$1/tasks" -name 'TASK-*.md' ! -name '*INDEX*' 2>/dev/null | sort | head -1)"
  last="$(find "$1/tasks" -name 'TASK-*.md' ! -name '*INDEX*' 2>/dev/null | sort | tail -1)"
  [ -n "$first" ] && [ -n "$last" ] && [ "$first" != "$last" ] || return 1
  lid="$(basename "$last" | sed -E 's/^(TASK-[0-9]+-[0-9]+).*/\1/')"
  fid="$(basename "$first" | sed -E 's/^(TASK-[0-9]+-[0-9]+).*/\1/')"
  sed -E "s/^(- \*\*Depende de\*\*:).*/\1 $lid/" "$first" > "$first.n" && mv "$first.n" "$first"
  sed -E "s/^(- \*\*Depende de\*\*:).*/\1 $fid/" "$last" > "$last.n" && mv "$last.n" "$last"
}
# shellcheck disable=SC2317,SC2329
plant_broken_ref() { # 1º FR da SPEC some: quem o realiza/mapeia aponta para o nada
  spec="$(find "$1/specs" -name 'SPEC-*.md' 2>/dev/null | sort | head -1)"; [ -n "$spec" ] || return 1
  fr="$(grep -oE 'FR-[0-9]+-[0-9]+' "$spec" | head -1)"; [ -n "$fr" ] || return 1
  sed -E "/^- \*\*$fr\*\*/d" "$spec" > "$spec.n" && mv "$spec.n" "$spec"
}
# shellcheck disable=SC2317,SC2329
plant_prose() { # prosa num campo de aresta
  t="$(find "$1/tasks" -name 'TASK-*.md' ! -name '*INDEX*' 2>/dev/null | sort | head -1)"; [ -n "$t" ] || return 1
  sed -E 's/^(- \*\*Depende de\*\*:).*/\1 depende do que o time decidir na daily/' "$t" > "$t.n" && mv "$t.n" "$t"
}

for par in $BASES; do
  name="${par%%:*}"; src="${par#*:}"
  [ -d "$src" ] || { echo "AVISO: base $name ausente em $src — pulada" >&2; continue; }
  W="$TMP/$name"; mkdir -p "$W"; cp -r "$src" "$W/base"
  graph_norm "$W" base > "$W/base.graph"; graph_check "$W" base > "$W/base.check"
  lint_out "$W" base > "$W/base.lint"; idx_out "$W" base > "$W/base.idx"

  # determinismo
  total=$((total + 1))
  if [ "$(graph_norm "$W" base)" = "$(cat "$W/base.graph")" ] && [ "$(lint_out "$W" base)" = "$(cat "$W/base.lint")" ]; then ok "$name/determinismo"; else falha "$name/determinismo"; fi

  # controle: as plantas produzem o diagnóstico na base SEM transformação
  for pl in cycle broken_ref prose; do
    cp -r "$W/base" "$W/ctl-$pl"
    if plant_$pl "$W/ctl-$pl"; then
      graph_check "$W" "ctl-$pl" > "$W/ctl-$pl.check"
      total=$((total + 1))
      case "$pl" in
        cycle)      grep -q '^ERROR	ciclo-task' "$W/ctl-$pl.check" && ok "$name/controle-ciclo" || falha "$name/controle-ciclo: $(head -3 "$W/ctl-$pl.check")" ;;
        broken_ref) grep -q '^ERROR	ref-quebrada' "$W/ctl-$pl.check" && ok "$name/controle-ref-quebrada" || falha "$name/controle-ref-quebrada: $(head -3 "$W/ctl-$pl.check")" ;;
        prose)      grep -q '^WARNING	nao-parseavel' "$W/ctl-$pl.check" && [ "$(grep -c '^ERROR' "$W/ctl-$pl.check")" = "$(grep -c '^ERROR' "$W/base.check")" ] \
                      && ok "$name/controle-prosa-degrada-sem-error" || falha "$name/controle-prosa-degrada-sem-error: $(grep -E '^(ERROR|WARNING	nao)' "$W/ctl-$pl.check" | head -3)" ;;
      esac
    else
      rm -rf "$W/ctl-$pl"
    fi
  done

  for tr in $TRANSFORMS; do
    D="$W/$tr"; cp -r "$W/base" "$D"; apply "$tr" "$D"
    total=$((total + 1))
    g="$(graph_norm "$W" "$tr")"; c="$(graph_check "$W" "$tr")"; l="$(lint_out "$W" "$tr")"; i="$(idx_out "$W" "$tr")"
    if [ "$g" = "$(cat "$W/base.graph")" ] && [ "$c" = "$(cat "$W/base.check")" ] && [ "$l" = "$(cat "$W/base.lint")" ] && [ "$i" = "$(cat "$W/base.idx")" ]; then ok "$name/$tr/invariante"
    else
      falha "$name/$tr/invariante"
      { printf '%s\n' "$g" | diff "$W/base.graph" - ; printf '%s\n' "$c" | diff "$W/base.check" - ; printf '%s\n' "$l" | diff "$W/base.lint" - ; printf '%s\n' "$i" | diff "$W/base.idx" - ; } 2>/dev/null | head -6 | sed 's/^/  /'
    fi
    # diagnóstico preservado sob a transformação
    for pl in cycle broken_ref prose; do
      [ -d "$W/ctl-$pl" ] || continue
      P="$W/$tr-$pl"; cp -r "$W/ctl-$pl" "$P"; apply "$tr" "$P"
      total=$((total + 1))
      if [ "$(graph_check "$W" "$tr-$pl")" = "$(cat "$W/ctl-$pl.check")" ]; then ok "$name/$tr/preserva-$pl"
      else falha "$name/$tr/preserva-$pl"; graph_check "$W" "$tr-$pl" | diff "$W/ctl-$pl.check" - | head -4 | sed 's/^/  /'; fi
    done
  done
done

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "parser-props: $fail de $total casos falharam"
  exit 1
fi
echo "parser-props: $total casos verdes"
exit 0
