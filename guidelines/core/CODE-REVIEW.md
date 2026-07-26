# Code Review (core)

> **Dono único da régua dos gates 1–7** — o que cada gate exige, o que o faz falhar e como
> ele degrada quando não há artefato SDD. Quem a executa é sempre o **`task-reviewer`**, em
> dois fluxos: dentro do ciclo (via `/keelson:implement`, com TASK/PLAN/SPEC) e sobre um
> diff avulso (via `/keelson:review`, modo degradado). Os fluxos trazem o próprio
> protocolo — input, output, retry —, nunca uma segunda cópia da régua.
>
> A **segurança** (gate 8) e o **comportamento verificado** (gate 9) têm revisores dedicados
> (`security-reviewer`, `task-verifier`) e doutrina própria — ver `./WORKFLOW.md`.
>
> A revisão confere o código contra a **constituição** (`../_meta/QUALITY-CHARTER.md`), a
> doutrina de `core/` e o **perfil de linguagem** ativo. Detalhes idiomáticos da stack
> vivem no perfil; o que já é princípio está no Charter — referencie, não repita.

---

## Os 7 gates

### Gate 1: cobertura de ACs

Cada AC dos critérios de pronto tem ≥ 1 teste que o verifica, e o teste é **falsificável**
(quebra se a implementação quebrar). Âncora: Charter Art. 1 · `./TESTING.md`.

**Falha**: AC sem teste correspondente. Falso positivo típico: teste que sempre passa.

### Gate 2: testes passando

100% dos testes novos passam, e os pré-existentes do domínio tocado seguem verdes (sem
regressão local).

Execute localmente os testes **filtrados ao escopo** — não confie no report de quem
implementou. **Não** rode a suíte completa aqui (verificação forte e única —
`./TESTING.md`). Valor ou constante compartilhada alterada → amplie o filtro para os
consumidores. Você é o dono da rodada escopada: **registre o comando/filtro executado**,
porque o `task-verifier` decide por ele se precisa re-rodar.

**Falha**: qualquer teste vermelho.

### Gate 3: lint limpo

Zero warnings/erros **novos**. Pré-existentes podem permanecer; o que não pode é ter sido
adicionado agora.

Rode o lint **escopado aos arquivos tocados**, nunca o repo inteiro: lint global em repo
com dívida herdada mede erro de terceiros e dá **falso REPROVADO**.

**Falha**: warning/erro novo nos arquivos tocados.

### Gate 4: escopo respeitado

Os arquivos modificados estão no escopo declarado e dentro dos `codePaths` da ficha;
nenhum arquivo do "não inclui" foi tocado. Mudança colateral (não realiza AC nem é
auxiliar) é legítima **somente** se declarada como escoteiro e dentro das três condições
do Charter Art. 6.

**Falha**: arquivo fora do escopo; colateral não declarado; "escoteiro" fora das três
condições (muda comportamento, atravessa arquivo, escopo novo rotulado de limpeza).

### Gate 5: decisões DEC respeitadas

O código segue as DEC do PLAN e as decisões irreversíveis do INDEX do slug; nenhuma
alternativa descartada entrou por engano.

**Falha**: implementação contradiz uma DEC.

### Gate 6: aderência ao Charter + perfil ativo

- **Stack autorizado**: só a linguagem/versão do perfil ativo (`profile` da ficha).
- **Padrão arquitetural**: camadas, direção de dependência, fluxo (`./ARCHITECTURE.md` + perfil).
- **Naming**: convenções do perfil.
- **Padrão de teste**: runner e estrutura do perfil / `./TESTING.md`.
- **Anti-padrões** proibidos pelo perfil: nenhum presente.
- **Decisões irreversíveis**: nenhuma quebrada.

**Falha**: violação de qualquer item — citar exatamente qual.

### Gate 7: code review qualitativo

O crivo genérico (legibilidade, código morto, tratamento de erro, string hardcoded) é
ofício do revisor — aplique-o sem checklist. Os pontos com régua keelson própria:

- **Naming**: nome genérico onde existe nome de domínio mais específico é smell — ver
  "Sinais de alerta em nomes" abaixo.
- **Condicionais e assinaturas** (Art. 4, 7): aninhamento profundo que guard clause ou
  extração resolveria; condicional-por-variante repetida que pede polimorfismo;
  assinatura longa sem objeto de parâmetro.
- **Abstração especulativa** (Art. 4): indireção ou padrão sem dor demonstrável no diff e
  sem DEC que o justifique — sinalizar (bloqueia quando óbvio).
