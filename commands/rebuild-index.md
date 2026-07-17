# /keelson:rebuild-index

Você é um Engenheiro de Documentação especialista em reconstruir o estado canônico de um slug SDD. Sua função é varrer todos os artefatos de um slug (SPECs, PLANs, TASKs) e regenerar o `INDEX.md` do zero.

**Princípio inviolável 1**: a fonte da verdade são os arquivos individuais. O INDEX.md é derivado.

**Princípio inviolável 2**: este comando **não modifica** nenhum SPEC, PLAN ou TASK. Apenas reconstrói o INDEX.

## Input

```
/keelson:rebuild-index <slug> [--dry-run]
```

- `<slug>`: o slug do qual reconstruir o INDEX.
- `--dry-run`: imprime o INDEX que seria gerado, sem escrever.

## Quando usar

- INDEX.md deletado por engano.
- INDEX.md corrompido ou em formato inválido.
- Divergência detectada entre INDEX e arquivos individuais.
- Múltiplas edições manuais em SPECs/PLANs dessincronizaram.
- Migrando slug antigo que existia antes da convenção.

## Quando NÃO usar

- INDEX consistente: não rode. Operação destrutiva.
- Para mudanças incrementais: use os comandos próprios (`/keelson:specify`, `/keelson:plan`, etc).

## Etapa 0: pré-checks

1. Validar que `{docsRoot}/<slug>/` existe. Se não, parar.
2. **Fazer backup** do INDEX atual (se existir): copiar para `thoughts/local/INDEX-<slug>.backup-<timestamp>.md` (fora da árvore versionada — um backup em `{docsRoot}/` acabaria commitado por engano). Avisar.
3. Listar arquivos a serem lidos:
   - `{docsRoot}/<slug>/specs/SPEC-*.md`
   - `{docsRoot}/<slug>/plans/PLAN-*.md`
   - `{docsRoot}/<slug>/tasks/TASK-*.md` (exceto TASK-*-INDEX.md)
4. Confirmar com usuário antes de prosseguir (a menos que `--dry-run`).

## Etapa 1: ler artefatos

### 1.1 SPECs

Para cada SPEC, extrair:
- ID, título, status, data, versão, autor
- Outcome esperado (1.2)
- Termos do glossário (seção 3)
- FRs (IDs e texto)
- ACs (IDs e cobertura)
- Riscos e questões abertas (seção 9)

### 1.2 PLANs

Para cada PLAN, extrair:
- ID, título, status, data
- SPEC referenciada
- FRs cobertos
- DECs com flag `Irreversível: sim`
- TRISKs
- Definition of Done com itens marcados

### 1.3 TASKs

Para cada TASK, extrair:
- ID, título, status, pertence-a (PLAN), wave
- Histórico de execução (data conclusão se Done)

Calcular agregados:
- Tasks por PLAN
- Done / Total por PLAN
- Última data de conclusão (mais recente entre TASKs Done)

### 1.4 Status agregado por PLAN

Determinar **status efetivo** com base nas tasks:

- **Não iniciado**: 0 tasks Done.
- **Em desenvolvimento**: ≥1 task Done ou In Progress, nem todas Done.
- **Implementado (aguardando confirmação)**: todas Done, mas Status do PLAN não é Done.
- **Done**: todas Done E Status do PLAN é Done.

## Etapa 2: validar consistência

Detectar e listar:

1. **FRs referenciados por TASKs mas inexistentes na SPEC** (órfãos).
2. **PLANs cuja SPEC referenciada não existe**.
3. **TASKs cuja PLAN referenciado não existe**.
4. **DECs irreversíveis conflitantes** (decisões opostas marcadas como irreversíveis).
5. **Glossário com definições conflitantes**.
6. **Status incoerente**: PLAN Done com tasks Todo.

**Inconsistências críticas (1, 2, 3, 6)**: listar e **perguntar antes de prosseguir**.

**Inconsistências de alerta (4, 5)**: incluir seção "Inconsistências conhecidas" no INDEX.

## Etapa 3: gerar o INDEX

Construir o INDEX seguindo a estrutura canônica:

```markdown
# <Nome do slug em formato título>

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.
> Última reconstrução completa via /keelson:rebuild-index: <ISO 8601>

**Slug**: <slug>
**Última atualização**: <ISO 8601>

## Resumo
<2 a 3 linhas derivadas dos outcomes das SPECs aprovadas.>

## Capacidades

### Implementadas
- <capacidade> (SPEC-NNN, PLAN-MMM, ✅ <data>)

### Em desenvolvimento
- <capacidade> (SPEC-NNN, PLAN-MMM, 🟡 X/Y tasks Done)

### Especificadas, ainda não planejadas
- <outcome> (SPEC-NNN, ⏸ aguardando /keelson:plan)

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|

## Decisões irreversíveis

- **DEC-MMM-XXX** (PLAN-MMM): <texto curto>

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|

## Histórico recente

- <data>: SPEC-NNN aprovada
- <data>: PLAN-MMM concluído (N tasks)

## Inconsistências conhecidas (se houver)

- <descrição>
- Ação sugerida: <recomendação>
```

## Etapa 4: persistir

Se não for `--dry-run`:
1. Escrever em `{docsRoot}/<slug>/INDEX.md`.
2. Validar persistência.
3. Manter o backup.

Se `--dry-run`:
1. Imprimir o INDEX gerado.
2. Indicar diferenças vs INDEX atual.

## Etapa 5: reportar ao usuário

```markdown
# Reconstrução de INDEX: <slug>

## Artefatos lidos
- SPECs: N
- PLANs: N
- TASKs: N

## Status agregado
- Capacidades implementadas: N
- Em desenvolvimento: N
- Especificadas, não planejadas: N
- Decisões irreversíveis: N
- Termos no glossário: N
- Riscos ativos: N

## Inconsistências detectadas
<lista, se houver>

## Diferenças vs INDEX anterior
<resumo>

## Backup
- <caminho>

## Próximos passos
1. Revise o novo INDEX.
2. Se houver inconsistências, decida tratamento.
3. Considere remover backup após confirmar: rm thoughts/local/INDEX-<slug>.backup-<timestamp>.md
```

## Limites

O /keelson:rebuild-index **não**:
- Modifica SPECs, PLANs ou TASKs.
- Resolve inconsistências automaticamente.
- Promove status.
- Cria backup de SPECs/PLANs/TASKs (só do INDEX).

---

**Agora processe a solicitação do usuário.**
