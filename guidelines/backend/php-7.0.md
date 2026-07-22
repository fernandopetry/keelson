---
lang: php
version: "7.0"
charter: 0.3.0
generated-by: profile-writer
reviewed: false
reviewer: null
---

# PHP 7.0 — Perfil de linguagem

> Instância do `QUALITY-CHARTER.md` (v0.3.0) para **PHP 7.0** — perfil de **legado**,
> gerado pelo `profile-writer` e **pendente de revisão humana** (`reviewed: false`).
> Cada seção pega um artigo do charter e responde: *"em PHP 7.0, isto se cumpre assim,
> com esta ferramenta, com esta armadilha a evitar"*. Mesma espinha (seções 0–12) do
> exemplar PHP 8.5, conteúdo restrito ao que **existe** em 7.0.
>
> **Escopo:** o que é idiomático de PHP 7.0. A arquitetura **específica do projeto**
> (nomes de camadas próprios, caminhos reais) mora em `guidelines/project/` e na ficha
> `keelson.config.json`; aqui, os nomes de pasta são placeholders genéricos (`src/`,
> `tests/`) e os namespaces usam `App\` como raiz de exemplo.

---

## 1. Identidade & versão

> ⚠️ **PHP 7.0 está em fim de vida (EOL).** Suporte ativo terminou em 03/12/2017 e o
> suporte de segurança em **10/01/2019** — o runtime **não recebe correção de
> vulnerabilidade** do projeto PHP há anos. Este perfil existe para manter um legado
> **sob controle**, não para legitimar a versão. A recomendação permanente deste perfil
> é: **plano de upgrade registrado** (7.0 → 7.4 como degrau, depois 8.x), e toda mudança
> nova escrita de forma a **facilitar** essa migração (strict_types, tipos escalares,
> PDO parametrizado), nunca a dificultar.

O alvo é **PHP 7.0** (lançado em dezembro de 2015 — a primeira versão da série 7, com o
engine reescrito vindo do 5.x). `declare(strict_types=1)` é **obrigatório** no topo de
todo arquivo novo — sem coerção silenciosa de tipo.

**Recursos DESTA versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| **`declare(strict_types=1)`** | Obrigatório em todo arquivo novo | 7.0 |
| **Scalar type hints** (`int`, `float`, `string`, `bool`) | Em todo parâmetro | 7.0 |
| **Return type declarations** (`: int`, `: User`) | Em todo método/função | 7.0 |
| **Null coalescing `??`** | Substitui `isset($x) ? $x : $default` | 7.0 |
| **Spaceship `<=>`** | Comparação em `usort` e afins | 7.0 |
| **Anonymous classes** | Fakes/stubs pontuais em teste | 7.0 |
| **`random_bytes()` / `random_int()`** | CSPRNG nativo — tokens, nonces | 7.0 |
| **`Throwable` / `Error`** | Erros de engine capturáveis; hierarquia unificada | 7.0 |
| **`yield` / `yield from`** | Generators para grandes volumes | 5.5 / 7.0 |
| **`intdiv()`**, group `use`, `Closure::call()` | Idiomas da versão | 7.0 |
| **`unserialize($s, ['allowed_classes' => ...])`** | Filtro de classes na desserialização | 7.0 |
| **`session_start([...])` com options** | Flags de cookie de sessão no início | 7.0 |

**Recursos de versões FUTURAS que NÃO existem aqui (NÃO usar — fatal/parse error):**

- **7.1:** nullable types `?T`, `void`, `iterable`, multi-catch `catch (A | B)`,
  visibilidade em constante de classe, `list()` com chaves;
- **7.2:** type hint `object`, argumento `$tag` (AEAD) em `openssl_encrypt`;
- **7.3:** `JSON_THROW_ON_ERROR`, `setcookie()` com array de opções (`samesite`),
  `array_key_first/last`, heredoc flexível;
- **7.4:** typed properties, arrow functions `fn()`, `??=`, spread em array,
  covariância de retorno, preloading;
- **8.x:** enums, `readonly`, `match`, named arguments, constructor promotion,
  atributos `#[...]`, union types, `str_contains`.

**Construções antigas que NÃO DEVEM aparecer (mesmo as que ainda rodam em 7.0):**

- `mysql_*` e `ereg*` — **removidos em 7.0**; código 5.x migrado tem que ir para
  **PDO** (preferido) ou `mysqli` com bind;
- **`mcrypt_*`** — ainda existe em 7.0, mas é **proibido por política**: deprecado em
  7.1 e removido em 7.2, com upstream (libmcrypt) abandonado. Criptografia via
  `openssl_*` ou libsodium (ver §6.4);
- construtores estilo PHP 4 (método com o nome da classe) — **deprecados em 7.0**
  (removidos em 8.0): use `__construct`;
- `each()`, `create_function()`, `@` (supressor de erro), variáveis globais de
  request (`$HTTP_RAW_POST_DATA` foi **removida** — use `php://input`).

**Por que a versão é seção de primeira classe:** código escrito "para PHP 7" genérico
com `?T` ou `void` **não parseia** em 7.0 — quebra no deploy, não no lint. O alvo é
7.0 exato, e o gate deve rodar sobre um binário 7.0.

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Guia canônico:** **PSR-12** (compatível com código 7.0; PSR-2 é o baseline histórico
da era e continua aceitável se o projeto já o usa — escolha **um** e cabeie na ficha).

