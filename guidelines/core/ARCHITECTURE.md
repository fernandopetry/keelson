# Arquitetura (core)

> Doutrina de arquitetura **agnóstica de linguagem**. Instancia principalmente o
> **Art. 4** (limites claros, responsabilidade única) e o **Art. 5** (nomear pela
> intenção) do `../_meta/QUALITY-CHARTER.md` — leia-os antes. Aqui ficam os
> **conceitos concretos** de como estruturar o código; os nomes de camada, pastas e
> convenções **específicos da stack** vivem no perfil de linguagem
> (`../backend/*.md`, `../frontend/*.md`), e os do projeto em `guidelines/project/`.

---

## A regra da dependência (camadas como conceito)

Organize o código em **camadas com uma direção de dependência única**: as dependências
apontam **para dentro**, na direção da regra de negócio. O núcleo de domínio não conhece
o framework, o banco, a rede, nem o mecanismo de entrega (HTTP, CLI, fila). Detalhes de
tecnologia ficam nas bordas e implementam **abstrações que o domínio define**.

Os nomes abaixo são conceituais — cada perfil dá o nome idiomático da sua stack.

| Responsabilidade | ✅ PODE | ❌ NÃO PODE |
|------------------|---------|-------------|
| **Entrega / Apresentação** | Receber requisição/evento, traduzir para o núcleo, formatar a saída | Regra de negócio; I/O direto (banco, rede) |
| **Aplicação / Orquestração** | Coordenar o fluxo de um caso de uso, chamando o domínio | Conhecer o mecanismo de entrega ou os detalhes de I/O |
| **Domínio** | Entidades, regras, invariantes, **portas** (interfaces) | Framework, banco, HTTP, qualquer detalhe externo |
| **Infraestrutura / Adaptadores** | Implementar as portas do domínio (persistência, rede, serviços externos) | Regra de negócio |

**Fluxo típico:** `requisição/evento → entrega → caso de uso → domínio → porta → adaptador`,
e a resposta volta pelo mesmo caminho, formatada só na borda de entrega. A camada de
apresentação (seja de backend ou de UI) **nunca** faz I/O direto: quem fala com o mundo
externo é sempre uma camada dedicada, atrás de uma abstração.

- **Régua (Charter Art. 4):** a regra de negócio pode ser testada sem levantar o mundo
  inteiro; trocar um detalhe (driver, framework, view) não obriga a reescrever o domínio.

---

## SOLID (limites em cinco princípios)

Os cinco princípios SOLID se aplicam (conhecimento canônico — sem redefinição aqui). O
fio comum: cada um empurra a mudança para ser **local e barata de raciocinar** — a mesma
meta do Art. 4.

---

## Onde o estado mora (local vs. compartilhado)

Estado tem custo de acoplamento proporcional ao seu alcance. Mantenha-o no menor escopo
que resolve o problema e **promova só quando necessário**:

| Situação | Onde |
|----------|------|
| Estado usado por 1–2 unidades próximas | Local (na própria unidade) |
| Estado compartilhado por 3+ unidades / cache de I/O | Compartilhado (store/serviço dedicado) |

Estado global implícito é efeito colateral disfarçado — trate-o como I/O: explícito e
isolável (ver abaixo).

---

## Padrões de projeto: vocabulário, não objetivo

Um padrão nomeia uma **solução para uma dor** — nunca se aplica um padrão para "seguir boas
práticas". Três perguntas antes de introduzir qualquer padrão (Charter Art. 4):

1. **A dor existe agora, neste diff?** Se é antecipação ("pode variar no futuro"), não aplique.
2. **A linguagem tem construção idiomática mais simples** que o padrão clássico? O perfil de
   linguagem responde — muitos padrões viraram feature nativa.
3. **A escolha molda componentes ou contratos?** Então é uma **DEC no PLAN**, com a
   alternativa mais simples (sem o padrão) entre as descartadas.

Mapa mínimo dor → padrão (o perfil dá a forma idiomática):

| Dor presente | Padrão |
|--------------|--------|
| Condicional que despacha pela mesma variante em vários pontos (Art. 7) | Polimorfismo (Strategy/State) |
| Construção complexa com invariantes a garantir | Fábrica |
| Dependência de serviço externo / I/O | Porta + adaptador (regra da dependência) |
| Vários interessados desconhecidos num acontecimento | Eventos (observer) |
| Contrato de terceiro incompatível com o do domínio | Adapter |

