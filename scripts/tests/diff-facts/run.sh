#!/usr/bin/env bash
# run.sh — suíte de regressão do diff-facts.sh (decisão 4.151).
#
# Cada caso monta um repo git sintético (base + branch com mudanças por categoria)
# e compara a saída com a esperada inline. Regras provadas: classificação por bucket
# (producao/teste/documentacao/migracao/config), veredito inerte nos dois sentidos,
# composição com contagem de linhas, pendência de deploy vs INDEX, degradação sem
# ficha (conservadora: não-doc → config, que não é inerte).
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

# ---- uso incorreto ----
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
