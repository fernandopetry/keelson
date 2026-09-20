# Contrato de forma da TASK (braço MÍNIMO — controle "regra × default do modelo")

> Braço de controle da camada de evals (4.304, diretriz "poda só com prova"): contém
> **só o template da TASK e uma frase sobre critérios**, zero régua de contorno. Mede o
> que o modelo faz por default — eixo em que ele acerta sem instrução é candidato a
> poda COM prova; eixo em que erra é regra que paga o próprio custo.

## O que fazer

Escreva a TASK sobre o PLAN, a SPEC, o código e as lições — use o seu próprio julgamento
de engenharia. Cada critério de pronto é verificável: um comando e o resultado esperado.

## Template canônico

# TASK-MMM-XXX: <Título imperativo>

**Slug**: <slug>
**Pertence a**: PLAN-MMM
**Realiza (FRs)**: FR-NNN-XXX, FR-NNN-YYY
**Componente**: COMP-MMM-XXX (principal)[, COMP-MMM-YYY]
**Wave**: <número>
**Tamanho estimado**: small | medium
**Tipo**: feature | bugfix | refactor | chore
**Status**: Todo

## Dependências

- **Depende de**: TASK-MMM-AAA | nenhuma
- **Bloqueia**: TASK-MMM-CCC | nenhuma

## Contexto

<1–2 linhas>

## Escopo

### Inclui
- <item>

### Não inclui
- <item adjacente>

## Critérios de pronto

- [ ] <critério observável>
- [ ] Testes cobrem AC-NNN-XXX — verificação executável: `<comando>` → <saída/efeito esperado>
- [ ] Sem warnings/lints novos

## Riscos específicos

- <opcional>

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
