#!/usr/bin/env bash
# run.sh — suíte de regressão do epic-state.sh (decisão 4.154).
#
# Monta árvores docs/ sintéticas com BRIEF épico + slugs filhos e prova a tabela de
# regras da Etapa 1 do /keelson:continue: 1 (forja aguardando produto), 2 (parcial),
# 3 (fila desatualizada), 4 (próxima pendente), 5 (aguardando-produto na frente),
# 6 (tudo entregue) — sempre a PRIMEIRA que casa. Desde a 4.156, também o formato
# de campo da fila (| # | Fatia | Estado | Âncora |, estados em negrito, caminho na
# Âncora) e a degradação `aviso` + regra `-` para estado fora do vocabulário.
#
# Uso: scripts/tests/epic-state/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ES="$HERE/../../epic-state.sh"

[ -f "$ES" ] || { echo "ERRO: epic-state.sh não encontrado" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

mkepic() { # $1=nome $2=linhas-da-fila; ecoa o caminho do brief
  r="$TMP/$1"
  mkdir -p "$r/docs/ancora/briefs"
  {
    printf '# BRIEF épico: Plataforma\n\n**Slug**: ancora\n**Status**: em execução\n**Data**: 2026-08-06\n**Branch**: feat/ancora-plataforma\n**Estratégia**: unica\n\n## Fila\n\n'
    printf '| # | Fatia | Slug de destino | Estado |\n|---|---|---|---|\n'
    printf '%s\n' "$2"
  } > "$r/docs/ancora/briefs/BRIEF-2026-08-06-plataforma-epic.md"
  printf '%s\n' "$r"
}

mkchild() { # $1=raiz $2=slug $3=brief-status $4=spec $5=plan-mmm $6=lista de status das tasks ("" = sem plan/tasks) $7=spec citada no PLAN (default: $4)
  d="$1/docs/$2"
  mkdir -p "$d/briefs"
  printf '# BRIEF-002: Fatia\n\n**Slug**: %s\n**Status**: %s\n**SPEC**: %s\n' "$2" "$3" "$4" > "$d/briefs/BRIEF-002.md"
  [ -n "$5" ] || return 0
  mkdir -p "$d/plans" "$d/tasks"
  printf '# PLAN-%s: Fatia\n\n**Status**: Approved\n\n## Cobertura\n\n**SPEC referenciada**: %s\n' "$5" "${7:-$4}" > "$d/plans/PLAN-$5-fatia.md"
  i=0
  for st in $6; do
    i=$((i + 1))
    printf '# TASK-%s-%03d: T%d\n\n**Status**: %s\n' "$5" "$i" "$i" "$st" > "$d/tasks/TASK-$5-$(printf '%03d' $i)-t.md"
  done
}

runcase() { # nome raiz regra-esperada [trecho-esperado-na-saida]
  name="$1"; r="$2"; want="$3"; trecho="${4:-}"
  total=$((total + 1))
  out="$( cd "$r" && bash "$ES" docs/ancora/briefs/BRIEF-2026-08-06-plataforma-epic.md --docs-root docs 2>"$TMP/err" )"
  st=$?
  got="$(printf '%s\n' "$out" | sed -n 's/^regra\t\([0-9-]\).*/\1/p')"
  if [ "$st" -ne 0 ] || [ "$got" != "$want" ]; then
    echo "FAIL $name: regra $got (esperada $want), exit $st"
    printf '%s\n' "$out" | sed 's/^/  /'; sed 's/^/  stderr: /' "$TMP/err"
    fail=$((fail + 1)); return
  fi
  if [ -n "$trecho" ]; then
    case "$out" in
      *"$trecho"*) : ;;
      *) echo "FAIL $name: saída sem [$trecho]"; printf '%s\n' "$out" | sed 's/^/  /'; fail=$((fail + 1)); return ;;
    esac
  fi
  echo "ok   $name"
}

bash -n "$ES" || { echo "FAIL bash -n epic-state.sh"; exit 1; }
echo "ok   bash -n epic-state.sh"

# regra 4: entregue + próxima pendente
R="$(mkepic r4 '| 1 | Login | lms | entregue (2026-08-01) |
| 2 | Relatórios | lms | pendente |')"
runcase regra-4 "$R" 4 "proxima fatia pendente (2)"

# regra 2: em ciclo com closures parciais
R="$(mkepic r2 '| 1 | Login | lms | entregue (2026-08-01) |
| 2 | Relatórios | lms | em ciclo (docs/lms/briefs/BRIEF-002.md) |')"
mkchild "$R" lms Emitido SPEC-002 002 "Done Todo"
runcase regra-2 "$R" 2 "fatia	2	lms	em ciclo (docs/lms/briefs/BRIEF-002.md)	parcial"

# regra 3: em ciclo mas tudo Done nos artefatos → divergência + fila desatualizada
R="$(mkepic r3 '| 1 | Relatórios | lms | em ciclo (docs/lms/briefs/BRIEF-002.md) |')"
mkchild "$R" lms Emitido SPEC-002 002 "Done Done"
runcase regra-3 "$R" 3 "divergencia	1	em ciclo (docs/lms/briefs/BRIEF-002.md) vs entregue"

# regra 1: forja do filho aguardando produto
R="$(mkepic r1 '| 1 | Relatórios | lms | em ciclo (docs/lms/briefs/BRIEF-002.md) |')"
mkchild "$R" lms aguardando-produto SPEC-002 "" ""
runcase regra-1 "$R" 1 "forja aguardando produto"

