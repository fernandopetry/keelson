#!/usr/bin/env bash
# run.sh — suíte de regressão do ledger.sh (decisões 4.76/4.151/4.314).
#
# Casos inline em diretório temporário, com --ts fixo (determinismo) e ambiente
# de sessão SEMPRE controlado pelo wrapper lg(). Regras provadas: nome ordenável
# canônico, cabeçalho, catálogo fechado de tipos, sufixo de colisão, list/count,
# arquivamento preservando pendentes — tudo no caminho LEGADO quando não há id de
# sessão (carência 4.314 intacta); e, com id, escrita na casa da sessão
# (<casa>/ledger/, slug registrado no meta), agregação legado+casa em list/count
# e archive arquivando cada casa dentro de si mesma. `last` (4.365): evento mais
# recente do par tipo/origem entre casas, ativos e arquivados; `wave_sequencial`
# aceito no catálogo (4.301 — o script recusava o tipo que a convenção lista);
# `diff_id:` (4.378/4.379): `mark gate <origem>` mede a identidade do escopo no
# DESPACHO e grava a marca; o append consome a marca e grava o diff_id DELA (igual à
# identidade do --guard quando a árvore não mudou); árvore mudada entre marca e registro
# → `diff_id_nota:`; sem marca → sem linha; outro gate não ganha linha; --diff-id
# explícito substitui, `none` suprime; a linha vem depois de `ref:`; stdin diff_id
# descartado; imune a GIT_DIR herdado; worktree vinculado não marca (sem linha); mark
# para origem sem guard → exit 2 (o corpo congelado do append-corpo — raiz sem git —
# prova "sem escopo → sem linha").
#
# Uso: scripts/tests/ledger/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LG="$HERE/../../ledger.sh"

[ -f "$LG" ] || { echo "ERRO: ledger.sh não encontrado em $LG" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$LG" || { echo "FAIL bash -n ledger.sh"; exit 1; }
echo "ok   bash -n ledger.sh"

# lg — invocação com ambiente de sessão controlado ("" = modo legado)
lg() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$LG" "$@"; }

R="$TMP/repo"; mkdir -p "$R"
LD="$R/thoughts/local/session-ledger"
TS1="2026-08-06T14:23:10-0300"

# --- modo legado (sem id de sessão): comportamento pré-4.314 intacto ---

# append cria nome e cabeçalho canônicos e ecoa o caminho
total=$((total + 1))
f="$(printf 'TASK-003 aprovada no retry (gate 4)\n' | lg "" "$R" append gate code-reviewer meu-slug --ref docs/meu-slug/tasks/TASK-003.md --ts "$TS1" 2>/dev/null)"
if [ "$f" = "$LD/20260806-142310-gate-code-reviewer.md" ]; then ok append-nome; else falha "append-nome: [$f]"; fi
total=$((total + 1))
want="ts: $TS1 · tipo: gate · origem: code-reviewer · slug: meu-slug
TASK-003 aprovada no retry (gate 4)
ref: docs/meu-slug/tasks/TASK-003.md"
if [ "$(cat "$f" 2>/dev/null)" = "$want" ]; then ok append-corpo; else falha "append-corpo: [$(cat "$f" 2>/dev/null)]"; fi

# linha ts: duplicada no stdin (formato pré-4.151) é descartada — o cabeçalho é do
# script (4.156). Repo próprio para não poluir as contagens dos casos seguintes.
total=$((total + 1))
RTS="$TMP/repo-ts"; mkdir -p "$RTS"
fts="$(printf 'ts: 2026-01-01T00:00:00-0300 · tipo: gate · origem: qa · slug: meu-slug\ncorpo real do evento\n' | lg "" "$RTS" append gate qa meu-slug --ts "2026-08-06T14:23:11-0300" 2>/dev/null)"
want="ts: 2026-08-06T14:23:11-0300 · tipo: gate · origem: qa · slug: meu-slug
corpo real do evento"
if [ "$(cat "$fts" 2>/dev/null)" = "$want" ]; then ok append-ts-duplicado-descartado; else falha "append-ts-duplicado-descartado: [$(cat "$fts" 2>/dev/null)]"; fi

# colisão de segundo ganha sufixo
total=$((total + 1))
f2="$(printf 'segundo evento no mesmo segundo\n' | lg "" "$R" append gate code-reviewer meu-slug --ts "$TS1" 2>/dev/null)"
if [ "$f2" = "$LD/20260806-142310-gate-code-reviewer-2.md" ]; then ok append-colisao; else falha "append-colisao: [$f2]"; fi

# tipo fora do catálogo fechado
total=$((total + 1))
printf 'x\n' | lg "" "$R" append relatorio qa meu-slug --ts "$TS1" >/dev/null 2>&1
[ $? -eq 2 ] && ok tipo-invalido-exit-2 || falha tipo-invalido-exit-2

# mais eventos para list/count/archive (inclui intervencao — catálogo 4.244)
printf 'largada da demanda\n' | lg "" "$R" append marco tech-lead meu-slug --ts "2026-08-06T09:00:00-0300" >/dev/null 2>&1
printf 'handoff de tela pendente\n' | lg "" "$R" append pendencia qa meu-slug --ts "2026-08-06T15:00:00-0300" >/dev/null 2>&1
printf 'veto do Diretor na janela do brief\n' | lg "" "$R" append intervencao tech-lead meu-slug --ts "2026-08-06T16:00:00-0300" >/dev/null 2>&1

# list ativo, ordenado
total=$((total + 1))
got="$(lg "" "$R" list 2>/dev/null | sed "s|$LD/||")"
want="20260806-090000-marco-tech-lead.md
20260806-142310-gate-code-reviewer-2.md
20260806-142310-gate-code-reviewer.md
20260806-150000-pendencia-qa.md
20260806-160000-intervencao-tech-lead.md"
if [ "$got" = "$want" ]; then ok list-ordenado; else falha "list-ordenado: [$got]"; fi

# count por tipo
total=$((total + 1))
got="$(lg "" "$R" count 2>/dev/null)"
want="gate	2
intervencao	1
marco	1
pendencia	1"
if [ "$got" = "$want" ]; then ok count-por-tipo; else falha "count-por-tipo: [$got]"; fi

# archive preserva o pendente indicado
total=$((total + 1))
msg="$(lg "" "$R" archive --keep 20260806-150000-pendencia-qa.md --ts "2026-08-06T18:00:00-0300" 2>/dev/null)"
case "$msg" in
  "ledger: 4 evento(s) arquivado(s) em $LD/reported-20260806-180000 · 1 pendente(s) preservado(s)") ok archive-keep ;;
  *) falha "archive-keep: [$msg]" ;;