- **Formatter/linter viáveis em runtime 7.0:**
  - `squizlabs/php_codesniffer` **3.x** (`phpcs`/`phpcbf`) — roda em PHP antigo e traz
    o ruleset `PSR12` a partir da 3.5. ⚠️ CONFIRMAR: faixa exata de PHP suportada pelo
    phpcs 3.x (documentação indica PHP 5.4+) e a versão mínima 3.5 para o ruleset PSR12.
  - `friendsofphp/php-cs-fixer` **^2** — a série 2.x suporta PHP 5.6–7.4 (confirmado na
    documentação de instalação). ⚠️ CONFIRMAR: em qual release 2.x entrou o ruleset
    `@PSR12` (a série começou com `@PSR2`); se a 2.x instalada não tiver `@PSR12`,
    use `@PSR2` + fixers avulsos.
- **É erro (bloqueia):** violação do ruleset escolhido; ausência de
  `declare(strict_types=1)` em arquivo novo; import não usado; uso de função removida
  ou proibida (§1).
- **É aviso (não bloqueia):** ordenação de `use`, largura de linha acima do alvo quando
  quebrar prejudica leitura — decisão do time, não do gate.
- **Comando de lint** (alimenta `keelson.config.json → quality.lint`):
  `vendor/bin/phpcs --standard=PSR12 src tests`
  (ou `vendor/bin/php-cs-fixer fix --dry-run --diff` na série 2.x).

**Armadilha comum:** rodar a ferramenta de lint num binário PHP moderno "porque é o que
tem na máquina" e o runtime de produção ser 7.0 — o lint passa e o parse de produção
quebra (ou vice-versa). O **sniff de compatibilidade de versão**
(`PHPCompatibility/PHPCompatibility` com `testVersion 7.0`) transforma "não use ?T"
em falha de build. ⚠️ CONFIRMAR: faixa de instalação do PHPCompatibility compatível com
phpcs 3.x em runtime 7.0.

---

## 3. Nomenclatura & idioma → Charter Art. 5

**Convenção por símbolo** (PSR-1/PSR-4, sem exceção — idêntica à do exemplar; a
convenção não depende da versão):

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Classe / Interface / Trait | `PascalCase` | `CreateUserUseCase` |
| Método / função / variável / propriedade | `camelCase` | `findById`, `$emailExists` |
| Constante de classe / global | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Arquivo | idêntico ao FQCN (PSR-4), 1 classe por arquivo | `CreateUserUseCase.php` |

**Padrões de nome que sinalizam papel** — o nome revela a intenção antes do corpo:

- `*Interface` (contrato de domínio) · `Pdo*Repository` (implementação PDO) ·
  `*UseCase` (um caso de uso, um `execute()`) · `*Action`/`*Controller` (entrada HTTP) ·
  `*DTO` (transporte, sem lógica) · `*Test` (teste da classe homônima).
- Value Object nomeado pelo **conceito** (`Email`, `Cpf`), não pelo tipo primitivo.
- Em 7.0 não há enums: **constantes de classe** agrupadas numa classe nomeada pelo
  conceito (`OrderStatus::OPEN`) fazem esse papel — nunca strings mágicas espalhadas.
  (Nota 7.0: constante de classe **não aceita** modificador de visibilidade — isso é
  7.1; todas são públicas.)

**Idioma:** identificadores em **inglês** — norma do ecossistema (stdlib, PSR, libs).
O idioma dos **comentários** é decisão do projeto (registrada em `guidelines/project/`),
mas **DEVE ser único e consistente** na base — legados 5.x→7.0 costumam misturar; código
novo segue a convenção registrada, e a unificação do restante entra no plano de
migração, não no diff da feature.

**Armadilha comum:** nomear pela implementação (`$arrayDeUsers`, `processData`) em vez
da intenção (`$activeUsers`, `deactivateExpiredContracts`). Em legado isso se agrava:
o nome herdado que mente (`save()` que também envia e-mail) **DEVE** ser renomeado ou
ter o efeito extraído quando tocado (Art. 5 — o nome cobre os efeitos colaterais).

---

## 4. Estrutura & arquitetura → Charter Art. 4, 7

O padrão idiomático continua **Clean/Hexagonal**, com dependência apontando para dentro:

```
Presentation → Application → Domain ← Infrastructure
```

| Camada | PODE conter | NÃO PODE conter |
|--------|-------------|-----------------|
| **Domain** | Entities, Value Objects, interfaces de repositório | Framework, PDO, HTTP, SQL |
| **Application** | UseCases, DTOs, orquestração | Request/Response, SQL, detalhes de I/O |
| **Infrastructure** | Implementar as interfaces do Domain (PDO, HTTP client) | Regra de negócio |
| **Presentation** | Actions/Controllers, Middleware, mapear HTTP↔DTO | Regra de negócio, SQL |

**Blocos idiomáticos em 7.0** (sem typed properties, sem `readonly`, sem promotion —
a disciplina que em 8.x é sintaxe aqui é **convenção + validação no construtor**):

- **Entity** — identidade + invariantes; propriedades **`private`** (o docblock `@var`
  supre o typed property ausente), mutação só por método de domínio nomeado.
- **Value Object** — `final`; valida no construtor e **lança** se inválido; sem setter;
  `equals()` por valor. É a forma 7.0 de imutabilidade: sem `readonly`, a garantia vem
  de não existir caminho de escrita.
- **DTO** — transporte; propriedades privadas + getters (ou públicas, se o time
  padronizar assim — consistência acima de gosto); fábrica estática `fromArray()`;
  **sem** lógica de negócio.
