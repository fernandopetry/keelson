---
lang: php
version: "8.0"
charter: 0.5.0
generated-by: profile-writer
reviewed: false
reviewer: null
---

# PHP 8.0 — Perfil de linguagem

> Instância do `QUALITY-CHARTER.md` (v0.3.0) para **PHP 8.0** — perfil de **legado**:
> a versão está fora de suporte (ver §1) e este perfil existe para manter o padrão de
> qualidade **enquanto** o upgrade não acontece, não para legitimar a permanência nela.
> Cada seção pega um artigo do charter e responde: *"em PHP 8.0, isto se cumpre assim,
> com esta ferramenta, com esta armadilha a evitar"*.
>
> **Escopo:** o que é idiomático de PHP 8.0. A arquitetura **específica do projeto**
> (nomes de camadas próprios, caminhos reais) mora em `guidelines/project/` e na ficha
> `keelson.config.json`; aqui, os nomes de pasta são placeholders genéricos (`src/`,
> `tests/`) e os namespaces usam `App\` como raiz de exemplo.
>
> **Proveniência:** gerado pelo `profile-writer` com base no exemplar PHP 8.5.
> `reviewed: false` — pendente de revisão humana; as afirmações marcadas
> `⚠️ CONFIRMAR:` são os alvos prioritários dessa revisão.

---

## 1. Identidade & versão

> **⚠️ PHP 8.0 está em fim de vida (EOL) desde 26 de novembro de 2023.** Não recebe
> mais correções de segurança da comunidade: toda vulnerabilidade descoberta desde
> então permanece **sem patch** no runtime. Consequência para este perfil:
>
> 1. **Plano de upgrade é recomendação permanente** — cada entrega neste projeto
>    DEVERIA reduzir a distância para 8.1+ (evitar construções removidas/deprecadas
>    adiante, manter dependências compatíveis com as duas versões), nunca aumentá-la.
> 2. A mitigação enquanto o upgrade não sai está na abertura do §6.
> 3. ⚠️ CONFIRMAR: suporte estendido comercial existiu (ex.: Zend PHP LTS para 8.0,
>    anunciado até dezembro/2025; TuxCare ELS) — confirmar se o projeto tem algum
>    contrato desses ativo hoje; sem ele, assuma runtime sem patches.

O alvo é **PHP 8.0** (lançado em novembro de 2020), com `declare(strict_types=1)`
obrigatório no topo de todo arquivo — sem coerção silenciosa de tipo.

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| **Named arguments** | Opcionais legíveis sem inflar assinatura: `f(strict: true)` | 8.0 |
| **Attributes `#[...]`** | Metadados nativos em vez de annotations em docblock | 8.0 |
| **Constructor property promotion** | Declarar e atribuir propriedade no construtor | 8.0 |
| **Union types** | `int\|string`, `?T` explícito em parâmetro/retorno/propriedade | 8.0 |
| **`match`** | Despacho exaustivo por valor, com `===` e sem fall-through | 8.0 |
| **Nullsafe `?->`** | Encadeamento seguro: `$user?->address?->city` | 8.0 |
| **`str_contains` / `str_starts_with` / `str_ends_with`** | Substituem `strpos(...) !== false` e afins | 8.0 |
| **`::class` em objeto** | `$obj::class` em vez de `get_class($obj)` | 8.0 |
| **Throw como expressão** | `$x = $y ?? throw new InvalidArgumentException(...)` | 8.0 |
| **Catch sem captura** | `catch (DomainException) { ... }` quando `$e` não é usado | 8.0 |
| **Tipos `mixed` e retorno `static`** | Contratos mais precisos em interfaces fluentes | 8.0 |

**Recursos de versões FUTURAS que NÃO existem em 8.0 — NÃO recomendar nem gerar:**

- **8.1:** `enum`, `readonly` properties, first-class callable syntax (`strlen(...)`),
  fibers, pure intersection types (`A&B` em tipo declarado), `never`, `new` em
  inicializador de parâmetro.
- **8.2:** `readonly class`, DNF types, constantes em traits.
- **8.3:** typed class constants, `#[\Override]`, `json_validate()`.
- **8.4:** property hooks, asymmetric visibility (`private(set)`), `new Foo()->bar()`
  sem parênteses, `array_find`/`array_any`/`array_all`.
- **8.5:** pipe `|>`, `clone with`, `#[\NoDiscard]`, `array_first`/`array_last`.

Os **substitutos idiomáticos em 8.0** para os mais sentidos estão no §4 (enum →
classe de constantes + `match`; `readonly` → propriedade `private` promovida + getter)
e no §11.

**Construções de versões antigas que NÃO DEVEM mais aparecer** (removidas em 8.0 —
código que as usa nem carrega): `each()`, `create_function()`, acesso a string/array
com chaves `{}` (`$str{0}`), cast `(real)`, `get_magic_quotes_gpc()`, métodos com o
mesmo nome da classe como construtor (estilo PHP 4). E as que ainda rodam mas são
proibidas pelo padrão: `extract()` sobre entrada externa, `@` para silenciar erro,
`strpos(...) !== false` onde `str_contains` resolve.

