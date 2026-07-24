---
lang: php
version: "8.5"
charter: 0.5.0
generated-by: exemplar
reviewed: true
reviewer: "Fernando Petry"
---

# PHP 8.5 — Perfil de linguagem

> A **instância de referência** do `QUALITY-CHARTER.md` para PHP 8.5. Cada seção abaixo
> pega um artigo do charter e responde: *"em PHP 8.5, isto se cumpre assim, com esta
> ferramenta, com esta armadilha a evitar"*. É o padrão de qualidade que os demais
> perfis (outras linguagens/versões) replicam — mesma espinha (seções 0–12), conteúdo
> específico da stack.
>
> **Escopo:** o que é idiomático de PHP 8.5. A arquitetura **específica do projeto**
> (nomes de camadas próprios, caminhos reais) mora em `guidelines/project/` e na ficha
> `keelson.config.json`; aqui, os nomes de pasta são placeholders genéricos (`src/`,
> `tests/`) e os namespaces usam `App\` como raiz de exemplo.

---

## 1. Identidade & versão

O alvo é **PHP 8.5** (lançado em novembro de 2025), com `declare(strict_types=1)`
obrigatório no topo de todo arquivo — sem coerção silenciosa de tipo.

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| **Pipe `\|>`** | Encadear transformações puras, esquerda→direita, sem variável temporária | 8.5 |
| **Clone with** | Imutabilidade: `clone($obj, ['field' => $novo])` | 8.5 |
| **`#[\NoDiscard]`** | Marcar método cujo retorno **não** pode ser ignorado | 8.5 |
| **`array_first()` / `array_last()`** | Substituem `reset()`/`end()` sem mover o ponteiro interno | 8.5 |
| **Property hooks** | Validação/derivação no `get`/`set` da propriedade | 8.4 |
| **Asymmetric visibility** | `public private(set)` — leitura pública, escrita restrita | 8.4 |
| **`new` sem parênteses** | `new Foo->bar()` | 8.4 |
| **`array_find` / `array_any` / `array_all`** | Busca declarativa em array | 8.4 |
| **Enums, `readonly`, first-class callable, named args** | Base de 8.1–8.3, uso corrente | ≤8.3 |

**Construções de versões antigas que NÃO DEVEM mais aparecer:** `reset()`/`end()` só
para pegar o primeiro/último elemento (use `array_first`/`array_last`); getters/setters
manuais quando um property hook resolve; `each()`, `create_function()`, `${var}` em
strings (removidos/deprecados); propriedades dinâmicas não declaradas (deprecadas desde
8.2 — declare a propriedade ou promova via construtor).

**Por que a versão é seção de primeira classe:** o mesmo "PHP" em 8.1 e 8.5 é quase outra
linguagem — pipe, clone-with e `#[\NoDiscard]` não existem antes de 8.5, e property hooks
não existem antes de 8.4. Código escrito para o alvo errado passa no lint e falha no
runtime da versão real.

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Guia canônico:** **PSR-12** / **PER Coding Style** (a evolução oficial mantida pelo
PHP-FIG). Não há divergência de estilo por gosto — o formatter decide.

- **Formatter/linter:** `php-cs-fixer` (config `.php-cs-fixer.dist.php` versionada na raiz)
  ou `phpcs`/`phpcbf` com ruleset PSR-12. Escolha uma e cabeie na ficha.
- **É erro (bloqueia):** qualquer violação de PSR-12 que o fixer reporte em `--dry-run`;
  ausência de `declare(strict_types=1)`; import não usado.
- **É aviso (não bloqueia):** preferências de ordenação de `use`, largura de linha acima
  do alvo quando quebrar prejudica leitura — decisão do time, não do gate.
- **Comando de lint** (alimenta `keelson.config.json → quality.lint`):
  `vendor/bin/php-cs-fixer fix --dry-run --diff` (exit code ≠ 0 reprova).

**Armadilha comum:** rodar `php-cs-fixer fix` (que reescreve) no gate em vez de
`--dry-run` — o gate deve **reprovar**, não **corrigir** silenciosamente e mascarar que o
autor entregou fora do padrão.