- **UseCase** — um `execute()`; recebe DTO, devolve Entity/resultado; depende de
  **interfaces**, injetadas pelo construtor.
- **Repository** — interface no Domain, implementação PDO na Infrastructure;
  `hydrate()` privado; **sem** regra de negócio.
- **Action/Controller** — zero lógica; mapeia entrada→DTO→UseCase e resultado→resposta.

```php
<?php
declare(strict_types=1);

namespace App\Application\UseCases\User;

use App\Domain\Entities\User\User;
use App\Domain\Repositories\User\UserRepositoryInterface;

final class CreateUserUseCase
{
    /** @var UserRepositoryInterface */
    private $repo; // 7.0: sem typed property — docblock + injeção tipada no construtor

    public function __construct(UserRepositoryInterface $repo)
    {
        $this->repo = $repo; // depende da ABSTRAÇÃO, nunca do PDO concreto
    }

    public function execute(CreateUserDTO $dto): User
    {
        if ($this->repo->emailExists($dto->getEmail())) {
            throw new \DomainException('Email already registered');
        }

        return $this->repo->save(User::fromDto($dto));
    }
}
```

**Isolamento de efeito colateral:** todo I/O (banco, rede, filesystem, relógio, estado
global) entra por **interface** injetada no construtor — é o que deixa o UseCase ser
testado sem levantar o mundo (Art. 4) e o que desacopla a regra do legado procedural
ao redor.

**Condicionais e assinaturas (Art. 4, 7):** prefira *early return* (guard clause) a
`if/else` aninhado. Sem `match` (8.0), condicional que despacha pela mesma variante em
vários pontos vira **polimorfismo** (implementações da interface) — um `switch` só é
aceitável **num único ponto** (a fábrica que escolhe a implementação), nunca repetido.
Método passando de **~4 parâmetros** → agrupe num **objeto de parâmetro/DTO**; sem
named arguments (8.0), parâmetros opcionais em cadeia são armadilha — o objeto de
parâmetro resolve.

**Padrões na prática (PHP 7.0)** — a construção idiomática antes do padrão clássico
(instancia "Padrões de projeto" de `../core/ARCHITECTURE.md`):

- **Strategy/State** → interface + implementações (polimorfismo clássico); closures
  (`\Closure`) para variação simples e local. Sem enums/match, a hierarquia pequena é
  a forma idiomática — não simule enum com arrays mágicos.
- **Factory** → *named constructor* estático (`fromArray()`, `fromRequest()`) antes de
  classe-fábrica; fábrica dedicada quando a construção tem variantes reais (é onde o
  único `switch` de despacho mora).
- **Observer** → eventos do framework, ou uma lib de eventos compatível com a era.
  ⚠️ CONFIRMAR: `psr/event-dispatcher` (PSR-14) requer PHP 7.2 — em 7.0, usar o event
  dispatcher do próprio framework ou lib compatível (ex.: `league/event` 2.x).
- **Builder** → em 7.0 tem **mais** justificativa que em 8.x: sem named arguments,
  construção com muitos opcionais fica ilegível — builder ou objeto de parâmetro são a
  saída idiomática. Ainda assim, só com dor presente (Art. 4), não por antecipação.
- **Armadilhas PHP:** Singleton e `static` mutável; *service location* (puxar do
  container/registry global) dentro de Domain/Application — a dependência entra pelo
  construtor; herança para reuso de código (prefira composição). Em legado 5.x→7.0,
  o registry global é o padrão herdado mais comum — código novo **não** o estende.

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceções, não códigos de retorno**, para condição excepcional. Fluxo normal ("não
encontrado" esperado) PODE ser `null` documentado com `@return User|null` (o tipo de
retorno nullable `?User` **não existe** em 7.0 — nesse caso omita o return type nativo
e documente, ou modele um objeto de resultado); violação de regra é **exceção tipada**.

- **PHP 7.0 unificou a hierarquia:** erros fatais do engine viraram `\Error`
  (`TypeError`, `ParseError`, `DivisionByZeroError`, `AssertionError`), e
  `\Throwable` é o topo que cobre `\Error` + `\Exception`. O handler de fronteira
  captura `\Throwable` — `catch (\Exception)` **deixa passar** os `Error` do engine
  (gotcha clássico de quem veio do 5.x).
- **Domínio lança tipado:** `DomainException` (regra de negócio),
  `InvalidArgumentException` (entrada inválida em DTO/VO). Nunca lance `\Exception` cru.
- **Sem multi-catch:** `catch (A | B)` é **7.1** — em 7.0, blocos `catch` separados
  (ou capturar o ancestral comum quando o tratamento é idêntico).
- **Nunca engolir silenciosamente:** `catch` vazio e o operador `@` são proibidos —
  se capturou, ou trata, ou re-lança com contexto.
- **Fronteira de conversão:** um único ponto (Action/Controller + handler global)
  captura `\Throwable`, loga o detalhe internamente e devolve ao cliente mensagem
  **genérica** com o status HTTP correto. `$e->getMessage()` **não** vai cru na resposta.

```php
try {
    $user = $this->useCase->execute($dto);
    return $this->ok($response, $user->toArray());
} catch (\InvalidArgumentException $e) {
    return $this->error($response, 'Validation failed', 422); // sem stack, sem interno
} catch (\DomainException $e) {
    return $this->error($response, $e->getMessage(), 400);    // mensagem de negócio, curada
} catch (\Throwable $e) {                                     // pega Exception E Error (7.0+)
    $this->logger->error('user.create.failed', ['exception' => $e]); // detalhe no log
    return $this->error($response, 'Internal error', 500);    // genérico para o cliente
}
```

