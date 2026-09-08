#!/usr/bin/env bash
# run.sh — suíte de regressão da camada de release (decisão 4.189).
#
# Cobre as duas metades do marcador Re-init:
#   - check-release.sh: a entrada da versão corrente exige "Re-init: required|none"
#     (escopo restrito à corrente — entrada histórica sem marcador NÃO falha);
#   - update.sh --reinit-scan: classificação do salto (BEFORE, AFTER] — required
#     vence, none limpa, marcador ausente degrada, BEFORE/AFTER fora do arquivo
#     degradam, CHANGELOG ausente degrada (nunca inventa "não precisa").
#
# Fixtures de CHANGELOG sintéticas montadas em diretório temporário; para o
# check-release, um mini-repo com os 3 lugares de versão + MIRRORS vazio.
#
# Uso: scripts/tests/release/run.sh
# Exit: 0 tudo verde · 1 alguma divergência. Bash 3.2-compatível.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
UPDATE="$HERE/../../update.sh"
CHECK="$HERE/../../check-release.sh"

[ -f "$UPDATE" ] || { echo "ERRO: update.sh não encontrado em $UPDATE" >&2; exit 1; }
[ -f "$CHECK" ]  || { echo "ERRO: check-release.sh não encontrado em $CHECK" >&2; exit 1; }

TMP="$(mktemp -d)" || { echo "ERRO: mktemp falhou" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
total=0

bash -n "$UPDATE" || { echo "FAIL bash -n update.sh"; exit 1; }
echo "ok   bash -n update.sh"
bash -n "$CHECK" || { echo "FAIL bash -n check-release.sh"; exit 1; }
echo "ok   bash -n check-release.sh"

# --- fixture de CHANGELOG para a varredura ---
CL="$TMP/CHANGELOG.md"
cat > "$CL" <<'EOF'
# Changelog

## [Unreleased]

---

## [0.12.0] — 2026-08-12

Re-init: none

### Added
- topo.

## [0.11.0] — 2026-08-11

Re-init: required

### Changed
- mudou o bloco.

## [0.10.1] — 2026-08-10

### Fixed
- entrada legada sem marcador.

## [0.10.0] — 2026-08-09

Re-init: none

### Added
- base.

## [0.9.0] — 2026-08-08

Re-init: none

### Added
- antiga.
EOF

scan() { # nome linha-1-esperada -- before after [changelog]
  name="$1"; want="$2"; shift 2
  [ "${1:-}" = "--" ] && shift
  total=$((total + 1))
  got="$(bash "$UPDATE" --reinit-scan "$1" "$2" "${3:-$CL}" 2>&1 | head -1)"
  case "$got" in
    "$want"*) echo "ok   $name" ;;
    *) echo "FAIL $name"
       printf '  esperado (prefixo): [%s]\n  obtido:            [%s]\n' "$want" "$got"
       fail=$((fail + 1)) ;;
  esac
}

# required no salto → ATENCAO com a versão nomeada
scan required-no-salto "ATENCAO:" -- 0.10.0 0.12.0
# salto só com none → veredito limpo
scan salto-limpo "Re-init: nenhuma versao do salto (0.11.0 -> 0.12.0)" -- 0.11.0 0.12.0
# entrada sem marcador dentro do salto → degrada nomeando a versão
scan sem-marcador-degrada "Re-init: nao determinavel para a(s) versao(oes): 0.10.1" -- 0.10.0 0.10.1
# required E sem-marcador no mesmo salto → required vence (aviso acionável primeiro)
scan required-vence "ATENCAO:" -- 0.9.0 0.12.0
# BEFORE ausente do arquivo → degrada, nunca varre o arquivo inteiro
scan before-ausente "Re-init: nao determinavel — a versao anterior (0.1.0) nao aparece no" -- 0.1.0 0.12.0
# AFTER ausente do arquivo (árvore velha) → degrada
scan after-ausente "Re-init: nao determinavel — a entrada da versao instalada (0.13.0) nao" -- 0.12.0 0.13.0
# CHANGELOG inexistente → degrada
scan changelog-ausente "Re-init: nao determinavel — CHANGELOG.md nao encontrado" -- 0.10.0 0.12.0 "$TMP/nao-existe.md"

# a versão required é nomeada no aviso
total=$((total + 1))
got="$(bash "$UPDATE" --reinit-scan 0.9.0 0.12.0 "$CL" 2>&1)"
case "$got" in
  *"0.11.0"*) echo "ok   required-nomeia-versao" ;;
  *) echo "FAIL required-nomeia-versao: 0.11.0 ausente do aviso"; fail=$((fail + 1)) ;;
esac

# uso incorreto do modo de teste
total=$((total + 1))
bash "$UPDATE" --reinit-scan 0.1.0 >/dev/null 2>&1
st=$?
if [ "$st" -eq 2 ]; then echo "ok   reinit-scan-args-exit-2"
else echo "FAIL reinit-scan-args-exit-2: exit $st"; fail=$((fail + 1)); fi

# --- mini-repo para o check-release ---
# Os 3 lugares de versão + MIRRORS vazio; scripts/ mínimo para o bash -n.
mkrepo() { # dir versao
  r="$1"; v="$2"
  mkdir -p "$r/.claude-plugin" "$r/scripts"
  printf '{\n  "name": "keelson",\n  "version": "%s"\n}\n' "$v" > "$r/.claude-plugin/plugin.json"
  printf '{\n  "metadata": { "version": "%s" }\n}\n' "$v" > "$r/.claude-plugin/marketplace.json"
  printf '## Status\n\n`%s`\n' "$v" > "$r/README.md"
  printf "MIRRORS=''\n" > "$r/scripts/publish-wiki.sh"
}

