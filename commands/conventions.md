---
description: 'Entrevista de convenções da casa — mede no código onde cada ato mora (tela, endpoint, serviço, dados), mostra a prévia "se eu fizesse X, faria assim", pergunta só o que o código não fecha e grava guidelines/project/conventions.md'
argument-hint: "[--dry-run | --refresh]"
disable-model-invocation: true
---

# /keelson:conventions

Você é o **Tech Lead** conduzindo a entrevista de convenções do projeto. O Diretor roda
este comando quando quer que o time pare de errar lugar, esqueleto, nome e camada do
que escreve. A matéria-prima é o **código existente**: o perfil de linguagem diz como a
linguagem faz; este comando descobre como **esta casa** faz, e grava o que descobriu em
`guidelines/project/conventions.md` para o developer, os gates e a forja de TASKs lerem
em toda demanda. O formato do arquivo, a régua de corte e quem o lê têm dono único:
`${CLAUDE_PLUGIN_ROOT}/guidelines/core/ARCHITECTURE.md` (seção *Convenções do projeto*,
decisão 4.493) — leia-a antes de começar; este comando não a replica.

**Princípio inviolável 1 — medido, nunca deduzido.** Cada resposta da prévia tem
origem: `código` (âncora `arquivo:linha` que o `code-scout` devolveu) ou `Diretor`
(ele escolheu ou escreveu). Resposta sem uma das duas não entra no arquivo. "Não
encontrado" é resposta válida do reconhecimento e vira pergunta — nunca é preenchido
com o que seria plausível.

**Princípio inviolável 2 — pergunta só o que o código não fecha.** Ato com um padrão
único no código não gera pergunta: vai direto para a prévia. Pergunta nasce de dois
padrões concorrentes ou de ausência. Entrevista que pergunta o que o código já responde
custa a atenção do Diretor e ensina o modelo a não medir.

**Princípio inviolável 3 — nada se grava sem o OK, nada se sobrescreve às cegas.** A
prévia é o contrato; o Diretor ajusta até dizer "grava". Arquivo existente muda por
entrada, com o diff de cada uma mostrado antes — sobrescrever o que o time revisou é o
pior defeito deste comando.

## Input

```
/keelson:conventions [--dry-run | --refresh]
```

- `--dry-run`: reconhecimento, entrevista e prévia completos; nada é escrito.
- `--refresh`: arquivo já existe — re-mede cada entrada de origem `código` contra a árvore
  atual (âncora viva? padrão ainda único?) e só então segue para a entrevista das que
  mudaram. Sem a flag, arquivo existente entra em modo **delta**: atos ainda sem entrada
  são medidos; os que já têm entrada são mostrados como estão.

## Quando usar

- Logo depois do `/keelson:init` (o relatório dele sugere), antes da primeira demanda.
- Quando o Diretor corrigiu "não é nessa pasta / não é assim que se faz tela aqui" mais
  de uma vez — a correção é lição (`lessons/`); a convenção que ela revela mora aqui.
- Depois de reorganização do código (`--refresh`): a entrada envelhece com a árvore.

## Quando NÃO usar

- Para declarar o que **nunca pode mudar** no produto: isso é `invariants.md` (régua em
  `ARCHITECTURE.md`, 4.242). Convenção diz *como se faz*; invariante diz *o que não se
  viola*.
- Para registrar um defeito corrigido: lição nasce de correção, pela closure do ciclo.
- Para documentar um slug: território por demanda é o MAP (`map-contract.md`).

## Etapa 0: pré-checks

1. Ficha (`keelson.config.json`): `codePaths`, `profile.backend`/`profile.frontend`
   (qual camada existe define quais atos do catálogo se aplicam — projeto sem
   frontend não tem ato *tela*) e `docsRoot`. Sem ficha → "rode `/keelson:init`" e pare.
2. Perfil ativo de cada camada: leia as seções **§3 Nomenclatura**, **§4 Estrutura** e
   **§9 Reúso**. São o que o arquivo novo **não** repete — a régua de corte do dono.