**Armadilhas por default:** Singleton e estado estático mutável (é o "estado global
implícito" acima, com nome próprio); herança para reuso de código (prefira composição);
camada ou abstração genérica "para o futuro" (viola o Art. 4).

*Resiliência distribuída* (circuit breaker, retry + idempotência, saga, outbox) é domínio
de `guidelines/project/` e de DECs.

---

## Invariantes do projeto — `guidelines/project/invariants.md` (opt-in, decisão 4.242)

Restrições de produto ou arquitetura que **devem permanecer verdadeiras em qualquer
demanda** e que **não nascem de um PLAN** — vêm do negócio, de compliance ou de operação
(ex.: "saldo de carteira nunca fica negativo", "a tabela de auditoria é append-only",
"resposta pública nunca expõe id interno"). O que nasce de um PLAN continua **DEC
irreversível no INDEX do slug** — este arquivo não a duplica. Na dúvida, a fronteira é um
teste: *a restrição existiria mesmo que aquele PLAN nunca tivesse sido escrito?*

- **Formato**: um invariante por bullet, enunciado **falsificável** — dá para apontar um
  diff que o viola. Regra vaga ("o código deve ser seguro") não entra.
- **Quem escreve**: o Diretor (ou o time, com o Diretor de acordo). O keelson **lê, não
  gera** — arquivo ausente significa que o projeto ainda não declarou invariantes.
- **Quem lê** (sempre condicional — só quando o arquivo existe): a Etapa 3 do
  `/keelson:plan` e o gate 6 do code review. Ausente → `n/a (sem invariants.md)`
  **declarado**, nunca aprovação silenciosa.

---

## Convenções do projeto — `guidelines/project/conventions.md` (opt-in, decisão 4.493)

Como **esta casa** faz cada ato de código — onde mora, qual esqueleto segue, como se
nomeia, que camada chama e onde fica o teste — para tela, componente, endpoint,
serviço, dados, job, teste e config. O perfil de linguagem diz como a linguagem faz;
este arquivo diz o que só vale aqui. A fronteira é um teste: *outro projeto na mesma
linguagem faria igual?* Se sim, é perfil; se não, é convenção da casa.

- **Formato**: uma seção `## <ato>` por ato; uma entrada por linha,
  `- [<aaaa-mm-dd> · <origem>] <fato> — <arquivo>:<linha>`. A origem é `código`
  (medida, com âncora obrigatória) ou `Diretor` (decidida na entrevista, sem âncora).
  Entrada que perdeu validade vira `[<data> · revogada] <fato> — <motivo>` no fim da
  seção; nada é apagado. A data é a da **medição**, para a idade ficar visível.
- **Corte**: só entra o que o perfil não diz e vale para qualquer demanda. Regra
  idiomática da linguagem é perfil; o que nunca pode mudar é `invariants.md`; defeito
  corrigido é lição (`lessons/`); fato de um slug é MAP. O arquivo cabe numa leitura —
  seção que vira inventário de arquitetura perdeu o corte.
- **Quem escreve**: `/keelson:conventions` (humano-only), medindo no código via
  `code-scout` e perguntando ao Diretor só o que o código não fecha; o Diretor revisa e
  commita. Edição à mão é bem-vinda — a origem `Diretor` existe para isso.
- **Quem lê** (sempre condicional — só quando o arquivo existe): o `developer` ao
  carregar contexto (a seção do ato que a task faz vale como o perfil), o gate 6 do
  code review (lugar, esqueleto, nome e camada do diff batem com a entrada do ato), a
  forja de TASKs (caminho e nome de arquivo novo no Inclui conferidos contra a entrada)
  e a Etapa 3 do `/keelson:plan` (desenho que contraria uma entrada declara a
  alternativa numa DEC, nunca em silêncio). Ausente → `n/a (sem conventions.md)`
  **declarado**; os leitores seguem o vizinho (seção abaixo).
- **Lição que revela convenção**: lição `alvo: projeto` de lugar, esqueleto, nome ou
  camada tem este arquivo como artefato de doutrina designado — a closure grava a
  linha aqui também, no formato acima, além da lição.

---

## Nomear seguindo o vizinho

Antes de nomear um tipo, arquivo, tabela ou coluna, **leia 2–3 vizinhos do mesmo
cluster** e copie o estilo. A pergunta nunca é "que nome eu prefiro?", é "como os
vizinhos se chamam?". Convenção consistente é o que faz código novo **ler como** o código
existente (Charter Art. 5).
