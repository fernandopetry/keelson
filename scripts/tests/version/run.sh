#!/usr/bin/env bash
# run.sh — suíte de regressão do scripts/version.sh (decisão 4.381).
#
# Cobre o que o report promete: a versão carregada vem do plugin.json da raiz; a
# origem da árvore é classificada (cache da CLI · Desktop · desenvolvimento · fora da
# loja); a ficha da CLI é lida por scope com o marcador "<- esta sessao" (com jq e no
# fallback sem jq); o cache do marketplace é comparado numericamente (0.9 < 0.10); cada
# fonte ausente vira linha "nao encontrado" e o veredito degrada em vez de inventar;
# uso incorreto e raiz sem plugin.json saem 2.
#
# Tudo em diretório temporário: loja da CLI sintética (--plugins-dir) + raízes de
# plugin sintéticas; `claude` é shim no PATH (nunca a CLI real).
#
# Uso: scripts/tests/version/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION="$HERE/../../version.sh"
[ -f "$VERSION" ] || { echo "ERRO: version.sh não encontrado em $VERSION" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$VERSION" || { echo "FAIL bash -n version.sh"; exit 1; }
echo "ok   bash -n version.sh"

# --- loja da CLI sintética ---
STORE="$TMP/plugins"
CACHE="$STORE/cache/keelson/keelson"
mkdir -p "$CACHE" "$STORE/marketplaces/keelson/.claude-plugin"

mkplugin() { # dir versao [charter]
  mkdir -p "$1/.claude-plugin" "$1/guidelines/_meta"
  printf '{\n  "name": "keelson",\n  "version": "%s"\n}\n' "$2" > "$1/.claude-plugin/plugin.json"
  if [ -n "${3:-}" ]; then
    printf '# QUALITY-CHARTER\n\n> **Versão: %s** — referência.\n' "$3" > "$1/guidelines/_meta/QUALITY-CHARTER.md"
  fi
}

mkplugin "$CACHE/0.10.0" 0.10.0 0.6.0
mkplugin "$CACHE/0.9.0"  0.9.0  0.6.0

DESKTOP="$TMP/Library/Application Support/Claude/local-agent-mode-sessions/org/user/rpm/plugin_01ABC"
mkplugin "$DESKTOP" 0.8.0 0.6.0

DEV="$TMP/dev/keelson"
mkplugin "$DEV" 0.11.0        # sem Charter: cobre a linha sem parêntese
mkdir -p "$DEV/.git"

OTHER="$TMP/elsewhere/keelson"
mkplugin "$OTHER" 0.10.0 0.6.0

writeficha() { # versao-user path-user
  cat > "$STORE/installed_plugins.json" <<EOF
{
  "version": 2,
  "plugins": {
    "outro@loja": [
      { "scope": "user", "installPath": "$STORE/cache/outro/outro/1.0.0", "version": "1.0.0" }
    ],
    "keelson@keelson": [
      {
        "scope": "user",
        "installPath": "$2",
        "version": "$1",
        "gitCommitSha": "abc"
      },
      {
        "scope": "project",
        "projectPath": "$TMP/proj",
        "installPath": "$CACHE/0.9.0",
        "version": "0.9.0"
      }
    ]
  }
}
EOF
}
writeficha 0.10.0 "$CACHE/0.10.0"

writemk() { # versao
  printf '{\n  "name": "keelson",\n  "metadata": { "version": "%s" }\n}\n' "$1" \
    > "$STORE/marketplaces/keelson/.claude-plugin/marketplace.json"
}
writemk 0.10.0
cat > "$STORE/known_marketplaces.json" <<EOF
{
  "keelson": { "installLocation": "$STORE/marketplaces/keelson", "lastUpdated": "2026-09-06T00:00:00.000Z" }
}
EOF

# shim da CLI: nunca a real
mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho "9.9.9 (shim)"\n' > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"

run() { # root [args...] → stdout+stderr em $out, exit em $st
  r="$1"; shift
  out="$(PATH="$TMP/bin:$PATH" bash "$VERSION" --root "$r" --plugins-dir "$STORE" "$@" 2>&1)"
  st=$?
}

has() { # nome trecho-esperado (na saída da última run)
  total=$((total + 1))
  case "$out" in
    *"$2"*) echo "ok   $1" ;;
    *) echo "FAIL $1: esperado [$2]"; printf '%s\n' "$out" | sed 's/^/    /'; fail=$((fail + 1)) ;;
  esac
}
lacks() { # nome trecho-proibido
  total=$((total + 1))
  case "$out" in
    *"$2"*) echo "FAIL $1: nao esperado [$2]"; printf '%s\n' "$out" | sed 's/^/    /'; fail=$((fail + 1)) ;;
    *) echo "ok   $1" ;;
  esac
}
exit_is() { # nome esperado
  total=$((total + 1))
  if [ "$st" -eq "$2" ]; then echo "ok   $1"; else echo "FAIL $1: exit $st (esperado $2)"; fail=$((fail + 1)); fi
}

