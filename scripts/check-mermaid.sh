#!/usr/bin/env bash
# check-mermaid.sh — todo bloco ```mermaid da superfície publicada da wiki parseia (decisão 4.248).
#
# O que este script prova: cada bloco mermaid das páginas próprias (docs/wiki/*.md) e
# das fontes espelhadas (manifesto MIRRORS de scripts/publish-wiki.sh — lido de lá,
# dono único, nunca duplicado) renderiza sem erro de parse. A classe que motivou o
# check (caso real, commit 784ba51): entidade HTML `&quot;` dentro de rótulo — o
# GitHub decodifica a entidade ANTES de parsear e as aspas aninhadas quebram a
# gramática do mermaid.
#
# Camadas (mesmo padrão do shellcheck/frontmatter, 4.208/4.211):
#   1. lint offline determinístico: `&quot;` em bloco mermaid é ERRO (classe provada);
#      outra entidade HTML (`&amp;`, `&#34;`…) é AVISO (decodificação a conferir);
#      bloco sem fence de fechamento é ERRO.
#   2. render (prova real): cada bloco sem ERRO offline vai ao renderizador
#      mermaid.ink (mesmo parser do GitHub); resposta 4xx = ERRO de parse; rede ou
#      serviço indisponível = AVISO e segue — o CI, que tem rede, é a prova real.
#
# Uso: check-mermaid.sh [--root <dir>] [--no-render]
# Exit: 0 ok/degradado · 1 bloco inválido · 2 uso incorreto.
# Bash 3.2-compatível, awk POSIX, read-only.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

ROOT=""
RENDER=1
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "uso: check-mermaid.sh [--root <dir>] [--no-render]" >&2; exit 2; }
            ROOT="$2"; shift 2 ;;
    --no-render) RENDER=0; shift ;;
    *) echo "uso: check-mermaid.sh [--root <dir>] [--no-render]" >&2; exit 2 ;;
  esac
done
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
[ -d "$ROOT" ] || { echo "ERRO: raiz inexistente: $ROOT" >&2; exit 2; }

