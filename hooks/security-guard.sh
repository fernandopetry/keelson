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
# `security-engineer` (avaliador independente — auto-revisão do gerador não fecha
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
# um marcador em .git/ evita re-cutucar em turnos seguintes enquanto a IDENTIDADE do
# diff sensível for a mesma — base + conteúdo exato dos arquivos sensíveis e manifestos,
# medida por `scripts/diff-facts.sh --guard security` (4.377/4.378 — dono único do
# escopo: base, lista filtrada por sensitiveGlobs + manifestos e identidade vêm dele;
# antes: listas + linhas casadas pela heurística, cegas a linha neutra alterada). A comparação é da branch inteira — sem o
# marcador, uma mudança sensível já commitada dispararia o bloqueio ao fim de todo turno.
# Rename detection fixada (-M, origem no pathspec): rename puro não vira "+ arquivo inteiro".
# E veredito do security-engineer já registrado no ledger da sessão (evento `gate`,
# 4.76) cujo `diff_id:` — identidade medida pelo ledger.sh no registro (4.378) — é igual
# à identidade atual cala o hook; evento sem `diff_id:` cai no mtime (4.365 — mesma
# forma do review-guard).
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

# Ciclo formal em andamento → o gate 8 tem dono (rodada da wave no /keelson:implement,
# 3.3/4.92); este hook é a rede da SESSÃO LIVRE, não um segundo cobrador
# (decisão 4.103). run-state ativo DESTA sessão → silêncio. Posse (4.252): run de
# OUTRA sessão (campo `sessao:` ≠ session_id do payload) não silencia a rede desta;
# dono desconhecido/formato antigo/sem session_id → silêncio como antes (nunca
# reativar nudge por dúvida).
session_id="$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")"
# casa da sessão (4.314) + caminho legado
for rs in "$proj"/thoughts/local/run-state-*.md "$proj"/thoughts/local/sessions/*/run-state-*.md; do
  [ -f "$rs" ] || continue
  grep -q "^status: em_andamento" "$rs" 2>/dev/null || continue
  dono="$(sed -n 's/^sessao:[ 	]*//p' "$rs" 2>/dev/null | sed -n 1p)"
  if [ -n "$session_id" ] && [ -n "$dono" ] && [ "$dono" != "desconhecida" ] && [ "$dono" != "$session_id" ]; then
    continue
  fi
  exit 0
done

# gates.security desligado na ficha → não cutuca (default: ligado quando ausente).
# Obs.: `//` do jq trata `false` como vazio, então NÃO serve aqui — testamos == false.
sec_gate="$(jq -r 'if .gates.security == false then "off" else "on" end' "$config" 2>/dev/null || echo on)"
[ "$sec_gate" = "off" ] && exit 0

# ledger.sh resolvido ANTES do cd (o $0 pode ser relativo); ausente → a consulta ao
# veredito registrado (abaixo) é pulada e o hook se comporta como sempre.
SCRIPTS_DIR="$(cd "$(dirname "$0")/../scripts" 2>/dev/null && pwd || true)"
LEDGER="$SCRIPTS_DIR/ledger.sh"
# diff-facts.sh --identity (4.377): identidade do diff para o marker anti-renudge.
DIFF_FACTS="$SCRIPTS_DIR/diff-facts.sh"

cd "$proj" 2>/dev/null || exit 0

# --- Escopo e identidade pelo dono único (decisão 4.378) ---
# diff-facts.sh --guard security detecta a base (merge-base com main/master/origin/*; sem
# base, working tree), lista os arquivos alterados + novos, filtra pelos sensitiveGlobs da
# ficha e pelos manifestos de dependência (sensíveis por definição, gate 8; rename
# detection fixada, 4.377) e mede a identidade do conjunto — a mesma que o ledger.sh grava
# no veredito (diff_id:). Script ausente → guarda desativada nesta execução (aviso).
if [ ! -f "$DIFF_FACTS" ]; then
  echo "security-guard: diff-facts.sh não encontrado; guarda de segurança desativada nesta execução." >&2
  exit 0
fi
facts="$(bash "$DIFF_FACTS" --repo "$proj" --guard security 2>/dev/null || true)"
diff_ref="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "ref" { print $2; exit }')"
[ -n "$diff_ref" ] || exit 0
base_note=""
if [ "$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "mode" { print $2; exit }')" = "worktree" ]; then
  base_note=$'\n\n(Observação: não foi possível determinar a base da branch (main/master). A detecção caiu no comportamento antigo — working tree via git status — em vez do diff da branch.)'
fi
sensitive_files="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "file" { print $2 }')"
untracked_files="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "file" && $3 == "untracked" { print $2 }')"
rename_src="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "rename_src" { print $2 }')"
dep_changed="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "dep" { print $2 }')"
identity="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "identity" { print $2; exit }')"
[ -z "$sensitive_files" ] && [ -z "$dep_changed" ] && exit 0

