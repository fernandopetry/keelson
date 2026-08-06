#!/usr/bin/env bash
# probe-env.sh — sondagem mecânica de ambiente do gate 9 (decisões 4.26/4.49/4.71/4.154).
# "Indisponibilidade se prova, não se presume": este script executa a sondagem barata e
# devolve a CAUSA NOMEADA + a evidência literal (o que tentou, o que retornou) — o
# insumo do `evidencia_indisponibilidade`/`sonda:` do handoff-protocol §8.1.
# As causas que dependem de MCP vivo (runtime de browser, permissão de ambiente)
# continuam do qa — este script cobre credencial e app.
#
# Uso: probe-env.sh <raiz-do-projeto> [--realm <nome>] [--boot] [--boot-wait <s>]
#                   [--timeout <s>]
#
#   --realm      realm alvo do keelson.local.json (default: defaultRealm, ou o único,
#                ou o flat legado como realm implícito "default")
#   --boot       com a sondagem falhando e `quality.boot` declarado na ficha, executa
#                o boot, aguarda --boot-wait (default 5s) e re-sonda 1× (4.71)
#   --timeout    timeout do probe HTTP em segundos (default 5)
#
# Saída (campo=valor, uma por linha): realm= · baseUrl= · probe=<http_code|falha> ·
#   causa=<ok|app_fora_do_ar|credencial_ausente|credencial_placeholder> · evidencia=…
#   (múltiplas linhas evidencia= — literais, prontas para o registro; senha NUNCA sai).
# Exit: 0 ambiente de pé · 1 indisponível (causa nomeada) · 2 uso incorreto ·
#       3 degradado (sem python3/curl — o qa sonda à mão e declara).
#
# Bash 3.2-compatível. Read-only sobre o repo (o --boot executa o comando da ficha).

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
die3() { echo "probe-env degradado: $*" >&2; exit 3; }
usage() { sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
FICHA_SH="$HERE/ficha.sh"

ROOT=""
REALM=""
DO_BOOT=0
BOOT_WAIT=5
TIMEOUT=5

while [ $# -gt 0 ]; do
  case "$1" in
    --realm)     shift; [ $# -gt 0 ] || die2 "--realm exige um nome."; REALM="$1" ;;
    --boot)      DO_BOOT=1 ;;
    --boot-wait) shift; [ $# -gt 0 ] || die2 "--boot-wait exige segundos."; BOOT_WAIT="$1" ;;
    --timeout)   shift; [ $# -gt 0 ] || die2 "--timeout exige segundos."; TIMEOUT="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1" ;;
    *) [ -z "$ROOT" ] || die2 "apenas uma raiz por vez."; ROOT="$1" ;;
  esac
  shift
done
[ -n "$ROOT" ] || { usage >&2; exit 2; }
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"

command -v python3 >/dev/null 2>&1 || die3 "sem python3 para ler keelson.local.json"
command -v curl >/dev/null 2>&1 || die3 "sem curl para o probe HTTP"

LOCALJ="$ROOT/keelson.local.json"
if [ ! -f "$LOCALJ" ]; then
  printf 'realm=%s\nbaseUrl=\nprobe=\ncausa=credencial_ausente\nevidencia=keelson.local.json ausente em %s — rode /keelson:init ou preencha o arquivo; nunca chute credencial\n' "${REALM:-}" "$ROOT"
  exit 1
fi

# resolve realm + campos (senha nunca é impressa: só presença/placeholder)
info="$(python3 - "$LOCALJ" "$REALM" <<'PY'
import json, sys
path, want = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except Exception as e:
    print("PARSE\t%s" % e)
    sys.exit(0)
sv = data.get("screenVerify", {}) or {}
realms = sv.get("realms")
if not isinstance(realms, dict) or not realms:
    # formato flat legado: baseUrl + login direto sob screenVerify = realm implícito
    if sv.get("baseUrl") or sv.get("login"):
        realms = {"default": sv}
    else:
        print("SEMREALM\t-")
        sys.exit(0)
name = want or sv.get("defaultRealm") or (list(realms)[0] if len(realms) == 1 else "")
if not name:
    print("AMBIGUO\t%s" % ", ".join(sorted(realms)))
    sys.exit(0)
if name not in realms:
    print("NAOEXISTE\t%s\t%s" % (name, ", ".join(sorted(realms))))
    sys.exit(0)
r = realms[name] or {}
login = r.get("login", {}) or {}
def flag(v):
    if v is None or v == "":
        return "vazio"
    if isinstance(v, str) and v.startswith("<") and v.endswith(">"):
        return "placeholder"
    return "ok"
print("OK\t%s\t%s\t%s\t%s\t%s" % (
    name, r.get("baseUrl") or "",
    flag(r.get("baseUrl")), flag(login.get("username")), flag(login.get("password"))))
