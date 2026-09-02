#!/usr/bin/env bash
# context-cost.sh — compõe o custo de contexto do ciclo para o report de fecho
# (decisão 4.239, extensão da 4.148; janelas medidas e espera entre turnos: 4.354).
# Lê SOMENTE o log de janela escrito pelo hook window-marker, fora do contexto do
# modelo — nunca o transcript: o dono da leitura do transcript é o hook, este
# script é o compositor. O log vive na casa da sessão (decisão 4.314, resolvida
# por session-dir.sh: <casa>/window.log) com leitura dupla do caminho legado
# thoughts/local/session-window.log — sessão que atravessou o update soma os dois
# trechos.
#
# O que este script prova: pico da janela, ranking de tokens por papel, minutos e
# chamadas de ferramenta por papel, espera entre turnos e janelas de um papel por
# etapa são FATOS do log, nunca estimativa do modelo. Sem log ou sem linhas →
# saída vazia, exit 0: a linha do report é telemetria — medida ou omitida, nunca
# estimada.
#
# Uso: context-cost.sh <raiz-do-projeto> [--compose] [--teams]
#      context-cost.sh <raiz-do-projeto> --janelas <papel> [--since <ts>] [--until <ts>]
#                      [--redacao <N>] [-- <arquivo>…]
#
#   (sem flag)  linhas cruas agregadas: `pico <tokens>` · `papel <tipo> <tokens> <spawns>
#               [<segundos> <chamadas>]` (as duas colunas extras só quando o hook mediu
#               a janela — decisão 4.354) · `espera <segundos> <intervalos>10min> <pares>`
#               (só com pares fim-de-turno → início-do-seguinte medidos).
#   --compose   linhas prontas para o report:
#               `pico: ~<N>k tokens`
#               `papel: <tipo> ~<N>k tokens (<M> spawns[ · <N>min[ em <k> medidos]][ · <C> chamadas])`
#                 — maiores primeiro; minutos = soma das janelas medidas do papel (paralelas
#                 somam), `em <k> medidos` quando nem todo spawn trouxe medida
#               `espera: ~<N>min entre turnos em <K> intervalo(s) > 10min`
#                 — soma dos intervalos entre o fim de um turno (linha `janela=`) e o
#                 início do seguinte (`inicio=` da linha seguinte) maiores que 10 min:
#                 espera por humano ou por agent em background; só quando há par medido
#   --teams     (só com --compose) o CHAMADOR declara que o ciclo rodou em
#               AGENT_TEAMS (enum de orquestração do implement — decisão 4.296):
#               havendo ranking, acrescenta a linha `cobertura:` — o ranking cobre
#               só despachos via Task; trabalho de teammate fica fora da medição.
#               Flag do chamador, nunca env var: este script não detecta modo.
#   --janelas   cauda `janelas` da Cronologia do BRIEF (index-contract.md, decisões
#               4.311/4.354) para um papel (substring do agentType, ex.: `scribe`):
#               `janelas: redação <N>min[/<L>l][ · correção <N>min[/<L>l]]…`
#               Cada spawn medido vira intervalo [fim − dur, fim]; os `--redacao N`
#               primeiros (por despacho; default 1 — fan-out da 4.310 passa 1 + nº
#               de redatores) formam a janela de redação (do 1º despacho ao último
#               retorno); os demais são correções, agrupadas por sobreposição.
#               `--since`/`--until` recortam pelo instante do retorno (marcas ISO
#               `YYYY-MM-DDTHH:MM:SS±HHMM`, como a Cronologia); `<L>` = soma de
#               `wc -l` dos arquivos após `--`. Nenhum spawn no recorte → saída
#               vazia (o campo não existe).
#
# Linha do log que não casa os formatos `<ts> janela=<N>[ inicio=<ts>]` /
# `<ts> agente=<tipo> tokens=<N>[ dur=<S>s][ tools=<N>]` é ignorada (4.156: parser
# casa o formato e degrada, nunca inventa); campo extra malformado é ignorado sem
# derrubar a linha.
#
# Exit: 0 sempre (telemetria) · 2 uso incorreto.
# Read-only. Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
USO="uso: context-cost.sh <raiz-do-projeto> [--compose] [--teams] | --janelas <papel> [--since <ts>] [--until <ts>] [--redacao <N>] [-- <arquivo>…]"

[ $# -ge 1 ] || die2 "$USO"
raiz="$1"
shift
compose=0
teams=0
janelas=""
since=""
until_=""
redacao=1
while [ $# -ge 1 ]; do
  case "$1" in
    --compose) compose=1 ;;
    --teams)   teams=1 ;;
    --janelas) shift; [ $# -ge 1 ] || die2 "--janelas exige o papel (substring do agentType)"; janelas="$1" ;;
    --since)   shift; [ $# -ge 1 ] || die2 "--since exige uma marca ISO"; since="$1" ;;
    --until)   shift; [ $# -ge 1 ] || die2 "--until exige uma marca ISO"; until_="$1" ;;
    --redacao) shift; [ $# -ge 1 ] || die2 "--redacao exige um inteiro"; redacao="$1" ;;
    --)        shift; break ;;
    *) die2 "flag desconhecida: $1" ;;
  esac
  shift
