#!/usr/bin/env bash
# fake-executor.sh — executor sintético da suíte do eval-run.sh. Determinístico:
# na fase de execução (cwd tem REGUA.md) escreve o deck conforme a MARCA da régua;
# na fase de juiz (prompt contém "DECK AVALIADO") veredita pelo marcador do deck.
# Emite o JSON mínimo que o runner parseia (total_cost_usd/duration_ms fixos).
set -u

PROMPT=""
prev=""
for a in "$@"; do
  [ "$prev" = "-p" ] && PROMPT="$a"
  prev="$a"
done

if [ -f REGUA.md ]; then
  # fase de execução: deck derivado da marca plantada na régua
  mkdir -p deck
  if grep -q "MARCA-VARIA" REGUA.md; then
    # variância intra-braço: alterna bom/ruim por contagem compartilhada
    st="${FAKE_STATE:-.}/varia.count"
    n=0; [ -f "$st" ] && n="$(cat "$st")"
    echo $((n + 1)) > "$st"
    if [ $((n % 2)) -eq 0 ]; then
      echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
    else
      echo "TASK com CORTE-RUIM por camada." > deck/TASK-001-001-ruim.md
    fi
  elif grep -q "MARCA-MA" REGUA.md; then
    echo "TASK com CORTE-RUIM por camada." > deck/TASK-001-001-ruim.md
  elif grep -q "MARCA-PLANT-CAMUFLADA" REGUA.md; then
    echo "TASK aparentemente boa (defeito camuflado)." > deck/TASK-001-001-camuflada.md
  elif grep -q "MARCA-PLANT" REGUA.md; then
    echo "TASK com CORTE-RUIM plantado." > deck/TASK-001-001-plant.md
  elif grep -q "MARCA-CRASH" REGUA.md; then
    # executor que falha DEPOIS de escrever deck íntegro — a amostra é inválida mesmo assim
    echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
    echo '{"result":"parcial","total_cost_usd":0.01,"duration_ms":1000}'
    echo "fake: crash simulado" >&2
    exit 1
  elif grep -q "MARCA-VAZIA" REGUA.md; then
    # executor "bem-sucedido" que não escreve nada
    echo '{"result":"nada feito","total_cost_usd":0.01,"duration_ms":1000}'
    exit 0
  elif grep -q "MARCA-LENTA" REGUA.md; then
    # executor travado: escreve o deck só depois de dormir (o teto deve matar antes)
    sleep 30
    echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
    echo '{"result":"tarde","total_cost_usd":0.01,"duration_ms":30000}'
    exit 0
  elif grep -q "MARCA-JSON-QUEBRADO" REGUA.md; then
    # deck íntegro, mas a saída do executor não é JSON (telemetria degrada, veredito não)
    echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
    echo "isto nao e json {"
    exit 0
  elif grep -q "MARCA-LISTA" REGUA.md; then
    # deck íntegro que registra o que o executor ENXERGA no workspace (prova de isolamento)
    { echo "TASK boa: comportamento fim-a-fim."; echo "VISTO: $(find . -maxdepth 1 | tr '\n' ' ')"; echo "VISTO-DECK: $(find deck -maxdepth 1 | tr '\n' ' ')"; } > "deck/TASK-001-001-$(grep -o 'MARCA-LISTA-[A-Z]*' REGUA.md).md"
    echo "rastro-$(grep -o 'MARCA-LISTA-[A-Z]*' REGUA.md)" > rastro.txt
    echo '{"result":"deck escrito","total_cost_usd":0.01,"duration_ms":1000}'
  elif grep -q "MARCA-JUIZ-CONFLITO" REGUA.md; then
    echo "TASK boa: comportamento fim-a-fim. JUIZ-CONFLITO" > deck/TASK-001-001-conflito.md
    echo '{"result":"deck escrito","total_cost_usd":0.01,"duration_ms":1000}'
  elif grep -q "MARCA-JUIZ-ECO" REGUA.md; then
    echo "TASK boa: comportamento fim-a-fim. JUIZ-ECO" > deck/TASK-001-001-eco.md
    echo '{"result":"deck escrito","total_cost_usd":0.01,"duration_ms":1000}'
  elif grep -q "MARCA-JUIZ-MUDO" REGUA.md; then
    # deck íntegro cujo juiz não conclui — simula falha de infra do juiz (4.377)
    echo "TASK boa: comportamento fim-a-fim. JUIZ-MUDO" > deck/TASK-001-001-muda.md
  else
    echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
  fi
  echo '{"result":"deck escrito","total_cost_usd":0.01,"duration_ms":1000}'
else
  # fase de juiz: reprova se a SEÇÃO DO DECK (após "DECK AVALIADO") traz o marcador —
  # nunca o prompt inteiro, que carrega a rubrica (juiz cego julga só o deck)
  if printf '%s' "$PROMPT" | awk '/DECK AVALIADO/{f=1} f' | grep -q "JUIZ-CONFLITO"; then
    # juiz que se contradiz em linhas distintas → o runner conta INVALIDO (4.389)
    printf '%s\n' '{"result":"motivo: parece bom\nVEREDITO: PASS\nna verdade nao\nVEREDITO: FAIL","total_cost_usd":0.001,"duration_ms":200}'
  elif printf '%s' "$PROMPT" | awk '/DECK AVALIADO/{f=1} f' | grep -q "JUIZ-ECO"; then
    # juiz que ECOA a instrução (PASS e FAIL na mesma linha) e depois conclui — vale a conclusão
    printf '%s\n' '{"result":"Instrucao: responda VEREDITO: PASS ou VEREDITO: FAIL.\nmotivo: deck integro\nVEREDITO: PASS","total_cost_usd":0.001,"duration_ms":200}'
  elif printf '%s' "$PROMPT" | awk '/DECK AVALIADO/{f=1} f' | grep -q "JUIZ-MUDO"; then
    # juiz sem linha VEREDITO parseável → o runner conta INVALIDO (4.377)
    printf '%s\n' '{"result":"motivo: juiz sem conclusao (simulado)","total_cost_usd":0.001,"duration_ms":200}'
  elif printf '%s' "$PROMPT" | awk '/DECK AVALIADO/{f=1} f' | grep -q "CORTE-RUIM"; then
    printf '%s\n' '{"result":"motivo: defeito presente\nVEREDITO: FAIL","total_cost_usd":0.001,"duration_ms":200}'
  else
    printf '%s\n' '{"result":"motivo: deck integro\nVEREDITO: PASS","total_cost_usd":0.001,"duration_ms":200}'
  fi
fi
exit 0