esac
total=$((total + 1))
ativos="$(lg "" "$R" list 2>/dev/null | sed "s|$LD/||")"
if [ "$ativos" = "20260806-150000-pendencia-qa.md" ]; then ok archive-pendente-fica; else falha "archive-pendente-fica: [$ativos]"; fi
total=$((total + 1))
arq="$(lg "" "$R" list --archived 2>/dev/null | grep -c '')"
if [ "$arq" = "4" ]; then ok archive-movidos; else falha "archive-movidos: [$arq]"; fi

# archive sem nada a mover
lg "" "$R" archive --keep 20260806-150000-pendencia-qa.md --ts "2026-08-06T19:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
lg "" "$R" archive --ts "2026-08-06T20:00:00-0300" >/dev/null 2>&1 && \
  msg="$(lg "" "$R" archive --ts "2026-08-06T21:00:00-0300" 2>/dev/null)" && \
  [ "$msg" = "ledger: nada a arquivar." ] && ok archive-vazio || falha "archive-vazio: [$msg]"

# ledger inexistente: list/count vazios, exit 0 (nunca é gate)
R2="$TMP/repo2"; mkdir -p "$R2"
total=$((total + 1))
got="$(lg "" "$R2" list 2>/dev/null)"; st=$?
if [ -z "$got" ] && [ "$st" -eq 0 ] 2>/dev/null; then ok list-vazio-exit-0; else falha list-vazio-exit-0; fi

# --- casa da sessão (4.314) ---

R3="$TMP/repo3"; mkdir -p "$R3"
LD3="$R3/thoughts/local/session-ledger"
SID="sessao-l-12345678"

# evento legado (trecho da sessão anterior ao update)
printf 'evento do trecho legado\n' | lg "" "$R3" append marco tech-lead meu-slug --ts "2026-08-30T08:00:00-0300" >/dev/null 2>&1

