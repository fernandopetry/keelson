#!/usr/bin/env bash
# pause.sh — marcas de pausa e retomada do ciclo, commitáveis e cross-máquina
# (decisão 4.382). Escritor e leitor ÚNICO das linhas `- pausa:` / `- retomada:` da
# `## Cronologia` do BRIEF (contrato: docs/_meta/conventions/index-contract.md — as
# duas classes de linha são a exceção declarada à regra "telemetria é cauda da linha
# da etapa"). O QUANDO pausar é do /keelson:pause (ponto seguro) e o QUANDO retomar
# é do /keelson:continue; aqui vive a mecânica: timestamp medido, identidade da
# sessão/máquina, piso derivado do git, agregação — nada nasce de memória (4.151/4.156).
#
# Uso: pause.sh <raiz> mark-pause  <slug> --ponto <texto> [--motivo <texto>]
#                                         [--brief <caminho>] [--ts <iso>] [--host <nome>]
#      pause.sh <raiz> mark-resume <slug> [--brief <caminho>] [--ts <iso>] [--host <nome>]
#                                         [--since <iso> [--since-label <texto>]]
#      pause.sh <raiz> report <caminho-do-BRIEF | slug>
#      pause.sh <raiz> resolve-brief <slug>
#
#   mark-pause    anexa à `## Cronologia` do BRIEF ativo do slug a linha
#                 `- pausa: <ts> · sessão <sid8>@<host> · ponto: <ponto> · motivo: <motivo>`
#                 (motivo omitido quando ausente). BRIEF sem a seção ganha `## Cronologia`
#                 no fim do arquivo (aditivo — caso do brief avulso, declarado em stderr).
#                 Ecoa `brief <caminho>` e `linha <linha gravada>`. Pausa já aberta (última
#                 `- pausa:` sem `- retomada:` posterior) → aviso em stderr e nova linha
#                 mesmo assim (o fato é que houve novo pedido; o report conta as abertas).
#   mark-resume   anexa `- retomada: <ts> · sessão <sid8>@<host> · parado desde <iso>
#                 (marcada | piso: último commit <sha7>) · <H>h<MM>min`. "Desde" = a
#                 última `- pausa:` sem retomada (marcada); sem pausa aberta, o PISO:
#                 --since explícito (testes) ou o último commit alcançável de HEAD
#                 (`git log -1 --format=%cI`), rotulado — nunca o instante real da queda
#                 da sessão, que ninguém mediu. Sem git legível → `parado desde —` e
#                 sem duração (lacuna declarada). Ecoa `brief` e `linha`.
#   report        lê a Cronologia e agrega (TSV, uma pausa por linha, ordenadas):
#                   pausa   <ts-desde|—>  <ts-retomada|sem-retomada>  <min|-> <marcada|piso|aberta>
#                   pausas  <N>  parado  <min>  <H>h<MM>min  <k> marcadas  <j> piso  <a> abertas
#                   cauda   pausas: <N> · parado ~<H>h<MM>min (<k> marcadas, <j> piso)[ · <a> sem retomada marcada]
#                 `marcada` = par pausa→retomada; `piso` = retomada sem pausa anterior (a
#                 duração é a da própria linha); `aberta` = pausa sem retomada (fora da soma,
#                 contada). Sem linha nenhuma → saída vazia, exit 0: telemetria — medida ou
#                 omitida, nunca estimada. A cauda é a linha `Duração` do report
#                 (report-contract.md); `parado` explica parte da parede, jamais entra na
#                 comparação com a faixa do estimator (4.325/4.346).
#   resolve-brief ecoa o BRIEF ATIVO do slug: em <docsRoot>/<slug>/briefs/, o BRIEF-*.md
#                 (épico excluído) de maior número cujo `**Status**:` é `Emitido` (formal)
#                 ou `Aberto` (avulso); docsRoot via ficha.sh (sem ficha: `docs`).
#
#   --ts     timestamp ISO da marca (testes); sem ele, medido com TZ=America/Sao_Paulo.
#   --host   nome da máquina (testes); sem ele, `hostname -s`. Identidade da sessão:
#            KEELSON_SESSAO quando definida, senão CLAUDE_CODE_SESSION_ID; <sid8> = 8
#            primeiros alfanuméricos. Sem id e/ou sem host, o campo `sessão` degrada
#            (só o que se sabe; nada dos dois → campo omitido) — nunca aborta a marca.
#
# Formatos ISO aceitos na leitura: YYYY-MM-DDTHH:MM:SS±HHMM ou ±HH:MM (normalizado para
# ±HHMM, como o cycle-clock). Linha da Cronologia que não parseia é ignorada com
# `WARNING nao-parseavel` em stderr — nunca número inventado.
#
# Exit: 0 ok · 2 uso incorreto · 3 degradado com causa nomeada em stderr (sem BRIEF
#       ativo, BRIEF ilegível) — o chamador declara. Read-only fora do BRIEF alvo.
# Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
die3() { echo "pause: degradado — $*" >&2; exit 3; }
usage() { sed -n '2,/^# Bash 3.2-compat/p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT="${1:-}"
[ -n "$ROOT" ] || { usage >&2; exit 2; }
case "$ROOT" in -h|--help) usage; exit 0 ;; esac
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
shift
ACTION="${1:-}"
[ -n "$ACTION" ] || { usage >&2; exit 2; }
shift

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA="$HERE/ficha.sh"

