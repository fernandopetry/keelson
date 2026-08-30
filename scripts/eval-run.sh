#!/usr/bin/env bash
# eval-run.sh — runner da camada de evals de comportamento do MANTENEDOR (decisão 4.304).
#
# O que este script prova: dado um caso em evals/ (formato do `claude plugin eval`:
# prompt.md + graders/), executa cada braço (uma versão da doutrina) N vezes em
# workspace isolado, julga cada saída por grader e compõe um veredito CONSULTIVO
# por eixo — A / B / empate / HOLD (divergência intra-braço nunca vira média
# silenciosa). Rodada com --plant exige que o braço-plant (régua deliberadamente
# quebrada) REPROVE nos eixos declarados em <caso>/plant/expect.txt — plant
# aprovado invalida a rodada inteira (controle positivo, 4.186).
#
# Fonte de braço:
#   git:<ref>   → régua extraída de `git show <ref>:commands/tasks.md`
#                 (bloco "## Etapa 1:" até antes de "## Etapa 4:"); extração
#                 vazia é erro, nunca régua inventada (4.156).
#   file:<path> → o arquivo inteiro é a régua.
#
# Uso: eval-run.sh <case-dir> --arm NOME=FONTE --arm NOME=FONTE
#                  [--plant FONTE] [--runs N] [--model M]
#                  [--executor CMD] [--results DIR]
#
#   --arm       exatamente 2 braços; o veredito compara o 1º contra o 2º.
#   --plant     3º braço de controle; exige <caso>/plant/expect.txt.
#   --runs      execuções por braço (default: frontmatter `runs:` do prompt.md, senão 2).
#   --model     passa --model ao executor (default: frontmatter `model:`, senão o do executor).
#   --executor  binário que roda o prompt (default: claude) — a suíte injeta um fake.
#               Toda chamada leva --strict-mcp-config: sem os MCP servers do usuário
#               (hermeticidade e custo — o arranque de MCP dominava o tempo de rodada).
#   --results   raiz das saídas (default: <case-dir>/results — gitignored, nunca versionar).
#
# Graders suportados (frontmatter `type:`): llm (rubrica no corpo; juiz cego — vê só
# o deck, nunca a régua ou o nome do braço; responde `VEREDITO: PASS|FAIL`),
# file_exists (`path:` glob no workspace), regex (`pattern:` + `mode: contains|
# not_contains` + `path:` glob, default deck/*.md).
#
# Custo/duração: somados dos campos total_cost_usd/duration_ms do JSON do executor —
# medidos ou declarados "nao medido", nunca estimados (4.239). O modelo usado é
# registrado no sumário (utilidade é sensível a modelo — 4.209).
#
# Exit: 0 rodada válida (veredito emitido) · 2 uso/caso inválido · 3 RODADA
# INVÁLIDA (plant aprovado). Read-only fora de --results.
# Bash 3.2-compatível, awk POSIX, sem dependências novas.

set -u

die() { echo "eval-run: $*" >&2; exit 2; }

CASE="${1:-}"; [ -n "$CASE" ] || die "uso: eval-run.sh <case-dir> --arm NOME=FONTE --arm NOME=FONTE [opções]"
shift
[ -d "$CASE" ] || die "case-dir inexistente: $CASE"
[ -f "$CASE/prompt.md" ] || die "caso sem prompt.md: $CASE"
[ -d "$CASE/graders" ] || die "caso sem graders/: $CASE"

ARM1=""; ARM2=""; PLANT=""; RUNS=""; MODEL=""; EXECUTOR="claude"; RESULTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --arm)      [ $# -ge 2 ] || die "--arm exige NOME=FONTE"
                if [ -z "$ARM1" ]; then ARM1="$2"; elif [ -z "$ARM2" ]; then ARM2="$2"
                else die "mais de 2 braços — o veredito é par a par"; fi; shift 2 ;;
    --plant)    [ $# -ge 2 ] || die "--plant exige FONTE"; PLANT="$2"; shift 2 ;;
    --runs)     [ $# -ge 2 ] || die "--runs exige N"; RUNS="$2"; shift 2 ;;
    --model)    [ $# -ge 2 ] || die "--model exige M"; MODEL="$2"; shift 2 ;;
    --executor) [ $# -ge 2 ] || die "--executor exige CMD"; EXECUTOR="$2"; shift 2 ;;
    --results)  [ $# -ge 2 ] || die "--results exige DIR"; RESULTS="$2"; shift 2 ;;
    *) die "opção desconhecida: $1" ;;
  esac
