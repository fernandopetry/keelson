#!/usr/bin/env bash
# run.sh — suíte de regressão do diff-facts.sh (decisão 4.151).
#
# Cada caso monta um repo git sintético (base + branch com mudanças por categoria)
# e compara a saída com a esperada inline. Regras provadas: classificação por bucket
# (producao/teste/documentacao/migracao/config), veredito inerte nos dois sentidos,
# composição com contagem de linhas, pendência de deploy vs INDEX, degradação sem
# ficha (conservadora: não-doc → config, que não é inerte) e o contrato do
# `--identity` (4.377): estável · muda com o conteúdo · ordem da lista indiferente ·
# untracked entra e muda · ausente difere · edição fora da lista não muda · base
# movida muda · base que não resolve e repo sem HEAD degradam para `none` sem erro;
# e o `--guard review|security` (4.378): lista filtrada pela ficha (codePaths ·
# sensitiveGlobs + manifestos), untracked marcado, rename_src, modo worktree sem base,
# `scope none` sem codePaths e identidade igual à do `--identity` sobre a mesma lista;
# 4.379: rename fora do escopo não muda a identidade (origem só de par que toca o
# escopo) e o modo executável entra no manifesto.
#
# Uso: scripts/tests/diff-facts/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
DF="$HERE/../../diff-facts.sh"

