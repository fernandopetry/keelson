---
description: Atualiza o plugin keelson instalado para a última versão do marketplace, via CLI do Claude Code — o update só vale após reiniciar a sessão
argument-hint: "[--scope user|project|local] [--root <raiz>]"
disable-model-invocation: true
---

# /keelson:update

Você é o operador de atualização do plugin. Sua função é rodar o script de update embarcado e **reportar fielmente** o que ele disse — versão antes/depois quando disponível, erro nomeado quando houver.

**Princípio inviolável 1**: o motor é o script (`scripts/update.sh`) — o comando só o executa e reporta. Não replique a lógica de update inline nem rode `claude plugin ...` por conta própria.

**Princípio inviolável 2**: **o update não vale para a sessão corrente** (a CLI avisa: *restart required to apply*). Todo report termina lembrando o Diretor de reiniciar a sessão — nunca prometa que a versão nova já está ativa.

## Input

```
/keelson:update [--scope user|project|local] [--root <raiz>]
```

| Argumento | Uso |
|---|---|
| *(nenhum)* | Atualiza a instalação do scope `user` (o default da CLI) e mede o projeto da pasta corrente |
| `--scope <s>` | Repassado ao `claude plugin update` — para instalação em `project` ou `local` |
| `--root <raiz>` | Raiz do projeto a medir, quando a sessão não está na raiz (default: pasta corrente, ou o topo do git, desde que tenha `keelson.config.json`) |

## Etapa 1: executar o update

Rodar via Bash, repassando os argumentos recebidos:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" $ARGUMENTS
```

O script atualiza marketplace→plugin, lê os `Re-init:` do CHANGELOG (4.189) e mede o projeto contra a árvore nova (4.440); as linhas Antes/Agora/Re-init/Medição/Veredito que ele imprime são o que você repassa.

## Etapa 2: reportar

1. Sucesso → reportar a versão antes/depois **conforme a saída do script** (se o script não exibiu versão, diga isso — nunca invente número), repassar a linha `Veredito:` exatamente como o script a deu (exige · não exige · não determinável · pulada/não medido) **com a medição do projeto** que a sustenta — quando o script disser que o salto não explica a divergência ("init esquecido em salto anterior"), repita isso: é o caso que o CHANGELOG sozinho deixaria passar — e fechar com o lembrete de reiniciar a sessão.
2. Falha → reproduzir o erro do script e a causa provável que ele nomeou (CLI ausente no PATH · plugin não instalado via marketplace neste scope · instalação de desenvolvimento). Não tentar contornar por outro caminho.

## Output ao usuário

```markdown
# Update do keelson

- Antes: <linha do script, ou "versão não exibida">
- Agora: <linha do script, ou "versão não exibida">
- Re-init pelo CHANGELOG: <linha do script — exige (com as versões) · não exige · não determinável>
- Medição do projeto: <raiz medida e as linhas de bloco do `CLAUDE.md` · `AGENTS.md` · blocos da ficha, ou "pulada — sem ficha na pasta corrente">
- Veredito: <linha `Veredito:` do script>

⚠ A sessão corrente continua na versão antiga — reinicie a sessão do Claude Code
para carregar a versão nova.
```
