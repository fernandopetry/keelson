#!/usr/bin/env bash
# jira-preview.sh — projeção determinística do ensaio do Jira (/keelson:jira-preview).
#
# Lê a ficha (bloco `jira`, via ficha.sh) e o mapa do projeto (`jira.mapFile`) e imprime,
# por cenário, a árvore que o sync criaria e o efeito de cada marco e de cada verbo de
# fase. Não fala com o Jira: transição disponível, tipo existente e campo obrigatório
# são do conector, medidos pelo comando. A régua é a do protocolo de sync
# (skills/_shared/jira-sync-protocol.md §2, §3, §7.0, §7.1, §9, §13, §16) — este script
# a aplica, não a redefine.
#
# Uso: jira-preview.sh [<raiz-do-projeto>] [--levels spec=N,feature=N,task=N,standalone=N]
#
#   --levels   hierarchyLevel medido no Jira para cada tipo configurado (task: -1 quando
#              o tipo é subtask). Sem a flag, vale a hierarquia presumida
#              spec=1,feature=0,task=-1,standalone=0 e a saída declara `niveis presumidos`.
#
# Saída: uma linha por fato, campos separados por TAB.
#   config   <ok|falta|aviso|info>  <campo>  <detalhe>
#   mapa     <ok|falta|aviso|info>  <item>   <detalhe>
#   cenario  <id>  <projecao>  <arvore>
#   largada  <id>  <detalhe>
#   marco    <id>  <marco>  <no>  <efeito>  <alvo>  <nota>
#   fase     <id>  <verbo>  <nivel>  <efeito>  <alvo>  <nota>
#   <efeito> de marco: move | comentario | nada | incerto · de fase: move | nao-move
#   <id>: spec-multi-feat (SPEC com 2+ FEATs) · spec-uma-feat (0 ou 1 FEAT) · avulso
#
# Exit: 0 ok (inclusive jira desligado — a saída diz) · 2 uso incorreto ·
#       3 degradado com causa em stderr (ficha ausente/ilegível, ficha.sh ausente).
# Linha de mapa que o parser não entende vira `mapa aviso nao-parseavel`, nunca fato.
#
# Bash 3.2-compatível + awk POSIX. Read-only.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/ficha.sh"

die2() { echo "ERRO: $*" >&2; exit 2; }
die3() { echo "jira-preview.sh degradado: $*" >&2; exit 3; }

ROOT=""
LEVELS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --levels) shift; [ $# -gt 0 ] || die2 "--levels exige spec=N,feature=N,task=N,standalone=N."
              LEVELS="$1" ;;
    -h|--help) sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) die2 "flag desconhecida: $1" ;;
    *) [ -z "$ROOT" ] || die2 "raiz informada duas vezes."; ROOT="$1" ;;
  esac
  shift
done
[ -n "$ROOT" ] || ROOT="."
[ -f "$FICHA_SH" ] || die3 "ficha.sh não encontrado em $FICHA_SH"
[ -f "$ROOT/keelson.config.json" ] || die3 "ficha ausente em $ROOT"

get() { bash "$FICHA_SH" "$ROOT" --get "$1" 2>/dev/null; }
bash "$FICHA_SH" "$ROOT" --get docsRoot >/dev/null 2>&1 || die3 "ficha ilegível em $ROOT"

T="$(printf '\t')"
out() { # campos... → linha TAB
  line=""; sep=""
  for f in "$@"; do line="$line$sep$f"; sep="$T"; done
  printf '%s\n' "$line"
}

ENABLED="$(get jira.enabled)"
if [ "$ENABLED" != "true" ]; then
  out config falta jira.enabled "integracao desligada — /keelson:init jira liga"
  exit 0
fi
out config ok jira.enabled "true"

PROJECT="$(get jira.projectKey)"
CLOUD="$(get jira.cloudId)"
SITE="$(get jira.site)"
MODE="$(get jira.mode)";             [ -n "$MODE" ] || MODE="create"
T_SPEC="$(get jira.issueType.spec)"
T_FEAT="$(get jira.issueType.feature)"
T_TASK="$(get jira.issueType.task)"
T_ALONE="$(get jira.issueType.standalone)"
POLICY="$(get jira.epicPolicy)";     [ -n "$POLICY" ] || POLICY="always"
SPARENT="$(get jira.standaloneParent)"
TRANS="$(get jira.transition)";      [ -n "$TRANS" ] || TRANS="comment"
MAPFILE="$(get jira.mapFile)"
TELEM="$(get jira.telemetry)"
ESTIM="$(get jira.estimate)"

