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
  else
    echo "TASK boa: comportamento fim-a-fim." > deck/TASK-001-001-boa.md
  fi
  echo '{"result":"deck escrito","total_cost_usd":0.01,"duration_ms":1000}'
else
  # fase de juiz: reprova se a SEÇÃO DO DECK (após "DECK AVALIADO") traz o marcador —
  # nunca o prompt inteiro, que carrega a rubrica (juiz cego julga só o deck)
  if printf '%s' "$PROMPT" | awk '/DECK AVALIADO/{f=1} f' | grep -q "CORTE-RUIM"; then
    printf '%s\n' '{"result":"motivo: defeito presente\nVEREDITO: FAIL","total_cost_usd":0.001,"duration_ms":200}'
  else
    printf '%s\n' '{"result":"motivo: deck integro\nVEREDITO: PASS","total_cost_usd":0.001,"duration_ms":200}'
  fi
fi
exit 0
