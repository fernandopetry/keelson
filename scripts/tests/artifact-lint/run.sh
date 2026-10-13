#!/usr/bin/env bash
# run.sh — suíte de regressão do artifact-lint.sh (decisão 4.152).
# Contrato do catálogo: docs/_meta/conventions/lint-contract.md.
#
# Fixtures são slugs sintéticos em fixtures/; as saídas esperadas vivem em expected/.
# Regra da suíte: fixture válida sai limpa (zero achado espúrio) e todo defeito
# plantado é acusado pelo check esperado. Check novo no catálogo → fixture nova.
# "legado" prova o rebaixamento ERROR → WARNING [legacy] em artefato Done.
# "defeitos-b" (4.384) planta, um por artefato, os checks do catálogo que nenhuma
# fixture exigia (spec-fr-sem-rfc, spec-nfr-sem-numero, spec-sem-premissa,
# plan-data-formato, plan-dod-vazia, task-tipo-enum, task-bugfix-forma-legada) —
# suprimir qualquer um deles no motor deixa a suíte vermelha.
# "defeitos-c" (4.401 — campanha de mutação) planta os RAMOS que a campanha achou sem
# fixture: cada campo de cabeçalho ausente (Slug/Status/Versão/Autor/Data), cada seção e
# subseção ausente (1.1, 1.3, 4.2 da SPEC; Aderência/Cobertura do PLAN; as do corpo da
# TASK, "Inclui" com Escopo presente), cada campo de DEC ausente, e o marcador de nome
# para refactor e chore.
# "defeitos-d" (4.427) planta area sensivel (dados pessoais em exportacao) sem NFR de
# seguranca nem AC de negacao → spec-area-sensivel-sem-negacao (W); a fixture "valido" e a
# contraprova: SPEC de login com AC de bloqueio fica em silencio.
#
# Uso: scripts/tests/artifact-lint/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/../../artifact-lint.sh"
FIX="$HERE/fixtures"
EXP="$HERE/expected"

