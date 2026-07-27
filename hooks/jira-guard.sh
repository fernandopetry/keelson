#!/usr/bin/env bash
# jira-guard — hook Stop que impede encerrar o turno com artefato SDD novo sem
# sincronizar com o Jira, quando a ficha declara jira.enabled: true (decisão 4.47).
#
# Por que existe: o gancho de sync é a ÚLTIMA sub-etapa do /keelson:specify e do
# /keelson:tasks, é condicional ("só quando jira.enabled") e cumpri-lo custa reler
# a ficha, abrir um protocolo longo e fazer chamadas MCP — no meio de um /keelson:auto
# focado em entregar código, é a primeira coisa sacrificada. Caso real (2026-07-26):
# sessão com plugin 0.27.0, ganchos presentes, conector à mão, ficha correta — SPEC
# criada e ZERO chamadas ao Jira. Texto mandando fazer já existia em dois comandos e
# foi ignorado; nada verificava depois. Este guard é a verificação que faltava.
#
# Complementa a 4.46 (rastro durável do pulo): aquela regra só é executada por quem
# ENTRA no protocolo. Quem nunca abre o protocolo não deixa rastro — é esse buraco
# que o guard fecha, exigindo sync OU registro explícito do motivo.
#
# Escopo deliberadamente estreito: só artefatos SDD TOCADOS NESTA BRANCH (working
# tree + diff contra a base). Passivo histórico já mergeado não é problema deste
# turno e transformaria o guard em renudge perpétuo.
#
# Fallback gracioso: sem python3, sem cwd, sem ficha, jira desligado, sem artefato
# pendente → exit 0. stop_hook_active + fingerprint evitam loop e repetição.

set -euo pipefail

input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0

active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null || echo False)"
if [ "$active" = "True" ]; then exit 0; fi

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then exit 0; fi
[ -f "$cwd/keelson.config.json" ] || exit 0

ficha="$(python3 - "$cwd/keelson.config.json" <<'PY' 2>/dev/null || true
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
j = d.get("jira") or {}
print("1" if j.get("enabled") is True else "0")
print(d.get("docsRoot") or "docs")
PY
)"
if [ -z "$ficha" ]; then exit 0; fi
enabled="$(printf '%s' "$ficha" | sed -n 1p)"
[ "$enabled" = "1" ] || exit 0
docs_root="$(printf '%s' "$ficha" | sed -n 2p)"
if [ -z "$docs_root" ]; then docs_root="docs"; fi

# --- candidatos: artefatos SDD tocados nesta branch (não o passivo histórico) ---
base=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  base="$(git -C "$cwd" merge-base HEAD origin/main 2>/dev/null || git -C "$cwd" merge-base HEAD main 2>/dev/null || true)"
fi

tocados="$(
  {
    # -uall: sem ele, o git resume diretório novo inteiro numa linha ("?? docs/slug/tasks/")
    # e as TASKs recém-criadas pelo /keelson:tasks passariam despercebidas.
    git -C "$cwd" status --porcelain -uall 2>/dev/null | sed 's/^...//' || true
    if [ -n "$base" ]; then git -C "$cwd" diff --name-only "$base"...HEAD 2>/dev/null || true; fi
  } | sed 's/^"//; s/"$//' | sort -u
)"
if [ -z "$tocados" ]; then exit 0; fi

tem_key() {
  grep -Eq '^\*\*Jira( Story)?\*\*:[[:space:]]*[A-Z][A-Z0-9_]*-[0-9]+' "$1" 2>/dev/null && return 0
  grep -Eq '(^|[[:space:]*])Jira\*{0,2}:[[:space:]]*[A-Z][A-Z0-9_]*-[0-9]+' "$1" 2>/dev/null && return 0
  return 1
}

pend_spec=0
pend_task=0
detalhes=""
slugs=""
while IFS= read -r rel; do
  if [ -z "$rel" ]; then continue; fi
  case "$rel" in
    "$docs_root"/*/specs/SPEC-*.md) tipo="SPEC" ;;
    "$docs_root"/*/tasks/TASK-*.md)
      case "$rel" in *-INDEX.md) continue ;; esac
      tipo="TASK" ;;
    *) continue ;;
  esac
  abs="$cwd/$rel"
  if [ ! -f "$abs" ]; then continue; fi
  if tem_key "$abs"; then continue; fi

  slug="$(printf '%s' "$rel" | sed "s|^$docs_root/||; s|/.*||")"
  # Pulo já registrado no INDEX do slug (decisão 4.46) → tratado, não cutuca.
  if [ -f "$cwd/$docs_root/$slug/INDEX.md" ] && \
     grep -qi 'sync jira pulado' "$cwd/$docs_root/$slug/INDEX.md" 2>/dev/null; then
    continue
  fi

  if [ "$tipo" = "SPEC" ]; then
    pend_spec=$((pend_spec + 1))
    detalhes="${detalhes}
— ${rel} (sem linha **Jira**:)"
  else
    pend_task=$((pend_task + 1))
  fi
  case " $slugs " in *" $slug "*) : ;; *) slugs="$slugs $slug" ;; esac
done <<EOF
$tocados
EOF

total=$((pend_spec + pend_task))
if [ "$total" -eq 0 ]; then exit 0; fi
if [ "$pend_task" -gt 0 ]; then
  detalhes="${detalhes}
— ${pend_task} TASK(s) sem key na closure"
fi

# Anti-renudge: mesmo conjunto pendente só cutuca uma vez.
git_dir="$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null || true)"
marker="" fingerprint=""
if [ -n "$git_dir" ]; then
  marker="$git_dir/keelson-jira-guard.last"
  fingerprint="$(printf '%s' "$detalhes" | git hash-object --stdin 2>/dev/null || true)"
  if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
    exit 0
  fi
fi

reason="jira-guard (keelson, decisão 4.47): a ficha declara jira.enabled: true, mas há artefato SDD criado/alterado nesta branch sem key do Jira:
${detalhes}

Slug(s):${slugs}

O gancho de sync (Etapa 5.3 do /keelson:specify, Etapa 7 do /keelson:tasks, closure do /keelson:implement) não deixou rastro. Faça agora UMA das duas coisas:
1. SINCRONIZE: aplique o protocolo (\${CLAUDE_PLUGIN_ROOT}/skills/_shared/jira-sync-protocol.md) — ou rode /keelson:jira-sync <slug> — e grave as keys nos artefatos.
2. Se o sync NÃO é possível (conector indisponível, projeto/tipo não resolvido): PROVE (protocolo §0 — carregue as ferramentas e faça a chamada de prova; 'não vi as ferramentas' não é evidência) e registre 1 linha no 'Histórico recente' do INDEX do slug com o motivo e a evidência, no formato 'sync Jira pulado (<o quê>) — <prova>'. Esse registro dispensa este guard nas próximas vezes.
Não encerre sem fazer uma das duas."

printf '%s' "$reason" | python3 -c 'import sys,json; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))' 2>/dev/null || exit 0

if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
  printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
fi

exit 0
