#!/usr/bin/env bash
# run.sh — suíte de regressão do largada-guard (decisão 4.391).
#
# Roda o hook de verdade (stdin JSON, python3, git) num repo temporário com ficha e
# docsRoot. Casos inline:
#   block — SPEC/PLAN/TASK nova (untracked) ou commitada NESTA branch sem run-state e sem
#           evento no ledger da sessão; o bloqueio nomeia o slug e os artefatos; dois slugs
#           sem largada saem os dois; docsRoot customizado;
#   allow — run-state do slug na casa da sessão (qualquer status) · run-state legado ·
#           evento ATIVO no ledger da casa · evento ARQUIVADO (reported-*/) — ciclo entregue
#           com run-state removido após o push · ledger LEGADO · artefato só no passivo
#           histórico (já na main) · TASK-INDEX/INDEX/briefs/handoffs não são sinal ·
#           arquivo fora de docsRoot · rota pontual (só código) · run-state/ledger de OUTRA
#           sessão contam (4.395 — posse é do wave-guard) · run-state de OUTRO slug não
#           cobre este · branch EMPILHADA sobre ciclo-pai não mesclado (4.415: nega as
#           demais refs; ref descendente e tracking próprio não silenciam; a mensagem lista
#           só os artefatos do slug acusado) · sem ficha · sem git · stop_hook_active ·
#           anti-renudge (mesmo conjunto → silêncio; artefato novo → cutuca de novo) · JSON inválido.
#
# Uso: scripts/tests/largada-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/largada-guard.sh"
SC="$HERE/../.."
[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "largada-guard: AVISO — python3 ausente; pulando." >&2; exit 0; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n largada-guard.sh"; exit 1; }
echo "ok   bash -n largada-guard.sh"

SID="sessaolg-1111-2222"
PROJ="$TMP/proj"
commit() { git -C "$PROJ" add -A; git -C "$PROJ" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "${1:-c}"; }
novo_repo() { # [docsRoot]
  rm -rf "$PROJ"; mkdir -p "$PROJ/${1:-docs}/pagamentos/specs" "$PROJ/${1:-docs}/pagamentos/plans" "$PROJ/${1:-docs}/pagamentos/tasks" "$PROJ/src"
  git -C "$PROJ" init -q -b main 2>/dev/null || { git -C "$PROJ" init -q; git -C "$PROJ" checkout -q -b main; }
  printf '{ "docsRoot": "%s", "codePaths": { "backend": ["src"] } }\n' "${1:-docs}" > "$PROJ/keelson.config.json"
  printf 'a\n' > "$PROJ/src/a.py"
  commit base
  git -C "$PROJ" checkout -q -b feat/pagamentos
}
spec() { mkdir -p "$(dirname "$1")"; printf '# SPEC\n\n**Slug**: pagamentos\n' > "$1"; }
S() { env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="$SID" RUN_STATE_SESSAO="$SID" bash "$@"; }

payload() { printf '{"cwd": "%s", "stop_hook_active": %s, "session_id": "%s"}' "$PROJ" "${1:-false}" "$SID"; }
decisao() { # [payload] → block | allow | erro:<st>
  out="$(bash "$HOOK" 2>"$TMP/err" <<< "${1:-$(payload)}")"
  st=$?
  [ "$st" -eq 0 ] || { printf 'erro:%s' "$st"; return; }
  if [ -z "$out" ]; then printf 'allow'
  elif printf '%s' "$out" | python3 -c 'import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get("decision")=="block" else 1)' 2>/dev/null; then printf 'block'
  else printf 'outro:%s' "$out"; fi
}
caso() { # nome esperado [payload]
  name="$1"; want="$2"
  total=$((total + 1))
  got="$(decisao "${3:-}")"
  if [ "$got" = "$want" ]; then echo "ok   $name"
  else echo "FAIL $name: esperado $want, veio $got"; fail=$((fail + 1)); fi
}

# --- block: artefato SDD nesta branch sem largada ---
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; caso spec-nova-sem-largada-block block
novo_repo; spec "$PROJ/docs/pagamentos/plans/PLAN-001-x.md"; caso plan-nova-sem-largada-block block
novo_repo; spec "$PROJ/docs/pagamentos/tasks/TASK-001-001-x.md"; caso task-nova-sem-largada-block block
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; commit spec-na-branch; caso commitada-na-branch-sem-largada-block block
novo_repo docs2; spec "$PROJ/docs2/pagamentos/specs/SPEC-001-x.md"; caso docsroot-custom-block block

# mensagem nomeia slug e artefatos; dois slugs saem os dois
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; spec "$PROJ/docs/cobranca/tasks/TASK-001-001-y.md"
total=$((total + 1))
r="$(bash "$HOOK" 2>/dev/null <<< "$(payload)" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("reason",""))' 2>/dev/null)"
case "$r" in
  *"— cobranca"*"— pagamentos"*"docs/cobranca/tasks/TASK-001-001-y.md"*"docs/pagamentos/specs/SPEC-001-x.md"*"run-state.sh"*) echo "ok   reason-nomeia-slugs-e-artefatos" ;;
  *) echo "FAIL reason-nomeia-slugs-e-artefatos: $r"; fail=$((fail + 1)) ;;
