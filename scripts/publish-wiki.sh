#!/usr/bin/env bash
# publish-wiki.sh — publica a documentação de usuário no GitHub Wiki (decisão 4.81).
#
# Uso: publish-wiki.sh [--dry-run] [--check] [--remote <url>] [--wiki-dir <dir>]
#                      [--message <msg>]
#
# A fonte da verdade é ESTE repositório: as páginas próprias vivem em docs/wiki/ e os
# espelhos vêm dos donos únicos listados em MIRRORS (method-guide, Charter, convenções).
# A wiki é ARTEFATO GERADO — edição feita pela UI do GitHub é sobrescrita aqui.
#
#   --dry-run  mostra o que mudaria (git diff) e não faz commit nem push
#   --check    sai 1 se a wiki estiver desatualizada (para CI de verificação)
#   --remote   URL do repo .wiki.git (default: derivada do remote 'origin')
#   --wiki-dir clone de trabalho (default: .wiki/ na raiz, ignorado pelo git)
#
# Bash 3.2-compatível. Diferente dos hooks, aqui falhar alto é o correto: quem roda
# pediu a publicação — remote ausente, wiki não inicializada ou push recusado é erro
# nomeado (exit 1), nunca silêncio.

set -u

# --- Espelhos: "<caminho no repo>|<nome da página>" (dono único fora de docs/wiki/) ---
MIRRORS='docs/_meta/method-guide.md|Guia-do-metodo
guidelines/_meta/QUALITY-CHARTER.md|Quality-Charter
docs/_meta/conventions/index-contract.md|Contrato-do-INDEX
docs/_meta/conventions/commit-convention.md|Convencao-de-commits
docs/_meta/conventions/handoff-protocol.md|Handoff-de-verificacao
docs/_meta/conventions/graph-contract.md|Contrato-do-grafo
docs/_meta/conventions/report-contract.md|Contrato-do-relatorio
docs/_meta/conventions/lint-contract.md|Contrato-do-lint'

DRY_RUN=0
CHECK=0
WIKI_REMOTE=""
WIKI_DIR=""
MESSAGE=""
PAGES_STATE=".keelson-wiki-pages"

die() { echo "ERRO: $*" >&2; exit 1; }
mask() { printf '%s' "$1" | sed -e 's#//[^@/]*@#//***@#'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --check)   CHECK=1; DRY_RUN=1 ;;
    --remote)  shift; [ $# -gt 0 ] || die "--remote exige uma URL"; WIKI_REMOTE="$1" ;;
    --wiki-dir) shift; [ $# -gt 0 ] || die "--wiki-dir exige um caminho"; WIKI_DIR="$1" ;;
    --message) shift; [ $# -gt 0 ] || die "--message exige um texto"; MESSAGE="$1" ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "opção desconhecida: $1 (use --help)" ;;
  esac
  shift
done

command -v git >/dev/null 2>&1 || die "git não encontrado no PATH."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel 2>/dev/null)" \
  || die "rode de dentro do repositório do keelson."
cd "$REPO_ROOT" || die "não consegui entrar em $REPO_ROOT"

[ -n "$WIKI_DIR" ] || WIKI_DIR="$REPO_ROOT/.wiki"

# --- Identidade do repositório: owner/repo a partir do remote 'origin' ---
ORIGIN="$(git config --get remote.origin.url 2>/dev/null || true)"
[ -n "$ORIGIN" ] || die "remote 'origin' ausente — não sei qual wiki publicar."

SLUG="$(printf '%s' "$ORIGIN" \
  | sed -e 's#^git@[^:]*:##' -e 's#^ssh://git@[^/]*/##' -e 's#^https\{0,1\}://[^/]*/##' -e 's#\.git$##')"
