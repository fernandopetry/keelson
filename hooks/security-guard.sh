#!/usr/bin/env bash
# security-guard — hook Stop que reforça o GATE 8 (segurança) do keelson.
#
# LÊ A FICHA `keelson.config.json` na raiz do projeto (via jq) para se
# parametrizar — nada de caminho sensível hardcoded. Da ficha extrai:
#   - gates.security  → se `false`, o hook sai sem cutucar;
#   - sensitiveGlobs  → quais caminhos deste projeto são sensíveis.
# Além dos globs, manifesto/lockfile de DEPENDÊNCIA é sensível por definição
# ("mudança de dependências" é gatilho declarado do gate 8) — vigiado sempre,
# independente dos sensitiveGlobs.
# Detecta mudança SENSÍVEL na BRANCH e bloqueia o encerramento UMA vez,
# lembrando de aplicar o gate de segurança: mudança sensível → o agent
# `security-reviewer` (avaliador independente — auto-revisão do gerador não fecha
# o gate); só mudança fora dos gatilhos do gate 8 pode se resolver pelo checklist
# de `guidelines/core/SECURITY.md` + a seção de segurança do perfil ativo.
#
# Melhoria vs. a versão original: em vez de olhar o working tree cru (git status),
# compara o diff da BRANCH contra a base (merge-base com main/master) e filtra
# pelos `sensitiveGlobs` — isso evita falso-positivo quando a mudança sensível veio
# de outra origem. Sem base determinável, cai no comportamento antigo (working
# tree) e registra isso na mensagem.
#
# Fallback gracioso: sem `jq` ou sem a ficha, o hook NÃO trava o fluxo — emite
# aviso em stderr e sai 0. `stop_hook_active` evita loop dentro do mesmo turno;
# um marcador em .git/ evita re-cutucar em turnos seguintes enquanto o diff
# sensível for o mesmo (a comparação é da branch inteira — sem o marcador, uma
# mudança sensível já commitada dispararia o bloqueio ao fim de todo turno).
#
# Natureza: a DETECÇÃO é heurística (padrão de conteúdo + path). Não prova que a
# revisão rodou — cutuca para forçá-la.

set -euo pipefail

input="$(cat)"

# Raiz do projeto (fornecida pelo Claude Code; fallback para git/pwd).
proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
config="$proj/keelson.config.json"

# --- Fallback gracioso: sem jq, não trava o fluxo. ---
if ! command -v jq >/dev/null 2>&1; then
  echo "security-guard: jq não encontrado; guarda de segurança desativada nesta execução." >&2
  exit 0
fi

# --- Fallback gracioso: sem a ficha, não trava o fluxo. ---
if [ ! -f "$config" ]; then
  echo "security-guard: keelson.config.json não encontrado em $proj; guarda desativada nesta execução." >&2
  exit 0
fi

# Evita loop.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

# gates.security desligado na ficha → não cutuca (default: ligado quando ausente).
# Obs.: `//` do jq trata `false` como vazio, então NÃO serve aqui — testamos == false.
sec_gate="$(jq -r 'if .gates.security == false then "off" else "on" end' "$config" 2>/dev/null || echo on)"
[ "$sec_gate" = "off" ] && exit 0

# Globs sensíveis vindos da ficha. Sem eles ainda vigiamos dependências (abaixo).
sensitive_globs="$(jq -r '.sensitiveGlobs[]?' "$config" 2>/dev/null || true)"

cd "$proj" 2>/dev/null || exit 0

# --- Determina a base da branch (o coração da melhoria) ---
# merge-base com o primeiro candidato existente; se nenhum, fica vazio (fallback).
base=""
for b in main master origin/main origin/master; do
  if git rev-parse --verify -q "$b" >/dev/null 2>&1; then
    base="$(git merge-base HEAD "$b" 2>/dev/null || true)"
    [ -n "$base" ] && break
  fi
done