**O que logar (Art. 2):** identificadores e ação (`user_id`, `action`), exceção com
stack **do lado do servidor** — **nunca** senha, token, PII ou corpo cru da requisição.
Em produção: `display_errors=Off`, `log_errors=On` — legado 7.0 com `display_errors`
ligado é vazamento de path/SQL/stack direto na tela.

**Armadilha comum — Information Disclosure:** sanear a mensagem só no *log* e devolver
`$e->getMessage()` cru na resposta (inclusive num `success:false` com HTTP 200). O
saneamento é **no sink de resposta**, não só no de log.

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> ⚠️ **Postura EOL primeiro:** PHP 7.0 não recebe patch de segurança desde
> **10/01/2019**. Toda CVE do interpretador/extensões desde então está **aberta** num
> runtime 7.0 puro. Mitigação mínima enquanto o upgrade não sai: (a) **plano de
> upgrade registrado como recomendação permanente** deste perfil; (b) superfície
> reduzida — extensões não usadas desabilitadas, `expose_php=Off`; (c) camadas
> externas compensando (WAF/proxy, rede segregada); (d) ⚠️ CONFIRMAR: se o runtime é
> de distro enterprise (RHEL/Debian LTS/Ubuntu ESM), verificar se o pacote recebe
> **backports** de segurança do distribuidor — isso muda a avaliação de risco, mas
> não elimina a recomendação de upgrade.
>
> Cada item abaixo traduz a **Régua do Art. 2** para "como se faz e como se erra em
> PHP 7.0". Vulnerabilidade aqui é **rejeição imediata** no review. Perfil gerado por
> IA: afirmações inferidas estão marcadas `⚠️ CONFIRMAR:` para dirigir a revisão.

### 6.1 Injeção → sempre parametrizar

**SQL — PDO com parâmetros nomeados** (disponível e idiomático em 7.0), nunca
concatenação nem interpolação de entrada:

```php
// ✅ prepared statement, parâmetros nomeados
$stmt = $pdo->prepare('SELECT id, name, email FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);

// ❌ NUNCA — concatenar/interpolar entrada externa é SQL Injection
$pdo->query("SELECT * FROM users WHERE email = '$email'");
```

- Ligue `PDO::ATTR_EMULATE_PREPARES => false` (prepared statements reais no driver) e
  `PDO::ERRMODE_EXCEPTION`.
- **Legado migrado de 5.x:** `mysql_*` foi **removido em 7.0** — a migração correta é
  para PDO parametrizado; migrar para `mysqli` com interpolação é trocar de API e
  manter a vulnerabilidade. `mysqli` só com `prepare`/`bind_param`.
- O que **não** dá para bindar (nome de coluna/tabela em `ORDER BY`) valida-se contra
  **whitelist** — nunca interpolando o input.
- **Command injection:** evite `exec/shell_exec/system/backticks`; se inevitável,
  `escapeshellarg()` em **cada** argumento.
- **Path traversal:** `basename()` + resolução com `realpath()` validada contra o
  diretório-base; nunca `file_get_contents($userInput)` / `include $userInput` crus.
- **Desserialização:** **nunca** `unserialize()` de entrada externa. Se inevitável,
  use o filtro de 7.0: `unserialize($s, ['allowed_classes' => false])` — e prefira
  `json_decode` como formato de troca.

**Armadilha comum — HY093:** reusar o mesmo placeholder nomeado duas vezes no SQL com
`EMULATE_PREPARES=false` (`... WHERE a = :x OR b = :x`) estoura *"invalid parameter
number"*. Use nomes distintos ou passe o valor duas vezes com chaves diferentes.

### 6.2 Saída / escaping → escapar no destino

Escape é **por contexto de saída**, no ponto de renderização:

```php
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); // HTML
echo rawurlencode($value);                            // componente de URL
$json = json_encode($value);                          // contexto JS/JSON — ver nota
if ($json === false) {                                // 7.0 NÃO tem JSON_THROW_ON_ERROR (7.3)
    throw new \RuntimeException('JSON encode failed: ' . json_last_error_msg());
}
```

- **`JSON_THROW_ON_ERROR` não existe em 7.0** — o cheque explícito de
  `json_encode() === false` / `json_last_error()` é obrigatório no helper canônico de
  resposta (um lugar só — Art. 3).
- Em template engine da era (Twig 1.x/2.x, Blade), o **autoescape** cuida do HTML —
  **não** o desligue (`|raw`, `{!! !!}`) para dado de usuário. Em legado com
  `echo`/HTML misturado, **todo** `echo` de dado externo passa por
  `htmlspecialchars(..., ENT_QUOTES, 'UTF-8')` — sem exceção.
- Header injection: valores de `header()` derivados de input validados/normalizados
  (⚠️ CONFIRMAR: PHP ≥ 5.1.2 já bloqueia CR/LF em `header()` — confirmar que o cheque
  cobre os vetores no build 7.0 em uso; não confiar só nele).

**Armadilha comum:** sanear o valor no log/persistência e devolver cru na resposta —
o escaping acontece em **cada** sink de saída, independentemente.

### 6.3 Autorização → negar por padrão

Toda action verifica **permissão antes de executar**; o default é **negar**. A checagem
vive num middleware/front controller, não espalhada dentro da regra.