done
if [ "$teams" -eq 1 ] && [ "$compose" -eq 0 ]; then
  die2 "--teams requer --compose"
fi
if [ -n "$janelas" ] && { [ "$compose" -eq 1 ] || [ "$teams" -eq 1 ]; }; then
  die2 "--janelas não combina com --compose/--teams"
fi
if [ -z "$janelas" ] && { [ -n "$since" ] || [ -n "$until_" ] || [ $# -gt 0 ] || [ "$redacao" != "1" ]; }; then
  die2 "--since/--until/--redacao/arquivos só valem com --janelas"
fi
case "$redacao" in ''|*[!0-9]*|0) die2 "--redacao deve ser inteiro ≥ 1: $redacao" ;; esac
[ -d "$raiz" ] || die2 "raiz inexistente: $raiz"

# marca ISO: aceita ±HHMM e ±HH:MM (normalizada para ±HHMM, como o cycle-clock)
norma() { printf '%s' "$1" | sed -E 's/([+-][0-9]{2}):([0-9]{2})$/\1\2/'; }
valida() { printf '%s' "$1" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}$'; }
if [ -n "$since" ]; then since="$(norma "$since")"; valida "$since" || die2 "--since fora do formato YYYY-MM-DDTHH:MM:SS±HHMM: $since"; fi
if [ -n "$until_" ]; then until_="$(norma "$until_")"; valida "$until_" || die2 "--until fora do formato YYYY-MM-DDTHH:MM:SS±HHMM: $until_"; fi

# linhas dos artefatos (só --janelas): soma de wc -l; arquivo ausente é aviso, nunca número inventado
linhas=""
if [ -n "$janelas" ] && [ $# -gt 0 ]; then
  linhas=0
  for f in "$@"; do
    if [ -f "$f" ]; then
      n="$(wc -l < "$f" 2>/dev/null | tr -d '[:space:]')"
      case "$n" in ''|*[!0-9]*) n=0 ;; esac
      linhas=$((linhas + n))
    else
      echo "aviso: arquivo inexistente ignorado na contagem de linhas: $f" >&2
    fi
  done
fi

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

awk -v compose="$compose" -v teams="$teams" -v papel="$janelas" -v since="$since" -v until_="$until_" \
    -v redacao="$redacao" -v linhas="$linhas" '
  # --- marcas ISO → segundos (mesmo idioma do cycle-clock.sh: awk POSIX, sem date) ---
  function d2(s, i) { return substr(s, i, 2) + 0 }
  function norma(ts) { if (length(ts) == 25 && substr(ts, 23, 1) == ":") ts = substr(ts, 1, 22) substr(ts, 24, 2); return ts }
  function valida(ts) { return ts ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9][0-9][0-9]$/ }
  function epoch(iso,   y, m, d, H, Mi, S, sign, off, yy, era, yoe, doy, doe, days) {
    y = substr(iso, 1, 4) + 0; m = d2(iso, 6); d = d2(iso, 9)
    H = d2(iso, 12); Mi = d2(iso, 15); S = d2(iso, 18)
    sign = substr(iso, 20, 1); off = d2(iso, 21) * 3600 + d2(iso, 23) * 60
    if (sign == "-") off = -off
    yy = y - (m <= 2 ? 1 : 0)
    era = int((yy >= 0 ? yy : yy - 399) / 400)
    yoe = yy - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    days = era * 146097 + doe - 719468
    return days * 86400 + H * 3600 + Mi * 60 + S - off
  }
  function minutos(seg) { return int((seg + 30) / 60) }
  BEGIN {
    esince = (since != "") ? epoch(since) : ""
    euntil = (until_ != "") ? epoch(until_) : ""
  }
  # janela do turno: `<ts> janela=<N>[ inicio=<ts>]`
  $2 ~ /^janela=[0-9]+$/ && (NF == 2 || (NF == 3 && $3 ~ /^inicio=/)) {
    v = substr($2, 8) + 0
    if (v > pico) pico = v
    ts = norma($1)
    if (valida(ts)) {
      nj++; jstop[nj] = epoch(ts); jini[nj] = ""
      if (NF == 3) { t2 = norma(substr($3, 8)); if (valida(t2)) jini[nj] = epoch(t2) }
    }
    next
  }
  # subagent concluído: `<ts> agente=<tipo> tokens=<N>[ dur=<S>s][ tools=<N>]`
  $2 ~ /^agente=./ && $3 ~ /^tokens=[0-9]+$/ && NF >= 3 {
    a = substr($2, 8)
    t = substr($3, 8) + 0
    if (!(a in soma)) { n++; nome[n] = a }
    soma[a] += t
    cnt[a]++
    d = -1; c = -1
    for (i = 4; i <= NF; i++) {
      if ($i ~ /^dur=[0-9]+s$/) d = substr($i, 5, length($i) - 5) + 0
      else if ($i ~ /^tools=[0-9]+$/) c = substr($i, 7) + 0
    }
    if (d >= 0) { dur[a] += d; nd[a]++ }
    if (c >= 0) { tl[a] += c; nc[a]++ }
    ts = norma($1)
    if (d >= 0 && valida(ts)) { ns++; sa[ns] = a; sfim[ns] = epoch(ts); sdur[ns] = d }
    next
  }
  END {
    if (papel != "") {
      # --- modo --janelas: intervalos [fim - dur, fim] do papel, no recorte, por despacho ---
      k = 0
      for (i = 1; i <= ns; i++) {
        if (index(sa[i], papel) == 0) continue
        if (esince != "" && sfim[i] <= esince) continue
        if (euntil != "" && sfim[i] > euntil) continue
        k++; ini[k] = sfim[i] - sdur[i]; fim[k] = sfim[i]
      }
      if (k == 0) exit 0
      # ordena por despacho (insertion sort — poucos spawns)
      for (i = 2; i <= k; i++) {
        vi = ini[i]; vf = fim[i]; j = i - 1
        while (j >= 1 && ini[j] > vi) { ini[j + 1] = ini[j]; fim[j + 1] = fim[j]; j-- }
        ini[j + 1] = vi; fim[j + 1] = vf
      }
      # grupo 1 = redação: os `redacao` primeiros spawns, do 1º despacho ao último retorno
      g = 1; gini[1] = ini[1]; gfim[1] = fim[1]
      lim = (redacao + 0 < k) ? redacao + 0 : k
      for (i = 2; i <= lim; i++) if (fim[i] > gfim[1]) gfim[1] = fim[i]
      # demais = correções, agrupadas por sobreposição
      for (i = lim + 1; i <= k; i++) {
        if (ini[i] < gfim[g]) { if (fim[i] > gfim[g]) gfim[g] = fim[i] }
        else { g++; gini[g] = ini[i]; gfim[g] = fim[i] }
      }
      out = "janelas: redação " minutos(gfim[1] - gini[1]) "min" (linhas != "" ? "/" linhas "l" : "")
      for (i = 2; i <= g; i++) out = out " · correção " minutos(gfim[i] - gini[i]) "min" (linhas != "" ? "/" linhas "l" : "")
      print out
      exit 0
    }
    # ordena papéis por tokens, decrescente (selection sort — poucos papéis)
    for (i = 1; i <= n; i++) {
      best = i
      for (j = i + 1; j <= n; j++)
        if (soma[nome[j]] > soma[nome[best]]) best = j
      tmp = nome[i]; nome[i] = nome[best]; nome[best] = tmp
    }
    # espera entre turnos: fim do turno i → início do turno i+1 (ordem cronológica)
    for (i = 2; i <= nj; i++) {
      vs = jstop[i]; vi = jini[i]; j = i - 1
      while (j >= 1 && jstop[j] > vs) { jstop[j + 1] = jstop[j]; jini[j + 1] = jini[j]; j-- }
      jstop[j + 1] = vs; jini[j + 1] = vi
    }
    pares = 0; esp = 0; kesp = 0
    for (i = 1; i < nj; i++) {
      if (jini[i + 1] == "") continue
      gap = jini[i + 1] - jstop[i]
      pares++
      if (gap > 600) { esp += gap; kesp++ }
    }
    if (compose) {
      if (pico > 0) printf "pico: ~%dk tokens\n", int((pico + 500) / 1000)
      for (i = 1; i <= n; i++) {
        a = nome[i]
        linha = sprintf("papel: %s ~%dk tokens (%d spawns", a, int((soma[a] + 500) / 1000), cnt[a])
        if (nd[a] > 0) {
          linha = linha sprintf(" · %dmin", minutos(dur[a]))
          if (nd[a] < cnt[a]) linha = linha sprintf(" em %d medidos", nd[a])
        }
        if (nc[a] > 0) linha = linha sprintf(" · %d chamadas", tl[a])
        print linha ")"
      }
      # cobertura (4.296): qualifica ranking existente, nunca inventa linha
      if (teams && n > 0)
        printf "cobertura: ciclo em AGENT_TEAMS — ranking cobre só despachos via Task; trabalho de teammate fora da medição\n"
      if (pares > 0)
        printf "espera: ~%dmin entre turnos em %d intervalo(s) > 10min\n", minutos(esp), kesp
    } else {
      if (pico > 0) printf "pico %d\n", pico
      for (i = 1; i <= n; i++) {
        a = nome[i]
        if (nd[a] > 0 || nc[a] > 0) printf "papel %s %d %d %d %d\n", a, soma[a], cnt[a], dur[a], tl[a]
        else printf "papel %s %d %d\n", a, soma[a], cnt[a]
      }
      if (pares > 0) printf "espera %d %d %d\n", esp, kesp, pares
    }
  }
' "$@"

exit 0
