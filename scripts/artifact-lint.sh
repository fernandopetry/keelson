#!/usr/bin/env bash
# artifact-lint.sh — lint mecânico de forma dos artefatos SDD (decisão 4.152).
# Contrato (catálogo de checks, severidades, régua de rebaixamento):
# docs/_meta/conventions/lint-contract.md. Os validators (spec/plan/task-validator)
# executam este script e citam a saída como FATO (mesma régua do graph.sh, §5 do
# graph-contract.md); a calibração final continua deles.
#
# Uso: artifact-lint.sh <caminho> [<caminho>…]
#   <caminho>  arquivo SPEC-*.md, PLAN-*.md ou TASK-*.md (tipo inferido do caminho),
#              ou diretório de slug ({docsRoot}/<slug>) — linta todos os artefatos
#              e acrescenta os checks cross-arquivo (overlap de FR).
#
# Saída: SEVERIDADE<TAB>check<TAB>detalhe, ordenada (LC_ALL=C).
# Exit: 0 sem ERROR · 1 com ERROR · 2 uso incorreto.
#
# Princípios (decisão 4.152):
# - Fato inequívoco (seção ausente, enum inválido, número de ID divergente) herda a
#   severidade do catálogo do validator. Check baseado em PADRÃO (EARS, wordlist de
#   tecnologia, Given-When-Then) sai no máximo como WARNING — quem escala é o
#   validator, com olhos. Falso ERROR em artefato legítimo é o pior defeito.
# - Carência de legado: artefato `Status: Done` rebaixa ERROR → WARNING com sufixo
#   `[legacy]` (mesma régua do graph-contract §3).
# - Julgamento (sujeito vago, FR composto, sinônimo de glossário, cobertura reversa)
#   NÃO entra aqui: continua no validator.
# Read-only. Bash 3.2 + awk POSIX, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }

[ $# -gt 0 ] || { usage >&2; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/findings.txt"
: > "$OUT"

# ---------- awk: SPEC ----------
cat > "$TMP/spec.awk" <<'AWK'
function emit(sev, chk, det) {
  if (sev == "ERROR" && STATUS == "Done") { sev = "WARNING"; det = det " [legacy]" }
  printf "%s\t%s\t%s (%s)\n", sev, chk, det, FILE
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function wordhit(line, w,   p, s, pre, aft) {
  s = line
  while ((p = index(s, w)) > 0) {
    pre = (p > 1) ? substr(s, p - 1, 1) : " "
    aft = substr(s, p + length(w), 1)
    if (pre !~ /[A-Za-z0-9_]/ && aft !~ /[A-Za-z0-9_]/) return 1
    s = substr(s, p + 1)
  }
  return 0
}
BEGIN {
  nhdr = split("Slug Status Vers Autor Data", hdr, " ")
  ntech = split(TECH, tech, "|")
}
{ line = $0; sub(/\r$/, "", line) }

# cabeçalho markdown (antes da primeira secao ##)
sect == "" && line ~ /^\*\*[A-Z]/ {
  if (line ~ /^\*\*Slug\*\*[ \t]*:/)    { hSlug = 1; v = line; sub(/^[^:]*:/, "", v); if (trim(v) == "") hSlug = 0 }
  if (line ~ /^\*\*Status\*\*[ \t]*:/)  { hStatus = 1; v = line; sub(/^[^:]*:/, "", v); STATUS = trim(v) }
  if (line ~ /^\*\*Vers/)               { hVers = 1 }
  if (line ~ /^\*\*Autor\*\*[ \t]*:/)   { hAutor = 1; v = line; sub(/^[^:]*:/, "", v); if (index(v, "<preencher>") > 0) autorPre = 1 }
  if (line ~ /^\*\*Data\*\*[ \t]*:/)    { hData = 1; v = trim(line); sub(/^[^:]*:[ \t]*/, "", v)
    if (v !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) dataFmt = 1 }
}

/^## / {
  h = trim(substr(line, 4))
  if (h ~ /^1\./)  { sec[1] = 1;  sect = "1" }
  if (h ~ /^2\./)  { sec[2] = 1;  sect = "2" }
  if (h ~ /^3\./)  { sec[3] = 1;  sect = "3" }
  if (h ~ /^4\./)  { sec[4] = 1;  sect = "4" }
  if (h ~ /^5\./)  { sec[5] = 1;  sect = "5" }
  if (h ~ /^6\./)  { sec[6] = 1;  sect = "6" }
  if (h ~ /^7\./)  { sec[7] = 1;  sect = "7" }
  if (h ~ /^8\./)  { sec[8] = 1;  sect = "8" }
  if (h ~ /^9\./)  { sec[9] = 1;  sect = "9" }
  if (h ~ /^10\./) { sec[10] = 1; sect = "10" }
  if (h !~ /^[0-9]/) sect = "x"
  cur_feat = ""; sub14 = ""
  next
}
/^### / {
  h = trim(substr(line, 5))
  if (sect == "1" && h ~ /^1\.1/) s11 = 1
  if (sect == "1" && h ~ /^1\.2/) s12 = 1
  if (sect == "1" && h ~ /^1\.3/) { s13 = 1; sub14 = "metrica"; next }
  if (sect == "4" && h ~ /^4\.1/) { s41 = 1; sub14 = "in"; next }
  if (sect == "4" && h ~ /^4\.2/) { s42 = 1; sub14 = "out"; next }
  if (h ~ /^FEAT-/) {
    if (match(h, /FEAT-[0-9]+-[0-9]+/)) {
      id = substr(h, RSTART, RLENGTH)
      if (sect != "5") emit("ERROR", "spec-feat-fora-da-5", id " declarada fora da secao 5")
      else { NF9++; FEAT[NF9] = id; FFR[NF9] = 0; FDESC[NF9] = 0; cur_feat = NF9; checkid(id) }
    }
    next
  }
  sub14 = ""
  next
}