**Por que a versão é seção de primeira classe:** "PHP" em 8.0 e em 8.1+ é quase outra
linguagem — `enum`, `readonly` e first-class callables não existem aqui, e código
gerado para o alvo errado **fatal-erra no parse/runtime** desta versão, não no lint.

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Guia canônico:** **PSR-12** (o guia vigente na era do PHP 8.0; o sucessor PER Coding
Style é compatível para trás). Não há divergência de estilo por gosto — o formatter
decide.

- **Formatter/linter:** `php-cs-fixer` (config `.php-cs-fixer.dist.php` versionada na
  raiz, ruleset `@PSR12`) ou `phpcs`/`phpcbf` com ruleset PSR-12 (PHP_CodeSniffer).
  Escolha **uma** e cabeie na ficha.
- **É erro (bloqueia):** qualquer violação de PSR-12 que o fixer reporte em
  `--dry-run`; ausência de `declare(strict_types=1)`; import não usado.
- **É aviso (não bloqueia):** preferências de ordenação de `use`, largura de linha
  acima do alvo quando quebrar prejudica leitura — decisão do time, não do gate.
- **Comando de lint** (alimenta `keelson.config.json → quality.lint`):
  `vendor/bin/php-cs-fixer fix --dry-run --diff` (exit code ≠ 0 reprova).

**Armadilhas comuns:**

- Rodar `php-cs-fixer fix` (que reescreve) no gate em vez de `--dry-run` — o gate deve
  **reprovar**, não **corrigir** silenciosamente.
- O php-cs-fixer **não roda em PHP 8.0.0 exato** (bug no tokenizer do PHP) — exige
  **8.0.1+**. Se o runtime está pinado em 8.0.0, atualize o patch release.
- ⚠️ CONFIRMAR: releases recentes do php-cs-fixer 3.x podem ter subido o piso de PHP
  acima de 8.0 — deixe o Composer resolver a última versão instalável sob
  `config.platform.php: 8.0.x` (ver §8) e confirme qual série 3.x o projeto consegue
  usar; não copie o constraint de um projeto em PHP 8.3+.

---

## 3. Nomenclatura & idioma → Charter Art. 5

**Convenção por símbolo** (PSR-1/PSR-4, sem exceção):

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Classe / Interface / Trait | `PascalCase` | `CreateUserUseCase` |
| Método / função / variável / propriedade | `camelCase` | `findById`, `$emailExists` |
| Constante de classe / global | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Arquivo | idêntico ao FQCN (PSR-4), 1 classe por arquivo | `CreateUserUseCase.php` |

*(Não há `enum` em 8.0 — a "classe de constantes" que o substitui segue a convenção de
classe + constantes: `OrderStatus::OPEN`.)*

**Padrões de nome que sinalizam papel** — o nome revela a intenção antes do corpo:

- `*Interface` (contrato de domínio) · `Pdo*Repository` (implementação PDO) ·
  `*UseCase` (um caso de uso, um `execute()`) · `*Action` (entrada HTTP) ·
  `*DTO` (transporte, sem lógica) · `*Test` (teste da classe homônima).
- Value Object nomeado pelo **conceito** (`Email`, `Cpf`), não pelo tipo primitivo.

**Idioma:** identificadores em **inglês** — é a norma idiomática do ecossistema PHP
(stdlib, PSR, libs são todas em inglês; misturar quebra a leitura). O idioma dos
**comentários** é uma decisão do projeto (registrada em `guidelines/project/`), mas
**DEVE ser único e consistente** em toda a base — nunca metade em inglês, metade em
outro idioma dentro do mesmo arquivo.

**Armadilha comum — específica de 8.0:** com **named arguments**, o **nome do
parâmetro vira API pública**: renomear `$email` para `$emailAddress` numa função
chamada com `f(email: ...)` **quebra os chamadores**. Nomeie parâmetros pela intenção
desde o início e trate renomeação de parâmetro como quebra de contrato.

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

**Blocos idiomáticos em 8.0** (uma responsabilidade cada) — sem `readonly`, a
imutabilidade é por **convenção reforçada por visibilidade**: propriedade `private`
promovida no construtor + getter, **sem setter**:

- **Entity** — identidade + invariantes; valida no construtor; mudança de estado por
  método de domínio nomeado (`activate()`, `close()`), nunca setter genérico.
- **Value Object** — `final`, propriedades `private` promovidas, getters, `equals()`
  por valor; "modificação" devolve **nova instância** (`withEmail(): self`).
- **DTO** — `final` de transporte; propriedades `private` promovidas + getters (sem
  `readonly`, propriedade `public` seria mutável de fora); `fromArray()` como fábrica;
  **sem** lógica.
- **UseCase** — um `execute()`; recebe DTO, devolve Entity/resultado; depende de
  **interfaces**, injetadas pelo construtor.
- **Repository** — interface no Domain, implementação PDO na Infrastructure;
  `hydrate()` privado; **sem** regra de negócio.
- **Action** — `final class` com `__invoke()`; zero lógica; mapeia
  entrada→DTO→UseCase e resultado→resposta.

