# BRIEF-001: Exportação da carteira de clientes pelo gerente comercial

**Status**: Emitido · **Slug**: clientes

## Pedido como dito
"O gerente comercial precisa baixar a carteira de clientes dele em planilha — nome, e-mail,
telefone e CPF — para trabalhar a campanha do trimestre fora do sistema. Hoje ele pede ao
suporte, que roda uma query e manda por e-mail."

## Personas
- **Gerente comercial**: dono de uma carteira (subconjunto dos clientes do tenant); usa o painel diariamente.
- **Analista de suporte**: hoje executa a extração manual; quer parar de fazer isso.
- Anti-persona: cliente final — não vê nem sabe da exportação.

## Interpretação do PO
- **Contexto**: os dados já existem na tela de clientes; o que falta é a saída em arquivo.
- **Pedido**: botão de exportação na tela de clientes que gera a planilha da carteira do gerente logado.
- **Premissas decididas**: formato CSV; a exportação é síncrona para carteiras de até 5.000 clientes.
- **Fora de escopo**: exportação de todos os clientes do tenant; agendamento; outros formatos.

## Fatos do código
- A tela de clientes (`clientes/index`) lista a carteira do gerente logado com filtro por status.
- Existe o papel `gerente` e o papel `operador`; a tela é visível para os dois.
- Não há hoje nenhum endpoint de exportação nem registro de quem baixou o quê.

## Perguntas
### Respondidas
- Q1 A planilha inclui o CPF completo? → **sim** (o Diretor decidiu: a campanha precisa do CPF).
### Pendentes a produto
- nenhuma
