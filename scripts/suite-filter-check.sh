#!/usr/bin/env bash
# suite-filter-check.sh — fato mecânico da filiação real dos alvos de um comando de suíte
# citado em TASK (decisão 4.429 — 4ª reincidência da família 4.93/4.368/4.428).
#
# Abre os arquivos de teste REAIS do projeto que um critério de TASK nomeia junto de um
# comando PHPUnit e confere se o filtro do comando bate com a filiação do arquivo:
#   - `--group X` mira arquivo que não carrega `@group X` / `#[Group('X')]` (nem o herda
#     da classe pai, 1 nível) → o comando roda ZERO testes desse arquivo;
#   - arquivo com grupo que a config do runner EXCLUI por padrão, citado por comando sem
#     `--group <esse grupo>` → idem (a 4.368 via só o artefato; aqui o arquivo é aberto);
#   - `--testsuite S` mira arquivo fora dos diretórios/arquivos que a config dá à suíte S,
#     ou suíte que a config não declara.
# Read-only; a saída é FATO — validator (`task-validator`, Etapa 3) e gerador
# (`/keelson:tasks`, Etapa 5) a citam; a calibração continua deles. Cobre PHPUnit
# (`--group`/`--testsuite`/`--filter`; config `phpunit.xml[.dist]`/`phpunit.dist.xml`);
# outro runner é silêncio, nunca achado (generalização por ocorrência de campo — 4.215).
# Contrato: este cabeçalho (molde do `e2e-coverage.sh`/`check-refs.sh`).
#
# Uso: scripts/suite-filter-check.sh <raiz-do-projeto> <TASK-*.md | TASK-MMM-INDEX.md | dir>...
#   <raiz-do-projeto>  onde vive a config do runner e os caminhos de teste (phpunit.xml)
#   alvo               TASK, índice (expande para as TASK-*.md do mesmo diretório) ou diretório
#
# Só as seções `## Critérios de pronto` e `## Roteiro do gate 9` entram (as seções de
# aresta, graph-contract §2); um item = bullet de topo + continuações. Cada trecho em
# crase com `phpunit`/`--group`/`--testsuite`/`--filter` é um comando; os alvos são os
# nomes do `--filter` (`A|B` → A, B), os caminhos `*.php` do próprio comando ou, sem
# nenhum dos dois, os `*Test`/`*Test.php` em crase do item. Nome que resolve para mais
# de um arquivo (classes homônimas) é julgado pela UNIÃO: só acusa quando nenhum deles
# satisfaz o filtro. Alvo que não existe no repo é arquivo que a TASK vai criar → n/a
# (contado no resumo, nunca achado).
#
# Saída (stdout), uma linha por achado: SEVERIDADE<TAB>check<TAB>detalhe (TASK:linha)
#   WARNING  suite-filter-grupo-sem-filiacao      --group X sobre arquivo sem o grupo X
#   WARNING  suite-filter-alvo-em-grupo-excluido  arquivo em grupo excluído por padrão, comando sem --group dele
#   WARNING  suite-filter-testsuite-sem-filiacao  --testsuite S sobre arquivo fora da suíte S
#   WARNING  suite-filter-testsuite-inexistente   --testsuite S que a config não declara
#   INFO     suite-filter-config-ausente          sem phpunit.xml na raiz: só o check de --group roda
#   INFO     suite-filter-resumo                  comandos · alvos conferidos · a criar (n/a)
#
# Exit: 0 rodou (achado não muda o exit — a classe é WARNING) · 2 uso incorreto.
# Falso-positivo num critério legítimo é o pior defeito desta camada (graph-contract §1):
# só a ANOTAÇÃO ancorada no início da linha conta como grupo (`@group X` citado em prosa
# de comentário não é anotação — caso real do 1º acervo medido); na dúvida o script cala —
# herança além de 1 nível, grupo vindo de trait ou de config de subdiretório ficam para
# a leitura do validator. Bash 3.2 + awk POSIX.