3. `guidelines/project/conventions.md` existe? → modo delta (ou `--refresh`). Leia-o.
4. Recorte das lições que já falam de lugar/esqueleto/nome:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lessons.sh" . match --tags arquitetura,estrutura,nomenclatura`
   (o recorte é inclusivo: lição sem `paths` entra sempre — leia só as que falam de
   lugar, esqueleto ou nome). Lição ativa que fixa um lugar ou padrão é **fato a favor**
   da entrada correspondente e aparece na prévia como origem `código` com a âncora da
   lição.

## Etapa 1: reconhecimento (code-scout, uma vez por camada)

Despache o **`code-scout`** (decisão 4.73) — um por camada da ficha, em paralelo quando
há duas — com o **catálogo de atos** abaixo e, para cada ato, as cinco perguntas. Ele
devolve conclusão ancorada; você não varre o código na main session.

Catálogo de atos (fechado — a ficha não o estende; ato que não existe no projeto sai
como `n/a`):

| Ato | Exemplo do que o Diretor pede |
|---|---|
| **tela** (página/rota) | "cria uma tela de listagem de clientes" |
| **componente** de UI reutilizável | "um seletor de período para reusar nas telas" |
| **endpoint** (API/controller/action) | "expõe um endpoint de exportação" |
| **serviço** (regra de negócio/caso de uso) | "calcula a comissão" |
| **dados** (modelo/entidade, repositório, migração) | "adiciona uma coluna" |
| **job** (fila, agendado, evento) | "roda o fechamento à noite" |
| **teste** (unitário, integração, E2E) | sempre: o par de qualquer ato acima |
| **config** (feature flag, env, parâmetro) | "liga isso só em homologação" |

As cinco perguntas por ato:

1. **Onde mora** — diretório e padrão de caminho (`src/pages/<Dominio>/<Nome>Page.vue`).
2. **Esqueleto** — o arquivo-exemplar que melhor representa a estrutura em vigor, com as linhas
   que mostram a estrutura (layout + tabela + filtro; controller → service → repository).
3. **Nome** — padrão de nome de arquivo e de símbolo (sufixo, prefixo, idioma, caso).
4. **Camada chamada** — o que esse ato pode chamar e o que não chama (tela chama
   composable, nunca o repositório; endpoint chama serviço, nunca o modelo).
5. **Par de teste** — onde mora o teste desse ato e como se chama.

O `code-scout` responde cada pergunta com um de três estados: **único** (um padrão
dominante, com 2–3 âncoras), **concorrentes** (dois ou mais padrões vivos, cada um com
âncora e contagem aproximada) ou **não encontrado** (nada na árvore responde). Estado
sem âncora não é estado — é "não encontrado".

## Etapa 2: entrevista (só o que ficou aberto)

Para cada pergunta em estado **concorrentes** ou **não encontrado**, uma pergunta ao
Diretor (`AskUserQuestion`), em rodadas de até 4, agrupadas por ato:

- **concorrentes** → as opções são os padrões encontrados, cada um com a âncora e a
  contagem ("`src/pages/` — 14 arquivos" · "`src/views/` — 3 arquivos, os mais recentes");
  a opção recomendada é a mais recente quando a contagem não decide, e a mais numerosa
  nos demais casos — diga qual critério usou.
- **não encontrado** → 3 sugestões vindas do perfil ativo (§4 e §9) adaptadas ao que
  a árvore já tem (pasta irmã existente, nome que os vizinhos usam), mais a opção livre.
  Deixe claro que a convenção **nasce agora**, por decisão do Diretor, e que a origem
  da entrada será `Diretor`.
- Não acrescente uma opção "outro": a ferramenta de pergunta já oferece a resposta
  livre. Resposta livre que cita um caminho é conferida na árvore antes da
  prévia (`test -e`); caminho inexistente é aceito como **declarado** (origem
  `Diretor`), com a nota de que ainda não existe.

Pergunta em estado **único** não é feita. Se o Diretor discordar de um "único" na
prévia (Etapa 3), ele corrige lá — a entrada troca de origem para `Diretor`.

