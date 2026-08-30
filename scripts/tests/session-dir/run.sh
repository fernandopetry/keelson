#!/usr/bin/env bash
# run.sh — suíte de regressão do session-dir.sh (decisão 4.314).
#
# Casos inline em diretório temporário, com --ts fixo (determinismo) e ambiente
# de sessão SEMPRE controlado (a suíte pode rodar dentro de uma sessão real onde
# CLAUDE_CODE_SESSION_ID existe). Regras provadas: modo legado sem id (dir,
# ledger-dir e window-log colapsam nos caminhos antigos), criação idempotente com
# session.meta canônico, resolução por meta (colisão de sid8 não confunde),
# registro dedupado de slugs, show, e "desconhecida" força o legado.
#
# Uso: scripts/tests/session-dir/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SD="$HERE/../../session-dir.sh"

[ -f "$SD" ] || { echo "ERRO: session-dir.sh não encontrado em $SD" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$SD" || { echo "FAIL bash -n session-dir.sh"; exit 1; }
echo "ok   bash -n session-dir.sh"

R="$TMP/repo"; mkdir -p "$R"
TS1="2026-08-30T10:00:00-0300"

# sd — invocação com ambiente de sessão controlado
sd() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$SD" "$@"; }

# sem id de sessão → modo legado nos três subcomandos
total=$((total + 1))
got="$(sd "" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok legado-dir || falha "legado-dir: [$got]"
total=$((total + 1))
got="$(sd "" "$R" ledger-dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local/session-ledger" ] && ok legado-ledger-dir || falha "legado-ledger-dir: [$got]"
total=$((total + 1))
got="$(sd "" "$R" window-log 2>/dev/null)"
[ "$got" = "$R/thoughts/local/session-window.log" ] && ok legado-window-log || falha "legado-window-log: [$got]"

# "desconhecida" também força o legado (é o valor de degradação do run-state)
total=$((total + 1))
got="$(sd "desconhecida" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok desconhecida-legado || falha "desconhecida-legado: [$got]"

# sem --create, sessão sem pasta → também cai no legado (leitor lê onde os dados estão)
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok sem-pasta-cai-no-legado || falha "sem-pasta-cai-no-legado: [$got]"

# --create nasce a pasta com o session.meta canônico
total=$((total + 1))
D="$R/thoughts/local/sessions/20260830-100000-sessaoa1"
got="$(sd "sessao-a-11112222" "$R" dir --create --ts "$TS1" 2>/dev/null)"
[ "$got" = "$D" ] && [ -d "$D" ] && ok create-nome || falha "create-nome: [$got]"
total=$((total + 1))
want="sessao: sessao-a-11112222
iniciada: $TS1
estado: ativa
slugs:"
[ "$(cat "$D/session.meta" 2>/dev/null)" = "$want" ] && ok create-meta || falha "create-meta: [$(cat "$D/session.meta" 2>/dev/null)]"

# criação é idempotente: segundo --create (mesmo com outro --ts) resolve a existente
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" dir --create --ts "2026-08-30T11:00:00-0300" 2>/dev/null)"
[ "$got" = "$D" ] && ok create-idempotente || falha "create-idempotente: [$got]"
total=$((total + 1))
n=0; for d in "$R/thoughts/local/sessions"/*; do [ -d "$d" ] && n=$((n + 1)); done
[ "$n" = "1" ] && ok create-sem-duplicata || falha "create-sem-duplicata: [$n]"

# ledger-dir e window-log da casa nova
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" ledger-dir --create 2>/dev/null)"
[ "$got" = "$D/ledger" ] && [ -d "$D/ledger" ] && ok novo-ledger-dir || falha "novo-ledger-dir: [$got]"
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" window-log 2>/dev/null)"
[ "$got" = "$D/window.log" ] && ok novo-window-log || falha "novo-window-log: [$got]"

# --slug registra na linha slugs: com dedup
sd "sessao-a-11112222" "$R" dir --slug alfa >/dev/null 2>&1
sd "sessao-a-11112222" "$R" dir --slug beta >/dev/null 2>&1
sd "sessao-a-11112222" "$R" dir --slug alfa >/dev/null 2>&1
total=$((total + 1))
got="$(sed -n 's/^slugs:[ 	]*//p' "$D/session.meta")"
[ "$got" = "alfa beta" ] && ok slug-dedup || falha "slug-dedup: [$got]"