---

## 3. Nomenclatura & idioma → Charter Art. 5

**Convenção por símbolo** (PSR-1/PSR-4, sem exceção):

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Classe / Interface / Enum / Trait | `PascalCase` | `CreateUserUseCase` |
| Método / função / variável / propriedade | `camelCase` | `findById`, `$emailExists` |
| Constante de classe / global | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Arquivo | idêntico ao FQCN (PSR-4), 1 classe por arquivo | `CreateUserUseCase.php` |

**Padrões de nome que sinalizam papel** — o nome revela a intenção antes do corpo:

- `*Interface` (contrato de domínio) · `Pdo*Repository` (implementação PDO) ·
  `*UseCase` (um caso de uso, um `execute()`) · `*Action` (entrada HTTP) ·
  `*DTO` (transporte, sem lógica) · `*Test` (teste da classe homônima).
- Value Object nomeado pelo **conceito** (`Email`, `Cpf`), não pelo tipo primitivo.

**Idioma:** identificadores em **inglês** — é a norma idiomática do ecossistema PHP
(stdlib, PSR, libs são todas em inglês; misturar quebra a leitura). O idioma dos
**comentários** é uma decisão do projeto (registrada em `guidelines/project/`), mas
**DEVE ser único e consistente** em toda a base — nunca metade em inglês, metade em outro
idioma dentro do mesmo arquivo.

**Armadilha comum:** nomear pela implementação (`$arrayDeUsers`, `processData`) em vez da
intenção (`$activeUsers`, `deactivateExpiredContracts`). O nome que descreve o *como*
mente assim que o *como* muda.

---

## 4. Estrutura & arquitetura → Charter Art. 4, 7

O padrão idiomático para backend PHP de porte é **Clean/Hexagonal Architecture**, com a
dependência apontando **para dentro**, em direção ao domínio:

```
Presentation → Application → Domain ← Infrastructure
```

| Camada | PODE conter | NÃO PODE conter |
|--------|-------------|-----------------|
| **Domain** | Entities, Value Objects, interfaces de repositório | Framework, PDO, HTTP, SQL |
| **Application** | UseCases, DTOs, orquestração | Request/Response, SQL, detalhes de I/O |
| **Infrastructure** | Implementar as interfaces do Domain (PDO, HTTP client) | Regra de negócio |
| **Presentation** | Actions, Middleware, mapear HTTP↔DTO | Regra de negócio, SQL |

**Blocos idiomáticos** (uma responsabilidade cada):

- **Entity** — identidade + invariantes; imutabilidade com `clone with`; property hooks
  para validar no `set`; `public private(set)` para expor sem deixar mutar de fora.
- **Value Object** — `final readonly`; valida no construtor; `equals()` por valor.
- **DTO** — `readonly class` de transporte; `fromArray()` como fábrica; **sem** lógica.
- **UseCase** — um `execute()`; recebe DTO, devolve Entity/resultado; depende de
  **interfaces**, injetadas pelo construtor.
- **Repository** — interface no Domain, implementação PDO na Infrastructure; `hydrate()`
  privado; **sem** regra de negócio.
- **Action** — `final class` com `__invoke()`; zero lógica; mapeia entrada→DTO→UseCase e
  resultado→resposta.

```php
declare(strict_types=1);

namespace App\Application\UseCases\User;

use App\Domain\Repositories\User\UserRepositoryInterface;
use App\Domain\Entities\User\User;

final class CreateUserUseCase
{
    // Depende da ABSTRAÇÃO (interface), nunca do PDO concreto → testável sem banco.
    public function __construct(private readonly UserRepositoryInterface $repo) {}

    #[\NoDiscard]
    public function execute(CreateUserDTO $dto): User
    {
        if ($this->repo->emailExists($dto->email)) {
            throw new \DomainException('Email already registered');
        }

        return $this->repo->save(User::fromDto($dto));
    }
}
```

