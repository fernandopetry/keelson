#!/usr/bin/env bash
# run.sh — suíte de regressão do suite-filter-check.sh (decisão 4.429).
#
# Repo sintético com phpunit.xml (suítes Unit/Integration, grupo `skip-migration`
# excluído por padrão) e arquivos de teste com filiações distintas; uma TASK com um
# critério por caso. Regras provadas: `--group X` sobre arquivo sem X acusa só o arquivo
# errado de um `--filter 'A|B'` (a heterogeneidade nasce como dois achados); arquivo em
# grupo excluído citado sem `--group` acusa; `--testsuite` fora da suíte e suíte
# inexistente acusam (a inexistente uma vez por comando); herança de 1 nível, `@group`
# em prosa de docblock (falso-positivo real do 1º acervo), alvo a criar, homônimo que
# satisfaz, comando fora das seções de aresta, `<exclude>` de caminho dentro de
# `<testsuite>` e `--group` com aspa colada NÃO acusam; sem phpunit.xml só o check de
# `--group` roda (INFO declarado); índice e diretório expandem; exit 2 de uso incorreto.
#
# Uso: scripts/tests/suite-filter/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
S="$HERE/../../suite-filter-check.sh"
[ -f "$S" ] || { echo "ERRO: suite-filter-check.sh não encontrado em $S" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0; total=0
ok()  { total=$((total + 1)); echo "ok   $1"; }
bad() { total=$((total + 1)); fail=$((fail + 1)); echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  /'; }
eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$(printf -- '--- esperado ---\n%s\n--- obtido ---\n%s' "$2" "$3")"; fi; }
contem()    { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1: não contém [$3]" "$2"; fi; }
naocontem() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1: contém [$3]" "$2"; else ok "$1"; fi; }
exitis()    { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: exit $3 (esperado $2)"; fi; }
# conta linhas de um check que citam um trecho
conta() { printf '%s\n' "$1" | grep -F -- "$2" | grep -cF -- "$3"; }

# ---------- repo sintético ----------
R="$TMP/repo"; mkdir -p "$R/tests/Unit/Sub" "$R/tests/Integration" "$R/tests/Legacy" "$R/docs/alpha/tasks"
cat > "$R/phpunit.xml" <<'XML'
<?xml version="1.0"?>
<phpunit>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
            <exclude>tests/Unit/Sub/Excluded</exclude>
        </testsuite>
        <testsuite name="Integration">
            <directory suffix="Test.php">./tests/Integration/</directory>
            <file>tests/Legacy/OldTest.php</file>
        </testsuite>
    </testsuites>
    <groups>
        <include>
            <group>fast</group>
        </include>
        <exclude>
            <group>skip-migration</group>
        </exclude>
    </groups>
</phpunit>
XML
php_class() { # $1 caminho · $2 classe · $3 extends · $4 anotação (linhas antes da classe)
  { printf '<?php\nnamespace Tests;\n%s\nfinal class %s extends %s\n{\n    public function testX(): void {}\n}\n' "$4" "$2" "$3"; } > "$1"
}
php_class "$R/tests/Unit/AlphaTest.php" AlphaTest TestCase ""
php_class "$R/tests/Unit/BetaTest.php" BetaTest TestCase '/**
 * @group skip-migration
 */'
php_class "$R/tests/Integration/GammaTest.php" GammaTest TestCase "#[Group('skip-migration')]"
php_class "$R/tests/Unit/BetaBase.php" BetaBase TestCase '/** @group skip-migration */'
php_class "$R/tests/Unit/DeltaTest.php" DeltaTest BetaBase ""
# prosa de docblock cita @group sem ser anotação (falso-positivo real do 1º acervo)
php_class "$R/tests/Integration/ProsaTest.php" ProsaTest TestCase '/**
 * Nasce SEM `@group skip-migration`: SQLite em memória.
 */'
# homônimos: Unit sem grupo, Sub com grupo (union: basta um satisfazer)
php_class "$R/tests/Unit/HomoTest.php" HomoTest TestCase ""
php_class "$R/tests/Unit/Sub/HomoTest.php" HomoTest TestCase "#[\\PHPUnit\\Framework\\Attributes\\Group('skip-migration')]"
php_class "$R/tests/Legacy/OldTest.php" OldTest TestCase ""

T="$R/docs/alpha/tasks/TASK-001-001-caso.md"
cat > "$T" <<'MD'
# TASK-001-001: caso

**Pertence a**: PLAN-001

## Escopo

### Inclui
- comando fora das seções de aresta: `phpunit --group skip-migration --filter AlphaTest` (ignorado)

## Critérios de pronto

- [ ] (a) heterogêneo: `docker compose exec app bash -c "cd /var/www && php vendor/bin/phpunit --configuration phpunit.xml --group skip-migration --filter 'AlphaTest|BetaTest'"` → `OK (N tests)`
- [ ] (b) grupo excluído sem --group: `php vendor/bin/phpunit tests/Unit/BetaTest.php` → `OK (N tests)`
- [ ] (c) fora da suíte: `phpunit --testsuite Unit --filter GammaTest` → ok
- [ ] (d) suíte inexistente com dois alvos: `phpunit --testsuite Nope --filter 'AlphaTest|DeltaTest'` → ok
- [ ] (e) herança 1 nível: `phpunit --group skip-migration --filter DeltaTest` → ok
- [ ] (f) alvo a criar: `phpunit --group skip-migration --filter NovoTest` → ok
- [ ] (g) prosa não é anotação: `phpunit --testsuite Integration --filter ProsaTest` **sem** `--group` → ok
- [ ] (h) homônimo satisfaz: `phpunit --group skip-migration --filter HomoTest` → ok
- [ ] (i) alvo do item, não do comando: rodar `phpunit --group skip-migration` sobre `AlphaTest` e `BetaTest`
- [ ] (j) aspa colada e filtro partido: `bash -c "phpunit --filter
  'GammaTest|
  BetaTest' --group skip-migration"` → ok
- [ ] (k) arquivo da suíte por `<file>`: `phpunit --testsuite Integration --filter OldTest` → ok
- [ ] (l) forma com igual: `phpunit --group=skip-migration --filter=AlphaTest` → ok

## Roteiro do gate 9 (fixado ANTES do código)

- (m) roteiro também conta: `phpunit --group fast --filter AlphaTest`

## Riscos específicos

- fora das seções: `phpunit --group skip-migration --filter AlphaTest` (ignorado)
MD
printf '# TASK-001-INDEX\n' > "$R/docs/alpha/tasks/TASK-001-INDEX.md"
printf '# TASK-001-002: limpa\n\n## Critérios de pronto\n\n- [ ] `phpunit --group skip-migration --filter BetaTest` → ok\n' > "$R/docs/alpha/tasks/TASK-001-002-limpa.md"

# ---------- 1. TASK única: achados esperados ----------
out="$(bash "$S" "$R" "$T" 2>"$TMP/err")"; st=$?
exitis "1. exit 0 com WARNINGs" 0 "$st"
[ -s "$TMP/err" ] && bad "1. stderr vazio" "$(cat "$TMP/err")" || ok "1. stderr vazio"
eq "1. (a) heterogêneo acusa só AlphaTest" "1" "$(conta "$out" ":12)" "tests/Unit/AlphaTest.php")"
eq "1. (a) BetaTest tem o grupo → silêncio" "0" "$(conta "$out" ":12)" "tests/Unit/BetaTest.php")"
eq "1. (a) um achado por filiação divergente, nunca por comando" "1" "$(conta "$out" ":12)" "WARNING")"
contem "1. (a) cita TASK:linha" "$out" "(docs/alpha/tasks/TASK-001-001-caso.md:12)"
contem "1. (b) grupo excluído sem --group" "$out" "suite-filter-alvo-em-grupo-excluido	\`tests/Unit/BetaTest.php\` carrega \`@group skip-migration\`"
contem "1. (c) --testsuite fora da suíte" "$out" "suite-filter-testsuite-sem-filiacao	\`--testsuite Unit\` mira \`tests/Integration/GammaTest.php\`"
eq "1. (d) suíte inexistente: uma vez por comando, não por alvo" "1" "$(printf '%s\n' "$out" | grep -c 'suite-filter-testsuite-inexistente	`--testsuite Nope`')"
eq "1. (d) DeltaTest herda grupo excluído e o comando não o passa → acusa" "1" "$(conta "$out" ":15)" "alvo-em-grupo-excluido	\`tests/Unit/DeltaTest.php\`")"
eq "1. (c) GammaTest também está em grupo excluído sem --group → acusa" "1" "$(conta "$out" ":14)" "alvo-em-grupo-excluido")"
eq "1. (e) herança de 1 nível → silêncio" "0" "$(conta "$out" "grupo-sem-filiacao" "DeltaTest")"
naocontem "1. (f) alvo a criar → silêncio" "$out" "NovoTest"
eq "1. (g) @group em prosa não é anotação → sem falso-positivo" "0" "$(conta "$out" "WARNING" "ProsaTest")"
eq "1. (h) homônimo que satisfaz → silêncio" "0" "$(conta "$out" "WARNING" "HomoTest")"
eq "1. (i) alvos do item quando o comando não os traz: acusa AlphaTest" "1" "$(conta "$out" ":20)" "tests/Unit/AlphaTest.php")"
eq "1. (j) aspa colada + filtro partido: sem achado (os dois têm o grupo)" "0" "$(conta "$out" ":21)" "WARNING")"
eq "1. (k) arquivo por <file> pertence à suíte" "0" "$(conta "$out" "WARNING" "OldTest")"
eq "1. (l) forma --group=/--filter= acusa AlphaTest" "1" "$(conta "$out" ":25)" "tests/Unit/AlphaTest.php")"
eq "1. (m) Roteiro do gate 9 entra: --group fast sobre AlphaTest" "1" "$(conta "$out" ":29)" "--group fast")"
eq "1. fora das seções de aresta → nada" "0" "$(printf '%s\n' "$out" | grep -c ':8)\|:33)')"
contem "1. resumo declara a criar" "$out" "INFO	suite-filter-resumo	"
naocontem "1. exclude de caminho dentro de testsuite não vira grupo excluído" "$out" "@group tests/Unit/Sub/Excluded"
naocontem "1. grupo de <include> não é excluído" "$out" "@group fast\`, excluído"
eq "1. sem outras classes de achado" "" "$(printf '%s\n' "$out" | grep -v '^WARNING	suite-filter-\(grupo-sem-filiacao\|alvo-em-grupo-excluido\|testsuite-sem-filiacao\|testsuite-inexistente\)\|^INFO	suite-filter-resumo')"

# ---------- 2. índice e diretório expandem; TASK limpa cala ----------
o1="$(bash "$S" "$R" "$R/docs/alpha/tasks/TASK-001-INDEX.md" 2>/dev/null)"
o2="$(bash "$S" "$R" "$R/docs/alpha/tasks" 2>/dev/null)"
eq "2. índice ≡ diretório" "$o1" "$o2"
contem "2. expande para a TASK com achados" "$o1" "TASK-001-001-caso.md"
naocontem "2. TASK limpa não aparece" "$o1" "TASK-001-002"
o3="$(bash "$S" "$R" "$R/docs/alpha/tasks/TASK-001-002-limpa.md" 2>/dev/null)"
eq "2. TASK limpa → só o resumo" "INFO	suite-filter-resumo	1 comandos com filtro · 1 alvos conferidos · 0 a criar (n/a)" "$o3"

# ---------- 3. sem phpunit.xml: só --group ----------
R2="$TMP/semconf"; mkdir -p "$R2/tests/Unit"; cp -R "$R/tests/Unit/AlphaTest.php" "$R/tests/Unit/BetaTest.php" "$R2/tests/Unit/"
mkdir -p "$R2/docs/alpha/tasks"; cp "$T" "$R2/docs/alpha/tasks/"
out="$(bash "$S" "$R2" "$R2/docs/alpha/tasks" 2>/dev/null)"; st=$?
exitis "3. exit 0" 0 "$st"
contem "3. INFO config ausente" "$out" "INFO	suite-filter-config-ausente"
contem "3. --group ainda roda" "$out" "suite-filter-grupo-sem-filiacao	\`--group skip-migration\` mira \`tests/Unit/AlphaTest.php\`"
naocontem "3. grupo excluído n/a sem config" "$out" "alvo-em-grupo-excluido"
naocontem "3. testsuite n/a sem config" "$out" "testsuite-"

# ---------- 4. uso incorreto ----------
bash "$S" >/dev/null 2>&1; exitis "4. sem args → 2" 2 "$?"
bash "$S" "$R" >/dev/null 2>&1; exitis "4. sem alvo → 2" 2 "$?"
bash "$S" "$TMP/nao-existe" "$T" >/dev/null 2>&1; exitis "4. raiz inexistente → 2" 2 "$?"
bash "$S" "$R" "$TMP/nao-existe.md" >/dev/null 2>&1; exitis "4. alvo inexistente → 2" 2 "$?"

echo "suite-filter: $((total - fail))/$total verdes"
[ "$fail" -eq 0 ]