# Padrões sensíveis — heurística multi-linguagem derivada das categorias de
# guidelines/core/SECURITY.md, composta por categoria (PHP/JS/Python/Go/Java/Ruby).
# Falso-positivo apenas nudga a revisão (lado seguro); a prova de verdade é o
# security-engineer + o perfil ativo. Grep roda com -i (case-insensitive).
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
  spec_arr=("${sens_arr[@]}")
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    spec_arr+=("$f")
  done <<< "$rename_src"
  added="$(git -c core.quotePath=false diff -M "$diff_ref" -- "${spec_arr[@]}" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
fi
unt_content=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if printf '%s\n' "$untracked_files" | grep -Fxq -- "$f" 2>/dev/null; then
    [ -f "$f" ] && unt_content="${unt_content}$(cat "$f" 2>/dev/null)"$'\n'
  fi
done <<< "$sensitive_files"

content_sensitive="$(printf '%s\n%s\n' "$added" "$unt_content" | grep -nEi "$PATTERN" || true)"
# Path sensível por palavra-chave (auth, sql, upload, ...).
path_sensitive="$(printf '%s\n' "$sensitive_files" | grep -iE '(auth|login|security|permiss|role|password|token|session|upload|payment|crypto|sql|query)' || true)"

if [ -n "$content_sensitive" ] || [ -n "$path_sensitive" ] || [ -n "$dep_changed" ]; then
  # Veredito já registrado cobre a árvore (decisões 4.365/4.378): o security-engineer
  # que revisou ESTE estado do diff deixou evento `gate` no ledger da sessão (4.76 —
  # escrito pelo Tech Lead ao receber o report), e o ledger.sh gravou nele a identidade
  # do diff vigiado (`diff_id:`) no instante do registro. Identidade igual à atual →
  # silêncio; diferente → o revisor viu outro estado → cutuca (delta). Evento legado sem
  # `diff_id:` → fallback por mtime (arquivo ausente conta como mais novo — conservador).
  # No modo sob demanda não há commit para ancorar o marcador (4.91) e o diff cumulativo
  # cresce a cada correção: sem esta consulta, cada rodada genuína de re-review
  # re-disparava a cutucada. Sem ledger ou sem evento → comportamento de sempre.
  if [ -f "$LEDGER" ]; then
    verdict="$(KEELSON_SESSAO="$session_id" bash "$LEDGER" "$proj" last gate security-engineer 2>/dev/null || true)"
    if [ -n "$verdict" ] && [ -f "$verdict" ]; then
      vid="$(sed -n 's/^diff_id:[ 	]*//p' "$verdict" 2>/dev/null | sed -n 1p)"
      if [ -n "$vid" ] && [ -n "$identity" ]; then
        [ "$vid" = "$identity" ] && exit 0
      else
        newer=0
        while IFS= read -r f; do
          [ -z "$f" ] && continue
          if [ ! -e "$f" ] || [ "$f" -nt "$verdict" ]; then newer=1; break; fi
        done <<< "$sensitive_files"
        [ "$newer" -eq 0 ] && exit 0
      fi
    fi
  fi
  # Anti-renudge entre turnos: stop_hook_active só cobre o turno atual.
  git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
  marker="" fingerprint=""
  if [ -n "$git_dir" ]; then
    marker="$git_dir/keelson-security-guard.last"
    # Identidade do diff sensível (4.377/4.378): base + conteúdo exato dos arquivos
    # sensíveis e dos manifestos, medida pelo --guard acima — linha neutra alterada num
    # arquivo sensível cutuca de novo; o marker guarda o último estado AVISADO, o ledger
    # (acima) o último REVISADO. Identidade vazia → forma antiga (listas + linhas casadas).
    fingerprint="$identity"
    [ -n "$fingerprint" ] || fingerprint="$(printf '%s\n%s\n%s\n%s' "$sensitive_files" "$content_sensitive" "$path_sensitive" "$dep_changed" | git hash-object --stdin 2>/dev/null || true)"
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
- Mudança de fato sensível (gatilhos do gate 8) com gates.security ativo → rode o agent security-engineer sobre o diff final. Auto-revisão do gerador NÃO fecha este gate: quem implementou não pode ser quem aprova ("verifiquei ao construir" não vale como veredito).
- Só quando a mudança está FORA dos gatilhos do gate 8 (este aviso é heurístico e pode ser falso-positivo) → basta o checklist de guidelines/core/SECURITY.md + a seção de segurança do perfil ativo.
- Confirme: consultas parametrizadas; saída escapada no destino; autorização verificada (negar por padrão); guarda de step-up no ponto que ESCREVE o dado (todos os writers, não só o caminho da tela); sem segredo/PII em log; cookies httponly/secure/samesite; sem token em storage do cliente; sem renderização crua de dado de usuário.

Se o security-engineer JÁ rodou sobre este diff (ou a mudança está comprovadamente fora dos gatilhos), pode encerrar — este aviso não se repetirá para esta mesma mudança. Se o que mudou desde o veredito dele é só o delta de uma correção de achados, a re-verificação é sobre o delta (régua de convergência: guidelines/core/CODE-REVIEW.md, decisão 4.88); achado de segurança que persistir após 1 retry escala ao Diretor como bloqueio, nunca ganha 3ª rodada silenciosa.${dep_note}${base_note}
EOF
)"
  if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
    printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
  fi
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi

exit 0