PY
)"

kind="${info%%	*}"
case "$kind" in
  PARSE)
    printf 'realm=%s\nbaseUrl=\nprobe=\ncausa=credencial_ausente\nevidencia=keelson.local.json ilegível: %s\n' "${REALM:-}" "${info#*	}"
    exit 1 ;;
  SEMREALM)
    printf 'realm=%s\nbaseUrl=\nprobe=\ncausa=credencial_ausente\nevidencia=keelson.local.json sem screenVerify.realms nem formato flat — rode /keelson:init\n' "${REALM:-}"
    exit 1 ;;
  AMBIGUO)
    printf 'realm=\nbaseUrl=\nprobe=\ncausa=credencial_ausente\nevidencia=vários realms sem defaultRealm e sem --realm: %s\n' "${info#*	}"
    exit 1 ;;
  NAOEXISTE)
    rest="${info#*	}"; nome="${rest%%	*}"; lista="${rest#*	}"
    printf 'realm=%s\nbaseUrl=\nprobe=\ncausa=credencial_ausente\nevidencia=realm "%s" não existe no keelson.local.json (existem: %s)\n' "$nome" "$nome" "$lista"
    exit 1 ;;
  OK) ;;
  *) die3 "resposta inesperada do leitor: $kind" ;;
esac

rest="${info#OK	}"
rname="${rest%%	*}"; rest="${rest#*	}"
burl="${rest%%	*}"; rest="${rest#*	}"
f_url="${rest%%	*}"; rest="${rest#*	}"
f_user="${rest%%	*}"
f_pass="${rest##*	}"

printf 'realm=%s\n' "$rname"
printf 'baseUrl=%s\n' "$burl"

bad=""
[ "$f_url" = "ok" ]  || bad="$bad baseUrl($f_url)"
[ "$f_user" = "ok" ] || bad="$bad login.username($f_user)"
[ "$f_pass" = "ok" ] || bad="$bad login.password($f_pass)"
if [ -n "$bad" ]; then
  printf 'probe=\ncausa=credencial_placeholder\nevidencia=campos do realm "%s" em branco/placeholder:%s — preencher o keelson.local.json (dev-only); nunca chute credencial\n' "$rname" "$bad"
  exit 1
fi

probe() { # ecoa "code" ou "falha<TAB>motivo"
  err="$(curl -sS -o /dev/null -m "$TIMEOUT" -w '%{http_code}' "$burl" 2>&1)"
  st=$?
  if [ $st -eq 0 ]; then
    printf '%s\n' "$err"
  else
    printf 'falha\t%s\n' "$(printf '%s' "$err" | tr '\n' ' ' | sed 's/[0-9]*$//;s/[ \t]*$//')"
  fi
}

r1="$(probe)"
case "$r1" in
  falha*)
    motivo="${r1#falha	}"
    if [ "$DO_BOOT" = 1 ]; then
      bootcmd="$(bash "$FICHA_SH" "$ROOT" --get quality.boot 2>/dev/null || true)"
      if [ -n "$bootcmd" ]; then
        bout="$( (cd "$ROOT" && eval "$bootcmd") 2>&1 | tail -3 | tr '\n' ' ' )"
        sleep "$BOOT_WAIT"
        r2="$(probe)"
        case "$r2" in
          falha*)
            printf 'probe=falha\ncausa=app_fora_do_ar\nevidencia=curl -m %s %s → %s\nevidencia=boot tentado (4.71): `%s` → %s\nevidencia=re-sondagem após %ss → %s\n' \
              "$TIMEOUT" "$burl" "$motivo" "$bootcmd" "${bout:-sem saída}" "$BOOT_WAIT" "${r2#falha	}"
            exit 1 ;;
          *)
            printf 'probe=%s\ncausa=ok\nevidencia=fora do ar no 1º probe (%s); boot `%s` subiu a app — re-sondagem HTTP %s\n' "$r2" "$motivo" "$bootcmd" "$r2"
            exit 0 ;;
        esac
      else
        printf 'probe=falha\ncausa=app_fora_do_ar\nevidencia=curl -m %s %s → %s\nevidencia=quality.boot: null/ausente na ficha — a app não sobe por comando deste repo; a sondagem que falhou basta (4.71)\n' \
          "$TIMEOUT" "$burl" "$motivo"
        exit 1
      fi
    fi
    printf 'probe=falha\ncausa=app_fora_do_ar\nevidencia=curl -m %s %s → %s\n' "$TIMEOUT" "$burl" "$motivo"
    exit 1 ;;
  *)
    printf 'probe=%s\ncausa=ok\nevidencia=curl -m %s %s → HTTP %s\n' "$r1" "$TIMEOUT" "$burl" "$r1"
    exit 0 ;;
esac
