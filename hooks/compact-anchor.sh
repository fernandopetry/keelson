#!/usr/bin/env bash
# compact-anchor — hook SessionStart (matcher: compact) que re-ancora a sessão
# nos fatos do disco logo após uma compactação de contexto (decisão 4.146).
#
# Por que existe: a sumarização comprime exatamente o detalhe de orquestração que
# ainda não virou artefato (wave em andamento, gates pendentes, onde retomar). O
# keelson já persiste o estado fora do contexto (run-state, ledger, artefatos SDD);
# o que faltava era a ponte de volta: no primeiro instante pós-compactação, este
# hook lê o disco e reinjeta os fatos como contexto — a sessão re-ancora no que
# está escrito, em vez de confiar no resumo.
#
# O que este hook NÃO faz: decidir nada, bloquear nada. É só um espelho do disco.
# Sem run em andamento e sem ledger → silêncio (exit 0, sem output).
#
# Fallback gracioso (doutrina dos hooks): sem python3, sem cwd, sem arquivo →
# exit 0, nunca trava o fluxo. Bash 3.2-compatível.

set -u

input="$(cat)"

# SessionStart com source=compact — defensivo caso o matcher mude
source_ev="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("source", ""))' 2>/dev/null || echo "")"
[ "$source_ev" = "compact" ] || exit 0

cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null || echo "")"
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
  exit 0
fi

runs=""
n=0
for f in "$cwd"/thoughts/local/run-state-*.md; do
  [ -f "$f" ] || continue
  grep -q '^status: em_andamento' "$f" 2>/dev/null || continue
  n=$((n + 1))
  campos="$(grep -E '^(slug|plan|waves_concluidas|waves_total|retomada):' "$f" 2>/dev/null | sed 's/^/    /' || true)"
  runs="${runs}
— ${f#"$cwd"/}:
${campos}"
done

ledger_line=""
if [ -d "$cwd/thoughts/local/session-ledger" ]; then
  # conta só eventos ativos (a raiz da pasta), não os já consumidos em reported-*/
  ev=$(find "$cwd/thoughts/local/session-ledger" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "${ev:-0}" -gt 0 ] 2>/dev/null; then
    ledger_line="Ledger de sessão: ${ev} evento(s) ativo(s) em thoughts/local/session-ledger/ — o report lê a pasta, não a memória."
  fi
fi

# nada em andamento e nada no ledger → nenhum contexto a injetar
if [ "$n" -eq 0 ] && [ -z "$ledger_line" ]; then
  exit 0
fi

echo "[keelson compact-anchor] Contexto recém-compactado — fatos do disco (imunes à sumarização, decisão 4.146):"
if [ "$n" -gt 0 ]; then
  printf '%s\n' "Run keelson EM ANDAMENTO:${runs}"
  echo "Antes do próximo despacho, releia os artefatos apontados em 'retomada' (INDEX do slug + TASK-INDEX) — estado de wave, gates pendentes e pendências do Diretor se re-derivam do disco, nunca do resumo comprimido."
fi
[ -n "$ledger_line" ] && echo "$ledger_line"

exit 0
