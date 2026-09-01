#!/usr/bin/env bash
# run.sh — suíte de regressão do cycle-clock.sh (decisão 4.325).
#
# Cada caso monta um diretório sintético de TASKs e compara a saída com a esperada
# inline. Regras provadas: parede min→max atravessando dias (multi-sessão), união de
# intervalos descontando sobreposição (waves paralelas), completude declarada,
# buraco conhecido (vazio/placeholder) sem aviso, nao-parseavel com WARNING e sem
# número inventado, janela negativa fora da soma, última ocorrência vence (Histórico
# de execução), filtro por PLAN + exclusão do INDEX, anotação após o token ISO
# tolerada, fuso misto convertido por epoch, exit 2 sem TASK elegível. Com
# --paralelismo (4.328): cadeia linear (ganho 1.0x, caminho = soma), waves paralelas
# (ganho > 1x, empate determinístico), ciclo omitido com motivo, dep ignorada
# contada, tudo omitido sem par; offset -03:00 normalizado (default).
#
# Uso: scripts/tests/cycle-clock/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CC="$HERE/../../cycle-clock.sh"

[ -f "$CC" ] || { echo "ERRO: cycle-clock.sh não encontrado em $CC" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

mktask() { # $1 dir · $2 nome (sem .md) · $3 valor de início · $4 valor de conclusão
  {
    printf '# %s\n\n## Histórico de execução\n\n' "$2"
    printf '**Data início**: %s\n' "$3"
    printf '**Data conclusão**: %s\n' "$4"
  } > "$1/$2.md"
}

assert() { # nome exit-esperado saida-esperada saida-obtida exit-obtido
  name="$1"; wantexit="$2"; want="$3"; got="$4"; st="$5"
  total=$((total + 1))
  if [ "$st" != "$wantexit" ]; then
    echo "FAIL $name — exit $st (esperado $wantexit)" >&2
    fail=$((fail + 1)); return
  fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $name — saída divergente:" >&2
    printf '%s\n' "--- esperado ---" "$want" "--- obtido ---" "$got" >&2
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

# --- duas sessões: parede inclui o intervalo parado, soma não --------------------
D="$TMP/duas-sessoes"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300"
mktask "$D" TASK-001-002-b "2026-01-12T09:30:00-0300" "2026-01-12T10:00:00-0300"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert duas-sessoes 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	2026-01-12T09:30:00-0300	2026-01-12T10:00:00-0300
completude	2 de 2 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-12T10:00:00-0300	2880min	48h00min
soma-tasks	90min	1h30min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- sobreposição (wave paralela): união, nunca soma crua ------------------------
D="$TMP/sobreposicao"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300"
mktask "$D" TASK-001-002-b "2026-01-10T10:30:00-0300" "2026-01-10T11:30:00-0300"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert sobreposicao 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	2026-01-10T10:30:00-0300	2026-01-10T11:30:00-0300
completude	2 de 2 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T11:30:00-0300	90min	1h30min
soma-tasks	90min	1h30min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- buraco conhecido (vazio + placeholder): declarado, sem aviso ----------------
D="$TMP/buraco"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T10:30:00-0300"
mktask "$D" TASK-001-002-b "" ""
mktask "$D" TASK-001-003-c "— (não medido)" "— (não medido)"
err="$(bash "$CC" "$D" 2>&1 >/dev/null)"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert buraco 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T10:30:00-0300
task	TASK-001-002-b	sem-marca	sem-marca
task	TASK-001-003-c	sem-marca	sem-marca
completude	1 de 3 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T10:30:00-0300	30min	0h30min
soma-tasks	30min	0h30min	uniao de intervalos - sobreposicao descontada" "$got" "$st"
total=$((total + 1))
if [ -n "$err" ]; then
  echo "FAIL buraco-sem-aviso — stderr deveria ser vazio: $err" >&2; fail=$((fail + 1))
else
  echo "ok   buraco-sem-aviso"
fi

# --- não-parseável: WARNING e ausência, nunca número inventado -------------------
D="$TMP/nao-parseavel"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "amanhã cedo" "2026-01-10T11:00:00-0300"
err="$(bash "$CC" "$D" 2>&1 >/dev/null)"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert nao-parseavel 0 "task	TASK-001-001-a	sem-marca	2026-01-10T11:00:00-0300
completude	0 de 1 TASK(s) com par de marcas
parede	omitida	sem inicio parseavel
soma-tasks	omitida	0 de 1 TASK(s) com par de marcas" "$got" "$st"
total=$((total + 1))
case "$err" in
  *"WARNING nao-parseavel: TASK-001-001-a: Data início 'amanhã cedo'"*) echo "ok   nao-parseavel-warning" ;;
  *) echo "FAIL nao-parseavel-warning — stderr: $err" >&2; fail=$((fail + 1)) ;;
esac