esac

# --- allow: a largada existe ---
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
S "$SC/run-state.sh" "$PROJ" open pagamentos "largada" >/dev/null 2>&1
caso run-state-aberto-na-casa-allow allow
S "$SC/run-state.sh" "$PROJ" close pagamentos "entrega" >/dev/null 2>&1
caso run-state-encerrado-ainda-prova-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
mkdir -p "$PROJ/thoughts/local"; printf 'status: em_andamento\nslug: pagamentos\nsessao: desconhecida\n' > "$PROJ/thoughts/local/run-state-pagamentos.md"
caso run-state-legado-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
printf 'APROVADO\n' | S "$SC/ledger.sh" "$PROJ" append gate code-reviewer pagamentos --ts "2026-09-08T10:00:00-0300" >/dev/null 2>&1
caso ledger-ativo-na-casa-allow allow
S "$SC/ledger.sh" "$PROJ" archive --ts "2026-09-08T11:00:00-0300" >/dev/null 2>&1
caso ledger-arquivado-apos-entrega-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
mkdir -p "$PROJ/thoughts/local/session-ledger"; printf 'ts: 2026-09-08T10:00:00-0300 · tipo: gate · origem: qa · slug: pagamentos\nok\n' > "$PROJ/thoughts/local/session-ledger/20260908-100000-gate-qa.md"
caso ledger-legado-allow allow
# largada registrada por OUTRA sessão conta (4.395): posse é do wave-guard, não deste guard
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="outra-sessao-9999" RUN_STATE_SESSAO="outra-sessao-9999" bash "$SC/run-state.sh" "$PROJ" open pagamentos "largada alheia" >/dev/null 2>&1
caso run-state-de-outra-sessao-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
printf 'ok\n' | env -u CLAUDE_CODE_SESSION_ID KEELSON_SESSAO="outra-sessao-9999" bash "$SC/ledger.sh" "$PROJ" append gate qa pagamentos --ts "2026-09-08T10:00:00-0300" >/dev/null 2>&1
caso ledger-de-outra-sessao-allow allow
# run-state/ledger de OUTRO slug não cobre este
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
S "$SC/run-state.sh" "$PROJ" open cobranca "largada de outro" >/dev/null 2>&1
printf 'x\n' | S "$SC/ledger.sh" "$PROJ" append gate qa cobranca --ts "2026-09-08T10:00:00-0300" >/dev/null 2>&1
caso largada-de-outro-slug-nao-cobre-block block

# --- allow: não é sinal ---
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; git -C "$PROJ" checkout -q main; commit spec-historica-na-main; git -C "$PROJ" checkout -q -b feat/outra
caso passivo-historico-na-main-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/tasks/TASK-001-INDEX.md"; spec "$PROJ/docs/pagamentos/INDEX.md"; mkdir -p "$PROJ/docs/pagamentos/briefs" "$PROJ/docs/pagamentos/handoffs"; spec "$PROJ/docs/pagamentos/briefs/BRIEF-001.md"; spec "$PROJ/docs/pagamentos/handoffs/HANDOFF-001.md"
caso derivados-e-briefs-nao-sao-sinal-allow allow
novo_repo; mkdir -p "$PROJ/outro/pagamentos/specs"; spec "$PROJ/outro/pagamentos/specs/SPEC-001-x.md"; caso fora-de-docsroot-allow allow
novo_repo; printf 'b\n' >> "$PROJ/src/a.py"; caso rota-pontual-so-codigo-allow allow
novo_repo; caso arvore-limpa-allow allow