case "$SLUG" in
  */*) : ;;
  *) die "não consegui derivar owner/repo de '$ORIGIN'." ;;
esac

BLOB_BASE="https://github.com/$SLUG/blob/main"
[ -n "$WIKI_REMOTE" ] || WIKI_REMOTE="$(printf '%s' "$ORIGIN" | sed -e 's#\.git$##').wiki.git"

# --- O wiki precisa existir: a primeira página é criada pela UI do GitHub ---
if ! git ls-remote "$WIKI_REMOTE" >/dev/null 2>&1; then
  echo "ERRO: o wiki de $SLUG ainda não foi inicializado (ou o acesso falhou)." >&2
  echo "" >&2
  echo "O repositório .wiki.git só passa a existir depois da primeira página criada" >&2
  echo "pela interface web. Abra https://github.com/$SLUG/wiki, clique em" >&2
  echo "'Create the first page', salve qualquer conteúdo e rode este script de novo" >&2
  echo "(o conteúdo dessa página inicial é substituído pela Home gerada)." >&2
  echo "" >&2
  echo "Remote tentado: $(mask "$WIKI_REMOTE")" >&2
  exit 1
fi

# --- Clone/atualização do destino ---
if [ -d "$WIKI_DIR/.git" ]; then
  git -C "$WIKI_DIR" remote set-url origin "$WIKI_REMOTE" \
    || die "não consegui apontar o clone existente para $(mask "$WIKI_REMOTE")"
  git -C "$WIKI_DIR" fetch --quiet origin || die "fetch do wiki falhou."
  BRANCH="$(git -C "$WIKI_DIR" rev-parse --abbrev-ref HEAD)"
  git -C "$WIKI_DIR" reset --quiet --hard "origin/$BRANCH" || die "reset do clone do wiki falhou."
else
  rm -rf "$WIKI_DIR"
  git clone --quiet "$WIKI_REMOTE" "$WIKI_DIR" \
    || die "clone do wiki falhou ($(mask "$WIKI_REMOTE"))."
fi
BRANCH="$(git -C "$WIKI_DIR" rev-parse --abbrev-ref HEAD)"

TMP="$(mktemp -d)" || die "não consegui criar diretório temporário."
trap 'rm -rf "$TMP"' EXIT

# --- Manifesto: "<caminho no repo> <página>" (páginas próprias + espelhos) ---
MAP="$TMP/map.txt"
: > "$MAP"

for f in docs/wiki/*.md; do
  [ -f "$f" ] || continue
  page="$(basename "$f" .md)"
  printf '%s %s\n' "$f" "$page" >> "$MAP"
done

printf '%s\n' "$MIRRORS" | while IFS='|' read -r src page; do
  [ -n "${src:-}" ] || continue
  [ -f "$src" ] || { echo "AVISO: espelho ausente, ignorado: $src" >&2; continue; }
  printf '%s %s\n' "$src" "$page" >> "$MAP"
done

[ -s "$MAP" ] || die "nenhuma página encontrada (docs/wiki/ vazio?)."

# --- Reescrita de links: destino publicado → página da wiki; resto → blob no GitHub ---
AWK_REWRITE="$TMP/rewrite.awk"
cat > "$AWK_REWRITE" <<'AWK'
function resolve(dir, rel,   path, parts, n, i, k, out) {
  if (substr(rel, 1, 1) == "/") path = substr(rel, 2)
  else path = (dir == "" ? rel : dir "/" rel)
  n = split(path, parts, "/")
  k = 0
  for (i = 1; i <= n; i++) {
    if (parts[i] == "." || parts[i] == "") continue
    if (parts[i] == "..") { if (k > 0) k--; continue }
    k++; stack[k] = parts[i]
  }
  out = ""
  for (i = 1; i <= k; i++) out = (out == "" ? stack[i] : out "/" stack[i])
  return out
}

function convert(d,   anchor, h, resolved) {
  if (d ~ /^[a-zA-Z][a-zA-Z0-9+.-]*:/ || d ~ /^#/ || d ~ /^\/\//) return d
  anchor = ""
  h = index(d, "#")
  if (h > 0) { anchor = substr(d, h); d = substr(d, 1, h - 1) }
  if (d == "") return anchor
  # Link escrito direto pelo nome da página ("[x](Contrato-do-INDEX)") — é como as
  # páginas próprias se referenciam, inclusive as que espelham arquivo de outra pasta.
  if (index(d, "/") == 0 && (d in known)) return d anchor
  resolved = resolve(SRCDIR, d)
  if (resolved in page) return page[resolved] anchor
  # Link entre páginas escrito como a wiki resolve, sem extensão ("[x](Conceitos)").
  if ((resolved ".md") in page) return page[resolved ".md"] anchor
  return BLOB "/" resolved anchor
}

function rewrite(s,   out, rest, idx, cpos, dest) {
  out = ""; rest = s
  while ((idx = index(rest, "](")) > 0) {
    out = out substr(rest, 1, idx + 1)
    rest = substr(rest, idx + 2)
    cpos = index(rest, ")")
    if (cpos == 0) return out rest
    dest = substr(rest, 1, cpos - 1)
    rest = substr(rest, cpos)
    out = out convert(dest)
  }
  return out rest
}

FNR == NR { page[$1] = $2; known[$2] = 1; next }
{
  if ($0 ~ /^[ \t]*```/) fence = !fence
  print (fence ? $0 : rewrite($0))
}
AWK

# --- Renderização ---
PAGES_NOW="$TMP/pages-now.txt"
: > "$PAGES_NOW"

# $MAP é lido duas vezes (redirect do loop + insumo do awk), nunca escrito aqui
# shellcheck disable=SC2094
while read -r src page; do
  [ -n "${src:-}" ] || continue
  srcdir="$(dirname "$src")"
  [ "$srcdir" = "." ] && srcdir=""
  out="$WIKI_DIR/$page.md"

  {
    printf '<!-- keelson:generated source=%s — não edite pela UI do wiki -->\n' "$src"
    # Banner visível só nos espelhos: ali o dono do texto é outro arquivo, e quem lê
    # precisa saber onde propor a mudança. Nas páginas próprias e nas parciais (_Sidebar,
    # _Footer, que aparecem em toda página) o rodapé da wiki já diz isso.
    case "$src" in
      docs/wiki/*) : ;;
      *)
        printf '> ℹ️ Página gerada a partir de [`%s`](%s/%s) no repositório do keelson —\n' \
          "$src" "$BLOB_BASE" "$src"
        printf '> é lá que ela se altera (via Pull Request). Edições feitas aqui são sobrescritas.\n\n'
        ;;
    esac
    awk -v SRCDIR="$srcdir" -v BLOB="$BLOB_BASE" -f "$AWK_REWRITE" "$MAP" "$src"
  } > "$out" || die "falha ao renderizar $src → $page.md"

  printf '%s\n' "$page.md" >> "$PAGES_NOW"
done < "$MAP"

# --- Órfãos: página que saiu do manifesto some da wiki (só as que nós geramos) ---
if [ -f "$WIKI_DIR/$PAGES_STATE" ]; then
  while read -r old; do
    [ -n "${old:-}" ] || continue
    grep -qxF "$old" "$PAGES_NOW" && continue
    [ -f "$WIKI_DIR/$old" ] || continue
    git -C "$WIKI_DIR" rm --quiet -f "$old" >/dev/null 2>&1 || rm -f "$WIKI_DIR/$old"
    echo "removida: $old"
  done < "$WIKI_DIR/$PAGES_STATE"
fi
sort "$PAGES_NOW" > "$WIKI_DIR/$PAGES_STATE"

# --- Publicação ---
git -C "$WIKI_DIR" add -A || die "git add no clone do wiki falhou."

if git -C "$WIKI_DIR" diff --cached --quiet; then
  echo "Wiki de $SLUG já está em dia — nada a publicar."
  exit 0
fi

echo "Mudanças a publicar em $SLUG.wiki ($BRANCH):"
git -C "$WIKI_DIR" diff --cached --stat

if [ "$CHECK" -eq 1 ]; then
  echo ""
  echo "ERRO: a wiki publicada está desatualizada em relação a docs/wiki/ e aos espelhos." >&2
  echo "Rode: scripts/publish-wiki.sh" >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "(--dry-run: nada foi commitado nem enviado)"
  exit 0
fi

if [ -z "$MESSAGE" ]; then
  SHA="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  MESSAGE="docs: publish wiki from $SHA"
fi

git -C "$WIKI_DIR" commit --quiet -m "$MESSAGE" || die "commit no clone do wiki falhou."
git -C "$WIKI_DIR" push --quiet origin "HEAD:$BRANCH" || die "push para o wiki falhou."

echo ""
echo "Wiki publicada: https://github.com/$SLUG/wiki"
