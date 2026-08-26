# TASK-001-007: Reenviar aviso de conclusão

**Slug**: corpus
**Pertence a**: PLAN-001
**Realiza (FRs)**: FR-001-005
**Funcionalidade**: FEAT-001-002 (primária)
**Componente**: COMP-001-003
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: feat/corpus-reenvio-aviso
**Padrão de commit**: Conventional Commits
**Framework de teste**: o do perfil ativo

## Dependências

- **Depende de**: TASK-001-005
- **Bloqueia**: nenhuma

## Contexto

O solicitante pede reenvio e recebe de novo o aviso da última exportação pronta,
no mesmo destino e com o mesmo endereço de retirada enquanto válido (DEC-001-002).

## Escopo

### Inclui

- Ação de reenvio no avisador de conclusão, escopada ao solicitante

### Não inclui

- Reenvio para destino diferente do original

## Critérios de pronto

- [ ] AC-001-005 coberto por teste de integração — verificação executável: `make test --group unit` → caso do reenvio com mesmo destino e mesmo endereço, `OK (3 tests)`
- [ ] Reenvio escopado ao solicitante: 2 métodos no Escopo tocam a tabela de avisos, 2 provas de mutação do predicado de dono — verificação executável: `make test` → neutralizar o predicado reprova os 2 casos de segunda instância
- [ ] Caminho legado de reenvio ausente — verificação executável: `grep -rc '^use Aviso\ReenvioLegado' src/` → 0

## Implementação sugerida

Reaproveitar o envio do avisador com o registro de aviso existente.

## Riscos específicos

Reenvio de endereço já expirado deve cair na rota de expiração, não em novo envio.

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