# append com id de sessão nasce na casa dela e registra o slug no meta
total=$((total + 1))
f3="$(printf 'gate na casa da sessão\n' | lg "$SID" "$R3" append gate qa meu-slug --ts "2026-08-30T10:00:00-0300" 2>/dev/null)"
SDIR3="$R3/thoughts/local/sessions/20260830-100000-sessaol1"
if [ "$f3" = "$SDIR3/ledger/20260830-100000-gate-qa.md" ]; then ok sessao-append-na-casa; else falha "sessao-append-na-casa: [$f3]"; fi
total=$((total + 1))
grep -q '^slugs:.*meu-slug' "$SDIR3/session.meta" 2>/dev/null && ok sessao-slug-no-meta || falha sessao-slug-no-meta

# list agrega: legado primeiro (trecho mais antigo), depois a casa da sessão
total=$((total + 1))
got="$(lg "$SID" "$R3" list 2>/dev/null | sed "s|$R3/thoughts/local/||")"
want="session-ledger/20260830-080000-marco-tech-lead.md
sessions/20260830-100000-sessaol1/ledger/20260830-100000-gate-qa.md"
if [ "$got" = "$want" ]; then ok sessao-list-agrega; else falha "sessao-list-agrega: [$got]"; fi

# count agrega os tipos das duas casas
total=$((total + 1))
got="$(lg "$SID" "$R3" count 2>/dev/null)"
want="gate	1
marco	1"
if [ "$got" = "$want" ]; then ok sessao-count-agrega; else falha "sessao-count-agrega: [$got]"; fi

# archive arquiva cada casa DENTRO de si (uma linha por casa com ativos)
total=$((total + 1))
msg="$(lg "$SID" "$R3" archive --ts "2026-08-30T18:00:00-0300" 2>/dev/null)"
want="ledger: 1 evento(s) arquivado(s) em $LD3/reported-20260830-180000 · 0 pendente(s) preservado(s)
ledger: 1 evento(s) arquivado(s) em $SDIR3/ledger/reported-20260830-180000 · 0 pendente(s) preservado(s)"
if [ "$msg" = "$want" ]; then ok sessao-archive-por-casa; else falha "sessao-archive-por-casa: [$msg]"; fi
total=$((total + 1))
got="$(lg "$SID" "$R3" list 2>/dev/null)"
[ -z "$got" ] && ok sessao-archive-esvazia || falha "sessao-archive-esvazia: [$got]"
total=$((total + 1))
arq="$(lg "$SID" "$R3" list --archived 2>/dev/null | grep -c '')"
[ "$arq" = "2" ] && ok sessao-archived-agrega || falha "sessao-archived-agrega: [$arq]"

# sem id, a casa da sessão é invisível (leitura dupla é da sessão dona)
total=$((total + 1))
printf 'novo evento na casa\n' | lg "$SID" "$R3" append marco tech-lead meu-slug --ts "2026-08-30T19:00:00-0300" >/dev/null 2>&1
got="$(lg "" "$R3" list 2>/dev/null)"
[ -z "$got" ] && ok legado-nao-ve-casa-alheia || falha "legado-nao-ve-casa-alheia: [$got]"

# --- last (4.365): evento mais recente do par tipo/origem, entre casas e pastas ---

R4="$TMP/repo4"; mkdir -p "$R4"
SID4="sessao-last-1234"
printf 'legado antigo\n' | lg "" "$R4" append gate code-reviewer s --ts "2026-08-30T08:00:00-0300" >/dev/null 2>&1
printf 'casa mais nova\n' | lg "$SID4" "$R4" append gate code-reviewer s --ts "2026-08-30T10:00:00-0300" >/dev/null 2>&1
printf 'outro gate\n' | lg "$SID4" "$R4" append gate qa s --ts "2026-08-30T11:00:00-0300" >/dev/null 2>&1
SDIR4="sessions/20260830-100000-sessaola"
total=$((total + 1))
got="$(lg "$SID4" "$R4" last gate code-reviewer 2>/dev/null | sed "s|$R4/thoughts/local/||")"
[ "$got" = "$SDIR4/ledger/20260830-100000-gate-code-reviewer.md" ] && ok last-mais-recente-entre-casas || falha "last-mais-recente-entre-casas: [$got]"

