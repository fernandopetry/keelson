#!/usr/bin/env bash
# run.sh — suíte de regressão do pause.sh (decisão 4.382).
#
# Cada caso monta um BRIEF sintético e compara a saída com a esperada inline. Regras
# provadas: a linha `- pausa:` entra no FIM da `## Cronologia` (antes do próximo
# heading, blanks internos preservados, blanks finais descartados) e no fim do arquivo
# quando a seção fecha o BRIEF; campo `sessão <sid8>@<host>` degrada sem id/host e é
# omitido sem os dois; motivo omitido quando ausente; brief avulso sem a seção ganha
# `## Cronologia` (aditivo, aviso) e o graph.sh continua limpo sobre ele (H6 do mapa);
# resolve-brief escolhe o BRIEF ativo de maior número (épico, Aceito e Concluído fora),
# exit 3 sem candidato; mark-resume mede a pausa marcada, cai no piso (--since rotulado
# ou último commit do git, com sha) e declara lacuna sem nenhum dos dois; janela
# negativa vira WARNING sem duração; report agrega marcada/piso/aberta com cauda, sai
# vazio sem marcas, ignora linha não-parseável com WARNING; offset ±HH:MM normalizado;
# exits 2 de uso incorreto.
#
# Uso: scripts/tests/pause/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
P="$HERE/../../pause.sh"
G="$HERE/../../graph.sh"