# 1. cache da CLI, ficha aponta para esta árvore, marketplace igual → coincide
run "$CACHE/0.10.0"
exit_is cache-exit-0 0
has cache-carregada "keelson carregado nesta sessao: 0.10.0 (Quality Charter 0.6.0)"
has cache-origem "origem: cache da CLI"
has cache-scope-marcado "user: 0.10.0  <- esta sessao"
has cache-outro-scope "project: 0.9.0"
lacks cache-outro-scope-nao-marcado "project: 0.9.0  <- esta sessao"
has cache-coincide "Sessao e instalacao coincidem (scope: user)."
has cache-marketplace "marketplace (cache local, ultimo refresh 2026-09-06T00:00:00.000Z): 0.10.0"
has cache-ultima "E a ultima versao conhecida no cache local do marketplace."
has cache-claude "Claude Code: 9.9.9 (shim)"
lacks cache-sem-atencao "ATENCAO"

# 2. cache da CLI, ficha já aponta para outra árvore (update sem restart), marketplace à frente
writeficha 0.11.0 "$CACHE/0.11.0"
writemk 0.11.0
run "$CACHE/0.10.0"
has restart-atencao "ATENCAO: a ficha da CLI nao aponta mais para esta arvore (user:0.11.0 project:0.9.0)"
has restart-reinicie "A sessao corrente continua em 0.10.0; reinicie-a."
has restart-mais-nova "Ha versao mais nova conhecida no marketplace: 0.11.0 (esta sessao: 0.10.0)."
has restart-acao-update "Atualize com /keelson:update"
lacks restart-nao-coincide "Sessao e instalacao coincidem"

# 3. comparação numérica: 0.9.0 carregada vs 0.10.0 no marketplace → mais nova (não lexicográfica)
writeficha 0.9.0 "$CACHE/0.9.0"
writemk 0.10.0
run "$CACHE/0.9.0"
has vercmp-numerico "Ha versao mais nova conhecida no marketplace: 0.10.0 (esta sessao: 0.9.0)."
has vercmp-coincide "Sessao e instalacao coincidem (scope: user project)."

# 4. loja do Desktop → origem nomeada, update não alcança, sem sugerir /keelson:update
writeficha 0.10.0 "$CACHE/0.10.0"
run "$DESKTOP"
has desktop-origem "origem: loja propria do Claude Desktop"
has desktop-atencao "ATENCAO: esta sessao carrega a copia da loja do Claude Desktop"
has desktop-nao-alcanca "NAO alcanca esta copia"
has desktop-mais-nova "Ha versao mais nova conhecida no marketplace: 0.10.0 (esta sessao: 0.8.0)."
lacks desktop-sem-update "Atualize com /keelson:update"

# 5. árvore de desenvolvimento (.git), sem Charter, à frente do marketplace
run "$DEV"
has dev-origem "origem: repositorio de desenvolvimento"
has dev-carregada-sem-charter "keelson carregado nesta sessao: 0.11.0"
lacks dev-sem-parentese "(Quality Charter"
has dev-veredito "Arvore de desenvolvimento: a versao e a do checkout"
has dev-a-frente "A frente do marketplace conhecido (0.10.0)"

