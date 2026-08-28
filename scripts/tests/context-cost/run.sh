#!/usr/bin/env bash
# run.sh — suíte de regressão do context-cost.sh (decisão 4.239).
#
# Casos inline em diretório temporário. Regras provadas: pico = maior janela do
# log; ranking por papel somado e ordenado decrescente; --compose arredonda para
# ~Nk; sem log / log vazio → saída vazia e exit 0 (telemetria, nunca trava);
# linha malformada é ignorada, nunca inventa número (4.156); --teams (4.296) só
# com --compose, e a linha `cobertura:` só qualifica ranking existente.
#
# Uso: scripts/tests/context-cost/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
CC="$HERE/../../context-cost.sh"

[ -f "$CC" ] || { echo "ERRO: context-cost.sh não encontrado em $CC" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$CC" || { echo "FAIL bash -n context-cost.sh"; exit 1; }
echo "ok   bash -n context-cost.sh"

# repo completo: janelas + agentes (com repetição de papel) + linhas malformadas
R="$TMP/repo"; mkdir -p "$R/thoughts/local"
cat > "$R/thoughts/local/session-window.log" <<'EOF'
2026-08-20T10:00:00-0300 janela=120000
2026-08-20T10:05:00-0300 janela=623400
2026-08-20T10:06:00-0300 agente=keelson:developer tokens=300000
2026-08-20T10:07:00-0300 agente=keelson:code-reviewer tokens=210000
2026-08-20T10:08:00-0300 agente=keelson:developer tokens=151600
linha malformada sem formato nenhum
2026-08-20T10:09:00-0300 agente=sem-tokens
2026-08-20T10:09:30-0300 agente=keelson:qa tokens=abc
2026-08-20T10:10:00-0300 janela=410000
EOF

# saída crua: pico + ranking decrescente, malformadas ignoradas
out="$(bash "$CC" "$R")"
want="pico 623400
papel keelson:developer 451600 2
papel keelson:code-reviewer 210000 1"
if [ "$out" = "$want" ]; then ok cru-completo; else falha "cru-completo: [$out]"; fi

# --compose: arredondamento ~Nk e formato pronto para o report
out="$(bash "$CC" "$R" --compose)"
want="pico: ~623k tokens
papel: keelson:developer ~452k tokens (2 spawns)
papel: keelson:code-reviewer ~210k tokens (1 spawns)"
if [ "$out" = "$want" ]; then ok compose-completo; else falha "compose-completo: [$out]"; fi

# --compose --teams (4.296): linha de cobertura fecha o ranking, flag do chamador
out="$(bash "$CC" "$R" --compose --teams)"
want="pico: ~623k tokens
papel: keelson:developer ~452k tokens (2 spawns)
papel: keelson:code-reviewer ~210k tokens (1 spawns)
cobertura: ciclo em AGENT_TEAMS — ranking cobre só despachos via Task; trabalho de teammate fora da medição"
if [ "$out" = "$want" ]; then ok compose-teams; else falha "compose-teams: [$out]"; fi

# --teams sem --compose: uso incorreto → exit 2 (borda congelada do parser)
if bash "$CC" "$R" --teams >/dev/null 2>&1; then falha "teams-sem-compose: aceitou"; else
  bash "$CC" "$R" --teams >/dev/null 2>&1; [ $? -eq 2 ] && ok teams-sem-compose || falha "teams-sem-compose: exit != 2"
fi

# só janelas (rota sem subagents): pico sai, nenhum papel
R2="$TMP/repo-so-janela"; mkdir -p "$R2/thoughts/local"
printf '2026-08-20T10:00:00-0300 janela=88000\n' > "$R2/thoughts/local/session-window.log"
out="$(bash "$CC" "$R2" --compose)"
if [ "$out" = "pico: ~88k tokens" ]; then ok compose-so-janela; else falha "compose-so-janela: [$out]"; fi

# --teams sem ranking: cobertura NÃO sai — qualifica medição existente, nunca inventa
out="$(bash "$CC" "$R2" --compose --teams)"
if [ "$out" = "pico: ~88k tokens" ]; then ok compose-teams-so-janela; else falha "compose-teams-so-janela: [$out]"; fi

# sem log: saída vazia, exit 0 (telemetria omitida, nunca erro)
R3="$TMP/repo-sem-log"; mkdir -p "$R3"
out="$(bash "$CC" "$R3" --compose)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok sem-log; else falha "sem-log: rc=$rc [$out]"; fi

# log vazio: idem
R4="$TMP/repo-log-vazio"; mkdir -p "$R4/thoughts/local"
: > "$R4/thoughts/local/session-window.log"
out="$(bash "$CC" "$R4")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok log-vazio; else falha "log-vazio: rc=$rc [$out]"; fi

# uso incorreto: sem raiz → exit 2
if bash "$CC" >/dev/null 2>&1; then falha "uso-sem-raiz: aceitou"; else
  bash "$CC" >/dev/null 2>&1; [ $? -eq 2 ] && ok uso-sem-raiz || falha "uso-sem-raiz: exit != 2"
fi

# raiz inexistente → exit 2
if bash "$CC" "$TMP/nao-existe" >/dev/null 2>&1; then falha "raiz-inexistente: aceitou"; else
  bash "$CC" "$TMP/nao-existe" >/dev/null 2>&1; [ $? -eq 2 ] && ok raiz-inexistente || falha "raiz-inexistente: exit != 2"
fi

if [ "$fail" -gt 0 ]; then
  echo "suite context-cost: $fail falha(s)" >&2
  exit 1
fi
echo "suite context-cost: verde"
exit 0
