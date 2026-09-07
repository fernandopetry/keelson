#!/usr/bin/env bash
# diff-facts.sh — fatos mecânicos sobre o diff de uma branch (decisão 4.151).
# Régua do "diff inerte" (dono: guidelines/core/TESTING.md, seção "Diff inerte"):
# a âncora mecânica é `git diff --name-only <base>...HEAD` confrontado com os
# codePaths da ficha e as árvores de teste — este script É essa âncora.
#
# Uso: diff-facts.sh --base <ref> ( --inert | --compose | --deploy-pending <INDEX.md> | --identity )
#      diff-facts.sh --guard <review|security> [--repo <dir>]
#                    [--repo <dir>] [--code-paths <p1,p2,…>] [--docs-root <dir>]
#                    [--deploy-dirs <seg1,seg2,…>] [--plugin-root <dir>]
#
#   --inert           classifica cada arquivo do diff e dá o veredito:
#                     linhas `inerte|codigo<TAB>bucket<TAB>path` + `veredito<TAB>…`.
#                     Exit 0 = diff inerte (dispensa declarada da suíte) · 1 = há
#                     código que os codePaths classificam como produção (rode a
#                     suíte) — bater com codePaths não prova que `quality.test` o
#                     exercita; confirme a cobertura antes de citar como prova.
#                     Na dúvida, o arquivo conta como código — "na dúvida, rode"
#                     é o default.
#   --compose         composição do diff para o report de fecho: linhas
#                     `arquivo<TAB>bucket<TAB>+<TAB>-<TAB>path` + resumo
#                     `total<TAB>bucket<TAB>arquivos<TAB>+<TAB>-` por bucket
#                     (producao · teste · documentacao · migracao · config). Exit 0.
#   --deploy-pending  artefatos de deploy do diff vs o que o INDEX declara
#                     (implement Etapa 4 item 8): `pendente|declarado<TAB>basename`.
#                     Declarado = o INDEX cita o basename literal (com extensão) OU o
#                     stem (basename sem a última extensão) como palavra inteira —
#                     `add_col` casa `add_col`, `add_col.sql` e `dir/add_col.sql`,
#                     nunca `add_col_v2` (4.383). Exit 1 se há pendente · 0 se tudo
#                     declarado.
#   --identity        identidade do diff dos arquivos lidos do STDIN (um caminho por
#                     linha, relativo à raiz do repo): hash de `base <sha|none>` + uma
#                     linha `<blob|absent> <path>` por arquivo em ordem canônica, blob =
#                     `git hash-object --no-filters` do working tree. Conteúdo exato,
#                     sem renderização de diff — imune a `diff.renames`, algoritmo,
#                     prefixos ou diff externo do usuário. Base que não resolve degrada
#                     para `none` (repo sem commit), nunca erro. Leitores: os markers
#                     anti-renudge do review-guard/security-guard (decisão 4.377).
#                     Exit 0 · 2 uso incorreto. Ignora codePaths/ficha.
#   --guard <g>       escopo e identidade do guard de Stop <g> = review|security (4.378):
#                     base como os hooks (merge-base com main/master/origin/*; sem base,
#                     working tree via git status), arquivos alterados + novos filtrados
#                     pela ficha (review: codePaths; security: sensitiveGlobs + manifestos
#                     de dependência, sempre) e a identidade desse conjunto. TSV:
#                     `base <sha|none>` · `ref <ref-do-diff>` · `mode branch|worktree` ·
#                     `file <path> tracked|untracked|moved-out` (moved-out = origem de
#                     rename que saiu do escopo, contada como exclusão — 4.380) ·
#                     `rename_src <path>` (só de par que toca o escopo, 4.379) ·
#                     `dep <path>` · `identity <hash>`; `scope none` quando a ficha não
#                     dá escopo
#                     (review sem codePaths). DONO ÚNICO do escopo: review-guard,
#                     security-guard e ledger.sh (`diff_id:`) consomem esta saída, nunca
#                     re-derivam. --base é ignorado. Exit 0 · 2 uso incorreto.
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
usage() { sed -n '2,/^# Read-only/p' "$0" | sed 's/^# \{0,1\}//'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/ficha.sh"

# ---- funções de escopo (dono único — os hooks consomem a saída de --guard, 4.378) ----
# path_has_prefix <prefixos-multilinha> <arquivo>: arquivo igual ou sob algum prefixo.
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
# path_matches_any_glob <globs-multilinha> <arquivo>: casa contra os globs da ficha
# (ex.: "src/**"); em `case`, `*` já casa `/`, então "src/**" pega tudo sob src.
path_matches_any_glob() {
  local globs="$1" file="$2" glob
  while IFS= read -r glob; do
    [ -z "$glob" ] && continue
    # shellcheck disable=SC2254  # o glob vem da ficha e deve expandir como padrão
    case "$file" in
      $glob) return 0 ;;
    esac
  done <<< "$globs"
  return 1
}
# Manifesto/lockfile de dependência é sensível por definição (gate 8) — dono doutrinário:
# guidelines/core/SECURITY.md ("mudança de dependência"); aqui vive só a lista literal.
DEP_MANIFESTS='composer\.json|composer\.lock|package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|requirements\.txt|poetry\.lock|uv\.lock|go\.mod|go\.sum|Cargo\.toml|Cargo\.lock|Gemfile|Gemfile\.lock'

