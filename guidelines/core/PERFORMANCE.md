# Performance (core)

> Princípios de performance **agnósticos de linguagem**. Instanciam o **Art. 8**
> (eficiência consciente, medida — não presumida) do `../_meta/QUALITY-CHARTER.md`.
> Aplicar após features com grandes volumes, consultas complexas ou renderização pesada.
> As ferramentas e APIs **concretas** (profiler, plano de consulta, lazy-load da UI)
> ficam no perfil de linguagem.
>
> Este arquivo é o **gabarito do gate 10** (performance — decisão 4.155): o
> `performance-engineer` o lê em runtime, nunca o replica (padrão da 4.20). Padrão de
> custo patológico deste catálogo é achado **bloqueante** no review; otimização além
> dele só entra com **medição citada** — sem medição, é sugestão, nunca reprovação.

---

## Backend / acesso a dados

- **Sem N+1:** nunca uma consulta **dentro de um laço** sobre dados de tamanho variável.
  Resolva com **uma** consulta que já traz o necessário (junção/agregação). Este é o
  padrão de custo mais comum e o de melhor relação impacto/esforço para corrigir.
  O N+1 também nasce por **composição** (decisão 4.178): ao injetar um colaborador que
  consulta num serviço de domínio, procure os chamadores — se algum o invoca dentro de
  laço, a consulta nova é N+1 por construção, sem estar inteira em nenhum dos dois
  arquivos.
- **Traga só o necessário:** selecione as colunas/campos que a unidade usa; evite puxar o
  registro inteiro por hábito.
- **Índices** nas colunas de filtro e ordenação; confirme o plano com a ferramenta de
  *query plan* do banco (ex.: `EXPLAIN`) contra o ambiente real, não o dublê de teste.
- **Paginação** em toda listagem grande — nunca "traga tudo".
- **Grandes volumes:** processe em **lotes** ou por **streaming** (cursor/gerador linha a
  linha), em vez de materializar tudo em memória; libere o que não usa mais.
- **Cache** em consultas custosas e frequentes, com **TTL** e estratégia clara de
  **invalidação**.
- **Trabalho pesado** (e-mail, import/export, webhooks, processamento longo) vai para
  **jobs/filas assíncronas**, não para o caminho da requisição.
- **Timeout explícito** em toda chamada de rede (HTTP, banco, fila) — sem timeout, a
  falha do serviço externo vira travamento do seu.

---

## Frontend / UI

Princípios agnósticos de renderização (o mecanismo idiomático está no perfil de frontend):

- **Carregamento tardio (lazy):** componentes/telas pesadas e rotas carregam sob demanda,
  não no bundle inicial; imagens com carregamento tardio.
- **Listas longas:** virtualização (renderizar só o visível) acima de algumas dezenas de
  itens; paginar dados do servidor.
- **Entrada de busca/filtro:** *debounce*; eventos de alta frequência (scroll, resize):
  *throttle*.
- **Valores derivados:** memoize (computa uma vez, recomputa só quando a dependência muda)
  em vez de recalcular a cada render.
- **Imports específicos:** importe o símbolo usado, não a biblioteca inteira (preserva o
  *tree-shaking*).
- **Chaves estáveis** em listas renderizadas; sem observadores desnecessários.
- **Rede:** requisições independentes em paralelo; cancelar requisições obsoletas;
  compressão ativa.

---

## Régua

- **Régua (Art. 8):** não há consulta/round-trip dentro de laço sobre dados de tamanho
  variável; qualquer otimização não óbvia **cita a medição** que a justifica.
- **Correção de custo se prova no caminho nomeado pelo achado, nunca no método tocado
  (decisão 4.178):** conte **todas** as idas ao banco/rede do caminho (contador no
  driver ou métrica da sessão) em **pelo menos dois volumes**, e mostre que a contagem
  não cresce com N. Medir só a consulta corrigida deixa a metade cara onde estava —
  e dublê que conta chamadas de **um** colaborador deixa o laço do outro invisível: o
  invariante fixa a chamada em lote **e** a ausência de cada chamada de item único do
  mesmo laço. Chunking paga a parte invariante da consulta uma vez **por lote** — só é
  barato com essa parte escopada ao que a consulta realmente pergunta.
- **Medição citada declara a composição da base, não só o volume (decisão 4.279):**
  em consulta/fórmula com ramos de curto-circuito, o custo depende da **distribuição**
  dos dados (a proporção que decide os ramos) — duas medições corretas do mesmo código
  divergem e custam uma rodada de conferência sem que ninguém saiba por quê. Declare o
  N por entidade **e** a proporção que decide os ramos, e meça o caso que **não**
  curto-circuita (costuma ser o estado real de lançamento). A régua qualifica a
  medição citada — não exige benchmark: sem medição, a saída legítima continua sendo
  inspeção declarada.
