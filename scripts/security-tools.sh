#!/usr/bin/env bash
# security-tools.sh — inventário das ferramentas que a política de segurança do keelson
# usa (decisão 4.426): o que está instalado, o que falta e como instalar — FATO de
# disco, para o /keelson:init oferecer a instalação e para o /keelson:audit nomear a
# ferramenta do ecossistema. Dono único da tabela lockfile → auditor de CVE (antes
# inline no commands/audit.md). Nenhuma ferramenta é obrigatória: o gate 8 declara a
# lacuna em `ferramentas_indisponiveis` (core/SECURITY.md, "Ferramenta ausente") — este
# script só mede e sugere, nunca instala.
#
# Uso: security-tools.sh [<raiz-do-projeto>] [--table]
#   <raiz>    default: diretório corrente. Lockfiles são procurados só na raiz.
#   --table   imprime a tabela de referência (markdown) e sai — para leitura humana.
#
# Saída (uma linha por ferramenta, campos separados por " | "):
#   <estado> | <ferramenta> | <papel> | <escopo> | <instalar>
#   estado: ok (com versão quando barata) · ausente · opcional-ausente
#   papel:  segredos · cve · sast
# Exit: sempre 0 (inventário, não gate). Bash 3.2 + awk POSIX; sem dependências.

set -u
LC_ALL=C; export LC_ALL

ROOT="."
TABLE=0
for a in "$@"; do
  case "$a" in
    --table) TABLE=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) ROOT="$a" ;;
  esac
done

# --- dica de instalação por plataforma -------------------------------------------
os="$(uname -s 2>/dev/null || echo unknown)"
hint() { # $1 brew  $2 outros
  if [ "$os" = "Darwin" ] && command -v brew >/dev/null 2>&1; then printf '%s' "$1"; else printf '%s' "$2"; fi
}

# --- tabela de referência (dono único) ------------------------------------------
if [ "$TABLE" -eq 1 ]; then
  cat <<'EOF'
| Papel | Gatilho | Ferramenta | Vem com | Se ausente |
|---|---|---|---|---|
| segredos | sempre (todo diff) | `gitleaks` | — | `brew install gitleaks` · Linux: release do projeto ou `go install github.com/zricethezav/gitleaks/v8@latest` |
| cve | `composer.lock` | `composer audit` | Composer 2.4+ | atualizar o Composer |
| cve | `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` | `npm audit` / `pnpm audit` / `yarn npm audit` | o gerenciador | — |
| cve | `requirements.txt` / `poetry.lock` / `uv.lock` | `pip-audit` | — | `pip install pip-audit` (ou `brew install pip-audit`) |
| cve | `go.mod` / `go.sum` | `govulncheck ./...` | — | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| cve | `Cargo.lock` | `cargo audit` | — | `cargo install cargo-audit` |
| cve | `Gemfile.lock` | `bundler-audit` | — | `gem install bundler-audit` |
| cve | qualquer lockfile sem ferramenta nativa | `osv-scanner` (escape hatch) | — | binário do projeto OSV |
| sast | perfil nomeia (opt-in; PHP: `composer.lock`) | `psalm --taint-analysis` ou `semgrep` | — | `composer require --dev vimeo/psalm` · `brew install semgrep` / `pip install semgrep` |
EOF
  exit 0
fi

have() { command -v "$1" >/dev/null 2>&1; }
ver() { # $1 cmd  $2 flag — 1ª linha, curta; vazio se falhar
  "$1" "$2" 2>/dev/null | head -1 | cut -c1-40
}
line() { printf '%s | %s | %s | %s | %s\n' "$1" "$2" "$3" "$4" "$5"; }

# --- segredos: sempre ------------------------------------------------------------
if have gitleaks; then
  line "ok $(ver gitleaks version)" "gitleaks" "segredos" "todo diff do gate 8 + branch na entrega" "—"
else
  line "ausente" "gitleaks" "segredos" "todo diff do gate 8 + branch na entrega" \
    "$(hint 'brew install gitleaks' 'release do projeto gitleaks ou: go install github.com/zricethezav/gitleaks/v8@latest')"
fi