sub14 == "metrica" { metrica = metrica " " line
  if (line ~ /^\*\*Fonte de medi/) temFonte = 1
  next
}

# acumulo do corpo das secoes 5-7 (glossario/tecnologia) — ANTES das regras com
# next de FR/NFR/AC, senao os bullets nunca chegam aqui
sect == "5" || sect == "6" || sect == "7" {
  body567 = body567 " " tolower(line)
  for (ti = 1; ti <= ntech; ti++)
    if (wordhit(line, tech[ti]) && !(tech[ti] in techseen)) {
      techseen[tech[ti]] = 1
      emit("WARNING", "spec-tecnologia", "\"" tech[ti] "\" citado na secao " sect " (dominio, nao tecnologia — pode ser falso positivo)")
    }
  if (index(line, "[confirmar]") > 0) nconf++
}
sub14 == "in"  && /^- / { nin++;  inod[nin] = tolower(trim(substr(line, 3))); next }
sub14 == "out" && /^- / { nout++; outod[nout] = tolower(trim(substr(line, 3))); next }

# FEAT: linha de descricao ">" antes do primeiro FR
sect == "5" && cur_feat != "" && /^> / { FDESC[cur_feat] = 1; next }

# FRs (secao 5)
sect == "5" && line ~ /^- \*\*FR-[0-9]+/ {
  nfr++
  if (match(line, /FR-[0-9]+-[0-9]+/)) { id = substr(line, RSTART, RLENGTH); checkid(id) }
  if (cur_feat != "") FFR[cur_feat]++
  else frFora++
  txt = line
  sub(/^- \*\*FR-[0-9-]+\*\*[ \t]*/, "", txt)
  # RFC 2119
  if (txt ~ /\[(MUST|SHOULD|MAY)\]/) {
    if (txt ~ /\[MUST\]/) nmust++
    else nsm++
  } else if (txt ~ /\[(must|should|may|obrigat|recomendado|opcional)/) {
    emit("WARNING", "spec-rfc-forma", id ": marcador RFC 2119 fora da forma canonica [MUST]/[SHOULD]/[MAY]")
    nsm++
  } else {
    emit("ERROR", "spec-fr-sem-rfc", id ": FR sem [MUST]/[SHOULD]/[MAY]")
  }
  sub(/^\[[A-Za-z]+\][ \t]*/, "", txt)
  # EARS
  if (txt !~ / deve[ m]/ && txt !~ / deve$/) {
    emit("ERROR", "spec-fr-sem-deve", id ": FR sem o verbo \"deve\"")
  } else if (txt !~ /^O[s]? .+ deve/ && txt !~ /^Quando .+, [oa]s? .+ deve/ && \
             txt !~ /^Enquanto .+, [oa]s? .+ deve/ && txt !~ /^Onde .+, [oa]s? .+ deve/ && \
             txt !~ /^Se .+ ent..o [oa]s? .+ deve/) {
    emit("WARNING", "spec-ears-nao-casa", id ": FR fora dos 5 padroes EARS")
  }
  if (split(txt, wtmp, /[ \t]+/) > 30)
    emit("WARNING", "spec-fr-palavras", id ": FR com mais de 30 palavras")
  next
}

# NFRs (secao 6)
sect == "6" && line ~ /^- \*\*NFR-[0-9]+/ {
  if (match(line, /NFR-[0-9]+-[0-9]+/)) { id = substr(line, RSTART, RLENGTH); checkid(id) }
  low = tolower(line)
  if (low ~ /r..?pido|seguro|user-friendly|intuitiv|escal..?vel/)
    emit("WARNING", "spec-nfr-vago", id ": NFR com termo vago (rapido/seguro/user-friendly/intuitivo/escalavel)")
  if (line !~ /[0-9]/)
    emit("WARNING", "spec-nfr-sem-numero", id ": NFR sem valor numerico")
  next
}

# ACs (secao 7)
sect == "7" && line ~ /^- \*\*AC-[0-9]+/ {
  nac++
  if (match(line, /AC-[0-9]+-[0-9]+/)) { id = substr(line, RSTART, RLENGTH); checkid(id) }
  low = tolower(line)
  if (!(index(low, "dado") > 0 && index(low, "quando") > 0 && (index(low, "ent\303\243o") > 0 || index(low, "entao") > 0)))
    emit("WARNING", "spec-ac-fora-gwt", id ": AC fora de Dado-Quando-Entao")
  next
}

# demais IDs numerados
line ~ /^- \*\*(RISK|A|Q)-[0-9]+/ {
  if (match(line, /(RISK|A|Q)-[0-9]+-[0-9]+/)) checkid(substr(line, RSTART, RLENGTH))
}

# premissas (secao 8) e riscos (secao 9)
sect == "8" && /^- / {
  nprem++
  if (index(line, "[confirmar]") > 0) nconf++
  if (index(line, "[assumido]") == 0 && index(line, "[confirmado]") == 0 && index(line, "[confirmar]") == 0)
    emit("WARNING", "spec-premissa-sem-marcador", "linha " FNR ": item da secao 8 sem [assumido]/[confirmado]/[confirmar]")
  else if ((index(line, "[assumido]") > 0 || index(line, "[confirmado]") > 0) && index(line, "[evid") == 0 && STATUS != "Approved" && STATUS != "Done")
    emit("WARNING", "spec-premissa-sem-selo", "linha " FNR ": premissa sem selo [evidencia: crenca|anedota|entrevistas|medido] (4.96)")
  next
}
sect == "9" && /^- / { nrisco++ }

# tecnologia (secoes 5, 6, 7) + glossario (secao 3)
sect == "3" && /^\|/ {
  n = split(line, c, "|")
  if (n >= 3) {
    t = trim(c[2])
    if (t != "" && t !~ /^Termo$/ && t !~ /^[-: ]+$/) { ngl++; gloss[ngl] = t }
  }
  next
}
sect == "1" || sect == "2" || sect == "4" || sect == "8" || sect == "9" || sect == "10" {
  if (index(line, "[confirmar]") > 0) nconf++
}

function checkid(id,   parts, n, nnn, xxx) {
  n = split(id, parts, "-")
  nnn = parts[n-1]; xxx = parts[n]
  if (SPECN != "" && nnn + 0 != SPECN + 0)
    emit("ERROR", "spec-id-fora-do-numero", id ": NNN (" nnn ") difere do numero da SPEC (" SPECN ")")
  if (length(xxx) != 3)
    emit("WARNING", "spec-id-zero-pad", id ": XXX sem zero-padding de 3 digitos")
}

END {
  for (i = 1; i <= 10; i++)
    if (!(i in sec)) emit("ERROR", "spec-secao-ausente", "secao \"## " i ".\" ausente")
  if ((1 in sec) && !s11) emit("ERROR", "spec-secao-ausente", "subsecao 1.1 ausente")
  if ((1 in sec) && !s12) emit("ERROR", "spec-secao-ausente", "subsecao 1.2 ausente")
  if ((1 in sec) && !s13) emit("ERROR", "spec-secao-ausente", "subsecao 1.3 ausente")
  if ((4 in sec) && !s41) emit("ERROR", "spec-secao-ausente", "subsecao 4.1 ausente")
  if ((4 in sec) && !s42) emit("ERROR", "spec-secao-ausente", "subsecao 4.2 ausente")
  if (!hSlug)   emit("ERROR", "spec-campo-ausente", "campo **Slug**: ausente ou vazio")
  if (!hStatus) emit("ERROR", "spec-campo-ausente", "campo **Status**: ausente")
  else if (STATUS !~ /^(Draft|Review|Approved|Done)$/)
    emit("ERROR", "spec-status-enum", "Status \"" STATUS "\" fora de {Draft, Review, Approved, Done}")
  if (!hVers)  emit("ERROR", "spec-campo-ausente", "campo **Versao**: ausente")
  if (!hAutor) emit("ERROR", "spec-campo-ausente", "campo **Autor**: ausente")
  else if (autorPre) emit("WARNING", "spec-autor-preencher", "Autor ainda como <preencher>")
  if (!hData)  emit("ERROR", "spec-campo-ausente", "campo **Data**: ausente")
  else if (dataFmt) emit("WARNING", "spec-data-formato", "Data fora do formato YYYY-MM-DD")
  # RFC ratio — so com 3+ FRs (SPEC de 1-2 FRs nao e falta de priorizacao)
  if (nfr >= 3) {
    if (nmust * 100 > nfr * 70) emit("WARNING", "spec-must-ratio", nmust " de " nfr " FRs sao MUST (>70% — sem priorizacao real)")
    if (nsm == 0) emit("WARNING", "spec-sem-should-may", "nenhum FR SHOULD ou MAY")
  }
  if (nfr > 30) emit("WARNING", "spec-porte-epico", nfr " FRs na secao 5 (>30 — sugerir /keelson:specify-epic antes de Approved, 4.115)")
  # FEATs
  if (NF9 > 0) {
    if (frFora > 0) emit("ERROR", "spec-feat-particao", frFora " FR(s) fora de qualquer heading FEAT (particao parcial)")
    for (i = 1; i <= NF9; i++) {
      if (FFR[i] == 0) emit("ERROR", "spec-feat-vazia", FEAT[i] " sem nenhum FR sob o heading")
      if (!FDESC[i])   emit("WARNING", "spec-feat-sem-descricao", FEAT[i] " sem a linha de descricao \"> \"")
    }
    if (NF9 == 1) emit("WARNING", "spec-feat-unica", "exatamente 1 FEAT declarada (sugerir colapso: a funcionalidade e a propria SPEC)")
  }
  # metrica (1.3)
  if (s13) {
    if (metrica !~ /[0-9]/) emit("WARNING", "spec-metrica-sem-numero", "metrica de sucesso (1.3) sem numero")
    if (!temFonte && (STATUS == "Draft" || STATUS == "Review"))
      emit("WARNING", "spec-metrica-sem-fonte", "metrica de sucesso (1.3) sem linha **Fonte de medicao**: (4.99)")
  }
  # escopo (4.1/4.2)
  if (s42 && nout == 0) emit("ERROR", "spec-out-of-scope-vazio", "out-of-scope (4.2) vazio")
  else if (s42 && nout < 2) emit("WARNING", "spec-out-of-scope-curto", "out-of-scope (4.2) com menos de 2 itens")
  for (i = 1; i <= nin; i++)
    for (j = 1; j <= nout; j++)
      if (inod[i] != "" && inod[i] == outod[j])
        emit("ERROR", "spec-in-eq-out", "item identico em in-scope e out-of-scope: \"" inod[i] "\"")
  # premissas/riscos
  if ((8 in sec) && nprem == 0)  emit("WARNING", "spec-sem-premissa", "nenhuma premissa listada na secao 8")
  if ((9 in sec) && nrisco == 0) emit("WARNING", "spec-sem-risco", "nenhum risco listado na secao 9")
  if (nconf > 3 && (STATUS == "Draft" || STATUS == "Review"))
    emit("WARNING", "spec-confirmar-teto", nconf " [confirmar] na SPEC (teto 3 — excedente vira [assumido] com default, 4.144)")
  # glossario nao usado
  for (i = 1; i <= ngl; i++)
    if (index(body567, tolower(gloss[i])) == 0)
      emit("WARNING", "spec-glossario-nao-usado", "termo \"" gloss[i] "\" do glossario nao aparece nas secoes 5-7")
}
AWK

# ---------- awk: PLAN ----------
cat > "$TMP/plan.awk" <<'AWK'
function emit(sev, chk, det) {
  if (sev == "ERROR" && STATUS == "Done") { sev = "WARNING"; det = det " [legacy]" }
  printf "%s\t%s\t%s (%s)\n", sev, chk, det, FILE
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function flushdec() {
  if (cur_dec == "") return
  if (!dCtx)  emit("ERROR", "plan-dec-campo-ausente", cur_dec " sem **Contexto**:")
  if (!dDec)  emit("ERROR", "plan-dec-campo-ausente", cur_dec " sem **Decisao**:")
  if (!dAlt)  emit("ERROR", "plan-dec-campo-ausente", cur_dec " sem **Alternativas consideradas**:")
  if (!dCons) emit("ERROR", "plan-dec-campo-ausente", cur_dec " sem **Consequencias**:")
  if (!dIrr)  emit("ERROR", "plan-dec-campo-ausente", cur_dec " sem **Irreversivel**:")
  if (dAlt && nAlt == 0) emit("ERROR", "plan-dec-sem-alternativa", cur_dec " sem nenhuma alternativa listada")
  else if (dAlt && nAlt == 1) emit("WARNING", "plan-dec-alternativa-unica", cur_dec " com apenas 1 alternativa (caminho unico?)")
  if (dIrr) {
    v = irrval
    lv = tolower(v); gsub(/\303\243/, "a", lv)  # ã→a
    if (lv != "sim" && lv != "nao")
      emit("ERROR", "plan-dec-irreversivel-enum", cur_dec ": Irreversivel \"" v "\" fora de {sim, nao}")
    else if (v != "sim" && v != "n\303\243o" && v != "nao")
      emit("WARNING", "plan-dec-irreversivel-forma", cur_dec ": Irreversivel \"" v "\" fora da forma canonica minuscula (auto-fix)")
  }
  if (!dReabrir && (STATUS == "Draft" || STATUS == "Review"))
    emit("WARNING", "plan-dec-sem-reabrir", cur_dec " sem linha **Reabrir se**: (4.97)")
  if (dReabrir && reabrirNunca)
    emit("WARNING", "plan-reabrir-nunca-sem-motivo", cur_dec ": **Reabrir se**: nunca sem motivo apos o travessao")
  cur_dec = ""
}
{ line = $0; sub(/\r$/, "", line) }

sect == "" && line ~ /^\*\*[A-Z]/ {
  if (line ~ /^\*\*Slug\*\*[ \t]*:/)   { v = line; sub(/^[^:]*:/, "", v); if (trim(v) != "") hSlug = 1 }
  if (line ~ /^\*\*Status\*\*[ \t]*:/) { hStatus = 1; v = line; sub(/^[^:]*:/, "", v); STATUS = trim(v) }
  if (line ~ /^\*\*Vers/)              { hVers = 1 }
  if (line ~ /^\*\*Autor\*\*[ \t]*:/)  { hAutor = 1 }
  if (line ~ /^\*\*Data\*\*[ \t]*:/)   { hData = 1; v = trim(line); sub(/^[^:]*:[ \t]*/, "", v)
    if (v !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) dataFmt = 1 }
}

/^## / {
  flushdec()
  h = trim(substr(line, 4))
  cur_comp = ""
  if (h ~ /^Ader/)      { sAder = 1; sect = "ader"; next }
  if (h ~ /^Cobertura/) { sCob = 1;  sect = "cob";  next }
  if (h ~ /^[0-9]+\./) {
    n = h + 0
    sec[n] = 1; sect = n
    next
  }
  sect = "x"; next
}
/^### / {
  flushdec()
  h = trim(substr(line, 5))
  cur_comp = ""
  if (h ~ /^DEC-/ && match(h, /DEC-[0-9]+-[0-9]+/)) {
    cur_dec = substr(h, RSTART, RLENGTH)
    dCtx = dDec = dAlt = dCons = dIrr = dReabrir = 0; nAlt = 0; irrval = ""; reabrirNunca = 0
    altmode = 0
    checkid(cur_dec)
    next
  }
  if (h ~ /^COMP-/ && match(h, /COMP-[0-9]+-[0-9]+/)) { checkid(substr(h, RSTART, RLENGTH)); next }
  if (h ~ /^TRISK-/ && match(h, /TRISK-[0-9]+-[0-9]+/)) { checkid(substr(h, RSTART, RLENGTH)); next }
  next
}