- **IDOR / acesso por registro:** a permissão genérica não basta — verifique que o
  registro pertence/é visível ao solicitante (`WHERE owner_id = :currentUserId`).
- **Tenant/instância:** o identificador de tenant tem **ponto único de população** a
  partir da **sessão server-side** — nunca de header/query/path. Leitor ausente
  **nega**; `?? 1` como fallback de tenant é bug de segurança (o `??` de 7.0 torna esse
  erro confortável de escrever — reprove no review).
- **Legado sem middleware:** apps 7.0 antigos costumam checar login por `include` de um
  `auth.php` no topo de cada script — o esquecimento de um `include` é acesso aberto.
  Código novo centraliza a checagem num **front controller único**; scripts soltos fora
  dele são dívida a eliminar no plano de migração.
- **Serialização de dado sensível:** default **fail-closed** — omitir por padrão, expor
  por parâmetro explícito. Nunca `toArray($includeFinancials = true)`.
- **Prova:** todo gate de autorização exige teste provando **403 sem a permissão**
  (não só 200 com ela).

### 6.4 Segredos, senhas & criptografia → fora do código, fora do log

- Segredos vêm de **variável de ambiente / secret store**, lidos via config — nunca
  hardcoded, nunca commitados (`.env` no `.gitignore`; `vlucas/phpdotenv` 2.x é
  compatível com a era. ⚠️ CONFIRMAR: faixa de versão do phpdotenv instalável em 7.0).
- Segredo **nunca** em log, em mensagem de erro, nem em **query string de URL**.
- **Senhas:** `password_hash($senha, PASSWORD_DEFAULT)` + `password_verify()` +
  `password_needs_rehash()` no login. Em 7.0, `PASSWORD_DEFAULT` = **bcrypt** —
  **Argon2 não existe** (chega em 7.2/7.3): não referencie `PASSWORD_ARGON2*`.
  **Nunca** MD5/SHA1, nunca hash caseiro, nunca a opção `salt` (deprecada em 7.0 —
  o salt é gerado pela função).
- **Tokens/nonces:** `random_bytes()`/`random_int()` (nativos em 7.0) — nunca
  `rand()`, `mt_rand()`, `uniqid()` para valor de segurança. Comparação de segredo com
  `hash_equals()` (timing-safe), nunca `===` sobre token.
- **Criptografia simétrica — mcrypt PROIBIDO** (ver §1). Em 7.0:
  - ⚠️ CONFIRMAR: `openssl_encrypt()` em 7.0 **não tem os parâmetros de AEAD**
    (`$tag` para GCM chega em **7.1**) — logo, cifra autenticada "na mão" com
    openssl em 7.0 exige compor AES-CTR/CBC + HMAC corretamente, o que é terreno de
    erro. A recomendação é **biblioteca auditada**: `defuse/php-encryption` v2
    (compatível com a era) ou libsodium (`paragonie/sodium_compat`, compatível com
    PHP antigo, ou a extensão PECL `libsodium`). ⚠️ CONFIRMAR: faixas exatas de
    instalação dessas libs num runtime 7.0 com Composer da era.

```php
// ❌ NUNCA
error_log("password: $password");
// ✅ apenas identificador e ação
$logger->info('login_attempt', ['user_id' => $userId]);
```

### 6.5 Sessão & estado de autenticação

- **Flags de cookie de sessão** — em 7.0 configure via `session_start` com options
  (novidade da 7.0) ou ini:

```php
session_start([
    'cookie_httponly' => true,  // JS não lê
    'cookie_secure'   => true,  // só HTTPS
    'use_strict_mode' => true,  // rejeita session id não iniciado pelo servidor
]);
```

- **`SameSite` NÃO existe em 7.0** (`setcookie` com array de opções e
  `session.cookie_samesite` são **7.3**). Consequências:
  - a proteção anti-CSRF **não pode** depender de SameSite: **token anti-CSRF é
    obrigatório** em todo form/endpoint de estado (POST/PUT/DELETE) — token por
    sessão via `random_bytes()`, comparado com `hash_equals()`;
  - ⚠️ CONFIRMAR: o workaround documentado para emitir `SameSite` em PHP < 7.3 é
    montar o header manualmente (`header('Set-Cookie: ...; SameSite=Lax', false)`) —
    validar se vale o risco/complexidade no projeto ou se o token CSRF basta.
- Sessão é a **fonte de verdade** de identidade e tenant — regenere o id no login
  (`session_regenerate_id(true)`), expire por inatividade, invalide no logout
  (`session_destroy` + cookie expirado).
- Token de autenticação **não** vai para `localStorage` (concern do front; o backend
  entrega como cookie `httponly`).
- ⚠️ CONFIRMAR: em 7.0, garanta `session.use_strict_mode=1` e
  `session.use_only_cookies=1` no ini de produção — defaults de builds antigos podem
  permitir session id via URL (session fixation).

### 6.6 Dependências & upload (síntese)

- **Mass assignment:** monte a Entity a partir de **DTO com campos whitelistados** —
  nunca `fill($_POST)` / `fromArray($request->all())` sem whitelist.
- **Upload:** whitelist de extensão **e** validação de MIME real
  (`finfo_file`); arquivo salvo **fora** do docroot ou com execução negada; nunca
  confie no nome/`Content-Type` enviados pelo cliente.
