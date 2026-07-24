# Code Review (core)

> Checklist de revisão **agnóstico de stack**. No fluxo SDD, o code review é o **gate de
> revisão de código** (gates 1–7); a **segurança** e o **comportamento verificado** são
> gates próprios, com revisores dedicados (`security-reviewer`, `task-verifier`) quando
> aplicável — ver `./WORKFLOW.md`.
>
> A revisão confere o código contra a **constituição** (`../_meta/QUALITY-CHARTER.md`), a
> doutrina de `core/` e o **perfil de linguagem** ativo. Detalhes idiomáticos da stack
> vivem no perfil; o que já é princípio está no Charter — referencie, não repita.

---

## O que verificar

| Área | Referência |
|------|------------|
| Correção provada por teste externo | Charter Art. 1 · `./TESTING.md` |
| Segurança (OWASP, negar por padrão) | Charter Art. 2 · `./SECURITY.md` |
| Reúso / DRY (nada reimplementado) | Charter Art. 3 |
| Limites e responsabilidade única (SOLID) | Charter Art. 4 · `./ARCHITECTURE.md` |
| Nomes revelam intenção; idioma consistente | Charter Art. 5 |
| Escopo restrito; escoteiro declarado no trecho tocado | Charter Art. 6 |
| Legibilidade; comentário dentro do piso e do teto | Charter Art. 7 |
| Performance (N+1, custo proporcional) | Charter Art. 8 · `./PERFORMANCE.md` |
| Definição de pronto satisfeita | Charter Art. 9 |
| Idiomas e armadilhas da stack | Perfil de linguagem ativo |
| Erros já cometidos no projeto | Arquivo de lições do projeto |

---

## Sinais de alerta em nomes (Charter Art. 5, 7)

Nomes genéricos escondem intenção: `process()`, `execute()`, `handle()`, `doStuff()`,
`data`, `info`, `obj`, `temp`, `value`, `result`, `*Manager`, `*Util`. Não são proibição
mecânica — `execute()` num contrato canônico (ex.: um caso de uso de método único) é
legítimo. São **gatilho de pergunta**: *"existe nome mais específico do domínio?"*. Se
existe, o genérico é smell a apontar. Nome que **silencia efeito colateral** (`login()`
que também envia e-mail) é o mesmo smell, mais grave — viola a régua do Art. 5.

---

## Rejeição imediata

- Vulnerabilidade de segurança (ver `./SECURITY.md`)
- Anti-padrão de arquitetura / quebra da regra da dependência (ver `./ARCHITECTURE.md`)
- Sem teste para a lógica de negócio nova ou alterada
- Reimplementação de código canônico já existente (viola Charter Art. 3)

---

## Régua do revisor: gerador ≠ avaliador

A revisão vale porque é feita com **contexto limpo**, por quem não escreveu o código. Ela
**não substitui** a prova externa (o teste), e o autochecklist do autor **não substitui**
a revisão. Onde não há teste possível (ex.: refactor de legibilidade), a revisão
independente é a prova.

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