base_note=""
if [ -n "$base" ]; then
  # Diff da branch: da base até o working tree (inclui commits da branch + não-commitado).
  changed="$(git diff --name-only "$base" 2>/dev/null || true)"
  diff_ref="$base"
else
  # Sem base determinável → comportamento antigo (working tree), registrado na mensagem.
  changed="$(git status --porcelain -uall 2>/dev/null | sed -E 's/^.{2} //; s/^.* -> //' || true)"
  diff_ref="HEAD"
  base_note=$'\n\n(Observação: não foi possível determinar a base da branch (main/master). A detecção caiu no comportamento antigo — working tree via git status — em vez do diff da branch.)'
fi

# Arquivos novos (não rastreados) entram na análise nos dois modos.
untracked_all="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
changed="$(printf '%s\n%s\n' "$changed" "$untracked_all" | sed '/^$/d' | sort -u)"
[ -z "$changed" ] && exit 0

# Manifesto/lockfile de dependência mudou? Sensível por definição (gate 8),
# independente dos sensitiveGlobs.
DEP_MANIFESTS='composer\.json|composer\.lock|package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|requirements\.txt|poetry\.lock|uv\.lock|go\.mod|go\.sum|Cargo\.toml|Cargo\.lock|Gemfile|Gemfile\.lock'
dep_changed="$(printf '%s\n' "$changed" | grep -E "(^|/)(${DEP_MANIFESTS})$" || true)"

# path_matches_any_glob <globs-multilinha> <arquivo> — casa o path contra os globs
# da ficha (ex.: "src/**"). Em `case`, `*` já casa `/`, então "src/**" pega tudo sob src.
path_matches_any_glob() {
  local globs="$1" file="$2" glob
  while IFS= read -r glob; do
    [ -z "$glob" ] && continue
    # shellcheck disable=SC2254  # o glob vem da ficha e deve expandir como padrão
    case "$file" in
      $glob) return 0 ;;
    esac
  done <<< "$globs"
  return 1
}

# Filtra os arquivos alterados pelos sensitiveGlobs.
sensitive_files=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  path_matches_any_glob "$sensitive_globs" "$f" && sensitive_files="${sensitive_files}${f}"$'\n'
done <<< "$changed"
sensitive_files="$(printf '%s' "$sensitive_files" | sed '/^$/d')"
[ -z "$sensitive_files" ] && [ -z "$dep_changed" ] && exit 0

# Padrões sensíveis — heurística multi-linguagem derivada das categorias de
# guidelines/core/SECURITY.md, composta por categoria (PHP/JS/Python/Go/Java/Ruby).
# Falso-positivo apenas nudga a revisão (lado seguro); a prova de verdade é o
# security-reviewer + o perfil ativo. Grep roda com -i (case-insensitive).
P_SECRET='password|passwd|senha|token|secret|api[_-]?key|credential|jwt|argon2|bcrypt|scrypt|pbkdf2|password_hash|hash_equals|hmac'
P_AUTHZ='csrf|session|cookie|permission|authoriz|redirect'
P_SQL='SELECT |INSERT |UPDATE |DELETE |->prepare|->query|->exec\(|\bpdo\b|mysqli|cursor\.execute|prepareStatement|createStatement|executeQuery|\bjdbc\b|db\.Query|db\.Exec|database/sql|find_by_sql|ActiveRecord|\.raw\('
P_EXEC='shell_exec|system\(|proc_open|popen|subprocess|child_process|exec\.Command|os/exec|Runtime\.getRuntime|ProcessBuilder'
P_INPUT='\$_GET|\$_POST|\$_REQUEST|\$_COOKIE|request\.(GET|POST|args|form|json|data)|req\.(query|body|params)|params\[|r\.FormValue|r\.URL\.Query|getParameter|@Request(Param|Body)'
P_DESER='unserialize|\bpickle\b|yaml\.load|Marshal\.load|ObjectInputStream|readObject|deserializ|render_template_string'
P_IO='move_uploaded_file|file_get_contents|file_put_contents|curl_|urllib|http\.Get|MultipartFile|\bupload'
P_FRONT='localStorage|sessionStorage|v-html|innerHTML|dangerouslySetInnerHTML|document\.write|bypassSecurityTrust'
P_HDR='setcookie|header\(|Set-Cookie'
PATTERN="${P_SECRET}|${P_AUTHZ}|${P_SQL}|${P_EXEC}|${P_INPUT}|${P_DESER}|${P_IO}|${P_FRONT}|${P_HDR}"