[ -f "$P" ] || { echo "ERRO: pause.sh não encontrado em $P" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

ok()  { total=$((total + 1)); echo "ok   $1"; }
bad() { total=$((total + 1)); fail=$((fail + 1)); echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  /'; }
eq() { # nome esperado obtido
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$(printf -- '--- esperado ---\n%s\n--- obtido ---\n%s' "$2" "$3")"; fi
}
contem()    { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1: não contém [$3]" "$2"; fi; }
naocontem() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1: contém [$3]" "$2"; else ok "$1"; fi; }
exitis()    { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: exit $3 (esperado $2)"; fi; }

# pz <sessao> <raiz> <args…> — sessão fixada, sem vazamento do ambiente real
pz() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$P" "$@"; }

brief_formal() { # $1 caminho · $2 status · $3 = "eof" (Cronologia fecha o arquivo) | "estimativa"
  {
    printf '# BRIEF-003: demanda\n\n**Slug**: alpha\n**Status**: %s\n**Data**: 2026-09-01\n' "$2"
    printf '**Largada**: 2026-09-01T09:00:00-0300\n**SPEC**: SPEC-003\n\n## Pedido como dito\nfazer\n\n'
    printf '## Cronologia\n- specify: 2026-09-01T10:00:00-0300 · correções: 0\n\n- plan: 2026-09-01T11:00:00-0300\n\n\n'
    [ "$3" = "estimativa" ] && printf '## Estimativa\n- waves: ~2\n'
  } > "$1"
}

# ---------- 1. mark-pause: fim da Cronologia, antes do próximo heading ----------
R1="$TMP/r1"; mkdir -p "$R1/docs/alpha/briefs"
B1="$R1/docs/alpha/briefs/BRIEF-003-demanda.md"; brief_formal "$B1" Emitido estimativa
out="$(pz abcdef12-3456-7890 "$R1" mark-pause alpha --ponto "TASK-003-002 closure (wave 1 de 3)" --motivo "fim do dia" --ts 2026-09-06T18:30:00-0300 --host mac-a 2>"$TMP/err")"; st=$?
exitis "1. mark-pause exit 0" 0 "$st"
eq "1. saída brief/linha" "$(printf 'brief\tdocs/alpha/briefs/BRIEF-003-demanda.md\nlinha\t- pausa: 2026-09-06T18:30:00-0300 · sessão abcdef12@mac-a · ponto: TASK-003-002 closure (wave 1 de 3) · motivo: fim do dia')" "$out"
want="$(printf '# BRIEF-003: demanda\n\n**Slug**: alpha\n**Status**: Emitido\n**Data**: 2026-09-01\n**Largada**: 2026-09-01T09:00:00-0300\n**SPEC**: SPEC-003\n\n## Pedido como dito\nfazer\n\n## Cronologia\n- specify: 2026-09-01T10:00:00-0300 · correções: 0\n\n- plan: 2026-09-01T11:00:00-0300\n- pausa: 2026-09-06T18:30:00-0300 · sessão abcdef12@mac-a · ponto: TASK-003-002 closure (wave 1 de 3) · motivo: fim do dia\n\n## Estimativa\n- waves: ~2')"
eq "1. BRIEF: linha antes do heading seguinte, blank interno preservado, blanks finais fora" "$want" "$(cat "$B1")"
[ -s "$TMP/err" ] && bad "1. stderr deveria ser vazio" "$(cat "$TMP/err")" || ok "1. sem aviso"

# ---------- 2. mark-pause: Cronologia fecha o arquivo; sem motivo; sessão degradada ----------
R2="$TMP/r2"; mkdir -p "$R2/docs/alpha/briefs"
B2="$R2/docs/alpha/briefs/BRIEF-003-demanda.md"; brief_formal "$B2" Emitido eof
out="$(pz "" "$R2" mark-pause alpha --ponto "SPEC-003 Draft" --ts 2026-09-06T18:30:00-03:00 --host " " 2>/dev/null)"; st=$?
exitis "2. exit 0" 0 "$st"
contem "2. offset -03:00 normalizado" "$out" "- pausa: 2026-09-06T18:30:00-0300 · ponto: SPEC-003 Draft"
naocontem "2. sem motivo → sem campo" "$out" "motivo:"
naocontem "2. sem id nem host → campo sessão omitido" "$out" "sessão"
eq "2. linha no fim do arquivo, blanks finais descartados" "- pausa: 2026-09-06T18:30:00-0300 · ponto: SPEC-003 Draft" "$(tail -n 1 "$B2")"
out="$(pz "" "$R2" mark-pause alpha --ponto x --ts 2026-09-06T19:00:00-0300 --host mac-b 2>/dev/null)"
contem "2. só host → 'host <nome>'" "$out" "· host mac-b ·"
out="$(pz sid-only "$R2" mark-pause alpha --ponto x --ts 2026-09-06T19:10:00-0300 --host " " 2>/dev/null)"
contem "2. só id → 'sessão <sid8>' sem @" "$out" "· sessão sidonly ·"

# ---------- 3. brief avulso sem a seção: aditivo + graph.sh limpo (H6) ----------
R3="$TMP/r3"; mkdir -p "$R3/docs/beta/briefs"
B3="$R3/docs/beta/briefs/BRIEF-007-ajuste-avulso.md"
printf '# BRIEF-007: ajuste\n\n**Slug**: beta\n**Tipo**: avulso\n**Status**: Aberto\n**Data**: 2026-09-05\n**Largada**: 2026-09-05T14:00:00-0300\n\n## Pedido como dito\nx\n\n## Criterio de aceite\n- observável\n\n## TASKs\nnenhuma' > "$B3"
out="$(pz s3 "$R3" mark-pause beta --ponto "commit a1b2c3d" --ts 2026-09-05T16:00:00-0300 --host h 2>"$TMP/err")"; st=$?
exitis "3. exit 0" 0 "$st"
contem "3. aviso de seção criada" "$(cat "$TMP/err")" "seção criada"
eq "3. seção anexada no fim" "$(printf '## TASKs\nnenhuma\n\n## Cronologia\n- pausa: 2026-09-05T16:00:00-0300 · sessão s3@h · ponto: commit a1b2c3d')" "$(tail -n 5 "$B3")"
if [ -f "$G" ]; then
  gout="$(bash "$G" "$R3/docs/beta" --check 2>&1)"; gst=$?
  exitis "3. graph.sh --check sem ERROR sobre o avulso com Cronologia" 0 "$gst"
  naocontem "3. graph.sh não acusa o brief" "$gout" "BRIEF-007"
else
  echo "aviso: graph.sh ausente — H6 não conferida." >&2
fi

# ---------- 4. resolve-brief ----------
R4="$TMP/r4"; mkdir -p "$R4/docs/gamma/briefs"
printf '# BRIEF-001: a\n**Status**: Aceito\n' > "$R4/docs/gamma/briefs/BRIEF-001-a.md"
printf '# BRIEF-002: b\n**Status**: Emitido\n' > "$R4/docs/gamma/briefs/BRIEF-002-b.md"
printf '# BRIEF-004: c\n**Status**: Emitido\n' > "$R4/docs/gamma/briefs/BRIEF-004-c.md"
printf '# BRIEF-005: d\n**Status**: Concluído\n' > "$R4/docs/gamma/briefs/BRIEF-005-d-avulso.md"
printf '# BRIEF épico\n**Status**: em execução\n' > "$R4/docs/gamma/briefs/BRIEF-2026-09-01-x-epic.md"
eq "4. maior número ativo, épico/Aceito/Concluído fora" "docs/gamma/briefs/BRIEF-004-c.md" "$(pz s4 "$R4" resolve-brief gamma)"
printf '{ "docsRoot": "documentacao" }\n' > "$R4/keelson.config.json"
mkdir -p "$R4/documentacao/gamma/briefs"; printf '# BRIEF-009: e\n**Status**: Aberto\n' > "$R4/documentacao/gamma/briefs/BRIEF-009-e-avulso.md"
eq "4. docsRoot da ficha" "documentacao/gamma/briefs/BRIEF-009-e-avulso.md" "$(pz s4 "$R4" resolve-brief gamma)"
out="$(pz s4 "$R4" resolve-brief delta 2>"$TMP/err")"; st=$?
exitis "4. sem candidato → exit 3" 3 "$st"
contem "4. causa nomeada" "$(cat "$TMP/err")" "nenhum BRIEF ativo"
out="$(pz s4 "$R4" mark-pause delta --ponto x 2>"$TMP/err")"; st=$?
exitis "4. mark-pause sem BRIEF → exit 3, nada gravado" 3 "$st"
contem "4. degradação declara a validade por-clone" "$(cat "$TMP/err")" "por-clone"

# ---------- 5. mark-resume: marcada · piso --since · piso git · lacuna ----------
out="$(pz r5 "$R1" mark-resume alpha --ts 2026-09-07T09:12:00-0300 --host mac-b 2>"$TMP/err")"; st=$?
exitis "5. resume exit 0" 0 "$st"
contem "5. retomada mede a pausa marcada" "$out" "- retomada: 2026-09-07T09:12:00-0300 · sessão r5@mac-b · parado desde 2026-09-06T18:30:00-0300 (marcada) · 14h42min"
[ -s "$TMP/err" ] && bad "5. sem aviso na marcada" "$(cat "$TMP/err")" || ok "5. sem aviso na marcada"
out="$(pz r5 "$R1" mark-resume alpha --ts 2026-09-07T10:00:00-0300 --host mac-b --since 2026-09-07T09:40:00-0300 --since-label "último commit 1234abc" 2>/dev/null)"
contem "5. sem pausa aberta → piso --since rotulado" "$out" "parado desde 2026-09-07T09:40:00-0300 (piso: último commit 1234abc) · 0h20min"
# piso via git: repo com 1 commit datado
R5="$TMP/r5"; mkdir -p "$R5/docs/alpha/briefs"; brief_formal "$R5/docs/alpha/briefs/BRIEF-003-demanda.md" Emitido eof
( cd "$R5" && git init -q . && git config user.email t@t && git config user.name t \
  && GIT_AUTHOR_DATE="2026-09-06T20:00:00-03:00" GIT_COMMITTER_DATE="2026-09-06T20:00:00-03:00" git add -A >/dev/null && \
  GIT_AUTHOR_DATE="2026-09-06T20:00:00-03:00" GIT_COMMITTER_DATE="2026-09-06T20:00:00-03:00" git commit -qm "chore: base" )
sha="$(cd "$R5" && git rev-parse --short HEAD)"
out="$(pz r5 "$R5" mark-resume alpha --ts 2026-09-07T08:00:00-0300 --host mac-c 2>/dev/null)"
contem "5. piso pelo último commit do git, com sha" "$out" "parado desde 2026-09-06T20:00:00-0300 (piso: último commit $sha) · 12h00min"
# lacuna: sem pausa, sem --since, sem git
out="$(pz r5 "$R2" mark-resume alpha --ts 2026-09-07T08:00:00-0300 --host h 2>"$TMP/err")"; st=$?
exitis "5. lacuna exit 0" 0 "$st"
# R2 tem pausa aberta (caso 2) → primeiro resume fecha a marcada; segundo é a lacuna
out="$(pz r5 "$R2" mark-resume alpha --ts 2026-09-07T08:30:00-0300 --host h 2>"$TMP/err")"
contem "5. sem marca nem commit → lacuna declarada" "$out" "parado desde — (sem marca nem commit legível)"
contem "5. aviso da lacuna" "$(cat "$TMP/err")" "lacuna"
# janela negativa
R6="$TMP/r6"; mkdir -p "$R6/docs/alpha/briefs"; brief_formal "$R6/docs/alpha/briefs/BRIEF-003-demanda.md" Emitido eof
pz s6 "$R6" mark-pause alpha --ponto p --ts 2026-09-06T18:00:00-0300 --host h >/dev/null 2>&1
out="$(pz s6 "$R6" mark-resume alpha --ts 2026-09-06T17:00:00-0300 --host h 2>"$TMP/err")"
contem "5. janela negativa → WARNING" "$(cat "$TMP/err")" "WARNING janela-negativa"
naocontem "5. janela negativa → sem duração" "$out" "min"
# pausa já aberta → aviso, linha entra (a retomada negativa acima fechou a anterior)
pz s6 "$R6" mark-pause alpha --ponto q --ts 2026-09-06T19:00:00-0300 --host h >/dev/null 2>&1
out="$(pz s6 "$R6" mark-pause alpha --ponto r --ts 2026-09-06T19:30:00-0300 --host h 2>"$TMP/err")"; st=$?
exitis "5. segunda pausa sobre aberta: exit 0" 0 "$st"
contem "5. aviso de pausa aberta" "$(cat "$TMP/err")" "já há pausa aberta em 2026-09-06T19:00:00-0300"
contem "5. linha entra mesmo assim" "$out" "ponto: r"

# ---------- 6. report: marcada + piso + aberta + cauda ----------
R7="$TMP/r7"; mkdir -p "$R7/docs/alpha/briefs"
B7="$R7/docs/alpha/briefs/BRIEF-003-demanda.md"
{
  printf '# BRIEF-003: demanda\n\n**Status**: Emitido\n\n## Cronologia\n- specify: 2026-09-01T10:00:00-0300\n'
  printf -- '- pausa: 2026-09-01T18:00:00-0300 · sessão a@h · ponto: SPEC-003 Draft\n'
  printf -- '- retomada: 2026-09-02T09:00:00-03:00 · sessão b@h · parado desde 2026-09-01T18:00:00-0300 (marcada) · 15h00min\n'
  printf -- '- plan: 2026-09-02T11:00:00-0300\n'
  printf -- '- retomada: 2026-09-03T08:30:00-0300 · sessão c@h2 · parado desde 2026-09-02T20:00:00-0300 (piso: último commit abc1234) · 12h30min\n'
  printf -- '- tasks: 2026-09-03T10:00:00-0300\n'
  printf -- '- pausa: 2026-09-03T17:45:00-0300 · sessão c@h2 · ponto: TASK-003-001 closure (wave 1 de 2) · motivo: reunião\n'
  printf -- '- pausa: sem data legível · ponto: x\n'
  printf '\n## Estimativa\n- pausa: 2026-09-09T09:00:00-0300 fora da seção, ignorada\n'
} > "$B7"
out="$(pz s7 "$R7" report docs/alpha/briefs/BRIEF-003-demanda.md 2>"$TMP/err")"; st=$?
exitis "6. report exit 0" 0 "$st"
want="$(printf 'pausa\t2026-09-01T18:00:00-0300\t2026-09-02T09:00:00-0300\t900\tmarcada\npausa\t2026-09-02T20:00:00-0300\t2026-09-03T08:30:00-0300\t750\tpiso: último commit abc1234\npausa\t2026-09-03T17:45:00-0300\tsem-retomada\t-\taberta\npausas\t3\tparado\t1650\t27h30min\t1 marcadas\t1 piso\t1 abertas\ncauda\tpausas: 3 · parado ~27h30min (1 marcadas, 1 piso) · 1 sem retomada marcada')"
eq "6. TSV agregado" "$want" "$out"
contem "6. linha não-parseável → WARNING" "$(cat "$TMP/err")" "WARNING nao-parseavel"
eq "6. report por slug resolve o BRIEF ativo" "$out" "$(pz s7 "$R7" report alpha 2>/dev/null)"
# vazio: Cronologia sem marca
brief_formal "$TMP/vazio.md" Emitido eof
out="$(pz s7 "$R2" report "$TMP/vazio.md" 2>/dev/null)"; st=$?
exitis "6. sem marca → exit 0" 0 "$st"
eq "6. sem marca → saída vazia" "" "$out"
# só abertas → parado —
R8="$TMP/r8"; mkdir -p "$R8"; printf '## Cronologia\n- pausa: 2026-09-01T18:00:00-0300 · ponto: p\n' > "$R8/b.md"
eq "6. só abertas → parado —" "$(printf 'pausa\t2026-09-01T18:00:00-0300\tsem-retomada\t-\taberta\npausas\t1\tparado\t-\t—\t0 marcadas\t0 piso\t1 abertas\ncauda\tpausas: 1 · parado — · 1 sem retomada marcada')" "$(pz s8 "$R8" report "$R8/b.md" 2>/dev/null)"
# janela negativa no report: fora da soma
printf '## Cronologia\n- pausa: 2026-09-01T18:00:00-0300 · ponto: p\n- retomada: 2026-09-01T17:00:00-0300 · parado desde 2026-09-01T18:00:00-0300 (marcada)\n' > "$R8/c.md"
out="$(pz s8 "$R8" report "$R8/c.md" 2>"$TMP/err")"
contem "6. janela negativa no report → WARNING" "$(cat "$TMP/err")" "WARNING janela-negativa"
contem "6. janela negativa fora da soma" "$out" "pausas: 1 · parado —"

# ---------- 7. uso incorreto ----------
pz s9 "$R1" nada alpha >/dev/null 2>&1; exitis "7. ação desconhecida → 2" 2 "$?"
pz s9 "$R1" mark-pause alpha >/dev/null 2>&1; exitis "7. mark-pause sem --ponto → 2" 2 "$?"
pz s9 "$R1" mark-pause "a/b" --ponto x >/dev/null 2>&1; exitis "7. slug inválido → 2" 2 "$?"
pz s9 "$R1" mark-pause alpha --ponto x --ts "2026-09-06 18:30" >/dev/null 2>&1; exitis "7. --ts fora do formato → 2" 2 "$?"
pz s9 "$R1" report >/dev/null 2>&1; exitis "7. report sem alvo → 2" 2 "$?"
pz s9 "$TMP/inexistente" report x >/dev/null 2>&1; exitis "7. raiz inexistente → 2" 2 "$?"
pz s9 "$R1" report "$TMP/nao-existe.md" >/dev/null 2>&1; exitis "7. BRIEF ilegível → 3" 3 "$?"

echo "pause: $((total - fail))/$total verdes"
[ "$fail" -eq 0 ]
