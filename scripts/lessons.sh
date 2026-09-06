#!/usr/bin/env bash
# lessons.sh — recorte mecânico do acervo de lições do projeto (decisão 4.376).
# Dono do formato da lição e do ciclo de vida: guidelines/core/WORKFLOW.md
# (§Ciclo de auto-aperfeiçoamento). Este script só lê e recorta; nunca escreve lição.
#
# Uso: lessons.sh <raiz-do-projeto> list  [--estado <e1,e2|todas>]
#      lessons.sh <raiz-do-projeto> match [--paths <p1,p2,...>] [--paths-file <arquivo|->]
#                                          [--tags <t1,t2,...>] [--estado <e1,e2|todas>]
#      lessons.sh <raiz-do-projeto> show  <id | heading | trecho do heading>
#      lessons.sh <raiz-do-projeto> index
#
# Acervo (leitura dupla, ambos opcionais):
#   guidelines/project/lessons/*.md   — 1 arquivo por lição, frontmatter YAML plano
#                                       (area, estado, validade, confirmada, contestada,
#                                       paths, tags, absorvida_em) + corpo canônico
#   guidelines/project/lessons.md     — acervo legado (blocos `## [Área] …` com
#                                       **Estado:**/**Validade:**/**Contadores:**;
#                                       linhas de `## Revogadas` são tombstones)
#
# Saída:
#   list  → 1 linha por lição: id<TAB>estado<TAB>area<TAB>heading<TAB>origem<TAB>absorvida_em
#   match → cabeçalho `# lessons.sh match: acervo=N recorte=R (path=P tag=T sempre=S) excluidas=E legado=L`
#           e depois cada lição do recorte, integral, separada por `---8<---`
#   show  → a lição integral (exit 1 se não encontrada)
#   index → tabela markdown (derivada — imprimir, nunca commitar como fonte)
#   Diagnósticos em stderr: `WARNING nao-parseavel <arquivo>` (a lição entra no recorte
#   mesmo assim — recorte que esconde lição é o pior defeito desta camada).
# Exit: 0 normal · 1 show sem resultado · 2 uso incorreto.
#
# Recorte (match) — regra inclusiva: entra a lição que (a) não declara `paths` (lição de
# classe/transversal: entra SEMPRE), ou (b) tem algum glob de `paths` casando algum
# caminho dado, ou (c) tem alguma `tag` entre as dadas. Estado default do recorte:
# ativa + em-observacao (revogada só com --estado revogada|todas). Globs: `**` e `*`
# casam qualquer trecho (inclusive `/`); padrão sem metacaractere casa o caminho
# exato ou tudo abaixo dele.
#
# Princípios (irmãos do graph.sh, 4.82): read-only; bash 3.2 + awk POSIX, sem
# dependências; frontmatter ilegível degrada para "sempre incluída" com WARNING,
# nunca para ausência.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL
SEP="$(printf '\037')"   # separador de campo dos registros internos (tab colapsa campo vazio no read)