```php
<?php

declare(strict_types=1);

namespace App\Application\UseCases\User;

use App\Domain\Entities\User\User;
use App\Domain\Repositories\User\UserRepositoryInterface;

final class CreateUserUseCase
{
    // Promotion (8.0): depende da ABSTRAÇÃO, nunca do PDO concreto → testável sem banco.
    public function __construct(private UserRepositoryInterface $repo)
    {
    }

    public function execute(CreateUserDTO $dto): User
    {
        if ($this->repo->emailExists($dto->email())) {
            throw new \DomainException('Email already registered');
        }

        return $this->repo->save(User::fromDto($dto));
    }
}
```

**Isolamento de efeito colateral:** todo I/O (banco, rede, filesystem, relógio, estado
global) entra por uma **interface** injetada no construtor. É isso que deixa o UseCase
ser testado sem levantar o mundo (Art. 4 da régua) e trocar o driver sem tocar a regra.

**Condicionais e assinaturas (Art. 4, 7):** prefira *early return* (guard clause) a
`if/else` aninhado; condicional que despacha pela mesma variante em vários pontos vira
**`match` exaustivo sobre uma classe de constantes** ou implementações da interface
(polimorfismo). Método passando de **~4 parâmetros** → agrupe num **DTO/objeto de
parâmetro**; *named arguments* (8.0) cobrem os opcionais sem inflar a assinatura.

**Substituto de enum em 8.0** — a construção que o time inteiro DEVE usar, para o
upgrade a 8.1 ser mecânico:

```php
final class OrderStatus
{
    public const OPEN = 'open';
    public const CLOSED = 'closed';

    private function __construct()
    {
    }

    /** @return string[] */
    public static function all(): array
    {
        return [self::OPEN, self::CLOSED];
    }
}

// Despacho exaustivo: match SEM default lança UnhandledMatchError para valor novo —
// é o mais perto de exaustividade de enum que 8.0 oferece.
$label = match ($status) {
    OrderStatus::OPEN   => 'Aberto',
    OrderStatus::CLOSED => 'Fechado',
};
```

**Padrões na prática (PHP 8.0)** — a construção idiomática vem **antes** do padrão
clássico (ver "Padrões de projeto" em `../core/ARCHITECTURE.md`):

- **Strategy/State** → `match` exaustivo sobre classe de constantes antes de
  hierarquia; hierarquia só quando as variantes carregam estado/dependências. Sem
  first-class callable (8.1): referência a callable é `Closure::fromCallable([$obj, 'method'])`
  ou closure explícita `fn($x) => $obj->method($x)`.
- **Factory** → *named constructor* estático (`fromArray()`, `fromRequest()`) antes de
  classe-fábrica dedicada; fábrica dedicada só quando a construção tem variantes reais.
- **Observer** → eventos do framework / PSR-14, nunca implementação manual do padrão.
- **Builder** → quase sempre desnecessário: *named arguments* + construtor com
  promotion resolvem os opcionais.
