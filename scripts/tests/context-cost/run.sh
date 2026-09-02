#!/usr/bin/env bash
# run.sh — suíte de regressão do context-cost.sh (decisão 4.239).
#
# Casos inline em diretório temporário, ambiente de sessão controlado pelo
# wrapper cc(). Regras provadas: pico = maior janela do log; ranking por papel
# somado e ordenado decrescente; --compose arredonda para ~Nk; sem log / log
# vazio → saída vazia e exit 0 (telemetria, nunca trava); linha malformada é
# ignorada, nunca inventa número (4.156); --teams (4.296) só com --compose, e a
# linha `cobertura:` só qualifica ranking existente; casa da sessão (4.314):
# window.log da casa é lido, e sessão que atravessou o update soma os dois
# trechos (legado + casa). Campos medidos (decisão 4.354): `dur=`/`tools=` viram
# minutos e chamadas na linha `papel:` (parcial declarado com `em <k> medidos`;
# log antigo sai byte-idêntico), `inicio=` na linha `janela=` vira a linha
# `espera:` (só intervalos > 10 min entre fim de turno e início do seguinte), e
# `--janelas <papel>` compõe a cauda da Cronologia (index-contract.md, literal:
# redação = os `--redacao N` primeiros spawns por despacho; correções agrupadas
# por sobreposição; recorte por `--since`/`--until` no retorno; `/<L>l` só com
# arquivos após `--`); sem spawn no recorte → vazio, exit 0; bordas de uso → 2.
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