# Pathspec (array indexado — ok em bash 3.2) só com os arquivos sensíveis.
sens_arr=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  sens_arr+=("$f")
done <<< "$sensitive_files"

# Conteúdo novo: linhas adicionadas (rastreadas) + conteúdo de arquivos novos.
added=""
if [ "${#sens_arr[@]}" -gt 0 ]; then
  added="$(git diff "$diff_ref" -- "${sens_arr[@]}" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
fi
unt_content=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if printf '%s\n' "$untracked_all" | grep -Fxq -- "$f" 2>/dev/null; then
    [ -f "$f" ] && unt_content="${unt_content}$(cat "$f" 2>/dev/null)"$'\n'
  fi
done <<< "$sensitive_files"

content_sensitive="$(printf '%s\n%s\n' "$added" "$unt_content" | grep -nEi "$PATTERN" || true)"
# Path sensível por palavra-chave (auth, sql, upload, ...).
path_sensitive="$(printf '%s\n' "$sensitive_files" | grep -iE '(auth|login|security|permiss|role|password|token|session|upload|payment|crypto|sql|query)' || true)"

if [ -n "$content_sensitive" ] || [ -n "$path_sensitive" ] || [ -n "$dep_changed" ]; then
  # Anti-renudge entre turnos: stop_hook_active só cobre o turno atual.
  git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
  marker="" fingerprint=""
  if [ -n "$git_dir" ]; then
    marker="$git_dir/keelson-security-guard.last"
    fingerprint="$(printf '%s\n%s\n%s\n%s' "$sensitive_files" "$content_sensitive" "$path_sensitive" "$dep_changed" | git hash-object --stdin 2>/dev/null || true)"
    if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
      exit 0
    fi
  fi
  dep_note=""
  if [ -n "$dep_changed" ]; then
    dep_note=$'\n\nMudança de dependências detectada (gatilho do gate 8):\n'"$dep_changed"$'\nRode a auditoria do ecossistema (a do perfil ativo — ex.: composer audit, npm audit, pip-audit, osv-scanner) e cite o CVE/advisory ID de qualquer achado — nunca de memória.'
  fi
  reason="$(cat <<EOF
Gate de Segurança (keelson, gate 8): há mudança no código sensível (sensitiveGlobs da ficha) com indícios de auth, SQL, crypto, upload, cookies, exec, I/O de request, redirect ou dependências.

Antes de encerrar, aplique o gate de segurança:
- Mudança de fato sensível (gatilhos do gate 8) com gates.security ativo → rode o agent security-reviewer sobre o diff final. Auto-revisão do gerador NÃO fecha este gate: quem implementou não pode ser quem aprova ("verifiquei ao construir" não vale como veredito).
- Só quando a mudança está FORA dos gatilhos do gate 8 (este aviso é heurístico e pode ser falso-positivo) → basta o checklist de guidelines/core/SECURITY.md + a seção de segurança do perfil ativo.
- Confirme: consultas parametrizadas; saída escapada no destino; autorização verificada (negar por padrão); guarda de step-up no ponto que ESCREVE o dado (todos os writers, não só o caminho da tela); sem segredo/PII em log; cookies httponly/secure/samesite; sem token em storage do cliente; sem renderização crua de dado de usuário.

Se o security-reviewer JÁ rodou sobre este diff (ou a mudança está comprovadamente fora dos gatilhos), pode encerrar — este aviso não se repetirá para esta mesma mudança.${dep_note}${base_note}
EOF
)"
  if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
    printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
  fi
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi

exit 0