# bloco DEC
cur_dec != "" {
  if (line ~ /^\*\*Contexto\*\*[ \t]*:/)      { dCtx = 1; altmode = 0 }
  else if (line ~ /^\*\*Decis/)               { dDec = 1; altmode = 0 }
  else if (line ~ /^\*\*Alternativas/)        { dAlt = 1; altmode = 1 }
  else if (line ~ /^\*\*Consequ/)             { dCons = 1; altmode = 0 }
  else if (line ~ /^\*\*Irrevers/)            { dIrr = 1; altmode = 0
    v = line; sub(/^[^:]*:[ \t]*/, "", v); irrval = trim(v) }
  else if (line ~ /^\*\*Reabrir se\*\*[ \t]*:/) { dReabrir = 1; altmode = 0
    v = line; sub(/^[^:]*:[ \t]*/, "", v); v = trim(v)
    if (tolower(v) ~ /^nunca/ && v !~ /nunca[ \t]*\342\200\224[ \t]*[^ \t]/ && v !~ /nunca[ \t]*-[ \t]*[^ \t]/) reabrirNunca = 1 }
  else if (line ~ /^\*\*/)                    { altmode = 0 }
  else if (altmode && line ~ /^[-*] /)        { nAlt++ }
  next
}

# cobertura
sect == "cob" {
  if (line ~ /^\*\*SPEC referenciada\*\*[ \t]*:/) {
    v = line; sub(/^[^:]*:/, "", v)
    if (trim(v) != "") temSpecRef = 1
  }
  if (line ~ /^\*\*FRs cobertos\*\*/) {
    v = line; sub(/^[^:]*:/, "", v)
    if (trim(v) != "") temFR = 1
    frmode = 1
    next
  }
  if (line ~ /^\*\*Cobertura agregada/) { temAgg = 1; frmode = 0; next }
  if (line ~ /^\*\*/) { frmode = 0; next }
  if (frmode && line ~ /^- /) temFR = 1
  next
}

