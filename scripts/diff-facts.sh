#!/usr/bin/env bash
# diff-facts.sh — fatos mecânicos sobre o diff de uma branch (decisão 4.151).
# Régua do "diff inerte" (dono: guidelines/core/TESTING.md, seção "Diff inerte"):
# a âncora mecânica é `git diff --name-only <base>...HEAD` confrontado com os
# codePaths da ficha e as árvores de teste — este script É essa âncora.
#
# Uso: diff-facts.sh --base <ref> ( --inert | --compose | --deploy-pending <INDEX.md> )
#                    [--repo <dir>] [--code-paths <p1,p2,…>] [--docs-root <dir>]
#                    [--deploy-dirs <seg1,seg2,…>] [--plugin-root <dir>]
#
#   --inert           classifica cada arquivo do diff e dá o veredito:
#                     linhas `inerte|codigo<TAB>bucket<TAB>path` + `veredito<TAB>…`.
#                     Exit 0 = diff inerte (dispensa declarada da suíte) · 1 = tem
#                     código que a suíte exercita (rode a suíte). Na dúvida, o
#                     arquivo conta como código — "na dúvida, rode" é o default.
#   --compose         composição do diff para o report de fecho: linhas
#                     `arquivo<TAB>bucket<TAB>+<TAB>-<TAB>path` + resumo
#                     `total<TAB>bucket<TAB>arquivos<TAB>+<TAB>-` por bucket
#                     (producao · teste · documentacao · migracao · config). Exit 0.
#   --deploy-pending  artefatos de deploy do diff vs o que o INDEX declara
#                     (implement Etapa 4 item 8): `pendente|declarado<TAB>basename`.
#                     Exit 1 se há pendente · 0 se tudo declarado.
#
#   Buckets: documentacao (docsRoot/**, *.md, assets estáticos) · teste (árvores e
#   sufixos de teste) · migracao (segmentos migrations/migrate/seeds/seeders, ou
#   --deploy-dirs) · producao (codePaths da ficha) · config (todo o resto).
#   Só documentacao é inerte.
#
#   codePaths/docsRoot: de --code-paths/--docs-root quando passados; senão da ficha
#   via ficha.sh (irmão de diretório). Ficha indisponível → degrada conservador
#   (sem codePaths: nada vira "producao", tudo não-doc vira config — e config NÃO é
#   inerte), com a causa nomeada em stderr.
#
# Exit: 0/1 conforme o modo · 2 uso incorreto (repo/base inválidos).
# Read-only. Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; }

HERE="$(cd "$(dirname "$0")" && pwd)"

REPO="$PWD"
BASE=""
MODE=""
INDEXF=""
CODEPATHS=""
DOCSROOT=""
DEPLOYDIRS="migrations,migrate,seeds,seeders"