# colisão de sid8: outra sessão com o MESMO prefixo não resolve a pasta alheia
total=$((total + 1))
got="$(sd "sessao-a-11119999" "$R" dir 2>/dev/null)"
[ "$got" = "$R/thoughts/local" ] && ok colisao-sid8-nao-confunde || falha "colisao-sid8-nao-confunde: [$got]"
total=$((total + 1))
D2="$(sd "sessao-a-11119999" "$R" dir --create --ts "2026-08-30T12:00:00-0300" 2>/dev/null)"
[ "$D2" != "$D" ] && [ -d "$D2" ] && grep -qxF "sessao: sessao-a-11119999" "$D2/session.meta" && ok colisao-cria-propria || falha "colisao-cria-propria: [$D2]"

# show imprime o meta da sessão corrente; nada sem pasta
total=$((total + 1))
got="$(sd "sessao-a-11112222" "$R" show 2>/dev/null | sed -n 1p)"
[ "$got" = "sessao: sessao-a-11112222" ] && ok show || falha "show: [$got]"
total=$((total + 1))
got="$(sd "sessao-c-inexistente" "$R" show 2>/dev/null)"
[ -z "$got" ] && ok show-ausente-vazio || falha "show-ausente-vazio: [$got]"

# CLAUDE_CODE_SESSION_ID é a fonte quando KEELSON_SESSAO não está definida
total=$((total + 1))
got="$(env -u KEELSON_SESSAO CLAUDE_CODE_SESSION_ID="sessao-a-11112222" bash "$SD" "$R" dir 2>/dev/null)"
[ "$got" = "$D" ] && ok fonte-env-harness || falha "fonte-env-harness: [$got]"

# --- handover local (4.315): latest-for · memo-find · adopt-memo · mark-reported ---

R2="$TMP/repo-handover"; mkdir -p "$R2"
S2="$R2/thoughts/local/sessions"
casa() { # nome sessao slugs — casa sintética com manifest
  mkdir -p "$S2/$1"
  printf 'sessao: %s\niniciada: 2026-08-29T09:00:00-0300\nestado: ativa\nslugs: %s\n' "$2" "$3" > "$S2/$1/session.meta"
}
casa 20260829-090000-sessanti sessao-antiga-1111 "gama"
casa 20260830-090000-sessmedi sessao-media-2222 "gama delta"
printf 'memo antigo\n' > "$S2/20260829-090000-sessanti/exploration-gama.md"
printf 'memo medio\n'  > "$S2/20260830-090000-sessmedi/exploration-gama.md"
mkdir -p "$R2/thoughts/local"
printf 'memo legado\n' > "$R2/thoughts/local/exploration-gama.md"
printf 'memo omega legado\n' > "$R2/thoughts/local/exploration-omega.md"
NOVA="sessao-nova-3333"

# latest-for devolve a casa mais recente com o slug
total=$((total + 1))
got="$(sd "$NOVA" "$R2" latest-for gama 2>/dev/null)"
[ "$got" = "$S2/20260830-090000-sessmedi" ] && ok latest-for-mais-recente || falha "latest-for-mais-recente: [$got]"

# latest-for exclui a casa da sessão corrente
sd "$NOVA" "$R2" dir --create --slug gama --ts "2026-08-30T12:00:00-0300" >/dev/null 2>&1
DN="$S2/20260830-120000-sessaono"
total=$((total + 1))
got="$(sd "$NOVA" "$R2" latest-for gama 2>/dev/null)"
[ "$got" = "$S2/20260830-090000-sessmedi" ] && ok latest-for-exclui-corrente || falha "latest-for-exclui-corrente: [$got]"

# latest-for sem match → vazio, exit 0
total=$((total + 1))
got="$(sd "$NOVA" "$R2" latest-for slug-inexistente 2>/dev/null)"; st=$?
[ -z "$got" ] && [ "$st" -eq 0 ] && ok latest-for-vazio || falha "latest-for-vazio: [$got]"

# memo-find: cadeia — anterior mais recente primeiro (corrente sem memo próprio)
total=$((total + 1))
got="$(sd "$NOVA" "$R2" memo-find gama 2>/dev/null)"
[ "$got" = "$S2/20260830-090000-sessmedi/exploration-gama.md" ] && ok memo-find-cadeia || falha "memo-find-cadeia: [$got]"