[ -f "$DF" ] || { echo "ERRO: diff-facts.sh não encontrado em $DF" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERRO: a suíte exige git" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

newrepo() { # $1 = nome; cria repo com commit base e ecoa o caminho
  r="$TMP/$1"
  mkdir -p "$r"
  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" checkout -qb main; }
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  printf 'base\n' > "$r/README.md"
  git -C "$r" add -A
  git -C "$r" commit -qm base
  printf '%s\n' "$r"
}

assert() { # nome exit-esperado saida-esperada saida-obtida exit-obtido
  name="$1"; wantexit="$2"; want="$3"; got="$4"; st="$5"
  total=$((total + 1))
  if [ "$st" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $st (esperado $wantexit)"
    fail=$((fail + 1)); return
  fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $name: saída divergente"
    printf '  esperado:\n%s\n  obtido:\n%s\n' "$want" "$got" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

bash -n "$DF" || { echo "FAIL bash -n diff-facts.sh"; exit 1; }
echo "ok   bash -n diff-facts.sh"

# --help imprime o cabeçalho inteiro (janela por sentinela, não por número de linha — 4.377)
total=$((total + 1))
helpout="$(bash "$DF" --help 2>&1)"; st=$?
case "$helpout" in
  *"--identity"*"Read-only"*) [ "$st" -eq 0 ] && echo "ok   help-cobre-identity" || { echo "FAIL help-cobre-identity: exit $st"; fail=$((fail + 1)); } ;;
  *) echo "FAIL help-cobre-identity: --help truncado ou sem --identity"; fail=$((fail + 1)) ;;
esac

# ---- repo completo, com ficha ----
R="$(newrepo completo)"
cat > "$R/keelson.config.json" <<'EOF'
{ "docsRoot": "docs", "codePaths": { "backend": ["src"], "frontend": ["resources/js"] } }
EOF
git -C "$R" add -A && git -C "$R" commit -qm ficha
git -C "$R" checkout -qb feat
mkdir -p "$R/src" "$R/tests" "$R/docs/slug" "$R/migrations" "$R/resources/js" "$R/public/img"
printf 'linha1\nlinha2\nlinha3\n' > "$R/src/servico.php"
printf 'teste1\nteste2\n'         > "$R/tests/ServicoTest.php"
printf 'doc\n'                    > "$R/docs/slug/INDEX.md"
printf 'nota\n'                   > "$R/CHANGELOG.md"
printf 'sql\n'                    > "$R/migrations/2026_08_06_add_col.sql"
printf 'js\n'                     > "$R/resources/js/app.js"
printf 'cfg\n'                    > "$R/.env.example"
printf 'png\n'                    > "$R/public/img/logo.png"
git -C "$R" add -A && git -C "$R" commit -qm mudancas

got="$(bash "$DF" --repo "$R" --base main --inert 2>/dev/null)"; st=$?
assert inert-misto 1 "codigo	config	.env.example
inerte	documentacao	CHANGELOG.md
inerte	documentacao	docs/slug/INDEX.md
codigo	migracao	migrations/2026_08_06_add_col.sql
inerte	documentacao	public/img/logo.png
codigo	producao	resources/js/app.js
codigo	producao	src/servico.php
codigo	teste	tests/ServicoTest.php
veredito	nao-inerte	5 de 8 arquivo(s) classificado(s) como codigo pelos codePaths — nao prova que quality.test os exercita; confirme a cobertura antes de citar como prova" "$got" "$st"

got="$(bash "$DF" --repo "$R" --base main --compose 2>/dev/null)"; st=$?
assert compose 0 "arquivo	config	1	0	.env.example
arquivo	documentacao	1	0	CHANGELOG.md
arquivo	documentacao	1	0	docs/slug/INDEX.md
arquivo	migracao	1	0	migrations/2026_08_06_add_col.sql
arquivo	documentacao	1	0	public/img/logo.png
arquivo	producao	1	0	resources/js/app.js
arquivo	producao	3	0	src/servico.php
arquivo	teste	2	0	tests/ServicoTest.php
total	producao	2	4	0
total	teste	1	2	0
total	documentacao	3	3	0
total	migracao	1	1	0
total	config	1	1	0" "$got" "$st"

# deploy-pending: INDEX declara uma migration, cala a outra
mkdir -p "$R/migrations2"
printf 'sql2\n' > "$R/migrations/2026_08_07_add_index.sql"
git -C "$R" add -A && git -C "$R" commit -qm segunda-migration
cat > "$TMP/INDEX-parcial.md" <<'EOF'
## Riscos ativos
Pendência de deploy: aplicar 2026_08_06_add_col.sql antes do código.
EOF
got="$(bash "$DF" --repo "$R" --base main --deploy-pending "$TMP/INDEX-parcial.md" 2>/dev/null)"; st=$?
assert deploy-parcial 1 "declarado	2026_08_06_add_col.sql
pendente	2026_08_07_add_index.sql" "$got" "$st"

cat > "$TMP/INDEX-completo.md" <<'EOF'
## Riscos ativos
Aplicar 2026_08_06_add_col.sql e depois 2026_08_07_add_index.sql.
EOF
got="$(bash "$DF" --repo "$R" --base main --deploy-pending "$TMP/INDEX-completo.md" 2>/dev/null)"; st=$?
assert deploy-completo 0 "declarado	2026_08_06_add_col.sql
declarado	2026_08_07_add_index.sql" "$got" "$st"

# ---- diff só de docs → inerte (exit 0) ----
R2="$(newrepo so-docs)"
cat > "$R2/keelson.config.json" <<'EOF'
{ "docsRoot": "docs", "codePaths": { "backend": ["src"] } }
EOF
git -C "$R2" add -A && git -C "$R2" commit -qm ficha
git -C "$R2" checkout -qb feat
mkdir -p "$R2/docs/slug"
printf 'spec\n' > "$R2/docs/slug/SPEC-001-x.md"
printf 'leia\n' >> "$R2/README.md"
git -C "$R2" add -A && git -C "$R2" commit -qm docs
got="$(bash "$DF" --repo "$R2" --base main --inert 2>/dev/null)"; st=$?
assert inert-so-docs 0 "inerte	documentacao	README.md
inerte	documentacao	docs/slug/SPEC-001-x.md
veredito	inerte	2 arquivo(s), nenhum exercitado pela suite" "$got" "$st"

# ---- sem ficha: degradação conservadora (não-doc → config, não-inerte) ----
R3="$(newrepo sem-ficha)"
git -C "$R3" checkout -qb feat
mkdir -p "$R3/src"
printf 'x\n' > "$R3/src/main.go"
git -C "$R3" add -A && git -C "$R3" commit -qm código
got="$(bash "$DF" --repo "$R3" --base main --inert 2>/dev/null)"; st=$?
assert inert-sem-ficha 1 "codigo	config	src/main.go
veredito	nao-inerte	1 de 1 arquivo(s) classificado(s) como codigo pelos codePaths — nao prova que quality.test os exercita; confirme a cobertura antes de citar como prova" "$got" "$st"

# a degradação é declarada em stderr
total=$((total + 1))
errout="$(bash "$DF" --repo "$R3" --base main --inert 2>&1 >/dev/null)"
case "$errout" in
  *"sem codePaths"*) echo "ok   sem-ficha-declarada" ;;
  *) echo "FAIL sem-ficha-declarada: stderr [$errout]"; fail=$((fail + 1)) ;;
