#!/usr/bin/env bash
# run.sh — suíte de regressão do lessons.sh (decisão 4.376).
#
# Fixture `acervo`: leitura dupla — 5 arquivos em guidelines/project/lessons/ (ativa com
# paths+tags · ativa só tags · em-observacao sem paths · revogada com absorvida_em ·
# arquivo SEM frontmatter) + lessons.md legado (2 blocos, 1 tombstone em Revogadas).
# Fixture `vazio`: projeto sem acervo. Regras provadas: contagem por origem, recorte
# inclusivo (sem paths = sempre; glob `**`; tag), estado default ativa+em-observacao,
# frontmatter ilegível → WARNING + incluída (nunca ausente), show por id/heading/trecho
# com exit 1 quando não há, index derivado, projeto sem acervo sai limpo.
#
# Uso: scripts/tests/lessons/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LS="$HERE/../../lessons.sh"
FIX="$HERE/fixtures"

[ -f "$LS" ] || { echo "ERRO: lessons.sh não encontrado em $LS" >&2; exit 1; }

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }
caso()  { total=$((total + 1)); }

bash -n "$LS" || { echo "FAIL bash -n lessons.sh"; exit 1; }
echo "ok   bash -n lessons.sh"

A="$FIX/acervo"
V="$FIX/vazio"

# --- list ---
caso; out="$(bash "$LS" "$A" list --estado todas 2>/dev/null)"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" = "8" ]; then ok "list todas = 8 (5 dir + 2 legado + 1 tombstone)"; else falha "list todas: $n"; fi

caso; out="$(bash "$LS" "$A" list 2>/dev/null)"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" = "6" ]; then ok "list default exclui revogadas = 6"; else falha "list default: $n"; fi

caso; if printf '%s\n' "$out" | grep -q "^migration-sem-rollback	ativa	Backend	\[Backend\] Migration sem rollback	guidelines/project/lessons.md"; then
  ok "legado: id = slug do heading, estado lido do bloco"; else falha "legado id/estado"; fi

caso; if printf '%s\n' "$out" | grep -q "^toggle-de-tema-pelo-gesto-real	ativa	"; then
  ok "legado sem campos de ciclo de vida → ativa (retrofit conservador)"; else falha "legado sem campos"; fi

caso; if bash "$LS" "$A" list --estado revogada 2>/dev/null | grep -q "^cache-de-view-antigo	revogada	Frontend	.*	scripts/lint-views.sh (check view-cache)$"; then
  ok "absorvida_em aparece na 6ª coluna"; else falha "absorvida_em"; fi

caso; if bash "$LS" "$A" list --estado revogada 2>/dev/null | grep -q "^query-builder-legado	revogada	Backend	"; then
  ok "tombstone de Revogadas conta como revogada"; else falha "tombstone"; fi

# --- WARNING de parse (stderr), lição segue no acervo ---
caso; err="$(bash "$LS" "$A" list 2>&1 >/dev/null)"
if printf '%s\n' "$err" | grep -q "^WARNING nao-parseavel guidelines/project/lessons/sem-frontmatter.md"; then
  ok "sem frontmatter → WARNING nao-parseavel"; else falha "warning parse: [$err]"; fi
caso; if printf '%s\n' "$out" | grep -q "^sem-frontmatter	ativa	Infra	"; then
  ok "sem frontmatter → incluída como ativa"; else falha "sem frontmatter incluída"; fi

# --- match ---
caso; m="$(bash "$LS" "$A" match --paths src/Domain/User.php 2>/dev/null)"
h="$(printf '%s\n' "$m" | head -1)"
if [ "$h" = "# lessons.sh match: acervo=8 recorte=5 (path=1 tag=0 sempre=4) excluidas=3 legado=3" ]; then
  ok "match por path: cabeçalho contável"; else falha "match cabeçalho: [$h]"; fi
caso; if printf '%s\n' "$m" | grep -q "^---8<--- id=repositorio-sem-escopo-de-tenant estado=ativa via=path"; then
  ok "glob ** casa src/Domain/User.php"; else falha "glob **"; fi
