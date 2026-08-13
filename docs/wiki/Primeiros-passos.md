# Primeiros passos

Do zero à primeira demanda entregue. Requisito: o plugin já
[instalado](Instalacao) e uma sessão do Claude Code aberta no seu repositório.

## 1. Preparar o projeto

```
/keelson:init
```

Responda o que ele perguntar (o resto ele detecta). Ao final, confira dois arquivos:

- **`keelson.config.json`** — a [ficha](Ficha-do-projeto). Vale um olhar agora: se
  `quality.test` e `quality.lint` não forem os comandos reais do seu projeto, os quality
  gates vão reprovar por motivo errado.
- **`CLAUDE.md`** — ganhou um bloco gerenciado do keelson. Não edite dentro dele; o
  `init` reescreve esse bloco a cada execução.

Faça o commit desses dois arquivos antes de começar — eles são configuração do time, não
rascunho de sessão.

## 2. Pedir a primeira demanda

O modo padrão é **autônomo**. Você não precisa digitar comando nenhum: peça em linguagem
natural na sessão.

```
Preciso exportar os relatórios em CSV, com filtro de período.
```

Ou explicitamente:

```
/keelson:auto "Exportação de relatórios em CSV com filtro de período"
```

### O que acontece a seguir

1. **Última chamada.** O time pergunta só o que muda o resultado — contrato externo,
   comportamento em falha, segurança, decisão irreversível. Pedido claro → nenhuma pergunta.
2. **Brief.** Seu pedido, mais a interpretação do PO em ~5 linhas, é gravado em
   `docs/<slug>/briefs/BRIEF-NNN.md`. A interpretação é mostrada e **o fluxo segue sem
   esperar** — é uma janela de veto: silêncio significa "pode ir"; se você corrigir, o
   brief é reemitido.
3. **O ciclo corre:** SPEC → PLAN → TASKs → implementação wave a wave, com os quality
   gates a cada tarefa — numa branch criada já na largada (uma por demanda; com Jira
   ativo, o card nasce na largada e a key pode entrar no nome da branch — veja o bloco
   `git` na [Ficha do projeto](Ficha-do-projeto)), com cada etapa commitada ao fechar:
   a papelada nunca fica horas fora do git.
4. **Entrega:** push da branch, **sem PR** — com o relatório de aceitação do PO (a
   entrega bate com o brief?) e a lista do que ficou pendente para você.

Você não precisa ficar olhando. O ciclo não para entre waves para pedir permissão.

## 3. Ler a entrega

O relatório final traz, em ordem de importância:

| Seção | O que olhar |
|---|---|
| Aceitação do PO | A entrega corresponde ao que você pediu no brief |
| Gates | O que passou, o que degradou e **o que ficou pendente** — pendência nomeada nunca vira "Done" |
| Pendências do Diretor | Decisões que sobraram para você, em lote |
| Duração | Relógio de parede por etapa |

Consulte o estado a qualquer momento:

```
/keelson:status <slug>
```

## 4. Revisar e integrar

**A autonomia termina nos commits.** Abrir PR, mergear e publicar são atos seus.

```
/keelson:integrate PLAN-001
```

Valida a Definition of Done, roda a suíte completa e **abre o Pull Request**. Merge e
deploy continuam na sua mão — inclusive porque pode haver outras sessões trabalhando na
mesma base.

## Quando você quer dirigir etapa a etapa

O ciclo autônomo é o caminho do dia a dia, mas cada etapa é um comando:

```
/keelson:specify "descrição da demanda" --slug=relatorios   # o QUÊ, sem tecnologia
/keelson:plan SPEC-001                                      # o COMO (componentes, decisões)
/keelson:tasks PLAN-001                                     # tarefas atômicas em waves
/keelson:implement PLAN-001 --dry-run                       # simular
/keelson:implement PLAN-001                                 # executar
```

Ou `/keelson:guided` para o mesmo ciclo pausando em dois marcos (SPEC pronta, PLAN
pronto) para o seu OK.

## Não sabe por onde começar?

```
/keelson:triage "descrição da demanda"
```

Ele classifica a demanda e diz qual comando usar — **não executa nada sem confirmação**.

## Recebeu um documento da área de produto?

```
/keelson:brief docs/<slug>/origin/PRD-exemplo.md
```

A **forja do BRIEF** é o estágio profundo antes do ciclo: inventaria o documento contra
o que a SPEC vai exigir, responde pelo **código** o que o código responde, pergunta a
você **uma coisa por vez** só o que faltou — e o que só produto sabe vira pergunta
formal com Q-ID, sem travar nada. No fim, ou o BRIEF sai `pronto` (com o comando de
handoff para rodar `/keelson:auto` numa sessão limpa), ou fica `aguardando-produto` e
você retoma **em qualquer sessão nova** com `/keelson:brief <slug>` quando as respostas
chegarem. Documento pequeno ou pedido claro não precisa da forja — vá direto ao `auto`.

## Três coisas que evitam retrabalho

1. **Não edite `INDEX.md`.** Ele é gerado. Se ficou errado: `/keelson:rebuild-index <slug>`.
2. **Projeto legado primeiro migra, depois muda.** Pasta de docs sem `INDEX.md` →
   `/keelson:migrate-legacy <slug>` antes de qualquer outra coisa.
3. **Trivial pula o ciclo — mas trivial é raio de dano, não tamanho.** Typo, texto,
   cor: mudança direta, sem SPEC. Já uma linha que muda o que o sistema promete (shape
   de id, chave de payload, default de API) entra no ciclo por menor que pareça: todo
   consumidor quebra junto. Na dúvida, `/keelson:triage` decide.

Continue por [Conceitos](Conceitos) para entender o modelo, ou pelo
[Guia do método](Guia-do-metodo) para a referência completa dos comandos.
