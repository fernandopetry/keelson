---
description: Mostra qual versão do keelson esta sessão carregou ("qual versão está rodando?") e a compara com a instalação da CLI e o marketplace — separa "update sem reiniciar" de "cópia fora da loja da CLI" (Claude Desktop); read-only, sem rede
---

# /keelson:version

Você é o operador de diagnóstico de versão do plugin. Sua função é rodar o script embarcado e **reportar fielmente** o que ele disse — a versão que esta sessão realmente executa, o que a CLI diz ter instalado e o veredito da comparação.

**Princípio inviolável**: o motor é o script (`scripts/version.sh`) — o comando só o executa e reporta. Não leia `plugin.json` por conta própria, não rode `claude plugin list` nem `claude plugin marketplace update`: o que o script não exibiu, você não afirma.

## Input

```
/keelson:version
```

Sem argumentos.

## Etapa 1: executar o diagnóstico

Rodar via Bash:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/version.sh"
```

O script lê, sem rede e sem alterar nada: a versão carregada (`plugin.json` da raiz) e a versão do Quality Charter; a **origem** da árvore (cache da CLI · repositório de desenvolvimento · loja própria do Claude Desktop · fora da loja da CLI); a ficha de plugins da CLI (uma linha por scope, marcando a que aponta para esta árvore); o cache local do marketplace (última versão **conhecida**, do último refresh — não "a última publicada"); a versão do Claude Code quando a CLI está no PATH.

## Etapa 2: reportar

1. Reproduzir as linhas do script — versão carregada, origem, scopes da ficha, marketplace e veredito — sem completar lacunas: fonte que o script marcou como `nao encontrado`, `ilegivel` ou `best-effort` aparece assim no report.
2. Quando o veredito trouxer `ATENCAO`, a ação que ele nomeia é a recomendação do report; não proponha caminho alternativo (rodar o update por conta própria, editar a ficha de plugins).
3. Falha do script (exit 2: raiz sem `plugin.json`, opção inválida) → reproduzir o erro. Não tentar contornar por outro caminho.

## Output ao usuário

```markdown
# Versão do keelson

- Carregada nesta sessão: <versão> (Quality Charter <versão>) — <origem>
- Instalada na CLI: <scope: versão por linha, ou "ficha de plugins não encontrada">
- Marketplace (cache local, refresh <data>): <versão, ou "cache não encontrado">
- Claude Code: <linha do script>

<veredito do script, com a ação nomeada — ou "sessão e instalação coincidem">
```
