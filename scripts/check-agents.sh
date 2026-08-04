#!/usr/bin/env bash
# check-agents.sh — paridade MCP dos agents (decisão 4.105).
#
# O que a doutrina exige e este script prova: todo servidor MCP citado no CORPO de um
# agent (`mcp__<server>__…`) está concedido na lista `tools:` do próprio frontmatter —
# como servidor (`mcp__<server>`), wildcard (`mcp__<server>__*`) ou ferramenta
# específica. Subagent com `tools:` explícito nunca herda ferramenta fora da lista
# (nem MCP, mesmo que a sessão despachante as tenha): corpo que instrui usar um MCP
# não concedido é papel estruturalmente incapaz do próprio trabalho — o gate degrada
# em TODA invocação, independente do ambiente.
#
# Agent SEM linha `tools:` herda tudo → nada a conferir. Limite honesto: skills que o
# agent invoca não são varridas (o mapeamento agent→skill não é mecânico); o caso real
# que motivou o check vivia no próprio corpo do agent.
#
# Uso: check-agents.sh [--agents-dir <dir>]   (default: agents/ na raiz do repo git)
# Exit: 0 tudo certo · 1 violações · 2 uso incorreto.
# Bash 3.2-compatível, POSIX grep/sed/awk, read-only.

set -u
LC_ALL=C
export LC_ALL

DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agents-dir) shift; [ $# -gt 0 ] || { echo "ERRO: --agents-dir exige um caminho." >&2; exit 2; }; DIR="$1" ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$DIR" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || { echo "ERRO: fora de um repo git e sem --agents-dir." >&2; exit 2; }
  DIR="$ROOT/agents"
fi
[ -d "$DIR" ] || { echo "ERRO: diretório de agents não existe: $DIR" >&2; exit 2; }

fails=0
checked=0

# extrai tokens mcp__… de stdin e reduz cada um ao nome do servidor
servers() { grep -oE 'mcp__[A-Za-z0-9_-]+' 2>/dev/null | sed -e 's/^mcp__//' -e 's/__.*$//' | sort -u; }

for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  checked=$((checked + 1))

  # frontmatter = do primeiro '---' ao seguinte; corpo = o resto do arquivo
  fm="$(awk 'NR==1 && $0=="---" {infm=1; next} infm && $0=="---" {exit} infm {print}' "$f")"
  tools_line="$(printf '%s\n' "$fm" | grep '^tools:' | head -1)"

  # sem `tools:` explícito → herda tudo (inclusive MCP), nada a conferir
  [ -n "$tools_line" ] || continue

  body="$(awk 'NR==1 && $0=="---" {infm=1; next} infm && $0=="---" {infm=0; body=1; next} body {print}' "$f")"
  cited="$(printf '%s\n' "$body" | servers)"
  [ -n "$cited" ] || continue

  granted="$(printf '%s\n' "$tools_line" | servers)"

  for s in $cited; do
    if ! printf '%s\n' "$granted" | grep -qx "$s"; then
      line="$(grep -n "mcp__${s}" "$f" | head -1 | cut -d: -f1)"
      echo "FALHA: $(basename "$f"): corpo cita mcp__${s}__… (linha ${line:-?}) sem grant em tools: — acrescente mcp__${s}__* (ou a ferramenta específica) ao frontmatter"
      fails=$((fails + 1))
    fi
  done
done

[ "$checked" -gt 0 ] || { echo "ERRO: nenhum agent .md em $DIR" >&2; exit 2; }

if [ "$fails" -gt 0 ]; then
  echo "check-agents: $fails violação(ões) em $checked agent(s)."
  exit 1
fi
echo "check-agents: paridade MCP ok em $checked agent(s)."
exit 0