# memo-find --all lista todos: anteriores (recente→antiga) e o legado por último
total=$((total + 1))
got="$(sd "$NOVA" "$R2" memo-find gama --all 2>/dev/null)"
want="$S2/20260830-090000-sessmedi/exploration-gama.md
$S2/20260829-090000-sessanti/exploration-gama.md
$R2/thoughts/local/exploration-gama.md"
[ "$got" = "$want" ] && ok memo-find-all || falha "memo-find-all: [$got]"

# memo-find cai no legado quando nenhuma casa tem o memo; vazio quando nada existe
total=$((total + 1))
got="$(sd "$NOVA" "$R2" memo-find omega 2>/dev/null)"
[ "$got" = "$R2/thoughts/local/exploration-omega.md" ] && ok memo-find-legado || falha "memo-find-legado: [$got]"
total=$((total + 1))
got="$(sd "$NOVA" "$R2" memo-find nada 2>/dev/null)"; st=$?
[ -z "$got" ] && [ "$st" -eq 0 ] && ok memo-find-vazio || falha "memo-find-vazio: [$got]"

# sem id de sessão a cadeia degrada para o legado
total=$((total + 1))
got="$(sd "" "$R2" memo-find gama 2>/dev/null)"
[ "$got" = "$R2/thoughts/local/exploration-gama.md" ] && ok memo-find-sem-id-legado || falha "memo-find-sem-id-legado: [$got]"

# adopt-memo herda o mais recente da cadeia para a casa própria e grava anterior:
total=$((total + 1))
got="$(sd "$NOVA" "$R2" adopt-memo gama 2>/dev/null)"
[ "$got" = "$DN/exploration-gama.md" ] && [ "$(cat "$DN/exploration-gama.md" 2>/dev/null)" = "memo medio" ] \
  && grep -qxF "anterior: sessao-media-2222" "$DN/session.meta" && ok adopt-herda || falha "adopt-herda: [$got]"

# memo-find passa a devolver o próprio (topo da cadeia)
total=$((total + 1))
got="$(sd "$NOVA" "$R2" memo-find gama 2>/dev/null)"
[ "$got" = "$DN/exploration-gama.md" ] && ok memo-find-proprio-primeiro || falha "memo-find-proprio-primeiro: [$got]"

# adopt-memo é idempotente e a primeira herança não é sobrescrita
printf 'memo editado pela nova\n' > "$DN/exploration-gama.md"
total=$((total + 1))
got="$(sd "$NOVA" "$R2" adopt-memo gama 2>/dev/null)"
[ "$got" = "$DN/exploration-gama.md" ] && [ "$(cat "$DN/exploration-gama.md")" = "memo editado pela nova" ] \
  && ok adopt-idempotente || falha "adopt-idempotente: [$got]"
total=$((total + 1))
got="$(sd "$NOVA" "$R2" adopt-memo omega 2>/dev/null)"
[ "$(cat "$DN/exploration-omega.md" 2>/dev/null)" = "memo omega legado" ] \
  && grep -qxF "anterior: sessao-media-2222" "$DN/session.meta" \
  && ! grep -qxF "anterior: legado" "$DN/session.meta" && ok adopt-legado-sem-sobrescrever-anterior || falha adopt-legado-sem-sobrescrever-anterior

# adopt-memo sem nada na cadeia ecoa o caminho e NÃO cria o arquivo
total=$((total + 1))
got="$(sd "$NOVA" "$R2" adopt-memo virgem 2>/dev/null)"
[ "$got" = "$DN/exploration-virgem.md" ] && [ ! -f "$DN/exploration-virgem.md" ] && ok adopt-virgem || falha "adopt-virgem: [$got]"

# adopt-memo sem id de sessão → caminho legado (comportamento antigo)
total=$((total + 1))
got="$(sd "" "$R2" adopt-memo gama 2>/dev/null)"
[ "$got" = "$R2/thoughts/local/exploration-gama.md" ] && ok adopt-sem-id-legado || falha "adopt-sem-id-legado: [$got]"

