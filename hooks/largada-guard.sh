#!/usr/bin/env bash
# largada-guard — hook Stop que acusa CICLO FORMAL SEM LARGADA REGISTRADA (decisão 4.391).
#
# Caso real (smoke com modelo real, 4.390): o /keelson:auto conduziu SPEC → PLAN → TASK →
# implementação num consumidor e, no relatório, declarou que "dado o tamanho pequeno da
# feature, simplificou a mecânica pesada do protocolo (ledger de sessão, run-state, …)".
# Os itens 5 e 5.5 da Etapa 0.5 do auto (4.76, 4.348) não têm cláusula de tamanho — e sem
# run-state o wave-guard nunca arma, sem ledger os stop-guards não têm veredito para ler:
# a guarda mecânica do ciclo foi contornada antes de nascer. Texto de doutrina reforçando
# seria no-op (o texto existia e foi lido — 4.160); este guard é a verificação que faltava.
#
# Sinal (todos ao mesmo tempo):
#   1. artefato SDD (specs/SPEC-*, plans/PLAN-*, tasks/TASK-* sob <docsRoot>/<slug>/) criado
#      ou alterado NESTA BRANCH — working tree + diff contra a base (main/origin/main),
#      nunca o passivo histórico já mergeado;
#   2. NENHUM run-state para o slug em NENHUMA casa de sessão nem no caminho legado — de
#      qualquer status: o auto abre na largada (open) e só remove depois do push;
#   3. NENHUM evento de ledger (ativo ou arquivado em reported-*/, qualquer casa ou
#      legado) citando o slug — um ciclo conduzido de verdade deixa vereditos de gate.
# Largada de OUTRA sessão conta (4.395 — smoke: a sessão que continuou um ciclo alheio
# recebia a cutucada; posse é do wave-guard): o sinal é "houve largada", não "é minha".
# Rota pontual (4.86/4.137) não produz artefato SDD → nunca dispara. Ciclo entregue com
# run-state removido após o push → o ledger arquivado ainda prova a largada → silêncio.
#
# Cutuca 1× por conjunto de artefatos (fingerprint em .git/, mesmo desenho do doc-guard);
# stop_hook_active evita loop. Fallback gracioso: sem python3, sem cwd, sem ficha, sem
# git → exit 0. Bash 3.2-compatível.

set -euo pipefail

input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null || echo False)"
[ "$active" = "True" ] && exit 0

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0
[ -f "$cwd/keelson.config.json" ] || exit 0
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0

SCRIPTS="$(cd "$(dirname "$0")/../scripts" 2>/dev/null && pwd)"
docs_root="docs"
if [ -f "$SCRIPTS/ficha.sh" ]; then
  dr="$(bash "$SCRIPTS/ficha.sh" "$cwd" --get docsRoot --default docs 2>/dev/null || true)"
  [ -n "$dr" ] && docs_root="$dr"
fi
docs_root="${docs_root%/}"

# --- 1. artefatos SDD tocados nesta branch ---
base="$(git -C "$cwd" merge-base HEAD origin/main 2>/dev/null || git -C "$cwd" merge-base HEAD main 2>/dev/null || true)"
tocados="$(
  {
    git -C "$cwd" status --porcelain -uall 2>/dev/null | sed 's/^...//; s/^.* -> //' || true
    if [ -n "$base" ]; then git -C "$cwd" diff --name-only "$base"...HEAD 2>/dev/null || true; fi
  } | sed 's/^"//; s/"$//' | sort -u \
    | grep -E "^$docs_root/[^/]+/(specs/SPEC-|plans/PLAN-|tasks/TASK-)[^/]*\.md$" \
    | grep -v -- '-INDEX\.md$' || true
)"
[ -n "$tocados" ] || exit 0

slugs="$(printf '%s\n' "$tocados" | sed "s|^$docs_root/||; s|/.*||" | sort -u)"

# --- casa da sessão (4.314) + legado ---
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id", ""))' 2>/dev/null || echo "")"
home=""
if [ -n "$sid" ] && [ -f "$SCRIPTS/session-dir.sh" ]; then
  home="$(KEELSON_SESSAO="$sid" bash "$SCRIPTS/session-dir.sh" "$cwd" dir 2>/dev/null || true)"
  [ "$home" = "$cwd/thoughts/local" ] && home=""
fi
legado="$cwd/thoughts/local"

# A largada conta quando QUALQUER sessão a registrou (4.395): a casa desta sessão, a de
# outra sessão (continuação de um ciclo que outra sessão largou — /keelson:continue, ou a
# sessão anterior caiu) ou o legado. De quem é o run é pergunta do wave-guard (posse,
# 4.251), não deste guard — aqui o sinal é "houve largada", nunca "a largada é minha".
tem_run_state() { # slug → 0 se existe run-state (qualquer status, qualquer casa)
  [ -n "$home" ] && [ -f "$home/run-state-$1.md" ] && return 0
  [ -f "$legado/run-state-$1.md" ] && return 0
  for d in "$legado"/sessions/*/; do
    [ -f "$d/run-state-$1.md" ] && return 0
  done
  return 1
}
tem_ledger() { # slug → 0 se algum evento (ativo ou arquivado, qualquer casa) cita o slug
  for d in "$home/ledger" "$legado/session-ledger" "$legado"/sessions/*/ledger; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    if find "$d" -name '*.md' -type f -exec grep -l "· slug: $1\$" {} + 2>/dev/null | grep -q .; then return 0; fi
  done
  return 1
}

sem_largada=""
while IFS= read -r slug; do
  [ -n "$slug" ] || continue
  tem_run_state "$slug" && continue
  tem_ledger "$slug" && continue
  sem_largada="${sem_largada}${slug}"$'\n'
done <<EOF
$slugs
EOF
[ -n "$sem_largada" ] || exit 0

# --- anti-renudge: mesmo conjunto de artefatos só cutuca uma vez ---
git_dir="$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null || true)"
marker=""; fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-largada-guard.last"
  fingerprint="$(printf '%s\n%s' "$sem_largada" "$tocados" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

lista="$(printf '%s' "$sem_largada" | sed '/^$/d; s/^/    — /')"
arqs="$(printf '%s\n' "$tocados" | sed 's/^/    — /' | head -12)"
reason="largada-guard (keelson, decisão 4.391): há artefato SDD criado/alterado NESTA branch, mas nenhuma largada registrada nesta sessão para o slug — sem run-state (run-state.sh open, decisão 4.348) e sem nenhum evento no ledger da sessão (decisão 4.76).

Slug(s) sem largada:
${lista}
Artefatos:
${arqs}

Ciclo formal não tem versão 'leve': sem run-state a guarda de waves nunca arma, sem ledger os stop-guards não têm veredito para ler e o report se reconstrói de memória. Tamanho da feature não é cláusula de dispensa (Etapa 0.5 do /keelson:auto, itens 5 e 5.5).

Faça UMA das duas coisas antes de encerrar:
1. Registre a largada agora e siga pelo protocolo: bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/run-state.sh\" <raiz> open <slug> \"<BRIEF>\" e, para cada veredito de gate já emitido, bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/ledger.sh\" <raiz> append gate <origem> <slug> com o corpo do veredito.
2. Se os artefatos não são de um ciclo (edição manual de doc, migração legada, rebuild), diga isso ao humano em uma linha — este aviso não se repete para o mesmo conjunto de arquivos."

if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi
printf '%s' "$reason" | python3 -c 'import sys,json; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))' 2>/dev/null || exit 0
exit 0