[ -f "$LINT" ] || { echo "ERRO: artifact-lint.sh não encontrado em $LINT" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

runcase() { # nome alvo exit-esperado arquivo-esperado
  name="$1"; alvo="$2"; wantexit="$3"; expfile="$4"
  total=$((total + 1))
  out="$TMP/$name.out"
  ( cd "$FIX" && bash "$LINT" "$alvo" ) > "$out" 2> "$TMP/$name.err"
  got=$?
  if [ "$got" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $got (esperado $wantexit)"
    sed 's/^/  stderr: /' "$TMP/$name.err"
    fail=$((fail + 1)); return
  fi
  if ! diff -u "$EXP/$expfile" "$out" > "$TMP/$name.diff" 2>&1; then
    echo "FAIL $name: saída difere do esperado"
    head -40 "$TMP/$name.diff" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

bash -n "$LINT" || { echo "FAIL bash -n artifact-lint.sh"; exit 1; }
echo "ok   bash -n artifact-lint.sh"

runcase valido          valido   0 valido.txt
runcase defeitos        defeitos 1 defeitos.txt
runcase legado          legado   0 legado.txt
runcase defeitos-b      defeitos-b 1 defeitos-b.txt
runcase defeitos-c      defeitos-c 1 defeitos-c.txt
runcase defeitos-d      defeitos-d 0 defeitos-d.txt
runcase arquivo-valido  valido/specs/SPEC-001-login.md 0 arquivo-unico-valido.txt
runcase arquivo-defeito defeitos/tasks/TASK-001-005-refactor-extrai.md 1 arquivo-unico-defeito.txt
runcase arquivo-mutacao-contada valido/tasks/TASK-001-003-mutacao-contada.md 0 arquivo-unico-mutacao-contada.txt

# determinismo: duas execuções idênticas byte a byte
total=$((total + 1))
( cd "$FIX" && bash "$LINT" defeitos ) > "$TMP/d1.out" 2>/dev/null
( cd "$FIX" && bash "$LINT" defeitos ) > "$TMP/d2.out" 2>/dev/null
if cmp -s "$TMP/d1.out" "$TMP/d2.out"; then echo "ok   determinismo"
else echo "FAIL determinismo: execuções divergem"; fail=$((fail + 1)); fi

# read-only: nenhuma fixture modificada
total=$((total + 1))
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-antes.txt"
( cd "$FIX" && bash "$LINT" valido >/dev/null 2>&1; bash "$LINT" defeitos >/dev/null 2>&1 )
( cd "$FIX" && find . -type f -exec cksum {} \; | sort ) > "$TMP/ck-depois.txt"
if cmp -s "$TMP/ck-antes.txt" "$TMP/ck-depois.txt"; then echo "ok   read-only"
else echo "FAIL read-only: fixture modificada"; fail=$((fail + 1)); fi

# --fix (4.478): só as classes mecânicas, só TASK; FIXED antes dos achados; idempotente
total=$((total + 1))
mkdir -p "$TMP/fx" && cp -R "$FIX/defeitos" "$TMP/fx/d" && cp -R "$FIX/defeitos-c" "$TMP/fx/c"
fixout="$(bash "$LINT" --fix "$TMP/fx/d" 2>/dev/null </dev/null)"
if printf '%s\n' "$fixout" | grep -q '^FIXED	task-criterio-cifrao-aspas-duplas	1 segmento(s) .* (TASK-001-002-corrige-login.md)$' \
   && grep -qF "grep -cE '^\\s*return \$this->guard\\(\\)' src/Login.php" "$TMP/fx/d/tasks/TASK-001-002-corrige-login.md" \
   && ! printf '%s\n' "$fixout" | grep -q 'task-criterio-cifrao-aspas-duplas	1 criterio'; then echo "ok   fix-cifrao-vira-aspas-simples"
else echo "FAIL fix-cifrao-vira-aspas-simples"; printf '%s\n' "$fixout" | grep -i 'cifrao' | sed 's/^/  /'; fail=$((fail + 1)); fi
total=$((total + 1))
fixc="$(bash "$LINT" --fix "$TMP/fx/c" 2>/dev/null </dev/null)"
if printf '%s\n' "$fixc" | grep -q '^FIXED	task-secao-ausente	secao "## Riscos especificos" acrescentada do template (TASK-001-001-limpa.md)$' \
   && printf '%s\n' "$fixc" | grep -q '^FIXED	task-secao-ausente	secao "## Historico de execucao" acrescentada do template (TASK-001-001-limpa.md)$' \
   && ! printf '%s\n' "$fixc" | grep -q 'task-secao-ausente	secao "## \(Riscos especificos\|Historico de execucao\)" ausente (TASK-001-001-limpa.md)' \
   && printf '%s\n' "$fixc" | grep -q 'task-secao-ausente	secao "## Criterios de pronto" ausente (TASK-001-001-limpa.md)' \
   && grep -q '^## Riscos específicos$' "$TMP/fx/c/tasks/TASK-001-001-limpa.md" && grep -q '^\*\*Commit SHA\*\*: $' "$TMP/fx/c/tasks/TASK-001-001-limpa.md"; then echo "ok   fix-secoes-fixas-do-template"
else echo "FAIL fix-secoes-fixas-do-template"; printf '%s\n' "$fixc" | grep 'limpa' | sed 's/^/  /'; fail=$((fail + 1)); fi
total=$((total + 1))
ck1="$(cd "$TMP/fx" && find . -type f -exec cksum {} \; | sort)"
bash "$LINT" --fix "$TMP/fx/d" >/dev/null 2>&1 </dev/null; bash "$LINT" --fix "$TMP/fx/c" >/dev/null 2>&1 </dev/null
ck2="$(cd "$TMP/fx" && find . -type f -exec cksum {} \; | sort)"
n2="$(bash "$LINT" --fix "$TMP/fx/c" 2>/dev/null </dev/null | grep -c '^FIXED')"
if [ "$ck1" = "$ck2" ] && [ "$n2" = "0" ]; then echo "ok   fix-idempotente"; else echo "FAIL fix-idempotente ($n2 FIXED na 2a rodada)"; fail=$((fail + 1)); fi
total=$((total + 1))
printf '# TASK-001-009: x\n\n**Status**: Todo\n\n## Critérios de pronto\n\n- [ ] a — `grep -c "it'"'"'s $x" f` → 1\n- [ ] b — `grep -c "^foo$" f` → 1\n\n## Histórico de execução\n\n**Commit SHA**: \n' > "$TMP/fx/c/tasks/TASK-001-009-mista.md"
bash "$LINT" --fix "$TMP/fx/c/tasks/TASK-001-009-mista.md" >/dev/null 2>&1 </dev/null
if grep -q 'grep -c "it'"'"'s \\$x" f' "$TMP/fx/c/tasks/TASK-001-009-mista.md" && grep -q 'grep -c "^foo$" f' "$TMP/fx/c/tasks/TASK-001-009-mista.md" \
   && [ "$(grep -n '^## ' "$TMP/fx/c/tasks/TASK-001-009-mista.md" | cut -d: -f2 | paste -sd'|' -)" = "## Critérios de pronto|## Riscos específicos|## Histórico de execução" ]; then echo "ok   fix-mista-escapa-e-insere-riscos-antes-do-historico"
else echo "FAIL fix-mista"; sed 's/^/  /' "$TMP/fx/c/tasks/TASK-001-009-mista.md"; fail=$((fail + 1)); fi
total=$((total + 1))
bash "$LINT" --fix >/dev/null 2>&1 </dev/null; st=$?
if [ "$st" -eq 2 ]; then echo "ok   fix-sem-caminho-exit-2"; else echo "FAIL fix-sem-caminho-exit-2: exit $st"; fail=$((fail + 1)); fi

# uso incorreto
total=$((total + 1))
bash "$LINT" "$TMP/nao-existe.md" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   caminho-inexistente-exit-2"
else echo "FAIL caminho-inexistente-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
bash "$LINT" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   sem-arg-exit-2"
else echo "FAIL sem-arg-exit-2: exit $st"; fail=$((fail + 1)); fi

total=$((total + 1))
printf 'x\n' > "$TMP/OUTRO-001-x.md"
bash "$LINT" "$TMP/OUTRO-001-x.md" >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   tipo-desconhecido-exit-2"
else echo "FAIL tipo-desconhecido-exit-2: exit $st"; fail=$((fail + 1)); fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "artifact-lint: $fail de $total casos falharam"
  exit 1
fi
echo "artifact-lint: $total casos verdes"
exit 0
