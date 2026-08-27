#!/usr/bin/env bash
# init-selfcheck.sh — provas mecânicas da Etapa 6 do /keelson:init (decisão 4.154).
# "Cobertura se verifica, não se infere" (4.51/4.71): cada item abaixo é provado por
# execução/matching real, nunca por leitura da config. A parte que exige MCP vivo
# (runtime Playwright respondendo, conector Jira) continua do comando — este script
# cobre o que o disco e o git provam sozinhos.
#
# Uso: init-selfcheck.sh <raiz-do-projeto> [--plugin-root <dir>] [--claude-json <path>]
#
# Saída: ok|aviso|falha<TAB>item<TAB>detalhe  (ordenada por item; LC_ALL=C)
# Itens: hooks-executaveis · ficha-legivel · codepaths-existem · quality-existe ·
#        sensitive-globs · perfil-resolve · perfil-reviewed · perfil-charter ·
#        local-example · local-json-ignorado · local-placeholder ·
#        artefatos-ignorados · playwright-flags · jira-campos · git-branch-config ·
#        models-validos
# Exit: 0 sem falha · 1 com falha · 2 uso incorreto.
#
# Bash 3.2-compatível; JSON via ficha.sh (irmão) e python3 (playwright/local.json;
# ausente → aviso "sem parser", nunca ✗ inventado). Read-only.

set -u
# git herdado de contexto de hook aponta para OUTRO repo — neutralizar antes de qualquer git
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_PREFIX
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/ficha.sh"

ROOT=""
PLUGROOT="${CLAUDE_PLUGIN_ROOT:-}"
CLAUDEJSON="${HOME:-/nonexistent}/.claude.json"

while [ $# -gt 0 ]; do
  case "$1" in
    --plugin-root) shift; [ $# -gt 0 ] || die2 "--plugin-root exige um diretório."; PLUGROOT="$1" ;;
    --claude-json) shift; [ $# -gt 0 ] || die2 "--claude-json exige um caminho."; CLAUDEJSON="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1" ;;
    *) [ -z "$ROOT" ] || die2 "apenas uma raiz por vez."; ROOT="$1" ;;
  esac
  shift
done
[ -n "$ROOT" ] || { usage >&2; exit 2; }
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"
[ -n "$PLUGROOT" ] || PLUGROOT="$(cd "$HERE/.." && pwd)"

TMP="$(mktemp -d)" || die2 "mktemp falhou."
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/out.txt"
: > "$OUT"

emit() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$OUT"; }
fget() { bash "$FICHA_SH" "$ROOT" --get "$1" 2>/dev/null; }

have_git=0
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  have_git=1
fi