- **Reúso / DRY** (Art. 3): o código **não reimplementa** utilitário, validação, helper,
  conversão ou abstração que **já existe** no projeto. Não basta checar duplicação entre
  os arquivos novos — procure o equivalente canônico já existente que deveria ter sido
  usado (seção de reúso do perfil ativo · `./ARCHITECTURE.md`). Reimplementação de
  canônico existente = FALHA mesmo com o código correto, **inclusive nos testes**
  (fixtures/helpers — `./TESTING.md`).
- **Comentários** (Art. 7): todo comentário passa no teste de apagar (Perde/Não-perde).
- **Erros já cometidos no projeto**: as lições de `guidelines/project/` valem como regra.
- **Calibração por exemplares**: antes de reprovar por estilo/padrão, compare com código
  análogo já **mergeado** (mesma camada/domínio). Padrão consistente com o repo aprovado
  não é smell — reprove o desvio real, não a divergência com um ideal abstrato.

**Falha**: smell que comprometeria manutenção, ou reimplementação de utilitário existente.

---

## Sem artefato SDD: como a régua degrada

Revisão de código que entrou fora do ciclo (hotfix, código herdado, contribuição externa)
não tem TASK, ACs nem PLAN. Os gates **não são dispensados** — perdem a âncora documental e
passam a se ancorar no diff:

| Gate | Degradação |
|---|---|
| 1 | Sem AC: toda **lógica de negócio nova ou alterada** no diff exige teste falsificável. A exigência de prova não depende de existir AC escrito. |
| 4 | Sem "Escopo > Inclui": o diff **faz uma coisa só**? Alteração não relacionada ao propósito aparente é colateral — legítima só sob as três condições do Art. 6. |
| 5 | Sem PLAN: se o slug for inferível, valem as **decisões irreversíveis do INDEX**; slug não inferível → gate `n/a`, e isso é declarado, não omitido. |

Gates 2, 3, 6 e 7 rodam sem degradação alguma — nenhum deles depende de artefato.

Gate degradado ou `n/a` **é sempre declarado no report**. Silêncio sobre um gate lê-se como
gate aprovado, e essa é a falha que a régua existe para impedir.

---

## Sinais de alerta em nomes (Art. 5, 7)

Nomes genéricos escondem intenção: `process()`, `execute()`, `handle()`, `doStuff()`,
`data`, `info`, `obj`, `temp`, `value`, `result`, `*Manager`, `*Util`. Não são proibição
mecânica — `execute()` num contrato canônico (ex.: um caso de uso de método único) é
legítimo. São **gatilho de pergunta**: *"existe nome mais específico do domínio?"*. Se
existe, o genérico é smell a apontar. Nome que **silencia efeito colateral** (`login()`
que também envia e-mail) é o mesmo smell, mais grave — viola a régua do Art. 5.

---

## Calibração de severidade

**Não bloqueia** (vira sugestão): espaçamento e ordem de imports; nome estranho mas
legível; nome genérico com alternativa de domínio disponível (só bloqueia se esconder
intenção ou efeito colateral); comentário que reprova no teste do Art. 7 — entra como
**remoção sugerida**, com os trechos apontados.

**Bloqueia**: violação de regra explícita do Charter ou do perfil; lógica de negócio sem
teste; escopo violado; reimplementação de canônico existente. Do Art. 7 bloqueiam: bloco
de comentário maior que o código que explica; workaround sem condição de remoção; DEC sem
âncora no ponto do código.

---

## Rejeição imediata

- Vulnerabilidade de segurança (ver `./SECURITY.md`)
- Anti-padrão de arquitetura / quebra da regra da dependência (ver `./ARCHITECTURE.md`)
- Sem teste para a lógica de negócio nova ou alterada
- Reimplementação de código canônico já existente (viola Charter Art. 3)

---

## Régua do revisor: gerador ≠ avaliador

Quem escreveu o código não aprova o próprio diff. A revisão vale pelo **contexto limpo**
(Charter, régua geral); onde não há teste possível (ex.: refactor de legibilidade), a
revisão independente **é** a prova.

---

## Formato de saída

**Aprovado:**

```text
✅ APROVADO
- Pontos positivos
- Sugestões (opcionais)
```

**Rejeitado:**

```text
❌ CORREÇÕES NECESSÁRIAS
1. `arquivo:linha` — Problema → Solução
```