# secao 7: mapeamento
sect == 7 && line ~ /^\|/ {
  n = split(line, c, "|")
  if (n >= 3 && trim(c[2]) ~ /^(FR|NFR)-[0-9]+-[0-9]+$/) nmap++
  next
}

# secao 9: DoD
sect == 9 {
  if (line ~ /^- /) ndod++
  if (index(line, "<preencher>") > 0) dodPre = 1
  dod = dod " " tolower(line)
  next
}

function checkid(id,   parts, n, mmm, xxx) {
  n = split(id, parts, "-")
  mmm = parts[n-1]; xxx = parts[n]
  if (PLANM != "" && mmm + 0 != PLANM + 0)
    emit("ERROR", "plan-id-fora-do-numero", id ": MMM (" mmm ") difere do numero do PLAN (" PLANM ")")
  if (length(xxx) != 3)
    emit("WARNING", "plan-id-zero-pad", id ": XXX sem zero-padding de 3 digitos")
}

END {
  flushdec()
  if (!hSlug)   emit("ERROR", "plan-campo-ausente", "campo **Slug**: ausente ou vazio")
  if (!hStatus) emit("ERROR", "plan-campo-ausente", "campo **Status**: ausente")
  else if (STATUS !~ /^(Draft|Review|Approved|Done)$/)
    emit("ERROR", "plan-status-enum", "Status \"" STATUS "\" fora de {Draft, Review, Approved, Done}")
  if (!hVers)  emit("ERROR", "plan-campo-ausente", "campo **Versao**: ausente")
  if (!hAutor) emit("ERROR", "plan-campo-ausente", "campo **Autor**: ausente")
  if (!hData)  emit("ERROR", "plan-campo-ausente", "campo **Data**: ausente")
  else if (dataFmt) emit("WARNING", "plan-data-formato", "Data fora do formato YYYY-MM-DD")
  if (!sAder) emit("ERROR", "plan-secao-ausente", "secao \"## Aderencia a guidelines\" ausente")
  if (!sCob)  emit("ERROR", "plan-secao-ausente", "secao \"## Cobertura\" ausente")
  for (i = 1; i <= 10; i++)
    if (!(i in sec)) emit("ERROR", "plan-secao-ausente", "secao \"## " i ".\" ausente")
  if (sCob) {
    if (!temSpecRef) emit("ERROR", "plan-cobertura-sem-spec", "Cobertura sem **SPEC referenciada**:")
    if (!temFR)      emit("ERROR", "plan-frs-cobertos-vazio", "lista **FRs cobertos**: vazia")
    if (!temAgg)     emit("ERROR", "plan-cobertura-agregada-ausente", "**Cobertura agregada do slug**: ausente")
  }
  if ((7 in sec) && nmap == 0) emit("ERROR", "plan-mapeamento-vazio", "secao 7 sem nenhuma linha FR -> componente")
  if (9 in sec) {
    if (ndod == 0)  emit("ERROR", "plan-dod-vazia", "Definition of Done (secao 9) sem itens")
    if (dodPre)     emit("ERROR", "plan-dod-placeholder", "Definition of Done com <preencher>")
    if (ndod > 0 && dod !~ /test|cobertura/)
      emit("WARNING", "plan-dod-sem-teste", "DoD nao menciona cobertura de teste")
    if (ndod > 0 && dod !~ /ficha|perfil|guideline/)
      emit("WARNING", "plan-dod-sem-perfil", "DoD nao menciona aderencia a ficha/perfil")
  }
}
AWK