# regra 5: aguardando-produto na frente da fila
R="$(mkepic r5 '| 1 | Login | lms | entregue (2026-08-01) |
| 2 | Relatórios | lms | aguardando-produto (Q-07) |
| 3 | Exportação | crm | pendente |')"
runcase regra-5 "$R" 5 "proxima fatia aguardando produto (2)"

# regra 6: fila toda entregue
R="$(mkepic r6 '| 1 | Login | lms | entregue (2026-08-01) |
| 2 | Relatórios | lms | entregue (2026-08-03) |')"
runcase regra-6 "$R" 6 "fila toda entregue"

# em ciclo pré-TASK (brief filho sem plan): regra 2 com pre-task
R="$(mkepic r2b '| 1 | Relatórios | lms | em ciclo (docs/lms/briefs/BRIEF-002.md) |')"
mkchild "$R" lms Emitido SPEC-002 "" ""
runcase regra-2-pre-task "$R" 2 "pre-task"

# ---- formato de campo (4.156): | # | Fatia | Estado | Âncora | ----

mkepic_legado() { # $1=nome $2=linhas-da-fila; ecoa o caminho do brief
  r="$TMP/$1"
  mkdir -p "$r/docs/ancora/briefs"
  {
    printf '# BRIEF épico: Plataforma\n\n**Slug**: ancora\n**Status**: em execução\n**Data**: 2026-08-06\n**Branch**: feat/ancora-plataforma\n**Estratégia**: unica\n\n## Fila\n\n'
    printf '| # | Fatia | Estado | Âncora |\n| --- | --- | --- | --- |\n'
    printf '%s\n' "$2"
  } > "$r/docs/ancora/briefs/BRIEF-2026-08-06-plataforma-epic.md"
  printf '%s\n' "$r"
}

# fila de campo: entregue em negrito + âncora com backtick → regra 4 na pendente
R="$(mkepic_legado leg4 '| 1 | Login | **entregue** (2026-08-01) | `briefs/BRIEF-001.md` · 13/13 TASKs Done |
| 2 | Digest | pendente | — |')"
runcase legado-regra-4 "$R" 4 "proxima fatia pendente (2)"

# fila de campo: em ciclo com data no estado e caminho na Âncora → verifica pelo filho
R="$(mkepic_legado leg2 '| 1 | Digest | **em ciclo** (2026-08-09) | `briefs/BRIEF-002.md` |')"
mkchild "$R" ancora Emitido SPEC-002 002 "Done Todo"
runcase legado-em-ciclo "$R" 2 "parcial"

# estado fora do vocabulário → aviso + regra -, nunca inventa fatia
R="$(mkepic_legado legav '| 1 | Login | esperando aprovacao | — |')"
runcase legado-nao-parseavel "$R" - "nao-parseavel"

# ---- vínculo BRIEF→PLAN por ID (4.170 — fixture do artefato de campo) ----

# header do BRIEF filho decorado ('SPEC-008 (a criar na Etapa 1)') e PLAN citando só o
# ID: o casamento cru classificava fatia adiantada como pre-task; por ID resolve
R="$(mkepic_legado id1 '| 1 | Quiz | **em ciclo** (2026-08-10) | `briefs/BRIEF-002.md` |')"
mkchild "$R" ancora Emitido "SPEC-008 (a criar na Etapa 1)" 010 "Done Todo" "SPEC-008"
runcase id-header-decorado "$R" 2 "parcial"

# PLAN citando a SPEC pelo caminho (4.124) e BRIEF pelo ID → também casa por ID
R="$(mkepic_legado id2 '| 1 | Quiz | **em ciclo** (2026-08-10) | `briefs/BRIEF-002.md` |')"
mkchild "$R" ancora Emitido "SPEC-008" 010 "Done Done" "docs/ancora/specs/SPEC-008-quiz.md"
runcase id-plan-por-caminho "$R" 3 "divergencia"

# ID não pode casar prefixo: SPEC-01 no BRIEF não casa SPEC-010 no PLAN → pre-task
R="$(mkepic_legado id3 '| 1 | Quiz | **em ciclo** (2026-08-10) | `briefs/BRIEF-002.md` |')"
mkchild "$R" ancora Emitido "SPEC-01" 010 "Done Done" "SPEC-010"
runcase id-sem-casar-prefixo "$R" 2 "pre-task"

# em ciclo com âncora para brief inexistente → aviso de degradação, nunca rota em silêncio
R="$(mkepic_legado sa1 '| 1 | Quiz | **em ciclo** (2026-08-10) | `briefs/BRIEF-999.md` |')"
runcase em-ciclo-sem-artefatos "$R" 2 "aviso	1	fatia em ciclo sem brief filho resolvivel"

# cabeçalho do épico ecoado
total=$((total + 1))
out="$( cd "$R" && bash "$ES" docs/ancora/briefs/BRIEF-2026-08-06-plataforma-epic.md --docs-root docs 2>/dev/null )"
case "$out" in
  "epico	em execução	feat/ancora-plataforma	unica"*) echo "ok   cabecalho-epico" ;;
  *) echo "FAIL cabecalho-epico"; printf '%s\n' "$out" | sed -n 1p | sed 's/^/  /'; fail=$((fail + 1)) ;;
esac

# uso incorreto
total=$((total + 1))
bash "$ES" "$TMP/nao-existe.md" >/dev/null 2>&1
[ $? -eq 2 ] && echo "ok   brief-inexistente-exit-2" || { echo "FAIL brief-inexistente-exit-2"; fail=$((fail + 1)); }

echo "---"
if [ "$fail" -gt 0 ]; then echo "epic-state: $fail de $total casos falharam"; exit 1; fi
echo "epic-state: $total casos verdes"
exit 0