req() { # campo valor
  if [ -n "$2" ]; then out config ok "$1" "$2"; else out config falta "$1" "obrigatorio com jira.enabled"; fi
}
req jira.projectKey "$PROJECT"
if [ -n "$CLOUD" ] || [ -n "$SITE" ]; then out config ok jira.site "${SITE:-cloudId $CLOUD}"
else out config falta jira.site "site e cloudId vazios — o conector nao resolve o site"; fi
req jira.issueType.spec "$T_SPEC"
req jira.issueType.task "$T_TASK"
if [ -n "$T_FEAT" ]; then out config ok jira.issueType.feature "$T_FEAT"
else out config info jira.issueType.feature "null — sem Story de funcionalidade (3o nivel desligado)"; fi
if [ -n "$T_ALONE" ]; then out config ok jira.issueType.standalone "$T_ALONE"
else out config info jira.issueType.standalone "null — brief avulso nao sincroniza"; fi
case "$MODE" in
  create) out config ok jira.mode "create — o sync cria a raiz" ;;
  link)   out config info jira.mode "link — a raiz nunca e criada: a SPEC precisa trazer a key no cabecalho" ;;
  *)      out config aviso jira.mode "valor desconhecido: $MODE" ;;
esac
case "$POLICY" in
  always)        out config ok jira.epicPolicy "always — toda SPEC ganha Epic" ;;
  multi-feature) out config ok jira.epicPolicy "multi-feature — SPEC com 0 ou 1 FEAT nao ganha Epic" ;;
  *)             out config aviso jira.epicPolicy "valor desconhecido: $POLICY — tratado como always"; POLICY="always" ;;
esac
case "$TRANS" in
  off)     out config info jira.transition "off — nenhum gancho toca a issue depois de criada" ;;
  comment) out config info jira.transition "comment — os marcos comentam, o card nao anda sozinho" ;;
  auto)    out config ok jira.transition "auto — os marcos movem o card" ;;
  *)       out config aviso jira.transition "valor desconhecido: $TRANS — tratado como comment"; TRANS="comment" ;;
esac
if [ -n "$SPARENT" ]; then out config ok jira.standaloneParent "$SPARENT"
else out config info jira.standaloneParent "null — Story avulsa nasce sem pai"; fi
out config info jira.telemetry "${TELEM:-false}"
out config info jira.estimate "${ESTIM:-false}"

# --- níveis -----------------------------------------------------------------------
L_SPEC=1; L_FEAT=0; L_TASK=-1; L_ALONE=0
if [ -n "$LEVELS" ]; then
  oldifs="$IFS"; IFS=","
  for pair in $LEVELS; do
    k="${pair%%=*}"; v="${pair#*=}"
    case "$v" in ''|*[!0-9-]*) IFS="$oldifs"; die2 "--levels: valor invalido em '$pair'." ;; esac
    case "$k" in
      spec) L_SPEC="$v" ;; feature) L_FEAT="$v" ;; task) L_TASK="$v" ;; standalone) L_ALONE="$v" ;;
      *) IFS="$oldifs"; die2 "--levels: chave desconhecida '$k'." ;;
    esac
  done
  IFS="$oldifs"
  out config ok niveis "medidos: spec=$L_SPEC feature=$L_FEAT task=$L_TASK standalone=$L_ALONE"
else
  out config info niveis "presumidos: spec=1 feature=0 task=-1 standalone=0 — confirme no Jira"
fi

# --- mapa -------------------------------------------------------------------------
TMP="$(mktemp -d)" || die3 "mktemp falhou"
trap 'rm -rf "$TMP"' EXIT
ROWS="$TMP/rows"; : > "$ROWS"
HAS_MAP=0
if [ -z "$MAPFILE" ]; then
  out mapa falta jira.mapFile "null — o sync so preenche titulo e descricao; nenhum card se move"
elif [ ! -f "$ROOT/$MAPFILE" ]; then
  out mapa falta jira.mapFile "arquivo nao encontrado: $MAPFILE"