## Etapa 3: prévia — "se eu precisasse fazer X, faria assim"

Monte e mostre, antes de escrever qualquer arquivo, um bloco por ato aplicável:

```markdown
### Se eu precisasse criar uma tela
- **Onde**: `src/pages/<Dominio>/<Nome>Page.vue` — src/pages/Clientes/ListaPage.vue:1 (código)
- **Esqueleto**: layout `PageShell` + tabela `DataGrid` + filtro no topo — src/pages/Pedidos/ListaPage.vue:12-80 (código)
- **Nome**: domínio em português, sufixo `Page`; componente em PascalCase — src/pages/Clientes/ListaPage.vue:1 (código)
- **Chama**: composable de `src/composables/` e store; nunca `src/api/` direto — src/pages/Pedidos/ListaPage.vue:5-9 (código)
- **Teste**: `tests/pages/<Dominio>/<Nome>Page.spec.ts` (Diretor — não existia; decidido na entrevista)
```

Regras da prévia:

- Toda linha termina com a origem entre parênteses: `(código)` com âncora, ou
  `(Diretor)` sem âncora. Linha sem origem é defeito do comando, não "opinião".
- Linha que repete o perfil ativo (regra idiomática da linguagem, não da casa) **sai**
  — a régua de corte é do dono. Na dúvida, pergunte-se: outro projeto na mesma
  linguagem faria igual? Se sim, é perfil, não convenção da casa.
- Mostre a prévia inteira e pergunte o que ajustar. Ajuste pedido → refaça o bloco
  tocado (origem vira `Diretor`) e mostre de novo. Repita até o OK explícito
  ("grava", "pode escrever", equivalente). `--dry-run` termina aqui, com a prévia.

## Etapa 4: gravar

- Destino: `guidelines/project/conventions.md`, no formato canônico do dono
  (`ARCHITECTURE.md`, seção *Convenções do projeto*): uma seção por ato, uma entrada
  por linha `[<data> · <origem>] <fato> — <âncora>`. A data é a de hoje (medição).
- **Arquivo novo** → escreva inteiro.
- **Modo delta** → acrescente só as seções/entradas novas; seção existente intocada.
- **`--refresh`** → para cada entrada existente de origem `código`: âncora morta
  (`test -e` falha) ou padrão já não único na re-medição → mostre
  `antes → depois` e grave só com OK; entrada de origem `Diretor` nunca é re-medida
  (é decisão, não medição) — apareça na prévia como está, para ele reafirmar ou mudar.
- Nunca reescreva entrada sem mostrar o diff dela. Nunca apague entrada: a que perdeu
  validade vira uma linha `[<data> · revogada] <fato antigo> — <motivo>` no fim da seção.
- O commit é do Diretor: o comando escreve, reporta e para.

## Etapa 5: report

```markdown
# Convenções do projeto: guidelines/project/conventions.md

- **Modo**: novo | delta | refresh | dry-run
- **Camadas**: backend (<perfil>) · frontend (<perfil>) | só backend
- **Atos medidos**: <N> aplicáveis · <N> n/a (<quais>)
- **Reconhecimento**: <N> perguntas únicas (sem entrevista) · <N> concorrentes · <N> não encontradas
- **Entrevista**: <N> perguntas feitas · <N> respondidas com opção · <N> com resposta livre
- **Entradas gravadas**: <N> origem código · <N> origem Diretor · <N> revogadas (refresh) | nenhuma (dry-run | sem OK)
- **Cortadas por repetir o perfil**: <N> (<ato: linha>)
- **Pendente de você**: commit do arquivo · <entradas declaradas cujo caminho ainda não existe> · nada
```

## Limites

Não escreve código nem cria os diretórios que uma entrada `Diretor` declara; não toca
perfil de linguagem, `invariants.md` nem `lessons/`; não documenta slug (MAP); não
commita. O que o Diretor pediu durante a entrevista e não é convenção (um defeito
visto de passagem, uma demanda) é devolvido no report como nota, nunca executado.
