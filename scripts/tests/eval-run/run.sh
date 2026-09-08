#!/usr/bin/env bash
# run.sh — suíte determinística do scripts/eval-run.sh (decisão 4.304).
# Nenhuma chamada de LLM: o fake-executor.sh simula execução e juiz por marcadores.
# Cenários: (1) A bom × B mau + plant detectável → veredito A, rodada válida;
# (2) plant camuflado aprovado → RODADA INVÁLIDA exit 3 (controle positivo da suíte);
# (3) braço com variância intra-braço → HOLD; (4) usos inválidos → exit 2 — inclusive
# `--runs 0` e fonte `git:` em caso sem `regua:` declarada (4.377); (5) --results relativo;
# (6) juiz sem veredito → HOLD por falha de infra, rótulo distinto de variância (4.377);
# (7) fonte `git:` com `regua:` + âncoras declaradas no caso, extraída de um repo git
# temporário — cabeçalho e rodapé com marcas más/plant provam que o recorte não vaza;
# (8) âncora declarada ausente ou fora de ordem → exit 2 antes de executar (4.379);
# (9–15, 4.389) falha de infra nunca vira evidência: executor com exit≠0, sem deck ou
# estourando --timeout → amostra INVALIDA (HOLD infra, juiz não roda); juiz conflitante →
# INVALIDO (eco da instrução descontado); JSON inválido → veredito pelo deck, custo "nao
# medido"; colisão de timestamp → sufixo; caminhos com espaço; isolamento entre braços.
# Saídas congeladas em expected/ (linha "resultados:" normalizada — carrega timestamp).
set -u
# git herdado de contexto de hook (pre-commit exporta GIT_INDEX_FILE etc.) aponta para
# OUTRO repo — neutralizar antes de qualquer git nos repos sintéticos (4.383)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
cd "$(dirname "$0")" || exit 1

RUNNER="../../eval-run.sh"
RUNNER_ABS="$(cd ../.. && pwd)/eval-run.sh"
HERE="$PWD"
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

# --- cenário 6: juiz sem veredito (INVALIDO) → HOLD por falha de infra, exit 0 (4.377) ---
export FAKE_STATE="$TMP/s6"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-juiz-mudo.md --arm B=file:reguas/regua-boa.md \
  --runs 2 --executor "$EXEC" --results "$TMP/r6" 2>&1)"
rc=$?
if [ $rc -eq 0 ]; then ok "cenário 6 exit 0"; else bad "cenário 6 exit $rc (esperado 0)"; fi
printf '%s\n' "$out" | norm > "$TMP/got6"
if diff -u expected/cenario6.txt "$TMP/got6" >/dev/null 2>&1; then ok "cenário 6 saída congelada (HOLD de infra ≠ variância)"
else bad "cenário 6 diverge do expected"; diff -u expected/cenario6.txt "$TMP/got6" >&2 || true; fi

