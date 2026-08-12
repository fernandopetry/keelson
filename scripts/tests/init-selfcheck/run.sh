#!/usr/bin/env bash
# run.sh — suíte de regressão do init-selfcheck.sh (decisão 4.154).
#
# Monta repos git sintéticos + um plugin-root falso (Charter 0.5.1 e perfil php) e
# compara a saída inteira com a esperada. Regras provadas: matching real dos
# sensitiveGlobs, check-ignore provado, local.json versionado é falha, flags efetivas
# do Playwright por escopo, charter antigo vira aviso, jira com campo vazio é falha.
#
# Uso: scripts/tests/init-selfcheck/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível; exige git.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SC="$HERE/../../init-selfcheck.sh"

[ -f "$SC" ] || { echo "ERRO: init-selfcheck.sh não encontrado" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

# ---- plugin-root falso ----
PR="$TMP/plugin"
mkdir -p "$PR/guidelines/_meta" "$PR/guidelines/backend"
printf '# QUALITY-CHARTER\n\n> **Versão: 0.5.1** — é esta versão que o campo `charter:`...\n' > "$PR/guidelines/_meta/QUALITY-CHARTER.md"
printf -- '---\nlang: php\nversion: "8.5"\ncharter: 0.5.1\nreviewed: true\n---\n# PHP\n' > "$PR/guidelines/backend/php.md"
mkdir -p "$PR/hooks"
printf '#!/bin/sh\nexit 0\n' > "$PR/hooks/guarda.sh"
chmod +x "$PR/hooks/guarda.sh"

mkrepo() { r="$TMP/$1"; mkdir -p "$r"; git -C "$r" init -q; git -C "$r" config user.email t@t; git -C "$r" config user.name t; printf '%s\n' "$r"; }

# ---- caso valido: tudo ok ----
R="$(mkrepo valido)"
mkdir -p "$R/src"
printf 'x\n' > "$R/src/app.php"
printf 'segredo\n' > "$R/.env"
cat > "$R/keelson.config.json" <<'EOF'
{
  "profile": { "backend": { "lang": "php", "version": "8.5", "file": "plugin:backend/php.md" } },
  "codePaths": { "backend": ["src"] },
  "sensitiveGlobs": [".env*", "src/**"],
  "quality": { "test": "true", "lint": null, "boot": null, "mutation": null },
  "gates": { "security": true, "screenVerify": { "enabled": true, "method": "skill:screen-verify", "artifactsDir": "thoughts/screen-verify" } },
  "docsRoot": "docs",
  "jira": { "enabled": false }
}
EOF
printf 'keelson.local.json\nthoughts/\n.playwright-mcp/\n.env\n' > "$R/.gitignore"
cat > "$R/keelson.local.example.json" <<'EOF'
{ "screenVerify": { "defaultRealm": "admin", "realms": { "admin": { "baseUrl": "<url>", "login": { "path": "/login", "username": "<user>", "password": "<senha>" } } } } }
EOF
cat > "$R/keelson.local.json" <<'EOF'
{ "screenVerify": { "defaultRealm": "admin", "realms": {
  "admin":  { "baseUrl": "http://localhost:8080", "login": { "path": "/login", "username": "dev", "password": "x" } },
  "portal": { "baseUrl": "http://localhost:8081", "login": { "path": "/entrar", "username": "dev", "password": "x" } } } } }
EOF
cat > "$R/.mcp.json" <<'EOF'
{ "mcpServers": { "playwright": { "command": "npx", "args": ["@playwright/mcp@latest", "--headless", "--output-dir", "thoughts/screen-verify", "--isolated"] } } }
EOF
git -C "$R" add -A >/dev/null 2>&1
git -C "$R" commit -qm base >/dev/null 2>&1

total=$((total + 1))
got="$(bash "$SC" "$R" --plugin-root "$PR" --claude-json "$TMP/nao-existe.json" 2>/dev/null)"; st=$?
want="ok	artefatos-ignorados	artifactsDir e .playwright-mcp/ ignorados (provado)
ok	codepaths-existem	todos os codePaths existem
ok	ficha-legivel	keelson.config.json parseado
ok	hooks-executaveis	todos os hooks do plugin têm bit de execução
ok	local-example	exemplo presente e versionado
ok	local-json-ignorado	keelson.local.json coberto pelo .gitignore (check-ignore)
ok	local-placeholder	keelson.local.json sem placeholder
ok	perfil-resolve	perfis da ficha resolvem em arquivo
ok	playwright-flags	escopo=projeto modo=headless — flags conferem
ok	quality-existe	todos os quality.* declarados resolvem
ok	sensitive-globs	todos os candidatos em disco casam com sensitiveGlobs"
if [ "$st" -eq 0 ] && [ "$got" = "$want" ]; then echo "ok   valido"
else echo "FAIL valido (exit $st)"; printf 'esperado:\n%s\nobtido:\n%s\n' "$want" "$got" | sed 's/^/  /'; fail=$((fail + 1)); fi

# ---- caso defeituoso ----
R2="$(mkrepo defeituoso)"
printf 'segredo\n' > "$R2/.env"
mkdir -p "$R2/config"
printf 'chave\n' > "$R2/config/id_rsa.key"
cat > "$R2/keelson.config.json" <<'EOF'
{
  "profile": { "backend": { "lang": "go", "version": "1.22", "file": "guidelines/project/backend/go-1.22.md" } },
  "codePaths": { "backend": ["src"] },
  "sensitiveGlobs": [".env"],
  "quality": { "test": "comando-que-nao-existe-xyz --run" },
  "gates": { "screenVerify": { "enabled": true, "method": "skill:screen-verify", "artifactsDir": "thoughts/screen-verify" } },
  "docsRoot": "docs",
  "jira": { "enabled": true, "projectKey": "", "issueType": { "spec": "10001", "task": null } }
}
EOF
mkdir -p "$R2/guidelines/project/backend"
printf -- '---\nlang: go\nversion: "1.22"\ncharter: 0.4.0\nreviewed: false\n---\n# Go\n' > "$R2/guidelines/project/backend/go-1.22.md"
printf '{ "screenVerify": { "baseUrl": "<url do ambiente>", "login": { "path": "/login", "username": "<user>", "password": "<senha>" } } }\n' > "$R2/keelson.local.json"
git -C "$R2" add -A >/dev/null 2>&1
git -C "$R2" commit -qm base >/dev/null 2>&1

total=$((total + 1))
got="$(bash "$SC" "$R2" --plugin-root "$PR" --claude-json "$TMP/nao-existe.json" 2>/dev/null)"; st=$?
want="aviso	local-example	keelson.local.example.json ausente
aviso	local-placeholder	keelson.local.json com campos em placeholder <...> — preencher (dev-only)
aviso	perfil-charter	charter do perfil menor que o atual — re-derivar/revisar: backend(0.4.0<0.5.1)
aviso	perfil-reviewed	perfil pendente de revisão humana (reviewed: false): backend
aviso	quality-existe	comando não encontrado no PATH nem na raiz: quality.test(comando-que-nao-existe-xyz)
falha	artefatos-ignorados	não cobertos por git check-ignore: thoughts/screen-verify/ .playwright-mcp/
falha	codepaths-existem	não existem no disco: src
falha	jira-campos	jira.enabled com campo vazio: projectKey issueType.task
falha	local-json-ignorado	keelson.local.json está VERSIONADO — segredo no repositório
falha	playwright-flags	nenhum mcpServers.playwright em .mcp.json, escopo do projeto ou global
falha	sensitive-globs	candidato de segredo sem glob que o cubra: config/id_rsa.key
ok	ficha-legivel	keelson.config.json parseado
ok	hooks-executaveis	todos os hooks do plugin têm bit de execução
ok	perfil-resolve	perfis da ficha resolvem em arquivo"
if [ "$st" -eq 1 ] && [ "$got" = "$want" ]; then echo "ok   defeituoso"
else echo "FAIL defeituoso (exit $st)"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/  /'; fail=$((fail + 1)); fi

# ---- hook do plugin sem bit de execução → falha nomeada, exit 1 (4.180) ----
PR2="$TMP/plugin2"
cp -R "$PR" "$PR2"
printf '#!/bin/sh\nexit 0\n' > "$PR2/hooks/quebrado.sh"   # nasce 644, como um Write
total=$((total + 1))
got="$(bash "$SC" "$R" --plugin-root "$PR2" --claude-json "$TMP/nao-existe.json" 2>/dev/null)"; st=$?
case "$got" in
  "falha	hooks-executaveis	hook sem bit de execução (falha silenciosa a cada disparo) — repare: chmod +x em quebrado.sh"*)
    [ "$st" -eq 1 ] && echo "ok   hook-sem-x" || { echo "FAIL hook-sem-x: exit $st"; fail=$((fail + 1)); } ;;
  *) echo "FAIL hook-sem-x:"; printf '%s\n' "$got" | sed -n 1,3p | sed 's/^/  /'; fail=$((fail + 1)) ;;
esac

# ---- ficha ausente → falha nomeada, exit 1 ----
R3="$(mkrepo sem-ficha)"
total=$((total + 1))
got="$(bash "$SC" "$R3" --plugin-root "$PR" 2>/dev/null)"; st=$?
case "$got" in
  falha*ficha-legivel*) [ "$st" -eq 1 ] && echo "ok   sem-ficha" || { echo "FAIL sem-ficha: exit $st"; fail=$((fail + 1)); } ;;
  *) echo "FAIL sem-ficha: [$got]"; fail=$((fail + 1)) ;;
esac

# ---- uso incorreto ----
total=$((total + 1))
bash "$SC" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   sem-arg-exit-2" || { echo "FAIL sem-arg-exit-2"; fail=$((fail + 1)); }

echo "---"
if [ "$fail" -gt 0 ]; then echo "init-selfcheck: $fail de $total casos falharam"; exit 1; fi
echo "init-selfcheck: $total casos verdes"
exit 0