caso; if ! printf '%s\n' "$m" | grep -q "id=prova-de-seguranca-sem-grupo"; then
  ok "lição com paths que não casam fica fora"; else falha "paths não casam"; fi
caso; if printf '%s\n' "$m" | grep -q "id=nome-de-branch-sem-acento estado=em-observacao via=sempre" \
   && printf '%s\n' "$m" | grep -q "id=migration-sem-rollback estado=ativa via=sempre" \
   && printf '%s\n' "$m" | grep -q "id=sem-frontmatter estado=ativa via=sempre"; then
  ok "sem paths (dir, legado, sem frontmatter) → sempre-incluídas"; else falha "sempre-incluídas"; fi
caso; if ! printf '%s\n' "$m" | grep -q "id=cache-de-view-antigo"; then
  ok "revogada fora do recorte default"; else falha "revogada no recorte"; fi
caso; if printf '%s\n' "$m" | grep -q "^\*\*Solução:\*\* todo método que toca a tabela escopada"; then
  ok "match imprime a lição integral"; else falha "conteúdo integral"; fi

caso; m2="$(bash "$LS" "$A" match --paths src/Infra/Repository/UserRepository.php 2>/dev/null | head -1)"
if [ "$m2" = "# lessons.sh match: acervo=8 recorte=5 (path=1 tag=0 sempre=4) excluidas=3 legado=3" ]; then
  ok "glob simples *.php casa"; else falha "glob simples: [$m2]"; fi

caso; m3="$(bash "$LS" "$A" match --paths docs/README.md 2>/dev/null | head -1)"
if [ "$m3" = "# lessons.sh match: acervo=8 recorte=4 (path=0 tag=0 sempre=4) excluidas=4 legado=3" ]; then
  ok "path estranho → só as sempre-incluídas"; else falha "path estranho: [$m3]"; fi

caso; m4="$(bash "$LS" "$A" match --paths docs/README.md --tags seguranca 2>/dev/null)"
if printf '%s\n' "$m4" | head -1 | grep -q "recorte=6 (path=0 tag=2 sempre=4)" \
   && printf '%s\n' "$m4" | grep -q "id=prova-de-seguranca-sem-grupo estado=ativa via=tag"; then
  ok "tag inclui lição de classe sem path casando"; else falha "tag: [$(printf '%s\n' "$m4" | head -1)]"; fi

caso; m5="$(printf 'src/Domain/A.php\ntests/Unit/X.php\n' | bash "$LS" "$A" match --paths-file - 2>/dev/null | head -1)"
if [ "$m5" = "# lessons.sh match: acervo=8 recorte=6 (path=2 tag=0 sempre=4) excluidas=2 legado=3" ]; then
  ok "--paths-file - lê stdin (git diff --name-only)"; else falha "paths-file: [$m5]"; fi

caso; m6="$(bash "$LS" "$A" match --paths src/Domain/A.php --estado ativa 2>/dev/null)"
if printf '%s\n' "$m6" | head -1 | grep -q "recorte=4 (path=1 tag=0 sempre=3) excluidas=4" \
   && ! printf '%s\n' "$m6" | grep -q "id=nome-de-branch-sem-acento"; then
  ok "--estado ativa exclui em-observacao"; else falha "estado ativa: [$(printf '%s\n' "$m6" | head -1)]"; fi

caso; m7="$(bash "$LS" "$A" match --paths src/Domain/A.php --estado todas 2>/dev/null | head -1)"
if [ "$m7" = "# lessons.sh match: acervo=8 recorte=6 (path=1 tag=0 sempre=5) excluidas=2 legado=3" ]; then
  ok "--estado todas inclui revogadas e tombstone"; else falha "estado todas: [$m7]"; fi

