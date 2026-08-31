#!/usr/bin/env bash
# cycle-clock.sh — relógio do ciclo (decisão 4.325): deriva, das marcas commitadas
# das TASKs de um PLAN, as duas grandezas de duração da implementação (Etapa 4),
# válidas mesmo quando o ciclo atravessou várias sessões (/keelson:continue) — a
# fonte é a closure commitada, imune a rebuild (4.200/4.308/4.82).
#
# Uso: bash cycle-clock.sh <tasks-dir> [PLAN-MMM]
#   <tasks-dir>  diretório com TASK-*.md (ex.: <docsRoot>/<slug>/tasks)
#   [PLAN-MMM]   filtra TASK-MMM-*.md (aceita "PLAN-013" ou "013"); sem filtro, todas.
#   TASK-*-INDEX.md nunca entra.
#
# Fonte por TASK: a ÚLTIMA ocorrência de "**Data início**:" e "**Data conclusão**:"
# (o Histórico de execução, no fim do arquivo, vence citações no corpo). Valor vazio
# ou placeholder "— (não medido)" é buraco conhecido (sem aviso); valor sem token ISO
# (YYYY-MM-DDTHH:MM:SS±HHMM — anotação após o token é tolerada) degrada com
# "WARNING nao-parseavel" em stderr e conta como ausente — nunca inventa número.
# Par com conclusão anterior ao início degrada ("WARNING janela-negativa") e sai da
# soma; as marcas individuais seguem valendo para a parede.
#
# Saída (colunas por TAB):
#   task <id> <inicio|sem-marca> <fim|sem-marca>       # uma por TASK, ordenadas
#   completude  N de M TASK(s) com par de marcas
#   parede      <min inicio> -> <max conclusao>  <N>min  <H>h<MM>min
#               # min sobre TODO início parseável, max sobre TODA conclusão — marca
#               # real conta mesmo sem o par; inclui esperas e dias parados (4.56)
#   soma-tasks  <N>min  <H>h<MM>min  uniao de intervalos - sobreposicao descontada
#               # só pares completos; janelas de waves paralelas não contam 2x
# Grandeza sem marca suficiente sai "<nome>\tomitida\t<motivo>" — medida ou omitida,
# nunca estimada (4.56/4.196). Minutos truncados.
# Exit: 0 = veredito produzido (buracos declarados) · 2 = uso inválido / sem TASK.

set -u
LC_ALL=C
export LC_ALL

dir="${1:-}"
plan="${2:-}"

if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  echo "uso: cycle-clock.sh <tasks-dir> [PLAN-MMM]" >&2
  exit 2
fi
case "$plan" in PLAN-*) plan="${plan#PLAN-}" ;; esac

files="$(find "$dir" -maxdepth 1 -name "TASK-${plan:+${plan}-}*.md" ! -name "*-INDEX.md" 2>/dev/null | sort)"
if [ -z "$files" ]; then
  echo "cycle-clock: nenhuma TASK elegivel em $dir${plan:+ (PLAN-$plan)}" >&2
  exit 2
fi

# --- extração por arquivo -----------------------------------------------------
# iso_of <valor> → token ISO | "" (vazio/placeholder) | "?" (não parseia)
iso_of() {
  v="$(printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -z "$v" ] && { printf '%s' ""; return 0; }
  case "$v" in "— (não medido)"*|"- (não medido)"*|"—") printf '%s' ""; return 0 ;; esac
  iso="$(printf '%s\n' "$v" | sed -n 's/.*\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9][0-9][0-9]\).*/\1/p')"
  if [ -n "$iso" ]; then printf '%s' "$iso"; else printf '%s' "?"; fi
}

rows=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  id="$(basename "$f" .md)"
  rawini="$(awk '/^\*\*Data início\*\*:/ {v=substr($0, index($0,":")+1)} END{print v}' "$f")"
  rawfim="$(awk '/^\*\*Data conclusão\*\*:/ {v=substr($0, index($0,":")+1)} END{print v}' "$f")"
  ini="$(iso_of "$rawini")"
  fim="$(iso_of "$rawfim")"
  if [ "$ini" = "?" ]; then
    echo "WARNING nao-parseavel: $id: Data início '$(printf '%s' "$rawini" | sed 's/^[[:space:]]*//')'" >&2
    ini=""
  fi
  if [ "$fim" = "?" ]; then
    echo "WARNING nao-parseavel: $id: Data conclusão '$(printf '%s' "$rawfim" | sed 's/^[[:space:]]*//')'" >&2
    fim=""
  fi
  rows="${rows}${id}	${ini}	${fim}
"
done <<EOF_FILES
$files
EOF_FILES

# --- agregação (awk POSIX; epoch calculado sem depender de date GNU/BSD) -------
printf '%s' "$rows" | awk -F '	' '
function d2(s, i) { return substr(s, i, 2) + 0 }
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
function hum(min) { return sprintf("%dh%02dmin", int(min / 60), min % 60) }
{
  id = $1; ini = $2; fim = $3
  total++
  printf "task\t%s\t%s\t%s\n", id, (ini == "" ? "sem-marca" : ini), (fim == "" ? "sem-marca" : fim)
  if (ini != "") { e = epoch(ini); if (nini == 0 || e < minini) { minini = e; mininis = ini }; nini++ }
  if (fim != "") { e = epoch(fim); if (nfim == 0 || e > maxfim) { maxfim = e; maxfims = fim }; nfim++ }
  if (ini != "" && fim != "") {
    a = epoch(ini); b = epoch(fim)
    if (b < a) {
      printf "WARNING janela-negativa: %s: conclusao anterior ao inicio — fora da soma\n", id > "/dev/stderr"
    } else {
      pares++
      S[pares] = a; E[pares] = b
    }
  }
}
END {
  printf "completude\t%d de %d TASK(s) com par de marcas\n", pares, total
  if (nini > 0 && nfim > 0 && maxfim >= minini) {
    pmin = int((maxfim - minini) / 60)
    printf "parede\t%s -> %s\t%dmin\t%s\n", mininis, maxfims, pmin, hum(pmin)
  } else if (nini == 0 || nfim == 0) {
    printf "parede\tomitida\t%s\n", (nini == 0 ? "sem inicio parseavel" : "sem conclusao parseavel")
  } else {
    printf "parede\tomitida\tmarcas inconsistentes (max conclusao < min inicio)\n"
  }
  if (pares == 0) {
    printf "soma-tasks\tomitida\t0 de %d TASK(s) com par de marcas\n", total
    exit 0
  }
  # ordena os pares por inicio (insercao — N pequeno) e funde sobreposicoes
  for (i = 2; i <= pares; i++) {
    a = S[i]; b = E[i]; j = i - 1
    while (j >= 1 && S[j] > a) { S[j+1] = S[j]; E[j+1] = E[j]; j-- }
    S[j+1] = a; E[j+1] = b
  }
  soma = 0; cs = S[1]; ce = E[1]
  for (i = 2; i <= pares; i++) {
    if (S[i] <= ce) { if (E[i] > ce) ce = E[i] }
    else { soma += ce - cs; cs = S[i]; ce = E[i] }
  }
  soma += ce - cs
  smin = int(soma / 60)
  printf "soma-tasks\t%dmin\t%s\tuniao de intervalos - sobreposicao descontada\n", smin, hum(smin)
}
'
exit 0