else
  HAS_MAP=1
  out mapa ok jira.mapFile "$MAPFILE"
  awk '
    function trim(s) { gsub(/^[ \t`*]+|[ \t`*]+$/, "", s); return s }
    function low(s)  { return tolower(s) }
    function ident(s,   t) {           # ID de status: numero entre parenteses, senao 1o numero, senao texto
      t = s
      if (match(t, /\([0-9]+\)/)) return substr(t, RSTART + 1, RLENGTH - 2)
      if (match(t, /[0-9]+/))     return substr(t, RSTART, RLENGTH)
      return trim(t)
    }
    function nivel(s,   l) {
      l = low(s)
      if (l ~ /sub/) return "subtask"
      if (l ~ /epic|pico/) return "epic"
      if (l ~ /story|hist/) return "story"
      return ""
    }
    BEGIN { OFS = "\t"; incomment = 0; sec = ""; ord = 0 }
    {
      line = $0
      if (incomment) { if (line ~ /-->/) incomment = 0; next }
      if (line ~ /<!--/) { if (line !~ /-->/) incomment = 1; next }
      if (line ~ /^#+[ \t]/) {
        l = low(line)
        if (l ~ /campos/) { sec = "campos"; print "sec", "campos" }
        else if (l ~ /etapas|colunas/) { sec = "etapas"; print "sec", "etapas"; hdr = 0 }
        else if (l ~ /trilho/) { sec = "trilho"; print "sec", "trilho" }
        else sec = ""
        next
      }
      if (sec == "trilho") {
        if (line !~ /:/) next
        t = line; sub(/^[ \t>*-]+/, "", t)
        k = t; sub(/:.*/, "", k); nv = nivel(trim(k))
        if (nv == "") next
        rest = t; sub(/^[^:]*:/, "", rest)
        gsub(/\342\206\222/, "\001", rest); gsub(/->/, "\001", rest)
        n = split(rest, seg, "\001"); ids = ""
        for (i = 1; i <= n; i++) { v = ident(seg[i]); if (v != "") ids = ids (ids == "" ? "" : " ") v }
        if (ids != "") print "trilho", nv, ids
        next
      }
      if (sec != "etapas" || line !~ /^[ \t]*\|/) next
      t = line; sub(/^[ \t]*\|/, "", t); sub(/\|[ \t]*$/, "", t)
      n = split(t, c, "|")
      if (!hdr) {
        cE = 0; cN = 0; cC = 0; cA = 0; cG = 0
        for (i = 1; i <= n; i++) {
          h = low(trim(c[i]))
          if (h ~ /^etapa/) cE = i
          else if (h ~ /^n.*vel$/) cN = i
          else if (h ~ /^coluna/) cC = i
          else if (h ~ /status/) cA = i
          else if (h ~ /^gatilho/) cG = i
        }
        if (cE && cA) { hdr = 1; if (!cN) print "legado", "sem-coluna-nivel" }
        next
      }
      if (t ~ /^[ \t:|-]+$/) next
      etapa = trim(c[cE]); le = low(etapa)
      gat = (cG ? low(trim(c[cG])) : "")
      nv = (cN ? nivel(trim(c[cN])) : "")
      alvo = ident(c[cA]); col = (cC ? trim(c[cC]) : "")
      tipo = "outro"
      if (gat ~ /--phase[ \t]+start-dev/) tipo = "fase:start-dev"
      else if (gat ~ /--phase[ \t]+finish-dev/) tipo = "fase:finish-dev"
      else if (le ~ /^task iniciada/) { tipo = "task-iniciada"; if (nv == "") nv = "subtask" }
      else if (le ~ /^task conclu/) { tipo = "task-concluida"; if (nv == "") nv = "subtask" }
      else if (le ~ /^trabalho iniciado/) { tipo = "trabalho-iniciado"; if (nv == "") nv = "story" }
      else if (le ~ /pronta p/) { tipo = "pronta-qa"; if (nv == "") nv = "story" }
      else if (le ~ /^fila de merge/) tipo = "fila-merge"
      if (tipo ~ /^fase:/ && nv == "") { print "ruim", etapa; next }
      if (alvo == "" && tipo != "outro") { print "ruim", etapa; next }
      ord++
      print "row", tipo, nv, alvo, col, ord
    }
  ' "$ROOT/$MAPFILE" > "$ROWS"

  for s in campos etapas trilho; do
    if grep -q "^sec${T}$s\$" "$ROWS"; then out mapa ok "secao-$s" "presente"
    elif [ "$s" = "trilho" ]; then out mapa info "secao-trilho" "ausente — so transicao direta, sem caminho de varios saltos"
    else out mapa falta "secao-$s" "ausente"; fi
  done
  grep -q "^legado${T}" "$ROWS" && out mapa aviso coluna-nivel "tabela de etapas sem a coluna Nivel — /keelson:init jira sugere a estrutura atual"
  while IFS="$T" read -r kind what _; do
    [ "$kind" = "ruim" ] && out mapa aviso nao-parseavel "linha de etapa ignorada: $what"
  done < "$ROWS"
  nother="$(grep -c "^row${T}outro${T}" "$ROWS")"
  [ "$nother" -gt 0 ] && out mapa aviso marcos-nao-canonicos "$nother linha(s) — documentacao do fluxo do time, o sync nao executa"