# ---- Escopo: páginas próprias + fontes espelhadas do MIRRORS ----
FILES=""
if [ -d "$ROOT/docs/wiki" ]; then
  for f in "$ROOT"/docs/wiki/*.md; do
    [ -f "$f" ] && FILES="$FILES${f#"$ROOT"/}
"
  done
fi
if [ -f "$ROOT/scripts/publish-wiki.sh" ]; then
  mirrors="$(awk -F'|' '
    /^MIRRORS=/ { inm=1; sub(/^MIRRORS='\''/, ""); if (length($1)) print $1; next }
    inm { line=$0; done=0
          if (line ~ /'\''[ \t]*$/) { sub(/'\''[ \t]*$/, "", line); done=1 }
          split(line, p, "|"); if (length(p[1])) print p[1]
          if (done) inm=0 }
  ' "$ROOT/scripts/publish-wiki.sh")"
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    [ -f "$ROOT/$m" ] && FILES="$FILES$m
"
  done <<EOF_MIRRORS
$mirrors
EOF_MIRRORS
fi

if [ -z "$FILES" ]; then
  echo "check-mermaid: ok — nenhuma superfície de wiki no escopo."
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

curl_ok=0
if [ "$RENDER" -eq 1 ] && command -v curl >/dev/null 2>&1; then
  curl_ok=1
fi

fails=0
avisos=0
n_blocos=0
n_arquivos=0
n_render_ok=0
n_render_skip=0

while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -q '^```mermaid[ \t]*$' "$ROOT/$f" 2>/dev/null || continue
  n_arquivos=$((n_arquivos + 1))
  rm -f "$TMP"/blk_*.mmd
  manifest="$(awk -v out="$TMP/blk" '
    /^```mermaid[ \t]*$/ { inb=1; n++; file=out "_" n ".mmd"; printf "" > file; print n " " NR; next }
    inb && /^```[ \t]*$/  { inb=0; close(file); next }
    inb                    { print >> file }
    END { if (inb) print "OPEN " n }
  ' "$ROOT/$f")"

  while read -r idx start; do
    [ -n "$idx" ] || continue
    if [ "$idx" = "OPEN" ]; then
      echo "ERRO: $f: bloco mermaid $start: fence \`\`\` de fechamento ausente"
      fails=$((fails + 1))
      continue
    fi
    n_blocos=$((n_blocos + 1))
    blk="$TMP/blk_${idx}.mmd"
    blk_erro=0

    # Camada 1 — lint offline
    hit="$(grep -n '&quot;' "$blk" 2>/dev/null | head -1 || true)"
    if [ -n "$hit" ]; then
      echo "ERRO: $f: bloco mermaid (linha $start): entidade &quot; no bloco — o GitHub decodifica antes de parsear e as aspas aninhadas quebram (784ba51); use aspas simples no rótulo"
      fails=$((fails + 1)); blk_erro=1
    fi
    hit="$(grep -nE '&[a-zA-Z]+;|&#[0-9]+;' "$blk" 2>/dev/null | grep -v '&quot;' | head -1 || true)"
    if [ -n "$hit" ]; then
      echo "AVISO: $f: bloco mermaid (linha $start): entidade HTML no bloco ($(printf '%s' "$hit" | sed 's/^[0-9]*://; s/^[ \t]*//' | head -c 60)…) — o GitHub decodifica antes de parsear; confira o resultado"
      avisos=$((avisos + 1))
    fi

    # Camada 2 — render real (só para bloco ainda sem ERRO)
    [ "$RENDER" -eq 1 ] || continue
    [ "$blk_erro" -eq 0 ] || continue
    if [ "$curl_ok" -eq 0 ]; then
      echo "AVISO: $f: bloco mermaid (linha $start): não validado — curl ausente (o CI é a prova real)"
      avisos=$((avisos + 1)); n_render_skip=$((n_render_skip + 1))
      continue
    fi
    b64="$(base64 < "$blk" | tr '+/' '-_' | tr -d '\n')"
    body="$TMP/resp.out"
    code="$(curl -sS --max-time 15 -o "$body" -w '%{http_code}' "https://mermaid.ink/svg/${b64}" 2>/dev/null)" || code="000"
    case "$code" in
      200)
        if head -c 4 "$body" 2>/dev/null | grep -q '<svg'; then
          n_render_ok=$((n_render_ok + 1))
        else
          echo "AVISO: $f: bloco mermaid (linha $start): não validado — resposta 200 sem SVG (o CI é a prova real)"
          avisos=$((avisos + 1)); n_render_skip=$((n_render_skip + 1))
        fi ;;
      4*)
        msg="$(head -c 100 "$body" 2>/dev/null | tr -d '\n' || true)"
        echo "ERRO: $f: bloco mermaid (linha $start): parse falhou no renderizador (HTTP $code): $msg"
        fails=$((fails + 1)) ;;
      *)
        echo "AVISO: $f: bloco mermaid (linha $start): não validado — renderizador inacessível (HTTP $code; o CI é a prova real)"
        avisos=$((avisos + 1)); n_render_skip=$((n_render_skip + 1)) ;;
    esac
  done <<EOF_MANIFEST
$manifest
EOF_MANIFEST
done <<EOF_FILES
$FILES
EOF_FILES

if [ "$fails" -gt 0 ]; then
  echo "check-mermaid: $fails bloco(s) mermaid inválido(s)." >&2
  exit 1
fi
if [ "$n_blocos" -eq 0 ]; then
  echo "check-mermaid: ok — nenhum bloco mermaid na superfície da wiki."
  exit 0
fi
resumo="check-mermaid: ok — $n_blocos bloco(s) em $n_arquivos arquivo(s)"
if [ "$RENDER" -eq 1 ]; then
  resumo="$resumo (render: $n_render_ok ok, $n_render_skip não validado)"
else
  resumo="$resumo (render desligado)"
fi
[ "$avisos" -gt 0 ] && resumo="$resumo — $avisos aviso(s)"
echo "$resumo."
exit 0
