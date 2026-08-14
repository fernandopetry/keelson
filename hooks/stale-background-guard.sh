#!/usr/bin/env bash
# stale-background-guard — hook Stop que cutuca quando há processo de SEGUNDO PLANO
# parado no tempo, para o agente decidir se ele está trabalhando ou travado.
#
# Por que existe: é comum um agente deixar loops de sondagem (`until ...; do sleep N; done`)
# rodando com condição de saída que nunca se satisfaz — sondando um arquivo/estado que não
# tem o registro esperado. Eles giram até o fim da sessão mesmo com o trabalho já concluído,
# e um `2>/dev/null` na condição apaga a evidência. Ninguém percebe até horas depois.
#
# O que este guard NÃO é: um lembrete de "não faça polling". Essa instrução já existe (a doc
# do Bash tool desaconselha sondar trabalho rastreado pelo harness, que notifica sozinho) e
# costuma ser ignorada. Prosa nova seria a defesa mais fraca possível. Este guard é um
# DETECTOR: pega a classe do erro (processo que não termina) independente da causa.
#
# Política de fail-closed: se não conseguir inspecionar os processos, ele CUTUCA dizendo que
# não conseguiu — "não consegui checar" nunca vira "está tudo certo". O custo de um falso
# positivo é um round-trip; o de um falso negativo é horas de CPU e a impressão de que havia
# trabalho acontecendo quando não havia.
#
# Agnóstico de projeto: não lê a ficha nem depende de stack. O alvo é filtrado em dois
# estágios: (1) a marca do Bash tool do Claude Code no comando — separa processo de agente
# de qualquer outra coisa da máquina do humano — e (2) atribuição de dono por ancestralidade
# de PPIDs (decisão 4.206): só é ignorado o processo cuja cadeia leva PROVADAMENTE ao
# processo `claude` de OUTRA sessão viva; cadeia órfã ou indeterminada continua acusando
# (fail-closed — indeterminado nunca vira "de outra sessão").
# stop_hook_active evita loop: cutuca uma vez por encerramento.

set -euo pipefail

input="$(cat)"

active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null || echo False)"
if [ "$active" = "True" ]; then
  exit 0
fi

python3 <<'PY'
import json
import os
import re
import subprocess
import sys

# Minutos a partir dos quais um processo de segundo plano merece um olhar. Calibrado para
# nao gritar de trabalho legitimo curto (suites de teste, builds costumam durar segundos a
# poucos minutos). Dev servers de longa duracao normalmente nao sao lancados via Bash tool.
THRESHOLD_MIN = 10

# Marca do shell que o Bash tool do Claude Code cria. E o que separa "processo de agente"
# de qualquer outra coisa da maquina do humano. A marca sozinha e GLOBAL da maquina — com
# sessoes paralelas ela casa processo de todas; o dono e decidido pela ancestralidade abaixo.
CLAUDE_SHELL_MARK = "shell-snapshots/snapshot-"

# Reconhece o processo de uma sessao claude na tabela: argv0 (ou caminho) terminando no
# binario `claude` seguido de espaco/fim. Nao casa `claude-code/`, `.claude/` nem os
# binarios do app desktop (`.../MacOS/Claude`, capitalizado).
CLAUDE_PROC_RE = re.compile(r"(^|/)claude(\s|$)")

# Teto de saltos ao subir a cadeia de PPIDs — protege contra tabela corrompida/ciclica.
MAX_SALTOS = 64


def bloqueia(reason: str) -> None:
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)


def etime_para_segundos(etime: str) -> int | None:
    """Converte o ELAPSED do ps ([[dd-]hh:]mm:ss) em segundos.

    O ps do macOS NAO suporta a coluna `etimes` (segundos prontos) — ele ignora a coluna
    em silencio e devolve outra coisa, entao parsear `etime` e obrigatorio aqui.
    """
    etime = etime.strip()
    if not re.fullmatch(r"(\d+-)?(\d+:)?\d+:\d+", etime):
        return None

    dias = 0
    if "-" in etime:
        d, etime = etime.split("-", 1)
        dias = int(d)

    partes = [int(p) for p in etime.split(":")]
    if len(partes) == 2:
        h, m, s = 0, partes[0], partes[1]
    else:
        h, m, s = partes

    return dias * 86400 + h * 3600 + m * 60 + s


try:
    saida = subprocess.run(
        ["ps", "-eo", "pid,ppid,etime,command"],
        capture_output=True, text=True, timeout=10, check=True,
    ).stdout
except Exception as e:
    # Fail-closed: nao conseguir checar NAO e o mesmo que estar limpo.
    bloqueia(
        "Guarda de segundo plano: NAO consegui inspecionar os processos "
        f"({type(e).__name__}: {e}).\n\n"
        "Isto nao significa que esta tudo certo — significa que a verificacao nao rodou. "
        "Confira a mao se ha processo de segundo plano seu ainda vivo (ex.: "
        "`ps -eo pid,ppid,etime,command | grep shell-snapshots`) e mate o que nao estiver "
        "trabalhando de verdade, antes de encerrar."
    )

# Uma passada monta a tabela inteira em memoria: as cadeias de PPID sao resolvidas sem
# nenhuma chamada adicional de `ps`.
ppid_de: dict[int, int] = {}
cmd_de: dict[int, str] = {}
linhas_ps = []

for linha in saida.splitlines()[1:]:
    m = re.match(r"\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*)", linha)
    if not m:
        continue
    pid, ppid, etime, cmd = int(m.group(1)), int(m.group(2)), m.group(3), m.group(4)
    ppid_de[pid] = ppid
    cmd_de[pid] = cmd
    linhas_ps.append((pid, etime, cmd))

