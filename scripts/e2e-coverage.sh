#!/usr/bin/env bash
# e2e-coverage.sh — fato mecânico da cobertura AC → spec E2E (decisão 4.166).
#
# Cruza os ACs definidos nas SPECs de um slug com as tags `@AC-NNN-XXX` dos specs E2E
# versionados do projeto (arquivos tagueados com `@<slug>`). Read-only; validators e o
# gate 9 citam a saída como fato — a calibração (nem todo AC é de tela) continua deles.
#
# Uso: scripts/e2e-coverage.sh <dir-do-slug> <dir-dos-specs-e2e>
#   <dir-do-slug>      p.ex. docs/meu-slug (o slug é o basename; SPECs em specs/SPEC-*.md)
#   <dir-dos-specs-e2e> diretório dos specs E2E do projeto (p.ex. e2e/ ou tests/e2e/)
#
# Saída (stdout), uma linha por achado: SEVERIDADE<TAB>check<TAB>detalhe
#   WARNING  e2e-dir-ausente   diretório de specs E2E não existe (quality.e2e mal configurado?)
#   WARNING  e2e-tag-orfa      tag @AC em arquivo do slug que não existe nas SPECs dele
#   INFO     ac-sem-spec-e2e   AC definido sem spec E2E tagueado — fato, não defeito
#   INFO     e2e-cobertura     resumo M/N
#
# Exit: 0 rodou (achado não muda o exit — não há classe ERROR aqui) · 2 uso incorreto.
# Âncora de AC idêntica à do graph.sh: linha `- **AC-NNN-XXX**` na SPEC. Na dúvida o
# script degrada (WARNING/omissão), nunca inventa achado. Bash 3.2 + awk POSIX.

set -u
LC_ALL=C
export LC_ALL

if [ $# -ne 2 ]; then
  echo "uso: $0 <dir-do-slug> <dir-dos-specs-e2e>" >&2
  exit 2
fi

SLUGDIR="${1%/}"
E2EDIR="${2%/}"

if [ ! -d "$SLUGDIR" ]; then
  echo "ERRO: dir do slug não existe: $SLUGDIR" >&2
  exit 2
fi
SLUG="$(basename "$SLUGDIR")"

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

# ACs definidos nas SPECs do slug (âncora do graph.sh: `- **AC-NNN-XXX**`)
: > "$TMP/defined"
if ls "$SLUGDIR"/specs/SPEC-*.md >/dev/null 2>&1; then
  awk '/^- \*\*AC-[0-9]+-[0-9]+\*\*/ {
         if (match($0, /AC-[0-9]+-[0-9]+/)) print substr($0, RSTART, RLENGTH)
       }' "$SLUGDIR"/specs/SPEC-*.md | sort -u > "$TMP/defined"
fi

if [ ! -d "$E2EDIR" ]; then
  printf 'WARNING\te2e-dir-ausente\t%s não existe\n' "$E2EDIR"
  exit 0
fi

# Arquivos de spec E2E deste slug: os que carregam a tag `@<slug>` (fronteira de
# palavra manual — `@demo` não pode casar `@demo-admin`).
grep -rlE -- "@${SLUG}([^A-Za-z0-9_-]|\$)" "$E2EDIR" 2>/dev/null | sort > "$TMP/files"

# Tags órfãs (por arquivo) + união das tags do slug
: > "$TMP/tagged"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -oE -- '@AC-[0-9]+-[0-9]+' "$f" 2>/dev/null | sed 's/^@//' | sort -u > "$TMP/ftags"
  comm -23 "$TMP/ftags" "$TMP/defined" | while IFS= read -r orfa; do
    printf 'WARNING\te2e-tag-orfa\t%s: @%s não existe nas SPECs de %s\n' "$f" "$orfa" "$SLUG"
  done
  cat "$TMP/ftags" >> "$TMP/tagged"
done < "$TMP/files"
sort -u "$TMP/tagged" > "$TMP/tagged.u"

# ACs definidos sem spec E2E — fato para a calibração do gate 9, não defeito
comm -23 "$TMP/defined" "$TMP/tagged.u" | while IFS= read -r ac; do
  printf 'INFO\tac-sem-spec-e2e\t%s sem spec E2E tagueado (@%s)\n' "$ac" "$SLUG"
done

total="$(awk 'END{print NR}' "$TMP/defined")"
covered="$(comm -12 "$TMP/defined" "$TMP/tagged.u" | awk 'END{print NR}')"
printf 'INFO\te2e-cobertura\t%s/%s ACs de %s com spec E2E (@%s)\n' "$covered" "$total" "$SLUG" "$SLUG"

exit 0
