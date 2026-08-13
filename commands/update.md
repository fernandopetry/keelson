---
description: Atualiza o plugin keelson instalado para a última versão do marketplace, via CLI do Claude Code — o update só vale após reiniciar a sessão
argument-hint: [--scope user|project|local]
disable-model-invocation: true
---

# /keelson:update

Você é o operador de atualização do plugin. Sua função é rodar o script de update embarcado e **reportar fielmente** o que ele disse — versão antes/depois quando disponível, erro nomeado quando houver.

**Princípio inviolável 1**: o motor é o script (`scripts/update.sh`) — o comando só o executa e reporta. Não replique a lógica de update inline nem rode `claude plugin ...` por conta própria.

**Princípio inviolável 2**: **o update não vale para a sessão corrente** (a CLI avisa: *restart required to apply*). Todo report termina lembrando o humano de reiniciar a sessão — nunca prometa que a versão nova já está ativa.

## Input

```
/keelson:update [--scope user|project|local]
```

| Argumento | Uso |
|---|---|
| *(nenhum)* | Atualiza a instalação do scope `user` (o default da CLI) |
| `--scope <s>` | Repassado ao `claude plugin update` — para instalação em `project` ou `local` |

## Etapa 1: executar o update

Rodar via Bash, repassando os argumentos recebidos:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" $ARGUMENTS
```

O script faz, nesta ordem: refresh do marketplace (`claude plugin marketplace update keelson`) e update do plugin (`claude plugin update keelson`) — a ordem importa: atualizar só o marketplace **não** atualiza o plugin instalado. Ao final, ele lê os marcadores `Re-init:` do CHANGELOG recém-instalado e diz se alguma versão do salto exige re-rodar `/keelson:init` (decisão 4.189) — quando não consegue determinar, ele diz isso, nunca "não precisa".

## Etapa 2: reportar

1. Sucesso → reportar a versão antes/depois **conforme a saída do script** (se o script não exibiu versão, diga isso — nunca invente número), repassar o veredito de re-init exatamente como o script o deu (exige · não exige · não determinável) e fechar com o lembrete de reiniciar a sessão.
2. Falha → reproduzir o erro do script e a causa provável que ele nomeou (CLI ausente no PATH · plugin não instalado via marketplace neste scope · instalação de desenvolvimento). Não tentar contornar por outro caminho.

## Output ao usuário

```markdown
# Update do keelson

- Antes: <linha do script, ou "versão não exibida">
- Agora: <linha do script, ou "versão não exibida">
- Re-init: <veredito do script — exige `/keelson:init` (com as versões) · não exige · não determinável>

⚠ A sessão corrente continua na versão antiga — reinicie a sessão do Claude Code
para carregar a versão nova.
```