# --- utilitários ---------------------------------------------------------------
ISO_RE='^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9][0-9][0-9]$'
norma() { printf '%s' "$1" | sed 's/\([+-][0-9][0-9]\):\([0-9][0-9]\)$/\1\2/'; }
valida_iso() { printf '%s' "$1" | grep -Eq "$ISO_RE"; }
agora() { TZ=America/Sao_Paulo date +%Y-%m-%dT%H:%M:%S%z; }

# epoch <iso> → segundos desde 1970 (awk puro, mesmo cálculo do cycle-clock.sh)
epoch() {
  printf '%s\n' "$1" | awk '
  function d2(s, i) { return substr(s, i, 2) + 0 }
  { iso = $0
    y = substr(iso, 1, 4) + 0; m = d2(iso, 6); d = d2(iso, 9)
    H = d2(iso, 12); Mi = d2(iso, 15); S = d2(iso, 18)
    sign = substr(iso, 20, 1); off = d2(iso, 21) * 3600 + d2(iso, 23) * 60
    if (sign == "-") off = -off
    yy = y - (m <= 2 ? 1 : 0)
    era = int((yy >= 0 ? yy : yy - 399) / 400)
    yoe = yy - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    days = era * 146097 + doe - 719468
    print days * 86400 + H * 3600 + Mi * 60 + S - off }'
}
hum() { printf '%dh%02dmin' "$(( $1 / 60 ))" "$(( $1 % 60 ))"; }

# identidade da sessão/máquina para o campo `sessão`
campo_sessao() { # $1 = host explícito ("" → medido)
  if [ "${KEELSON_SESSAO+definida}" = "definida" ]; then sid="$KEELSON_SESSAO"; else sid="${CLAUDE_CODE_SESSION_ID:-}"; fi
  [ "$sid" = "desconhecida" ] && sid=""
  sid8="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9' | cut -c1-8)"
  host="$1"
  if [ -z "$host" ]; then host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"; fi
  host="$(printf '%s' "$host" | tr -d '[:space:]')"
  if [ -n "$sid8" ] && [ -n "$host" ]; then printf 'sessão %s@%s' "$sid8" "$host"
  elif [ -n "$sid8" ]; then printf 'sessão %s' "$sid8"
  elif [ -n "$host" ]; then printf 'host %s' "$host"
  else printf '%s' ""; fi
}

# docsRoot da ficha (sem ficha/ilegível → docs)
docs_root() {
  dr=""
  if [ -f "$FICHA" ]; then dr="$(bash "$FICHA" "$ROOT" --get docsRoot --default docs 2>/dev/null || true)"; fi
  [ -n "$dr" ] || dr="docs"
  printf '%s' "$dr"
}

# BRIEF ativo do slug (ver cabeçalho) → caminho relativo à raiz; vazio se nenhum
resolve_brief() { # $1 = slug
  dir="$ROOT/$(docs_root)/$1/briefs"
  [ -d "$dir" ] || return 0
  found=""
  for f in "$dir"/BRIEF-*.md; do   # glob já vem ordenado; épico (id por data) fica fora
    [ -f "$f" ] || continue
    case "$f" in *-epic.md) continue ;; esac
    st="$(sed -n 's/^\*\*Status\*\*:[ 	]*//p' "$f" | sed -n 1p | sed 's/[ 	]*$//')"
    case "$st" in Emitido|Aberto) found="$f" ;; esac
  done
  [ -n "$found" ] && printf '%s' "${found#"$ROOT"/}"
}