# --- janela negativa: fora da soma; marcas inconsistentes → parede omitida -------
D="$TMP/janela-negativa"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T12:00:00-0300" "2026-01-10T10:00:00-0300"
err="$(bash "$CC" "$D" 2>&1 >/dev/null)"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert janela-negativa 0 "task	TASK-001-001-a	2026-01-10T12:00:00-0300	2026-01-10T10:00:00-0300
completude	0 de 1 TASK(s) com par de marcas
parede	omitida	marcas inconsistentes (max conclusao < min inicio)
soma-tasks	omitida	0 de 1 TASK(s) com par de marcas" "$got" "$st"
total=$((total + 1))
case "$err" in
  *"WARNING janela-negativa: TASK-001-001-a"*) echo "ok   janela-negativa-warning" ;;
  *) echo "FAIL janela-negativa-warning — stderr: $err" >&2; fail=$((fail + 1)) ;;
esac

# --- só início conta para a parede; par incompleto fora da soma ------------------
D="$TMP/so-inicio"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T08:00:00-0300" ""
mktask "$D" TASK-001-002-b "2026-01-10T09:00:00-0300" "2026-01-10T09:30:00-0300"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert so-inicio 0 "task	TASK-001-001-a	2026-01-10T08:00:00-0300	sem-marca
task	TASK-001-002-b	2026-01-10T09:00:00-0300	2026-01-10T09:30:00-0300
completude	1 de 2 TASK(s) com par de marcas
parede	2026-01-10T08:00:00-0300 -> 2026-01-10T09:30:00-0300	90min	1h30min
soma-tasks	30min	0h30min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- filtro por PLAN + INDEX fora + anotação após o ISO + última ocorrência vence -
D="$TMP/filtro"; mkdir -p "$D"
{
  printf '# a\n\n**Data início**: 2026-01-10T09:00:00-0300\n\n## Histórico de execução\n\n'
  printf '**Data início**: 2026-01-10T10:00:00-0300\n'
  printf '**Data conclusão**: 2026-01-10T11:00:00-0300 (derivada do commit anterior — ver Notas)\n'
} > "$D/TASK-001-001-a.md"
mktask "$D" TASK-002-001-outro "2026-01-01T00:00:00-0300" "2026-01-01T01:00:00-0300"
printf '# índice\n**Data início**: 1999-01-01T00:00:00-0300\n**Data conclusão**: 1999-01-01T01:00:00-0300\n' > "$D/TASK-001-INDEX.md"
got="$(bash "$CC" "$D" PLAN-001 2>/dev/null)"; st=$?
assert filtro-plan 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
completude	1 de 1 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T11:00:00-0300	60min	1h00min
soma-tasks	60min	1h00min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- fuso misto: epoch converte offsets distintos ---------------------------------
D="$TMP/fuso"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T13:30:00+0000"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert fuso-misto 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T13:30:00+0000
completude	1 de 1 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T13:30:00+0000	30min	0h30min
soma-tasks	30min	0h30min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- --paralelismo (4.328): ganho + caminho crítico -------------------------------
mktaskdep() { # $1 dir · $2 nome · $3 início · $4 conclusão · $5 valor de "Depende de"
  {
    printf '# %s\n\n## Dependências\n\n' "$2"
    printf -- '- **Depende de**: %s\n' "$5"
    printf '\n## Histórico de execução\n\n'
    printf '**Data início**: %s\n' "$3"
    printf '**Data conclusão**: %s\n' "$4"
  } > "$1/$2.md"
}

# cadeia linear: caminho = soma da cadeia; ganho 1.0x (sequencial); crase tolerada
D="$TMP/par-linear"; mkdir -p "$D"
mktaskdep "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300" "nenhuma"
mktaskdep "$D" TASK-001-002-b "2026-01-10T11:00:00-0300" "2026-01-10T11:30:00-0300" "TASK-001-001"
mktaskdep "$D" TASK-001-003-c "2026-01-10T11:30:00-0300" "2026-01-10T12:30:00-0300" "\`TASK-001-002\`"
got="$(bash "$CC" "$D" --paralelismo 2>/dev/null)"; st=$?
assert par-linear 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	2026-01-10T11:00:00-0300	2026-01-10T11:30:00-0300
task	TASK-001-003-c	2026-01-10T11:30:00-0300	2026-01-10T12:30:00-0300
completude	3 de 3 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T12:30:00-0300	150min	2h30min
soma-tasks	150min	2h30min	uniao de intervalos - sobreposicao descontada
ganho	1.0x	soma-crua 150min / parede 150min
caminho-critico	150min	2h30min	TASK-001-001 -> TASK-001-002 -> TASK-001-003 (3 TASK(s))" "$got" "$st"

