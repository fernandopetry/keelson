#!/usr/bin/env bash
# run.sh — suíte de regressão do doc-guard (decisões 4.6/4.385).
#
# Roda o hook de verdade (stdin JSON, jq, git status) num repo temporário com
# ficha keelson.config.json (codePaths + docsRoot). Casos inline:
#   block — código de codePaths alterado sem NENHUM artefato em docsRoot (modificado,
#           novo, diretório novo, renomeio); o bloqueio cita docsRoot e o slug legado;
#   allow — código + docs no mesmo working tree; só docs; só arquivo fora de
#           codePaths (prefixo parecido `srcx/` não conta); docsRoot customizado;
#           árvore limpa; ficha sem codePaths; sem ficha (aviso em stderr);
#           stop_hook_active; anti-renudge (mesmo conjunto → silêncio; conjunto
#           diferente → cutuca de novo; marcador em .git/).
#
# Uso: scripts/tests/doc-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/doc-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
if ! command -v jq >/dev/null 2>&1; then
  echo "doc-guard: AVISO — jq ausente, o hook degrada para exit 0 e a suíte não prova nada; pulando." >&2
  exit 0
fi

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n doc-guard.sh"; exit 1; }
echo "ok   bash -n doc-guard.sh"

PROJ="$TMP/proj"
novo_repo() { # [docsRoot] [json-da-ficha]
  rm -rf "$PROJ"; mkdir -p "$PROJ/src/app" "$PROJ/web" "$PROJ/${1:-docs}/slug" "$PROJ/srcx"
  git -C "$PROJ" init -q
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" > "$PROJ/keelson.config.json"
  else printf '{ "docsRoot": "%s", "codePaths": { "backend": ["src"], "frontend": ["web"] } }\n' "${1:-docs}" > "$PROJ/keelson.config.json"; fi
  printf 'a\n' > "$PROJ/src/app/a.txt"; printf 'w\n' > "$PROJ/web/w.txt"
  printf '# doc\n' > "$PROJ/${1:-docs}/slug/INDEX.md"; printf 'x\n' > "$PROJ/srcx/f.txt"
  git -C "$PROJ" add -A; git -C "$PROJ" -c user.email=t@t -c user.name=t commit -q -m base
}

decisao() { # [payload] → block | allow | erro:<st>
  pl="${1:-{\"stop_hook_active\": false\}}"
  out="$(CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" 2>"$TMP/err" <<< "$pl")"
  st=$?
  [ "$st" -eq 0 ] || { printf 'erro:%s' "$st"; return; }
  d="$(printf '%s' "$out" | jq -r '.decision // empty' 2>/dev/null)"
  if [ "$d" = "block" ]; then printf 'block'; elif [ -z "$out" ]; then printf 'allow'; else printf 'outro:%s' "$out"; fi
}

caso() { # nome esperado [payload]
  name="$1"; want="$2"
  total=$((total + 1))
  got="$(decisao "${3:-}")"
  if [ "$got" = "$want" ]; then echo "ok   $name"
  else echo "FAIL $name: esperado $want, veio $got"; fail=$((fail + 1)); fi
}

# --- árvore limpa ---
novo_repo; caso arvore-limpa-allow allow

# --- código sem docs → block; anti-renudge ---
novo_repo; printf 'b\n' >> "$PROJ/src/app/a.txt"
caso codigo-modificado-sem-docs-block block
caso mesmo-conjunto-nao-recutuca allow
total=$((total + 1))
if [ -f "$PROJ/.git/keelson-doc-guard.last" ]; then echo "ok   marcador-em-git"; else echo "FAIL marcador-em-git"; fail=$((fail + 1)); fi
printf 'n\n' > "$PROJ/src/app/novo.txt"
caso conjunto-diferente-recutuca block
caso stop-hook-active-allow allow '{"stop_hook_active": true}'

# --- variantes de mudança de código ---
novo_repo; printf 'n\n' > "$PROJ/src/novo.txt"; caso arquivo-novo-untracked-block block
novo_repo; mkdir -p "$PROJ/src/novo-dir"; printf 'n\n' > "$PROJ/src/novo-dir/f.txt"; caso dir-novo-untracked-block block
novo_repo; git -C "$PROJ" mv src/app/a.txt src/app/b.txt; caso renomeio-block block
novo_repo; printf 'f\n' >> "$PROJ/web/w.txt"; caso frontend-sem-docs-block block

# --- allow: docs acompanham, ou a mudança não é de código ---
novo_repo; printf 'b\n' >> "$PROJ/src/app/a.txt"; printf 'upd\n' >> "$PROJ/docs/slug/INDEX.md"; caso codigo-com-docs-allow allow
novo_repo; printf 'b\n' >> "$PROJ/src/app/a.txt"; printf 'novo\n' > "$PROJ/docs/outro.md"; caso codigo-com-doc-nova-allow allow
novo_repo; printf 'upd\n' >> "$PROJ/docs/slug/INDEX.md"; caso so-docs-allow allow
novo_repo; printf 'x2\n' >> "$PROJ/srcx/f.txt"; caso prefixo-parecido-nao-conta-allow allow
novo_repo; printf 'r\n' > "$PROJ/README.txt"; caso fora-de-codepaths-allow allow

# --- docsRoot customizado ---
novo_repo documentacao; printf 'b\n' >> "$PROJ/src/app/a.txt"; caso docsroot-custom-sem-docs-block block
novo_repo documentacao; printf 'b\n' >> "$PROJ/src/app/a.txt"; printf 'upd\n' >> "$PROJ/documentacao/slug/INDEX.md"; caso docsroot-custom-com-docs-allow allow
novo_repo documentacao; printf 'b\n' >> "$PROJ/src/app/a.txt"; mkdir -p "$PROJ/docs"; printf 'x\n' > "$PROJ/docs/errado.md"; caso docsroot-custom-docs-default-nao-conta-block block

# --- bloqueio cita a raiz de docs e a rota legada ---
novo_repo documentacao; printf 'b\n' >> "$PROJ/src/app/a.txt"
total=$((total + 1))
out="$(CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" 2>/dev/null <<< '{"stop_hook_active": false}')"
r="$(printf '%s' "$out" | jq -r '.reason // empty')"
case "$r" in
  *"documentacao/"*"migrate-legacy"*) echo "ok   reason-cita-docsroot-e-legado" ;;
  *) echo "FAIL reason-cita-docsroot-e-legado: $r"; fail=$((fail + 1)) ;;
esac

# --- fallback gracioso ---
novo_repo docs '{ "docsRoot": "docs" }'; printf 'b\n' >> "$PROJ/src/app/a.txt"; caso ficha-sem-codepaths-allow allow
novo_repo; rm -f "$PROJ/keelson.config.json"; printf 'b\n' >> "$PROJ/src/app/a.txt"
caso sem-ficha-allow allow
total=$((total + 1))
if grep -q 'keelson.config.json não encontrado' "$TMP/err"; then echo "ok   sem-ficha-avisa-stderr"; else echo "FAIL sem-ficha-avisa-stderr: $(cat "$TMP/err")"; fail=$((fail + 1)); fi
novo_repo; printf 'b\n' >> "$PROJ/src/app/a.txt"; caso json-invalido-block block '{nao e json'   # stop_hook_active ilegível = false

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "doc-guard: $fail de $total casos falharam"
  exit 1
fi
echo "doc-guard: $total casos verdes"
exit 0
