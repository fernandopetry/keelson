#!/usr/bin/env bash
# scope-scan.sh — a promessa já vive numa SPEC do slug? (decisão 4.479)
#
# Fato mecânico para a Etapa 0 do /keelson:auto (e a triagem): antes de abrir SPEC nova,
# varre o §4 (Escopo) de toda SPEC do slug pelos termos do pedido e imprime cada bullet
# do In-scope/Out-of-scope que os cita. Termo no **Out-of-scope** de SPEC aprovada é a
# assinatura da rota EMENDA (4.398: "um item do out-of-scope que entra") — SPEC nova
# só com DEC ou componente novo declarado; termo no **In-scope** é promessa já feita
# (duplicata ou extensão, nunca pedido novo). O script não decide: nomeia o fato.
#
# Uso: scope-scan.sh <dir-do-slug> <termo> [<termo>…]
#   <dir-do-slug>  {docsRoot}/<slug>, já resolvido pelo chamador
#   <termo>        radical do pedido, 1 palavra cada (ex.: `multiplic`, `divis`, `export`);
#                  casamento por substring, sem distinção de caixa nem de acento
# Saída: `SPEC-NNN<TAB><Status><TAB>4.1|4.2<TAB><bullet>` por acerto, na ordem das SPECs;
#        nada quando nenhum bullet cita os termos (ausência de acerto é fato, não erro).
# Exit: 0 normal · 2 uso incorreto. Read-only. Bash 3.2 + awk POSIX, sem dependências.
set -u
LC_ALL=C
export LC_ALL
dir="${1:-}"
[ -n "$dir" ] && [ $# -ge 2 ] || { echo "uso: scope-scan.sh <dir-do-slug> <termo> [<termo>…]" >&2; exit 2; }
[ -d "$dir" ] || { echo "scope-scan: diretório não encontrado: $dir" >&2; exit 2; }
shift
fold() { # minúsculas + acentos comuns do português dobrados para ASCII (bytes UTF-8)
  # shellcheck disable=SC2018,SC2019  # LC_ALL=C: só ASCII no tr; os acentos (bytes UTF-8) dobram no sed abaixo
  printf '%s' "$1" | tr 'A-Z' 'a-z' \
    | sed 's/á/a/g; s/à/a/g; s/â/a/g; s/ã/a/g; s/é/e/g; s/ê/e/g; s/í/i/g; s/ó/o/g; s/ô/o/g; s/õ/o/g; s/ú/u/g; s/ç/c/g; s/Á/a/g; s/À/a/g; s/Â/a/g; s/Ã/a/g; s/É/e/g; s/Ê/e/g; s/Í/i/g; s/Ó/o/g; s/Ô/o/g; s/Õ/o/g; s/Ú/u/g; s/Ç/c/g'
}
termos=""
for t in "$@"; do
  ft="$(fold "$t")"
  [ -n "$ft" ] || continue
  termos="$termos$ft
"
done
[ -n "$termos" ] || { echo "scope-scan: nenhum termo válido" >&2; exit 2; }
for f in "$dir"/specs/SPEC-*.md; do
  [ -f "$f" ] || continue
  id="$(basename "$f" | sed -n 's/^\(SPEC-[0-9][0-9]*\)[-.].*/\1/p')"
  [ -n "$id" ] || continue
  st="$(sed -n 's/^\*\*Status\*\*[ 	]*:[ 	]*//p' "$f" | sed -n 1p | sed 's/\r$//; s/[ 	]*$//')"
  # bullets do §4.1/§4.2, com a versão dobrada ao lado para o casamento
  awk '
    /^## / { sec = ""; next }
    /^### 4\.1/ { sec = "4.1"; next }
    /^### 4\.2/ { sec = "4.2"; next }
    /^### / { sec = ""; next }
    sec != "" && /^[-*] / { b = $0; sub(/^[-*][ \t]+/, "", b); print sec "\t" b }
  ' "$f" | while IFS="$(printf '\t')" read -r sec bullet; do
    fb="$(fold "$bullet")"
    hit=0
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      case "$fb" in *"$t"*) hit=1; break ;; esac
    done <<EOF
$termos
EOF
    [ "$hit" = 1 ] && printf '%s\t%s\t%s\t%s\n' "$id" "${st:-?}" "$sec" "$bullet"
  done
done
exit 0