# ---- identidade do diff (4.377): base + blob exato de cada arquivo → hash ----
# $1 = ref da base (pode não resolver → none); stdin = caminhos (um por linha).
# Conteúdo exato via hash-object, sem renderização de diff — imune à config de git.
# O modo relevante ao git entra ao lado do blob (4.379): 100755/100644 pelo bit de
# execução, symlink como `link <alvo>` — `chmod +x` com bytes iguais é mudança que o
# git registra e a identidade tem de acompanhar.
identidade() {
  base_id="$(git -C "$REPO" rev-parse --verify --quiet "${1}^{commit}" 2>/dev/null || true)"
  [ -n "$base_id" ] || base_id="none"
  sed '/^[[:space:]]*$/d' | sort -u > "$TMPI/paths.txt"
  {
    printf 'base %s\n' "$base_id"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if [ -L "$REPO/$p" ]; then
        printf 'link %s %s\n' "$(readlink "$REPO/$p" 2>/dev/null || echo '?')" "$p"
      elif [ -f "$REPO/$p" ]; then
        h="$(git -C "$REPO" hash-object --no-filters -- "$p" 2>/dev/null || true)"
        if [ -x "$REPO/$p" ]; then m="100755"; else m="100644"; fi
        printf '%s %s %s\n' "${h:-unreadable}" "$m" "$p"
      else
        printf 'absent %s\n' "$p"
      fi
    done < "$TMPI/paths.txt"
  } > "$TMPI/manifest.txt"
  git -C "$REPO" hash-object --stdin < "$TMPI/manifest.txt"
}