usage() {
  sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

root="${1:-}"; [ -n "$root" ] || usage
cmd="${2:-}"; [ -n "$cmd" ] || usage
shift 2
if [ ! -d "$root" ]; then
  echo "lessons: raiz não encontrada: $root" >&2
  exit 2
fi

LDIR="$root/guidelines/project/lessons"
LFILE="$root/guidelines/project/lessons.md"

TMP="$(mktemp -d)" || { echo "lessons: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT
REC="$TMP/records.tsv"
BLK="$TMP/blocks"
mkdir -p "$BLK"
: > "$REC"

slugify() { # texto → slug ascii (minúsculas, [a-z0-9-])
  printf '%s' "$1" | sed 's/^## *//; s/^\[[^]]*\] *//' | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# ---------- coleta: arquivo por lição ----------
# awk emite 1 linha TSV por arquivo e grava o conteúdo integral em $BLK/<n>.md.
# Campos: n id estado area heading validade confirmada contestada absorvida paths tags origem kind parse
n=0
if [ -d "$LDIR" ]; then
  for f in "$LDIR"/*.md; do
    [ -f "$f" ] || continue
    n=$((n + 1))
    id="$(basename "$f" .md)"
    cp "$f" "$BLK/$n.md"
    awk -v S="$SEP" -v n="$n" -v id="$id" -v origem="guidelines/project/lessons/$(basename "$f")" '
      BEGIN { infm = 0; done = 0; parse = "ok"; key = ""; heading = ""
              estado = ""; area = ""; validade = ""; conf = ""; cont = ""; abs = ""; paths = ""; tags = "" }
      function addlist(k, v) {
        gsub(/^[ \t"'"'"']+|[ \t"'"'"']+$/, "", v)
        if (v == "") return
        if (k == "paths") paths = (paths == "" ? v : paths ";" v)
        else if (k == "tags") tags = (tags == "" ? v : tags ";" v)
      }
      function inline(k, v,   i, m, arr) {
        gsub(/^\[|\]$/, "", v)
        m = split(v, arr, ",")
        for (i = 1; i <= m; i++) addlist(k, arr[i])
      }
      NR == 1 { if ($0 == "---") { infm = 1; next } else { parse = "warn" } }
      infm && !done {
        if ($0 == "---") { done = 1; infm = 0; next }
        if ($0 ~ /^[ \t]+-[ \t]/ && key != "") { v = $0; sub(/^[ \t]+-[ \t]*/, "", v); addlist(key, v); next }
        if ($0 ~ /^[A-Za-z_]+:/) {
          k = $0; sub(/:.*/, "", k); v = $0; sub(/^[A-Za-z_]+:[ \t]*/, "", v)
          gsub(/^["'"'"']|["'"'"']$/, "", v)
          key = ""
          if (k == "paths" || k == "tags") { key = k; if (v ~ /^\[/) inline(k, v); else if (v != "") addlist(k, v); next }
          if (k == "estado") estado = v
          else if (k == "area") area = v
          else if (k == "validade") validade = v
          else if (k == "confirmada") conf = v
          else if (k == "contestada") cont = v
          else if (k == "absorvida_em") abs = v
          next
        }
        next
      }
      heading == "" && /^## / { heading = $0; sub(/^## */, "", heading) }
      /^\*\*Estado:\*\*/ && estado == "" { estado = $0; sub(/^\*\*Estado:\*\*[ \t]*/, "", estado) }
      END {
        if (heading == "") { heading = id; parse = "warn" }
        if (area == "" && heading ~ /^\[[^]]*\]/) { area = heading; sub(/\].*/, "", area); sub(/^\[/, "", area) }
        if (estado == "") { estado = "ativa"; if (parse == "ok") parse = "warn" }
        if (validade == "") validade = "indeterminada"
        if (conf == "") conf = 0
        if (cont == "") cont = 0
        printf "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s\n",
          n, id, estado, area, heading, validade, conf, cont, abs, paths, tags, origem, "dir", parse
      }' "$f" >> "$REC"
  done
fi

