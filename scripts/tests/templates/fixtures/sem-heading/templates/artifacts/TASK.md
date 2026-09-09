<!-- Template canônico do TASK (decisão 4.405). Dono da régua de forma: commands/tasks.md, Etapas 1–3. Comentários <!-- --> são instrução ao scribe, nunca conteúdo do artefato gerado. -->

# TASK-MMM-XXX: <Título imperativo>

**Slug**: <slug>
**Pertence a**: PLAN-MMM
**Realiza (FRs)**: FR-NNN-XXX, FR-NNN-YYY <!-- lista de IDs ou `nenhuma` (chore sem FR) -->
**AC violado**: AC-NNN-XXX <!-- só Tipo=bugfix: o AC que o bug viola; omitir a linha nos demais tipos -->
**Funcionalidade**: FEAT-NNN-XXX (primária)[, FEAT-NNN-YYY]
**Componente**: COMP-MMM-XXX (principal)[, COMP-MMM-YYY] <!-- os COMPs que a fatia atravessa; principal = onde vive o núcleo da mudança -->
**Wave**: <número>
**Tamanho estimado**: small | medium
**Tipo**: feature | bugfix | refactor | chore
**Status**: Todo

## Dependências

- **Depende de**: TASK-MMM-AAA, TASK-MMM-BBB <!-- lista de IDs ou `nenhuma` -->
- **Bloqueia**: TASK-MMM-CCC <!-- lista de IDs ou `nenhuma`; preencher após gerar todas -->

## Contexto

<3 a 5 linhas.>

## Escopo

### Inclui
- <item>

### Não inclui
- <item adjacente>


- [ ] <critério observável>
- [ ] Testes cobrem AC-NNN-XXX (listar ACs) — verificação executável: `<comando>` → <saída/efeito esperado>, fixada antes do código
- [ ] Sem warnings/lints novos <!-- sobre TODOS os arquivos do diff (`git diff --name-only main...HEAD`), produção e teste — condição, nunca arquivo nomeado de memória (4.321/4.369) -->

## Roteiro do gate 9 (fixado ANTES do código)

<!-- Só com gates.screenVerify ativo e AC atribuído ao gate 9 — régua na seção "Roteiro do gate 9" abaixo; sem gate 9, omitir. Ambiente (URLs digitáveis + realm) · sujeito concreto (identidade + credencial) · pré-condição com receita (montar + restaurar) · um passo por AC. -->

## Riscos específicos

- <opcional>

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: 
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
