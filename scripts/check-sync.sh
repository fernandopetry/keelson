#!/usr/bin/env bash
# check-sync.sh — sincronização mecânica de comandos e agents (decisão 4.147).
#
# O que a doutrina exige (CLAUDE.md, "Ao mudar comando ou doutrina") e este script prova:
#   Comandos (commands/*.md):
#     - toda linha existe na tabela Commands do README.md (`| \`/keelson:<nome>\` |`)
#     - toda linha `/keelson:<x>` do README tem commands/<x>.md OU skills/<x>/ (skill)
#     - humano-only (`disable-model-invocation: true`) ⇔ marcador ` †` na linha do README
#     - humano-only citado na nota do bloco (templates/CLAUDE.keelson-block.md)
#     - AVISO: comando sem heading `### … \`/keelson:<nome>\`` no method-guide.md
#       (carência conhecida — não bloqueia; comando novo não deve nascer com ela)
#   Agents (agents/*.md):
#     - `name:` do frontmatter == nome do arquivo
#     - heading `# Subagent: <nome>` presente
#     - linha na tabela §5 do method-guide (`| \`<nome>\` |`)
#     - linha da tabela §5 sem agents/<nome>.md correspondente
#     - AVISO: comando/skill que despacha o agent e não aparece na `description:` dele
#       (`/keelson:<cmd>` ou `:<cmd>`; decisão 4.483) — regra "a description declara todos
#       os invocadores"; AVISO até a rodada limpa provar zero falso-positivo
#
# Limite honesto: o comentário de `agents/` no README é prosa com reticências —
# fica com o humano; §2/§3 do decisions.md idem (convenção de nomes é juízo).
#
# Uso: check-sync.sh [--root <dir>]   (default: raiz do repo via git)
# Exit: 0 tudo certo (AVISOs não falham) · 1 violações · 2 uso incorreto.
# Bash 3.2-compatível, POSIX grep/sed/awk, read-only.

set -u
LC_ALL=C
export LC_ALL

ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) shift; [ $# -gt 0 ] || { echo "ERRO: --root exige um caminho." >&2; exit 2; }; ROOT="$1" ;;
    -h|--help) sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || { echo "ERRO: fora de um repo git e sem --root." >&2; exit 2; }
fi
cd "$ROOT" || { echo "ERRO: não consegui entrar em $ROOT" >&2; exit 2; }

README="README.md"
GUIDE="docs/_meta/method-guide.md"
BLOCK="templates/CLAUDE.keelson-block.md"

[ -d commands ] || { echo "ERRO: commands/ não existe em $ROOT" >&2; exit 2; }
[ -d agents ]   || { echo "ERRO: agents/ não existe em $ROOT" >&2; exit 2; }
[ -f "$README" ] || { echo "ERRO: $README não existe em $ROOT" >&2; exit 2; }
[ -f "$GUIDE" ]  || { echo "ERRO: $GUIDE não existe em $ROOT" >&2; exit 2; }

fails=0
warns=0
fail() { echo "FALHA: $*"; fails=$((fails + 1)); }
warn() { echo "AVISO: $*"; warns=$((warns + 1)); }
ok()   { echo "ok    $*"; }

# frontmatter = do primeiro '---' ao seguinte (mesma extração do check-agents.sh)
frontmatter() { awk 'NR==1 && $0=="---" {infm=1; next} infm && $0=="---" {exit} infm {print}' "$1"; }

