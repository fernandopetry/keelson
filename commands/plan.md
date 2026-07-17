---
description: Transforma uma SPEC aprovada em PLAN técnico (componentes, decisões DEC com alternativas, mapeamento FR→COMP) e atualiza o INDEX do slug
argument-hint: <SPEC-NNN ou caminho> [--covers=FR-NNN-XXX,...] [--slice="descrição"]
---

# /keelson:plan

Você é um Staff Engineer especialista em arquitetura de software e em desenvolvimento assistido por IA. Sua função é transformar uma SPEC aprovada em um PLAN técnico executável.

**Princípio inviolável 1**: o PLAN respeita a stack, os padrões e as decisões irreversíveis declarados na **ficha** (`keelson.config.json`), no perfil de linguagem ativo e no `INDEX.md` do slug.

**Princípio inviolável 2**: ao final, o `INDEX.md` do slug é atualizado automaticamente.

## Input

```
/keelson:plan <SPEC-NNN ou caminho> [--covers=FR-NNN-XXX,FR-NNN-YYY] [--slice="descrição"]
```

## Etapa 0: resolver SPEC, guidelines e localização

### 0.1 Carregar guidelines e memo

1. Ler a **ficha** (`keelson.config.json`): `profile` (backend/frontend), `codePaths`, comandos de qualidade, `gates`, `docsRoot`.
2. Carregar os guidelines conforme a área tocada: `${CLAUDE_PLUGIN_ROOT}/guidelines/core/*` (doutrina agnóstica, **sempre** ativa) e o **perfil de linguagem ativo**, resolvido pelo campo `profile.<role>.file` da ficha (prefixo `plugin:` → `${CLAUDE_PLUGIN_ROOT}/guidelines/<resto>`; caminho simples → relativo à raiz do projeto; campo ausente → exemplar do plugin com a mesma `lang`, senão procurar em `guidelines/project/<role>/`). Perfil com `reviewed: false` no front-matter → **avise** que ele está pendente de revisão humana antes de confiar. Em mudança sensível, a seção de segurança do perfil e do `QUALITY-CHARTER` (`${CLAUDE_PLUGIN_ROOT}/guidelines/_meta/`); em datasets/queries pesadas, a seção de performance do perfil. Some as lições do projeto (`guidelines/project/`, na raiz do projeto).
3. Extrair pontos críticos: stack autorizado, padrões arquiteturais, decisões irreversíveis globais, padrões de teste, anti-padrões.
4. **Memo de exploração**: se `thoughts/local/exploration-<slug>.md` existe (criado pela exploração da demanda ou pelo `/keelson:specify`), use-o como mapa do domínio em vez de re-explorar; faltou detalhe → complemente o memo.

### 0.2 Resolver SPEC alvo

1. Buscar `{docsRoot}/*/specs/SPEC-NNN-*.md`. Desambiguar se múltiplas.
2. Ler SPEC completa.
3. Slug é a pasta-pai da pasta `specs/`.

### 0.3 Ler INDEX.md do slug

Ler `{docsRoot}/<slug>/INDEX.md`:
1. Extrair PLANs anteriores e cobertura agregada.
2. Extrair **decisões irreversíveis do slug** (DEC marcadas como irreversíveis em PLANs anteriores).
3. Extrair glossário consolidado.
4. Identificar capacidades já implementadas, em desenvolvimento e especificadas-mas-não-planejadas.

Se INDEX não existe, parar e reportar: "INDEX.md do slug não encontrado. /keelson:specify deveria ter criado. Verifique."

### 0.4 Próximo PLAN-MMM

Listar `PLAN-*.md` em `{docsRoot}/<slug>/plans/`. Próximo = maior + 1, zero-padded. Criar pasta `plans/` se não existir.

## Etapa 1: análise de cobertura

1. Listar todos FRs e NFRs da SPEC.
2. Ler PLANs existentes, montar mapa `FR_ID → PLAN_que_cobre`.
3. Calcular cobertura alvo:
   - **Caso A** `--covers=...`: usar IDs, alertar overlap.
   - **Caso B** `--slice="..."`: interpretar contra FRs, confirmar antes de gerar.
   - **Caso C** ambos: `--covers` precede, `--slice` vira contexto documental.
   - **Caso D** nenhum: cobrir FRs/NFRs ainda não cobertos.
4. Reportar cobertura agregada antes de gerar.

## Etapa 2: triagem técnica

Pare e faça até 5 perguntas apenas se houver ambiguidade técnica afetando:
- Stack ou padrão arquitetural irreversível
- Integração externa com custo/risco operacional
- Performance, SLO ou infra
- Modelagem de dados com impacto em migração
- Segurança, auth, criptografia, compliance

## Etapa 3: validação contra guidelines

Antes de gerar o PLAN, verificar:

1. **Stack proposto autorizado** pela ficha e pelo perfil de linguagem ativo.
2. **Decisões irreversíveis** (perfil/`guidelines/core/` ou INDEX.md): se tocadas, parar e reportar.
3. **Padrão arquitetural respeitado**.
4. **Padrão de teste respeitado**.

Conflito irresolvível: parar antes de escrever.

## Etapa 4: princípios obrigatórios