# arquivado continua contando (reported-*/ entra na busca)
lg "$SID4" "$R4" archive --ts "2026-08-30T12:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
got="$(lg "$SID4" "$R4" last gate code-reviewer 2>/dev/null | sed "s|$R4/thoughts/local/||")"
[ "$got" = "$SDIR4/ledger/reported-20260830-120000/20260830-100000-gate-code-reviewer.md" ] && ok last-inclui-arquivado || falha "last-inclui-arquivado: [$got]"

# legado mais novo que a casa vence pelo timestamp do nome, não pela ordem das casas
printf 'legado mais novo\n' | lg "" "$R4" append gate code-reviewer s --ts "2026-08-30T13:00:00-0300" >/dev/null 2>&1
total=$((total + 1))
got="$(lg "$SID4" "$R4" last gate code-reviewer 2>/dev/null | sed "s|$R4/thoughts/local/||")"
[ "$got" = "session-ledger/20260830-130000-gate-code-reviewer.md" ] && ok last-legado-mais-novo || falha "last-legado-mais-novo: [$got]"

# sem evento do par → vazio, exit 0 (nunca é gate); sem argumentos → exit 2
total=$((total + 1))
got="$(lg "$SID4" "$R4" last gate security-engineer 2>/dev/null)"; st=$?
if [ -z "$got" ] && [ "$st" -eq 0 ]; then ok last-vazio-exit-0; else falha "last-vazio-exit-0: [$got] exit $st"; fi
total=$((total + 1))
lg "$SID4" "$R4" last gate >/dev/null 2>&1
[ $? -eq 2 ] && ok last-sem-origem-exit-2 || falha last-sem-origem-exit-2

# wave_sequencial pertence ao catálogo (sdd-conventions, 4.301) — o append aceita
total=$((total + 1))
fw="$(printf 'recurso compartilhado: mesma tabela\n' | lg "" "$R4" append wave_sequencial tech-lead s --ts "2026-08-30T14:00:00-0300" 2>/dev/null)"
if [ -f "$fw" ] && [ "$(basename "$fw")" = "20260830-140000-wave_sequencial-tech-lead.md" ]; then ok append-wave-sequencial; else falha "append-wave-sequencial: [$fw]"; fi