- **Armadilhas PHP:** Singleton e `static` mutável; *service location* (puxar do
  container) dentro de Domain/Application — a dependência entra pelo construtor;
  herança para reuso de código (prefira composição); setter público "só para o
  hydrator" que destrói a invariante que o construtor garantiu.

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceções, não códigos de retorno**, para condição excepcional. Fluxo normal ("não
encontrado" esperado) PODE ser `?T`/`null` — o nullsafe `?->` (8.0) encadeia sem
boilerplate; violação de regra é **exceção tipada**.

- **Domínio lança tipado:** `DomainException` (regra de negócio),
  `InvalidArgumentException` (entrada inválida no DTO/VO). Nunca lance `\Exception` cru.
- **8.0 endureceu o runtime a favor do padrão:** funções internas lançam `TypeError`/
  `ValueError` em argumento inválido (em vez de warning + `null`/`false`), e o **PDO
  nasce com `ERRMODE_EXCEPTION` por padrão** — não escreva código que dependa de
  retorno `false` silencioso dessas fontes. ⚠️ CONFIRMAR: o default `ERRMODE_EXCEPTION`
  do PDO a partir de 8.0 (documentado no guia de migração 7.4→8.0); ainda assim,
  declare o atributo **explicitamente** na criação da conexão (ver §6.1) para não
  depender de default.
- **Nunca engolir silenciosamente:** `catch (\Throwable) {}` vazio, ou o operador `@`,
  são proibidos — o erro some e o bug vira silencioso. (Em 8.0 o `@` deixou de
  silenciar erros fatais, mas segue escondendo warnings — segue proibido.) Se
  capturou, ou trata, ou re-lança com contexto. O *catch* sem captura (8.0) é para
  quando `$e` não é usado — não para esconder o tratamento.
- **Fronteira de conversão:** um único ponto (Action + handler global) captura
  `\Throwable`, loga o detalhe internamente e devolve ao cliente uma mensagem
  **genérica** com o status HTTP correto. O `$e->getMessage()` **não** vai cru para a
  resposta.

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
stack **do lado do servidor** — **nunca** senha, token, PII ou o corpo cru da
requisição.

**Armadilha comum — Information Disclosure:** sanear a mensagem só no *log* e devolver
o `$e->getMessage()` cru na resposta (inclusive dentro de um `success:false` com HTTP
200). O valor tem que ser saneado **no sink de resposta**, não só no de log. Stack
trace ao cliente em produção é vazamento — em runtime EOL (ver §1), vazamento de
versão/stack é ainda mais explorável. `display_errors=Off` em produção, sempre.

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> **⚠️ Postura EOL primeiro (ver §1):** PHP 8.0 não recebe patch de segurança desde
> 26/11/2023. Isso muda a régua desta seção: **não existe "o runtime corrige depois"**.
> Mitigação permanente enquanto o upgrade não sai:
>
> 1. **Plano de upgrade para versão suportada é o controle de segurança nº 1** — as
>    demais medidas abaixo são paliativas.
> 2. Rode `composer audit` no pipeline (§8) — as **dependências** ainda recebem
>    advisories mesmo com o runtime congelado; mantenha-as atualizadas dentro do que
>    o `config.platform.php: 8.0.x` permite.
> 3. Acompanhe CVEs publicados contra PHP ≤ 8.0 (NVD / `/keelson:audit` quando
>    disponível) e trate cada um como **sem correção disponível**: mitigue na camada
>    de aplicação/infra (WAF, desativar a feature afetada, validação extra).
> 4. Reduza superfície: extensões não usadas desabilitadas, `expose_php=Off`,
>    `display_errors=Off`.
>
> Cada item abaixo é um item da **Régua do Art. 2** traduzido para "como se faz e como
> se erra em PHP 8.0". Vulnerabilidade aqui é **rejeição imediata** no review. Este
> perfil é **gerado** (`reviewed: false`): as afirmações marcadas `⚠️ CONFIRMAR:` devem
> ser validadas pelo revisor humano antes de virarem doutrina.

### 6.1 Injeção → sempre parametrizar

**SQL — PDO com parâmetros NOMEADOS**, nunca concatenação nem interpolação de entrada:

```php
$pdo = new \PDO($dsn, $user, $pass, [
    \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION, // explícito, sem depender de default
    \PDO::ATTR_EMULATE_PREPARES   => false,                    // prepared statements reais no driver
    \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
]);

// ✅ prepared statement, parâmetros nomeados
$stmt = $pdo->prepare('SELECT id, name, email FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);

// ❌ NUNCA — concatenar/interpolar entrada externa é SQL Injection
$pdo->query("SELECT * FROM users WHERE email = '$email'");
```

- O que **não** dá para bindar (nome de coluna/tabela em `ORDER BY`) valida-se contra
  uma **whitelist** — nunca interpolando o input.
- **Command injection:** evite `exec/shell_exec/system/proc_open`; se inevitável,
  `escapeshellarg()` em **cada** argumento (e `escapeshellcmd()` não substitui — ele
  protege o comando, não os argumentos).
- **Path traversal:** `basename()` + validação contra diretório-base (`realpath()` e
  prefixo conferido); nunca abrir `file_get_contents($userInput)` cru.
- **Deserialização:** `unserialize()` sobre entrada externa é RCE em potencial — use
  `json_decode`; se `unserialize` for inevitável, passe
  `['allowed_classes' => false]`.

**Armadilha comum — HY093:** reusar o mesmo placeholder nomeado duas vezes no SQL com
`EMULATE_PREPARES=false` (`... WHERE a = :x OR b = :x`) estoura *"invalid parameter
number"*. Use nomes distintos ou passe o valor duas vezes com chaves diferentes.

### 6.2 Saída / escaping → escapar no destino

Escape é **por contexto de saída**, feito no ponto de renderização:

```php
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); // HTML — ENT_QUOTES OBRIGATÓRIO em 8.0
echo rawurlencode($value);                            // componente de URL
echo json_encode($value, JSON_THROW_ON_ERROR);        // contexto JS/JSON
```

- ⚠️ CONFIRMAR: em **PHP 8.0 o default de `htmlspecialchars()` ainda é `ENT_COMPAT`**
  — **não escapa aspas simples**; o default só passou a incluir `ENT_QUOTES |
  ENT_SUBSTITUTE` no PHP 8.1. Em 8.0, chamar `htmlspecialchars($v)` sem flags deixa
  XSS passar em atributo HTML com aspas simples. **Sempre** passe `ENT_QUOTES, 'UTF-8'`
  explicitamente (idealmente atrás de um helper único de escape — Art. 3).
- Numa API JSON, `json_encode` já escapa; num template (Twig/Blade), o autoescape cuida
  do HTML — **não** o desligue (`|raw`, `{!! !!}`) para dado de usuário. **Nunca**
  renderize entrada de usuário crua em HTML.
- **Header injection:** `header()` com entrada externa concatenada permite injetar
  CRLF; valide/normalize antes.

**Armadilha comum:** sanear o mesmo valor no log/persistência mas devolver cru na
resposta — o escaping tem que acontecer em **cada** sink de saída, independentemente.

### 6.3 Autorização → negar por padrão

Toda action verifica **permissão antes de executar**; o default é **negar**. A
checagem vive num middleware/guard, não espalhada dentro da regra.

- **IDOR / acesso por registro:** ter a permissão genérica não basta — verifique que o
  registro pertence/é visível ao solicitante (`WHERE owner_id = :currentUserId`).
- **Tenant/instância:** `instance_id` (e afins) tem **ponto único de população** a
  partir da **sessão server-side** — nunca de header/query/path. Leitor ausente
  **nega**, nunca assume default permissivo (`?? 1` é bug de segurança).
- **Serializador de dado sensível:** default **fail-closed** — omitir por padrão,
  expor por parâmetro explícito. Nunca `toArray(bool $includeFinancials = true)`.
- **Prova:** todo gate de autorização exige teste de integração provando **403 sem a
  permissão** (não só 200 com ela).

**Ganho de 8.0 sobre 7.x — comparações mais sãs:** em PHP ≤ 7.4, `0 == "foo"` era
`true` — fonte clássica de bypass de autenticação/autorização por *type juggling* em
comparações frouxas. Em 8.0, string não numérica comparada a número **não** vira `0`:
`0 == "foo"` é `false`. Isso **fecha uma classe de bypass** ao migrar de 7.x — e é um
argumento de segurança a favor do upgrade que trouxe o projeto até aqui.
⚠️ CONFIRMAR: a mudança cobre **número vs string**; **duas strings numéricas** seguem
comparadas numericamente (`'0e111' == '0e222'` continua `true` — o clássico "magic
hash"). Logo a regra do padrão permanece: `===` sempre, e `hash_equals()` para
comparar hashes/tokens (também elimina timing attack).

**Armadilha comum (framework de roteamento):** ler o argumento de rota do lugar errado
(ex.: atributo do request em vez do argumento da rota resolvida) devolve `null` e
**libera tudo silenciosamente**. Confirme a fonte e a **ordem dos middlewares**
(autorização depois do roteamento).

### 6.4 Segredos & configuração → fora do código, fora do log

- Segredos vêm de **variável de ambiente / secret store**, lidos via config —
  **nunca** hardcoded no fonte, **nunca** commitados (`.env` no `.gitignore`).
- Segredo **nunca** em log, em mensagem de erro, nem em **query string de URL**.
- **Senhas:** `password_hash($senha, PASSWORD_ARGON2ID)`; verificação com
  `password_verify()`; `password_needs_rehash()` no login para migrar hashes antigos.
  **Nunca** MD5/SHA1, nunca hash caseiro.
  - ⚠️ CONFIRMAR: `PASSWORD_ARGON2ID` existe desde o PHP 7.3, **mas só se o binário
    foi compilado com suporte a Argon2** (libargon2, ou via libsodium a partir do
    7.4). Confirme no ambiente-alvo com `defined('PASSWORD_ARGON2ID')`; se ausente,
    o fallback correto é `PASSWORD_BCRYPT` (o default `PASSWORD_DEFAULT` em 8.0) —
    não um hash caseiro.
- **Criptografia de dados:** use a extensão **sodium** (bundled desde o PHP 7.2):
  `sodium_crypto_secretbox` (simétrica autenticada), `sodium_crypto_box` (assimétrica),
  `sodium_memzero` para limpar segredo da memória. **Nunca** `mcrypt` (removida) nem
  construção caseira sobre `openssl_*` sem necessidade documentada.
- **Aleatoriedade:** tokens/nonces com `random_bytes()`/`random_int()` (CSPRNG) —
  nunca `rand()`/`mt_rand()`/`uniqid()` para valor de segurança.

```php
// ❌ NUNCA
error_log("password: $password");
// ✅ apenas identificador e ação
$logger->info('login_attempt', ['user_id' => $userId]);
```

### 6.5 Sessão & estado de autenticação

- **Cookies de sessão** com as três flags: `httponly` (JS não lê), `secure` (só
  HTTPS), `samesite=Strict|Lax` (anti-CSRF). A forma com array de opções existe desde
  o PHP 7.3 — disponível em 8.0:

```php
setcookie('session', $value, [
    'httponly' => true,
    'secure'   => true,
    'samesite' => 'Strict',
]);
// e no php.ini / session_set_cookie_params():
// session.cookie_httponly=1, session.cookie_secure=1, session.cookie_samesite=Strict
```

- Sessão é a **fonte de verdade** de identidade e tenant — regenere o id no login
  (`session_regenerate_id(true)`), expire por inatividade, invalide no logout
  (`session_destroy()` + cookie expirado).
- ⚠️ CONFIRMAR: `session.use_strict_mode=1` no `php.ini` (rejeita session id não
  iniciado pelo servidor — mitiga session fixation) é prática recomendada
  documentada para a era 8.0; validar a configuração do ambiente real.
- Token de autenticação **não** vai para `localStorage` (concern do front, mas o
  backend deve entregá-lo como cookie `httponly`).
- **CSRF:** forms de estado (POST/PUT/DELETE) exigem token anti-CSRF (gerado com
  `random_bytes()`, comparado com `hash_equals()`); APIs consumidas por SPA validam
  origem além da mesma-origem.

### 6.6 Dependências & upload (síntese)

- **Mass assignment:** monte a Entity a partir de um **DTO com campos whitelistados**
  — nunca `->fill($request->all())`.
- **Upload:** whitelist de extensão **e** validação de MIME real (`finfo`); nunca
  confie no nome/tipo enviado pelo cliente; arquivo salvo fora do docroot ou com
  execução negada.
- **Auditar dependência:** `composer audit` (ver §8) — em runtime EOL, é a única
  linha de defesa automatizada que ainda recebe atualização.

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico: PHPUnit 9** — a última série major que suporta PHP 8.0 (PHPUnit 10
exige PHP 8.1). Comando (alimenta `keelson.config.json → quality.test`):
`composer test` (que embrulha `vendor/bin/phpunit`).

**Convenções idiomáticas — atenção às diferenças para o exemplar 8.5:**

- **Annotations, não attributes:** o PHPUnit 9 usa docblocks — `/** @test */`,
  `@dataProvider`, `@group`. Os atributos `#[Test]`/`#[DataProvider]` só existem no
  PHPUnit 10+ (que não roda aqui). Não misture os dois estilos.
- **Sem intersection type nativo:** `UserRepositoryInterface&MockObject` como **tipo
  declarado** de propriedade é sintaxe de PHP 8.1 — em 8.0 **fatal-erra no parse**.
  Declare o tipo simples e documente a interseção no docblock (o IDE/PHPStan entende).
- **Mocks:** `PHPUnit\Framework\MockObject` via `$this->createMock(Interface::class)`.
  Não usar Mockery — mantenha um único mecanismo de mock na base.
- **Nomes reveladores de intenção:** o padrão do time (ex.: `deveXxx()` /
  `naoDeveXxx()`, ou `it_...`) — o que importa é ser **consistente** e descrever a
  regra sob teste.
- **AAA:** Arrange → Act → Assert, blocos longos separados visualmente.
- **Agrupamento:** `@group` para separar testes que precisam de banco dos puramente
  unitários (o gate roda o subconjunto certo).

```php
/**
 * @group skip-migration
 */
final class CreateUserUseCaseTest extends TestCase
{
    /** @var UserRepositoryInterface&MockObject */
    private MockObject $repo; // tipo simples: interseção declarada só no docblock (8.0!)

    private CreateUserUseCase $useCase;

    protected function setUp(): void
    {
        $this->repo = $this->createMock(UserRepositoryInterface::class);
        $this->useCase = new CreateUserUseCase($this->repo);
    }

    /** @test */
    public function deveCriarUsuarioQuandoEmailInedito(): void
    {
        // ═══════════ Arrange ═══════════
        $this->repo->method('emailExists')->willReturn(false);
        $this->repo->method('save')->willReturnArgument(0);

        // ═══════════ Act ═══════════
        $user = $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));

        // ═══════════ Assert ═══════════
        $this->assertSame('John', $user->name());
    }

    /** @test */
    public function naoDeveCriarComEmailExistente(): void
    {
        $this->repo->method('emailExists')->willReturn(true);

        $this->expectException(\DomainException::class);
        $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));
    }
}
```

**Testar comportamento, não implementação:** prove a regra de negócio, cálculos
críticos, validações de domínio e edge cases. Não teste getter trivial, nem "a classe
instanciou", nem infraestrutura externa. Mocke as **fronteiras** (interfaces de
repositório/serviço); nunca mocke a unidade sob teste.

**Fixtures / dados compartilhados (Art. 3):** teste de repositório/endpoint que
precisa de banco roda num **SQLite em memória**, e o **schema e os dados de teste
vivem num helper central** (por convenção, sob `tests/Support/`) — um método por
tabela para o schema, um builder com defaults+overrides por linha. Declarar
`CREATE TABLE`/`INSERT` **inline** no teste é a mesma violação DRY dos helpers de
produção: cópias divergem e quebram em massa por *drift*. Coluna nova → edite o
helper, num lugar só.

> ⚠️ **SQLite ≠ o banco de produção.** O teste em SQLite não substitui o *smoke*
> contra o banco real (MySQL/Postgres) quando o SQL do repositório muda — construções
> específicas do dialeto (e erros como HY093) só aparecem lá.

**Régua (Art. 1):** existe teste que **falha se o comportamento regredir**. Gate de
autorização exige o teste de **403 sem permissão**, com o stack HTTP e a ordem de
middlewares de produção. Migração 7.x→8.0: os comportamentos que mudaram (§11) DEVEM
estar cobertos por teste — é o oráculo que prova que o upgrade não regrediu regra.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador: Composer 2.** `composer.json` declara, `composer.lock` **fixa** — o
lock é **commitado** para builds reprodutíveis. (Composer 1 é EOL — não usar.)

- **Trave a plataforma:** em `composer.json`, `config.platform.php: "8.0.x"` — impede
  o Composer de resolver pacotes que exigem PHP mais novo do que a produção roda,
  mesmo quando a máquina do dev tem 8.3. Sem isso, o lock mente sobre a produção.
- **Política de versão:** constraints com caret (`^2.4`) para libs maduras; o `.lock`
  garante a versão exata em CI/produção. `composer install` em CI (respeita o lock),
  `composer update` só deliberadamente. Em runtime EOL, muitas libs **abandonam** o
  suporte a 8.0 nas majors novas — atualizar dependência aqui exige conferir o
  constraint de PHP dela, e a distância acumulada é mais um argumento para o upgrade.
- **Auditar vulnerabilidade conhecida:** `composer audit` no pipeline — reprovar em
  vulnerabilidade de severidade relevante, **citando o CVE/advisory ID** reportado.
  - O comando existe desde o **Composer 2.4**, que roda em PHP 7.2+ — logo
    **compatível com PHP 8.0**; garanta `composer --version` ≥ 2.4 no CI.
  - ⚠️ CONFIRMAR: o advisory database consultado é o da **Packagist.org security
    advisories API**, que agrega o **FriendsOfPHP/security-advisories** e advisories
    do GitHub — confirmar a composição exata das fontes na documentação do Composer
    da versão instalada.
  - Alternativa/reforço: `roave/security-advisories` como dev-dependency (impede
    **instalar** versão vulnerável, no resolver) — complementa, não substitui, o
    `composer audit` (que detecta vulnerabilidade no que **já está** no lock).
- **Higiene:** `composer outdated` para atrasos; evite pacote **abandonado** (o
  Packagist marca `abandoned`) e confira **licença** compatível antes de adicionar.
- **Autoload PSR-4:** classe nova exige `composer dump-autoload` (ou `-o` em
  produção) para entrar no mapa.

**Armadilha comum:** não commitar o `composer.lock` (ou rodar `composer update` no
deploy) — cada ambiente resolve versões diferentes e o bug "só na produção" nasce aí.
Em 8.0 a variante piora: o dev com PHP 8.3 local e sem `config.platform.php` gera um
lock que a produção 8.0 **não consegue nem instalar**.

---

## 9. Reúso: o que já existe → Charter Art. 3

**Antes de escrever** helper, validação, conversão, DTO ou trait, **procure o
equivalente** — reimplementar o que existe (ou duplicar entre arquivos) é proibido,
mesmo que o código fique correto.

- **Casting/parse de entrada** (string→int/float/date, com null-safety) mora num
  **trait canônico de parsing** consumido por todos os DTOs — nunca reimplemente o
  conversor.
- **Par Create/Update** de um domínio compartilha validação/sanitização num **trait
  do domínio** — nunca duplique a regra entre os dois DTOs.
- **Conceito de domínio recorrente** (CPF, e-mail, código) vira **Value Object**
  único, não validação repetida em cada ponto de uso.
- **Escape de saída** atrás de um helper único por contexto (ver §6.2 — o `ENT_QUOTES`
  obrigatório de 8.0 é exatamente o tipo de detalhe que não pode depender de cada
  chamador lembrar).
- **Prefira a stdlib e o framework** antes de rolar o seu: `str_contains`/
  `str_starts_with` (8.0 — não reimplemente com `strpos`), `filter_var`, `array_*`,
  `password_hash`, `DateTimeImmutable`, o QueryBuilder/HTTP client do framework.

**Como descobrir o que já existe:** busca por nome/conceito no `codePaths` da ficha;
**um guard determinístico** (teste de arquitetura) que **reprova** a reimplementação
de um conversor canônico é o mecanismo ideal — transforma "lembre de reusar" em falha
de build.

**Régua (Art. 3):** a mudança não introduz um **segundo caminho** para algo que já
existia; quando o conceito se repetiu, ele foi **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

O custo patológico mais comum em backend PHP é o **round-trip de banco em laço** (N+1):

```php
// ❌ N+1 — uma query POR item
foreach ($this->orderRepo->findAll() as $order) {
    $customer = $this->customerRepo->findById($order->customerId());
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
- **Paginação** (`LIMIT`/`OFFSET`) em toda listagem de tamanho variável; **índice**
  nas colunas de `WHERE`/`ORDER BY`.
- **Grandes volumes:** `fetch()` linha a linha ou **generator (`yield`)** em vez de
  `fetchAll()` (não materializa o array inteiro na memória); `unset()` em variáveis
  grandes após uso.
- **Trabalho pesado** (import/export, e-mail, webhook) vai para **fila/job**, não no
  request.
- **OPcache ligado** em produção; *preloading* (desde 7.4) para o hot path do
  framework.
- **JIT (novo em 8.0):** ganha em carga CPU-bound; em web app I/O-bound o ganho é
  tipicamente marginal — **ligue só com medição** que o justifique (Art. 8: medida,
  não presumida).

**Ferramenta de medição idiomática:** `EXPLAIN` no banco **real** (não no SQLite de
teste) para plano de query; **Xdebug profiler** ou **Blackfire** para CPU/memória do
PHP. **Régua (Art. 8):** não há query/round-trip dentro de laço sobre dados de
tamanho variável; otimização não óbvia **cita a medição** que a justifica — nunca
palpite.

**Armadilha comum:** `fetchAll()` num resultado grande e depois iterar — dobra o pico
de memória à toa; o `fetch()` em cursor faz o mesmo trabalho com pegada constante.

---

## 11. Gotchas da versão (8.0) → Charter Art. 1, 7

**Vindo de 7.4 (o upgrade que muitos legados acabaram de fazer) — o que quebra:**

- **Comparações string/número mudaram:** `0 == "foo"` era `true` em 7.x, é **`false`**
  em 8.0. Código 7.x que dependia da coerção antiga muda de comportamento
  silenciosamente — todo `==` envolvendo entrada externa DEVE virar `===` na
  migração (e ganhou-se segurança de graça: §6.3).
- **Funções internas lançam `TypeError`/`ValueError`** em argumento inválido, em vez
  de warning + `null`/`false`. O código 7.x que checava `=== false` depois da chamada
  agora **nem chega lá** — a exceção sobe antes. Cubra os caminhos com teste.
- **Resources viraram objetos** (`CurlHandle`, `GdImage`, `Socket`, `XMLParser`…):
  `is_resource()` sobre eles agora retorna `false` e quebra guardas antigas — troque
  por `instanceof` ou checagem de `false`.
- **PDO nasce com `ERRMODE_EXCEPTION`** (era `ERRMODE_SILENT`): código que ignorava
  retorno falso de `query()`/`execute()` agora recebe exceção — bom para o padrão
  (§5), fatal para quem não tem handler de fronteira.
- **Precedência de `.` mudou:** `'x' . $a + $b` agora avalia `$a + $b` primeiro
  (era warning em 7.4, mudou em 8.0). Parentetize.
- **Removidos:** `each()`, `create_function()`, `$str{0}` (chaves para offset),
  cast `(real)`, `get_magic_quotes_gpc()`, construtores estilo PHP 4, e a opção
  `salt` de `password_hash()` (o salt é sempre gerado pela função).
- **Sorts ficaram estáveis** em 8.0: elementos iguais preservam a ordem relativa —
  se algum teste dependia da instabilidade antiga, ele estava testando acidente.
- **`match` lança `UnhandledMatchError`** para valor não coberto — é feature
  (exaustividade), mas quem porta um `switch` sem `default` precisa saber que agora
  **explode em runtime** em vez de cair silenciosamente.
- **Named arguments viram contrato:** renomear parâmetro é breaking change (§3).

**Vindo de 8.1+ para trás (dev acostumado com versão nova, gerando código para 8.0)
— o que NEM COMPILA aqui:**

- `enum` → use a classe de constantes + `match` (§4).
- `readonly` em propriedade/classe → propriedade `private` promovida + getter, sem
  setter (§4).
- First-class callable `f(...)` → `Closure::fromCallable('f')` ou
  `fn($x) => f($x)`.
- Intersection types declarados (`A&B`) → tipo simples + docblock (§7).
- `never`, `new` em inicializador, fibers, DNF types, `#[\Override]`,
  property hooks, `array_find`/`array_first`, pipe `|>` → não existem; o code
  review DEVE barrar sugestão de IA/copy-paste que os traga.

**Régua (Art. 1/7):** quem vem de outra versão precisa que essas surpresas estejam
**cobertas por teste** (ex.: um teste sobre o caminho que dependia de `== ` frouxo,
ou sobre a exceção nova do PDO) e **comentadas com o porquê** onde a escolha não é
óbvia (ex.: por que a classe de constantes existe em vez de `enum`).

---

## 12. Ferramentas & comandos

Estes comandos são a ponte entre a doutrina (este perfil) e a automação (os gates
leem a ficha). Cada linha alimenta `keelson.config.json → quality.*`. Todo o
ferramental abaixo foi escolhido pela **compatibilidade com PHP 8.0** — versões
majors mais novas de algumas ferramentas exigem PHP 8.1+ e não servem aqui:

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `composer test` (embrulha `vendor/bin/phpunit` — **PHPUnit 9.x**; a série 10 exige PHP 8.1) | `quality.test` |
| **lint** | `vendor/bin/php-cs-fixer fix --dry-run --diff` (exige PHP ≥ 8.0.1 — ver §2) ou `vendor/bin/phpcs --standard=PSR12 src tests` (PHP_CodeSniffer) | `quality.lint` |
| **typecheck** | `vendor/bin/phpstan analyse` (ou `vendor/bin/psalm`) — PHP não tem compilador; o **analisador estático** cumpre esse papel. Configure `phpVersion: 80000` no `phpstan.neon` para o analisador reprovar sintaxe de 8.1+ que o runtime não aceita. Opcional, mas **fortemente recomendado em legado EOL**; se não adotado, `null`. | `quality.typecheck` |
| **build** | **não se aplica** — PHP é interpretado. O "build" de deploy é `composer install --no-dev --optimize-autoloader` + warmup de OPcache, não um passo de gate. | `quality.build` (`null`) |

Complemento fora do gate, mas obrigatório no pipeline (§8): `composer audit`
(Composer ≥ 2.4).

Exemplo de ficha correspondente:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "8.0" } },
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
charter (prova externa e falsificável) fica sem executor. E num runtime EOL, o
analisador estático com `phpVersion` pinado é também o guard que impede sintaxe de
8.1+ de entrar na base (§11).