set -u
LC_ALL=C
export LC_ALL

usage() { echo "uso: $0 <raiz-do-projeto> <TASK-*.md | TASK-MMM-INDEX.md | dir>..." >&2; exit 2; }
[ $# -ge 2 ] || usage
ROOT="${1%/}"; shift
[ -d "$ROOT" ] || { echo "ERRO: raiz não existe: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

# ---------- alvos: TASK-*.md (índice/diretório expandem) ----------
: > "$TMP/tasks"
add_dir() { for f in "$1"/TASK-*.md; do [ -f "$f" ] || continue; case "$f" in *-INDEX.md) continue ;; esac; echo "$f" >> "$TMP/tasks"; done; }
for a in "$@"; do
  if [ -d "$a" ]; then add_dir "${a%/}"
  elif [ -f "$a" ]; then case "$a" in *-INDEX.md) add_dir "$(dirname "$a")" ;; *) echo "$a" >> "$TMP/tasks" ;; esac
  else echo "ERRO: alvo não existe: $a" >&2; exit 2
  fi
done
sort -u "$TMP/tasks" -o "$TMP/tasks"

# ---------- config do runner ----------
CONF=""
for c in phpunit.xml phpunit.xml.dist phpunit.dist.xml; do [ -f "$ROOT/$c" ] && { CONF="$ROOT/$c"; break; }; done
# suites: `S<TAB>caminho` (diretório ou arquivo, relativo à raiz); excl: grupos excluídos
# por padrão (`<groups><exclude><group>`). `<exclude>` dentro de `<testsuite>` exclui
# caminho, nunca grupo; abertura e fecho na mesma linha contam na mesma linha.
: > "$TMP/suites"; : > "$TMP/excl"
if [ -n "$CONF" ]; then
  awk '
    function txt(s) { gsub(/<[^>]*>/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); sub(/^\.\//, "", s); sub(/\/$/, "", s); return s }
    {
      line = $0
      if (line ~ /<testsuite[ \t]/) { s = line; sub(/.*name="/, "", s); sub(/".*/, "", s); suite = s }
      if (line ~ /<groups[ \t>]/) ingroups = 1
      if (line ~ /<exclude[ \t>]/) ex = 1
      if (suite != "" && !ex && line ~ /<(directory|file)[ >]/) { p = txt(line); if (p != "") print suite "\t" p }
      if (ingroups && ex && line ~ /<group[ >]/) { g = txt(line); if (g != "") print "EXCL\t" g }
      if (line ~ /<\/exclude>/) ex = 0
      if (line ~ /<\/groups>/) ingroups = 0
      if (line ~ /<\/testsuite>/) suite = ""
    }
  ' "$CONF" > "$TMP/conf"
  grep -v '^EXCL	' "$TMP/conf" > "$TMP/suites" || true
  sed -n 's/^EXCL	//p' "$TMP/conf" | sort -u > "$TMP/excl"
else
  printf 'INFO\tsuite-filter-config-ausente\tsem phpunit.xml[.dist] em %s — só o check de --group roda; --testsuite e grupo excluído ficam n/a\n' "$ROOT"
fi

# diretórios onde procurar classe por nome: os das suítes; sem config, tests/ e test/
: > "$TMP/dirs"
if [ -s "$TMP/suites" ]; then cut -f2 "$TMP/suites" | sort -u | while IFS= read -r p; do [ -d "$ROOT/$p" ] && echo "$ROOT/$p"; done > "$TMP/dirs"; fi
[ -s "$TMP/dirs" ] || { for d in tests test; do [ -d "$ROOT/$d" ] && echo "$ROOT/$d"; done > "$TMP/dirs"; }

# ---------- helpers ----------
rel() { case "$1" in "$ROOT"/*) printf '%s' "${1#"$ROOT"/}" ;; *) printf '%s' "$1" ;; esac; }
# grupos declarados num arquivo, um por linha — só a ANOTAÇÃO ancorada no início da
# linha (docblock ` * @group X` · atributo `#[Group('X')]`, com ou sem namespace)
groups_of() {
  grep -E "^[[:space:]]*(/\*\*)?[[:space:]]*\*?[[:space:]]*@group[[:space:]]+[A-Za-z0-9_.-]+([[:space:]]|$)" "$1" 2>/dev/null \
    | sed -E 's/.*@group[[:space:]]+([A-Za-z0-9_.-]+).*/\1/'
  grep -E "^[[:space:]]*#\[(\\\\?[A-Za-z0-9_\\\\]+\\\\)?Group\(['\"][A-Za-z0-9_.-]+['\"]\)" "$1" 2>/dev/null \
    | sed -E "s/.*Group\(['\"]([A-Za-z0-9_.-]+)['\"]\).*/\1/"
}
# resolve classe → arquivo(s) `<Nome>.php` nos diretórios de teste (vendor/node_modules fora)
find_class() { # $1 = nome
  [ -s "$TMP/dirs" ] || return 0
  while IFS= read -r d; do
    find "$d" -type f -name "$1.php" -not -path '*/vendor/*' -not -path '*/node_modules/*' 2>/dev/null
  done < "$TMP/dirs" | sort -u
}
# grupos do arquivo + da classe pai (1 nível, resolvida por nome nos diretórios de teste)
groups_inherited() { # $1 = arquivo
  groups_of "$1"
  parent="$(grep -oE "extends[[:space:]]+\\\\?[A-Za-z0-9_\\\\]+" "$1" 2>/dev/null | head -1 | sed -E 's/^extends[[:space:]]+//; s/.*\\//')"
  [ -n "$parent" ] || return 0
  pf="$(find_class "$parent" | head -1)"
  [ -n "$pf" ] && groups_of "$pf"
  return 0
}
in_suite() { # $1 = suite · $2 = caminho relativo → "yes" quando pertence
  grep "^$1	" "$TMP/suites" | cut -f2 | while IFS= read -r p; do
    case "$2" in "$p"|"$p"/*) echo yes; break ;; esac
  done
}
suite_declared() { grep -q "^$1	" "$TMP/suites"; }
warn() { printf 'WARNING\t%s\t%s (%s:%s)\n' "$1" "$2" "$3" "$4"; }

: > "$TMP/count"

# ---------- por TASK ----------
while IFS= read -r task; do
  [ -f "$task" ] || continue
  # 1. itens das seções de aresta: linha `<n><TAB><texto do item>` (continuações unidas)
  awk '
    function flush() { if (buf != "") print start "\t" buf; buf = ""; start = 0 }
    /^## / { flush(); sec = ($0 ~ /^## Crit.*rios de pronto/ || $0 ~ /^## Roteiro do gate 9/) ? 1 : 0; next }
    !sec { next }
    /^[-*] / || /^[0-9]+\. / { flush(); start = NR; buf = $0; next }
    /^[ \t]*$/ { next }
    buf != "" { line = $0; gsub(/^[ \t]+/, " ", line); buf = buf line; next }
    END { flush() }
  ' "$task" > "$TMP/items"

  # 2. por item: comandos (trechos em crase) e alvos do item — campo vazio vira `-`
  #    (tabs consecutivos colapsam no `read` do bash)
  #    CMD<TAB>linha<TAB>grupos<TAB>suites<TAB>alvos,   ·   ITEM<TAB>linha<TAB>alvos,
  awk -F'\t' '
    function addl(list, v) { if (v == "") return list; if (index("," list ",", "," v ",") > 0) return list; return (list == "" ? v : list "," v) }
    function unq(v) { gsub(/^["'"'"']+|["'"'"']+$/, "", v); return v }
    function names_from_filter(f, list,   n, parts, i, p) {
      f = unq(f); gsub(/\^|\$|\\b|\(|\)/, "", f)
      n = split(f, parts, "|")
      for (i = 1; i <= n; i++) { p = parts[i]; sub(/::.*/, "", p); sub(/.*\\/, "", p); gsub(/[ \t]/, "", p); if (p ~ /^[A-Za-z_][A-Za-z0-9_]*$/) list = addl(list, p) }
      return list
    }
    # valor entre aspas que a quebra de linha partiu (A|B| C): junta ate a aspa de fecho
    function quoted(ws, n, i,   v, q) {
      v = ws[i]; q = substr(v, 1, 1)
      if ((q == "'"'"'" || q == "\"") && (length(v) < 2 || substr(v, length(v), 1) != q)) {
        while (i < n) { i++; v = v ws[i]; if (substr(ws[i], length(ws[i]), 1) == q) break }
      }
      return v
    }
    function scan_cmd(c, line,   g, s, t, w, n, ws, i, v) {
      g = ""; s = ""; t = ""
      n = split(c, ws, /[ \t]+/)
      for (i = 1; i <= n; i++) {
        w = ws[i]
        if (w ~ /^--group=/) { v = w; sub(/^--group=/, "", v); g = addl(g, unq(v)) }
        else if (w == "--group" && i < n) { g = addl(g, unq(ws[i + 1])) }
        else if (w ~ /^--testsuite=/) { v = w; sub(/^--testsuite=/, "", v); s = addl(s, unq(v)) }
        else if (w == "--testsuite" && i < n) { s = addl(s, unq(ws[i + 1])) }
        else if (w ~ /^--filter=/) { v = w; sub(/^--filter=/, "", v); t = names_from_filter(v, t) }
        else if (w == "--filter" && i < n) { t = names_from_filter(quoted(ws, n, i + 1), t) }
        else if (w ~ /\.php["'"'"']?$/ && w !~ /^-/) { v = unq(w); if (v !~ /vendor\/bin\/phpunit/) t = addl(t, v) }
      }
      gsub(/,/, " ", g); gsub(/,/, " ", s)  # `--group a,b` → dois grupos
      if (g == "") g = "-"; if (s == "") s = "-"; if (t == "") t = "-"
      # comando sem filtro mas com alvo também entra: é o caso do arquivo em grupo
      # excluído citado sem `--group` (4.368)
      if (g != "-" || s != "-" || t != "-") print "CMD\t" line "\t" g "\t" s "\t" t
    }
    {
      line = $1; text = $2; item_t = ""; ncmd = 0
      n = split(text, seg, "`")
      for (i = 2; i <= n; i += 2) {           # trechos em crase
        c = seg[i]
        if (c ~ /phpunit|--group|--testsuite|--filter/) { scan_cmd(c, line); ncmd++ }
        else if (c ~ /^[A-Za-z_][A-Za-z0-9_]*Test$/) item_t = addl(item_t, c)
        else if (c ~ /^[A-Za-z0-9_.\/-]+Test\.php$/) item_t = addl(item_t, c)
      }
      if (ncmd == 0 && text ~ /--group|--testsuite/) scan_cmd(text, line)
      print "ITEM\t" line "\t" (item_t == "" ? "-" : item_t)
    }
  ' "$TMP/items" > "$TMP/cmds"

  trel="$(rel "$task")"
  grep '^CMD	' "$TMP/cmds" | while IFS='	' read -r _ line groups suites targets; do
    [ "$groups" = "-" ] && groups=""; [ "$suites" = "-" ] && suites=""; [ "$targets" = "-" ] && targets=""
    [ -n "$targets" ] || targets="$(grep "^ITEM	$line	" "$TMP/cmds" | cut -f3 | grep -v '^-$')"
    echo "cmd" >> "$TMP/count"
    # (C1) --testsuite S que a config não declara — uma vez por comando
    if [ -n "$CONF" ]; then
      for s in $suites; do
        suite_declared "$s" || warn suite-filter-testsuite-inexistente "\`--testsuite $s\` não existe na config do runner ($(rel "$CONF"))" "$trel" "$line"
      done
    fi
    [ -n "$targets" ] || continue
    printf '%s\n' "$targets" | tr ',' '\n' | while IFS= read -r tgt; do
      [ -n "$tgt" ] || continue
      : > "$TMP/files"
      case "$tgt" in
        *.php) f="$ROOT/${tgt#./}"; [ -f "$f" ] && echo "$f" > "$TMP/files" ;;
        *) find_class "$tgt" > "$TMP/files" ;;
      esac
      if [ ! -s "$TMP/files" ]; then echo "new" >> "$TMP/count"; continue; fi
      echo "ok" >> "$TMP/count"
      nf="$(wc -l < "$TMP/files" | tr -d ' ')"
      # união dos grupos dos arquivos resolvidos (homônimos: basta um satisfazer)
      : > "$TMP/fg_all"
      while IFS= read -r f; do groups_inherited "$f" >> "$TMP/fg_all"; done < "$TMP/files"
      sort -u "$TMP/fg_all" -o "$TMP/fg_all"
      fdesc="$(rel "$(head -1 "$TMP/files")")"; [ "$nf" -gt 1 ] && fdesc="$fdesc (+$((nf - 1)) homônimo(s))"
      # (A) --group X sem X em nenhum arquivo resolvido
      for g in $groups; do
        grep -qx "$g" "$TMP/fg_all" || warn suite-filter-grupo-sem-filiacao "\`--group $g\` mira \`$fdesc\`, que não carrega \`@group $g\` (nem herda da classe pai) — roda 0 testes deste arquivo com \"N > 0\" verde" "$trel" "$line"
      done
      # (B) todo arquivo resolvido carrega grupo excluído por padrão que o comando não passa
      if [ -s "$TMP/excl" ]; then
        allx=1; exname=""
        while IFS= read -r f; do
          groups_inherited "$f" | sort -u > "$TMP/fg"
          hit=""
          while IFS= read -r ex; do
            grep -qx "$ex" "$TMP/fg" || continue
            passed=""; for g in $groups; do [ "$g" = "$ex" ] && passed=1; done
            [ -n "$passed" ] || { hit="$ex"; break; }
          done < "$TMP/excl"
          [ -n "$hit" ] && exname="$hit" || allx=""
        done < "$TMP/files"
        [ -n "$allx" ] && warn suite-filter-alvo-em-grupo-excluido "\`$fdesc\` carrega \`@group $exname\`, excluído por padrão na config do runner, e o comando não passa \`--group $exname\` — roda 0 testes deste arquivo" "$trel" "$line"
      fi
      # (C2) --testsuite S declarada: algum arquivo resolvido está dentro dela?
      if [ -n "$CONF" ]; then
        for s in $suites; do
          suite_declared "$s" || continue
          inside=""
          while IFS= read -r f; do [ -n "$(in_suite "$s" "$(rel "$f")")" ] && inside=1; done < "$TMP/files"
          [ -n "$inside" ] || warn suite-filter-testsuite-sem-filiacao "\`--testsuite $s\` mira \`$fdesc\`, que está fora dos caminhos da suíte $s na config — roda 0 testes deste arquivo" "$trel" "$line"
        done
      fi
    done
  done
done < "$TMP/tasks"

n_cmd="$(grep -c '^cmd$' "$TMP/count")"; n_ok="$(grep -c '^ok$' "$TMP/count")"; n_new="$(grep -c '^new$' "$TMP/count")"
printf 'INFO\tsuite-filter-resumo\t%s comandos com filtro · %s alvos conferidos · %s a criar (n/a)\n' "$n_cmd" "$n_ok" "$n_new"
exit 0