# ---- hooks do plugin executáveis (4.180) ----
# hooks.json invoca hooks/*.sh diretamente: sem bit de execução o hook falha em
# silêncio a cada disparo (caso de campo: 269 falhas de Stop em 3 dias). O chmod no
# cache local evapora no próximo update — a correção durável é no git do plugin.
if [ -d "$PLUGROOT/hooks" ]; then
  hx_bad=""
  for h in "$PLUGROOT"/hooks/*.sh; do
    [ -f "$h" ] || continue
    [ -x "$h" ] || hx_bad="$hx_bad $(basename "$h")"
  done
  if [ -n "$hx_bad" ]; then
    emit falha hooks-executaveis "hook sem bit de execução (falha silenciosa a cada disparo) — repare: chmod +x em$hx_bad"
  else
    emit ok hooks-executaveis "todos os hooks do plugin têm bit de execução"
  fi
fi

# ---- ficha legível ----
if ! bash "$FICHA_SH" "$ROOT" --get docsRoot >/dev/null 2>"$TMP/ferr"; then
  emit falha ficha-legivel "$(sed -n 1p "$TMP/ferr")"
  sort "$OUT"; exit 1
fi
emit ok ficha-legivel "keelson.config.json parseado"

# ---- codePaths existem ----
cp_bad=""
for p in $( { fget codePaths.backend; fget codePaths.frontend; } ); do
  [ -n "$p" ] || continue
  case "$p" in *'*'*) continue ;; esac   # glob: existência não é um único diretório
  [ -e "$ROOT/$p" ] || cp_bad="$cp_bad $p"
done
if [ -n "$cp_bad" ]; then emit falha codepaths-existem "não existem no disco:$cp_bad"
else emit ok codepaths-existem "todos os codePaths existem"; fi

# ---- quality.* declarados existem no disco/PATH (sem executar nada) ----
q_bad=""
for k in test lint typecheck build boot mutation; do
  cmd="$(fget "quality.$k")"
  [ -n "$cmd" ] || continue
  first="${cmd%% *}"
  if command -v "$first" >/dev/null 2>&1; then continue; fi
  if [ -x "$ROOT/$first" ] || [ -f "$ROOT/$first" ]; then continue; fi
  q_bad="$q_bad quality.$k($first)"
done
if [ -n "$q_bad" ]; then emit aviso quality-existe "comando não encontrado no PATH nem na raiz:$q_bad"
else emit ok quality-existe "todos os quality.* declarados resolvem"; fi

# ---- sensitiveGlobs cobrem os candidatos reais (matching real — 4.71) ----
fget sensitiveGlobs > "$TMP/globs.txt"
( cd "$ROOT" && find . \( -name .git -o -name node_modules -o -name vendor -o -name .wiki \) -prune -o \
    -type f \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.key' \) -print 2>/dev/null ) \
  | sed 's|^\./||' | grep -v '\.example' > "$TMP/cand.txt" || true
sg_bad=""
while IFS= read -r cand; do
  [ -n "$cand" ] || continue
  hit=0
  # $gpat sem aspas no case é o ponto: o candidato é casado contra o GLOB da ficha
  # shellcheck disable=SC2254
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    gpat="$g"
    case "$gpat" in *'**'*) gpat="$(printf '%s' "$gpat" | sed 's/\*\*/\*/g')" ;; esac
    case "$cand" in $gpat) hit=1; break ;; esac
    case "$gpat" in
      */*) : ;;
      *) case "$(basename "$cand")" in $gpat) hit=1; break ;; esac ;;
    esac
  done < "$TMP/globs.txt"
  [ "$hit" = 1 ] || sg_bad="$sg_bad $cand"
done < "$TMP/cand.txt"
if [ -n "$sg_bad" ]; then emit falha sensitive-globs "candidato de segredo sem glob que o cubra:$sg_bad"
else emit ok sensitive-globs "todos os candidatos em disco casam com sensitiveGlobs"; fi

# ---- perfil resolve + reviewed + charter ----
charter_cur="$(sed -n 's/.*\*\*Versão: \([0-9][0-9.]*\)\*\*.*/\1/p' "$PLUGROOT/guidelines/_meta/QUALITY-CHARTER.md" 2>/dev/null | sed -n 1p)"
pr_bad=""; rev_pend=""; ch_old=""
for role in backend frontend; do
  f="$(bash "$FICHA_SH" "$ROOT" --resolve-profile "$role" --plugin-root "$PLUGROOT" 2>/dev/null)"
  [ -n "$f" ] || continue
  if [ ! -f "$f" ]; then pr_bad="$pr_bad $role($f)"; continue; fi
  if sed -n '1,10p' "$f" | grep -q '^reviewed: *false'; then rev_pend="$rev_pend $role"; fi
  pch="$(sed -n '1,10p' "$f" | sed -n 's/^charter: *//p' | tr -d '"' | sed -n 1p)"
  if [ -n "$pch" ] && [ -n "$charter_cur" ] && [ "$pch" != "$charter_cur" ]; then
    older="$(printf '%s\n%s\n' "$pch" "$charter_cur" | sort -t. -k1,1n -k2,2n -k3,3n | sed -n 1p)"
    [ "$older" = "$pch" ] && ch_old="$ch_old $role($pch<$charter_cur)"
  fi
done
if [ -n "$pr_bad" ]; then emit falha perfil-resolve "profile.<role>.file não aponta arquivo existente:$pr_bad"
else emit ok perfil-resolve "perfis da ficha resolvem em arquivo"; fi
[ -n "$rev_pend" ] && emit aviso perfil-reviewed "perfil pendente de revisão humana (reviewed: false):$rev_pend"
[ -n "$ch_old" ] && emit aviso perfil-charter "charter do perfil menor que o atual — re-derivar/revisar:$ch_old"

