#!/usr/bin/env bash
# run.sh — campanha de MUTAÇÃO dos parsers da camada mecânica (decisão 4.401).
#
# Régua do grafo (4.82): "check novo não entra no catálogo sem fixture". Esta suíte prova
# a régua mecanicamente, repetindo o que a auditoria de 2026-09-07 fez à mão (4.384: sete
# emits do lint suprimidos com a suíte verde): para CADA ponto de emissão de diagnóstico
# em artifact-lint.sh, graph.sh e index-check.sh — `emit("SEV", "id", …)` / `finding("SEV",
# "id", …)` — gera um mutante que suprime só aquela linha (`0 && emit(...)`) e roda as
# suítes que cobrem o motor (própria + corpus). Mutante que atravessa tudo verde é um
# diagnóstico que nenhuma fixture exige.
#
# Catraca (expected/survivors.txt): a lista dos sobreviventes CONHECIDOS. Sobrevivente
# fora da lista → vermelho (check ou ramo novo sem fixture — a régua da 4.82); sobrevivente
# listado que passou a morrer → aviso para encurtar a lista (a catraca só desce). Mudar de
# linha muda a chave (`id@linha`): ao editar o motor, regenere com --report e confira.
#
# Uso: scripts/tests/mutation/run.sh [--report] [--only lint|graph|index]
#   --report  só imprime a tabela (morto/sobrevive por mutante); não compara com a catraca.
# Exit: 0 nenhum sobrevivente novo · 1 sobrevivente fora da catraca · 2 uso incorreto.
# Bash 3.2-compatível. ~5 min (≈160 mutantes × suítes de 1–2 s).

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
REPORT=0; ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --report) REPORT=1 ;;
    --only) shift; ONLY="${1:-}" ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
EXP="$HERE/expected/survivors.txt"
OUT="$TMP/survivors.txt"; : > "$OUT"
total=0; killed=0; surv=0

# árvore de trabalho: scripts/ e as suítes que os mutantes rodam (fixtures inclusas)
W="$TMP/w"; mkdir -p "$W/scripts/tests"
cp "$ROOT"/scripts/*.sh "$W/scripts/"
for s in artifact-lint graph index corpus; do cp -R "$ROOT/scripts/tests/$s" "$W/scripts/tests/$s"; done

valido() { # motor → 0 se o script mutado ainda roda na fixture válida do corpus (exit 0/1, sem erro de awk)
  case "$1" in
    lint)  ( cd "$W/scripts/tests/corpus/fixtures" && bash "$W/scripts/artifact-lint.sh" corpus ) >/dev/null 2>"$TMP/err" ;;
    graph) ( cd "$W/scripts/tests/corpus/fixtures" && bash "$W/scripts/graph.sh" corpus --check ) >/dev/null 2>"$TMP/err" ;;
    index) ( cd "$W/scripts/tests/corpus/fixtures" && bash "$W/scripts/index-check.sh" corpus ) >/dev/null 2>"$TMP/err" ;;
  esac
  rc=$?
  [ "$rc" -le 1 ] && ! grep -qiE 'syntax error|awk:' "$TMP/err"
}

run_suites() { # motor → 0 se todas as suítes do motor passam
  case "$1" in
    lint)  bash "$W/scripts/tests/artifact-lint/run.sh" >/dev/null 2>&1 && bash "$W/scripts/tests/corpus/run.sh" >/dev/null 2>&1 ;;
    graph) bash "$W/scripts/tests/graph/run.sh" >/dev/null 2>&1 && bash "$W/scripts/tests/corpus/run.sh" >/dev/null 2>&1 ;;
    index) bash "$W/scripts/tests/index/run.sh" >/dev/null 2>&1 && bash "$W/scripts/tests/corpus/run.sh" >/dev/null 2>&1 ;;
  esac
}

# sanidade: sem mutante, tudo verde (senão a campanha não prova nada)
for m in lint graph index; do
  [ -z "$ONLY" ] || [ "$ONLY" = "$m" ] || continue
  run_suites "$m" || { echo "ERRO: suítes de $m já falham sem mutante — corrija antes de mutar" >&2; exit 1; }
done

mutate() { # motor arquivo função
  motor="$1"; file="$2"; fn="$3"
  orig="$W/scripts/$file"; keep="$TMP/$file.orig"; cp "$orig" "$keep"
  # pontos de emissão: linha + id
  grep -nE "$fn\\(\"(ERROR|WARNING|INFO)\", \"[a-z0-9-]+\"" "$keep" | while IFS=: read -r ln rest; do
    id="$(printf '%s' "$rest" | grep -oE "$fn\\(\"(ERROR|WARNING|INFO)\", \"[a-z0-9-]+\"" | head -1 | sed -E 's/.*", "([a-z0-9-]+)"/\1/')"
    key="$motor $id@$ln"
    # mutante: só ESTA linha tem a chamada suprimida
    # no replacement do sub() o `&` é "texto casado" — `\\&` é o `&` literal (a 1ª versão
    # produzia `0 emit(emit(` e matava 161 de 161 por erro de sintaxe; a sanidade abaixo pegou)
    awk -v n="$ln" -v fn="$fn" 'NR==n { sub(fn "\\(", "0 \\&\\& " fn "(") } { print }' "$keep" > "$orig"
    # sanidade do mutante: tem de continuar RODANDO (sintaxe e exit ≠ 2 na fixture válida) —
    # mutante que quebra o awk mata a suíte por acidente e viraria "morto" falso
    if ! valido "$motor"; then echo "INVALIDO  $key (mutante quebra o script — não conta)"; continue; fi
    if run_suites "$motor"; then echo "SOBREVIVE $key"; echo "$key" >> "$OUT"; else echo "morto     $key"; fi
  done
  cp "$keep" "$orig"
}

{
  [ -n "$ONLY" ] && [ "$ONLY" != "lint" ]  || mutate lint  artifact-lint.sh emit
  [ -n "$ONLY" ] && [ "$ONLY" != "graph" ] || mutate graph graph.sh finding
  [ -n "$ONLY" ] && [ "$ONLY" != "index" ] || mutate index index-check.sh finding
} | tee "$TMP/tabela.txt" | { if [ "$REPORT" -eq 1 ]; then cat; else grep -c . >/dev/null; fi; }

total="$(grep -cE '^(morto|SOBREVIVE)' "$TMP/tabela.txt")"; surv="$(grep -c '^SOBREVIVE' "$TMP/tabela.txt")"; inval="$(grep -c '^INVALIDO' "$TMP/tabela.txt")"; killed=$((total - surv))
echo "---"
echo "mutation: $total mutantes · $killed mortos · $surv sobreviventes · $inval inválidos (não contam)"
[ "$REPORT" -eq 1 ] && exit 0

[ -f "$EXP" ] || { echo "ERRO: catraca ausente em $EXP — rode com --report e congele os sobreviventes conhecidos" >&2; exit 1; }
novos="$(sort "$OUT" | comm -23 - <(sort "$EXP"))"
mortos_listados="$(sort "$EXP" | comm -23 - <(sort "$OUT"))"
[ -z "$mortos_listados" ] || { echo "aviso: sobreviventes listados que agora MORREM (encurte a catraca):"; printf '%s\n' "$mortos_listados" | sed 's/^/  /'; }
if [ -n "$novos" ]; then
  echo "FAIL sobreviventes fora da catraca — diagnóstico sem fixture que o exija (4.82):"
  printf '%s\n' "$novos" | sed 's/^/  /'
  echo "mutation: FAIL"
  exit 1
fi
echo "mutation: catraca respeitada ($surv sobreviventes conhecidos)"
exit 0
