#!/usr/bin/env bash
# run.sh — suíte determinística do scripts/eval-run.sh (decisão 4.304).
# Nenhuma chamada de LLM: o fake-executor.sh simula execução e juiz por marcadores.
# Cenários: (1) A bom × B mau + plant detectável → veredito A, rodada válida;
# (2) plant camuflado aprovado → RODADA INVÁLIDA exit 3 (controle positivo da suíte);
# (3) braço com variância intra-braço → HOLD; (4) usos inválidos → exit 2.
# Saídas congeladas em expected/ (linha "resultados:" normalizada — carrega timestamp).
set -u
cd "$(dirname "$0")" || exit 1

RUNNER="../../eval-run.sh"
EXEC="$PWD/fake-executor.sh"
fail=0
ok()  { echo "  ok: $*"; }
bad() { echo "  FALHA: $*" >&2; fail=1; }

bash -n "$RUNNER" 2>/dev/null && ok "bash -n eval-run.sh" || bad "bash -n eval-run.sh"
[ -x "$RUNNER" ] && ok "bit +x do eval-run.sh" || bad "eval-run.sh sem bit +x (4.180/4.195)"
[ -x "$EXEC" ] || chmod +x "$EXEC"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
norm() { grep -v '^- resultados:'; }

# --- cenário 1: A bom × B mau + plant detectável → exit 0, veredito A nos eixos ---
export FAKE_STATE="$TMP/s1"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --plant file:reguas/regua-plant.md --runs 2 --executor "$EXEC" --results "$TMP/r1" 2>&1)"
rc=$?
if [ $rc -eq 0 ]; then ok "cenário 1 exit 0"; else bad "cenário 1 exit $rc (esperado 0)"; fi
printf '%s\n' "$out" | norm > "$TMP/got1"
if diff -u expected/cenario1.txt "$TMP/got1" >/dev/null 2>&1; then ok "cenário 1 saída congelada"
else bad "cenário 1 diverge do expected"; diff -u expected/cenario1.txt "$TMP/got1" >&2 || true; fi

# --- cenário 2: plant camuflado aprovado → RODADA INVÁLIDA, exit 3 ---
export FAKE_STATE="$TMP/s2"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --plant file:reguas/regua-plant-camuflada.md --runs 2 --executor "$EXEC" --results "$TMP/r2" 2>&1)"
rc=$?
if [ $rc -eq 3 ]; then ok "cenário 2 exit 3"; else bad "cenário 2 exit $rc (esperado 3)"; fi
if printf '%s\n' "$out" | grep -q "RODADA INVÁLIDA"; then ok "cenário 2 acusa rodada inválida"
else bad "cenário 2 sem a linha RODADA INVÁLIDA"; fi

# --- cenário 3: variância intra-braço → HOLD, exit 0 ---
export FAKE_STATE="$TMP/s3"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-varia.md --arm B=file:reguas/regua-boa.md \
  --runs 2 --executor "$EXEC" --results "$TMP/r3" 2>&1)"
rc=$?
if [ $rc -eq 0 ]; then ok "cenário 3 exit 0"; else bad "cenário 3 exit $rc (esperado 0)"; fi
printf '%s\n' "$out" | norm > "$TMP/got3"
if diff -u expected/cenario3.txt "$TMP/got3" >/dev/null 2>&1; then ok "cenário 3 saída congelada (HOLD)"
else bad "cenário 3 diverge do expected"; diff -u expected/cenario3.txt "$TMP/got3" >&2 || true; fi

# --- cenário 5 (regressão do bug de caminho relativo): --results relativo deve
# --- produzir os mesmos vereditos — o prompt do juiz era lido após o cd e sumia ---
export FAKE_STATE="$TMP/s5"; mkdir -p "$FAKE_STATE"
rm -rf rel-out
out="$("$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --runs 1 --executor "$EXEC" --results rel-out 2>&1)"
rc=$?
rm -rf rel-out
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "eixo-um: A=PASS · B=FAIL → A"; then
  ok "cenário 5 --results relativo mantém o veredito"
else bad "cenário 5: veredito errado com --results relativo (exit $rc)"; printf '%s\n' "$out" >&2; fi

# --- cenário 4: usos inválidos → exit 2 ---
"$RUNNER" nao-existe --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  >/dev/null 2>&1
[ $? -eq 2 ] && ok "case-dir inexistente → exit 2" || bad "case-dir inexistente não deu exit 2"
"$RUNNER" case --arm A=file:reguas/regua-boa.md >/dev/null 2>&1
[ $? -eq 2 ] && ok "1 braço só → exit 2" || bad "1 braço só não deu exit 2"
"$RUNNER" case --arm A=file:reguas/nao-existe.md --arm B=file:reguas/regua-ma.md \
  --results "$TMP/r5" >/dev/null 2>&1
[ $? -eq 2 ] && ok "régua inexistente → exit 2" || bad "régua inexistente não deu exit 2"

if [ $fail -eq 0 ]; then echo "eval-run: suíte OK"; else echo "eval-run: suíte com FALHAS" >&2; exit 1; fi