# ---------- coleta: acervo legado (arquivo único) ----------
if [ -f "$LFILE" ]; then
  start=$((n + 1))
  awk -v S="$SEP" -v start="$start" -v blk="$BLK" -v origem="guidelines/project/lessons.md" '
    function flush() {
      if (cur == "") return
      out = blk "/" idx ".md"
      printf "%s", body > out
      close(out)
      a = ""; if (heading ~ /^\[[^]]*\]/) { a = heading; sub(/\].*/, "", a); sub(/^\[/, "", a) }
      if (estado == "") estado = "ativa"
      if (validade == "") validade = "indeterminada"
      if (conf == "") conf = 0
      if (cont == "") cont = 0
      printf "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s\n",
        idx, "", estado, a, heading, validade, conf, cont, "", "", "", origem, "legado", "ok"
      cur = ""
    }
    BEGIN { idx = start - 1; cur = ""; revog = 0 }
    /^## / {
      flush()
      h = $0; sub(/^## */, "", h)
      if (h ~ /^Revogadas/) { revog = 1; next }
      if (revog) revog = 0
      idx++; cur = h; heading = h; body = $0 "\n"; estado = ""; validade = ""; conf = ""; cont = ""
      next
    }
    revog && /^- / {
      idx++
      h = $0; sub(/^- */, "", h); sub(/ — .*/, "", h)   # tombstone: título antes do " — <motivo>"
      out = blk "/" idx ".md"; printf "%s\n", $0 > out; close(out)
      a = ""; if (h ~ /^\[[^]]*\]/) { a = h; sub(/\].*/, "", a); sub(/^\[/, "", a) }
      printf "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s" S "%s\n",
        idx, "", "revogada", a, h, "indeterminada", 0, 0, "", "", "", origem, "legado", "ok"
      next
    }
    cur != "" {
      body = body $0 "\n"
      if ($0 ~ /^\*\*Estado:\*\*/) { estado = $0; sub(/^\*\*Estado:\*\*[ \t]*/, "", estado); sub(/[ \t]*$/, "", estado) }
      if ($0 ~ /^\*\*Validade:\*\*/) { validade = $0; sub(/^\*\*Validade:\*\*[ \t]*/, "", validade) }
      if ($0 ~ /^\*\*Contadores:\*\*/) {
        c = $0
        if (match(c, /confirmada[ \t]+[0-9]+/)) { conf = substr(c, RSTART, RLENGTH); sub(/confirmada[ \t]+/, "", conf) }
        if (match(c, /contestada[ \t]+[0-9]+/)) { cont = substr(c, RSTART, RLENGTH); sub(/contestada[ \t]+/, "", cont) }
      }
    }
    END { flush() }
  ' "$LFILE" >> "$REC"
fi

# id do legado = slug do heading (derivado; o heading segue sendo a chave humana)
if grep -q "${SEP}legado${SEP}" "$REC" 2>/dev/null; then
  : > "$REC.tmp"
  while IFS="$SEP" read -r rn rid rest; do
    if [ -z "$rid" ]; then
      rh="$(printf '%s\n' "$rest" | awk -F"$SEP" '{ print $3 }')"
      rid="$(slugify "$rh")"
    fi
    printf '%s%s%s%s%s\n' "$rn" "$SEP" "$rid" "$SEP" "$rest" >> "$REC.tmp"
  done < "$REC"
  mv "$REC.tmp" "$REC"
fi

total="$(wc -l < "$REC" | tr -d ' ')"
legado="$(grep -c "${SEP}legado${SEP}" "$REC" 2>/dev/null || true)"
[ -n "$legado" ] || legado=0

# avisos de parse (stderr) — a lição fica no acervo
# shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
  [ "$rparse" = "warn" ] && echo "WARNING nao-parseavel $rorigem (frontmatter ausente/incompleto — lição tratada como ativa e sempre-incluída)" >&2
done < "$REC"

# ---------- filtros ----------
estados="ativa,em-observacao"
paths=""
tags=""
query=""
while [ $# -gt 0 ]; do
  case "$1" in
    --estado) estados="${2:-}"; shift 2 ;;
    --paths) paths="$paths,${2:-}"; shift 2 ;;
    --paths-file)
      pf="${2:-}"; shift 2
      if [ "$pf" = "-" ]; then lst="$(cat)"; else lst="$(cat "$pf" 2>/dev/null || true)"; fi
      paths="$paths,$(printf '%s\n' "$lst" | tr '\n' ',')" ;;
    --tags) tags="$tags,${2:-}"; shift 2 ;;
    --*) echo "lessons: opção desconhecida: $1" >&2; exit 2 ;;
    *) query="$query $1"; shift ;;
  esac
done
query="${query# }"

estado_ok() { # $1 estado da lição
  [ "$estados" = "todas" ] && return 0
  case ",$estados," in *",$1,"*) return 0 ;; esac
  return 1
}

