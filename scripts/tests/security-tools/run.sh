#!/usr/bin/env bash
# run.sh — suíte do scripts/security-tools.sh (decisão 4.426). Sem rede, sem instalar nada:
# PATH sintético com binários falsos prova a detecção (presente × ausente), o mapeamento
# lockfile → ferramenta (dono único da tabela), o piso do Composer 2.4, o escape hatch sem
# lockfile e o exit 0 incondicional (inventário, não gate). Bash 3.2-compatível.
set -u
LC_ALL=C; export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
HERE="$(cd "$(dirname "$0")" && pwd)"
SH="$HERE/../../security-tools.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0; total=0
ok()  { total=$((total+1)); echo "  ok: $*"; }
bad() { total=$((total+1)); fail=1; echo "  FALHA: $*" >&2; }
fakebin() { # $1 nome  $2 saída do --version/version
  printf '#!/bin/sh\necho "%s"\n' "$2" > "$TMP/bin/$1"; chmod +x "$TMP/bin/$1"
}
mkdir -p "$TMP/bin"
# PATH mínimo: só o essencial do sistema + os falsos (nada do usuário vaza)
BASE_PATH="/usr/bin:/bin"
run() { PATH="$TMP/bin:$BASE_PATH" bash "$SH" "$@"; }

bash -n "$SH" && ok "bash -n" || bad "bash -n"
[ -x "$SH" ] && ok "bit +x" || bad "sem +x (4.180/4.195)"

# 1) nada instalado, sem lockfile → gitleaks ausente + osv-scanner opcional; exit 0
mkdir -p "$TMP/p1"
out="$(run "$TMP/p1")"; rc=$?
[ $rc -eq 0 ] && ok "exit 0 sem nada instalado" || bad "exit $rc (esperado 0)"
printf '%s\n' "$out" | grep -q '^ausente | gitleaks | segredos' && ok "gitleaks ausente detectado" || bad "gitleaks ausente não reportado: $out"
printf '%s\n' "$out" | grep -q '^opcional-ausente | osv-scanner' && ok "sem lockfile → osv-scanner opcional" || bad "escape hatch ausente"
printf '%s\n' "$out" | grep -Eq 'go install|brew install' && ok "linha de ausente traz dica de instalação" || bad "sem dica"

# 2) gitleaks presente → ok com versão
fakebin gitleaks "v8.24.0"
out="$(run "$TMP/p1")"
printf '%s\n' "$out" | grep -q '^ok v8.24.0 | gitleaks' && ok "gitleaks presente → ok + versão" || bad "gitleaks presente não reconhecido: $out"

# 3) composer.lock: Composer 2.3 → ausente (piso 2.4); 2.7 → ok; sast opcional-ausente
mkdir -p "$TMP/p3"; : > "$TMP/p3/composer.lock"
fakebin composer "Composer version 2.3.10 2023-01-01"
out="$(run "$TMP/p3")"
printf '%s\n' "$out" | grep -q '^ausente | composer audit | cve | composer.lock (Composer 2.3.10 < 2.4)' && ok "Composer < 2.4 → ausente com motivo" || bad "piso 2.4 não aplicado: $out"
fakebin composer "Composer version 2.7.1 2024-02-09"
out="$(run "$TMP/p3")"
printf '%s\n' "$out" | grep -q '^ok composer 2.7.1 | composer audit' && ok "Composer 2.7 → ok" || bad "Composer 2.7 não ok: $out"
printf '%s\n' "$out" | grep -q '^opcional-ausente | psalm --taint-analysis ou semgrep | sast' && ok "SAST PHP opcional-ausente" || bad "SAST opcional não reportado"
fakebin semgrep "1.90.0"
out="$(run "$TMP/p3")"
printf '%s\n' "$out" | grep -q '^ok 1.90.0 | semgrep | sast' && ok "semgrep presente → sast ok" || bad "semgrep não reconhecido"
printf '%s\n' "$out" | grep -q 'osv-scanner' && bad "com lockfile o escape hatch não deve aparecer" || ok "com lockfile sem escape hatch"

# 4) dois ecossistemas: package-lock (npm ausente) + requirements (pip-audit presente)
mkdir -p "$TMP/p4"; : > "$TMP/p4/package-lock.json"; : > "$TMP/p4/requirements.txt"
fakebin pip-audit "pip-audit 2.7.3"
out="$(run "$TMP/p4")"
printf '%s\n' "$out" | grep -q '^ausente | npm audit | cve | package-lock.json' && ok "npm ausente por lockfile" || bad "npm audit não mapeado: $out"
printf '%s\n' "$out" | grep -q '^ok pip-audit 2.7.3 | pip-audit | cve | requirements.txt' && ok "pip-audit presente por lockfile" || bad "pip-audit não mapeado"
[ "$(printf '%s\n' "$out" | grep -c ' | cve | ')" -eq 2 ] && ok "dois ecossistemas → duas linhas cve" || bad "contagem cve errada"

# 5) --table é markdown com as 3 famílias
out="$(run --table)"
printf '%s\n' "$out" | grep -q '^| segredos |' && printf '%s\n' "$out" | grep -q '^| sast |' && printf '%s\n' "$out" | grep -q 'Gemfile.lock' && ok "--table cobre segredos/cve/sast" || bad "--table incompleta"

[ $fail -eq 0 ] && { echo "security-tools: suíte OK ($total checks)"; exit 0; } || { echo "security-tools: suíte com FALHAS" >&2; exit 1; }