fi

row_alvo() { # tipo nivel → alvo (vazio se ausente); nivel vazio = qualquer
  awk -F"$T" -v t="$1" -v n="$2" '$1=="row" && $2==t && (n=="" || $3==n) { print $4; exit }' "$ROWS"
}
row_col() {
  awk -F"$T" -v t="$1" -v n="$2" '$1=="row" && $2==t && (n=="" || $3==n) { print $5; exit }' "$ROWS"
}
trilho_de() { awk -F"$T" -v n="$1" '$1=="trilho" && $2==n { print $3; exit }' "$ROWS"; }
pos() { # nivel alvo → posicao na regua do nivel (trilho; senao ordem das linhas); vazio = fora
  tr_="$(trilho_de "$1")"
  if [ -n "$tr_" ]; then
    i=0
    for s in $tr_; do i=$((i + 1)); [ "$s" = "$2" ] && { echo "$i"; return; }; done
    return
  fi
  awk -F"$T" -v n="$1" -v a="$2" '$1=="row" && $3==n && $4==a { print $6; exit }' "$ROWS"
}
rotulo() { # alvo coluna → "id (coluna)"
  if [ -n "$2" ]; then printf '%s (%s)' "$1" "$2"; else printf '%s' "$1"; fi
}

if [ "$HAS_MAP" = "1" ]; then
  for m in task-iniciada task-concluida trabalho-iniciado pronta-qa; do
    a="$(row_alvo "$m" "")"
    if [ -n "$a" ]; then out mapa ok "marco-$m" "alvo $(rotulo "$a" "$(row_col "$m" "")")"
    else out mapa falta "marco-$m" "sem linha — o marco vira comentario"; fi
  done
  for v in start-dev finish-dev; do
    for n in epic story subtask; do
      a="$(row_alvo "fase:$v" "$n")"
      if [ -n "$a" ]; then out mapa ok "fase-$v-$n" "alvo $(rotulo "$a" "$(row_col "fase:$v" "$n")")"
      elif [ "$n" = "epic" ]; then out mapa info "fase-$v-epic" "sem linha — o Epic nao se move (opt-in)"
      else out mapa falta "fase-$v-$n" "sem linha — esse nivel nao se move com --phase $v"; fi
    done
  done
  for n in story subtask; do
    tr_="$(trilho_de "$n")"
    [ -n "$tr_" ] || continue
    out mapa ok "trilho-$n" "$(printf '%s' "$tr_" | sed 's/ / > /g')"
    awk -F"$T" -v n="$n" '$1=="row" && $3==n && $2!="outro" && $2!="fila-merge" { print $2 "\t" $4 }' "$ROWS" |
    while IFS="$T" read -r tp al; do
      [ -n "$(pos "$n" "$al")" ] || out mapa aviso "trilho-$n" "alvo $al ($tp) fora do trilho — o caminho de varios saltos nao chega nele"
    done
  done
fi