# --- cve: por lockfile presente na raiz -----------------------------------------
found_lock=0
if [ -f "$ROOT/composer.lock" ]; then
  found_lock=1
  if have composer; then
    cv="$(composer --version 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.[0-9]+/) {print $i; exit}}')"
    maj="${cv%%.*}"; rest="${cv#*.}"; min="${rest%%.*}"
    case "$maj" in ''|*[!0-9]*) maj=0 ;; esac; case "$min" in ''|*[!0-9]*) min=0 ;; esac
    if [ "$maj" -gt 2 ] || { [ "$maj" -eq 2 ] && [ "$min" -ge 4 ]; }; then
      line "ok composer $cv" "composer audit" "cve" "composer.lock" "—"
    else
      line "ausente" "composer audit" "cve" "composer.lock (Composer $cv < 2.4)" "atualizar o Composer para 2.4+ (composer self-update)"
    fi
  else
    line "ausente" "composer audit" "cve" "composer.lock" "instalar o Composer 2.4+"
  fi
  # sast opcional do ecossistema PHP
  if have semgrep; then line "ok $(ver semgrep --version)" "semgrep" "sast" "opt-in do perfil (PHP)" "—"
  elif [ -x "$ROOT/vendor/bin/psalm" ]; then line "ok" "psalm --taint-analysis" "sast" "opt-in do perfil (PHP)" "—"
  else line "opcional-ausente" "psalm --taint-analysis ou semgrep" "sast" "opt-in do perfil (PHP)" \
    "composer require --dev vimeo/psalm · $(hint 'brew install semgrep' 'pip install semgrep')"; fi
fi
for lf in package-lock.json pnpm-lock.yaml yarn.lock; do
  if [ -f "$ROOT/$lf" ]; then
    found_lock=1
    case "$lf" in
      package-lock.json) tool=npm;  cmd="npm audit" ;;
      pnpm-lock.yaml)    tool=pnpm; cmd="pnpm audit" ;;
      yarn.lock)         tool=yarn; cmd="yarn npm audit" ;;
    esac
    if have "$tool"; then line "ok $tool $(ver "$tool" --version)" "$cmd" "cve" "$lf" "—"
    else line "ausente" "$cmd" "cve" "$lf" "instalar o $tool (vem com o runtime Node/o gerenciador)"; fi
  fi
done
for lf in requirements.txt poetry.lock uv.lock; do
  if [ -f "$ROOT/$lf" ]; then
    found_lock=1
    if have pip-audit; then line "ok $(ver pip-audit --version)" "pip-audit" "cve" "$lf" "—"
    else line "ausente" "pip-audit" "cve" "$lf" "$(hint 'brew install pip-audit' 'pip install pip-audit')"; fi
    break
  fi
done
if [ -f "$ROOT/go.mod" ] || [ -f "$ROOT/go.sum" ]; then
  found_lock=1
  if have govulncheck; then line "ok" "govulncheck ./..." "cve" "go.mod" "—"
  else line "ausente" "govulncheck ./..." "cve" "go.mod" "go install golang.org/x/vuln/cmd/govulncheck@latest"; fi
fi
if [ -f "$ROOT/Cargo.lock" ]; then
  found_lock=1
  if have cargo && cargo audit --version >/dev/null 2>&1; then line "ok $(ver cargo-audit --version)" "cargo audit" "cve" "Cargo.lock" "—"
  else line "ausente" "cargo audit" "cve" "Cargo.lock" "cargo install cargo-audit"; fi
fi
if [ -f "$ROOT/Gemfile.lock" ]; then
  found_lock=1
  if have bundler-audit || have bundle-audit; then line "ok" "bundler-audit" "cve" "Gemfile.lock" "—"
  else line "ausente" "bundler-audit" "cve" "Gemfile.lock" "gem install bundler-audit"; fi
fi
if [ "$found_lock" -eq 0 ]; then
  if have osv-scanner; then line "ok $(ver osv-scanner --version)" "osv-scanner" "cve" "nenhum lockfile conhecido na raiz (escape hatch)" "—"
  else line "opcional-ausente" "osv-scanner" "cve" "nenhum lockfile conhecido na raiz (escape hatch)" "binário do projeto OSV (só se o ecossistema não tiver ferramenta nativa)"; fi
fi
exit 0
