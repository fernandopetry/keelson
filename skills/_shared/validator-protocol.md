# Protocolo comum dos validators (spec / plan / task)

> Fonte única da moldura compartilhada pelas skills `spec-validator`, `plan-validator` e
> `task-validator`. Cada SKILL.md contém apenas os checks próprios do seu artefato e
> aponta para cá ("protocolo §N").

## §1. Calibração por exemplares (antes de reprovar por convenção)

O padrão-ouro vivo são os artefatos **aprovados/mergeados** do projeto (SPECs aprovadas,
PLANs aprovados, TASKs Done de PLANs mergeados). Se um check de convenção diverge da
prática real de 2–3 deles, suspeite da regra, não do artefato: não gere ERROR; emita
`evento_aprendizado` de falso positivo (§6).

## §2. Setup

1. Ler a **ficha** (`keelson.config.json` na raiz): `docsRoot` resolve todo caminho
   `{docsRoot}/...` (sem ficha, assumir `docs/`); `profile.<role>.file` aponta o perfil
   de linguagem ativo — fonte **primária** de stack/convenções (a mesma de que o comando
   gerador gera).
2. Ler o artefato-alvo e o contexto que a SKILL lista.
3. Ler `CLAUDE.md` se existir — fonte **complementar**: ausência dele, ou omissão de uma
   convenção nele, nunca gera ERROR.
4. Inicializar as listas `errors`, `warnings`, `infos`, `auto_fixes_applied`.

## §3. Severidades e auto-fix

- **ERROR** bloqueia (gate de status, §4). **WARNING** não bloqueia, mas pede revisão.
  **INFO** é informativo.
- Violação trivial e segura (case de RFC 2119, zero-padding, acentuação de campo) recebe
  **auto-fix sem confirmação**: aplicar no arquivo e registrar
  `<linha>: <antes> → <depois>` em `auto_fixes_applied`.

## §4. Gate de status e override

Após os auto-fixes, recontar `errors`:

- `errors` não-vazia e Status `Approved` → forçar Status para `Draft` e registrar no
  artefato uma seção `## Histórico de validação` com data e motivo. (TASK: com ERROR ela
  não é executável pelo `/keelson:implement`; Status `Todo` é forçado para `Blocked`.)
- `errors` vazia → o artefato **pode** ser promovido; a promoção de Status é sempre
  **manual**.

Override consciente, declarado no próprio artefato:

```yaml
override-erros: <IDs>
override-justificativa: <texto>
override-aprovador: <nome>
```

Respeite o override com justificativa; mantenha o ERROR no relatório com flag `OVERRIDDEN`.

## §5. Relatório

```markdown
# Relatório de validação: <ID do artefato>

**Arquivo**: <caminho>
**Status atual**: <status>
**Resultado**: PASSOU | PASSOU COM RESSALVAS | BLOQUEADO

## Resumo
- Errors: N (M corrigidos, K pendentes) | Warnings: N | Infos: N

## Auto-fixes aplicados
- linha 12: `[must]` → `[MUST]`

## Errors pendentes
- **[<ID/check>]** <violação>.
  Sugestão: <ação>

## Warnings / Infos
- ...

## Próximos passos
1. Resolver errors pendentes e validar novamente
2. Quando errors == 0, promover Status manualmente
```

Múltiplos artefatos no input → validar em sequência e consolidar num relatório só.

## §6. Evento de aprendizado (telemetria do processo)

Se o artefato validado foi **recém-gerado por um comando do keelson** (não escrito/editado
por humano) e restou ERROR não auto-corrigível, acrescente ao relatório um bloco para a
main session rotear ao `process-tuner`:

```yaml
evento_aprendizado:
  gatilho: validator_error
  descricao: <qual ERROR o gerador produziu>
  causa_raiz: <que instrução do gerador faltou/foi ambígua>
  artefato_suspeito: commands/<comando-gerador>.md
```

Falso positivo recorrente do próprio validator também é evento (`artefato_suspeito`: a
própria skill).

## §7. Limites

Nenhum validator valida **mérito**: se o artefato ataca o problema certo, se a escolha
técnica é a melhor, se a granularidade é a ideal. Forma e consistência, não estratégia.
Validators também não reescrevem o artefato — reportam, sugerem e aplicam só auto-fix
óbvio e seguro (§3).