# 6. fora da loja (sem .git, fora do cache, fora do padrão Desktop)
run "$OTHER"
has other-origem "origem: fora da loja da CLI"
has other-atencao "ATENCAO: esta sessao carrega uma arvore fora da loja da CLI"

# 7. fallback sem jq: mesma leitura por scope (best-effort)
saved_path="$PATH"
NOJQ="$TMP/nojq"; mkdir -p "$NOJQ"
for b in bash sed awk tr head grep cat dirname; do
  p="$(command -v "$b")"; [ -n "$p" ] && ln -sf "$p" "$NOJQ/$b"
done
out="$(PATH="$NOJQ" bash "$VERSION" --root "$CACHE/0.10.0" --plugins-dir "$STORE" 2>&1)"; st=$?
exit_is nojq-exit-0 0
has nojq-marcado "(leitura best-effort sem jq)"
has nojq-scope-user "user: 0.10.0  <- esta sessao"
has nojq-scope-project "project: 0.9.0"
has nojq-coincide "Sessao e instalacao coincidem (scope: user)."
has nojq-claude-ausente "Claude Code: CLI 'claude' nao encontrada no PATH"
has nojq-refresh-data "ultimo refresh 2026-09-06T00:00:00.000Z"
PATH="$saved_path"

# 8. ficha sem o keelson → "nao consta", veredito degrada
cat > "$STORE/installed_plugins.json" <<EOF
{ "version": 2, "plugins": { "outro@loja": [ { "scope": "user", "installPath": "/x", "version": "1.0.0" } ] } }
EOF
run "$CACHE/0.10.0"
has ficha-sem-keelson "keelson@keelson nao consta na ficha (nenhum scope)"
has ficha-sem-keelson-veredito "Nao da para comparar com a ficha da CLI"

# 9. ficha ausente
rm -f "$STORE/installed_plugins.json"
run "$CACHE/0.10.0"
exit_is ficha-ausente-exit-0 0
has ficha-ausente "ficha nao encontrada"
has ficha-ausente-veredito "Nao da para comparar com a ficha da CLI"

# 10. cache do marketplace ausente → linha honesta, sem comparação
writeficha 0.10.0 "$CACHE/0.10.0"
rm -f "$STORE/marketplaces/keelson/.claude-plugin/marketplace.json"
run "$CACHE/0.10.0"
has mk-ausente "marketplace: cache local nao encontrado"
has mk-ausente-veredito "Sem cache do marketplace nao da para dizer se ha versao mais nova"
lacks mk-ausente-sem-comparacao "Ha versao mais nova"
writemk 0.10.0

# 11. raiz sem plugin.json → exit 2 com erro nomeado
mkdir -p "$TMP/vazio"
run "$TMP/vazio"
exit_is sem-plugin-json-exit-2 2
has sem-plugin-json-erro "nao e um plugin keelson"

# 12. opção desconhecida → exit 2
run "$CACHE/0.10.0" --nope
exit_is opcao-desconhecida-exit-2 2

# 13. CLAUDE_PLUGIN_ROOT é o default da raiz quando --root falta
out="$(CLAUDE_PLUGIN_ROOT="$CACHE/0.9.0" PATH="$TMP/bin:$PATH" bash "$VERSION" --plugins-dir "$STORE" 2>&1)"; st=$?
exit_is env-root-exit-0 0
has env-root-carregada "keelson carregado nesta sessao: 0.9.0"

# 14. read-only: nada na loja mudou
before="$(find "$STORE" -type f | sort | xargs cat | cksum)"
run "$CACHE/0.10.0"
after="$(find "$STORE" -type f | sort | xargs cat | cksum)"
total=$((total + 1))
if [ "$before" = "$after" ]; then echo "ok   read-only"; else echo "FAIL read-only: a loja mudou"; fail=$((fail + 1)); fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "version: $total/$total ok"
  exit 0
fi
echo "version: $fail de $total FALHARAM"
exit 1
