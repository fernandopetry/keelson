#!/usr/bin/env bash
# run.sh — suíte do publish-wiki.sh contra um remoto Git LOCAL (decisões 4.81/4.386).
#
# Repo-fonte sintético (docs/wiki/ + espelhos nos caminhos reais do MIRRORS) e um
# bare local fazendo o papel do <repo>.wiki.git, já "inicializado pela UI" (Home
# + uma página MANUAL). O script é copiado para scripts/ do repo-fonte, então
# REPO_ROOT resolve para ele; --remote aponta o bare (nada sai para a rede). Provado:
#   --check em wiki atrasada → exit 1 e o bare não muda; --dry-run → exit 0, sem
#     commit; publicação → páginas próprias + espelhos no bare, manifesto
#     .keelson-wiki-pages, página manual PRESERVADA;
#   reescrita de links — nome de página conhecido, caminho relativo para fonte
#     publicada (com âncora), arquivo não publicado → blob no GitHub, URL/âncora
#     intocadas, bloco de código intocado; banner de origem só nos espelhos;
#   idempotência — 2ª publicação "já está em dia" sem commit novo; --check verde;
#   órfãos — página que saiu de docs/wiki/ some do bare, manual continua;
#   sobrescrita — edição na wiki de página gerada é sobrescrita; clone local
#     sujo é resetado; --message vira a mensagem do commit;
#   erros nomeados — wiki não inicializada → exit 1; sem remote origin → exit 1;
#     opção desconhecida → exit 1.
#
# Uso: scripts/tests/wiki/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
PUB="$HERE/../../publish-wiki.sh"
[ -f "$PUB" ] || { echo "ERRO: publish-wiki.sh não encontrado em $PUB" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$PUB" || { echo "FAIL bash -n publish-wiki.sh"; exit 1; }
echo "ok   bash -n publish-wiki.sh"

SRC="$TMP/src"; BARE="$TMP/wiki.git"; WD="$TMP/wiki-clone"
G() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }

# --- repo-fonte ---
mkdir -p "$SRC/docs/wiki" "$SRC/docs/_meta/conventions" "$SRC/guidelines/_meta" "$SRC/scripts"
git -C "$SRC" init -q
git -C "$SRC" remote add origin https://github.com/acme/keelson.git
cp "$PUB" "$SRC/scripts/publish-wiki.sh"; chmod +x "$SRC/scripts/publish-wiki.sh"
cat > "$SRC/docs/wiki/Home.md" <<'EOF'
# Home

Comece em [Conceitos](Conceitos).
EOF
cat > "$SRC/docs/wiki/Conceitos.md" <<'EOF'
# Conceitos