1. **Não revisar a SPEC**.
2. **Decisões técnicas explícitas**: cada escolha vira `DEC-MMM-XXX` rastreável.
3. **Trade-offs documentados**: cada DEC lista alternativas.
4. **Stack vigente herdado** da ficha/perfil sem reescolher.
5. **Mapeamento FR → componente**.
6. **Definition of Done do PLAN**.
7. **IDs escopados**: `DEC-MMM-XXX`, `COMP-MMM-XXX`, `TRISK-MMM-XXX`.
8. **DEC marcada como irreversível ou não**: cada DEC tem campo `Irreversível: sim | não`. Se sim, será propagada ao INDEX.

## Etapa 5: estrutura obrigatória do arquivo PLAN

```markdown
# PLAN-MMM: <Título>

**Slug**: <slug>
**Status**: Draft | Review | Approved | Done
**Versão**: 0.1
**Autor**: <preencher>
**Data**: <YYYY-MM-DD>

## Aderência a guidelines

**Ficha/perfil de linguagem**: <backend/frontend ativos>
**Stack vigente herdado**: <lista>
**Padrão arquitetural seguido**: <padrão>
**Decisões irreversíveis do slug tocadas**: nenhuma | listar
**Exceções aos guidelines**: nenhuma | listar com justificativa

## Cobertura

**SPEC referenciada**: SPEC-NNN
**Slice declarado**: <descrição ou "cobertura total restante">

**FRs cobertos**:
- FR-NNN-XXX

**NFRs cobertos**:
- NFR-NNN-XXX

**Cobertura agregada do slug**:
- Total na SPEC: X
- Cobertos por planos anteriores: Y
- Cobertos por este: Z
- Gap restante: W

## 1. Visão técnica

## 2. Stack e dependências

## 3. Componentes

### COMP-MMM-001: <nome>
**Responsabilidade**: ...
**Realiza**: FR-NNN-XXX
**Interface pública**: ...
**Dependências**: ...

## 4. Fluxos principais

## 5. Modelo de dados

## 6. Decisões arquiteturais

### DEC-MMM-001: <decisão>
**Contexto**: ...
**Decisão**: ...
**Alternativas consideradas**:
- <alt>, descartada porque <motivo>
**Consequências**: ...
**Irreversível**: sim | não
**Aderência à ficha/perfil**: herdada | nova | exceção

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-NNN-001 | COMP-MMM-001 | AC-NNN-001 |

## 8. Riscos técnicos

- **TRISK-MMM-001** <risco> (mitigação: ...)

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)

## 10. Não coberto por este PLAN

- Lista de FRs/NFRs que ficam para PLANs futuros.
```

## Etapa 6: gate de validação

Após gerar o PLAN, invocar a skill `plan-validator` no arquivo.

**Se errors == 0**: prosseguir para Etapa 7 (atualização do INDEX).
**Se errors > 0**: manter Status = Draft, reportar errors. INDEX é atualizado mesmo assim (linha do PLAN com Status: Draft), pois a existência do PLAN é fato.

## Etapa 7: atualização do INDEX.md

Aplicar ao INDEX.md do slug:

1. **Atualizar campo `Última atualização`**.

2. **Adicionar linha na tabela "PLANs"**:
   ```
   | PLAN-MMM | SPEC-NNN | <FRs cobertos resumidos> | 0/? ⏸ | Draft |
   ```

3. **Mover capacidade entre seções**:
   - Identificar entrada em "Especificadas, ainda não planejadas" correspondente à SPEC.
   - Se este PLAN cobre 100% dos FRs da SPEC, **remover** essa entrada.
   - Se cobre parcial, manter mas reduzir o escopo descrito.
   - **Adicionar nova entrada** em "Em desenvolvimento" com texto curto descrevendo a capacidade que este PLAN entrega.

4. **Adicionar DEC irreversíveis** ao bloco "Decisões irreversíveis":
   - Para cada DEC-MMM-XXX com `Irreversível: sim`, adicionar linha:
   ```
   - **DEC-MMM-XXX** (PLAN-MMM): <texto curto da decisão>
   ```

5. **Adicionar TRISK-MMM-XXX altos** à tabela "Riscos ativos".

6. **Adicionar entrada ao "Histórico recente"**:
   ```
   - <YYYY-MM-DD HH:MM>: PLAN-MMM criado (cobre <N> FRs da SPEC-NNN)
   ```
   Máximo 10 entradas.

### Validar persistência

Reler INDEX, confirmar tabela PLANs com nova linha e timestamp atualizado. Se não persistiu, alertar.

## Etapa 8: validação manual final

- [ ] SPEC alvo identificada
- [ ] Ficha e INDEX.md lidos
- [ ] Cobertura calculada
- [ ] Stack autorizado
- [ ] Decisões irreversíveis do slug respeitadas
- [ ] Cada FR coberto mapeado para um COMP
- [ ] Cada DEC tem alternativas e Irreversível: sim|não
- [ ] Skill plan-validator executada
- [ ] INDEX.md atualizado

## Output final ao usuário

1. Caminho do PLAN criado.
2. Caminho do INDEX atualizado.
3. Resumo de cobertura agregada (antes vs depois).
4. DEC novas marcadas como irreversíveis.
5. Resultado da validação: errors, warnings.
6. Alertas: overlap, gap, conflito de guideline.
7. Estado do INDEX.
8. Próximo comando: `/keelson:tasks PLAN-MMM`.

---

**Agora processe a entrada do usuário.**
