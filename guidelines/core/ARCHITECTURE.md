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

- **S — Responsabilidade única:** cada unidade tem **um** motivo para mudar. Se você
  descreve o que ela faz usando "e", provavelmente são duas unidades.
- **O — Aberto/fechado:** estenda comportamento por composição/novos tipos, não editando
  o núcleo estável a cada variação.
- **L — Substituição de Liskov:** um subtipo tem de honrar o contrato do supertipo — sem
  enfraquecer garantias nem surpreender quem depende da abstração.
- **I — Segregação de interface:** prefira contratos pequenos e focados a uma interface
  gorda que obriga o cliente a depender do que não usa.
- **D — Inversão de dependência:** dependa de **abstrações**, não de implementações
  concretas; o domínio define a porta, a infraestrutura a implementa.

O fio comum: cada princípio empurra a mudança para ser **local e barata de raciocinar** —
é a mesma meta do Art. 4.

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

## Isolamento de efeito colateral

Todo efeito colateral (I/O, rede, banco, relógio, aleatoriedade, estado global)
**DEVE** ser explícito e isolável atrás de uma porta. Regra de negócio pura não faz I/O;
ela **recebe** o resultado do I/O ou **pede** por meio de uma abstração. É isso que torna
o domínio testável sem infraestrutura (Charter Art. 1 e Art. 4).

---

## Nomear seguindo o vizinho

Antes de nomear um tipo, arquivo, tabela ou coluna, **leia 2–3 vizinhos do mesmo
cluster** e copie o estilo. A pergunta nunca é "que nome eu prefiro?", é "como os
vizinhos se chamam?". Convenção consistente é o que faz código novo **ler como** o código
existente (Charter Art. 5).

As convenções **concretas** (casing, prefixos de namespace, sufixos com semântica fixa,
nomes de arquivo por papel) são específicas da linguagem e do projeto — vivem no perfil de
linguagem e em `guidelines/project/`, não aqui.