- **Auditar dependência:** sem `composer audit` na era — ver §8 (advisories via
  `roave/security-advisories` + `local-php-security-checker`).

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico:** **PHPUnit 6.5** — a última série 6.x, que requer `^7.0` (roda em
7.0/7.1/7.2; PHPUnit 7 já exige 7.1). Comando (alimenta
`keelson.config.json → quality.test`): `composer test` embrulhando `vendor/bin/phpunit`.

**Convenções idiomáticas da era + padrão de qualidade:**

- **Annotations, não atributos:** `@test`, `@dataProvider`, `@group` em docblock —
  atributos `#[Test]` são PHP 8 / PHPUnit 10, **não existem aqui**.
- **Base namespaced:** `PHPUnit\Framework\TestCase` (o PHPUnit 6 já usa o namespace).
  ⚠️ CONFIRMAR: no PHPUnit 6, o type do mock em docblock é
  `\PHPUnit_Framework_MockObject_MockObject` (nome legado) — confirmar o FQCN correto
  da série 6.5 antes de padronizar o docblock.
- **Mocks:** `$this->createMock(Interface::class)` (disponível na série 6) — um único
  mecanismo de mock na base; não misturar com Mockery.
- **Exceções:** `$this->expectException(DomainException::class)` **antes** do Act.
- **Nomes reveladores:** o padrão do time (ex.: `deveXxx()`/`naoDeveXxx()` ou
  `testItDoesX`) — consistente e descrevendo a **regra** sob teste.
- **AAA:** Arrange → Act → Assert, blocos separados visualmente.
- **Sem typed properties** na classe de teste (7.4) — docblock `@var`.

```php
<?php
declare(strict_types=1);

use PHPUnit\Framework\TestCase;

/**
 * @group unit
 */
final class CreateUserUseCaseTest extends TestCase
{
    /** @var UserRepositoryInterface|\PHPUnit_Framework_MockObject_MockObject */
    private $repo;

    /** @var CreateUserUseCase */
    private $useCase;

    protected function setUp() // 7.0: sem ": void" (o return type void é 7.1)
    {
        $this->repo = $this->createMock(UserRepositoryInterface::class);
        $this->useCase = new CreateUserUseCase($this->repo);
    }

    /** @test */
    public function deveCriarUsuarioQuandoEmailInedito()
    {
        // ═══════ Arrange ═══════
        $this->repo->method('emailExists')->willReturn(false);
        $this->repo->method('save')->willReturnArgument(0);

        // ═══════ Act ═══════
        $user = $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));

        // ═══════ Assert ═══════
        $this->assertSame('John', $user->getName());
    }

    /** @test */
    public function naoDeveCriarComEmailExistente()
    {
        $this->repo->method('emailExists')->willReturn(true);

        $this->expectException(\DomainException::class);
        $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));
    }
}
```

> Nota: em PHPUnit 6/PHP 7.0, `setUp()` **sem** `: void` — o return type `void` não
> parseia em 7.0. (Séries novas do PHPUnit exigem `setUp(): void`; é um dos pontos de
> atrito do upgrade — registre no plano de migração.)

**Testar comportamento, não implementação:** prove regra de negócio, cálculos críticos,
validações de domínio e edge cases. Não teste getter trivial nem "a classe instanciou".
Mocke as **fronteiras** (interfaces de repositório/serviço); nunca a unidade sob teste.
Anonymous classes (7.0) servem para fakes pontuais quando o mock dinâmico atrapalha.

**Fixtures / dados compartilhados (Art. 3):** teste que precisa de banco roda em
**SQLite em memória** (`sqlite::memory:` via PDO), com **schema e dados num helper
central** (`tests/Support/`) — um método por tabela, um builder com defaults+overrides
por linha. `CREATE TABLE`/`INSERT` inline no teste é violação DRY: cópias divergem e
quebram em massa quando o schema muda.

> ⚠️ **SQLite ≠ banco de produção.** Quando o SQL do repositório muda, o *smoke* contra
> o banco real (MySQL/Postgres da era) continua obrigatório — dialeto e erros como
> HY093 só aparecem lá.

**Régua (Art. 1):** existe teste que **falha se o comportamento regredir**. Gate de
autorização exige o teste de **403 sem permissão**, com o stack HTTP e a ordem de
middlewares de produção.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador:** **Composer**. `composer.json` declara, `composer.lock` **fixa** — o
lock é **commitado** para builds reprodutíveis.

- ⚠️ CONFIRMAR: num runtime 7.0, a versão máxima do Composer que **roda** é a série
  **2.2 LTS** (Composer ≥ 2.3 exige PHP 7.2.5+). Consequência direta:
  **`composer audit` NÃO existe** (foi adicionado no Composer **2.4**).
- **Auditoria de vulnerabilidade na era — duas ferramentas complementares, ambas
  consultando o advisory database `FriendsOfPHP/security-advisories`** (a mesma fonte
  comunitária que alimenta o `composer audit` moderno, sincronizada com CVEs):
  - **`roave/security-advisories` (`dev-latest`, em `require-dev`)** — metapacote de
    `conflict` que **impede instalar** versão com vulnerabilidade conhecida. Limite em
    legado: ele barra a **instalação**, não escaneia o que **já está** no lock — e num
    projeto preso a libs antigas pode bloquear o `composer update` inteiro; avalie.
  - **`local-php-security-checker`** — binário standalone (Go) que **escaneia o
    `composer.lock` existente** contra o advisory database, **sem depender da versão
    do PHP** da máquina. É a ferramenta certa para o pipeline de um legado 7.0.
    ⚠️ CONFIRMAR: o projeto (`fabpot/local-php-security-checker`) segue mantido; se
    arquivado, o substituto atual (ex.: `symfony security:check` do Symfony CLI, também
    local e sem dependência do runtime PHP).
  - **NÃO usar** `sensiolabs/security-checker` — abandonado; a API
    `security.symfony.com` que ele consultava foi **desligada em janeiro de 2021**.
