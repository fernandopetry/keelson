# Performance (core)

> Princípios de performance **agnósticos de linguagem**. Instanciam o **Art. 8**
> (eficiência consciente, medida — não presumida) do `../_meta/QUALITY-CHARTER.md`.
> Aplicar após features com grandes volumes, consultas complexas ou renderização pesada.
> As ferramentas e APIs **concretas** (profiler, plano de consulta, lazy-load da UI)
> ficam no perfil de linguagem.

---

## Backend / acesso a dados

- **Sem N+1:** nunca uma consulta **dentro de um laço** sobre dados de tamanho variável.
  Resolva com **uma** consulta que já traz o necessário (junção/agregação). Este é o
  padrão de custo mais comum e o de melhor relação impacto/esforço para corrigir.
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