# mark-reported marca o estado; escrita posterior com --create reabre
total=$((total + 1))
sd "$NOVA" "$R2" mark-reported 2>/dev/null
grep -qxF "estado: reportada" "$DN/session.meta" && ok mark-reported || falha mark-reported
total=$((total + 1))
sd "$NOVA" "$R2" dir --create >/dev/null 2>&1
grep -qxF "estado: ativa" "$DN/session.meta" && ok reabertura-no-create || falha reabertura-no-create

# mark-reported sem casa → no-op silencioso
total=$((total + 1))
got="$(sd "sessao-sem-casa-9" "$R2" mark-reported 2>&1)"; st=$?
[ -z "$got" ] && [ "$st" -eq 0 ] && ok mark-reported-sem-casa || falha "mark-reported-sem-casa: [$got]"

# mark-reported com --ts grava reportada_em determinístico (e re-report atualiza)
total=$((total + 1))
sd "$NOVA" "$R2" mark-reported --ts "2026-08-30T18:00:00-0300" 2>/dev/null
grep -qxF "reportada_em: 2026-08-30T18:00:00-0300" "$DN/session.meta" && ok mark-reported-em || falha "mark-reported-em: [$(cat "$DN/session.meta")]"
total=$((total + 1))
sd "$NOVA" "$R2" mark-reported --ts "2026-08-30T19:00:00-0300" 2>/dev/null
grep -qxF "reportada_em: 2026-08-30T19:00:00-0300" "$DN/session.meta" \
  && [ "$(grep -c '^reportada_em:' "$DN/session.meta")" = "1" ] && ok mark-reported-atualiza || falha mark-reported-atualiza

# --- gc (4.316): report-only por default, régua conservadora ---

R3="$TMP/repo-gc"; mkdir -p "$R3"
S3="$R3/thoughts/local/sessions"
HOJE="2026-08-30T12:00:00-0300"
casa_gc() { # nome sessao estado [reportada_em]
  mkdir -p "$S3/$1"
  printf 'sessao: %s\niniciada: 2026-07-01T09:00:00-0300\nestado: %s\nslugs: gama\n' "$2" "$3" > "$S3/$1/session.meta"
  [ -n "${4:-}" ] && printf 'reportada_em: %s\n' "$4" >> "$S3/$1/session.meta"
}
casa_gc 20260801-090000-gvelha11 sessao-gv-1 reportada "2026-08-01T10:00:00-0300"   # 29 dias → elegível
casa_gc 20260825-090000-grecent1 sessao-gr-1 reportada "2026-08-25T10:00:00-0300"   # 5 dias → mantida
casa_gc 20260701-090000-gativa11 sessao-ga-1 ativa                                   # ativa → invisível
casa_gc 20260801-090000-gledger1 sessao-gl-1 reportada "2026-08-01T10:00:00-0300"
mkdir -p "$S3/20260801-090000-gledger1/ledger"
printf 'x\n' > "$S3/20260801-090000-gledger1/ledger/20260801-100000-pendencia-qa.md"  # pendência → mantida
casa_gc 20260801-090000-grunst11 sessao-gs-1 reportada "2026-08-01T10:00:00-0300"
printf 'status: em_andamento\nslug: gama\nsessao: sessao-gs-1\n' > "$S3/20260801-090000-grunst11/run-state-gama.md"  # → mantida
casa_gc 20260710-090000-gsemrep1 sessao-gn-1 reportada                                # sem reportada_em → idade pela criação (51d) → elegível
mkdir -p "$R3/thoughts/local/session-ledger/reported-20260701-120000"                 # 60 dias → elegível
printf 'x\n' > "$R3/thoughts/local/session-ledger/reported-20260701-120000/20260701-110000-gate-qa.md"
mkdir -p "$R3/thoughts/local/session-ledger/reported-20260829-120000"                 # 1 dia → fora

# report-only: lista elegíveis e mantidas, remove nada, ativa invisível
total=$((total + 1))
got="$(sd "sessao-gc-atual" "$R3" gc --ts "$HOJE" 2>/dev/null)"
echo "$got" | grep -q "elegivel: $S3/20260801-090000-gvelha11 · reportada há 29 dia(s)" \
  && echo "$got" | grep -q "elegivel: $S3/20260710-090000-gsemrep1 · criada (sem reportada_em) há 51 dia(s)" \
  && echo "$got" | grep -q "elegivel: $R3/thoughts/local/session-ledger/reported-20260701-120000 · arquivado há 60 dia(s)" \
  && ok gc-report-elegiveis || falha "gc-report-elegiveis: [$got]"