- **Política de versão:** constraints com caret e **pin da era** — muitas libs atuais
  exigem PHP ≥ 7.2/8.x; a resolução do Composer respeita o `"php": "7.0.x"` declarado
  no `composer.json` (`config.platform.php` cabeado em `7.0` garante isso mesmo
  rodando o Composer noutra máquina — **obrigatório** em legado).
- **Higiene:** `composer outdated` para atrasos; evitar pacote **abandonado** (o
  Packagist marca `abandoned`) — com a ressalva realista de que num alvo 7.0 parte do
  ecossistema compatível **está** abandonada: cada dependência dessas é um item
  nomeado no **plano de upgrade**, não uma escolha nova aceitável.
- **Autoload PSR-4:** classe nova exige `composer dump-autoload` para entrar no mapa.

**Armadilha comum:** rodar `composer update` numa máquina com PHP moderno **sem**
`config.platform.php=7.0` — o resolver instala versões que exigem 7.2+ e o deploy
quebra no runtime 7.0. O lock deve ser gerado **para** a plataforma-alvo.

---

## 9. Reúso: o que já existe → Charter Art. 3

**Antes de escrever** helper, validação, conversão, DTO ou trait, **procure o
equivalente** — reimplementar o que existe (ou duplicar entre arquivos) é proibido,
mesmo que o código fique correto. Em legado isso é dobrado: a base 5.x→7.0 costuma já
ter três versões do mesmo helper — a mudança **converge** para um canônico, nunca
adiciona a quarta.

- **Casting/parse de entrada** (string→int/float/date, com null-safety via `??`) mora
  num **trait canônico de parsing** consumido pelos DTOs — traits existem desde 5.4,
  plenamente idiomáticos em 7.0.
- **Par Create/Update** de um domínio compartilha validação/sanitização num **trait do
  domínio** — nunca duplique a regra entre os dois DTOs.
- **Conceito de domínio recorrente** (CPF, e-mail, código) vira **Value Object** único.
- **Prefira a stdlib** antes de rolar o seu: `filter_var` (validação de e-mail/URL/int),
  `array_*`, `password_hash`, `random_bytes`, `DateTimeImmutable` (5.5+ — prefira à
  `DateTime` mutável), `intdiv`, `hash_equals`.
- **Polyfills em vez de gambiarra:** função de versão futura que faz falta
  (`str_contains`, `array_key_first`) entra via `symfony/polyfill-php7x`/`php80` —
  ⚠️ CONFIRMAR: faixa dos pacotes de polyfill instalável em runtime 7.0 — nunca
  reimplementada à mão com outro nome.

**Como descobrir o que já existe:** busca por nome/conceito nos `codePaths` da ficha;
**um guard determinístico** (teste de arquitetura/lint custom) que **reprova** a
reimplementação de um conversor canônico transforma "lembre de reusar" em falha de
build.

**Régua (Art. 3):** a mudança não introduz um **segundo caminho** para algo que já
existia; quando o conceito se repetiu, ele foi **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

Contexto de versão: o 7.0 (phpng) já entrega ~2× o throughput do 5.6 — a migração
5.x→7.0 em si é o maior ganho de performance disponível; não "otimize" reintroduzindo
ilegibilidade que o engine novo tornou desnecessária.

O custo patológico mais comum continua o **round-trip de banco em laço** (N+1):

```php
// ❌ N+1 — uma query POR item
foreach ($this->orderRepo->findAll() as $order) {
    $customer = $this->customerRepo->findById($order->getCustomerId());
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
  `fetchAll()`; `unset()` em variáveis grandes após uso.
- **Trabalho pesado** (import/export, e-mail, webhook) vai para **fila/job/cron**,
  não no request.
- **OPcache ligado em produção** (bundled desde 5.5; *preloading* é 7.4 — não existe).

**Ferramenta de medição idiomática:** `EXPLAIN` no banco **real** (não no SQLite de
teste) para plano de query; para CPU/memória do PHP, ⚠️ CONFIRMAR: a série do
**Xdebug compatível com PHP 7.0 é a 2.5/2.6** (Xdebug 3 não suporta 7.0) — profiler
via cachegrind; **Blackfire** e **Tideways/XHProf** tinham suporte à era, confirmar
disponibilidade atual de agente para 7.0. **Régua (Art. 8):** não há query/round-trip
dentro de laço sobre dados de tamanho variável; otimização não óbvia **cita a medição**
que a justifica — nunca palpite.

**Armadilha comum:** `fetchAll()` num resultado grande e depois iterar — dobra o pico
de memória; `fetch()` em cursor (ou generator no repositório) faz o mesmo trabalho com
pegada constante.

---

## 11. Gotchas da versão (7.0) → Charter Art. 1, 7

**Vindo de 5.x (o engine mudou — mudanças silenciosas de comportamento):**

- **Uniform variable syntax:** expressões indiretas passaram a avaliar **esquerda →
  direita**: `$$foo['bar']` agora é `($$foo)['bar']` (em 5.x era `${$foo['bar']}`).
  Código 5.x com variável-variável/propriedade dinâmica composta muda de significado
  **sem erro** — grep e cubra com teste.
- **`foreach` não move mais o ponteiro interno** do array, e opera sobre cópia em
  by-value — código 5.x que misturava `foreach` com `current()`/`next()` muda de
  comportamento.
- **`list()`** atribui na **ordem esquerda→direita** (em 5.x era reversa) e não
  desempacota mais string.
- **Strings hexadecimais não são mais numéricas:** `"0x1A" == 26` era `true` em 5.x,
  é `false` em 7.0; `is_numeric("0x1A")` é `false`.
- **Removidos em 7.0:** `mysql_*`, `ereg*`, ASP tags (`<% %>`),
  `<script language="php">`, `$HTTP_RAW_POST_DATA` (use `php://input`), chamada de
  método não-estático em contexto estático incompatível.