**Isolamento de efeito colateral:** todo I/O (banco, rede, filesystem, relógio, estado
global) entra por uma **interface** injetada no construtor. É isso que deixa o UseCase ser
testado sem levantar o mundo (Art. 4 da régua) e trocar o driver sem tocar a regra.

**Condicionais e assinaturas (Art. 4, 7):** prefira *early return* (guard clause) a
`if/else` aninhado; condicional que despacha pela mesma variante em vários pontos vira
**enum com `match` exaustivo** ou implementações da interface (polimorfismo). Método
passando de **~4 parâmetros** → agrupe num **DTO/objeto de parâmetro `readonly`**; *named
arguments* cobrem os opcionais sem inflar a assinatura.

**Armadilha comum:** SQL ou `$_SESSION`/`getenv()` dentro do UseCase ou da Action —
vaza detalhe de infraestrutura para dentro da regra de negócio e torna o teste refém do
ambiente. Detalhe de I/O só na Infrastructure.

**Padrões na prática (PHP 8.5)** — a construção idiomática vem **antes** do padrão
clássico (ver "Padrões de projeto" em `../core/ARCHITECTURE.md`):

- **Strategy/State** → `enum` com `match` exaustivo ou *first-class callable* antes de
  hierarquia de classes; hierarquia só quando as variantes carregam estado/dependências.
- **Factory** → *named constructor* estático (`fromArray()`, `fromRequest()`) antes de
  classe-fábrica dedicada; fábrica dedicada só quando a construção tem variantes reais.