total=$((total + 1))
echo "$got" | grep -q "mantida: $S3/20260825-090000-grecent1 · reportada há 5 dia(s) (limiar 14)" \
  && echo "$got" | grep -q "mantida: $S3/20260801-090000-gledger1 · ledger com evento ativo" \
  && echo "$got" | grep -q "mantida: $S3/20260801-090000-grunst11 · run-state em_andamento" \
  && ok gc-report-mantidas || falha "gc-report-mantidas: [$got]"
total=$((total + 1))
! echo "$got" | grep -q "gativa11" && [ -d "$S3/20260801-090000-gvelha11" ] && ok gc-report-only-nao-remove || falha gc-report-only-nao-remove

# --days sobe o limiar
total=$((total + 1))
got="$(sd "sessao-gc-atual" "$R3" gc --days 40 --ts "$HOJE" 2>/dev/null)"
echo "$got" | grep -q "mantida: $S3/20260801-090000-gvelha11 · reportada há 29 dia(s) (limiar 40)" \
  && echo "$got" | grep -q "elegivel: $R3/thoughts/local/session-ledger/reported-20260701-120000" \
  && ok gc-days || falha "gc-days: [$got]"

# --apply remove só os elegíveis
total=$((total + 1))
got="$(sd "sessao-gc-atual" "$R3" gc --apply --ts "$HOJE" 2>/dev/null)"
[ ! -d "$S3/20260801-090000-gvelha11" ] && [ ! -d "$S3/20260710-090000-gsemrep1" ] \
  && [ ! -d "$R3/thoughts/local/session-ledger/reported-20260701-120000" ] \
  && [ -d "$S3/20260825-090000-grecent1" ] && [ -d "$S3/20260701-090000-gativa11" ] \
  && [ -d "$S3/20260801-090000-gledger1" ] && [ -d "$S3/20260801-090000-grunst11" ] \
  && [ -d "$R3/thoughts/local/session-ledger/reported-20260829-120000" ] \
  && echo "$got" | grep -q "removida: $S3/20260801-090000-gvelha11" && ok gc-apply || falha "gc-apply: [$got]"

# nova passada: nada elegível → "nada a limpar" (mantidas continuam listadas)
total=$((total + 1))
got="$(sd "sessao-gc-atual" "$R3" gc --ts "$HOJE" 2>/dev/null)"
! echo "$got" | grep -q "^elegivel:" && echo "$got" | grep -q "gc: nada a limpar." && ok gc-nada || falha "gc-nada: [$got]"

# repo vazio → nada a limpar, exit 0
total=$((total + 1))
R4="$TMP/repo-gc-vazio"; mkdir -p "$R4"
got="$(sd "" "$R4" gc --ts "$HOJE" 2>/dev/null)"; st=$?
[ "$got" = "gc: nada a limpar." ] && [ "$st" -eq 0 ] && ok gc-vazio || falha "gc-vazio: [$got]"

# --days não-numérico → exit 2
total=$((total + 1))
sd "" "$R3" gc --days abc >/dev/null 2>&1
[ $? -eq 2 ] && ok gc-days-invalido-exit-2 || falha gc-days-invalido-exit-2

# erros de uso
total=$((total + 1))
sd "x" "$R" latest-for >/dev/null 2>&1
[ $? -eq 2 ] && ok latest-for-sem-slug-exit-2 || falha latest-for-sem-slug-exit-2
total=$((total + 1))
sd "x" "$TMP/nao-existe" dir >/dev/null 2>&1
[ $? -eq 2 ] && ok raiz-inexistente-exit-2 || falha raiz-inexistente-exit-2
total=$((total + 1))
sd "x" "$R" acao-invalida >/dev/null 2>&1
[ $? -eq 2 ] && ok acao-invalida-exit-2 || falha acao-invalida-exit-2
total=$((total + 1))
sd "x" "$R" dir --ts "nao-e-iso" --create >/dev/null 2>&1
[ $? -eq 2 ] && ok ts-ilegivel-exit-2 || falha ts-ilegivel-exit-2

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "session-dir: $fail de $total casos falharam"
  exit 1
fi
echo "session-dir: $total casos verdes"
exit 0