- pagina conhecida: [Primeiros passos](Primeiros-passos)
- espelho por caminho: [guia](../_meta/method-guide.md#secao-2)
- espelho por nome: [contrato](Contrato-do-INDEX)
- nao publicado: [script](../../scripts/graph.sh)
- externo: [issues](https://github.com/acme/keelson/issues)
- ancora: [topo](#conceitos)

```bash
# dentro de fence nada muda: [x](../_meta/method-guide.md)
```
EOF
printf '# Primeiros passos\n\nVolte a [Home](Home).\n' > "$SRC/docs/wiki/Primeiros-passos.md"
printf '# Guia\n\n## secao 2\n\nVeja [o contrato](conventions/index-contract.md) e [o Charter](../../guidelines/_meta/QUALITY-CHARTER.md).\n' > "$SRC/docs/_meta/method-guide.md"
printf '# Contrato do INDEX\n' > "$SRC/docs/_meta/conventions/index-contract.md"
printf '# Charter\n' > "$SRC/guidelines/_meta/QUALITY-CHARTER.md"
G "$SRC" add -A; G "$SRC" commit -q -m fonte

# --- bare "inicializado pela UI": Home + página manual ---
git init -q --bare -b master "$BARE" 2>/dev/null || git init -q --bare "$BARE"
SEED="$TMP/seed"; git clone -q "$BARE" "$SEED" 2>/dev/null
printf 'primeira pagina criada pela UI\n' > "$SEED/Home.md"; printf '# Manual\n\nescrita a mao\n' > "$SEED/Manual.md"
G "$SEED" add -A; G "$SEED" commit -q -m seed; BR="$(git -C "$SEED" rev-parse --abbrev-ref HEAD)"; git -C "$SEED" push -q origin "HEAD:$BR" 2>/dev/null

pub() { # args → $TMP/out, $st
  ( cd "$SRC" && bash scripts/publish-wiki.sh --remote "$BARE" --wiki-dir "$WD" "$@" ) > "$TMP/out" 2>&1
  st=$?
}
tem() { grep -qF -- "$1" "$TMP/out"; }
bare_head() { git -C "$BARE" rev-parse "$BR" 2>/dev/null; }
bare_file() { git -C "$BARE" show "$BR:$1" 2>/dev/null; }
bare_has() { git -C "$BARE" cat-file -e "$BR:$1" 2>/dev/null; }

# --- --check e --dry-run não publicam ---
h0="$(bare_head)"
pub --check
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "a wiki publicada está desatualizada" && [ "$(bare_head)" = "$h0" ]; then ok check-atrasada-exit-1-sem-push
else falha "check-atrasada-exit-1-sem-push: exit=$st $(tail -3 "$TMP/out")"; fi
pub --dry-run
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "(--dry-run: nada foi commitado nem enviado)" && tem "Conceitos.md" && [ "$(bare_head)" = "$h0" ]; then ok dry-run-mostra-sem-publicar
else falha "dry-run-mostra-sem-publicar: exit=$st $(tail -3 "$TMP/out")"; fi

# --- publicação ---
pub --message "docs: teste"
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "Wiki publicada: https://github.com/acme/keelson/wiki" && [ "$(bare_head)" != "$h0" ]; then ok publica-exit-0
else falha "publica-exit-0: exit=$st $(tail -3 "$TMP/out")"; fi
total=$((total + 1))
if bare_has Home.md && bare_has Conceitos.md && bare_has Primeiros-passos.md && bare_has Guia-do-metodo.md && bare_has Contrato-do-INDEX.md && bare_has Quality-Charter.md; then ok paginas-proprias-e-espelhos-no-bare
else falha "paginas-proprias-e-espelhos-no-bare: $(git -C "$BARE" ls-tree --name-only "$BR" | tr '\n' ' ')"; fi
total=$((total + 1))
if [ "$(bare_file Manual.md)" = "$(printf '# Manual\n\nescrita a mao')" ]; then ok pagina-manual-preservada; else falha "pagina-manual-preservada"; fi
total=$((total + 1))
if [ "$(bare_file .keelson-wiki-pages | tr '\n' ' ')" = "Conceitos.md Contrato-do-INDEX.md Guia-do-metodo.md Home.md Primeiros-passos.md Quality-Charter.md " ]; then ok manifesto-gerado-ordenado
else falha "manifesto-gerado-ordenado: [$(bare_file .keelson-wiki-pages | tr '\n' ' ')]"; fi
total=$((total + 1))
if [ "$(git -C "$BARE" log -1 --format=%s "$BR")" = "docs: teste" ]; then ok message-custom; else falha "message-custom: $(git -C "$BARE" log -1 --format=%s "$BR")"; fi
total=$((total + 1))
if [ "$(bare_file Home.md | head -1)" = "<!-- keelson:generated source=docs/wiki/Home.md — não edite pela UI do wiki -->" ]; then ok home-da-ui-substituida-com-marca
else falha "home-da-ui-substituida-com-marca: $(bare_file Home.md | head -1)"; fi

# --- reescrita de links ---
C="$(bare_file Conceitos.md)"
chk() { total=$((total + 1)); if printf '%s\n' "$C" | grep -qF -- "$2"; then ok "$1"; else falha "$1: [$2] ausente"; fi; }
chk link-pagina-conhecida            '[Primeiros passos](Primeiros-passos)'
chk link-espelho-por-caminho-com-ancora '[guia](Guia-do-metodo#secao-2)'
chk link-espelho-por-nome            '[contrato](Contrato-do-INDEX)'
chk link-nao-publicado-vira-blob     '[script](https://github.com/acme/keelson/blob/main/scripts/graph.sh)'
chk link-externo-intocado            '[issues](https://github.com/acme/keelson/issues)'
chk link-ancora-intocada             '[topo](#conceitos)'
chk fence-intocado                   '# dentro de fence nada muda: [x](../_meta/method-guide.md)'
total=$((total + 1))
if ! printf '%s\n' "$C" | grep -q 'Página gerada a partir de'; then ok pagina-propria-sem-banner; else falha pagina-propria-sem-banner; fi
M="$(bare_file Guia-do-metodo.md)"
total=$((total + 1))
if printf '%s\n' "$M" | grep -qF 'Página gerada a partir de [`docs/_meta/method-guide.md`](https://github.com/acme/keelson/blob/main/docs/_meta/method-guide.md)'; then ok espelho-com-banner-de-origem
else falha "espelho-com-banner-de-origem: $(printf '%s\n' "$M" | head -3)"; fi
total=$((total + 1))
if printf '%s\n' "$M" | grep -qF '[o contrato](Contrato-do-INDEX)' && printf '%s\n' "$M" | grep -qF '[o Charter](Quality-Charter)'; then ok espelho-links-relativos-resolvidos
else falha "espelho-links-relativos-resolvidos: $M"; fi

# --- idempotência ---
h1="$(bare_head)"
pub
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "já está em dia — nada a publicar" && [ "$(bare_head)" = "$h1" ]; then ok segunda-publicacao-no-op
else falha "segunda-publicacao-no-op: exit=$st $(tail -2 "$TMP/out")"; fi
pub --check
total=$((total + 1))
if [ "$st" -eq 0 ]; then ok check-em-dia-exit-0; else falha "check-em-dia-exit-0: exit=$st"; fi

# --- órfãos e sobrescrita ---
git -C "$SRC" rm -q docs/wiki/Primeiros-passos.md; sed -i.bak 's/\[Primeiros passos\](Primeiros-passos)/removida/' "$SRC/docs/wiki/Conceitos.md"; rm -f "$SRC/docs/wiki/Conceitos.md.bak"
G "$SRC" commit -q -am remove-pagina
# edição "pela UI" de página gerada + lixo no clone local
EDIT="$TMP/edit"; rm -rf "$EDIT"; git clone -q "$BARE" "$EDIT" 2>/dev/null
printf 'editado pela UI\n' >> "$EDIT/Conceitos.md"; G "$EDIT" commit -q -am ui-edit; git -C "$EDIT" push -q origin "HEAD:$BR" 2>/dev/null
printf 'lixo\n' > "$WD/lixo-local.md"
pub
total=$((total + 1))
if [ "$st" -eq 0 ] && tem "removida: Primeiros-passos.md" && ! bare_has Primeiros-passos.md && bare_has Manual.md; then ok orfa-removida-manual-fica
else falha "orfa-removida-manual-fica: exit=$st $(tail -3 "$TMP/out")"; fi
total=$((total + 1))
if ! bare_file Conceitos.md | grep -q 'editado pela UI'; then ok edicao-na-ui-sobrescrita; else falha edicao-na-ui-sobrescrita; fi
total=$((total + 1))
if ! bare_has lixo-local.md && [ ! -f "$WD/lixo-local.md" ]; then ok clone-local-resetado; else falha clone-local-resetado; fi

# --- erros nomeados ---
pub --remote "$TMP/nao-existe.git"
total=$((total + 1))
( cd "$SRC" && bash scripts/publish-wiki.sh --remote "$TMP/nao-existe.git" --wiki-dir "$WD" ) > "$TMP/out" 2>&1; st=$?
if [ "$st" -eq 1 ] && tem "ainda não foi inicializado"; then ok wiki-nao-inicializada-exit-1; else falha "wiki-nao-inicializada-exit-1: exit=$st $(head -2 "$TMP/out")"; fi
total=$((total + 1))
pub --bogus
if [ "$st" -eq 1 ] && tem "opção desconhecida"; then ok opcao-desconhecida-exit-1; else falha "opcao-desconhecida-exit-1: exit=$st"; fi
git -C "$SRC" remote remove origin
pub
total=$((total + 1))
if [ "$st" -eq 1 ] && tem "remote 'origin' ausente"; then ok sem-origin-exit-1; else falha "sem-origin-exit-1: exit=$st $(head -2 "$TMP/out")"; fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "wiki: $fail de $total casos falharam"
  exit 1
fi
echo "wiki: $total casos verdes"
exit 0