- **Observer** → eventos do framework / PSR-14, nunca implementação manual do padrão.
- **Builder** → desnecessário: *named arguments* + construtor `readonly` resolvem.
- **Armadilhas PHP:** Singleton e `static` mutável; *service location* (puxar do
  container) dentro de Domain/Application — a dependência entra pelo construtor;
  herança para reuso de código (prefira composição).

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceções, não códigos de retorno**, para condição excepcional. Fluxo normal ("não
encontrado" esperado) PODE ser `?T`/`null`; violação de regra é **exceção tipada**.

- **Domínio lança tipado:** `DomainException` (regra de negócio), `InvalidArgumentException`
  (entrada inválida no DTO/VO). Nunca lance `\Exception` cru.
- **Nunca engolir silenciosamente:** `catch (\Throwable) {}` vazio, ou o operador `@`, são
  proibidos — o erro some e o bug vira silencioso. Se capturou, ou trata, ou re-lança com
  contexto.
- **Fronteira de conversão:** um único ponto (Action + handler global) captura `\Throwable`,
  loga o detalhe internamente e devolve ao cliente uma mensagem **genérica** com o status
  HTTP correto. O `$e->getMessage()` **não** vai cru para a resposta.

```php
try {
    $user = $this->useCase->execute($dto);
    return $this->ok($response, $user->toArray());
} catch (\InvalidArgumentException $e) {
    return $this->error($response, 'Validation failed', 422); // detalhe de campo, sem stack
} catch (\DomainException $e) {
    return $this->error($response, $e->getMessage(), 400);     // mensagem de negócio, curada
} catch (\Throwable $e) {
    $this->logger->error('user.create.failed', ['exception' => $e]); // detalhe fica no log
    return $this->error($response, 'Internal error', 500);     // genérico para o cliente
}
```

**O que logar (Art. 2):** identificadores e ação (`user_id`, `action`), a exceção com
stack **do lado do servidor** — **nunca** senha, token, PII ou o corpo cru da requisição.

**Armadilha comum — Information Disclosure:** sanear a mensagem só no *log* e devolver o
`$e->getMessage()` cru na resposta (inclusive dentro de um `success:false` com HTTP 200).
O valor tem que ser saneado **no sink de resposta**, não só no de log. Stack trace ao
cliente em produção é vazamento.

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> A seção mais importante do perfil. Cada item abaixo é um item da **Régua do Art. 2**
> traduzido para "como se faz e como se erra em PHP 8.5". Vulnerabilidade aqui é
> **rejeição imediata** no review.
>
> *(Este é o exemplar curado e revisado por humano — `reviewed: true`. Perfis
> **gerados** para linguagens que o autor não domina devem marcar cada afirmação de
> segurança com `⚠️ CONFIRMAR:` para dirigir a revisão; aqui as afirmações já foram
> validadas.)*

### 6.1 Injeção → sempre parametrizar

**SQL — PDO com parâmetros NOMEADOS**, nunca concatenação nem interpolação de entrada:

```php
// ✅ prepared statement, parâmetros nomeados
$stmt = $pdo->prepare('SELECT id, name, email FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);

// ❌ NUNCA — concatenar/interpolar entrada externa é SQL Injection
$pdo->query("SELECT * FROM users WHERE email = '$email'");
```

- Ligue `PDO::ATTR_EMULATE_PREPARES => false` (força prepared statements reais no driver).
- O que **não** dá para bindar (nome de coluna/tabela em `ORDER BY`) valida-se contra uma
  **whitelist** — nunca interpolando o input.
- **Command injection:** evite `exec/shell_exec/system`; se inevitável, `escapeshellarg()`
  em cada argumento.
- **Path traversal:** `basename()` + validação contra diretório-base; nunca abrir
  `file_get_contents($userInput)` cru.

**Armadilha comum — HY093:** reusar o mesmo placeholder nomeado duas vezes no SQL com
`EMULATE_PREPARES=false` (`... WHERE a = :x OR b = :x`) estoura *"invalid parameter
number"*. Use nomes distintos ou passe o valor duas vezes com chaves diferentes.

### 6.2 Saída / escaping → escapar no destino

Escape é **por contexto de saída**, feito no ponto de renderização:

```php
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); // HTML
echo rawurlencode($value);                            // componente de URL
echo json_encode($value, JSON_THROW_ON_ERROR);        // contexto JS/JSON
```

Numa API JSON, `json_encode` já escapa; num template (Twig/Blade), o autoescape cuida do
HTML — **não** o desligue para dado de usuário. **Nunca** renderize entrada de usuário crua
em HTML.

**Armadilha comum:** saneie o mesmo valor no log/persistência mas devolva cru na resposta
— o escaping tem que acontecer em **cada** sink de saída, independentemente.

### 6.3 Autorização → negar por padrão

Toda action verifica **permissão antes de executar**; o default é **negar**. A checagem
vive num middleware/guard, não espalhada dentro da regra.

- **IDOR / acesso por registro:** ter a permissão genérica não basta — verifique que o
  registro pertence/ é visível ao solicitante (`WHERE owner_id = :currentUserId`).
- **Tenant/instância:** `instance_id` (e afins) tem **ponto único de população** a partir
  da **sessão server-side** — nunca de header/query/path. Leitor ausente **nega**, nunca
  assume default permissivo (`?? 1` é bug de segurança).
- **Serializador de dado sensível:** default **fail-closed** — omitir por padrão, expor por
  parâmetro explícito. Nunca `toArray(bool $includeFinancials = true)`.
- **Prova:** todo gate de autorização exige teste de integração provando **403 sem a
  permissão** (não só 200 com ela).

**Armadilha comum (framework de roteamento):** ler o argumento de rota do lugar errado
(ex.: atributo do request em vez do argumento da rota resolvida) devolve `null` e **libera
tudo silenciosamente**. Confirme a fonte e a **ordem dos middlewares** (autorização depois
do roteamento).

### 6.4 Segredos & configuração → fora do código, fora do log

- Segredos vêm de **variável de ambiente / secret store**, lidos via config — **nunca**
  hardcoded no fonte, **nunca** commitados (`.env` no `.gitignore`).
- Segredo **nunca** em log, em mensagem de erro, nem em **query string de URL**.
- **Senhas:** `password_hash($senha, PASSWORD_ARGON2ID)` (ou bcrypt); verificação com
  `password_verify`. **Nunca** MD5/SHA1, nunca hash caseiro.

```php
// ❌ NUNCA
error_log("password: $password");
// ✅ apenas identificador e ação
$logger->info('login_attempt', ['user_id' => $userId]);
```

### 6.5 Sessão & estado de autenticação

- **Cookies de sessão** com as três flags: `httponly` (JS não lê), `secure` (só HTTPS),
  `samesite=Strict|Lax` (anti-CSRF):

```php
setcookie('session', $value, [
    'httponly' => true,
    'secure'   => true,
    'samesite' => 'Strict',
]);
```

- Sessão é a **fonte de verdade** de identidade e tenant — regenere o id no login
  (`session_regenerate_id(true)`), expire por inatividade, invalide no logout.
- Token de autenticação **não** vai para `localStorage` (concern do front, mas o backend
  deve entregá-lo como cookie `httponly`).
- **CSRF:** forms de estado (POST/PUT/DELETE) exigem token anti-CSRF; APIs consumidas por
  SPA validam origem (ex.: header `X-Requested-With`) além da mesma-origem.

### 6.6 Dependências & upload (síntese)

- **Mass assignment:** monte a Entity a partir de um **DTO com campos whitelistados** —
  nunca `->fill($request->all())`.
- **Upload:** whitelist de extensão **e** validação de MIME real; nunca confie no nome/tipo
  enviado pelo cliente.
- **Auditar dependência:** `composer audit` (ver §8).

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico:** **PHPUnit**. Comando (alimenta `keelson.config.json → quality.test`):
`composer test` (que embrulha `vendor/bin/phpunit`).

**Convenções idiomáticas do ecossistema + do padrão de qualidade:**

- **Mocks:** `PHPUnit\Framework\MockObject` via `$this->createMock(Interface::class)`.
  Não usar Mockery — mantenha um único mecanismo de mock na base.
- **Atributos, não annotations:** `#[Test]`, `#[DataProvider('xxxProvider')]` (as
  annotations `@test`/`@dataProvider` estão obsoletas no PHPUnit atual).
- **Nomes reveladores de intenção:** o padrão do time (ex.: `deveXxx()` / `naoDeveXxx()`,
  ou `it_...`) — o que importa é ser **consistente** e descrever a regra sob teste.
- **AAA:** Arrange → Act → Assert, blocos longos separados visualmente.
- **Agrupamento:** use `#[Group('...')]` para separar testes que precisam de banco dos
  puramente unitários (o gate roda o subconjunto certo).

```php
/**
 * @group skip-migration
 */
final class CreateUserUseCaseTest extends TestCase
{
    private UserRepositoryInterface&MockObject $repo;
    private CreateUserUseCase $useCase;

    protected function setUp(): void
    {
        $this->repo = $this->createMock(UserRepositoryInterface::class);
        $this->useCase = new CreateUserUseCase($this->repo);
    }

    #[Test]
    public function deveCriarUsuarioQuandoEmailInedito(): void
    {
        // ═══════════ Arrange ═══════════
        $this->repo->method('emailExists')->willReturn(false);
        $this->repo->method('save')->willReturnArgument(0);

        // ═══════════ Act ═══════════
        $user = $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));

        // ═══════════ Assert ═══════════
        $this->assertSame('John', $user->name);
    }

    #[Test]
    public function naoDeveCriarComEmailExistente(): void
    {
        $this->repo->method('emailExists')->willReturn(true);

        $this->expectException(\DomainException::class);
        (void) $this->useCase->execute(new CreateUserDTO('John', 'john@example.com')); // (void) silencia o #[\NoDiscard]
    }
}
```

**Testar comportamento, não implementação:** prove a regra de negócio, cálculos críticos,
validações de domínio e edge cases. Não teste getter trivial, nem "a classe instanciou",
nem infraestrutura externa. Mocke as **fronteiras** (interfaces de repositório/serviço);
nunca mocke a unidade sob teste.

**Fixtures / dados compartilhados (Art. 3):** teste de repositório/endpoint que precisa de
banco roda num **SQLite em memória**, e o **schema e os dados de teste vivem num helper
central** (por convenção, sob `tests/Support/`) — um método por tabela para o schema, um
builder com defaults+overrides por linha. Declarar `CREATE TABLE`/`INSERT` **inline** no
teste é a mesma violação DRY dos helpers de produção: cópias divergem e quebram em massa
por *drift* quando o repositório passa a ler uma coluna nova. Coluna nova → edite o helper,
num lugar só.

> ⚠️ **SQLite ≠ o banco de produção.** O teste em SQLite não substitui o *smoke* contra o
> banco real (MySQL/Postgres) quando o SQL do repositório muda — construções específicas do
> dialeto (e erros como HY093) só aparecem lá.

**Régua (Art. 1):** existe teste que **falha se o comportamento regredir**. Gate de
autorização exige o teste de **403 sem permissão**, com o stack HTTP e a ordem de
middlewares de produção.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador:** **Composer**. `composer.json` declara, `composer.lock` **fixa** — o lock
é **commitado** para builds reprodutíveis.

- **Política de versão:** constraints com caret (`^8.2`) para libs maduras; o `.lock`
  garante a versão exata em CI/produção. `composer install` em CI (respeita o lock),
  `composer update` só deliberadamente.
- **Auditar vulnerabilidade conhecida:** `composer audit` no pipeline (consulta o advisory
  database do ecossistema PHP, sincronizado com o CVE/NVD) — reprovar em vulnerabilidade de
  severidade relevante, **citando o CVE/advisory ID** reportado.
- **Higiene:** `composer outdated` para atrasos; evite pacote **abandonado** (o Packagist
  marca `abandoned`) e confira **licença** compatível antes de adicionar.
- **Autoload PSR-4:** classe nova exige `composer dump-autoload` (ou `-o` em produção) para
  entrar no mapa.

**Armadilha comum:** não commitar o `composer.lock` (ou rodar `composer update` no deploy)
— cada ambiente resolve versões diferentes e o bug "só na produção" nasce aí.

---

## 9. Reúso: o que já existe → Charter Art. 3

**Antes de escrever** helper, validação, conversão, DTO ou trait, **procure o
equivalente** — reimplementar o que existe (ou duplicar entre arquivos) é proibido, mesmo
que o código fique correto.

- **Casting/parse de entrada** (string→int/float/date, com null-safety) mora num **trait
  canônico de parsing** consumido por todos os DTOs — nunca reimplemente o conversor.
- **Par Create/Update** de um domínio compartilha validação/sanitização num **trait do
  domínio** — nunca duplique a regra entre os dois DTOs.
- **Conceito de domínio recorrente** (CPF, e-mail, código) vira **Value Object** único, não
  validação repetida em cada ponto de uso.
- **Prefira a stdlib e o framework** antes de rolar o seu: `filter_var`, `array_*`,
  `password_hash`, `DateTimeImmutable`, o QueryBuilder/HTTP client do framework.

**Como descobrir o que já existe:** busca por nome/conceito no `codePaths` da ficha;
**um guard determinístico** (teste de arquitetura) que **reprova** a reimplementação de um
conversor canônico é o mecanismo ideal — transforma "lembre de reusar" em falha de build.

**Régua (Art. 3):** a mudança não introduz um **segundo caminho** para algo que já existia;
quando o conceito se repetiu, ele foi **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

O custo patológico mais comum em backend PHP é o **round-trip de banco em laço** (N+1):

```php
// ❌ N+1 — uma query POR item
foreach ($this->orderRepo->findAll() as $order) {
    $customer = $this->customerRepo->findById($order->customerId);
}

// ✅ uma query com JOIN, no repositório PDO
$stmt = $pdo->prepare(
    'SELECT o.id, o.total, c.name AS customer_name
       FROM orders o JOIN customers c ON c.id = o.customer_id
      WHERE o.status = :status'
);
$stmt->execute(['status' => 'OPEN']);
```

Padrões a seguir:

- **`SELECT` só das colunas usadas** pelo `hydrate()` — nunca `SELECT *`.
- **Paginação** (`LIMIT`/`OFFSET`) em toda listagem de tamanho variável; **índice** nas
  colunas de `WHERE`/`ORDER BY`.
- **Grandes volumes:** `fetch()` linha a linha ou **generator (`yield`)** em vez de
  `fetchAll()` (não materializa o array inteiro na memória); `unset()` em variáveis grandes
  após uso.
- **Trabalho pesado** (import/export, e-mail, webhook) vai para **fila/job**, não no
  request.

**Ferramenta de medição idiomática:** `EXPLAIN` no banco **real** (não no SQLite de teste)
para plano de query; **Xdebug profiler**, **Blackfire** ou **SPX** para CPU/memória do PHP;
**OPcache** (e *preloading*) ligados em produção. **Régua (Art. 8):** não há query/round-trip
dentro de laço sobre dados de tamanho variável; otimização não óbvia **cita a medição** que a
justifica — nunca palpite.

**Armadilha comum:** `fetchAll()` num resultado grande e depois iterar — dobra o pico de
memória à toa; o `fetch()` em cursor faz o mesmo trabalho com pegada constante.

---

## 11. Gotchas da versão (8.5) → Charter Art. 1, 7

- **`clone with` é raso.** `clone($obj, ['a' => $x])` copia por cima do clone raso —
  objetos aninhados continuam **compartilhados** por referência. Para deep-copy, clone os
  filhos explicitamente (ou implemente `__clone`).
- **`#[\NoDiscard]` avisa se você ignora o retorno.** Para descartar de propósito (típico
  em teste de exceção), prefixe `(void)`. Sem isso, o warning polui o gate.
- **`array_first`/`array_last` não movem o ponteiro interno** — seguros sobre cópias e em
  código concorrente-por-request, ao contrário de `reset()`/`end()`. Migre os usos antigos.
- **Pipe `|>` encadeia da esquerda para a direita** com funções unárias puras; melhora a
  leitura mas **não** substitui um método de domínio nomeado quando há efeito colateral.
- **Property hooks podem recursar:** dentro do hook `set` de `$name`, atribuir a
  `$this->name` re-dispara o hook — escreva no backing correto ou use a forma sem recursão.
  `strict_types=1` continua valendo: sem coerção silenciosa, e `==` vs `===` importa.
- **Vindo de 8.3/8.4:** promova propriedades dinâmicas (deprecadas) ou marque
  `#[\AllowDynamicProperties]`; torne **explícito** o `?T` em parâmetro com default `null`
  (o nullable implícito foi deprecado em 8.4). Prefira `readonly`, enums e first-class
  callable no lugar das construções pré-8.1.

**Régua (Art. 1/7):** quem vem de outra versão precisa que essas surpresas estejam
**cobertas por teste** (ex.: um teste que pega o clone raso compartilhando o objeto
aninhado) e **comentadas com o porquê** onde a escolha não é óbvia.

---

## 12. Ferramentas & comandos

Estes comandos são a ponte entre a doutrina (este perfil) e a automação (os gates leem a
ficha). Cada linha alimenta `keelson.config.json → quality.*`:

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `composer test` (embrulha `vendor/bin/phpunit`) | `quality.test` |
| **lint** | `vendor/bin/php-cs-fixer fix --dry-run --diff` (ou `phpcs`) | `quality.lint` |
| **typecheck** | `vendor/bin/phpstan analyse` (ou `psalm`) — PHP não tem compilador; o **analisador estático** cumpre esse papel. Opcional, mas **recomendado**; se não adotado, `null`. | `quality.typecheck` |
| **build** | **não se aplica** — PHP é interpretado. O "build" de deploy é `composer install --no-dev --optimize-autoloader` + warmup de OPcache, não um passo de gate. | `quality.build` (`null`) |

Exemplo de ficha correspondente:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "8.5" } },
  "codePaths": { "backend": ["src"] },
  "quality": {
    "test": "composer test",
    "lint": "vendor/bin/php-cs-fixer fix --dry-run --diff",
    "typecheck": "vendor/bin/phpstan analyse",
    "build": null
  }
}
```

**Por quê:** sem estes comandos declarados, o gate não sabe o que rodar — a régua do
charter (prova externa e falsificável) fica sem executor.