# ---------- awk: TASK ----------
cat > "$TMP/task.awk" <<'AWK'
function emit(sev, chk, det) {
  if (sev == "ERROR" && STATUS == "Done") { sev = "WARNING"; det = det " [legacy]" }
  printf "%s\t%s\t%s (%s)\n", sev, chk, det, FILE
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
{ line = $0; sub(/\r$/, "", line) }

sect == "" && line ~ /^\*\*[A-Z]/ {
  if (line ~ /^\*\*Slug\*\*[ \t]*:/)     { v = line; sub(/^[^:]*:/, "", v); if (trim(v) != "") hSlug = 1 }
  if (line ~ /^\*\*Status\*\*[ \t]*:/)   { hStatus = 1; v = line; sub(/^[^:]*:/, "", v); STATUS = trim(v) }
  if (line ~ /^\*\*Wave\*\*[ \t]*:/)     { hWave = 1; v = line; sub(/^[^:]*:/, "", v); WAVE = trim(v) }
  if (line ~ /^\*\*Tamanho estimado\*\*[ \t]*:/) { hTam = 1; v = line; sub(/^[^:]*:/, "", v); TAM = trim(v) }
  if (line ~ /^\*\*Tipo\*\*[ \t]*:/)     { hTipo = 1; v = line; sub(/^[^:]*:/, "", v); TIPO = trim(v) }
  if (line ~ /^\*\*AC violado\*\*[ \t]*:/) { v = line; sub(/^[^:]*:/, "", v); if (trim(v) != "") temACV = 1 }
  if (line ~ /^\*\*Funcionalidade\*\*[ \t]*:/) {
    v = line; sub(/^[^:]*:/, "", v); FUNC = trim(v)
  }
  if (line ~ /^\*\*Realiza \(FRs\)\*\*[ \t]*:/) {
    v = line; sub(/^[^:]*:/, "", v); REALIZA = trim(v)
  }
}

/^## / {
  h = trim(substr(line, 4))
  if (h ~ /^Conven/)       { sConv = 1; sect = "conv"; next }
  if (h ~ /^Depend/)       { sDep = 1;  sect = "dep";  next }
  if (h ~ /^Contexto/)     { sCtx = 1;  sect = "ctx";  next }
  if (h ~ /^Escopo/)       { sEsc = 1;  sect = "esc";  next }
  if (h ~ /^Implementa/)   { sImpl = 1; sect = "impl"; next }
  if (h ~ /^Crit/)         { sCrit = 1; sect = "crit"; next }
  if (h ~ /^Roteiro do gate 9/) { sect = "gate9"; next }
  if (h ~ /^Riscos/)       { sRisc = 1; sect = "risc"; next }
  if (h ~ /^Hist/)         { sHist = 1; sect = "hist"; next }
  sect = "x"; next
}
/^### / {
  h = trim(substr(line, 5))
  if (sect == "esc" && h ~ /^Inclui/) { sInc = 1; subq = "inc"; next }
  if (sect == "esc" && h ~ /inclui/)  { sNInc = 1; subq = "ninc"; next }
  subq = ""
  next
}