REPO="$PWD"
BASE=""
MODE=""
GUARD=""
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
    --identity)
      [ -z "$MODE" ] || die2 "use apenas um modo."; MODE="identity" ;;
    --guard)
      [ -z "$MODE" ] || die2 "use apenas um modo."
      shift; [ $# -gt 0 ] || die2 "--guard exige review|security."
      MODE="guard"; GUARD="$1"
      case "$GUARD" in review|security) ;; *) die2 "--guard: escopo desconhecido: $GUARD (review|security)" ;; esac ;;
    --code-paths)  shift; [ $# -gt 0 ] || die2 "--code-paths exige lista separada por vírgula."; CODEPATHS="$1" ;;
    --docs-root)   shift; [ $# -gt 0 ] || die2 "--docs-root exige um diretório."; DOCSROOT="$1" ;;
    --deploy-dirs) shift; [ $# -gt 0 ] || die2 "--deploy-dirs exige lista separada por vírgula."; DEPLOYDIRS="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) die2 "opção desconhecida: $1 (use --help)" ;;
  esac
  shift
done

[ -n "$MODE" ] || { usage >&2; exit 2; }
if [ "$MODE" != "guard" ]; then
  [ -n "$BASE" ] || die2 "--base é obrigatório."
fi
[ -d "$REPO" ] || die2 "repo não existe: $REPO"
command -v git >/dev/null 2>&1 || die2 "git indisponível."
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || die2 "não é repositório git: $REPO"

# ---- --identity: identidade do diff dos arquivos do stdin (decisão 4.377) ----
# Base que não resolve NÃO é erro neste modo: repo sem commit ou branch sem base
# degrada para `none` — a identidade continua cobrindo o conteúdo dos arquivos.
if [ "$MODE" = "identity" ]; then
  TMPI="$(mktemp -d)" || die2 "mktemp falhou."
  trap 'rm -rf "$TMPI"' EXIT
  identidade "$BASE" || die2 "hash-object falhou."
  exit 0
fi

# ---- --guard: escopo + identidade do guard de Stop (decisão 4.378) ----
if [ "$MODE" = "guard" ]; then
  TMPI="$(mktemp -d)" || die2 "mktemp falhou."
  trap 'rm -rf "$TMPI"' EXIT
  CP=""; SG=""
  if [ -f "$REPO/keelson.config.json" ] && [ -f "$FICHA_SH" ]; then
    case "$GUARD" in
      review)   CP="$( { bash "$FICHA_SH" "$REPO" --get codePaths.backend; bash "$FICHA_SH" "$REPO" --get codePaths.frontend; } 2>/dev/null | sed '/^[[:space:]]*$/d' )" ;;
      security) SG="$(bash "$FICHA_SH" "$REPO" --get sensitiveGlobs 2>/dev/null | sed '/^[[:space:]]*$/d')" ;;
    esac
  fi
  if [ "$GUARD" = "review" ] && [ -z "$CP" ]; then
    printf 'scope\tnone\n'
    exit 0
  fi
  # base: merge-base com o primeiro candidato existente; sem base → working tree
  gbase=""
  for b in main master origin/main origin/master; do
    if git -C "$REPO" rev-parse --verify -q "$b" >/dev/null 2>&1; then
      gbase="$(git -C "$REPO" merge-base HEAD "$b" 2>/dev/null || true)"
      [ -n "$gbase" ] && break
    fi
  done
  rpairs=""
  if [ -n "$gbase" ]; then
    # rename detection fixada (-M, 4.377): destino na lista, origem em rename_src
    ns="$(git -C "$REPO" -c core.quotePath=false diff --name-status -M "$gbase" 2>/dev/null || true)"
    changed="$(printf '%s\n' "$ns" | awk -F'\t' 'NF >= 2 { print $NF }')"
    rpairs="$(printf '%s\n' "$ns" | awk -F'\t' '$1 ~ /^[RC]/ && NF >= 3 { print $2 "\t" $3 }')"
    gref="$gbase"; gmode="branch"
  else
    changed="$(git -C "$REPO" -c core.quotePath=false status --porcelain -uall 2>/dev/null | sed -E 's/^.{2} //; s/^.* -> //' || true)"
    gref="HEAD"; gmode="worktree"
  fi
  untracked="$(git -C "$REPO" -c core.quotePath=false ls-files --others --exclude-standard 2>/dev/null || true)"
  changed="$(printf '%s\n%s\n' "$changed" "$untracked" | sed '/^$/d' | sort -u)"
  files=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$GUARD" in
      review)   path_has_prefix "$CP" "$f" && files="${files}${f}"$'\n' ;;
      security) [ -n "$SG" ] && path_matches_any_glob "$SG" "$f" && files="${files}${f}"$'\n' ;;
    esac
  done <<< "$changed"
  files="$(printf '%s' "$files" | sed '/^$/d')"
  # origem de rename entra só quando o par toca o escopo — origem ou destino dentro dele
  # (4.379): rename fora do escopo não é mudança do que o guard vigia
  # rename que SAI do escopo é, para o guard, uma exclusão (4.380): a origem entra na
  # lista de arquivos como `moved-out` — conta, entra na identidade e no pathspec
  rsrc=""; movedout=""
  while IFS='	' read -r rs rd; do
    [ -n "$rs" ] || continue
    sin=0; din=0
    case "$GUARD" in
      review)   path_has_prefix "$CP" "$rs" && sin=1; path_has_prefix "$CP" "$rd" && din=1 ;;
      security) [ -n "$SG" ] && path_matches_any_glob "$SG" "$rs" && sin=1
                [ -n "$SG" ] && path_matches_any_glob "$SG" "$rd" && din=1 ;;
    esac
    [ "$sin" -eq 1 ] || [ "$din" -eq 1 ] || continue
    rsrc="${rsrc}${rs}"$'\n'
    [ "$sin" -eq 1 ] && [ "$din" -eq 0 ] && movedout="${movedout}${rs}"$'\n'
  done <<< "$rpairs"
  rsrc="$(printf '%s' "$rsrc" | sed '/^$/d')"
  movedout="$(printf '%s' "$movedout" | sed '/^$/d')"
  deps=""
  [ "$GUARD" = "security" ] && deps="$(printf '%s\n' "$changed" | grep -E "(^|/)(${DEP_MANIFESTS})$" || true)"
  printf 'base\t%s\n' "${gbase:-none}"
  printf 'ref\t%s\n' "$gref"
  printf 'mode\t%s\n' "$gmode"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if printf '%s\n' "$untracked" | grep -Fxq -- "$f" 2>/dev/null; then fst="untracked"; else fst="tracked"; fi
    printf 'file\t%s\t%s\n' "$f" "$fst"
  done <<< "$files"
  while IFS= read -r f; do [ -n "$f" ] || continue; printf 'file\t%s\tmoved-out\n' "$f"; done <<< "$movedout"
  while IFS= read -r f; do [ -n "$f" ] || continue; printf 'rename_src\t%s\n' "$f"; done <<< "$rsrc"
  while IFS= read -r f; do [ -n "$f" ] || continue; printf 'dep\t%s\n' "$f"; done <<< "$deps"
  ident="$(printf '%s\n' "$files" "$deps" "$rsrc" | identidade "$gref")" || die2 "hash-object falhou."
  printf 'identity\t%s\n' "$ident"
  exit 0
fi

git -C "$REPO" rev-parse --verify --quiet "$BASE" >/dev/null 2>&1 || die2 "base não resolve: $BASE"
if [ "$MODE" = "deploy" ]; then
  [ -f "$INDEXF" ] || die2 "INDEX não encontrado: $INDEXF"
fi

# ---- codePaths e docsRoot: flag > ficha > degradação conservadora ----
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
    printf 'veredito\tnao-inerte\t%d de %d arquivo(s) classificado(s) como codigo pelos codePaths — nao prova que quality.test os exercita; confirme a cobertura antes de citar como prova\n' "$bad" "$n"
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
      stem="${base%.*}"
      # basename literal (substring, como sempre) OU stem como palavra inteira — a
      # forma sem extensão é a majoritária nos INDEX de campo, e sem a fronteira de
      # palavra `add_col` casaria `add_col_v2` (4.383)
      if grep -Fq "$base" "$INDEXF" 2>/dev/null || grep -Fqw "$stem" "$INDEXF" 2>/dev/null; then
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