if not linhas_ps:
    # Parser que nao casa NENHUMA linha e falha de inspecao (ex.: colunas reordenadas
    # numa plataforma nova), nunca "esta tudo limpo".
    bloqueia(
        "Guarda de segundo plano: a saida do `ps` nao casou o formato esperado "
        "(pid,ppid,etime,command) — a verificacao NAO rodou.\n\n"
        "Confira a mao: `ps -eo pid,ppid,etime,command | grep shell-snapshots`."
    )


def ancestrais(pid: int) -> list[int]:
    cadeia, visto = [], set()
    atual = ppid_de.get(pid)
    while atual is not None and atual > 1 and atual not in visto and len(cadeia) < MAX_SALTOS:
        cadeia.append(atual)
        visto.add(atual)
        atual = ppid_de.get(atual)
    return cadeia


# Raiz da MINHA sessao: o primeiro ancestral do proprio hook que e um processo claude.
# O hook roda como filho do claude que o disparou, entao a cadeia passa por ele.
# (Env var: costura de teste da suite scripts/tests/stale-bg/ — nunca setada em uso real.)
meu_pid = int(os.environ.get("KEELSON_STALE_GUARD_SELF_PID", os.getpid()))
raiz_da_sessao = next(
    (a for a in ancestrais(meu_pid) if CLAUDE_PROC_RE.search(cmd_de.get(a, ""))),
    None,
)

suspeitos = []
ignorados_outra_sessao = 0

for pid, etime, cmd in linhas_ps:
    if pid == meu_pid or CLAUDE_SHELL_MARK not in cmd:
        continue
    # O proprio hook e seus filhos casam a marca, mas vivem segundos — o limiar os exclui.

    segundos = etime_para_segundos(etime)
    if segundos is None or segundos < THRESHOLD_MIN * 60:
        continue

    # Dono por ancestralidade. So ha prova de "outra sessao" quando (a) a raiz da minha
    # foi identificada e (b) a cadeia do candidato passa por ALGUM claude que nao e ela.
    # Sem raiz identificada, ou com cadeia orfa (reparentada ao init quando o shell pai
    # morre — o caso classico do proprio incidente), o dono e indeterminado e o processo
    # CONTINUA no laudo: indeterminado nunca vira "de outra sessao".
    anc = ancestrais(pid)
    if raiz_da_sessao is not None and raiz_da_sessao not in anc:
        if any(CLAUDE_PROC_RE.search(cmd_de.get(a, "")) for a in anc):
            ignorados_outra_sessao += 1
            continue
        dono = "indeterminado"
    elif raiz_da_sessao is None:
        dono = "indeterminado"
    else:
        dono = "meu"

    # `sleep` no comando = cheiro de loop de sondagem. E a forma exata do incidente que
    # originou este guard, e a doc do Bash tool desaconselha explicitamente.
    sondagem = re.search(r"\bsleep\s+\d", cmd) is not None

    suspeitos.append({
        "pid": pid,
        "etime": etime,
        "minutos": segundos // 60,
        "sondagem": sondagem,
        "dono": dono,
        "cmd": re.sub(r"\s+", " ", cmd)[:160],
    })

if not suspeitos:
    sys.exit(0)

suspeitos.sort(key=lambda s: -s["minutos"])

linhas = []
for s in suspeitos:
    marca = " ⟵ CHEIRO DE LOOP DE SONDAGEM" if s["sondagem"] else ""
    dono = " · dono INDETERMINADO (cadeia orfa — pode ser seu)" if s["dono"] == "indeterminado" else ""
    linhas.append(f"  PID {s['pid']} · vivo há {s['etime']}{dono}{marca}\n    {s['cmd']}")

tem_sondagem = any(s["sondagem"] for s in suspeitos)

nota_outras = (
    f" (outros {ignorados_outra_sessao} pertencem a outra(s) sessao(oes) claude viva(s) "
    "e foram ignorados)" if ignorados_outra_sessao else ""
)

reason = (
    f"Guarda de segundo plano: {len(suspeitos)} processo(s) atribuivel(is) a ESTA sessao "
    f"estao vivos ha mais de {THRESHOLD_MIN} minutos{nota_outras}.\n\n"
    + "\n".join(linhas)
    + "\n\nAntes de encerrar, decida por cada um — nao presuma que trabalho longo e "
    "trabalho acontecendo:\n"
    "- Esta MESMO trabalhando? Prove: veja o output crescer (`Read` no arquivo de output) "
    "ou o efeito no alvo. Idade nao e prova de progresso.\n"
    "- Terminou e ninguem percebeu? Mate-o.\n"
    "- Nao consegue dizer qual dos dois? Trate como travado e mate: o custo de matar algo "
    "vivo e refazer; o de deixar um zumbi e voce achar que ha trabalho em curso quando nao ha.\n"
)

if tem_sondagem:
    reason += (
        "\nUM OU MAIS PARECEM LOOP DE SONDAGEM (`sleep` em laco). Antes de esperar mais:\n"
        "- Trabalho rastreado pelo harness (subagente, comando em background) JA notifica "
        "sozinho quando termina — sondar nao adianta nada e a doc do Bash tool desaconselha.\n"
        "- Se ainda assim for sondar algo externo (CI, deploy), TESTE a condicao de saida "
        "uma vez antes de entrar no laco. Um incidente tipico e um "
        "`until [ -n \"$(jq ... 'select(.type==\"result\")' ...)\" ]` sobre um arquivo que "
        "NAO TEM esse registro: condicao insatisfazivel, laco eterno.\n"
        "- Nunca `2>/dev/null` na condicao de saida: e o que apaga a evidencia do laco preso."
    )

bloqueia(reason)
PY

exit 0
