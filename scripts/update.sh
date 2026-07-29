#!/usr/bin/env bash
# update.sh — atualiza o plugin keelson instalado, via CLI do Claude Code
# (decisão 4.57). Invocado pelo /keelson:update; rodável também à mão.
#
# Uso: update.sh [--scope user|project|local]
#
# Passos: refresh do marketplace E update do plugin — nesta ordem, porque
# atualizar só o marketplace NÃO atualiza o plugin instalado (README, Install).
# A versão antes/depois vem da ficha de plugins da CLI
# (~/.claude/plugins/installed_plugins.json, via jq, selecionada pelo scope);
# sem jq, cai para o parse best-effort de `claude plugin list`.
# O que NÃO faz: recarregar a sessão — o update só vale após reiniciar a
# sessão do Claude Code, e o script termina dizendo exatamente isso.
#
# Bash 3.2-compatível. Diferente dos hooks, aqui falhar alto é o correto:
# o humano invocou pedindo o update — CLI ausente, plugin não instalado ou
# update falho é erro nomeado (exit 1), nunca silêncio.

set -u

PLUGIN="keelson"
MARKETPLACE="keelson"
PLUGIN_ID="${PLUGIN}@${MARKETPLACE}"
INSTALLED_JSON="${HOME}/.claude/plugins/installed_plugins.json"

SCOPE="user"
if [ "${1:-}" = "--scope" ] && [ -n "${2:-}" ]; then
  SCOPE="$2"
fi

# Leitura confiável (ficha + jq, filtrada pelo scope) ou fallback best-effort
# (parse de `claude plugin list`). Nunca aborta: erro de leitura → vazio.
can_read_ficha() {
  [ -f "$INSTALLED_JSON" ] && command -v jq >/dev/null 2>&1
}

installed_version() {
  if can_read_ficha; then
    jq -r --arg id "$PLUGIN_ID" --arg scope "$SCOPE" \
      '(.plugins[$id] // []) | map(select(.scope == $scope)) | (.[0].version // "")' \
      "$INSTALLED_JSON" 2>/dev/null || true
  else
    claude plugin list 2>/dev/null \
      | awk -v id="$PLUGIN_ID" '$0 ~ id {found=1; next} found && /Version:/ {print $2; exit}' \
      || true
  fi
}

if ! command -v claude >/dev/null 2>&1; then
  echo "ERRO: CLI 'claude' nao encontrada no PATH — impossivel atualizar o plugin." >&2
  echo "Garanta a CLI do Claude Code no PATH e rode de novo: /keelson:update" >&2
  exit 1
fi

BEFORE="$(installed_version)"

# Gate "não instalado": só quando a leitura é confiável — no fallback, vazio
# significa "não sei ler", não "não instalado", e o update segue best-effort.
if [ -z "$BEFORE" ] && can_read_ficha; then
  echo "ERRO: plugin '$PLUGIN_ID' nao esta instalado no scope '$SCOPE'." >&2
  echo "Instale com: claude plugin install $PLUGIN_ID" >&2
  echo "(ja instalado? confira o scope real com 'claude plugin list' e repasse via --scope)" >&2
  exit 1
fi

if [ -n "$BEFORE" ]; then
  echo "keelson instalado: $BEFORE (scope $SCOPE)"
fi

echo "==> claude plugin marketplace update $MARKETPLACE"
if ! claude plugin marketplace update "$MARKETPLACE"; then
  echo "ERRO: refresh do marketplace falhou — sem ele o update usaria o cache velho" >&2
  echo "e reportaria 'ja atualizado' sem estar. Veja a saida acima (rede? git?)." >&2
  exit 1
fi

echo "==> claude plugin update $PLUGIN_ID --scope $SCOPE"
if ! claude plugin update "$PLUGIN_ID" --scope "$SCOPE"; then
  echo "ERRO: 'claude plugin update $PLUGIN_ID' falhou — veja a saida acima." >&2
  echo "Causas tipicas: plugin nao instalado via marketplace neste scope" >&2
  echo "(tente --scope project|local) ou instalacao de desenvolvimento (skills-dir)." >&2
  exit 1
fi

AFTER="$(installed_version)"

echo ""
if [ -n "$BEFORE" ] && [ "$AFTER" = "$BEFORE" ]; then
  echo "keelson ja estava na ultima versao publicada ($BEFORE). Nada a fazer."
elif [ -n "$AFTER" ]; then
  echo "keelson atualizado: ${BEFORE:-?} -> $AFTER"
  echo "A sessao corrente continua na versao antiga — reinicie a sessao do"
  echo "Claude Code para carregar a versao nova."
else
  echo "Update aplicado (versao nao exibida — ficha/jq indisponiveis)."
  echo "A sessao corrente continua na versao antiga — reinicie a sessao do"
  echo "Claude Code para carregar a versao nova."
fi