# última linha `- pausa:` sem `- retomada:` posterior na Cronologia → ISO da pausa aberta
pausa_aberta() { # $1 = brief
  awk '
    /^## Cronologia[[:space:]]*$/ { sec = 1; next }
    sec && /^## / { sec = 0 }
    sec && /^- pausa:/ { open = $0 }
    sec && /^- retomada:/ { open = "" }
    END { print open }' "$1" | sed -n 's/^- pausa:[ 	]*\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9]:\{0,1\}[0-9][0-9]\).*/\1/p'
}

# anexa uma linha ao fim da `## Cronologia` (antes do próximo heading); cria a seção se faltar
anexa_cronologia() { # $1 = brief · $2 = linha
  f="$1"
  if ! grep -q '^## Cronologia[[:space:]]*$' "$f"; then
    # aditivo: arquivo termina em newline, seção nova no fim
    [ -s "$f" ] && [ "$(tail -c 1 "$f" | od -An -c | tr -d ' ')" != '\n' ] && printf '\n' >> "$f"
    printf '\n## Cronologia\n%s\n' "$2" >> "$f"
    echo "pause: aviso — BRIEF sem '## Cronologia'; seção criada no fim do arquivo (aditivo, 4.382)." >&2
    return 0
  fi
  tmp="$f.tmp.$$"
  LINHA="$2" awk '
    BEGIN { sec = 0; done = 0; blanks = 0 }
    /^## Cronologia[[:space:]]*$/ && !done { print; sec = 1; next }
    sec && /^## / { print ENVIRON["LINHA"]; print ""; sec = 0; done = 1; print; next }
    sec && /^[[:space:]]*$/ { blanks++; next }
    sec { while (blanks > 0) { print ""; blanks-- }; print; next }
    { print }
    END { if (sec && !done) print ENVIRON["LINHA"] }' "$f" > "$tmp" || { rm -f "$tmp"; die2 "não consegui escrever $f"; }
  mv "$tmp" "$f" || die2 "não consegui atualizar $f"
}