# --- efeito de marco e de fase -----------------------------------------------------
# marco <cenario> <rotulo-marco> <tipo> <no> <qa:0|1> <cruzado:0|1>
marco() {
  cen="$1"; lab="$2"; tipo="$3"; no="$4"; qa="$5"; cruz="$6"
  if [ "$TRANS" = "off" ]; then out marco "$cen" "$lab" "$no" nada "-" "transition off"; return; fi
  if [ "$HAS_MAP" != "1" ]; then out marco "$cen" "$lab" "$no" comentario "-" "sem mapa: o card nao anda"; return; fi
  a="$(row_alvo "$tipo" "")"; col="$(row_col "$tipo" "")"
  if [ -z "$a" ]; then out marco "$cen" "$lab" "$no" comentario "-" "sem linha no mapa"; return; fi
  al="$(rotulo "$a" "$col")"
  if [ "$TRANS" = "comment" ]; then out marco "$cen" "$lab" "$no" comentario "$al" "transition comment: o card nao anda"; return; fi
  if [ "$cruz" = "1" ]; then
    out marco "$cen" "$lab" "$no" incerto "$al" "alvo de linha subtask aplicado a card de nivel story — so a prova viva fecha"; return
  fi
  if [ "$qa" = "1" ] && [ "$tipo" != "trabalho-iniciado" ]; then
    teto="$(row_alvo trabalho-iniciado "")"
    if [ -z "$teto" ]; then out marco "$cen" "$lab" "$no" comentario "$al" "sem teto declarado (linha Trabalho iniciado ausente)"; return; fi
    pa="$(pos story "$a")"; pt="$(pos story "$teto")"
    if [ -z "$pa" ] || [ -z "$pt" ]; then out marco "$cen" "$lab" "$no" comentario "$al" "alvo ou teto fora da regua do nivel"; return; fi
    if [ "$pa" -gt "$pt" ]; then out marco "$cen" "$lab" "$no" comentario "$al" "alvo alem do teto $teto — avancar e ato humano (--phase)"; return; fi
  fi
  nv="subtask"; [ "$qa" = "1" ] && nv="story"
  tr_="$(trilho_de "$nv")"
  if [ -z "$tr_" ]; then out marco "$cen" "$lab" "$no" move "$al" "so salto direto (nivel sem trilho) — transicao a medir"
  elif [ -z "$(pos "$nv" "$a")" ]; then out marco "$cen" "$lab" "$no" incerto "$al" "alvo fora do trilho — so salto direto"
  else out marco "$cen" "$lab" "$no" move "$al" "caminho pelo trilho — transicoes a medir"; fi
}
# fase <cenario> <nivel> <no>
fases() {
  cen="$1"; nv="$2"; no="$3"
  for v in start-dev finish-dev; do
    if [ "$TRANS" = "off" ]; then out fase "$cen" "$v" "$no" nao-move "-" "transition off"; continue; fi
    if [ "$HAS_MAP" != "1" ]; then out fase "$cen" "$v" "$no" nao-move "-" "sem mapa"; continue; fi
    a="$(row_alvo "fase:$v" "$nv")"
    if [ -z "$a" ]; then out fase "$cen" "$v" "$no" nao-move "-" "sem linha $nv para o verbo (opt-out)"
    else out fase "$cen" "$v" "$no" move "$(rotulo "$a" "$(row_col "fase:$v" "$nv")")" "ordem do Diretor — vale com comment e auto"; fi
  done
}
m_sub()  { marco "$1" "TASK iniciada" task-iniciada "$2" 0 0; marco "$1" "TASK concluida" task-concluida "$2" 0 0; }
m_qa()   { marco "$1" "Trabalho iniciado (Story)" trabalho-iniciado "$2" 1 0; marco "$1" "Funcionalidade pronta p/ QA" pronta-qa "$2" 1 0; }
m_iso()  { marco "$1" "TASK iniciada" task-iniciada "$2" 1 1; marco "$1" "TASK concluida" task-concluida "$2" 1 1
           marco "$1" "Funcionalidade pronta p/ QA" pronta-qa "$2" 1 0; }
epic_auto() { out marco "$1" "todos" "Epic" nada "-" "Epic intocado pelos ganchos automaticos — so anda por --phase com linha epic"; }

RAIZ="Epic"
[ "$MODE" = "link" ] && RAIZ="issue existente (key no cabecalho da SPEC)"
SUB_OK=1; [ "$L_TASK" = "-1" ] || SUB_OK=0
FEAT_OK=0; [ -n "$T_FEAT" ] && [ "$L_FEAT" = "0" ] && FEAT_OK=1
ALONE_OK=0; [ -n "$T_ALONE" ] && [ "$L_ALONE" = "0" ] && ALONE_OK=1
[ -n "$T_FEAT" ] && [ "$L_FEAT" != "0" ] && out config aviso jira.issueType.feature "nivel $L_FEAT nao e 0 — a Story nao aninha sob o Epic"
[ -n "$T_ALONE" ] && [ "$L_ALONE" != "0" ] && out config aviso jira.issueType.standalone "nivel $L_ALONE nao e 0 — a tarefa isolada nao aninha"