# cc — invocação com ambiente de sessão controlado ("" no 1º arg = modo legado)
cc() { sess="$1"; shift; env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$sess" bash "$CC" "$@"; }

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
out="$(cc "" "$R")"
want="pico 623400
papel keelson:developer 451600 2
papel keelson:code-reviewer 210000 1"
if [ "$out" = "$want" ]; then ok cru-completo; else falha "cru-completo: [$out]"; fi

# --compose: arredondamento ~Nk e formato pronto para o report
out="$(cc "" "$R" --compose)"
want="pico: ~623k tokens
papel: keelson:developer ~452k tokens (2 spawns)
papel: keelson:code-reviewer ~210k tokens (1 spawns)"
if [ "$out" = "$want" ]; then ok compose-completo; else falha "compose-completo: [$out]"; fi

# --compose --teams (4.296): linha de cobertura fecha o ranking, flag do chamador
out="$(cc "" "$R" --compose --teams)"
want="pico: ~623k tokens
papel: keelson:developer ~452k tokens (2 spawns)
papel: keelson:code-reviewer ~210k tokens (1 spawns)
cobertura: ciclo em AGENT_TEAMS — ranking cobre só despachos via Task; trabalho de teammate fora da medição"
if [ "$out" = "$want" ]; then ok compose-teams; else falha "compose-teams: [$out]"; fi

# --teams sem --compose: uso incorreto → exit 2 (borda congelada do parser)
if cc "" "$R" --teams >/dev/null 2>&1; then falha "teams-sem-compose: aceitou"; else
  cc "" "$R" --teams >/dev/null 2>&1; [ $? -eq 2 ] && ok teams-sem-compose || falha "teams-sem-compose: exit != 2"
fi

# só janelas (rota sem subagents): pico sai, nenhum papel
R2="$TMP/repo-so-janela"; mkdir -p "$R2/thoughts/local"
printf '2026-08-20T10:00:00-0300 janela=88000\n' > "$R2/thoughts/local/session-window.log"
out="$(cc "" "$R2" --compose)"
if [ "$out" = "pico: ~88k tokens" ]; then ok compose-so-janela; else falha "compose-so-janela: [$out]"; fi

# --teams sem ranking: cobertura NÃO sai — qualifica medição existente, nunca inventa
out="$(cc "" "$R2" --compose --teams)"
if [ "$out" = "pico: ~88k tokens" ]; then ok compose-teams-so-janela; else falha "compose-teams-so-janela: [$out]"; fi

# sem log: saída vazia, exit 0 (telemetria omitida, nunca erro)
R3="$TMP/repo-sem-log"; mkdir -p "$R3"
out="$(cc "" "$R3" --compose)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok sem-log; else falha "sem-log: rc=$rc [$out]"; fi

# log vazio: idem
R4="$TMP/repo-log-vazio"; mkdir -p "$R4/thoughts/local"
: > "$R4/thoughts/local/session-window.log"
out="$(cc "" "$R4")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok log-vazio; else falha "log-vazio: rc=$rc [$out]"; fi

# casa da sessão (4.314): window.log da casa é a fonte
R5="$TMP/repo-casa"; mkdir -p "$R5/thoughts/local/sessions/20260830-100000-sessaoc1"
printf 'sessao: sessao-c-11112222\niniciada: 2026-08-30T10:00:00-0300\nestado: ativa\nslugs:\n' \
  > "$R5/thoughts/local/sessions/20260830-100000-sessaoc1/session.meta"
printf '2026-08-30T10:05:00-0300 janela=200000\n' > "$R5/thoughts/local/sessions/20260830-100000-sessaoc1/window.log"
out="$(cc "sessao-c-11112222" "$R5" --compose)"
if [ "$out" = "pico: ~200k tokens" ]; then ok casa-da-sessao; else falha "casa-da-sessao: [$out]"; fi

# sessão que atravessou o update soma os dois trechos (legado + casa)
printf '2026-08-30T09:00:00-0300 janela=310000\n2026-08-30T09:01:00-0300 agente=keelson:qa tokens=50000\n' \
  > "$R5/thoughts/local/session-window.log"
out="$(cc "sessao-c-11112222" "$R5" --compose)"
want="pico: ~310k tokens
papel: keelson:qa ~50k tokens (1 spawns)"
if [ "$out" = "$want" ]; then ok casa-soma-legado; else falha "casa-soma-legado: [$out]"; fi

# outra sessão não lê o window.log da casa alheia (só o legado)
out="$(cc "sessao-outra-9999" "$R5")"
want="pico 310000
papel keelson:qa 50000 1"
if [ "$out" = "$want" ]; then ok casa-alheia-invisivel; else falha "casa-alheia-invisivel: [$out]"; fi

# uso incorreto: sem raiz → exit 2
if bash "$CC" >/dev/null 2>&1; then falha "uso-sem-raiz: aceitou"; else
  bash "$CC" >/dev/null 2>&1; [ $? -eq 2 ] && ok uso-sem-raiz || falha "uso-sem-raiz: exit != 2"
fi

# raiz inexistente → exit 2
if cc "" "$TMP/nao-existe" >/dev/null 2>&1; then falha "raiz-inexistente: aceitou"; else
  cc "" "$TMP/nao-existe" >/dev/null 2>&1; [ $? -eq 2 ] && ok raiz-inexistente || falha "raiz-inexistente: exit != 2"
fi

# --- campos medidos (4.354) ---------------------------------------------------
R6="$TMP/repo-medido"; mkdir -p "$R6/thoughts/local"
cat > "$R6/thoughts/local/session-window.log" <<'EOF'
2026-08-20T10:00:00-0300 janela=120000
2026-08-20T10:05:00-0300 janela=623400 inicio=2026-08-20T10:01:00-0300
2026-08-20T10:06:00-0300 agente=keelson:developer tokens=300000 dur=3132s tools=41
2026-08-20T10:07:00-0300 agente=keelson:code-reviewer tokens=210000
2026-08-20T10:08:00-0300 agente=keelson:developer tokens=151600 dur=abcs tools=7
2026-08-20T11:10:00-0300 janela=410000 inicio=2026-08-20T10:50:00-0300
2026-08-20T11:30:00-0300 janela=420000 inicio=2026-08-20T11:12:00-0300
EOF
# cru: colunas extras só no papel medido; espera = 1 intervalo > 10min (10:05 → 10:50) de 3 pares
out="$(cc "" "$R6")"
want="pico 623400
papel keelson:developer 451600 2 3132 48
papel keelson:code-reviewer 210000 1
espera 2700 1 3"
if [ "$out" = "$want" ]; then ok cru-medido; else falha "cru-medido: [$out]"; fi
# compose: minutos parciais declarados (dur malformado não conta), chamadas somadas, espera
out="$(cc "" "$R6" --compose)"
want="pico: ~623k tokens
papel: keelson:developer ~452k tokens (2 spawns · 52min em 1 medidos · 48 chamadas)
papel: keelson:code-reviewer ~210k tokens (1 spawns)
espera: ~45min entre turnos em 1 intervalo(s) > 10min"
if [ "$out" = "$want" ]; then ok compose-medido; else falha "compose-medido: [$out]"; fi
# --janelas: fan-out (decompositor + 2 redatores paralelos) e duas correções separadas
R7="$TMP/repo-janelas"; mkdir -p "$R7/thoughts/local"
cat > "$R7/thoughts/local/session-window.log" <<'EOF'
2026-08-20T09:00:00-0300 agente=keelson:scribe tokens=1000 dur=600s tools=3
2026-08-20T10:05:00-0300 agente=keelson:scribe tokens=90000 dur=300s tools=9
2026-08-20T10:20:00-0300 agente=keelson:scribe tokens=90000 dur=840s tools=9
2026-08-20T10:25:00-0300 agente=keelson:scribe tokens=90000 dur=1140s tools=9
2026-08-20T10:30:00-0300 agente=keelson:task-validator tokens=50000 dur=500s tools=20
2026-08-20T10:48:00-0300 agente=keelson:scribe tokens=30000 dur=480s tools=4
2026-08-20T10:55:00-0300 agente=keelson:scribe tokens=30000 dur=300s tools=4
EOF
printf 'a\nb\nc\n' > "$TMP/t1.md"; printf 'x\ny\n' > "$TMP/t2.md"
# expected copiada literal do formato de index-contract.md (4.311): redação <N>min/<N>l · correção <N>min/<N>l
out="$(cc "" "$R7" --janelas scribe --since 2026-08-20T10:00:00-0300 --redacao 3 -- "$TMP/t1.md" "$TMP/t2.md")"
want="janelas: redação 25min/5l · correção 8min/5l · correção 5min/5l"
if [ "$out" = "$want" ]; then ok janelas-fanout; else falha "janelas-fanout: [$out]"; fi
# default --redacao 1, sem recorte e sem arquivos: sem /l; correções agrupadas por sobreposição
out="$(cc "" "$R7" --janelas scribe)"
want="janelas: redação 10min · correção 5min · correção 19min · correção 8min · correção 5min"
if [ "$out" = "$want" ]; then ok janelas-default; else falha "janelas-default: [$out]"; fi
# recorte por retorno; --since com ±HH:MM normalizado
out="$(cc "" "$R7" --janelas scribe --since 2026-08-20T09:30:00-03:00 --until 2026-08-20T10:10:00-0300)"
if [ "$out" = "janelas: redação 5min" ]; then ok janelas-recorte; else falha "janelas-recorte: [$out]"; fi
# arquivo inexistente: aviso em stderr, contagem segue com o que existe
out="$(cc "" "$R7" --janelas scribe --until 2026-08-20T09:30:00-0300 -- "$TMP/t1.md" "$TMP/nao-existe.md" 2>/dev/null)"
if [ "$out" = "janelas: redação 10min/3l" ]; then ok janelas-arquivo-ausente; else falha "janelas-arquivo-ausente: [$out]"; fi
# papel sem spawn no recorte / sem log: vazio, exit 0 (o campo não existe)
out="$(cc "" "$R7" --janelas developer)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok janelas-sem-spawn; else falha "janelas-sem-spawn: rc=$rc [$out]"; fi
out="$(cc "" "$R3" --janelas scribe)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok janelas-sem-log; else falha "janelas-sem-log: rc=$rc [$out]"; fi
# bordas de uso: --janelas com --compose · --since sem --janelas · marca inválida · --redacao 0 → exit 2
for args in "--janelas scribe --compose" "--since 2026-08-20T10:00:00-0300" "--janelas scribe --since 2026-13-99" "--janelas scribe --redacao 0" "--janelas"; do
  # shellcheck disable=SC2086
  if cc "" "$R7" $args >/dev/null 2>&1; then falha "uso-janelas [$args]: aceitou"; else
    # shellcheck disable=SC2086
    cc "" "$R7" $args >/dev/null 2>&1; [ $? -eq 2 ] && ok "uso-janelas [$args]" || falha "uso-janelas [$args]: exit != 2"
  fi
done

if [ "$fail" -gt 0 ]; then
  echo "suite context-cost: $fail falha(s)" >&2
  exit 1
fi
echo "suite context-cost: verde"
exit 0