# --- diff_id (4.378): evento gate de code-reviewer/security-engineer carrega a identidade ---
DF="$HERE/../../diff-facts.sh"
R5="$TMP/repo-diffid"; mkdir -p "$R5/src"
( cd "$R5" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
printf '{ "codePaths": { "backend": ["src"] }, "sensitiveGlobs": ["src/**"] }\n' > "$R5/keelson.config.json"
printf 'a\n' > "$R5/src/a.php"
( cd "$R5" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m base && git checkout -qb feat )
printf 'b\n' > "$R5/src/a.php"
# sem marca → sem linha (medir a árvore no registro não prova que ela foi revisada — 4.379)
total=$((total + 1))
f5="$(printf 'APROVADO\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:00-0300" 2>/dev/null)"
if grep -q '^diff_id:' "$f5" 2>/dev/null; then falha "diff-id-sem-marca-ausente: $(cat "$f5")"; else ok diff-id-sem-marca-ausente; fi
# mark grava a marca (ts/diff_id/scope) com a identidade do --guard e ecoa o caminho
total=$((total + 1))
mk="$(lg "" "$R5" mark gate code-reviewer s --ts "2026-09-06T10:00:00-0300" 2>/dev/null)"
now="$(bash "$DF" --repo "$R5" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
if [ -f "$mk" ] && [ "$(basename "$mk")" = "mark-gate-code-reviewer" ] && [ "$(sed -n 's/^diff_id: //p' "$mk")" = "$now" ] && grep -q '^scope: review$' "$mk"; then ok mark-grava-identidade-do-guard; else falha "mark-grava-identidade-do-guard: [$mk] $(cat "$mk" 2>/dev/null)"; fi
# a marca não entra em list/count/last (sem .md)
total=$((total + 1))
if lg "" "$R5" list 2>/dev/null | grep -q "mark-gate"; then falha "mark-invisivel-ao-list"; else ok mark-invisivel-ao-list; fi
# append consome a marca: diff_id = o da marca (== identidade atual, árvore intacta), marca removida
total=$((total + 1))
f5b="$(printf 'APROVADO\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:00-0300" 2>/dev/null)"
did="$(sed -n 's/^diff_id: //p' "$f5b" 2>/dev/null)"
if [ -n "$did" ] && [ "$did" = "$now" ] && [ ! -f "$mk" ]; then ok diff-id-da-marca-consumida; else falha "diff-id-da-marca-consumida: [$did] vs [$now], marca $([ -f "$mk" ] && echo presente || echo ausente)"; fi
total=$((total + 1))
if grep -q '^diff_id_nota:' "$f5b" 2>/dev/null; then falha "diff-id-sem-nota-arvore-intacta"; else ok diff-id-sem-nota-arvore-intacta; fi
# P1 (4.379): marca em A, árvore vai a B, registro do parecer de A → diff_id de A + nota
total=$((total + 1))
lg "" "$R5" mark gate code-reviewer s --ts "2026-09-06T10:00:00-0300" >/dev/null 2>&1
idA="$now"
printf 'c\n' > "$R5/src/a.php"
idB="$(bash "$DF" --repo "$R5" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
f5c="$(printf 'APROVADO (parecer sobre A)\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:00-0300" 2>/dev/null)"
didc="$(sed -n 's/^diff_id: //p' "$f5c" 2>/dev/null)"
if [ "$didc" = "$idA" ] && [ "$didc" != "$idB" ] && grep -q '^diff_id_nota:' "$f5c"; then ok diff-id-e-da-marca-nao-da-arvore-com-nota; else falha "diff-id-e-da-marca-nao-da-arvore-com-nota: gravado [$didc] A [$idA] B [$idB] $(grep -c diff_id_nota "$f5c")"; fi
# security-engineer → escopo security
total=$((total + 1))
lg "" "$R5" mark gate security-engineer s --ts "2026-09-06T10:00:01-0300" >/dev/null 2>&1
f6="$(printf 'APROVADO\n' | lg "" "$R5" append gate security-engineer s --ts "2026-09-06T10:00:01-0300" 2>/dev/null)"
sid="$(sed -n 's/^diff_id: //p' "$f6" 2>/dev/null)"
sec="$(bash "$DF" --repo "$R5" --guard security 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
if [ -n "$sid" ] && [ "$sid" = "$sec" ]; then ok diff-id-igual-ao-guard-security; else falha "diff-id-igual-ao-guard-security: [$sid] vs [$sec]"; fi
# marca órfã de OUTRO slug nunca é consumida: o veredito sai sem diff_id e a marca fica
total=$((total + 1))
lg "" "$R5" mark gate code-reviewer outro-slug --ts "2026-09-06T10:00:02-0300" >/dev/null 2>&1
f5d="$(printf 'x\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:02-0300" 2>/dev/null)"
LD5="$R5/thoughts/local/session-ledger"
if ! grep -q '^diff_id:' "$f5d" 2>/dev/null && [ -f "$LD5/mark-gate-code-reviewer" ] && grep -q '^slug: outro-slug$' "$LD5/mark-gate-code-reviewer"; then ok mark-orfa-de-outro-slug-ignorada; else falha "mark-orfa-de-outro-slug-ignorada: $(cat "$f5d" 2>/dev/null) marca=$(cat "$LD5/mark-gate-code-reviewer" 2>/dev/null)"; fi
rm -f "$LD5/mark-gate-code-reviewer"
# nota vem antes de ref:; diff_id: fecha o arquivo mesmo com nota
total=$((total + 1))
lg "" "$R5" mark gate code-reviewer s >/dev/null 2>&1
printf 'd\n' > "$R5/src/a.php"
f5e="$(printf 'x\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:02-0300" --ref docs/y.md 2>/dev/null)"
if [ "$(tail -1 "$f5e" | cut -c1-9)" = "diff_id: " ] && [ "$(tail -2 "$f5e" | head -1)" = "ref: docs/y.md" ] && grep -q '^diff_id_nota:' "$f5e"; then ok nota-antes-de-ref-diff-id-fecha; else falha "nota-antes-de-ref-diff-id-fecha: $(cat "$f5e")"; fi
# mark para origem sem guard → exit 2
total=$((total + 1))
lg "" "$R5" mark gate qa s >/dev/null 2>&1
[ $? -eq 2 ] && ok mark-origem-sem-guard-exit-2 || falha "mark-origem-sem-guard-exit-2"
total=$((total + 1))
f7="$(printf 'PASSOU\n' | lg "" "$R5" append gate qa s --ts "2026-09-06T10:00:02-0300" 2>/dev/null)"
if grep -q '^diff_id:' "$f7" 2>/dev/null; then falha "diff-id-qa: gate de outro papel não ganha diff_id"; else ok diff-id-outro-gate-ausente; fi
total=$((total + 1))
f8="$(printf 'x\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:03-0300" --diff-id deadbeef 2>/dev/null)"
if [ "$(sed -n 's/^diff_id: //p' "$f8" 2>/dev/null)" = "deadbeef" ]; then ok diff-id-explicito; else falha "diff-id-explicito: $(cat "$f8" 2>/dev/null)"; fi
total=$((total + 1))
f9="$(printf 'x\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:04-0300" --diff-id none 2>/dev/null)"
if grep -q '^diff_id:' "$f9" 2>/dev/null; then falha "diff-id-none: linha devia estar suprimida"; else ok diff-id-none-suprime; fi
total=$((total + 1))
lg "" "$R5" mark gate code-reviewer s >/dev/null 2>&1
f10="$(printf 'x\n' | lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:05-0300" --ref docs/x.md 2>/dev/null)"
if [ "$(tail -2 "$f10" 2>/dev/null | head -1)" = "ref: docs/x.md" ] && tail -1 "$f10" 2>/dev/null | grep -q '^diff_id: '; then ok diff-id-apos-ref; else falha "diff-id-apos-ref: $(cat "$f10" 2>/dev/null)"; fi