# plena <cenario> <multi:0|1> — projeção sem a política compacta (§7.0)
plena() {
  cen="$1"; multi="$2"
  if [ "$SUB_OK" = "0" ]; then
    out cenario "$cen" "2 niveis por link" "$RAIZ ~ issue comum por TASK (link 'relates to'; o tipo de task nao e sub-task)"
    m_sub "$cen" "issue da TASK"; fases "$cen" subtask "issue da TASK"; return
  fi
  if [ "$L_SPEC" = "0" ]; then
    if [ -n "$T_FEAT" ]; then out config aviso jira.issueType.feature "spec de nivel 0 nao comporta Story abaixo — 3o nivel ignorado"; fi
    out cenario "$cen" "2 niveis valido" "issue da SPEC > sub-task por TASK"
    m_sub "$cen" "sub-task"; fases "$cen" story "issue da SPEC"; fases "$cen" subtask "sub-task"; return
  fi
  if [ "$FEAT_OK" = "1" ]; then
    if [ "$multi" = "1" ]; then out cenario "$cen" "3 niveis pleno" "$RAIZ > Story por FEAT > sub-task por TASK"
    else out cenario "$cen" "2 niveis via Story unica" "$RAIZ > Story (da FEAT unica, ou implicita espelhando a SPEC) > sub-task por TASK"; fi
    epic_auto "$cen"; m_qa "$cen" "Story"; m_sub "$cen" "sub-task"
    fases "$cen" epic "Epic"; fases "$cen" story "Story"; fases "$cen" subtask "sub-task"; return
  fi
  if [ "$ALONE_OK" = "1" ]; then
    out cenario "$cen" "2 niveis via tarefa isolada" "$RAIZ > tarefa isolada por TASK (sem Story: o QA cai para tarefa de dev)"
    epic_auto "$cen"; m_iso "$cen" "tarefa isolada"
    fases "$cen" epic "Epic"; fases "$cen" story "tarefa isolada"; return
  fi
  out cenario "$cen" "inviavel" "sub-task nao cabe sob o Epic e nao ha feature nem standalone de nivel 0 — nada e criado"
}

LARG="raiz criada na largada do ciclo (antes da SPEC), salvo modo link"
[ "$POLICY" = "multi-feature" ] && LARG="raiz criada no gancho do specify (a politica precisa contar as FEATs)"

# SPEC com 2+ FEATs
out largada spec-multi-feat "$LARG"
plena spec-multi-feat 1

# SPEC com 0 ou 1 FEAT
if [ "$POLICY" = "multi-feature" ] && [ "$FEAT_OK" = "1" ] && [ "$SUB_OK" = "1" ]; then
  out largada spec-uma-feat "$LARG"
  out cenario spec-uma-feat "compacta" "Story raiz sem pai > sub-task por TASK (sem Epic)"
  m_qa spec-uma-feat "Story raiz"; m_sub spec-uma-feat "sub-task"
  fases spec-uma-feat story "Story raiz"; fases spec-uma-feat subtask "sub-task"
else
  if [ "$POLICY" = "multi-feature" ]; then
    out config aviso jira.epicPolicy "multi-feature sem feature de nivel 0 — projecao compacta inviavel, cai para a plena"
  fi
  out largada spec-uma-feat "$LARG"
  plena spec-uma-feat 0
fi

# Brief avulso
if [ -z "$T_ALONE" ]; then
  out cenario avulso "nao sincroniza" "issueType.standalone null — o brief avulso nao gera card"
elif [ "$ALONE_OK" = "0" ]; then
  out cenario avulso "inviavel" "standalone de nivel $L_ALONE — a Story avulsa nao aninha sub-tasks"
else
  if [ -n "$SPARENT" ]; then pai="$SPARENT > "; else pai="(sem pai) "; fi
  out largada avulso "Story criada antes do codigo, na largada do brief"
  out cenario avulso "Story avulsa" "${pai}Story avulsa > sub-task por TASK (so quando o trabalho reparte)"
  marco avulso "TASK iniciada" task-iniciada "Story avulsa" 1 1
  marco avulso "Funcionalidade pronta p/ QA" pronta-qa "Story avulsa" 1 0
  if [ "$SUB_OK" = "1" ]; then m_sub avulso "sub-task"; fi
  fases avulso story "Story avulsa"; fases avulso subtask "sub-task"
fi
exit 0
