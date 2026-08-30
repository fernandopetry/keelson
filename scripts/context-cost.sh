#!/usr/bin/env bash
# context-cost.sh — compõe o custo de contexto do ciclo para o report de fecho
# (decisão 4.239, extensão da 4.148). Lê SOMENTE o log de janela escrito pelo
# hook window-marker, fora do contexto do modelo — nunca o transcript: o dono da
# leitura do transcript é o hook, este script é o compositor. O log vive na casa
# da sessão (decisão 4.314, resolvida por session-dir.sh: <casa>/window.log) com
# leitura dupla do caminho legado thoughts/local/session-window.log — sessão que
# atravessou o update soma os dois trechos.
#
# O que este script prova: o pico da janela e o ranking de tokens por papel são
# FATOS do log, nunca estimativa do modelo. Sem log ou sem linhas → saída vazia,
# exit 0: a linha do report é telemetria — medida ou omitida, nunca estimada.
#
# Uso: context-cost.sh <raiz-do-projeto> [--compose] [--teams]
#
#   (sem flag)  linhas cruas agregadas: `pico <tokens>` + `papel <tipo> <tokens> <spawns>`
#               (papéis em ordem decrescente de tokens).
#   --compose   linhas prontas para o report:
#               `pico: ~<N>k tokens`
#               `papel: <tipo> ~<N>k tokens (<M> spawns)` — maiores primeiro.
#   --teams     (só com --compose) o CHAMADOR declara que o ciclo rodou em
#               AGENT_TEAMS (enum de orquestração do implement — decisão 4.296):
#               havendo ranking, acrescenta a linha `cobertura:` — o ranking cobre
#               só despachos via Task; trabalho de teammate fica fora da medição.
#               Flag do chamador, nunca env var: este script não detecta modo.
#
# Linha do log que não casa os formatos `<ts> janela=<N>` / `<ts> agente=<tipo>
# tokens=<N>` é ignorada (4.156: parser casa o formato e degrada, nunca inventa).
#
# Exit: 0 sempre (telemetria) · 2 uso incorreto.
# Read-only. Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }

[ $# -ge 1 ] || die2 "uso: context-cost.sh <raiz-do-projeto> [--compose] [--teams]"
raiz="$1"
shift
compose=0
teams=0
while [ $# -ge 1 ]; do
  case "$1" in
    --compose) compose=1 ;;
    --teams)   teams=1 ;;
    *) die2 "flag desconhecida: $1" ;;
  esac
  shift
done
if [ "$teams" -eq 1 ] && [ "$compose" -eq 0 ]; then
  die2 "--teams requer --compose"
fi
[ -d "$raiz" ] || die2 "raiz inexistente: $raiz"

# casa da sessão (4.314) + caminho legado — awk agrega o que existir
SDS="$(cd "$(dirname "$0")" && pwd)/session-dir.sh"
log_leg="$raiz/thoughts/local/session-window.log"
log_new=""
if [ -f "$SDS" ]; then
  log_new="$(bash "$SDS" "$raiz" window-log 2>/dev/null)" || log_new=""
fi
[ "$log_new" = "$log_leg" ] && log_new=""
set --
[ -n "$log_new" ] && [ -f "$log_new" ] && set -- "$@" "$log_new"
[ -f "$log_leg" ] && set -- "$@" "$log_leg"
[ $# -gt 0 ] || exit 0

awk -v compose="$compose" -v teams="$teams" '
  $2 ~ /^janela=[0-9]+$/ && NF == 2 {
    v = substr($2, 8) + 0
    if (v > pico) pico = v
    next
  }
  $2 ~ /^agente=./ && $3 ~ /^tokens=[0-9]+$/ && NF == 3 {
    a = substr($2, 8)
    t = substr($3, 8) + 0
    if (!(a in soma)) { n++; nome[n] = a }
    soma[a] += t
    cnt[a]++
    next
  }
  END {
    # ordena papéis por tokens, decrescente (selection sort — poucos papéis)
    for (i = 1; i <= n; i++) {
      best = i
      for (j = i + 1; j <= n; j++)
        if (soma[nome[j]] > soma[nome[best]]) best = j
      tmp = nome[i]; nome[i] = nome[best]; nome[best] = tmp
    }
    if (compose) {
      if (pico > 0) printf "pico: ~%dk tokens\n", int((pico + 500) / 1000)
      for (i = 1; i <= n; i++) {
        a = nome[i]
        printf "papel: %s ~%dk tokens (%d spawns)\n", a, int((soma[a] + 500) / 1000), cnt[a]
      }
      # cobertura (4.296): qualifica ranking existente, nunca inventa linha
      if (teams && n > 0)
        printf "cobertura: ciclo em AGENT_TEAMS — ranking cobre só despachos via Task; trabalho de teammate fora da medição\n"
    } else {
      if (pico > 0) printf "pico %d\n", pico
      for (i = 1; i <= n; i++) {
        a = nome[i]
        printf "papel %s %d %d\n", a, soma[a], cnt[a]
      }
    }
  }
' "$@"

exit 0
