#!/usr/bin/env bash
# run.sh — suíte do roteamento do pre-commit (decisões 4.63/4.83/4.385).
#
# O hook de verdade (scripts/git-hooks/pre-commit) roda num repo TEMPORÁRIO via
# core.hooksPath — nunca contra o índice do repo do keelson (o hook exporta
# GIT_INDEX_FILE etc.; simular com o índice real já quebrou suíte). As suítes do
# repo sintético são FALSAS: cada run.sh grava um marcador quando invocado e sai
# 0 (ou 1, quando o caso pede falha). Provado:
#   roteamento — motor staged → suíte(s) certa(s) e só elas (ledger.sh → ledger,
#     review-guard, security-guard; hook com suíte → sua suíte; arquivo fora da
#     camada mecânica → nenhuma); suíte falhando → commit BLOQUEADO; suíte ausente
#     → aviso e segue; KEELSON_SKIP_TESTS=1 → nada roda;
#   sintaxe — .sh staged com bash -n quebrado → bloqueado;
#   guarda da main (4.63) — main atrás de origin/main → bloqueado, mensagem cita
#     `git pull --rebase`; KEELSON_SKIP_MAIN_CHECK=1 passa; sem remoto passa;
#     detached HEAD passa; branch que não é main passa.
#
# Uso: scripts/tests/pre-commit/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
HOOK="$ROOT/scripts/git-hooks/pre-commit"