# --- cenário 7: fonte git: com regua/âncoras declaradas no caso (4.377) ---
GR="$TMP/gitrepo"; mkdir -p "$GR"
( cd "$GR" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
cat > "$GR/regua-ancoras.md" <<'EOR'
# Cabeçalho que NÃO deve entrar na régua. MARCA-MA
## Regua
Régua sintética boa vinda do git. MARCA-BOA
## Fim
Rodapé que não deve entrar. MARCA-PLANT
EOR
( cd "$GR" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m regua )
export FAKE_STATE="$TMP/s7"; mkdir -p "$FAKE_STATE"
out="$( cd "$GR" && "$RUNNER_ABS" "$HERE/case-git" --arm A=git:HEAD --arm B="file:$HERE/reguas/regua-ma.md" \
  --runs 1 --executor "$EXEC" --results "$TMP/r7" 2>&1 )"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "eixo-um: A=PASS · B=FAIL → A"; then
  ok "cenário 7 fonte git: extraída pela regua declarada no caso"
else bad "cenário 7: fonte git: com regua declarada falhou (exit $rc)"; printf '%s\n' "$out" >&2; fi
got7="$(cat "$TMP"/r7/*/run/A-r1/REGUA.md 2>/dev/null)"
if [ "$got7" = "## Regua
Régua sintética boa vinda do git. MARCA-BOA" ]; then ok "cenário 7 recorte entre âncoras exato (sem cabeçalho/rodapé)"
else bad "cenário 7: recorte divergente: [$got7]"; fi

# --- cenário 8: âncoras declaradas ausentes ou fora de ordem → exit 2 ANTES de executar (4.379) ---
GR8="$TMP/gitrepo-ancoras"; mkdir -p "$GR8"
( cd "$GR8" && { git init -q -b main 2>/dev/null || { git init -q; git checkout -qb main; }; } )
printf '## Regua\nRégua boa. MARCA-BOA\n## Outra secao sem a ancora Fim\nTrecho que vazaria. MARCA-MA\n' > "$GR8/regua-ancoras.md"
( cd "$GR8" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m regua )
( cd "$GR8" && "$RUNNER_ABS" "$HERE/case-git" --arm A=git:HEAD --arm B="file:$HERE/reguas/regua-ma.md" \
  --runs 1 --executor "$EXEC" --results "$TMP/r8a" >/dev/null 2>&1 ); rc=$?
[ $rc -eq 2 ] && ok "cenário 8 regua_fim ausente → exit 2 (nunca régua maior)" || bad "cenário 8: regua_fim ausente saiu $rc (esperado 2)"
[ -d "$TMP/r8a" ] && bad "cenário 8: executou braço com âncora ausente" || ok "cenário 8 nada executado com âncora ausente"
printf '## Fim\n## Regua\nRégua boa. MARCA-BOA\n' > "$GR8/regua-ancoras.md"
( cd "$GR8" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m ordem )
( cd "$GR8" && "$RUNNER_ABS" "$HERE/case-git" --arm A=git:HEAD --arm B="file:$HERE/reguas/regua-ma.md" \
  --runs 1 --executor "$EXEC" --results "$TMP/r8b" >/dev/null 2>&1 ); rc=$?
[ $rc -eq 2 ] && ok "cenário 8 regua_fim antes do início → exit 2" || bad "cenário 8: fim antes do início saiu $rc (esperado 2)"
printf 'sem a ancora de inicio\n## Fim\n' > "$GR8/regua-ancoras.md"
( cd "$GR8" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m inicio )
( cd "$GR8" && "$RUNNER_ABS" "$HERE/case-git" --arm A=git:HEAD --arm B="file:$HERE/reguas/regua-ma.md" \
  --runs 1 --executor "$EXEC" --results "$TMP/r8c" >/dev/null 2>&1 ); rc=$?
[ $rc -eq 2 ] && ok "cenário 8 regua_inicio ausente → exit 2" || bad "cenário 8: início ausente saiu $rc (esperado 2)"

# --- cenário 9 (4.389): executor que FALHA (exit 1) mesmo tendo escrito deck → amostra
# --- INVALIDA, HOLD por infra — o juiz nunca vê o deck de uma execução falha ---
export FAKE_STATE="$TMP/s9"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-crash.md --arm B=file:reguas/regua-boa.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r9" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "eixo-um: A=INVALIDO · B=PASS → HOLD (sem veredito válido"; then ok "cenário 9 executor com exit≠0 → amostra INVALIDA (HOLD infra)"
else bad "cenário 9: executor falho não virou INVALIDO (exit $rc)"; printf '%s\n' "$out" >&2; fi
find "$TMP/r9" -path '*/run/A-r1/infra.txt' | grep -q . && ok "cenário 9 motivo em infra.txt" || bad "cenário 9 sem infra.txt"
find "$TMP/r9" -path '*/run/A-r1/judge-eixo-um/raw.json' | grep -q . && bad "cenário 9: juiz rodou sobre execução falha" || ok "cenário 9 juiz não rodou sobre a amostra inválida"
printf '%s\n' "$out" | grep -q "amostra INVALIDA" && ok "cenário 9 aviso em stderr" || bad "cenário 9 sem aviso"

# --- cenário 10: executor "bem-sucedido" sem deck → INVALIDA (deck vazio nunca é PASS) ---
export FAKE_STATE="$TMP/s10"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-vazia.md --arm B=file:reguas/regua-boa.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r10" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "sem-defeito: A=INVALIDO · B=PASS → HOLD (sem veredito válido"; then ok "cenário 10 execução sem deck → INVALIDA (juiz não aprova o vazio)"
else bad "cenário 10: execução sem deck não virou INVALIDO (exit $rc)"; printf '%s\n' "$out" >&2; fi

# --- cenário 11: executor travado → --timeout mata e a amostra é INVALIDA; a rodada termina ---
export FAKE_STATE="$TMP/s11"; mkdir -p "$FAKE_STATE"
t0="$(date +%s)"
out="$("$RUNNER" case --arm A=file:reguas/regua-lenta.md --arm B=file:reguas/regua-boa.md \
  --runs 1 --timeout 2 --executor "$EXEC" --results "$TMP/r11" 2>&1)"
rc=$?
dt=$(( $(date +%s) - t0 ))
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "estourou o teto de 2s" && printf '%s\n' "$out" | grep -q "eixo-um: A=INVALIDO"; then ok "cenário 11 timeout mata o executor → INVALIDA"
else bad "cenário 11: timeout não acusado (exit $rc)"; printf '%s\n' "$out" >&2; fi
[ "$dt" -lt 20 ] && ok "cenário 11 rodada terminou em ${dt}s (executor dormia 30s)" || bad "cenário 11: rodada levou ${dt}s — o teto não matou o executor"
"$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md --timeout 0 --executor "$EXEC" --results "$TMP/r11b" >/dev/null 2>&1
[ $? -eq 2 ] && ok "cenário 11 --timeout 0 → exit 2" || bad "cenário 11: --timeout 0 aceito"

# --- cenário 12: juiz conflitante (PASS e FAIL em linhas distintas) → INVALIDO; eco da instrução não conta ---
export FAKE_STATE="$TMP/s12"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-juiz-conflito.md --arm B=file:reguas/regua-juiz-eco.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r12" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "eixo-um: A=INVALIDO · B=PASS → HOLD (sem veredito válido"; then ok "cenário 12 juiz conflitante → INVALIDO; eco da instrução → conclusão vale"
else bad "cenário 12: conflito/eco do juiz mal lidos (exit $rc)"; printf '%s\n' "$out" >&2; fi

# --- cenário 13: JSON inválido do executor com deck íntegro → veredito segue, telemetria degrada ---
export FAKE_STATE="$TMP/s13"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" case --arm A=file:reguas/regua-json-quebrado.md --arm B=file:reguas/regua-ma.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r13" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "eixo-um: A=PASS · B=FAIL → A" && printf '%s\n' "$out" | grep -q "custo: nao medido (3 de 4 chamadas com campo)"; then ok "cenário 13 JSON inválido: veredito pelo deck, custo declarado não medido"
else bad "cenário 13: JSON inválido mal tratado (exit $rc)"; printf '%s\n' "$out" >&2; fi

# --- cenário 14: mesmo timestamp duas vezes → diretórios distintos, agg nunca soma ---
export FAKE_STATE="$TMP/s14"; mkdir -p "$FAKE_STATE"
EVAL_RUN_TS=20260907-120000 "$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r14" >/dev/null 2>&1
out="$(EVAL_RUN_TS=20260907-120000 "$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --runs 1 --executor "$EXEC" --results "$TMP/r14" 2>&1)"
if [ -d "$TMP/r14/20260907-120000" ] && [ -d "$TMP/r14/20260907-120000-2" ] && [ "$(wc -l < "$TMP/r14/20260907-120000-2/agg/eixo-um.A" | tr -d ' ')" = "1" ] \
   && printf '%s\n' "$out" | grep -q "resultados: $TMP/r14/20260907-120000-2"; then ok "cenário 14 colisão de timestamp → sufixo -2, agg isolado"
else bad "cenário 14: rodadas no mesmo segundo se misturaram"; ls "$TMP/r14" >&2; fi

# --- cenário 15: caminhos com espaço (caso e --results) e isolamento entre braços/runs ---
CS="$TMP/caso com espaco"; cp -R case "$CS"
export FAKE_STATE="$TMP/s15"; mkdir -p "$FAKE_STATE"
out="$("$RUNNER" "$CS" --arm A=file:reguas/regua-lista-a.md --arm B=file:reguas/regua-lista-b.md \
  --runs 2 --executor "$EXEC" --results "$TMP/saida com espaco" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q "deck-presente: A=PASS · B=PASS" && printf '%s\n' "$out" | grep -q "sem-defeito: A=PASS · B=PASS"; then ok "cenário 15 caminhos com espaço: graders file_exists/regex/llm funcionam"
else bad "cenário 15: caminho com espaço quebrou a rodada (exit $rc)"; printf '%s\n' "$out" >&2; fi
dA="$(cat "$TMP/saida com espaco"/*/run/A-r1/deck/TASK-001-001-MARCA-LISTA-ALFA.md 2>/dev/null)"
dB2="$(cat "$TMP/saida com espaco"/*/run/B-r2/deck/TASK-001-001-MARCA-LISTA-BETA.md 2>/dev/null)"
if printf '%s' "$dA" | grep -q "VISTO-DECK:  *$" || printf '%s' "$dA" | grep -qv "BETA"; then :; fi
if ! printf '%s' "$dB2" | grep -q "ALFA" && ! printf '%s' "$dB2" | grep -q "rastro" && ! printf '%s' "$dA" | grep -q "BETA"; then ok "cenário 15 isolamento: braço/run não enxerga deck nem rastro de outro"
else bad "cenário 15: vazamento entre workspaces"; printf 'A: %s\nB2: %s\n' "$dA" "$dB2" >&2; fi
if [ "$(cat "$TMP/saida com espaco"/*/run/A-r1/REGUA.md)" != "$(cat "$TMP/saida com espaco"/*/run/B-r1/REGUA.md)" ]; then ok "cenário 15 cada braço recebe a própria régua"
else bad "cenário 15: réguas iguais nos dois braços"; fi

# --- cenário 4: usos inválidos → exit 2 ---
"$RUNNER" nao-existe --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  >/dev/null 2>&1
[ $? -eq 2 ] && ok "case-dir inexistente → exit 2" || bad "case-dir inexistente não deu exit 2"
"$RUNNER" case --arm A=file:reguas/regua-boa.md >/dev/null 2>&1
[ $? -eq 2 ] && ok "1 braço só → exit 2" || bad "1 braço só não deu exit 2"
"$RUNNER" case --arm A=file:reguas/nao-existe.md --arm B=file:reguas/regua-ma.md \
  --results "$TMP/r5" >/dev/null 2>&1
[ $? -eq 2 ] && ok "régua inexistente → exit 2" || bad "régua inexistente não deu exit 2"
"$RUNNER" case --arm A=file:reguas/regua-boa.md --arm B=file:reguas/regua-ma.md \
  --runs 0 --executor "$EXEC" --results "$TMP/r8" >/dev/null 2>&1
[ $? -eq 2 ] && ok "--runs 0 → exit 2 (rodada sem execução não é veredito, 4.377)" || bad "--runs 0 não deu exit 2"
"$RUNNER" case --arm A=git:HEAD --arm B=file:reguas/regua-ma.md \
  --results "$TMP/r9" >/dev/null 2>&1
[ $? -eq 2 ] && ok "git: em caso sem regua: → exit 2 (régua nunca adivinhada, 4.377)" || bad "git: sem regua: não deu exit 2"

if [ $fail -eq 0 ]; then echo "eval-run: suíte OK"; else echo "eval-run: suíte com FALHAS" >&2; exit 1; fi
