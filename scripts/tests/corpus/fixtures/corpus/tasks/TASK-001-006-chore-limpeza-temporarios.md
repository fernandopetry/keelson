# TASK-001-006: Limpar temporários da geração

**Slug**: corpus
**Pertence a**: PLAN-001
**Componente**: COMP-001-002
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: chore/corpus-limpeza-temporarios
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-004
- **Bloqueia**: nenhuma

## Contexto

A geração deixa arquivos intermediários no diretório de trabalho; a limpeza roda
ao fim de cada geração concluída ou falhada.

## Escopo

### Inclui

- Remoção dos intermediários ao fim da geração, nas duas saídas

### Não inclui

- Retenção dos arquivos finais (política fora deste documento na SPEC)

## Implementação sugerida

Bloco de finalização único no gerador, executado em sucesso e em falha.

## Critérios de pronto

- [ ] Diretório de trabalho vazio após geração concluída — verificação executável: `make test` → caso do diretório pós-sucesso verde
- [ ] Diretório de trabalho vazio após geração falhada — verificação executável: `make test` → caso do diretório pós-falha verde

## Riscos específicos

Nenhum além dos do PLAN.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