done
[ -n "$ARM1" ] && [ -n "$ARM2" ] || die "exatamente 2 --arm são obrigatórios"
if [ -n "$PLANT" ] && [ ! -f "$CASE/plant/expect.txt" ]; then
  die "--plant exige $CASE/plant/expect.txt (graders que o plant deve REPROVAR)"
fi

# Frontmatter do prompt.md: defaults de runs/model; corpo = prompt do braço.
fm() { awk -v k="$1:" '/^---$/{c++;next} c==1 && $1==k {sub(/^[^:]*: */,""); print; exit}' "$CASE/prompt.md"; }
[ -n "$RUNS" ] || RUNS="$(fm runs)"; [ -n "$RUNS" ] || RUNS=2
case "$RUNS" in ''|*[!0-9]*) die "--runs inválido: $RUNS" ;; esac
[ -n "$MODEL" ] || MODEL="$(fm model)"
PROMPT_BODY="$(awk '/^---$/{c++;next} c>=2' "$CASE/prompt.md")"
[ -n "$PROMPT_BODY" ] || die "prompt.md sem corpo após o frontmatter"

TS="$(date +%Y%m%d-%H%M%S)"
[ -n "$RESULTS" ] || RESULTS="$CASE/results"
case "$RESULTS" in /*) ;; *) RESULTS="$PWD/$RESULTS" ;; esac  # subshells fazem cd — caminho relativo quebraria
RES="$RESULTS/$TS"
mkdir -p "$RES/agg" || die "não consegui criar $RES"

# ---------- régua por fonte ----------
regua_para() { # $1 fonte → imprime a régua no stdout
  case "$1" in
    git:*)
      ref="${1#git:}"
      out="$(git show "$ref:commands/tasks.md" 2>/dev/null \
        | awk '/^## Etapa 1:/{f=1} /^## Etapa 4:/{f=0} f')"
      [ -n "$out" ] || die "extração vazia da régua em $1 (ref ou âncoras '## Etapa 1/4' ausentes)"
      printf '%s\n' "$out" ;;
    file:*)
      p="${1#file:}"
      [ -f "$p" ] || die "régua inexistente: $p"
      cat "$p" ;;
    *) die "fonte de braço inválida (git:<ref> ou file:<path>): $1" ;;
  esac
}

# ---------- execução de um braço ----------
executa() { # $1 nome  $2 fonte
  nome="$1"; fonte="$2"
  i=1
  while [ "$i" -le "$RUNS" ]; do
    ws="$RES/run/$nome-r$i"
    mkdir -p "$ws/deck"
    regua_para "$fonte" > "$ws/REGUA.md"
    if [ -d "$CASE/fixtures" ]; then cp -R "$CASE/fixtures/." "$ws/" || die "cópia de fixtures falhou"; fi
    ( cd "$ws" && "$EXECUTOR" -p "$PROMPT_BODY" --output-format json \
        --strict-mcp-config \
        --permission-mode acceptEdits --allowedTools "Read,Write,Edit,Glob,Grep" \
        ${MODEL:+--model "$MODEL"} > raw.json 2> stderr.log )
    rc=$?
    [ $rc -eq 0 ] || echo "eval-run: aviso — executor saiu $rc em $nome-r$i (segue para os graders)" >&2
    julga_workspace "$nome" "$ws"
    i=$((i + 1))
  done
}

# ---------- graders ----------
julga_workspace() { # $1 braço  $2 workspace
  braco="$1"; ws="$2"
  for g in "$CASE"/graders/*.md; do
    [ -f "$g" ] || continue
    gname="$(basename "$g" .md)"
    gtype="$(awk '/^---$/{c++;next} c==1 && $1=="type:"{print $2; exit}' "$g")"
    verdict="INVALIDO"
    case "$gtype" in
      llm)
        jp="$ws/judge-$gname.txt"
        {
          awk '/^---$/{c++;next} c>=2' "$g"
          printf '\n---\nDECK AVALIADO (julgue somente o que está abaixo):\n'
          for f in "$ws"/deck/*.md; do
            [ -f "$f" ] || continue
            printf '\n### arquivo: %s\n' "$(basename "$f")"
            cat "$f"
          done
          printf '\nResponda com exatamente uma linha final: "VEREDITO: PASS" ou "VEREDITO: FAIL", precedida de 1 linha de motivo.\n'
        } > "$jp"
        jd="$ws/judge-$gname"
        mkdir -p "$jd"
        jprompt="$(cat "$jp")"   # ler ANTES do cd do subshell — jp pode ser relativo
        ( cd "$jd" && "$EXECUTOR" -p "$jprompt" --output-format json \
            --strict-mcp-config \
            --permission-mode acceptEdits --allowedTools "Read" \
            ${MODEL:+--model "$MODEL"} > raw.json 2> stderr.log ) || true
        v="$(grep -oE 'VEREDITO: ?(PASS|FAIL)' "$jd/raw.json" 2>/dev/null | tail -1 | grep -oE 'PASS|FAIL')"
        [ -n "$v" ] && verdict="$v"
        ;;
      file_exists)
        glob="$(awk '/^---$/{c++;next} c==1 && $1=="path:"{sub(/^[^:]*: */,""); print; exit}' "$g")"
        [ -n "$glob" ] || die "grader $gname (file_exists) sem path:"
        # expansão de glob do grader é o próprio teste
        # shellcheck disable=SC2086
        set -- $ws/$glob
        if [ -e "$1" ]; then verdict="PASS"; else verdict="FAIL"; fi
        ;;
      regex)
        pat="$(awk '/^---$/{c++;next} c==1 && $1=="pattern:"{sub(/^[^:]*: */,""); print; exit}' "$g")"
        modo="$(awk '/^---$/{c++;next} c==1 && $1=="mode:"{print $2; exit}' "$g")"
        glob="$(awk '/^---$/{c++;next} c==1 && $1=="path:"{sub(/^[^:]*: */,""); print; exit}' "$g")"
        [ -n "$pat" ] || die "grader $gname (regex) sem pattern:"
        [ -n "$glob" ] || glob="deck/*.md"
        hit=1
        # expansão de glob do grader é o próprio teste
        # shellcheck disable=SC2086
        set -- $ws/$glob
        [ -e "$1" ] && grep -qE "$pat" "$@" 2>/dev/null && hit=0
        case "$modo" in
          not_contains) [ $hit -ne 0 ] && verdict="PASS" || verdict="FAIL" ;;
          *)            [ $hit -eq 0 ] && verdict="PASS" || verdict="FAIL" ;;
        esac
        ;;
      *) die "grader $gname com type desconhecido: '$gtype'" ;;
    esac
    printf '%s\n' "$verdict" >> "$RES/agg/$gname.$braco"
  done
}