- **Deprecados em 7.0:** construtores estilo PHP 4 (método com nome da classe) — migre
  para `__construct` já (removidos em 8.0); opção `salt` de `password_hash`.
- **Erros fatais viraram `\Error` capturável:** `TypeError`,
  `DivisionByZeroError` (em `intdiv`/`%`; a divisão `/` por zero em 7.0 ainda é
  **warning retornando `INF`/`NAN`** — só vira exceção em 8.0), `ParseError`,
  `AssertionError`. Handler de fronteira captura `\Throwable`, não `\Exception`.
- **Octal inválido** (`0128`) virou erro de parse; **shift negativo** lança
  `ArithmeticError`; `func_get_args()` reflete o valor **atual** do argumento (não o
  passado originalmente); múltiplos `default` num `switch` viraram erro fatal.

**Vindo de 7.4/8.x para trás (escrevendo para o alvo 7.0):**

- **Parse error imediato:** `?T`, `void`, `iterable`, `catch (A | B)`, typed
  properties, `fn()`, `??=`, spread em array, `match`, enums, `readonly`, named args,
  constructor promotion, atributos `#[...]`.
- **Constantes/funções inexistentes** (erro só em runtime): `JSON_THROW_ON_ERROR`,
  `str_contains`, `array_key_first/last`, `PASSWORD_ARGON2*` — polyfill ou construção
  da era (§9).
- **`setcookie()` com array de opções é 7.3** — em 7.0 a assinatura é posicional
  (`setcookie($name, $value, $expire, $path, $domain, $secure, $httponly)`); passar
  array no terceiro parâmetro **não faz** o que parece. `SameSite` indisponível (§6.5).
- **`session.cookie_samesite` ini é ignorado** em 7.0 — configurá-lo dá sensação
  falsa de proteção; o token CSRF é o mecanismo real aqui.
- **Nullable "implícito" não existe como sintaxe:** `function f(?int $x)` não parseia;
  `function f(int $x = null)` **funciona** em 7.0 (parâmetro vira nullable) — use com
  parcimônia e documente com `@param int|null`.

**Régua (Art. 1/7):** quem migra 5.x→7.0 (ou escreve pensando em 8.x) precisa que essas
surpresas estejam **cobertas por teste** (ex.: teste do parse de entrada que pegaria a
mudança de `list()`/hex string) e **comentadas com o porquê** onde a escolha da era não
é óbvia — o próximo dev virá de PHP moderno e vai "corrigir" para sintaxe que não
parseia aqui.

---

## 12. Ferramentas & comandos

Estes comandos são a ponte entre a doutrina (este perfil) e a automação (os gates leem
a ficha). Cada linha alimenta `keelson.config.json → quality.*`. Todos rodam sobre o
**binário PHP 7.0** do projeto (ou com `config.platform.php=7.0` no Composer):

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `composer test` (embrulha `vendor/bin/phpunit` — PHPUnit **^6.5**) | `quality.test` |
| **lint** | `vendor/bin/phpcs --standard=PSR12 src tests` (ou `vendor/bin/php-cs-fixer fix --dry-run --diff` na série **2.x**) | `quality.lint` |
| **typecheck** | ⚠️ CONFIRMAR: PHPStan/Psalm atuais **não rodam** em PHP 7.0 (PHPStan 1.x exige 7.2+). Opções: (a) rodar um PHPStan antigo (série **0.9.x**, última a suportar runtime 7.0 — confirmar); (b) rodar PHPStan moderno **noutro binário PHP** no CI, analisando o código 7.0 (confirmar suporte do `phpVersion` alvo). Se nenhum for viável, `null`. | `quality.typecheck` |
| **build** | **não se aplica** — PHP é interpretado. O "build" de deploy é `composer install --no-dev --optimize-autoloader` + OPcache, não um passo de gate. | `quality.build` (`null`) |

Auditoria de dependências (fora da tabela por não ser gate `quality.*`, mas parte do
pipeline — ver §8): `local-php-security-checker` sobre o `composer.lock` +
`roave/security-advisories` em `require-dev`.

Exemplo de ficha correspondente:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "7.0" } },
  "codePaths": { "backend": ["src"] },
  "quality": {
    "test": "composer test",
    "lint": "vendor/bin/phpcs --standard=PSR12 src tests",
    "typecheck": null,
    "build": null
  }
}
```

**Por quê:** sem estes comandos declarados, o gate não sabe o que rodar — a régua do
charter (prova externa e falsificável) fica sem executor. E num legado EOL, o gate que
roda **na versão certa** é a única coisa que impede sintaxe 7.1+ de chegar ao deploy.
