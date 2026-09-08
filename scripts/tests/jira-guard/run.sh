#!/usr/bin/env bash
# run.sh — suíte de regressão do jira-guard (decisões 4.47/4.385).
#
# Roda o hook de verdade (stdin JSON, python3, git) num repo temporário com ficha
# jira.enabled. Casos inline:
#   block — SPEC/TASK nova (untracked) ou alterada sem linha **Jira**:; artefato
#           commitado na BRANCH (diff contra main) sem key; o bloqueio nomeia a
#           SPEC, conta as TASKs e o slug;
#   allow — jira desligado/ausente; key presente (formas **Jira**: e **Jira Story**:);
#           TASK-INDEX excluída; pulo registrado no INDEX ("sync Jira pulado");
#           artefato do passivo histórico (já na main); docsRoot customizado; arquivo
#           fora de docsRoot; sem ficha; stop_hook_active; anti-renudge (mesmo conjunto
#           → silêncio; conjunto diferente → cutuca de novo).
#
# Uso: scripts/tests/jira-guard/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../../../hooks/jira-guard.sh"

[ -f "$HOOK" ] || { echo "ERRO: hook não encontrado em $HOOK" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "jira-guard: AVISO — python3 ausente, o hook degrada; pulando." >&2; exit 0; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$HOOK" || { echo "FAIL bash -n jira-guard.sh"; exit 1; }
echo "ok   bash -n jira-guard.sh"

PROJ="$TMP/proj"
commit() { git -C "$PROJ" add -A; git -C "$PROJ" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "${1:-c}"; }
novo_repo() { # [enabled=true] [docsRoot=docs]
  rm -rf "$PROJ"; mkdir -p "$PROJ/${2:-docs}/slug/specs" "$PROJ/${2:-docs}/slug/tasks"
  git -C "$PROJ" init -q -b main 2>/dev/null || { git -C "$PROJ" init -q; git -C "$PROJ" checkout -q -b main; }
  printf '{ "docsRoot": "%s", "jira": { "enabled": %s } }\n' "${2:-docs}" "${1:-true}" > "$PROJ/keelson.config.json"
  printf '# INDEX\n\n## Histórico recente\n' > "$PROJ/${2:-docs}/slug/INDEX.md"
  commit base
}
spec() { # caminho [linha-jira]
  { printf '# SPEC-001: x\n\n**Slug**: slug\n'; [ -n "${2:-}" ] && printf '%s\n' "$2"; printf '\n## 1.\n'; } > "$1"
}

payload() { printf '{"cwd": "%s", "stop_hook_active": %s}' "$PROJ" "${1:-false}"; }
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

# --- desligado / ausente ---
novo_repo false; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; caso jira-desligado-allow allow
novo_repo; printf '{ "docsRoot": "docs" }\n' > "$PROJ/keelson.config.json"; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; caso jira-ausente-na-ficha-allow allow
novo_repo; rm -f "$PROJ/keelson.config.json"; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; caso sem-ficha-allow allow
novo_repo; caso arvore-limpa-allow allow

# --- pendências no working tree ---
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; caso spec-nova-sem-key-block block
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md" '**Jira**: PROJ-12'; caso spec-com-key-allow allow
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md" '**Jira Story**: PROJ-12'; caso spec-com-jira-story-allow allow
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md" '**Jira**: <preencher>'; caso spec-key-placeholder-block block
novo_repo; spec "$PROJ/docs/slug/tasks/TASK-001-001-x.md"; caso task-nova-sem-key-block block
novo_repo; spec "$PROJ/docs/slug/tasks/TASK-INDEX.md"; caso task-index-excluida-allow allow
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; printf -- '- 2026-09-07: sync Jira pulado (conector indisponível) — prova: chamada §0 falhou\n' >> "$PROJ/docs/slug/INDEX.md"
caso pulo-registrado-no-index-allow allow
novo_repo; mkdir -p "$PROJ/docs/slug/plans"; spec "$PROJ/docs/slug/plans/PLAN-001-x.md"
caso plan-nao-e-candidato-allow allow
novo_repo; mkdir -p "$PROJ/outro/slug/specs"; spec "$PROJ/outro/slug/specs/SPEC-001-x.md"; caso fora-de-docsroot-allow allow
novo_repo true documentacao; spec "$PROJ/documentacao/slug/specs/SPEC-001-x.md"; caso docsroot-custom-block block

# --- branch vs passivo histórico ---
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; commit spec-na-main
caso passivo-historico-na-main-allow allow
git -C "$PROJ" checkout -q -b feat; spec "$PROJ/docs/slug/specs/SPEC-002-y.md"; commit spec-na-branch
caso commitado-na-branch-sem-key-block block
spec "$PROJ/docs/slug/specs/SPEC-002-y.md" '**Jira**: PROJ-7'; commit key-na-branch
caso branch-key-adicionada-allow allow

# --- anti-renudge ---
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"
caso primeira-vez-block block
caso mesmo-conjunto-nao-recutuca allow
spec "$PROJ/docs/slug/tasks/TASK-001-001-x.md"
caso conjunto-diferente-recutuca block
caso stop-hook-active-allow allow "$(payload true)"

# --- mensagem nomeia SPEC, conta TASKs e cita o slug ---
novo_repo; spec "$PROJ/docs/slug/specs/SPEC-001-x.md"; spec "$PROJ/docs/slug/tasks/TASK-001-001-x.md"; spec "$PROJ/docs/slug/tasks/TASK-001-002-y.md"
total=$((total + 1))
r="$(bash "$HOOK" 2>/dev/null <<< "$(payload)" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("reason",""))' 2>/dev/null)"
case "$r" in
  *"docs/slug/specs/SPEC-001-x.md (sem linha **Jira**:)"*"2 TASK(s) sem key"*"Slug(s): slug"*) echo "ok   reason-nomeia-pendencias" ;;
  *) echo "FAIL reason-nomeia-pendencias: $r"; fail=$((fail + 1)) ;;
esac

# --- fallback gracioso ---
caso cwd-ausente-allow allow '{"stop_hook_active": false}'
caso json-invalido-allow allow '{nao e json'

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "jira-guard: $fail de $total casos falharam"
  exit 1
fi
echo "jira-guard: $total casos verdes"
exit 0