# diff_id: escrita de memória no stdin é descartada (mesma classe do ts:, 4.156)
total=$((total + 1))
f11="$(printf 'diff_id: 1111111111111111111111111111111111111111\ncorpo real\n' | lg "" "$R5" append gate qa s --ts "2026-09-06T10:00:06-0300" 2>/dev/null)"
if grep -q '^diff_id:' "$f11" 2>/dev/null; then falha "diff-id-stdin-descartado: $(cat "$f11")"; else ok diff-id-stdin-descartado; fi
# GIT_DIR herdado de contexto de hook não desvia a medição (diff-facts desarma as variáveis)
total=$((total + 1))
GIT_DIR=/nao/existe/.git GIT_WORK_TREE=/nao/existe lg "" "$R5" mark gate code-reviewer s >/dev/null 2>&1
f12="$(printf 'x\n' | GIT_DIR=/nao/existe/.git GIT_WORK_TREE=/nao/existe lg "" "$R5" append gate code-reviewer s --ts "2026-09-06T10:00:07-0300" 2>/dev/null)"
idnow="$(bash "$DF" --repo "$R5" --guard review 2>/dev/null | awk -F'\t' '$1 == "identity" { print $2 }')"
if [ -n "$idnow" ] && [ "$(sed -n 's/^diff_id: //p' "$f12" 2>/dev/null)" = "$idnow" ]; then ok diff-id-imune-a-git-dir-herdado; else falha "diff-id-imune-a-git-dir-herdado: [$(sed -n 's/^diff_id: //p' "$f12" 2>/dev/null)] vs [$idnow]"; fi
# raiz que é worktree vinculado → sem linha (a árvore medida tem de ser a principal)
total=$((total + 1))
WT="$TMP/wt-ledger"
if git -C "$R5" worktree add -q "$WT" -b wt-branch >/dev/null 2>&1; then
  printf '{ "codePaths": { "backend": ["src"] } }\n' > "$WT/keelson.config.json"
  printf 'w\n' > "$WT/src/a.php"
  mkw="$(lg "" "$WT" mark gate code-reviewer s 2>/dev/null)"
  f13="$(printf 'x\n' | lg "" "$WT" append gate code-reviewer s --ts "2026-09-06T10:00:08-0300" 2>/dev/null)"
  if [ -z "$mkw" ] && ! grep -q '^diff_id:' "$f13" 2>/dev/null; then ok diff-id-worktree-sem-marca-nem-linha; else falha "diff-id-worktree-sem-marca-nem-linha: marca [$mkw] $(cat "$f13")"; fi
  git -C "$R5" worktree remove --force "$WT" >/dev/null 2>&1 || true
else
  echo "ok   diff-id-worktree-sem-linha (git worktree indisponível — pulado)"
fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "ledger: $fail de $total casos falharam"
  exit 1
fi
echo "ledger: $total casos verdes"
exit 0