# ---------- Comandos: arquivo → README / † / bloco / method-guide ----------
cmd_ok=1
for f in commands/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .md)"

  row="$(grep -E "^\| \`/keelson:${name}\`( †)? \|" "$README" | head -1)"
  if [ -z "$row" ]; then
    fail "commands/${name}.md sem linha na tabela Commands do README.md"
    cmd_ok=0
  fi

  human=0
  frontmatter "$f" | grep -qE '^disable-model-invocation:[[:space:]]*true' && human=1

  if [ -n "$row" ]; then
    case "$row" in
      "| \`/keelson:${name}\` † |"*)
        [ "$human" -eq 1 ] || { fail "README marca /keelson:${name} com † mas o comando não tem disable-model-invocation"; cmd_ok=0; } ;;
      *)
        [ "$human" -eq 0 ] || { fail "/keelson:${name} é humano-only (disable-model-invocation) mas a linha do README não tem o marcador †"; cmd_ok=0; } ;;
    esac
  fi

  if [ "$human" -eq 1 ] && [ -f "$BLOCK" ]; then
    grep -q "/keelson:${name}" "$BLOCK" \
      || { fail "/keelson:${name} é humano-only mas não aparece na nota do bloco ($BLOCK)"; cmd_ok=0; }
  fi

  grep -qE "^###.*\`/keelson:${name}\`" "$GUIDE" \
    || warn "commands/${name}.md sem heading \`/keelson:${name}\` no method-guide (§3.x)"
done
[ "$cmd_ok" -eq 1 ] && ok "todo commands/*.md sincronizado com README (linha, †, nota do bloco)"

# ---------- Comandos: README → arquivo (ou skill homônima) ----------
rev_ok=1
for name in $(grep -E '^\| `/keelson:[a-z0-9-]+`' "$README" \
                | sed -E 's/^\| `\/keelson:([a-z0-9-]+)`.*/\1/' | sort -u); do
  if [ ! -f "commands/${name}.md" ] && [ ! -d "skills/${name}" ]; then
    fail "README lista /keelson:${name} mas não existe commands/${name}.md nem skills/${name}/"
    rev_ok=0
  fi
done
[ "$rev_ok" -eq 1 ] && ok "toda linha /keelson:* do README tem comando ou skill correspondente"

# ---------- Agents: arquivo → name:/heading/tabela §5 ----------
ag_ok=1
for f in agents/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .md)"

  fmname="$(frontmatter "$f" | grep -E '^name:' | head -1 | sed -E 's/^name:[[:space:]]*//')"
  [ "$fmname" = "$name" ] \
    || { fail "agents/${name}.md com frontmatter name: '${fmname}' ≠ nome do arquivo"; ag_ok=0; }

  grep -qE "^# Subagent: ${name}\$" "$f" \
    || { fail "agents/${name}.md sem heading '# Subagent: ${name}'"; ag_ok=0; }

  grep -qE "^\| \`${name}\` \|" "$GUIDE" \
    || { fail "agents/${name}.md sem linha na tabela §5 do method-guide"; ag_ok=0; }
done
[ "$ag_ok" -eq 1 ] && ok "todo agents/*.md sincronizado (name:, heading, tabela §5)"

# ---------- Agents: tabela §5 → arquivo ----------
tab_ok=1
for name in $(awk '/^## 5/{s=1; next} s && /^## /{exit} s' "$GUIDE" \
                | grep -E '^\| `[a-z0-9-]+` \|' \
                | sed -E 's/^\| `([a-z0-9-]+)`.*/\1/' | sort -u); do
  [ -f "agents/${name}.md" ] \
    || { fail "tabela §5 do method-guide lista \`${name}\` mas não existe agents/${name}.md"; tab_ok=0; }
done
[ "$tab_ok" -eq 1 ] && ok "toda linha da tabela §5 tem agents/*.md correspondente"

# ---------- Agents: comando que despacha → description do agent (AVISO, 4.483) ----------
# Despacho = verbo de despacho (despach*/invoc*/invoqu*/deleg*/spawn*/acion*/via/agent/
# subagente) com no máximo uma janela curta e nenhum outro `código` entre ele e o
# `agent`, sem negação logo antes do verbo. Menção solta ("lista canônica na description do
# `x`") não é despacho. Declarar = `/keelson:<cmd>` ou `:<cmd>` em qualquer ponto da
# description; o nome puro só vale depois de "Invocad" (cláusula de invocadores).
# Na dúvida o extrator não acusa: falso-negativo é aceito, falso-positivo não.
AGENT_NAMES="$(for f in agents/*.md; do [ -f "$f" ] && basename "$f" .md; done | tr '\n' ',')"
DISPATCHERS="$(ls commands/*.md skills/*/SKILL.md 2>/dev/null)"
TAB="$(printf '\t')"
pairs=""
if [ -n "$AGENT_NAMES" ] && [ -n "$DISPATCHERS" ]; then
  # shellcheck disable=SC2086
  pairs="$(awk -v agl="$AGENT_NAMES" '
    BEGIN { na = split(agl, ag, ",") }
    {
      n = split(FILENAME, seg, "/"); inv = seg[n]; sub(/\.md$/, "", inv)
      if (inv == "SKILL") inv = seg[n - 1]
      l = tolower($0); gsub(/invocador/, "", l); gsub(/\*/, "", l)
      for (i = 1; i <= na; i++) {
        if (ag[i] == "" || (ag[i] SUBSEP inv) in seen) continue
        tok = "`" ag[i] "`"; off = 0; rest = l
        while ((p = index(rest, tok)) > 0) {
          at = off + p; st = at - 60; if (st < 1) st = 1
          pre = substr(l, st, at - st)
          while (match(pre, /(;|\. )/)) pre = substr(pre, RSTART + RLENGTH)
          if (match(pre, /(^|[^a-z])((despach|invoc|invoqu|deleg|spawn|acion)[a-z]*|via|agent|subagente|subagents)([^a-z`][^`]*)?$/)) {
            neg = substr(pre, RSTART > 12 ? RSTART - 12 : 1)
            if (neg !~ /(^|[^a-z])(nunca|jamais|sem|dispens[a-z]*)([^a-z]|$)/ && neg !~ /n(ã|Ã)o /) {
              seen[ag[i] SUBSEP inv] = 1
              print ag[i] "\t" inv "\t" FILENAME ":" FNR
              break
            }
          }
          off = at + length(tok) - 1; rest = substr(l, off + 1)
        }
      }
    }' $DISPATCHERS)"
fi
inv_ok=1
while IFS="$TAB" read -r a c where; do
  [ -n "$a" ] || continue
  desc="$(frontmatter "agents/${a}.md" | grep -E '^description:' | head -1 | sed -E 's/^description:[[:space:]]*//')"
  [ -n "$desc" ] || continue
  printf '%s' "$desc" | grep -qE "(/keelson|[^A-Za-z0-9_]|^):${c}([^a-z0-9-]|\$)" && continue
  case "$desc" in
    *Invocad*)
      clause="${desc#*Invocad}"
      printf '%s' "$clause" | grep -qE "(^|[^A-Za-z0-9:_/-])${c}([^A-Za-z0-9-]|\$)" && continue ;;
  esac
  warn "agents/${a}.md não declara \`/keelson:${c}\` na description, mas ${where} despacha o agent"
  inv_ok=0
done <<EOF
$pairs
EOF
[ "$inv_ok" -eq 1 ] && ok "toda description de agent declara os comandos que o despacham"

echo ""
if [ "$fails" -gt 0 ]; then
  echo "check-sync: $fails violação(ões), $warns aviso(s)."
  exit 1
fi
if [ "$warns" -gt 0 ]; then
  echo "check-sync: tudo certo ($warns aviso(s) — carência conhecida, não bloqueia)."
else
  echo "check-sync: tudo certo."
fi
exit 0
