#!/usr/bin/env bash
# legacy-move.sh — movimentação transacional do /keelson:migrate-legacy (decisão 4.154).
# Move os .md da raiz do slug legado para legacy/, com `git mv` quando o slug está num
# repositório (fallback: mv) e ROLLBACK automático em falha no meio — rollback parcial
# feito de memória é exatamente o que dá errado sob falha. O TRIAGE, o INDEX espelho e
# o julgamento do que é "parcial" continuam do comando.
#
# Uso: legacy-move.sh <dir-do-slug>
#
# Regras:
# - Pré-condição: o slug NÃO tem INDEX.md (é a definição de legado) → senão exit 2.
# - Move apenas os *.md da RAIZ do slug; subpastas não-SDD ficam intactas.
# - specs/, plans/ ou tasks/ com conteúdo → aviso `sdd-parcial` (caso especial do
#   comando, que alerta o humano) — nunca movidos.
# - Falha em qualquer mv → desfaz os já movidos e sai 1 com a causa.
#
# Saída: movido<TAB><arquivo> · aviso<TAB>sdd-parcial<TAB><dir> · rollback<TAB><arquivo>
# Exit: 0 tudo movido · 1 falha (com rollback executado) · 2 uso incorreto.
# Bash 3.2-compatível.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }

DIR="${1:-}"
[ -n "$DIR" ] || { usage >&2; exit 2; }
case "$DIR" in -h|--help) usage; exit 0 ;; esac
[ -d "$DIR" ] || die2 "diretório não existe: $DIR"
[ ! -f "$DIR/INDEX.md" ] || die2 "$DIR tem INDEX.md — não é slug legado (nada a migrar)."

have_git=0
if command -v git >/dev/null 2>&1 && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  have_git=1
fi

for d in specs plans tasks; do
  if [ -d "$DIR/$d" ] && [ -n "$(ls "$DIR/$d" 2>/dev/null)" ]; then
    printf 'aviso\tsdd-parcial\t%s/ ja existe com conteudo — deixado como esta (alertar o humano)\n' "$d"
  fi
done

any=0
for f in "$DIR"/*.md; do
  [ -f "$f" ] && { any=1; break; }
done
[ "$any" = 1 ] || { echo "aviso	nada-a-mover	nenhum .md na raiz de $DIR"; exit 0; }

mkdir -p "$DIR/legacy" || die2 "não consegui criar $DIR/legacy"

mv_um() { # $1 origem, $2 destino — ambos relativos ao DIR
  [ -e "$DIR/$2" ] && return 1
  if [ "$have_git" = 1 ] && git -C "$DIR" mv "$1" "$2" 2>/dev/null; then
    return 0
  fi
  # arquivo untracked (ou fora de repo): mv comum
  mv "$DIR/$1" "$DIR/$2" 2>/dev/null
}

MOVIDOS=""
falha=""
for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  if mv_um "$b" "legacy/$b"; then
    printf 'movido\t%s\n' "$b"
    MOVIDOS="$MOVIDOS $b"
  else
    falha="$b"
    break
  fi
done

if [ -n "$falha" ]; then
  echo "ERRO: falha ao mover $falha (destino ocupado ou permissão) — desfazendo." >&2
  for b in $MOVIDOS; do
    if mv_um "legacy/$b" "$b"; then printf 'rollback\t%s\n' "$b"
    else echo "ERRO: rollback de $b falhou — estado inconsistente, resolva à mão." >&2; fi
  done
  exit 1
fi
exit 0