path_hit() { # $1 lista de globs (;) — casa algum caminho dado?
  pl="$1"
  oldifs="$IFS"; IFS=';'
  for pat in $pl; do
    IFS="$oldifs"
    [ -n "$pat" ] || { IFS=';'; continue; }
    pat="$(printf '%s' "$pat" | sed 's#\*\*#*#g; s#^\./##')"
    IFS=','
    for p in $paths; do
      IFS="$oldifs"
      p="${p#./}"
      [ -n "$p" ] || { IFS=','; continue; }
      case "$pat" in
        *'*'*|*'?'*|*'['*)
          # shellcheck disable=SC2254
          case "$p" in $pat) return 0 ;; esac ;;
        *)
          case "$p" in "$pat"|"$pat"/*) return 0 ;; esac ;;
      esac
      IFS=','
    done
    IFS=';'
  done
  IFS="$oldifs"
  return 1
}

tag_hit() { # $1 lista de tags (;) — alguma entre as dadas?
  tl="$1"
  [ -n "$tags" ] || return 1
  oldifs="$IFS"; IFS=';'
  for t in $tl; do
    IFS="$oldifs"
    [ -n "$t" ] || { IFS=';'; continue; }
    case ",$tags," in *",$t,"*) IFS="$oldifs"; return 0 ;; esac
    IFS=';'
  done
  IFS="$oldifs"
  return 1
}

case "$cmd" in
  list)
    # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
      estado_ok "$restado" || continue
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$rid" "$restado" "$rarea" "$rheading" "$rorigem" "$rabs"
    done < "$REC"
    ;;
  index)
    echo "| id | estado | área | lição | origem |"
    echo "|---|---|---|---|---|"
    # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
      estado_ok "$restado" || continue
      printf '| %s | %s | %s | %s | %s |\n' "$rid" "$restado" "$rarea" "$rheading" "$rorigem"
    done < "$REC"
    ;;
  show)
    [ -n "$query" ] || usage
    qslug="$(slugify "$query")"
    qlow="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"
    hit=""
    # 1) id exato · 2) slug do heading · 3) trecho do heading (case-insensitive), 1º achado
    # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
      if [ "$rid" = "$query" ]; then hit="$rn"; break; fi
    done < "$REC"
    if [ -z "$hit" ]; then
      # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
        if [ "$(slugify "$rheading")" = "$qslug" ]; then hit="$rn"; break; fi
      done < "$REC"
    fi
    if [ -z "$hit" ]; then
      # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
        hl="$(printf '%s' "$rheading" | tr '[:upper:]' '[:lower:]')"
        case "$hl" in *"$qlow"*) hit="$rn"; break ;; esac
      done < "$REC"
    fi
    if [ -z "$hit" ]; then
      echo "lessons: lição não encontrada: $query" >&2
      exit 1
    fi
    r="$(awk -F"$SEP" -v n="$hit" '$1 == n' "$REC")"
    printf '# %s\n' "$(printf '%s' "$r" | awk -F"$SEP" '{ printf "id=%s estado=%s origem=%s", $2, $3, $12 }')"
    cat "$BLK/$hit.md"
    ;;
  match)
    sel="$TMP/sel"; : > "$sel"
    np=0; nt=0; ns=0; ne=0
    # shellcheck disable=SC2034
    while IFS="$SEP" read -r rn rid restado rarea rheading rval rconf rcont rabs rpaths rtags rorigem rkind rparse; do
      if ! estado_ok "$restado"; then ne=$((ne + 1)); continue; fi
      motivo=""
      if [ -z "$rpaths" ]; then motivo="sempre"; ns=$((ns + 1))
      elif path_hit "$rpaths"; then motivo="path"; np=$((np + 1))
      elif tag_hit "$rtags"; then motivo="tag"; nt=$((nt + 1))
      else ne=$((ne + 1)); continue
      fi
      printf '%s%s%s%s%s%s%s%s%s\n' "$rn" "$SEP" "$rid" "$SEP" "$restado" "$SEP" "$motivo" "$SEP" "$rorigem" >> "$sel"
    done < "$REC"
    rec=$((np + nt + ns))
    echo "# lessons.sh match: acervo=$total recorte=$rec (path=$np tag=$nt sempre=$ns) excluidas=$ne legado=$legado"
    while IFS="$SEP" read -r rn rid restado motivo rorigem; do
      echo "---8<--- id=$rid estado=$restado via=$motivo origem=$rorigem"
      cat "$BLK/$rn.md"
    done < "$sel"
    ;;
  *) usage ;;
esac
exit 0