# ---- screenVerify: local.json, gitignore, placeholders, artefatos ----
sv="$(bash "$FICHA_SH" "$ROOT" --screen-verify 2>/dev/null)"
sv_on="$(printf '%s\n' "$sv" | sed -n 's/^enabled=//p')"
sv_dir="$(printf '%s\n' "$sv" | sed -n 's/^artifactsDir=//p')"
sv_method="$(printf '%s\n' "$sv" | sed -n 's/^method=//p')"
if [ "$sv_on" = "true" ]; then
  if [ -f "$ROOT/keelson.local.example.json" ]; then
    if [ "$have_git" = 1 ] && ! git -C "$ROOT" ls-files --error-unmatch keelson.local.example.json >/dev/null 2>&1; then
      emit aviso local-example "keelson.local.example.json existe mas não está versionado"
    else
      emit ok local-example "exemplo presente e versionado"
    fi
  else
    emit aviso local-example "keelson.local.example.json ausente"
  fi
  if [ "$have_git" = 1 ]; then
    if git -C "$ROOT" ls-files --error-unmatch keelson.local.json >/dev/null 2>&1; then
      emit falha local-json-ignorado "keelson.local.json está VERSIONADO — segredo no repositório"
    elif git -C "$ROOT" check-ignore -q keelson.local.json 2>/dev/null; then
      emit ok local-json-ignorado "keelson.local.json coberto pelo .gitignore (check-ignore)"
    else
      emit falha local-json-ignorado "keelson.local.json fora do .gitignore (check-ignore falhou)"
    fi
    art_bad=""
    for d in "$sv_dir" ".playwright-mcp"; do
      [ -n "$d" ] || continue
      git -C "$ROOT" check-ignore -q "$d/x" 2>/dev/null || art_bad="$art_bad $d/"
    done
    if [ -n "$art_bad" ]; then emit falha artefatos-ignorados "não cobertos por git check-ignore:$art_bad"
    else emit ok artefatos-ignorados "artifactsDir e .playwright-mcp/ ignorados (provado)"; fi
  fi
  if [ -f "$ROOT/keelson.local.json" ]; then
    if grep -q '<[a-zA-Z][^>]*>' "$ROOT/keelson.local.json" 2>/dev/null; then
      emit aviso local-placeholder "keelson.local.json com campos em placeholder <...> — preencher (dev-only)"
    else
      emit ok local-placeholder "keelson.local.json sem placeholder"
    fi
  else
    emit aviso local-placeholder "keelson.local.json ausente — rode /keelson:init para criá-lo"
  fi
fi

