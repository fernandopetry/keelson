#!/usr/bin/env bash
# doc-guard — hook Stop que reforça a Documentação Autônoma do keelson.
#
# LÊ A FICHA `keelson.config.json` na raiz do projeto (via jq) para se
# parametrizar — nada de caminho de código hardcoded. Da ficha extrai:
#   - codePaths.backend / codePaths.frontend → onde vive o código deste projeto;
#   - docsRoot                               → onde vivem os artefatos de doc.
# Bloqueia o encerramento UMA vez quando há código de feature alterado sem
# NENHUMA atualização correspondente na pasta de docs.
#
# Fallback gracioso: sem `jq` ou sem a ficha, o hook NÃO trava o fluxo — emite
# um aviso em stderr e sai 0. `stop_hook_active` evita loop dentro do mesmo turno;
# um marcador em .git/ evita re-cutucar em turnos seguintes enquanto o conjunto de
# código alterado for o mesmo (só volta a cutucar se a mudança mudar).
#
# Heurística best-effort: olha o working tree (git status). Fluxos que já
# commitaram código + docs juntos deixam o tree limpo e não disparam.
# Política: QUALITY-CHARTER (Art. 9) e docs/_meta/decisions.md (decisão 4.6).

set -euo pipefail

input="$(cat)"

# Raiz do projeto (fornecida pelo Claude Code; fallback para git/pwd).
proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
config="$proj/keelson.config.json"

# --- Fallback gracioso: sem jq, não trava o fluxo. ---
if ! command -v jq >/dev/null 2>&1; then
  echo "doc-guard: jq não encontrado; guarda de documentação desativada nesta execução." >&2
  exit 0
fi

# --- Fallback gracioso: sem a ficha, não trava o fluxo. ---
if [ ! -f "$config" ]; then
  echo "doc-guard: keelson.config.json não encontrado em $proj; guarda desativada nesta execução." >&2
  exit 0
fi

# Evita loop: se já reentramos por causa deste hook, não bloqueia de novo.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

# Paths de código e raiz de docs vindos da ficha.
code_paths="$(jq -r '((.codePaths.backend // []) + (.codePaths.frontend // []))[]?' "$config" 2>/dev/null || true)"
docs_root="$(jq -r '.docsRoot // "docs"' "$config" 2>/dev/null || echo docs)"
[ -z "$docs_root" ] && docs_root="docs"

# Sem paths de código declarados na ficha → nada a vigiar.
[ -z "$code_paths" ] && exit 0

# Status do working tree (caminhos limpos, renomeios resolvidos; -uall lista
# arquivos untracked individualmente — sem isso um diretório novo vira "dir/" e
# o fingerprint anti-renudge não muda quando um arquivo novo entra nele).
changed="$(git -C "$proj" status --porcelain -uall 2>/dev/null | sed -E 's/^.{2} //; s/^.* -> //' || true)"
[ -z "$changed" ] && exit 0

# path_has_prefix <lista-de-prefixos-multilinha> <arquivo> — true se o arquivo
# está sob algum dos prefixos (igual a ele ou dentro dele).
path_has_prefix() {
  local prefixes="$1" file="$2" p
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    p="${p%/}"                       # normaliza barra final
    [ "$file" = "$p" ] && return 0
    case "$file" in
      "$p"/*) return 0 ;;
    esac
  done <<< "$prefixes"
  return 1
}

code_changed=""
docs_changed=""
code_files=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if path_has_prefix "$code_paths" "$f"; then
    code_changed="yes"
    code_files="${code_files}${f}"$'\n'
  fi
  path_has_prefix "$docs_root" "$f" && docs_changed="yes"
done <<< "$changed"

if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
  # Anti-renudge entre turnos: stop_hook_active só cobre o turno atual; sem o marcador,
  # um working tree sujo re-dispararia o bloqueio ao fim de TODO turno da sessão.
  git_dir="$(git -C "$proj" rev-parse --absolute-git-dir 2>/dev/null || true)"
  marker="" fingerprint=""
  if [ -n "$git_dir" ]; then
    marker="$git_dir/keelson-doc-guard.last"
    fingerprint="$(printf '%s' "$code_files" | sort -u | git hash-object --stdin 2>/dev/null || true)"
    if [ -n "$fingerprint" ] && [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ]; then
      exit 0
    fi
  fi
  reason="$(cat <<EOF
Documentação Autônoma (keelson): há código de feature alterado (paths de codePaths da ficha) mas NENHUM artefato em ${docs_root}/ foi atualizado nesta mudança.

Aplique a calibração (NÃO conclua sozinho 'nada a documentar'):
- Slug COM INDEX.md, não-trivial/bugfix/refactor: rode o /keelson:* apropriado (atualiza o INDEX e faz closure).
- Slug COM INDEX.md, trivial: 1 linha em '## Histórico recente' do ${docs_root}/<slug>/INDEX.md (<data>: <descrição> (commit <sha>)).
- Slug LEGADO (pasta ${docs_root}/<slug>/ com .md mas sem INDEX.md): rode /keelson:migrate-legacy antes.
- Domínio SEM cobertura keelson e mudança NÃO-TRIVIAL/capacidade nova: OFEREÇA ao humano criar o slug (/keelson:specify), seguir registrando o débito, ou adiar — não decida sozinho.
- Domínio SEM cobertura e mudança TRIVIAL: mencione em 1 linha que o domínio não tem slug e pode encerrar — este aviso não se repetirá.
EOF
)"
  if [ -n "$marker" ] && [ -n "$fingerprint" ]; then
    printf '%s' "$fingerprint" > "$marker" 2>/dev/null || true
  fi
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi

exit 0