# --- branch empilhada (4.415): o ciclo-pai não mesclado não é "desta branch" ---
# feat/pai carrega a SPEC de `identidade` sem largada em casa nenhuma; feat/pagamentos
# nasce sobre feat/pai com run-state aberto só para pagamentos → silêncio.
novo_repo; git -C "$PROJ" checkout -q -b feat/pai; mkdir -p "$PROJ/docs/identidade/specs"
printf '# SPEC\n\n**Slug**: identidade\n' > "$PROJ/docs/identidade/specs/SPEC-001-id.md"; commit spec-do-pai
git -C "$PROJ" checkout -q -B feat/pagamentos; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; commit spec-filha
S "$SC/run-state.sh" "$PROJ" open pagamentos "largada" >/dev/null 2>&1
caso branch-empilhada-nao-herda-ciclo-pai-allow allow
# sem largada nenhuma, a acusação nomeia SÓ o slug desta branch e SÓ os artefatos dele
novo_repo; git -C "$PROJ" checkout -q -b feat/pai; mkdir -p "$PROJ/docs/identidade/specs"
printf '# SPEC\n\n**Slug**: identidade\n' > "$PROJ/docs/identidade/specs/SPEC-001-id.md"; commit spec-do-pai
git -C "$PROJ" checkout -q -B feat/pagamentos; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; commit spec-filha
total=$((total + 1))
r="$(bash "$HOOK" 2>/dev/null <<< "$(payload)" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("reason",""))' 2>/dev/null)"
case "$r" in
  *"— pagamentos"*"docs/pagamentos/specs/SPEC-001-x.md"*) case "$r" in *identidade*) echo "FAIL branch-empilhada-acusa-so-esta-branch: cita identidade: $r"; fail=$((fail + 1)) ;; *) echo "ok   branch-empilhada-acusa-so-esta-branch" ;; esac ;;
  *) echo "FAIL branch-empilhada-acusa-so-esta-branch: $r"; fail=$((fail + 1)) ;;
esac
# mensagem lista só os artefatos do slug acusado (dois slugs na branch, um com largada)
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; spec "$PROJ/docs/cobranca/tasks/TASK-001-001-y.md"
S "$SC/run-state.sh" "$PROJ" open cobranca "largada" >/dev/null 2>&1
total=$((total + 1))
r="$(bash "$HOOK" 2>/dev/null <<< "$(payload)" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("reason",""))' 2>/dev/null)"
case "$r" in
  *"docs/cobranca/"*) echo "FAIL artefatos-so-do-slug-acusado: lista cobranca: $r"; fail=$((fail + 1)) ;;
  *"— pagamentos"*"docs/pagamentos/specs/SPEC-001-x.md"*) echo "ok   artefatos-so-do-slug-acusado" ;;
  *) echo "FAIL artefatos-so-do-slug-acusado: $r"; fail=$((fail + 1)) ;;
esac
# ref que DESCENDE de HEAD (worktree de wave, 4.334) e tracking remoto da própria branch não
# apagam o universo: a SPEC commitada nesta branch continua acusada
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; commit spec-na-branch
git -C "$PROJ" branch -q feat/pagamentos-wave-1; git -C "$PROJ" checkout -q feat/pagamentos-wave-1; printf 'w\n' >> "$PROJ/src/a.py"; commit wave; git -C "$PROJ" checkout -q feat/pagamentos
caso ref-descendente-nao-silencia-block block
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; commit spec-na-branch
git -C "$PROJ" update-ref refs/remotes/origin/feat/pagamentos HEAD
caso tracking-remoto-proprio-nao-silencia-block block

# --- anti-renudge ---
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
caso primeira-vez-block block
caso mesmo-conjunto-nao-recutuca allow
spec "$PROJ/docs/pagamentos/plans/PLAN-001-x.md"
caso artefato-novo-recutuca block
total=$((total + 1))
if [ -f "$PROJ/.git/keelson-largada-guard.last" ]; then echo "ok   marcador-em-git"; else echo "FAIL marcador-em-git"; fail=$((fail + 1)); fi

# --- fallback gracioso ---
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"
caso stop-hook-active-allow allow "$(payload true)"
rm -f "$PROJ/keelson.config.json"; caso sem-ficha-allow allow
novo_repo; spec "$PROJ/docs/pagamentos/specs/SPEC-001-x.md"; rm -rf "$PROJ/.git"; caso sem-git-allow allow
caso cwd-ausente-allow allow '{"stop_hook_active": false}'
caso json-invalido-allow allow '{nao e json'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "largada-guard: $fail de $total casos falharam"
  exit 1
fi
echo "largada-guard: $total casos verdes"
exit 0