# ---- flags efetivas do Playwright MCP (método skill:screen-verify) ----
if [ "$sv_method" = "skill:screen-verify" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$ROOT" "$CLAUDEJSON" "$sv_dir" <<'PY' >> "$OUT"
import json, os, sys
root, cjson, artdir = sys.argv[1], sys.argv[2], sys.argv[3]

def load(p):
    try:
        with open(p) as f:
            return json.load(f)
    except Exception:
        return None

entry, scope = None, None
proj = load(os.path.join(root, ".mcp.json"))
if proj and proj.get("mcpServers", {}).get("playwright"):
    entry, scope = proj["mcpServers"]["playwright"], "projeto"
if entry is None:
    cj = load(cjson)
    if cj:
        pj = cj.get("projects", {}).get(root, {}).get("mcpServers", {}).get("playwright")
        if pj:
            entry, scope = pj, "pessoal-projeto"
        elif cj.get("mcpServers", {}).get("playwright"):
            entry, scope = cj["mcpServers"]["playwright"], "global"

if entry is None:
    print("falha\tplaywright-flags\tnenhum mcpServers.playwright em .mcp.json, escopo do projeto ou global")
    sys.exit(0)

args = entry.get("args", []) or []
modo = "headless" if "--headless" in args else "janela"
findings = []
outdir = None
if "--output-dir" in args:
    i = args.index("--output-dir")
    outdir = args[i + 1] if i + 1 < len(args) else None
if artdir and outdir != artdir:
    findings.append("--output-dir %r != artifactsDir %r" % (outdir, artdir))

nrealms = 0
local = load(os.path.join(root, "keelson.local.json"))
if local:
    svl = local.get("screenVerify", {}) or {}
    realms = svl.get("realms")
    nrealms = len(realms) if isinstance(realms, dict) else (1 if svl.get("baseUrl") else 0)
if nrealms >= 2 and "--isolated" not in args:
    findings.append("%d realms sem --isolated (sessao de um realm vaza no outro)" % nrealms)
elif "--isolated" not in args:
    findings.append("sem --isolated (aviso: perfil persistente)")

detail = "escopo=%s modo=%s" % (scope, modo)
if findings:
    hard = [f for f in findings if not f.startswith("sem --isolated (aviso")]
    soft = [f for f in findings if f.startswith("sem --isolated (aviso")]
    if hard:
        print("falha\tplaywright-flags\t%s — %s" % (detail, "; ".join(hard + soft)))
    else:
        print("aviso\tplaywright-flags\t%s — %s" % (detail, "; ".join(soft)))
else:
    print("ok\tplaywright-flags\t%s — flags conferem" % detail)
PY
  else
    emit aviso playwright-flags "sem python3 para ler a config efetiva — confira as flags à mão"
  fi
fi

# ---- jira: campos mínimos preenchidos (sem chamar conector) ----
if [ "$(fget jira.enabled)" = "true" ]; then
  j_bad=""
  [ -n "$(fget jira.projectKey)" ] || j_bad="$j_bad projectKey"
  [ -n "$(fget jira.issueType.spec)" ] || j_bad="$j_bad issueType.spec"
  [ -n "$(fget jira.issueType.task)" ] || j_bad="$j_bad issueType.task"
  if [ -n "$j_bad" ]; then emit falha jira-campos "jira.enabled com campo vazio:$j_bad"
  else emit ok jira-campos "campos mínimos do Jira preenchidos"; fi
fi

# ---- git: bloco de branch coerente (4.190/4.192) — só emite quando o bloco existe ----
g_strat="$(fget git.branchStrategy)"
g_name="$(fget git.branchNaming)"
if [ -n "$g_strat" ] || [ -n "$g_name" ]; then
  g_bad=""
  case "${g_strat:-unica}" in unica|por-fatia) : ;; *) g_bad="$g_bad branchStrategy(${g_strat})" ;; esac
  case "${g_name:-slug}" in slug|tracker-key) : ;; *) g_bad="$g_bad branchNaming(${g_name})" ;; esac
  if [ "$g_name" = "tracker-key" ] && [ "$(fget jira.enabled)" != "true" ]; then
    g_bad="$g_bad tracker-key-sem-jira(naming exige jira.enabled true — sem key a branch cai sempre no fallback)"
  fi
  if [ -n "$g_bad" ]; then emit falha git-branch-config "bloco git incoerente:$g_bad"
  else emit ok git-branch-config "estratégia e naming de branch coerentes"; fi
fi

# ---- models: chave aponta agent real do pacote, alias conhecido (4.272) — só emite quando o bloco existe ----
m_obj="$(fget models)"
if [ -n "$m_obj" ] && [ "$m_obj" != "{}" ]; then
  if command -v python3 >/dev/null 2>&1; then
    m_pairs="$(python3 - "$ROOT/keelson.config.json" <<'PY' 2>/dev/null
import json, sys
try:
    with open(sys.argv[1]) as f:
        m = json.load(f).get("models") or {}
except Exception:
    sys.exit(0)
for k, v in m.items():
    print("%s=%s" % (k, v))
PY
)"
    m_bad=""; m_warn=""; m_n=0
    for m_pair in $m_pairs; do
      m_k="${m_pair%%=*}"; m_v="${m_pair#*=}"
      m_n=$((m_n + 1))
      [ -f "$PLUGROOT/agents/$m_k.md" ] || m_bad="$m_bad $m_k"
      case "$m_v" in opus|sonnet|haiku) : ;; *) m_warn="$m_warn $m_pair" ;; esac
    done
    if [ -n "$m_bad" ]; then emit falha models-validos "agent desconhecido no elenco do plugin:$m_bad"
    elif [ -n "$m_warn" ]; then emit aviso models-validos "alias fora do conjunto conhecido (opus/sonnet/haiku):$m_warn — confira no harness"
    else emit ok models-validos "desvios de modelo apontam agents do pacote: $m_n"; fi
  else
    emit aviso models-validos "sem python3 para validar o bloco models — confira à mão"
  fi
fi

sort "$OUT"
if grep -q '^falha' "$OUT"; then exit 1; fi
exit 0
