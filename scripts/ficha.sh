#!/usr/bin/env bash
# ficha.sh — leitor único da ficha keelson.config.json (decisão 4.151).
#
# Uso: ficha.sh [<raiz-do-projeto>] --get <chave.pontuada> [--default <valor>]
#      ficha.sh [<raiz-do-projeto>] --resolve-profile <role> [--plugin-root <dir>]
#      ficha.sh [<raiz-do-projeto>] --screen-verify
#
#   <raiz-do-projeto>   diretório com keelson.config.json (default: cwd)
#   --get               imprime o valor da chave: escalar cru; boolean true/false;
#                       null/ausente → vazio (ou --default); array → um item por linha;
#                       objeto → JSON compacto
#   --resolve-profile   imprime o caminho resolvido de profile.<role>.file:
#                       prefixo "plugin:" → <plugin-root>/guidelines/<resto>
#                       (--plugin-root ou $CLAUDE_PLUGIN_ROOT); caminho simples →
#                       <raiz>/<caminho>; campo ausente/null → vazio (o fallback
#                       doutrinário — exemplar da mesma lang — é do chamador)
#   --screen-verify     normaliza gates.screenVerify (inclusive o atalho booleano
#                       legado true/false) em 3 linhas: enabled=… method=… artifactsDir=…
#
# Exit: 0 ok (chave ausente é vazio, não erro) · 2 uso incorreto ·
#       3 degradado com causa nomeada em stderr (ficha ausente/ilegível, JSON inválido,
#       sem python3 nem jq, plugin-root indisponível) — o chamador volta ao raciocínio
#       próprio e DECLARA a degradação (mesma régua do graph-contract §5).
#
# Bash 3.2-compatível; parser: python3 (preferência — mesmo runtime dos hooks) com
# fallback jq; sem dependências novas. Read-only.

set -u
LC_ALL=C
export LC_ALL

die2() { echo "ERRO: $*" >&2; exit 2; }
die3() { echo "ficha.sh degradado: $*" >&2; exit 3; }
usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; }

ROOT=""
ACTION=""
KEY=""
DEFAULT_SET=0
DEFAULT_VAL=""
ROLE=""
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --get)
      [ -z "$ACTION" ] || die2 "use apenas uma ação (--get, --resolve-profile ou --screen-verify)."
      shift; [ $# -gt 0 ] || die2 "--get exige a chave (ex.: quality.test)."
      ACTION="get"; KEY="$1" ;;
    --default)
      shift; [ $# -gt 0 ] || die2 "--default exige um valor."
      DEFAULT_SET=1; DEFAULT_VAL="$1" ;;
    --resolve-profile)
      [ -z "$ACTION" ] || die2 "use apenas uma ação (--get, --resolve-profile ou --screen-verify)."
      shift; [ $# -gt 0 ] || die2 "--resolve-profile exige o role (ex.: backend)."
      ACTION="profile"; ROLE="$1" ;;
    --plugin-root)
      shift; [ $# -gt 0 ] || die2 "--plugin-root exige um diretório."
      PLUGIN_ROOT="$1" ;;
    --screen-verify)
      [ -z "$ACTION" ] || die2 "use apenas uma ação (--get, --resolve-profile ou --screen-verify)."
      ACTION="screen" ;;
    -h|--help) usage; exit 0 ;;
    -*) die2 "opção desconhecida: $1 (use --help)" ;;
    *)
      [ -z "$ROOT" ] || die2 "apenas uma raiz de projeto por vez."
      ROOT="$1" ;;
  esac
  shift
done

[ -n "$ACTION" ] || { usage >&2; exit 2; }
[ -n "$ROOT" ] || ROOT="$PWD"
[ -d "$ROOT" ] || die2 "raiz não existe: $ROOT"

FICHA="$ROOT/keelson.config.json"
[ -f "$FICHA" ] || die3 "ficha ausente: $FICHA"
[ -r "$FICHA" ] || die3 "ficha ilegível: $FICHA"