N1="${ARM1%%=*}"; F1="${ARM1#*=}"
N2="${ARM2%%=*}"; F2="${ARM2#*=}"
[ "$N1" != "$N2" ] || die "os 2 braços precisam de nomes distintos"
regua_para "$F1" > /dev/null   # falha cedo, antes de gastar execução
regua_para "$F2" > /dev/null
[ -z "$PLANT" ] || regua_para "$PLANT" > /dev/null

executa "$N1" "$F1"
executa "$N2" "$F2"
[ -z "$PLANT" ] || executa plant "$PLANT"

# ---------- agregação ----------
conta() { c="$(grep -c "^$2\$" "$RES/agg/$1" 2>/dev/null)"; echo "${c:-0}"; }
status_braco() { # PASS | FAIL | VARIANCIA para $1=grader $2=braço
  p="$(conta "$1.$2" PASS)"; f="$(conta "$1.$2" FAIL)"; i="$(conta "$1.$2" INVALIDO)"
  if [ "$i" -gt 0 ] || { [ "$p" -gt 0 ] && [ "$f" -gt 0 ]; }; then echo "VARIANCIA"
  elif [ "$p" -gt 0 ]; then echo "PASS"
  elif [ "$f" -gt 0 ]; then echo "FAIL"
  else echo "VARIANCIA"; fi
}

