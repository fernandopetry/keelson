#!/usr/bin/env bash
# warroom.sh — mecânica do modo warroom (decisão 4.372): janela declarada pelo
# Diretor em que a mudança sai sem gate bloqueante e CADA COMMIT vira dívida de
# verificação registrada em `{docsRoot}/DEBT.md`, artefato durável e commitável.
# A régua (quando ativa, o que sobrevive, como a dívida se cobra) vive em
# docs/_meta/conventions/production-intake-protocol.md ("Warroom"); este script
# cuida só do fato mecânico — marcador, reconciliação a partir do git, fecho.
#
# Uso: warroom.sh <raiz-do-repo> open <motivo…>
#      warroom.sh <raiz-do-repo> status
#      warroom.sh <raiz-do-repo> reconcile
#      warroom.sh <raiz-do-repo> settle <hash> <resolvida|assumida> <nota…>
#      warroom.sh <raiz-do-repo> close
#      warroom.sh <raiz-do-repo> open-debts
#
#   open       cria o marcador `warroom.meta` na CASA DA SESSÃO (session-dir.sh, 4.314;
#              sem id de sessão → thoughts/local/warroom.meta) com inicio, motivo,
#              branch e base (HEAD do momento). Já ativo → ecoa o estado e sai 0
#              (idempotente). Registra evento `marco` no ledger (ledger.sh presente).
#   status     ecoa `ativo` + campos do marcador, ou `inativo`; sempre exit 0.
#   reconcile  a operação que o hook Stop roda a cada turno: lista os commits da
#              branch desde `base` (git log base..HEAD, sem merges) e acrescenta ao
#              DEBT.md uma linha aberta `- [ ]` por commit ainda não listado — hash,
#              data, branch, gates não rodados, arquivos tocados, flag `sensivel: sim`
#              quando algum arquivo casa com `sensitiveGlobs` da ficha (gate 8 é o
#              que sobrevive ao warroom), motivo da janela. Idempotente: a fonte é o
#              git, não a memória de ninguém. Ecoa `novas: N`. Sem marcador → `novas: 0`.
#   settle     fecha a linha do <hash>: `[ ]` → `[x]`, com `fecho: <estado> — <nota>
#              (<data>)`. `resolvida` = os gates rodaram sobre o diff e passaram (ou a
#              correção convergiu); `assumida` = o Diretor assume a dívida, com motivo.
#   close      reconcile final + remove o marcador + evento `marco` de fecho; dívida
#              ainda aberta → evento `pendencia` (é o que o report lê). Ecoa o resumo.
#   open-debts ecoa as linhas abertas do DEBT.md (uma por linha; vazio se nenhuma).
#
# DEBT.md mora em `{docsRoot}/DEBT.md` (docsRoot via ficha.sh, default `docs`). Ele é
# versionado de propósito: dívida que some com a sessão é dívida perdoada.
# Nunca é gate: sem git, sem ficha ou sem marcador o script degrada com aviso e sai 0.
# Exit: 0 ok · 2 uso incorreto. Bash 3.2-compatível, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,42p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

HERE="$(cd "$(dirname "$0")" && pwd)"
SDS="$HERE/session-dir.sh"
LEDGER="$HERE/ledger.sh"
FICHA="$HERE/ficha.sh"

# git do repo do consumidor, nunca herdando variáveis de um hook chamador (4.154)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

# --- casa da sessão → caminho do marcador ---
# resolve_casa [--create]: sem --create, a casa que já existe (ou a legada quando a
# pasta da sessão ainda não nasceu); com --create, a pasta da sessão nasce agora —
# o `open` usa --create para o marcador cair na MESMA casa que o ledger.
resolve_casa() {
  casa="$ROOT/thoughts/local"
  if [ -f "$SDS" ]; then
    d="$(bash "$SDS" "$ROOT" dir "$@" 2>/dev/null)" || d=""
    [ -n "$d" ] && casa="$d"
  fi
  MARKER="$casa/warroom.meta"
}
resolve_casa

# --- DEBT.md ---
droot="docs"
if [ -f "$FICHA" ] && [ -f "$ROOT/keelson.config.json" ]; then
  v="$(bash "$FICHA" "$ROOT" --get docsRoot --default docs 2>/dev/null)" || v=""
  [ -n "$v" ] && droot="${v%/}"
fi
DEBT="$ROOT/$droot/DEBT.md"

agora_iso() { TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z; }
agora_curta() { TZ=America/Sao_Paulo date '+%Y-%m-%d %H:%M'; }

campo() { # $1 = nome → valor do marcador
  [ -f "$MARKER" ] || return 0
  sed -n "s/^$1:[ 	]*//p" "$MARKER" | sed -n 1p
}