sect == "dep" && line ~ /^- \*\*Depende de\*\*[ \t]*:/ {
  v = line; sub(/^[^:]*:/, "", v); DEP = trim(v); next
}
sect == "crit" && line ~ /^- \[[ xX]\]/ {
  ncrit++
  crit = crit " " line
  next
}
sect == "gate9" { g9 = g9 " " line; next }
sect == "hist" {
  if (line ~ /^- \[ \]/) {
    if (index(line, "aprovado (wave") == 0 && index(line, "consolidado (") == 0) nGateAberto++
  }
  next
}

END {
  if (!hSlug)   emit("ERROR", "task-campo-ausente", "campo **Slug**: ausente ou vazio")
  if (!hStatus) emit("ERROR", "task-campo-ausente", "campo **Status**: ausente")
  else if (STATUS !~ /^(Todo|In Progress|Done|Blocked)$/)
    emit("ERROR", "task-status-enum", "Status \"" STATUS "\" fora de {Todo, In Progress, Done, Blocked}")
  if (!hWave) emit("ERROR", "task-campo-ausente", "campo **Wave**: ausente")
  if (!hTam)  emit("ERROR", "task-campo-ausente", "campo **Tamanho estimado**: ausente")
  else if (TAM !~ /^(small|medium)$/)
    emit("ERROR", "task-tamanho-enum", "Tamanho estimado \"" TAM "\" fora de {small, medium}")
  if (!hTipo) emit("WARNING", "task-tipo-ausente", "campo **Tipo**: ausente (auto-fix: feature)")
  else if (TIPO !~ /^(feature|bugfix|refactor|chore)$/)
    emit("ERROR", "task-tipo-enum", "Tipo \"" TIPO "\" fora de {feature, bugfix, refactor, chore}")
  if (!sConv) emit("ERROR", "task-secao-ausente", "secao \"## Convencoes (do projeto)\" ausente")
  if (!sDep)  emit("ERROR", "task-secao-ausente", "secao \"## Dependencias\" ausente")
  if (!sCtx)  emit("ERROR", "task-secao-ausente", "secao \"## Contexto\" ausente")
  if (!sEsc)  emit("ERROR", "task-secao-ausente", "secao \"## Escopo\" ausente")
  else {
    if (!sInc)  emit("ERROR", "task-secao-ausente", "subsecao \"### Inclui\" ausente")
    if (!sNInc) emit("ERROR", "task-secao-ausente", "subsecao \"### Nao inclui\" ausente")
  }
  if (!sImpl) emit("ERROR", "task-secao-ausente", "secao \"## Implementacao sugerida\" ausente")
  if (!sCrit) emit("ERROR", "task-secao-ausente", "secao \"## Criterios de pronto\" ausente")
  if (!sRisc) emit("ERROR", "task-secao-ausente", "secao \"## Riscos especificos\" ausente")
  if (!sHist) emit("ERROR", "task-secao-ausente", "secao \"## Historico de execucao\" ausente")
  # nome do arquivo vs tipo
  if (TIPO == "bugfix" && FILE !~ /-fix-/)
    emit("WARNING", "task-nome-tipo", "Tipo bugfix sem marcador -fix- no nome do arquivo")
  if (TIPO == "refactor" && FILE !~ /-refactor-/)
    emit("WARNING", "task-nome-tipo", "Tipo refactor sem marcador -refactor- no nome do arquivo")
  if (TIPO == "chore" && FILE !~ /-chore-/)
    emit("WARNING", "task-nome-tipo", "Tipo chore sem marcador -chore- no nome do arquivo")
  # wave 2+ sem dependencia
  ldep = tolower(DEP)
  if (WAVE + 0 >= 2 && (DEP == "" || ldep == "nenhuma" || ldep == "nenhum" || ldep == "n/a" || ldep == "-"))
    emit("WARNING", "task-wave2-sem-dep", "Wave " WAVE " sem nenhuma dependencia declarada (suspeito)")
  # funcionalidade: primaria/transversal
  if (FUNC != "" && tolower(FUNC) !~ /^transversal/) {
    nfe = 0
    s = FUNC
    while (match(s, /FEAT-[0-9]+-[0-9]+/)) { nfe++; s = substr(s, RSTART + RLENGTH) }
    if (nfe >= 2 && index(FUNC, "(prim") == 0)
      emit("ERROR", "task-feat-sem-primaria", "2+ FEATs em Funcionalidade sem (primaria) nem forma transversal")
  }
  if (FUNC != "" && tolower(FUNC) ~ /^transversal/) {
    nfe = 0
    s = FUNC
    while (match(s, /FEAT-[0-9]+-[0-9]+/)) { nfe++; s = substr(s, RSTART + RLENGTH) }
    if (nfe < 2)
      emit("ERROR", "task-feat-transversal-uma", "forma transversal com apenas " nfe " FEAT (transversal exige 2+)")
  }
  # criterios de pronto
  if (sCrit && ncrit == 0) emit("ERROR", "task-criterios-vazios", "secao \"Criterios de pronto\" sem itens de checklist")
  else if (sCrit && REALIZA != "" && tolower(REALIZA) !~ /^(nenhuma|nenhum|n\/a|-)$/ && index(crit g9, "AC-") == 0)
    emit("ERROR", "task-criterio-sem-ac", "nenhum criterio de pronto ou roteiro do gate 9 menciona AC")
  # tipo especifico
  if (TIPO == "bugfix" && !temACV) {
    if (REALIZA ~ /\/ *AC-/ || REALIZA ~ /AC-[0-9]/)
      emit("INFO", "task-bugfix-forma-legada", "AC violado na forma antiga dentro de Realiza (FRs) — nao reprova")
    else
      emit("ERROR", "task-bugfix-sem-ac-violado", "Tipo bugfix sem campo **AC violado**: preenchido")
  }
  if (TIPO == "refactor" && index(tolower(crit), "comportamento observ") == 0)
    emit("ERROR", "task-refactor-sem-identidade", "Tipo refactor sem criterio \"comportamento observavel identico\"")
  # done com gate aberto
  if (STATUS == "Done" && nGateAberto > 0)
    emit("WARNING", "task-done-gate-aberto", nGateAberto " item(ns) de Quality gates desmarcado(s) sem consolidacao declarada (4.90)")
}
AWK