esac

# ---- diff vazio → inerte ----
R4="$(newrepo vazio)"
git -C "$R4" checkout -qb feat
got="$(bash "$DF" --repo "$R4" --base main --inert 2>/dev/null)"; st=$?
assert inert-vazio 0 "veredito	inerte	0 arquivo(s), nenhum exercitado pela suite" "$got" "$st"

# ---- --identity: identidade do diff (decisão 4.377) ----
R5="$(newrepo identidade)"
mkdir -p "$R5/src"
printf 'a\n' > "$R5/src/a.txt"
git -C "$R5" add -A && git -C "$R5" commit -qm arquivo
git -C "$R5" checkout -qb feat
ident() { # $1 base, demais = arquivos (um por linha no stdin do script)
  b="$1"; shift
  printf '%s\n' "$@" | bash "$DF" --repo "$R5" --base "$b" --identity 2>/dev/null
}
same() { total=$((total + 1)); if [ -n "$2" ] && [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: [$2] vs [$3]"; fail=$((fail + 1)); fi; }
difere() { total=$((total + 1)); if [ -n "$2" ] && [ -n "$3" ] && [ "$2" != "$3" ]; then echo "ok   $1"; else echo "FAIL $1: [$2] vs [$3]"; fail=$((fail + 1)); fi; }
hex40() { total=$((total + 1)); case "$2" in *[!0-9a-f]*|'') echo "FAIL $1: não é hash [$2]"; fail=$((fail + 1)) ;; *) if [ ${#2} -eq 40 ]; then echo "ok   $1"; else echo "FAIL $1: tamanho ${#2}"; fail=$((fail + 1)); fi ;; esac; }

h0="$(ident main src/a.txt)"; h0b="$(ident main src/a.txt)"
hex40 identity-e-hash "$h0"
same  identity-estavel "$h0" "$h0b"
printf 'b\n' > "$R5/src/a.txt"; h1="$(ident main src/a.txt)"
difere identity-conteudo-muda "$h0" "$h1"
printf 'c\n' > "$R5/src/novo.txt"
h2="$(ident main src/a.txt src/novo.txt)"; h2r="$(ident main src/novo.txt src/a.txt)"
same  identity-ordem-indiferente "$h2" "$h2r"
difere identity-untracked-entra "$h1" "$h2"
printf 'd\n' > "$R5/src/novo.txt"; h3="$(ident main src/a.txt src/novo.txt)"
difere identity-untracked-alterado "$h2" "$h3"
rm "$R5/src/novo.txt"; h4="$(ident main src/a.txt src/novo.txt)"
difere identity-ausente-difere "$h3" "$h4"
printf 'fora\n' >> "$R5/README.md"; h5="$(ident main src/a.txt src/novo.txt)"
same  identity-fora-da-lista-nao-muda "$h4" "$h5"
h6="$(ident main~1 src/a.txt src/novo.txt)"
difere identity-base-movida-muda "$h5" "$h6"
h7="$(ident nao-existe src/a.txt)"; st=$?
total=$((total + 1)); [ "$st" -eq 0 ] && echo "ok   identity-base-irresoluvel-exit-0" || { echo "FAIL identity-base-irresoluvel-exit-0: exit $st"; fail=$((fail + 1)); }
hex40 identity-base-irresoluvel-hash "$h7"
difere identity-base-none-difere "$h1" "$h7"

# repo sem commit algum: HEAD não resolve → base `none`, conteúdo continua identificado
R6="$TMP/sem-commit"; mkdir -p "$R6/src"
git -C "$R6" init -q
printf 'x\n' > "$R6/src/x.txt"
h8="$(printf 'src/x.txt\n' | bash "$DF" --repo "$R6" --base HEAD --identity 2>/dev/null)"; st=$?
total=$((total + 1)); [ "$st" -eq 0 ] && echo "ok   identity-sem-head-exit-0" || { echo "FAIL identity-sem-head-exit-0: exit $st"; fail=$((fail + 1)); }
hex40 identity-sem-head-hash "$h8"
printf 'y\n' > "$R6/src/x.txt"
h9="$(printf 'src/x.txt\n' | bash "$DF" --repo "$R6" --base HEAD --identity 2>/dev/null)"
difere identity-sem-head-conteudo-muda "$h8" "$h9"

# ---- --guard review|security: escopo + identidade do guard (decisão 4.378) ----
T="$(printf '\t')"
norm_guard() { sed -E "s/^(base|ref)${T}[0-9a-f]{40}$/\1${T}<sha>/; s/^identity${T}[0-9a-f]{40}$/identity${T}<hash>/"; }
R7="$(newrepo guard)"
mkdir -p "$R7/src/auth" "$R7/lib" "$R7/docs"
cat > "$R7/keelson.config.json" <<'EOF'
{ "codePaths": { "backend": ["src"] }, "sensitiveGlobs": ["src/auth/**"] }
EOF
printf 'a\n' > "$R7/src/a.php"; printf 'l\n' > "$R7/src/auth/login.php"; printf 'x\n' > "$R7/lib/x.php"; printf '{}\n' > "$R7/composer.json"
seq 1 40 | sed 's/^/linha /' > "$R7/src/c.php"   # candidato a rename puro (conteúdo intacto)
git -C "$R7" add -A && git -C "$R7" commit -qm base
git -C "$R7" checkout -qb feat
printf 'a2\n' > "$R7/src/a.php"           # código rastreado modificado
printf 'novo\n' > "$R7/src/novo.php"      # código untracked
printf 'l2\n' > "$R7/src/auth/login.php"  # sensível
printf 'x2\n' > "$R7/lib/x.php"           # fora dos codePaths
printf 'd\n' > "$R7/docs/leia.md"         # docs
printf '{"x":1}\n' > "$R7/composer.json"  # manifesto de dependência fora dos globs

got="$(bash "$DF" --repo "$R7" --guard review 2>/dev/null | norm_guard)"; st=$?
assert guard-review 0 "base	<sha>
ref	<sha>
mode	branch
file	src/a.php	tracked
file	src/auth/login.php	tracked
file	src/novo.php	untracked
identity	<hash>" "$got" "$st"

got="$(bash "$DF" --repo "$R7" --guard security 2>/dev/null | norm_guard)"; st=$?
assert guard-security 0 "base	<sha>
ref	<sha>
mode	branch
file	src/auth/login.php	tracked
dep	composer.json
identity	<hash>" "$got" "$st"

# identidade do --guard == --identity sobre a mesma lista e a mesma base
gid="$(bash "$DF" --repo "$R7" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
iid="$(printf 'src/a.php\nsrc/auth/login.php\nsrc/novo.php\n' | bash "$DF" --repo "$R7" --base main --identity 2>/dev/null)"
same guard-identity-igual-ao-identity "$gid" "$iid"

# rename puro: destino na lista, origem em rename_src (arquivo modificado + movido não é
# rename para o git — similaridade abaixo de 50% — e por isso c.php nasce intacto)
git -C "$R7" mv src/c.php src/d.php
got="$(bash "$DF" --repo "$R7" --guard review 2>/dev/null | norm_guard | grep -E '^(file|rename_src)')"; st=$?
assert guard-rename 0 "file	src/a.php	tracked
file	src/auth/login.php	tracked
file	src/d.php	tracked
file	src/novo.php	untracked
rename_src	src/c.php" "$got" "$st"

# sem codePaths → scope none (review); security sem globs ainda vigia manifestos
R8="$(newrepo guard-sem-escopo)"
printf '{ "docsRoot": "docs" }\n' > "$R8/keelson.config.json"
printf '{}\n' > "$R8/package.json"
got="$(bash "$DF" --repo "$R8" --guard review 2>/dev/null)"; st=$?
assert guard-review-scope-none 0 "scope	none" "$got" "$st"
got="$(bash "$DF" --repo "$R8" --guard security 2>/dev/null | norm_guard | grep -E '^(file|dep)')"; st=$?
assert guard-security-so-manifesto 0 "dep	package.json" "$got" "$st"

# sem base (repo sem commit): modo worktree, ref HEAD, untracked, identidade com base none
R9="$TMP/guard-worktree"; mkdir -p "$R9/src"
git -C "$R9" init -q
printf '{ "codePaths": { "backend": ["src"] } }\n' > "$R9/keelson.config.json"
printf 'w\n' > "$R9/src/w.php"
got="$(bash "$DF" --repo "$R9" --guard review 2>/dev/null | norm_guard)"; st=$?
assert guard-worktree 0 "base	none
ref	HEAD
mode	worktree
file	src/w.php	untracked
identity	<hash>" "$got" "$st"

# P2 (4.379): rename fora do escopo não muda a identidade; rename que ENTRA no escopo traz a origem
R10="$(newrepo guard-rename-escopo)"
mkdir -p "$R10/src" "$R10/docs" "$R10/lib"
printf '{ "codePaths": { "backend": ["src"] } }\n' > "$R10/keelson.config.json"
seq 1 40 | sed 's/^/l /' > "$R10/src/a.php"; printf 'doc\n' > "$R10/docs/a.md"; seq 1 40 | sed 's/^/x /' > "$R10/lib/x.php"
git -C "$R10" add -A && git -C "$R10" commit -qm base && git -C "$R10" checkout -qb feat
printf 'value = 1;\n' >> "$R10/src/a.php"
g1="$(bash "$DF" --repo "$R10" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
git -C "$R10" mv docs/a.md docs/b.md
g2="$(bash "$DF" --repo "$R10" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
same guard-rename-fora-do-escopo-nao-muda "$g1" "$g2"
total=$((total + 1))
if bash "$DF" --repo "$R10" --guard review 2>/dev/null | grep -q "^rename_src"; then echo "FAIL guard-rename-fora-sem-rename-src"; fail=$((fail + 1)); else echo "ok   guard-rename-fora-sem-rename-src"; fi
git -C "$R10" mv lib/x.php src/x.php
got="$(bash "$DF" --repo "$R10" --guard review 2>/dev/null | grep -E '^rename_src')"; st=$?
assert guard-rename-entra-no-escopo 0 "rename_src	lib/x.php" "$got" "$st"

# P3 (4.379): chmod +x com bytes iguais muda a identidade (o git registra 100644 → 100755)
R11="$(newrepo guard-modo)"
mkdir -p "$R11/src"
printf '{ "codePaths": { "backend": ["src"] } }\n' > "$R11/keelson.config.json"
seq 1 40 | sed 's/^/l /' > "$R11/src/a.php"
git -C "$R11" add -A && git -C "$R11" commit -qm base && git -C "$R11" checkout -qb feat
printf 'value = 1;\n' >> "$R11/src/a.php"
m1="$(bash "$DF" --repo "$R11" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
chmod +x "$R11/src/a.php"
m2="$(bash "$DF" --repo "$R11" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
difere guard-modo-executavel-muda "$m1" "$m2"
chmod -x "$R11/src/a.php"
m3="$(bash "$DF" --repo "$R11" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
same guard-modo-volta "$m1" "$m3"

total=$((total + 1))
bash "$DF" --repo "$R7" --guard outro >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   guard-escopo-invalido-exit-2"
else echo "FAIL guard-escopo-invalido-exit-2: exit $st"; fail=$((fail + 1)); fi

# ---- uso incorreto ----
total=$((total + 1))
printf 'src/a.txt\n' | bash "$DF" --repo "$R5" --identity >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   identity-sem-base-exit-2"
else echo "FAIL identity-sem-base-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$DF" --repo "$R" --base nao-existe --inert >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   base-invalida-exit-2"
else echo "FAIL base-invalida-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$DF" --repo "$R" --inert >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-base-exit-2"
else echo "FAIL sem-base-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$DF" --repo "$TMP" --base main --inert >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   fora-de-repo-exit-2"
else echo "FAIL fora-de-repo-exit-2: exit $st"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "diff-facts: $fail de $total casos falharam"
  exit 1
fi
echo "diff-facts: $total casos verdes"
exit 0