ledger_evento() { # tipo corpo…
  [ -f "$LEDGER" ] || return 0
  printf '%s\n' "$2" | bash "$LEDGER" "$ROOT" append "$1" warroom "${3:-warroom}" >/dev/null 2>&1 || true
}

git_ok() { ( cd "$ROOT" && git rev-parse --is-inside-work-tree >/dev/null 2>&1 ); }

# gates da ficha que o warroom deixa de rodar — lista canônica, nomeada pelo número
gates_pulados() {
  lista="1-7 (tests+review)"
  sec="on"; qa="on"
  if [ -f "$ROOT/keelson.config.json" ] && command -v jq >/dev/null 2>&1; then
    sec="$(jq -r 'if .gates.security == false then "off" else "on" end' "$ROOT/keelson.config.json" 2>/dev/null || echo on)"
    qa="$(jq -r 'if .gates.qa == false then "off" else "on" end' "$ROOT/keelson.config.json" 2>/dev/null || echo on)"
  fi
  [ "$sec" = "on" ] && lista="$lista, 8 (security)"
  [ "$qa" = "on" ] && lista="$lista, 9 (qa)"
  printf '%s' "$lista"
}

# glob simples da ficha (mesma família do security-guard): `*` não cruza `/`, `**` cruza
casa_glob() { # padrão arquivo
  pat="$1"; f="$2"
  re="$(printf '%s' "$pat" | sed -e 's/[.[\^$+?(){}|]/\\&/g' -e 's#\*\*/#__DS__#g' -e 's#\*\*#__DS2__#g' -e 's#\*#[^/]*#g' -e 's#__DS__#(.*/)?#g' -e 's#__DS2__#.*#g')"
  printf '%s\n' "$f" | grep -Eq "^${re}$"
}

sensivel() { # arquivos (multilinha) → 0 se algum casa com sensitiveGlobs
  [ -f "$ROOT/keelson.config.json" ] && command -v jq >/dev/null 2>&1 || return 1
  globs="$(jq -r '.sensitiveGlobs[]?' "$ROOT/keelson.config.json" 2>/dev/null || true)"
  [ -n "$globs" ] || return 1
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    while IFS= read -r g; do
      [ -z "$g" ] && continue
      casa_glob "$g" "$f" && return 0
    done <<EOF
$globs
EOF
  done <<EOF
$1
EOF
  return 1
}

debt_header() {
  mkdir -p "$(dirname "$DEBT")"
  [ -f "$DEBT" ] && return 0
  cat > "$DEBT" <<'EOF'
# Dívida de verificação (warroom)

> Gerado por `scripts/warroom.sh` do keelson — não edite as linhas à mão. Cada linha é
> um commit feito com o modo warroom ativo, sem os gates listados. Linha aberta `[ ]`
> é pendência do Diretor: fecha pelo `/keelson:warroom close` (gates sobre o diff
> acumulado) ou por `warroom.sh settle <hash> resolvida|assumida <nota>`.

EOF
}

do_open() {
  motivo="$*"
  [ -n "$motivo" ] || die2 "open exige o <motivo>."
  git_ok || { echo "warroom: fora de repositório git — nada aberto." >&2; exit 0; }
  if [ -f "$MARKER" ]; then
    echo "warroom: já ativo desde $(campo inicio) (motivo: $(campo motivo)) — marcador $MARKER"
    exit 0
  fi
  resolve_casa --create
  mkdir -p "$casa"
  branch="$(cd "$ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo desconhecida)"
  base="$(cd "$ROOT" && git rev-parse HEAD 2>/dev/null || echo "")"
  sess="${KEELSON_SESSAO-${CLAUDE_CODE_SESSION_ID:-desconhecida}}"
  [ -n "$sess" ] || sess="desconhecida"
  cat > "$MARKER" <<EOF
inicio: $(agora_iso)
motivo: $motivo
branch: $branch
base: ${base:-sem-commit}
sessao: $sess
EOF
  ledger_evento marco "warroom ABERTO — motivo: $motivo
branch $branch · base ${base:-sem-commit} · gates não bloqueiam; cada commit vira linha em $droot/DEBT.md"
  echo "warroom: ATIVO — motivo: $motivo · branch $branch · base $(printf '%s' "${base:-sem-commit}" | cut -c1-7)"
  echo "marcador: $MARKER"
  echo "dívida: $droot/DEBT.md (reconciliada a cada turno pelo hook warroom-guard)"
}

do_status() {
  if [ -f "$MARKER" ]; then
    echo "ativo"
    sed 's/^/  /' "$MARKER"
  else
    echo "inativo"
  fi
  if [ -f "$DEBT" ]; then
    n="$(grep -c '^- \[ \]' "$DEBT" 2>/dev/null || true)"
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    echo "dívida aberta: $n linha(s) em $droot/DEBT.md"
  fi
}