# lista de tecnologia da Etapa 5 do spec-validator (dono da lista: o SKILL.md)
TECH='PHP|Python|Java|JavaScript|TypeScript|Ruby|Go|Rust|Node.js|.NET|Vue|React|Angular|Laravel|Symfony|Django|Flask|Spring|Rails|Express|FastAPI|MySQL|PostgreSQL|MongoDB|Redis|Elasticsearch|DynamoDB|BigQuery|REST|GraphQL|gRPC|WebSocket|microservice|monolith|event-sourcing|CQRS|AWS|GCP|Azure|Lambda|S3|EC2|Cloud Run|Kubernetes|Docker|jQuery|Axios|Lodash|Pinia|Vuex|Redux'

lint_file() { # $1 = caminho
  f="$1"
  b="$(basename "$f")"
  case "$b" in
    SPEC-*.md)
      n="$(printf '%s\n' "$b" | sed -n 's/^SPEC-\([0-9][0-9]*\)[-.].*/\1/p')"
      awk -v FILE="$b" -v SPECN="$n" -v TECH="$TECH" -f "$TMP/spec.awk" "$f" >> "$OUT" ;;
    PLAN-*.md)
      n="$(printf '%s\n' "$b" | sed -n 's/^PLAN-\([0-9][0-9]*\)[-.].*/\1/p')"
      awk -v FILE="$b" -v PLANM="$n" -f "$TMP/plan.awk" "$f" >> "$OUT" ;;
    TASK-*-INDEX.md) : ;;
    TASK-*.md)
      awk -v FILE="$b" -f "$TMP/task.awk" "$f" >> "$OUT" ;;
    *)
      die2 "não reconheço o tipo de artefato: $f (esperado SPEC-*.md, PLAN-*.md ou TASK-*.md)" ;;
  esac
}