SUM="$RES/summary.md"
{
  echo "# eval-run — $(basename "$CASE")"
  echo "braços: $N1=$F1 · $N2=$F2${PLANT:+ · plant=$PLANT}"
  echo "runs por braço: $RUNS · modelo: ${MODEL:-default do executor} · executor: $(basename "$EXECUTOR")"
  echo
  echo "## Veredito por eixo (consultivo — 4.304)"
} > "$SUM"

for g in "$CASE"/graders/*.md; do
  gname="$(basename "$g" .md)"
  s1="$(status_braco "$gname" "$N1")"; s2="$(status_braco "$gname" "$N2")"
  if [ "$s1" = "VARIANCIA" ] || [ "$s2" = "VARIANCIA" ]; then vered="HOLD (variância intra-braço)"
  elif [ "$s1" = "$s2" ]; then vered="empate ($s1 nos dois)"
  elif [ "$s1" = "PASS" ]; then vered="$N1"
  else vered="$N2"; fi
  echo "- $gname: $N1=$s1 · $N2=$s2 → $vered" >> "$SUM"
done

RC=0
if [ -n "$PLANT" ]; then
  echo >> "$SUM"; echo "## Plant (controle positivo — 4.186)" >> "$SUM"
  furos=0
  while IFS= read -r gname; do
    [ -n "$gname" ] || continue
    [ -f "$CASE/graders/$gname.md" ] || die "plant/expect.txt cita grader inexistente: $gname"
    p="$(conta "$gname.plant" PASS)"
    inv="$(conta "$gname.plant" INVALIDO)"
    if [ "$p" -gt 0 ]; then
      echo "- $gname: plant APROVADO ($p PASS) — o grader não detecta o defeito plantado" >> "$SUM"
      furos=$((furos + 1))
    elif [ "$inv" -gt 0 ]; then
      echo "- $gname: plant sem veredito válido ($inv INVALIDO) — não prova detecção" >> "$SUM"
      furos=$((furos + 1))
    else
      echo "- $gname: plant reprovado — grader detecta o defeito (ok)" >> "$SUM"
    fi
  done < "$CASE/plant/expect.txt"
  if [ "$furos" -gt 0 ]; then
    echo >> "$SUM"; echo "**RODADA INVÁLIDA**: $furos grader(s) aprovaram o plant — veredito acima não é evidência." >> "$SUM"
    RC=3
  fi
fi

# ---------- custo (medido ou omitido, nunca estimado — 4.239) ----------
custo_l="custo: nao medido"; dur_l="duracao: nao medida"
jsons="$(find "$RES/run" -name raw.json 2>/dev/null)"
if [ -n "$jsons" ]; then
  tot="$(printf '%s\n' "$jsons" | wc -l | tr -d ' ')"
  soma="$(printf '%s\n' "$jsons" | xargs grep -ho '"total_cost_usd":[0-9.]*' 2>/dev/null \
    | awk -F: '{s+=$2; n++} END{if(n>0) printf "%.4f %d", s, n}')"
  if [ -n "$soma" ]; then
    val="${soma% *}"; n="${soma#* }"
    if [ "$n" = "$tot" ]; then custo_l="custo: US\$$val ($n chamadas)"
    else custo_l="custo: nao medido ($n de $tot chamadas com campo)"; fi
  fi
  dsoma="$(printf '%s\n' "$jsons" | xargs grep -ho '"duration_ms":[0-9]*' 2>/dev/null \
    | awk -F: '{s+=$2; n++} END{if(n>0) printf "%d %d", s, n}')"
  if [ -n "$dsoma" ]; then
    dv="${dsoma% *}"; dn="${dsoma#* }"
    [ "$dn" = "$tot" ] && dur_l="duracao: $((dv / 1000))s somados" || dur_l="duracao: nao medida"
  fi
fi
{ echo; echo "## Telemetria"; echo "- $custo_l"; echo "- $dur_l"; echo "- resultados: $RES"; } >> "$SUM"

cat "$SUM"
exit $RC