do_reconcile() {
  [ -f "$MARKER" ] || { echo "novas: 0"; return 0; }
  git_ok || { echo "novas: 0"; return 0; }
  base="$(campo base)"
  branch="$(campo branch)"
  motivo="$(campo motivo)"
  inicio="$(campo inicio)"
  if [ -z "$base" ] || [ "$base" = "sem-commit" ]; then
    range="HEAD"
  else
    range="$base..HEAD"
  fi
  hashes="$(cd "$ROOT" && git log --no-merges --reverse --format=%H "$range" 2>/dev/null || true)"
  [ -n "$hashes" ] || { echo "novas: 0"; return 0; }
  debt_header
  novas=0
  gates="$(gates_pulados)"
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    h7="$(printf '%s' "$h" | cut -c1-7)"
    grep -q "\`$h7\`" "$DEBT" 2>/dev/null && continue
    data="$(cd "$ROOT" && TZ=America/Sao_Paulo git show -s --format=%cd --date=format-local:'%Y-%m-%d %H:%M' "$h" 2>/dev/null || echo "?")"
    files="$(cd "$ROOT" && git show --pretty=format: --name-only "$h" 2>/dev/null | sed '/^$/d')"
    nf="$(printf '%s\n' "$files" | sed '/^$/d' | wc -l | tr -d ' ')"
    lista="$(printf '%s\n' "$files" | sed '/^$/d' | head -6 | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    [ "$nf" -gt 6 ] && lista="$lista, …"
    flag=""
    sensivel "$files" && flag=" · **sensivel: sim** (gate 8 obrigatório no fecho)"
    printf -- '- [ ] `%s` · %s · branch `%s` · gates não rodados: %s · %s arquivo(s): %s%s · janela: %s (motivo: %s)\n' \
      "$h7" "$data" "$branch" "$gates" "$nf" "$lista" "$flag" "$inicio" "$motivo" >> "$DEBT"
    novas=$((novas + 1))
  done <<EOF
$hashes
EOF
  echo "novas: $novas"
}

do_settle() {
  h="${1:-}"; estado="${2:-}"; shift 2 2>/dev/null || true
  nota="$*"
  [ -n "$h" ] || die2 "settle exige <hash> <resolvida|assumida> <nota>."
  case "$estado" in resolvida|assumida) ;; *) die2 "estado deve ser resolvida ou assumida: $estado" ;; esac
  [ -n "$nota" ] || die2 "settle exige a <nota> (o que rodou, ou por que a dívida é assumida)."
  [ -f "$DEBT" ] || die2 "não há $droot/DEBT.md."
  h7="$(printf '%s' "$h" | cut -c1-7)"
  grep -q "^- \[ \] \`$h7\`" "$DEBT" || die2 "linha aberta com hash $h7 não encontrada em $droot/DEBT.md."
  tmp="$DEBT.tmp.$$"
  awk -v h="$h7" -v st="$estado" -v nota="$nota" -v data="$(agora_curta)" '
    index($0, "- [ ] `" h "`") == 1 { sub(/^- \[ \]/, "- [x]"); print $0 " · fecho: " st " — " nota " (" data ")"; next }
    { print }' "$DEBT" > "$tmp" && mv "$tmp" "$DEBT"
  echo "settle: $h7 → $estado"
}

do_close() {
  if [ ! -f "$MARKER" ]; then
    echo "warroom: inativo — nada a fechar."
  else
    do_reconcile
    motivo="$(campo motivo)"
    rm -f "$MARKER"
    ledger_evento marco "warroom FECHADO — motivo da janela: $motivo
dívida reconciliada em $droot/DEBT.md; gates do diff acumulado devidos no fecho"
    echo "warroom: FECHADO (marcador removido)"
  fi
  abertas="$(do_open_debts)"
  n=0
  [ -n "$abertas" ] && n="$(printf '%s\n' "$abertas" | wc -l | tr -d ' ')"
  if [ "$n" -gt 0 ]; then
    ledger_evento pendencia "dívida warroom aberta: $n linha(s) em $droot/DEBT.md
fecha com settle resolvida (gates rodados) ou assumida (Diretor, com motivo)"
    echo "dívida aberta: $n linha(s) em $droot/DEBT.md"
    printf '%s\n' "$abertas"
  else
    echo "dívida aberta: 0"
  fi
}

do_open_debts() {
  [ -f "$DEBT" ] || return 0
  grep '^- \[ \]' "$DEBT" 2>/dev/null || true
}

case "$ACTION" in
  open)       do_open "$@" ;;
  status)     do_status ;;
  reconcile)  do_reconcile ;;
  settle)     do_settle "$@" ;;
  close)      do_close ;;
  open-debts) do_open_debts ;;
  -h|--help)  usage ;;
  *) die2 "ação desconhecida: $ACTION (open | status | reconcile | settle | close | open-debts)" ;;
esac
exit 0