checkrel() { # nome exit-esperado trecho-esperado dir
  name="$1"; wantexit="$2"; wantgrep="$3"; dir="$4"
  total=$((total + 1))
  got="$(bash "$CHECK" --root "$dir" 2>&1)"
  st=$?
  if [ "$st" -ne "$wantexit" ]; then
    echo "FAIL $name: exit $st (esperado $wantexit)"
    printf '%s\n' "$got" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  if [ -n "$wantgrep" ] && ! printf '%s\n' "$got" | grep -qF "$wantgrep"; then
    echo "FAIL $name: saída sem o trecho esperado [$wantgrep]"
    printf '%s\n' "$got" | sed 's/^/  /'
    fail=$((fail + 1)); return
  fi
  echo "ok   $name"
}

# entrada corrente com marcador → verde (mesmo com entrada histórica sem marcador)
R1="$TMP/repo-ok"; mkrepo "$R1" 0.12.0
cp "$CL" "$R1/CHANGELOG.md"
checkrel corrente-com-marcador 0 "entrada [0.12.0] declara o marcador Re-init" "$R1"

# entrada corrente SEM marcador → falha nomeando o §4.189
R2="$TMP/repo-sem-marcador"; mkrepo "$R2" 0.10.1
cp "$CL" "$R2/CHANGELOG.md"
checkrel corrente-sem-marcador 1 "sem a linha \"Re-init: required\" ou \"Re-init: none\" (§4.189)" "$R2"

# valor inválido no marcador → falha (só required|none valem)
R3="$TMP/repo-valor-invalido"; mkrepo "$R3" 0.12.0
sed 's/^Re-init: none$/Re-init: talvez/' "$CL" > "$R3/CHANGELOG.md"
checkrel marcador-invalido 1 "sem a linha \"Re-init: required\" ou \"Re-init: none\" (§4.189)" "$R3"

# --- negativos das guardas de versão/CHANGELOG/MIRRORS (4.384) ---
# A 4.83 provou cada camada por mutação à mão e nunca congelou: a suíte só criava
# as três versões iguais, e a comparação trocada por `true` seguia verde.

# versões divergentes entre os 3 lugares → falha nomeando os três valores
R4="$TMP/repo-diverge"; mkrepo "$R4" 0.12.0
printf '{\n  "metadata": { "version": "0.13.0" }\n}\n' > "$R4/.claude-plugin/marketplace.json"
cp "$CL" "$R4/CHANGELOG.md"
checkrel versoes-divergem 1 "versões divergem: plugin.json=0.12.0 marketplace.json=0.13.0 README=0.12.0" "$R4"

# README atrasado (os dois manifests iguais) → falha
R5="$TMP/repo-readme-atrasado"; mkrepo "$R5" 0.12.0
printf '## Status\n\n`0.11.0`\n' > "$R5/README.md"
cp "$CL" "$R5/CHANGELOG.md"
checkrel readme-atrasado 1 "README=0.11.0" "$R5"

# marketplace.json ausente → falha nomeando o arquivo
R6="$TMP/repo-sem-marketplace"; mkrepo "$R6" 0.12.0
rm -f "$R6/.claude-plugin/marketplace.json"
cp "$CL" "$R6/CHANGELOG.md"
checkrel marketplace-ausente 1 "não achei a versão em .claude-plugin/marketplace.json" "$R6"

# versão bumpada sem entrada no CHANGELOG → falha citando §4.48
R7="$TMP/repo-sem-entrada"; mkrepo "$R7" 0.14.0
cp "$CL" "$R7/CHANGELOG.md"
checkrel changelog-sem-entrada 1 'sem entrada "## [0.14.0]" — bump sem entrada é release incompleto (§4.48)' "$R7"

# CHANGELOG ausente → falha (a entrada não pode existir)
R8="$TMP/repo-sem-changelog"; mkrepo "$R8" 0.12.0
checkrel changelog-ausente-falha 1 'sem entrada "## [0.12.0]"' "$R8"

# MIRRORS apontando para arquivo inexistente → falha nomeando o espelho
R9="$TMP/repo-mirror-quebrado"; mkrepo "$R9" 0.12.0
cp "$CL" "$R9/CHANGELOG.md"
printf "MIRRORS='docs/nao-existe.md|Pagina'\n" > "$R9/scripts/publish-wiki.sh"
checkrel mirror-quebrado 1 "MIRRORS aponta para arquivo inexistente: docs/nao-existe.md" "$R9"

# controle: MIRRORS apontando para arquivo existente → verde
R10="$TMP/repo-mirror-ok"; mkrepo "$R10" 0.12.0
cp "$CL" "$R10/CHANGELOG.md"
mkdir -p "$R10/docs"; printf '# p\n' > "$R10/docs/existe.md"
printf "MIRRORS='docs/existe.md|Pagina'\n" > "$R10/scripts/publish-wiki.sh"
checkrel mirror-ok 0 "todos os espelhos do MIRRORS existem" "$R10"

# bash -n: script com sintaxe quebrada no mini-repo → falha
R11="$TMP/repo-bash-n"; mkrepo "$R11" 0.12.0
cp "$CL" "$R11/CHANGELOG.md"
printf 'if [ 1 ]; then\n' > "$R11/scripts/quebrado.sh"
checkrel bash-n-quebrado 1 "bash -n falhou em scripts/quebrado.sh" "$R11"

echo "---"
if [ "$fail" -gt 0 ]; then
  echo "release: $fail de $total casos falharam"
  exit 1
fi
echo "release: $total casos verdes"
exit 0