# ---- extração de valor por chave pontuada, num único parser ----
# Saída canônica do extrator (consumida abaixo): 1ª linha é o tipo
# (absent|null|scalar|bool|array|object), demais linhas o valor.
extract() { # $1 = chave pontuada
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$FICHA" "$1" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
except Exception as e:
    print("invalid: %s" % e, file=sys.stderr)
    sys.exit(3)
cur = data
for part in sys.argv[2].split("."):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        print("absent")
        sys.exit(0)
if cur is None:
    print("null")
elif isinstance(cur, bool):
    print("bool"); print("true" if cur else "false")
elif isinstance(cur, (int, float, str)):
    print("scalar"); print(cur)
elif isinstance(cur, list):
    print("array")
    for item in cur:
        if isinstance(item, (dict, list)):
            print(json.dumps(item, separators=(",", ":"), ensure_ascii=False))
        elif isinstance(item, bool):
            print("true" if item else "false")
        elif item is None:
            print("")
        else:
            print(item)
else:
    print("object"); print(json.dumps(cur, separators=(",", ":"), ensure_ascii=False))
PY
    return $?
  fi
  if command -v jq >/dev/null 2>&1; then
    # no fallback jq, ausente e null colapsam em "null" — o contrato trata os dois
    # igual (saída vazia), então a distinção não muda comportamento observável
    jq -r --arg k "$1" '
      (try (getpath($k | split("."))) catch null) as $v
      | if $v == null then "null"
        elif ($v | type) == "boolean" then "bool\n" + ($v | tostring)
        elif ($v | type) == "array" then
          "array" + ($v | map("\n" + (if type == "object" or type == "array" then tojson
                                      elif type == "boolean" then tostring
                                      elif . == null then ""
                                      else tostring end)) | join(""))
        elif ($v | type) == "object" then "object\n" + ($v | tojson)
        else "scalar\n" + ($v | tostring)
        end' "$FICHA" 2>/dev/null
    st=$?
    [ $st -eq 0 ] || { echo "invalid: jq falhou ao ler a ficha" >&2; return 3; }
    return 0
  fi
  echo "sem parser" >&2
  return 4
}

run_extract() { # $1 = chave; popula VTYPE e VOUT (valor sem a linha de tipo)
  out="$(extract "$1" 2>"$TMPERR")"
  st=$?
  if [ $st -eq 3 ]; then die3 "JSON inválido em $FICHA ($(cat "$TMPERR"))"; fi
  if [ $st -eq 4 ]; then die3 "sem python3 nem jq para ler a ficha"; fi
  [ $st -eq 0 ] || die3 "falha inesperada ao ler a ficha"
  VTYPE="$(printf '%s\n' "$out" | sed -n 1p)"
  VOUT="$(printf '%s\n' "$out" | sed 1d)"
}

TMPERR="$(mktemp)" || die3 "mktemp falhou"
trap 'rm -f "$TMPERR"' EXIT

case "$ACTION" in
  get)
    run_extract "$KEY"
    case "$VTYPE" in
      absent|null)
        if [ "$DEFAULT_SET" = 1 ]; then printf '%s\n' "$DEFAULT_VAL"; fi
        exit 0 ;;
      scalar|bool|array|object)
        [ -n "$VOUT" ] && printf '%s\n' "$VOUT"
        exit 0 ;;
      *) die3 "extrator devolveu tipo desconhecido: $VTYPE" ;;
    esac ;;

  profile)
    run_extract "profile.$ROLE.file"
    case "$VTYPE" in
      absent|null) exit 0 ;;
      scalar) ;;
      *) die3 "profile.$ROLE.file não é escalar (tipo: $VTYPE)" ;;
    esac
    case "$VOUT" in
      plugin:*)
        rest="${VOUT#plugin:}"
        [ -n "$PLUGIN_ROOT" ] || die3 "profile.$ROLE.file usa prefixo plugin: e não há --plugin-root nem \$CLAUDE_PLUGIN_ROOT"
        printf '%s\n' "$PLUGIN_ROOT/guidelines/$rest" ;;
      *)
        printf '%s\n' "$ROOT/$VOUT" ;;
    esac
    exit 0 ;;

  screen)
    run_extract "gates.screenVerify"
    case "$VTYPE" in
      absent|null)
        printf 'enabled=false\nmethod=\nartifactsDir=thoughts/screen-verify\n'; exit 0 ;;
      bool)
        # atalho booleano legado: true/false = {enabled, method:null} (init Etapa 4)
        printf 'enabled=%s\nmethod=\nartifactsDir=thoughts/screen-verify\n' "$VOUT"; exit 0 ;;
      object)
        run_extract "gates.screenVerify.enabled";      en="$VOUT"; [ "$VTYPE" = bool ] || en="false"
        run_extract "gates.screenVerify.method";       me=""; [ "$VTYPE" = scalar ] && me="$VOUT"
        run_extract "gates.screenVerify.artifactsDir"; ad="thoughts/screen-verify"; [ "$VTYPE" = scalar ] && ad="$VOUT"
        printf 'enabled=%s\nmethod=%s\nartifactsDir=%s\n' "$en" "$me" "$ad"
        exit 0 ;;
      *) die3 "gates.screenVerify com tipo inesperado: $VTYPE" ;;
    esac ;;
esac

die2 "ação não tratada: $ACTION"