# --- parse de opções comuns ----------------------------------------------------
SLUG=""; BRIEF=""; TS=""; HOST=""; PONTO=""; MOTIVO=""; SINCE=""; SINCE_LABEL=""
case "$ACTION" in
  mark-pause|mark-resume|resolve-brief)
    SLUG="${1:-}"; [ -n "$SLUG" ] || die2 "$ACTION exige o <slug>."; shift
    case "$SLUG" in */*|*" "*) die2 "slug inválido: $SLUG" ;; esac ;;
  report)
    ALVO="${1:-}"; [ -n "$ALVO" ] || die2 "report exige o <caminho-do-BRIEF | slug>."; shift ;;
  *) die2 "ação desconhecida: $ACTION (mark-pause | mark-resume | report | resolve-brief)" ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) shift; [ $# -gt 0 ] || die2 "--brief exige um caminho."; BRIEF="$1" ;;
    --ts) shift; [ $# -gt 0 ] || die2 "--ts exige um ISO 8601."; TS="$(norma "$1")"; valida_iso "$TS" || die2 "--ts fora do formato YYYY-MM-DDTHH:MM:SS±HHMM: $1" ;;
    --host) shift; [ $# -gt 0 ] || die2 "--host exige um nome."; HOST="$1" ;;
    --ponto) shift; [ $# -gt 0 ] || die2 "--ponto exige um texto."; PONTO="$1" ;;
    --motivo) shift; [ $# -gt 0 ] || die2 "--motivo exige um texto."; MOTIVO="$1" ;;
    --since) shift; [ $# -gt 0 ] || die2 "--since exige um ISO 8601."; SINCE="$(norma "$1")"; valida_iso "$SINCE" || die2 "--since fora do formato: $1" ;;
    --since-label) shift; [ $# -gt 0 ] || die2 "--since-label exige um texto."; SINCE_LABEL="$1" ;;
    *) die2 "opção desconhecida: $1" ;;
  esac
  shift
done
case "$PONTO$MOTIVO" in *"
"*) die2 "--ponto/--motivo são de uma linha." ;; esac

# resolve o BRIEF alvo (explícito ou ativo do slug) → $BRIEF relativo, $BF absoluto
alvo_brief() {
  if [ -z "$BRIEF" ]; then
    BRIEF="$(resolve_brief "$SLUG")"
    [ -n "$BRIEF" ] || die3 "nenhum BRIEF ativo (Status Emitido|Aberto) em $(docs_root)/$SLUG/briefs/ — marca não gravada; a pausa vale só por-clone (run-state + ledger)."
  fi
  case "$BRIEF" in /*) BF="$BRIEF" ;; *) BF="$ROOT/$BRIEF" ;; esac
  [ -f "$BF" ] || die3 "BRIEF ilegível: $BRIEF"
}

case "$ACTION" in
  resolve-brief)
    b="$(resolve_brief "$SLUG")"
    [ -n "$b" ] || die3 "nenhum BRIEF ativo (Status Emitido|Aberto) em $(docs_root)/$SLUG/briefs/."
    printf '%s\n' "$b"; exit 0 ;;

  mark-pause)
    [ -n "$PONTO" ] || die2 "mark-pause exige --ponto <texto> (o ponto seguro em que parou)."
    alvo_brief
    [ -n "$TS" ] || TS="$(agora)"
    aberta="$(pausa_aberta "$BF")"
    [ -n "$aberta" ] && echo "pause: aviso — já há pausa aberta em $aberta sem retomada marcada; nova pausa registrada mesmo assim (o report conta as abertas)." >&2
    sess="$(campo_sessao "$HOST")"
    linha="- pausa: $TS"
    [ -n "$sess" ] && linha="$linha · $sess"
    linha="$linha · ponto: $PONTO"
    [ -n "$MOTIVO" ] && linha="$linha · motivo: $MOTIVO"
    anexa_cronologia "$BF" "$linha"
    printf 'brief\t%s\nlinha\t%s\n' "$BRIEF" "$linha"; exit 0 ;;

  mark-resume)
    alvo_brief
    [ -n "$TS" ] || TS="$(agora)"
    desde="$(pausa_aberta "$BF")"
    if [ -n "$desde" ]; then
      desde="$(norma "$desde")"; rotulo="marcada"
    elif [ -n "$SINCE" ]; then
      desde="$SINCE"; rotulo="piso: ${SINCE_LABEL:-declarado}"
    else
      gi="$(cd "$ROOT" 2>/dev/null && git log -1 --format='%cI %h' 2>/dev/null || true)"
      gts="$(norma "${gi%% *}")"; gsha="${gi#* }"
      if [ -n "$gi" ] && valida_iso "$gts"; then
        desde="$gts"; rotulo="piso: último commit $gsha"
      else
        desde=""; rotulo=""
        echo "pause: aviso — sem pausa marcada e sem commit legível: 'parado desde' fica como lacuna." >&2
      fi
    fi
    sess="$(campo_sessao "$HOST")"
    linha="- retomada: $TS"
    [ -n "$sess" ] && linha="$linha · $sess"
    if [ -n "$desde" ]; then
      a="$(epoch "$desde")"; b="$(epoch "$TS")"
      if [ "$b" -lt "$a" ]; then
        echo "WARNING janela-negativa: retomada $TS anterior a 'parado desde' $desde — duração omitida" >&2
        linha="$linha · parado desde $desde ($rotulo)"
      else
        min=$(( (b - a) / 60 ))
        linha="$linha · parado desde $desde ($rotulo) · $(hum "$min")"
      fi
    else
      linha="$linha · parado desde — (sem marca nem commit legível)"
    fi
    anexa_cronologia "$BF" "$linha"
    printf 'brief\t%s\nlinha\t%s\n' "$BRIEF" "$linha"; exit 0 ;;

  report)
    case "$ALVO" in
      */*|*.md) case "$ALVO" in /*) BF="$ALVO" ;; *) BF="$ROOT/$ALVO" ;; esac ;;
      *) b="$(resolve_brief "$ALVO")"; [ -n "$b" ] || die3 "nenhum BRIEF ativo em $(docs_root)/$ALVO/briefs/."; BF="$ROOT/$b" ;;
    esac
    [ -f "$BF" ] || die3 "BRIEF ilegível: $ALVO"
    # extração: uma linha TSV por marca — tipo · ts · desde(retomada) · rótulo
    awk '
      function iso(s,   r) { if (match(s, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9]:?[0-9][0-9]/)) { r = substr(s, RSTART, RLENGTH)
                               if (length(r) == 25 && substr(r, 23, 1) == ":") r = substr(r, 1, 22) substr(r, 24, 2); return r } return "" }
      /^## Cronologia[[:space:]]*$/ { sec = 1; next }
      sec && /^## / { sec = 0 }
      sec && /^- pausa:/ { t = iso(substr($0, 9)); if (t == "") { print "WARNING nao-parseavel: " $0 > "/dev/stderr"; next }
                           printf "pausa\t%s\t\t\n", t; next }
      sec && /^- retomada:/ { t = iso(substr($0, 12)); if (t == "") { print "WARNING nao-parseavel: " $0 > "/dev/stderr"; next }
                              d = ""; rot = ""; p = index($0, "parado desde ")
                              if (p > 0) { seg = substr($0, p + 13); q = index(seg, " · "); if (q > 0) seg = substr(seg, 1, q - 1)
                                d = iso(seg)
                                if (index(seg, "(marcada)") > 0) rot = "marcada"; else if (match(seg, /\(piso:[^)]*\)/)) rot = substr(seg, RSTART + 1, RLENGTH - 2) }
                              printf "retomada\t%s\t%s\t%s\n", t, d, rot; next }' "$BF" \
    | awk -F '	' '
      function d2(s, i) { return substr(s, i, 2) + 0 }
      function epoch(iso,   y, m, d, H, Mi, S, sign, off, yy, era, yoe, doy, doe, days) {
        y = substr(iso, 1, 4) + 0; m = d2(iso, 6); d = d2(iso, 9)
        H = d2(iso, 12); Mi = d2(iso, 15); S = d2(iso, 18)
        sign = substr(iso, 20, 1); off = d2(iso, 21) * 3600 + d2(iso, 23) * 60
        if (sign == "-") off = -off
        yy = y - (m <= 2 ? 1 : 0)
        era = int((yy >= 0 ? yy : yy - 399) / 400)
        yoe = yy - era * 400
        doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
        doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
        days = era * 146097 + doe - 719468
        return days * 86400 + H * 3600 + Mi * 60 + S - off }
      function hum(min) { return sprintf("%dh%02dmin", int(min / 60), min % 60) }
      function fecha(desde, ate, rot,   m) {
        n++
        if (ate == "") { printf "pausa\t%s\tsem-retomada\t-\taberta\n", desde; abertas++; return }
        if (desde == "") { printf "pausa\t—\t%s\t-\t%s (sem desde)\n", ate, rot; abertas++; return }
        m = int((epoch(ate) - epoch(desde)) / 60)
        if (m < 0) { printf "WARNING janela-negativa: retomada %s anterior a %s — fora da soma\n", ate, desde > "/dev/stderr"; printf "pausa\t%s\t%s\t-\t%s\n", desde, ate, rot; abertas++; return }
        printf "pausa\t%s\t%s\t%d\t%s\n", desde, ate, m, rot
        soma += m; if (rot == "marcada") marc++; else piso++ }
      $1 == "pausa" { if (aberta != "") fecha(aberta, "", "aberta"); aberta = $2; next }
      $1 == "retomada" { if (aberta != "") { fecha(aberta, $2, "marcada"); aberta = "" }
                         else { fecha($3, $2, ($4 == "" ? "piso" : $4)) } next }
      END {
        if (aberta != "") fecha(aberta, "", "aberta")
        if (n == 0) exit 0
        medidas = marc + piso
        if (medidas > 0) {
          printf "pausas\t%d\tparado\t%d\t%s\t%d marcadas\t%d piso\t%d abertas\n", n, soma, hum(soma), marc, piso, abertas
          c = sprintf("pausas: %d · parado ~%s (%d marcadas, %d piso)", n, hum(soma), marc, piso)
        } else {
          printf "pausas\t%d\tparado\t-\t—\t0 marcadas\t0 piso\t%d abertas\n", n, abertas
          c = sprintf("pausas: %d · parado —", n)
        }
        if (abertas > 0) c = c sprintf(" · %d sem retomada marcada", abertas)
        printf "cauda\t%s\n", c }'
    exit 0 ;;
esac