# waves paralelas: caminho < soma crua; ganho > 1x; empate resolve pela ordem
D="$TMP/par-waves"; mkdir -p "$D"
mktaskdep "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300" "nenhuma"
mktaskdep "$D" TASK-001-002-b "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300" "nenhuma"
mktaskdep "$D" TASK-001-003-c "2026-01-10T11:00:00-0300" "2026-01-10T12:00:00-0300" "TASK-001-001, TASK-001-002"
got="$(bash "$CC" "$D" --paralelismo 2>/dev/null)"; st=$?
assert par-waves 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-003-c	2026-01-10T11:00:00-0300	2026-01-10T12:00:00-0300
completude	3 de 3 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T12:00:00-0300	120min	2h00min
soma-tasks	120min	2h00min	uniao de intervalos - sobreposicao descontada
ganho	1.5x	soma-crua 180min / parede 120min
caminho-critico	120min	2h00min	TASK-001-001 -> TASK-001-003 (2 TASK(s))" "$got" "$st"

# ciclo de dependência: caminho omitido com motivo; ganho segue saindo
D="$TMP/par-ciclo"; mkdir -p "$D"
mktaskdep "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300" "TASK-001-002"
mktaskdep "$D" TASK-001-002-b "2026-01-10T11:00:00-0300" "2026-01-10T11:30:00-0300" "TASK-001-001"
got="$(bash "$CC" "$D" --paralelismo 2>/dev/null)"; st=$?
assert par-ciclo 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	2026-01-10T11:00:00-0300	2026-01-10T11:30:00-0300
completude	2 de 2 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T11:30:00-0300	90min	1h30min
soma-tasks	90min	1h30min	uniao de intervalos - sobreposicao descontada
ganho	1.0x	soma-crua 90min / parede 90min
caminho-critico	omitido	ciclo de dependencia entre as TASKs" "$got" "$st"

# dep fora do conjunto lido (cross-PLAN/inexistente) e dep para TASK sem par:
# ignoradas e CONTADAS na linha — nunca silêncio
D="$TMP/par-drop"; mkdir -p "$D"
mktaskdep "$D" TASK-001-001-a "2026-01-10T10:00:00-0300" "2026-01-10T11:00:00-0300" "TASK-009-099"
mktaskdep "$D" TASK-001-002-b "" "" "nenhuma"
mktaskdep "$D" TASK-001-003-c "2026-01-10T11:00:00-0300" "2026-01-10T12:00:00-0300" "TASK-001-001, TASK-001-002"
got="$(bash "$CC" "$D" --paralelismo 2>/dev/null)"; st=$?
assert par-drop 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
task	TASK-001-002-b	sem-marca	sem-marca
task	TASK-001-003-c	2026-01-10T11:00:00-0300	2026-01-10T12:00:00-0300
completude	2 de 3 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T12:00:00-0300	120min	2h00min
soma-tasks	120min	2h00min	uniao de intervalos - sobreposicao descontada
ganho	1.0x	soma-crua 120min / parede 120min
caminho-critico	120min	2h00min	TASK-001-001 -> TASK-001-003 (2 TASK(s), 2 dep(s) ignoradas: fora do conjunto ou sem par de marcas)" "$got" "$st"

# sem nenhum par de marcas: as duas grandezas novas saem omitidas
D="$TMP/par-vazio"; mkdir -p "$D"
mktaskdep "$D" TASK-001-001-a "" "" "nenhuma"
got="$(bash "$CC" "$D" --paralelismo 2>/dev/null)"; st=$?
assert par-vazio 0 "task	TASK-001-001-a	sem-marca	sem-marca
completude	0 de 1 TASK(s) com par de marcas
parede	omitida	sem inicio parseavel
soma-tasks	omitida	0 de 1 TASK(s) com par de marcas
ganho	omitido	sem par de marcas
caminho-critico	omitido	sem par de marcas" "$got" "$st"

# --- offset ISO com dois-pontos (-03:00 — caso real do corpus): normalizado -------
D="$TMP/offset-colon"; mkdir -p "$D"
mktask "$D" TASK-001-001-a "2026-01-10T10:00:00-03:00" "2026-01-10T11:00:00-03:00"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert offset-colon 0 "task	TASK-001-001-a	2026-01-10T10:00:00-0300	2026-01-10T11:00:00-0300
completude	1 de 1 TASK(s) com par de marcas
parede	2026-01-10T10:00:00-0300 -> 2026-01-10T11:00:00-0300	60min	1h00min
soma-tasks	60min	1h00min	uniao de intervalos - sobreposicao descontada" "$got" "$st"

# --- sem TASK elegível → exit 2 ---------------------------------------------------
D="$TMP/vazio"; mkdir -p "$D"
got="$(bash "$CC" "$D" 2>/dev/null)"; st=$?
assert sem-tasks 2 "" "$got" "$st"
got="$(bash "$CC" "$TMP/nao-existe" 2>/dev/null)"; st=$?
assert dir-invalido 2 "" "$got" "$st"

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "cycle-clock: $fail de $total casos FALHARAM"
  exit 1
fi
echo "cycle-clock: $total casos verdes"