# overlap de FR entre PLANs e entre TASKs do mesmo PLAN (só no modo diretório)
lint_dir_cross() { # $1 = dir do slug
  d="$1"
  for f in "$d"/plans/PLAN-*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    awk -v FILE="$b" '
      /^## / { on = ($0 ~ /^## Cobertura/) ? 1 : 0; frmode = 0 }
      on && /^\*\*FRs cobertos\*\*/ {
        v = $0; sub(/^[^:]*:/, "", v)
        while (match(v, /FR-[0-9]+-[0-9]+/)) { print substr(v, RSTART, RLENGTH) "\t" FILE; v = substr(v, RSTART + RLENGTH) }
        frmode = 1; next
      }
      on && /^\*\*/ { frmode = 0 }
      on && frmode && /^- / {
        v = $0
        if (match(v, /FR-[0-9]+-[0-9]+/)) print substr(v, RSTART, RLENGTH) "\t" FILE
      }
    ' "$f"
  done > "$TMP/plancov.tsv"
  awk -F'\t' '
    { seen[$1] = ($1 in seen) ? seen[$1] ", " $2 : $2; cnt[$1]++ }
    END { for (fr in cnt) if (cnt[fr] > 1)
      printf "WARNING\tplan-overlap-fr\t%s coberto por %d PLANs (%s) — overlap nao justificado?\n", fr, cnt[fr], seen[fr] }
  ' "$TMP/plancov.tsv" >> "$OUT"

  for f in "$d"/tasks/TASK-*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    case "$b" in *-INDEX.md) continue ;; esac
    m="$(printf '%s\n' "$b" | sed -n 's/^TASK-\([0-9][0-9]*\)-[0-9][0-9]*[-.].*/\1/p')"
    [ -n "$m" ] || continue
    awk -v FILE="$b" -v M="$m" '
      /^\*\*Realiza \(FRs\)\*\*[ \t]*:/ {
        v = $0; sub(/^[^:]*:/, "", v)
        while (match(v, /FR-[0-9]+-[0-9]+/)) { print M "\t" substr(v, RSTART, RLENGTH) "\t" FILE; v = substr(v, RSTART + RLENGTH) }
      }
    ' "$f"
  done > "$TMP/taskcov.tsv"
  awk -F'\t' '
    { k = $1 SUBSEP $2; seen[k] = (k in seen) ? seen[k] ", " $3 : $3; cnt[k]++; fr[k] = $2 }
    END { for (k in cnt) if (cnt[k] > 1)
      printf "WARNING\ttask-overlap-fr\t%s realizado por %d TASKs do mesmo PLAN (%s)\n", fr[k], cnt[k], seen[k] }
  ' "$TMP/taskcov.tsv" >> "$OUT"
}

for arg in "$@"; do
  if [ -d "$arg" ]; then
    found=0
    for f in "$arg"/specs/SPEC-*.md "$arg"/plans/PLAN-*.md "$arg"/tasks/TASK-*.md; do
      [ -f "$f" ] || continue
      case "$(basename "$f")" in *-INDEX.md) continue ;; esac
      found=1
      lint_file "$f"
    done
    [ "$found" = 1 ] || die2 "nenhum artefato SDD em: $arg"
    lint_dir_cross "$arg"
  elif [ -f "$arg" ]; then
    lint_file "$arg"
  else
    die2 "caminho não existe: $arg"
  fi
done

sort "$OUT"
if grep -q '^ERROR' "$OUT"; then exit 1; fi
exit 0