caso; m8="$(bash "$LS" "$A" match 2>/dev/null | head -1)"
if [ "$m8" = "# lessons.sh match: acervo=8 recorte=4 (path=0 tag=0 sempre=4) excluidas=4 legado=3" ]; then
  ok "match sem filtro → só sempre-incluídas (nunca recorte vazio por engano)"; else falha "match sem filtro: [$m8]"; fi

# --- show ---
caso; s="$(bash "$LS" "$A" show prova-de-seguranca-sem-grupo 2>/dev/null)"
if printf '%s\n' "$s" | head -1 | grep -q "^# id=prova-de-seguranca-sem-grupo estado=ativa origem=guidelines/project/lessons/prova-de-seguranca-sem-grupo.md" \
   && printf '%s\n' "$s" | grep -q "^## \[Testes\] Prova de segurança"; then
  ok "show por id"; else falha "show id"; fi
caso; s2="$(bash "$LS" "$A" show "[Backend] Migration sem rollback" 2>/dev/null | head -1)"
if [ "$s2" = "# id=migration-sem-rollback estado=ativa origem=guidelines/project/lessons.md" ]; then
  ok "show por heading (legado, com [Área])"; else falha "show heading: [$s2]"; fi
caso; s3="$(bash "$LS" "$A" show "gesto REAL" 2>/dev/null | head -1)"
if [ "$s3" = "# id=toggle-de-tema-pelo-gesto-real estado=ativa origem=guidelines/project/lessons.md" ]; then
  ok "show por trecho do heading (case-insensitive)"; else falha "show trecho: [$s3]"; fi
caso; if bash "$LS" "$A" show nao-existe >/dev/null 2>&1; then falha "show inexistente exit 0"; else
  rc=$?; if [ "$rc" = "1" ]; then ok "show inexistente → exit 1"; else falha "show inexistente rc=$rc"; fi; fi

# --- index ---
caso; ix="$(bash "$LS" "$A" index 2>/dev/null)"
if printf '%s\n' "$ix" | head -1 | grep -q "^| id | estado |" \
   && [ "$(printf '%s\n' "$ix" | grep -Ec '^\| [a-z0-9-]+ \| (ativa|em-observacao) \|')" = "6" ]; then
  ok "index: tabela derivada com as 6 não-revogadas"; else falha "index"; fi

# --- projeto sem acervo ---
caso; e="$(bash "$LS" "$V" match --paths src/x.php 2>&1)"; rc=$?
if [ "$rc" = "0" ] && [ "$e" = "# lessons.sh match: acervo=0 recorte=0 (path=0 tag=0 sempre=0) excluidas=0 legado=0" ]; then
  ok "sem acervo → exit 0, cabeçalho zerado, sem ruído"; else falha "vazio: rc=$rc [$e]"; fi
caso; if [ -z "$(bash "$LS" "$V" list 2>&1)" ]; then ok "sem acervo → list vazio"; else falha "vazio list"; fi

# --- read-only e uso ---
caso; before="$(find "$A" -type f | LC_ALL=C sort | xargs cat | cksum)"
bash "$LS" "$A" match --paths src/Domain/A.php >/dev/null 2>&1
bash "$LS" "$A" show migration-sem-rollback >/dev/null 2>&1
after="$(find "$A" -type f | LC_ALL=C sort | xargs cat | cksum)"
if [ "$before" = "$after" ]; then ok "read-only: acervo intocado"; else falha "acervo alterado"; fi
caso; if bash "$LS" "$A" 2>/dev/null; then falha "sem subcomando exit 0"; else
  rc=$?; if [ "$rc" = "2" ]; then ok "uso incorreto → exit 2"; else falha "uso rc=$rc"; fi; fi
caso; if bash "$LS" "$A/nao-existe" list 2>/dev/null; then falha "raiz inexistente exit 0"; else
  rc=$?; if [ "$rc" = "2" ]; then ok "raiz inexistente → exit 2"; else falha "raiz rc=$rc"; fi; fi

echo
echo "lessons: $((total - fail))/$total ok"
[ "$fail" -eq 0 ] || exit 1
exit 0