while [ $# -gt 0 ]; do
  case "$1" in
    --base)   shift; [ $# -gt 0 ] || die2 "--base exige uma ref."; BASE="$1" ;;
    --repo)   shift; [ $# -gt 0 ] || die2 "--repo exige um diretório."; REPO="$1" ;;
    --inert)
      [ -z "$MODE" ] || die2 "use apenas um modo."; MODE="inert" ;;
    --compose)
      [ -z "$MODE" ] || die2 "use apenas um modo."; MODE="compose" ;;
    --deploy-pending)
      [ -z "$MODE" ] || die2 "use apenas um modo."
      shift; [ $# -gt 0 ] || die2 "--deploy-pending exige o caminho do INDEX.md."
      MODE="deploy"; INDEXF="$1" ;;
    --code-paths)  shift; [ $# -gt 0 ] || die2 "--code-paths exige lista separada por vírgula."; CODEPATHS="$1" ;;
    --docs-root)   shift; [ $# -gt 0 ] || die2 "--docs-root exige um diretório."; DOCSROOT="$1" ;;
    --deploy-dirs) shift; [ $# -gt 0 ] || die2 "--deploy-dirs exige lista separada por vírgula."; DEPLOYDIRS="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) die2 "opção desconhecida: $1 (use --help)" ;;
  esac
  shift
done

[ -n "$MODE" ] || { usage >&2; exit 2; }
[ -n "$BASE" ] || die2 "--base é obrigatório."
[ -d "$REPO" ] || die2 "repo não existe: $REPO"
command -v git >/dev/null 2>&1 || die2 "git indisponível."
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || die2 "não é repositório git: $REPO"
git -C "$REPO" rev-parse --verify --quiet "$BASE" >/dev/null 2>&1 || die2 "base não resolve: $BASE"
if [ "$MODE" = "deploy" ]; then
  [ -f "$INDEXF" ] || die2 "INDEX não encontrado: $INDEXF"
fi

# ---- codePaths e docsRoot: flag > ficha > degradação conservadora ----
FICHA_SH="$HERE/ficha.sh"
if [ -z "$CODEPATHS" ] && [ -f "$REPO/keelson.config.json" ] && [ -f "$FICHA_SH" ]; then
  cp_all="$( { bash "$FICHA_SH" "$REPO" --get codePaths.backend 2>/dev/null; \
               bash "$FICHA_SH" "$REPO" --get codePaths.frontend 2>/dev/null; } | tr '\n' ',' )"
  CODEPATHS="${cp_all%,}"
fi
if [ -z "$DOCSROOT" ]; then
  if [ -f "$REPO/keelson.config.json" ] && [ -f "$FICHA_SH" ]; then
    DOCSROOT="$(bash "$FICHA_SH" "$REPO" --get docsRoot --default docs 2>/dev/null || echo docs)"
  else
    DOCSROOT="docs"
  fi
fi
if [ -z "$CODEPATHS" ]; then
  echo "diff-facts: sem codePaths (ficha ausente/ilegível e sem --code-paths) — classificação degrada conservadora (não-doc vira config, que não é inerte)." >&2
fi

TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT

# lista sempre com --name-only; --compose acrescenta o numstat
git -C "$REPO" diff --name-only "$BASE"...HEAD > "$TMP/names.txt" 2>"$TMP/err" \
  || die2 "git diff falhou: $(sed -n 1p "$TMP/err")"
if [ "$MODE" = "compose" ]; then
  git -C "$REPO" diff --numstat "$BASE"...HEAD > "$TMP/numstat.txt" 2>/dev/null || die2 "git diff --numstat falhou."
fi

# ---- classificador (awk) ----
# stdin: `add<TAB>del<TAB>path` (name-only entra com add/del vazios)
classify() {
  awk -v CP="$CODEPATHS" -v DR="$DOCSROOT" -v DD="$DEPLOYDIRS" '
    function bucket(p,   i, seg, n, parts, base, ncp, cps, c) {
      sub(/\/$/, "", DR)
      # 1. docsRoot e markdown e asset → documentacao (o único bucket inerte)
      if (DR != "" && index(p, DR "/") == 1) return "documentacao"
      if (p ~ /\.(md|markdown|txt|png|jpe?g|gif|svg|ico|webp|woff2?|ttf|eot|mp4|pdf)$/) return "documentacao"
      # 2. migração/seed (segmento de caminho, lista configurável)
      n = split(p, parts, "/")
      for (i = 1; i < n; i++) {
        seg = "," parts[i] ","
        if (index("," DD ",", seg) > 0) return "migracao"
      }
      # 3. teste (árvore ou sufixo)
      for (i = 1; i < n; i++)
        if (parts[i] ~ /^(tests?|__tests__|spec|cypress|e2e)$/) return "teste"
      base = parts[n]
      if (base ~ /(\.test\.|\.spec\.|_test\.)/ || base ~ /Test\.[A-Za-z]+$/) return "teste"
      # 4. codePaths → producao
      if (CP != "") {
        ncp = split(CP, cps, ",")
        for (i = 1; i <= ncp; i++) {
          c = cps[i]
          sub(/^[ \t]+/, "", c); sub(/[ \t]+$/, "", c); sub(/\/$/, "", c)
          if (c == "") continue
          if (p == c || index(p, c "/") == 1) return "producao"
        }
      }
      # 5. resto: config/manifesto/script — a suíte pode depender disso; não é inerte
      return "config"
    }
    BEGIN { FS = "\t" }
    { print bucket($3) "\t" $1 "\t" $2 "\t" $3 }
  '
}

case "$MODE" in
  inert)
    n=0; bad=0
    # placeholder "-" nos campos numéricos: IFS de tab colapsa campo vazio no read
    awk '{ print "-\t-\t" $0 }' "$TMP/names.txt" | classify | sort -t'	' -k4 > "$TMP/class.txt"
    while IFS='	' read -r b _a _d p; do
      [ -n "$p" ] || continue
      n=$((n + 1))
      if [ "$b" = "documentacao" ]; then
        printf 'inerte\t%s\t%s\n' "$b" "$p"
      else
        printf 'codigo\t%s\t%s\n' "$b" "$p"
        bad=$((bad + 1))
      fi
    done < "$TMP/class.txt"
    if [ "$bad" -eq 0 ]; then
      printf 'veredito\tinerte\t%d arquivo(s), nenhum exercitado pela suite\n' "$n"
      exit 0
    fi
    printf 'veredito\tnao-inerte\t%d de %d arquivo(s) exercitado(s) pela suite\n' "$bad" "$n"
    exit 1 ;;

  compose)
    # numstat: binário vem como "-" → conta 0
    awk 'BEGIN { FS = "\t" } { a = $1; d = $2; if (a == "-") a = 0; if (d == "-") d = 0; print a "\t" d "\t" $3 }' \
      "$TMP/numstat.txt" | classify | sort -t'	' -k4 > "$TMP/class.txt"
    awk '
      BEGIN { FS = "\t"; nb = split("producao teste documentacao migracao config", bl, " ") }
      {
        printf "arquivo\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4
        cnt[$1]++; add[$1] += $2; del[$1] += $3
      }
      END {
        for (i = 1; i <= nb; i++) {
          b = bl[i]
          printf "total\t%s\t%d\t%d\t%d\n", b, cnt[b], add[b], del[b]
        }
      }
    ' "$TMP/class.txt"
    exit 0 ;;

  deploy)
    pend=0
    awk '{ print "-\t-\t" $0 }' "$TMP/names.txt" | classify | sort -t'	' -k4 > "$TMP/class.txt"
    while IFS='	' read -r b _a _d p; do
      [ -n "$p" ] || continue
      [ "$b" = "migracao" ] || continue
      base="$(basename "$p")"
      if grep -Fq "$base" "$INDEXF" 2>/dev/null; then
        printf 'declarado\t%s\n' "$base"
      else
        printf 'pendente\t%s\n' "$base"
        pend=$((pend + 1))
      fi
    done < "$TMP/class.txt"
    [ "$pend" -eq 0 ] && exit 0
    exit 1 ;;
esac

die2 "modo não tratado: $MODE"