[ -f "$HOOK" ] || { echo "ERRO: pre-commit não encontrado em $HOOK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0
ok()    { echo "ok   $1"; }
falha() { echo "FAIL $1"; fail=$((fail + 1)); }

bash -n "$HOOK" || { echo "FAIL bash -n pre-commit"; exit 1; }
echo "ok   bash -n pre-commit"

R="$TMP/repo"; MARK="$TMP/marks"
SUITES="ledger review-guard security-guard noverify graph diff-facts corpus"
G() { git -C "$R" -c user.email=t@t -c user.name=t "$@"; }
# commit de preparação: sem o hook (hooksPath inexistente), só o caso sob teste passa por ele
setup_commit() { G -c core.hooksPath=/dev/null commit -q -m "$1"; }

novo_repo() { # [branch]
  rm -rf "$R" "$MARK"; mkdir -p "$R/scripts/git-hooks" "$R/hooks" "$MARK"
  git -C "$R" init -q -b "${1:-main}" 2>/dev/null || { git -C "$R" init -q; git -C "$R" checkout -q -b "${1:-main}"; }
  cp "$HOOK" "$R/scripts/git-hooks/pre-commit"; chmod +x "$R/scripts/git-hooks/pre-commit"
  G config core.hooksPath scripts/git-hooks
  for s in $SUITES; do
    mkdir -p "$R/scripts/tests/$s"
    printf '#!/usr/bin/env bash\ntouch "%s/%s"\necho "%s: verde"\nexit 0\n' "$MARK" "$s" "$s" > "$R/scripts/tests/$s/run.sh"
    chmod +x "$R/scripts/tests/$s/run.sh"
  done
  for m in ledger diff-facts graph; do printf '#!/usr/bin/env bash\nexit 0\n' > "$R/scripts/$m.sh"; chmod +x "$R/scripts/$m.sh"; done
  printf '#!/usr/bin/env bash\nexit 0\n' > "$R/hooks/noverify-guard.sh"; chmod +x "$R/hooks/noverify-guard.sh"
  printf 'x\n' > "$R/outro.txt"
  G add -A; setup_commit base
}

tenta_commit() { # → exit do git commit; stderr em $TMP/err
  G commit -q -m caso >"$TMP/out" 2>"$TMP/err"
}
rodou() { [ -f "$MARK/$1" ]; }
marks() { find "$MARK" -type f -exec basename {} \; | tr '\n' ' '; }
limpa_marks() { rm -f "$MARK"/*; }

# --- roteamento: motor → suítes ---
novo_repo; printf '# mudou\n' >> "$R/scripts/ledger.sh"; G add -A; limpa_marks
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && rodou ledger && rodou review-guard && rodou security-guard && ! rodou noverify && ! rodou graph; then ok ledger-roteia-tres-suites
else falha "ledger-roteia-tres-suites: exit=$st marks=[$(marks)] $(tail -3 "$TMP/err")"; fi

novo_repo; printf '# mudou\n' >> "$R/hooks/noverify-guard.sh"; G add -A; limpa_marks
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && rodou noverify && ! rodou ledger; then ok hook-roteia-sua-suite
else falha "hook-roteia-sua-suite: exit=$st marks=[$(marks)]"; fi

novo_repo; printf '# mudou\n' >> "$R/scripts/graph.sh"; G add -A; limpa_marks
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && rodou graph && rodou corpus; then ok graph-roteia-grafo-e-corpus
else falha "graph-roteia-grafo-e-corpus: exit=$st marks=[$(marks)]"; fi

novo_repo; printf 'y\n' >> "$R/outro.txt"; G add -A; limpa_marks
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && [ -z "$(marks)" ]; then ok fora-da-camada-nao-roda-nada
else falha "fora-da-camada-nao-roda-nada: exit=$st marks=[$(marks)]"; fi

# --- suíte falhando → bloqueado; escape → passa ---
novo_repo; printf '#!/usr/bin/env bash\necho "ledger: 1 de 3 casos falharam"\nexit 1\n' > "$R/scripts/tests/ledger/run.sh"
G add -A; setup_commit suite-vermelha-instalada
printf '# mudou\n' >> "$R/scripts/ledger.sh"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -ne 0 ] && grep -q 'BLOQUEADO: suíte ledger falhou' "$TMP/err"; then ok suite-vermelha-bloqueia
else falha "suite-vermelha-bloqueia: exit=$st $(tail -3 "$TMP/err")"; fi
total=$((total + 1))
KEELSON_SKIP_TESTS=1 G commit -q -m escape >/dev/null 2>"$TMP/err"; st=$?
if [ "$st" -eq 0 ]; then ok skip-tests-passa; else falha "skip-tests-passa: exit=$st $(tail -2 "$TMP/err")"; fi

# --- suíte ausente → aviso e segue ---
novo_repo; rm -rf "$R/scripts/tests/ledger"; G add -A; setup_commit sem-suite
printf '# mudou\n' >> "$R/scripts/ledger.sh"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && grep -q 'scripts/tests/ledger/run.sh ausente' "$TMP/err"; then ok suite-ausente-avisa-e-segue
else falha "suite-ausente-avisa-e-segue: exit=$st $(tail -2 "$TMP/err")"; fi

# --- bash -n quebrado → bloqueado ---
novo_repo; printf 'if [ 1 ]; then\n' > "$R/scripts/quebrado.sh"; chmod +x "$R/scripts/quebrado.sh"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -ne 0 ] && grep -q 'bash -n falhou em scripts/quebrado.sh' "$TMP/err"; then ok bash-n-quebrado-bloqueia
else falha "bash-n-quebrado-bloqueia: exit=$st $(tail -2 "$TMP/err")"; fi

# --- bit de execução ausente em script do pacote → bloqueado ---
novo_repo; printf '#!/usr/bin/env bash\nexit 0\n' > "$R/hooks/novo-guard.sh"; chmod 644 "$R/hooks/novo-guard.sh"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -ne 0 ] && grep -qi 'bit de execu' "$TMP/err"; then ok sem-exec-bit-bloqueia
else falha "sem-exec-bit-bloqueia: exit=$st $(tail -2 "$TMP/err")"; fi

# --- guarda da main (4.63) ---
ORIGIN="$TMP/origin.git"; rm -rf "$ORIGIN"; git init -q --bare -b main "$ORIGIN" 2>/dev/null || git init -q --bare "$ORIGIN"
novo_repo; G remote add origin "$ORIGIN"; G push -q origin main 2>/dev/null
# outra sessão publica na origin
OUTRA="$TMP/outra"; rm -rf "$OUTRA"; git clone -q -b main "$ORIGIN" "$OUTRA" 2>/dev/null
printf 'z\n' > "$OUTRA/paralela.txt"; git -C "$OUTRA" add -A; git -C "$OUTRA" -c user.email=o@o -c user.name=o commit -q -m paralela; git -C "$OUTRA" push -q origin main 2>/dev/null
printf 'y\n' >> "$R/outro.txt"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -ne 0 ] && grep -q 'origin/main tem 1 commit(s)' "$TMP/err" && grep -q 'git pull --rebase origin main' "$TMP/err"; then ok main-atras-bloqueia
else falha "main-atras-bloqueia: exit=$st $(tail -4 "$TMP/err")"; fi
total=$((total + 1))
KEELSON_SKIP_MAIN_CHECK=1 G commit -q -m escape >/dev/null 2>"$TMP/err"; st=$?
if [ "$st" -eq 0 ]; then ok skip-main-check-passa; else falha "skip-main-check-passa: exit=$st $(tail -2 "$TMP/err")"; fi

# branch que não é main, mesmo atrás → passa
novo_repo; G remote add origin "$ORIGIN"; G fetch -q origin 2>/dev/null; G checkout -q -b feat
printf 'y\n' >> "$R/outro.txt"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ]; then ok branch-nao-main-passa; else falha "branch-nao-main-passa: exit=$st $(tail -2 "$TMP/err")"; fi

# sem remoto → passa
novo_repo; printf 'y\n' >> "$R/outro.txt"; G add -A
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ]; then ok sem-remoto-passa; else falha "sem-remoto-passa: exit=$st $(tail -2 "$TMP/err")"; fi

# detached HEAD → guarda da main não interfere (e a Parte 2 ainda roteia)
novo_repo; G remote add origin "$ORIGIN"; G fetch -q origin 2>/dev/null; G checkout -q --detach
printf '# mudou\n' >> "$R/scripts/ledger.sh"; G add -A; limpa_marks
tenta_commit; st=$?
total=$((total + 1))
if [ "$st" -eq 0 ] && rodou ledger; then ok detached-head-passa-e-roteia
else falha "detached-head-passa-e-roteia: exit=$st marks=[$(marks)] $(tail -2 "$TMP/err")"; fi

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "pre-commit: $fail de $total casos falharam"
  exit 1
fi
echo "pre-commit: $total casos verdes"
exit 0
