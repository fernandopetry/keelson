---
lang: php
version: "7.4"
charter: 0.3.0
generated-by: profile-writer
reviewed: false
reviewer: null
---

# PHP 7.4 — Perfil de linguagem

> Instância do `QUALITY-CHARTER.md` para **PHP 7.4** — a versão onde a maior parte do
> legado 7.x estacionou. Cada seção abaixo pega um artigo do charter e responde: *"em
> PHP 7.4, isto se cumpre assim, com esta ferramenta, com esta armadilha a evitar"*.
> Mesma espinha do exemplar 8.5 (seções 0–12), conteúdo específico desta versão.
>
> **Escopo:** o que é idiomático de PHP 7.4. A arquitetura **específica do projeto**
> (nomes de camadas próprios, caminhos reais) mora em `guidelines/project/` e na ficha
> `keelson.config.json`; aqui, os nomes de pasta são placeholders genéricos (`src/`,
> `tests/`) e os namespaces usam `App\` como raiz de exemplo.
>
> ⚠️ Perfil **gerado** (`reviewed: false`): afirmações de segurança inferidas sem
> confirmação documental estão marcadas `⚠️ CONFIRMAR:` para dirigir a revisão humana.

---

## 1. Identidade & versão

> **⚠️ PHP 7.4 está em fim de vida (EOL) desde 28/nov/2022.** Não recebe mais correção
> de segurança do projeto PHP: toda CVE nova no runtime fica **sem patch oficial**.
> Consequência para este perfil: (a) o **plano de upgrade para 8.x é recomendação
> permanente** — toda decisão de arquitetura nova DEVERIA reduzir a distância até 8.x,
> nunca aumentá-la; (b) a superfície exposta DEVE ser mínima e as mitigações da §6
> ganham peso extra, porque o runtime por baixo não se defende mais sozinho.
> ⚠️ CONFIRMAR: disponibilidade de backports de segurança pagos/da distro para 7.4
> (ex.: Ubuntu Pro/ESM, RHEL, Freexian ELTS) no ambiente real do projeto.

O alvo é **PHP 7.4** (última minor da série 7, lançada em novembro de 2019), com
`declare(strict_types=1)` obrigatório no topo de todo arquivo — sem coerção silenciosa
de tipo.

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| **Typed properties** | `private ?DateTimeImmutable $deletedAt = null;` — tipo na propriedade, não só no docblock | 7.4 |
| **Arrow functions `fn`** | Closures de **uma expressão**, captura implícita por valor: `fn ($u) => $u->id` | 7.4 |
| **Null coalescing assignment `??=`** | `$config['ttl'] ??= 300;` — default sem repetir o alvo | 7.4 |
| **Spread em array** | `[...$defaults, ...$overrides]` — **apenas chaves inteiras** em 7.4 | 7.4 |
| **Covariant return / contravariant param** | Sobrescrever devolvendo tipo mais específico | 7.4 |
| **Separador numérico** | `1_000_000` | 7.4 |
| **`password_algos()`** | Descobrir em runtime os algoritmos de hash disponíveis | 7.4 |
| **Preloading (`opcache.preload`)** | Carregar classes quentes na inicialização do FPM | 7.4 |
| **`JSON_THROW_ON_ERROR`, `array_key_first/last`, trailing comma em chamadas** | Base 7.3, uso corrente | 7.3 |
| **`PASSWORD_ARGON2ID`** | Hash de senha (ver §6.4 para disponibilidade) | 7.3 |
| **ext/sodium nativa** | Criptografia moderna sem lib externa | 7.2 |

**Recursos que NÃO existem em 7.4 (são todos 8.x — não usar, não recomendar):**
union types, named arguments, attributes `#[...]`, constructor property promotion,
`match`, nullsafe `?->`, enums, `readonly`, first-class callable syntax `f(...)`,
`str_contains`/`str_starts_with`/`str_ends_with`, non-capturing catch, `throw` como
expressão, trailing comma em **lista de parâmetros**, `$obj::class`.

**Construções que NÃO DEVEM mais aparecer (deprecadas em/até 7.4):** acesso a
array/string com chaves `$str{0}` (deprecado em 7.4, removido em 8.0 — use `$str[0]`);
ternário aninhado **sem parênteses**; `create_function()`, `each()`; **mcrypt**
(removido em 7.2 — sodium ou OpenSSL, ver §6.4); cast `(real)`; funções/métodos
nomeados `fn` (virou palavra reservada em 7.4).

**Por que a versão é seção de primeira classe:** "PHP" em 7.4 e em 8.x é quase outra
linguagem — sem enums, sem `match`, sem promotion, com semântica de comparação frouxa
diferente (ver §11). Código escrito para o alvo errado dá **parse error** no deploy —
ou pior, roda com comportamento silenciosamente diferente (`#[...]` é comentário em 7.4).

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Guia canônico:** **PSR-12** (PHP-FIG). O PER Coding Style é a evolução do PSR-12, mas
cobre sintaxe 8.x; para uma base 7.4, PSR-12 é o alvo natural. Não há divergência de
estilo por gosto — o formatter decide.

- **Formatter/linter:** `php-cs-fixer` **3.x** (exige PHP ≥ 7.4 para rodar — compatível
  com este alvo; config `.php-cs-fixer.dist.php` versionada na raiz) **ou**
  `phpcs`/`phpcbf` com ruleset PSR-12 (PHP_CodeSniffer 3.x roda em qualquer 7.x).
  Escolha **uma** e cabeie na ficha. ⚠️ CONFIRMAR: se a release mais recente do
  php-cs-fixer 3.x ainda instala sob PHP 7.4 — se não, **pinar** a última versão cujo
  `composer.json` aceite `^7.4`.
- **É erro (bloqueia):** qualquer violação de PSR-12 reportada em `--dry-run`; ausência
  de `declare(strict_types=1)`; import não usado; uso de construção deprecada em 7.4
  (`$str{0}`, ternário aninhado sem parênteses).
- **É aviso (não bloqueia):** ordenação de `use`, largura de linha acima do alvo quando
  quebrar prejudica leitura — decisão do time, não do gate.
- **Comando de lint** (alimenta `keelson.config.json → quality.lint`):
  `vendor/bin/php-cs-fixer fix --dry-run --diff` (exit code ≠ 0 reprova).

**Armadilha comum:** rodar `php-cs-fixer fix` (que reescreve) no gate em vez de
`--dry-run` — o gate deve **reprovar**, não **corrigir** silenciosamente. E: config de
fixer copiada de projeto 8.x habilita regras que reescrevem para sintaxe 8.x (promotion,
`match`) — o resultado nem parseia em 7.4. A config DEVE declarar o alvo 7.4.

---

## 3. Nomenclatura & idioma → Charter Art. 5

**Convenção por símbolo** (PSR-1/PSR-4, sem exceção — idêntica em todas as versões de PHP):

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Classe / Interface / Trait | `PascalCase` | `CreateUserUseCase` |
| Método / função / variável / propriedade | `camelCase` | `findById`, `$emailExists` |
| Constante de classe / global | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `STATUS_ACTIVE` |
| Arquivo | idêntico ao FQCN (PSR-4), 1 classe por arquivo | `CreateUserUseCase.php` |

**Padrões de nome que sinalizam papel** — o nome revela a intenção antes do corpo:

- `*Interface` (contrato de domínio) · `Pdo*Repository` (implementação PDO) ·
  `*UseCase` (um caso de uso, um `execute()`) · `*Action` (entrada HTTP) ·
  `*DTO` (transporte, sem lógica) · `*Test` (teste da classe homônima).
- Value Object nomeado pelo **conceito** (`Email`, `Cpf`), não pelo tipo primitivo.
- Sem enums em 7.4, o conjunto fechado de variantes vive em **constantes de classe**
  nomeadas pelo domínio (`OrderStatus::OPEN`) — nunca strings mágicas espalhadas.

**Idioma:** identificadores em **inglês** — norma do ecossistema (stdlib, PSR, libs).
O idioma dos **comentários** é decisão do projeto (registrada em `guidelines/project/`),
mas **DEVE ser único e consistente** em toda a base — nunca metade em cada idioma no
mesmo arquivo.

**Armadilha comum:** nomear pela implementação (`$arrayDeUsers`, `processData`) em vez
da intenção (`$activeUsers`, `deactivateExpiredContracts`). O nome que descreve o *como*
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

**Blocos idiomáticos em 7.4** (uma responsabilidade cada — note as diferenças para 8.x):

- **Entity** — identidade + invariantes; **typed properties privadas + getters**;
  imutabilidade via método `withX()` que **clona manualmente** (não há `clone with`
  nem `readonly` em 7.4).
- **Value Object** — `final class`; valida no **construtor**; **sem setter algum** —
  a imutabilidade é **por convenção e revisão**, já que `readonly` não existe;
  `equals()` por valor.
- **DTO** — typed properties públicas + `fromArray()` como fábrica **whitelistando
  campos**; **sem** lógica de negócio.
- **UseCase** — um `execute()`; recebe DTO, devolve Entity/resultado; depende de
  **interfaces**, injetadas pelo construtor (atribuição explícita — não há promotion).
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
    // Depende da ABSTRAÇÃO (interface), nunca do PDO concreto → testável sem banco.
    // 7.4: declaração tipada + atribuição no construtor (promotion é 8.0).
    private UserRepositoryInterface $repo;

    public function __construct(UserRepositoryInterface $repo)
    {
        $this->repo = $repo;
    }

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
global) entra por uma **interface** injetada no construtor. É isso que deixa o UseCase
ser testado sem levantar o mundo (Art. 4) e trocar o driver sem tocar a regra.

**Condicionais e assinaturas (Art. 4, 7):** prefira *early return* (guard clause) a
`if/else` aninhado. Sem `match` nem enums em 7.4, condicional que despacha pela mesma
variante em vários pontos vira **polimorfismo via interface + implementações**, ou um
**`switch` único e exaustivo** (com `default` que **lança**) confinado numa fábrica —
nunca `switch` repetido em N pontos. Método passando de **~4 parâmetros** → agrupe num
**DTO/objeto de parâmetro**; sem *named arguments* em 7.4, a lista longa de opcionais
posicionais é ainda mais ilegível — o objeto de parâmetro é a saída idiomática.

**Armadilha comum:** SQL ou `$_SESSION`/`getenv()` dentro do UseCase ou da Action —
vaza infraestrutura para dentro da regra e torna o teste refém do ambiente. Detalhe de
I/O só na Infrastructure.

**Padrões na prática (PHP 7.4)** — a construção idiomática vem **antes** do padrão
clássico (ver "Padrões de projeto" em `../core/ARCHITECTURE.md`):

- **Strategy/State** → interface + implementações (polimorfismo clássico); para
  conjuntos fechados simples, constantes de classe + `switch` exaustivo **num único
  ponto** (fábrica). Sem enums nativos; se o projeto precisar de enum rico, a lib
  `myclabs/php-enum` é o substituto consagrado — não role o seu.
- **Factory** → *named constructor* estático (`fromArray()`, `fromRequest()`) antes de
  classe-fábrica dedicada; fábrica dedicada só com variantes reais.
- **Observer** → eventos do framework / PSR-14, nunca implementação manual do padrão.
- **Builder** → diferente de 8.x (onde *named args* o dispensam), em 7.4 um builder
  simples ou um objeto de parâmetro **se justifica** quando há muitos opcionais — mas
  só depois que um DTO com defaults não resolver.
- **Armadilhas PHP:** Singleton e `static` mutável; *service location* (puxar do
  container) dentro de Domain/Application — a dependência entra pelo construtor;
  herança para reuso de código (prefira composição); array associativo gigante como
  "objeto" — em 7.4 typed properties já existem, use uma classe.

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceções, não códigos de retorno**, para condição excepcional. Fluxo normal ("não
encontrado" esperado) PODE ser `?T`/`null`; violação de regra é **exceção tipada**.

- **Domínio lança tipado:** `DomainException` (regra de negócio),
  `InvalidArgumentException` (entrada inválida no DTO/VO). Nunca lance `\Exception` cru.
- **Nunca engolir silenciosamente:** `catch (\Throwable $e) {}` vazio e o operador `@`
  são proibidos — o erro some e o bug vira silencioso. Se capturou, ou trata, ou
  re-lança com contexto. (Em 7.4 o catch **exige** a variável — não há non-capturing
  catch; a variável não usada não é desculpa para o bloco vazio.)
- **O engine 7.4 é mais permissivo que o 8.x — endureça-o:** muitas condições que em
  8.0 viram `TypeError`/`ValueError`/`DivisionByZeroError` em 7.4 são só **warnings que
  seguem em frente** (função interna com argumento inválido devolve `null` + warning;
  `1/0` devolve `false` + warning). Um handler global que converte warning/notice em
  `ErrorException` (`set_error_handler` + `error_reporting(E_ALL)`) DEVE estar ativo —
  sem ele, erro real atravessa o request calado.
- **Fronteira de conversão:** um único ponto (Action + handler global) captura
  `\Throwable`, loga o detalhe internamente e devolve ao cliente uma mensagem
  **genérica** com o status HTTP correto. O `$e->getMessage()` **não** vai cru para a
  resposta.

```php
try {
    $user = $this->useCase->execute($dto);
    return $this->ok($response, $user->toArray());
} catch (\InvalidArgumentException $e) {
    return $this->error($response, 'Validation failed', 422); // campo, sem stack
} catch (\DomainException $e) {
    return $this->error($response, $e->getMessage(), 400);     // mensagem de negócio, curada
} catch (\Throwable $e) {
    $this->logger->error('user.create.failed', ['exception' => $e]); // detalhe no log
    return $this->error($response, 'Internal error', 500);     // genérico para o cliente
}
```

**O que logar (Art. 2):** identificadores e ação (`user_id`, `action`), a exceção com
stack **do lado do servidor** — **nunca** senha, token, PII ou o corpo cru da
requisição. `display_errors=Off` e `expose_php=Off` em produção — stack trace e versão
de PHP na resposta são vazamento (agravado por o runtime ser EOL: a versão exata expõe
CVEs conhecidas sem patch).

**Armadilha comum — Information Disclosure:** sanear a mensagem só no *log* e devolver
o `$e->getMessage()` cru na resposta (inclusive dentro de um `success:false` com HTTP
200). O valor tem que ser saneado **no sink de resposta**, não só no de log.

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> **⚠️ Runtime EOL desde 28/nov/2022 — esta seção parte desse fato.** Rodar 7.4 em
> produção significa que vulnerabilidade nova no **interpretador** não terá correção:
> a postura é **mitigar e migrar**. Mitigações mínimas enquanto o upgrade não sai:
> superfície exposta mínima (FPM atrás de proxy, sem porta direta), `display_errors=Off`
> + `expose_php=Off`, dependências auditadas com rigor redobrado (§8) — e o **plano de
> upgrade para 8.x registrado como recomendação permanente** em toda entrega.
> ⚠️ CONFIRMAR: se o binário PHP do ambiente recebe backports de segurança de
> distro/fornecedor (Ubuntu Pro/ESM, RHEL, ELTS) — isso muda o tamanho do risco.
>
> Cada item abaixo é um item da **Régua do Art. 2** traduzido para "como se faz e como
> se erra em PHP 7.4". Vulnerabilidade aqui é **rejeição imediata** no review. Perfil
> gerado: afirmações inferidas estão marcadas `⚠️ CONFIRMAR:`.

### 6.1 Injeção → sempre parametrizar

**SQL — PDO com parâmetros NOMEADOS**, nunca concatenação nem interpolação de entrada
(o mecanismo PDO é idêntico ao de 8.x):

```php
// ✅ prepared statement, parâmetros nomeados
$stmt = $pdo->prepare('SELECT id, name, email FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);

// ❌ NUNCA — concatenar/interpolar entrada externa é SQL Injection
$pdo->query("SELECT * FROM users WHERE email = '$email'");
```

- Ligue `PDO::ATTR_EMULATE_PREPARES => false` (prepared statements reais no driver) e
  `PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION` — em 7.4 o modo de erro default do PDO
  é **silencioso** (`ERRMODE_SILENT`; só virou exceção por default no PHP 8.0), então
  sem essa flag a query que falha **não lança nada**. ⚠️ CONFIRMAR: default
  `ERRMODE_SILENT` em 7.4 (mudança para `ERRMODE_EXCEPTION` documentada como 8.0).
- O que **não** dá para bindar (nome de coluna/tabela em `ORDER BY`) valida-se contra
  uma **whitelist** — nunca interpolando o input.
- **Command injection:** evite `exec/shell_exec/system/proc_open`; se inevitável,
  `escapeshellarg()` em **cada** argumento (nunca a string inteira montada).
- **Path traversal:** `basename()` + `realpath()` validado contra o diretório-base;
  nunca `file_get_contents($userInput)` cru; `allow_url_include` OFF (deprecado em 7.4).

**Armadilha comum — HY093:** reusar o mesmo placeholder nomeado duas vezes no SQL com
`EMULATE_PREPARES=false` (`... WHERE a = :x OR b = :x`) estoura *"invalid parameter
number"*. Use nomes distintos ou passe o valor duas vezes com chaves diferentes.

### 6.2 Saída / escaping → escapar no destino

Escape é **por contexto de saída**, feito no ponto de renderização:

```php
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); // HTML — ENT_QUOTES OBRIGATÓRIO
echo rawurlencode($value);                            // componente de URL
echo json_encode($value, JSON_THROW_ON_ERROR);        // JSON (flag existe desde 7.3)
```

- **`ENT_QUOTES` explícito é inegociável em 7.4:** o default de `htmlspecialchars`
  nesta versão **não escapa aspas simples** (`ENT_COMPAT`) — o default só passou a
  incluir `ENT_QUOTES` no PHP 8.1. Chamada sem flags deixa XSS passar em atributo HTML
  com aspas simples. ⚠️ CONFIRMAR: default `ENT_COMPAT | ENT_HTML401` em 7.4 e mudança
  de default apenas em 8.1.
- Valor embutido dentro de `<script>` exige as flags
  `JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP` no `json_encode`.
  ⚠️ CONFIRMAR: conjunto de flags recomendado para contexto script.
- Numa API JSON, `json_encode` já escapa; num template (Twig/Blade em versão compatível
  com 7.4), o autoescape cuida do HTML — **não** o desligue (`|raw`, `{!! !!}`) para
  dado de usuário. Template em PHP puro (`.phtml`, comum em legado): **todo** `echo` de
  dado externo passa por `htmlspecialchars(..., ENT_QUOTES, 'UTF-8')`, sem exceção.

**Armadilha comum:** sanear o valor no log/persistência mas devolvê-lo cru na resposta
— o escaping tem que acontecer em **cada** sink de saída, independentemente.

### 6.3 Autorização → negar por padrão

Toda action verifica **permissão antes de executar**; o default é **negar**. A checagem
vive num middleware/guard (PSR-15 se o stack for PSR-7), não espalhada dentro da regra.

- **IDOR / acesso por registro:** ter a permissão genérica não basta — verifique que o
  registro pertence/é visível ao solicitante (`WHERE owner_id = :currentUserId`).
- **Tenant/instância:** `instance_id` (e afins) tem **ponto único de população** a
  partir da **sessão server-side** — nunca de header/query/path. Leitor ausente
  **nega**, nunca assume default permissivo (`?? 1` é bug de segurança).
- **Serializador de dado sensível:** default **fail-closed** — omitir por padrão, expor
  por parâmetro explícito. Nunca `toArray(bool $includeFinancials = true)`.
- **Prova:** todo gate de autorização exige teste de integração provando **403 sem a
  permissão** (não só 200 com ela).

**Armadilha comum (framework de roteamento):** ler o argumento de rota do lugar errado
(atributo do request em vez do argumento da rota resolvida) devolve `null` e **libera
tudo silenciosamente**. Confirme a fonte e a **ordem dos middlewares** (autorização
depois do roteamento). Em legado 7.x sem middleware pipeline, a checagem costuma viver
num `require auth.php` no topo do script — se for esse o padrão do projeto, ela DEVE
ser **inescapável** (front controller), não um include que cada script lembra de fazer.

### 6.4 Segredos & configuração → fora do código, fora do log

- Segredos vêm de **variável de ambiente / secret store**, lidos via config — **nunca**
  hardcoded no fonte, **nunca** commitados (`.env` no `.gitignore`).
  ⚠️ CONFIRMAR: versão de `vlucas/phpdotenv` compatível com 7.4 (v4/v5), se o projeto
  usar `.env`.
- Segredo **nunca** em log, em mensagem de erro, nem em **query string de URL**.
- **Senhas — `password_hash`, preferindo Argon2id quando o build oferecer:**

```php
// password_algos() existe desde 7.4 — checagem de disponibilidade em runtime
$algo = in_array('argon2id', password_algos(), true)
    ? PASSWORD_ARGON2ID          // constante existe desde 7.3
    : PASSWORD_DEFAULT;          // bcrypt — fallback seguro
$hash = password_hash($password, $algo);
// verificação SEMPRE com password_verify($senha, $hash) — nunca comparar hash na mão
```

  **Nunca** MD5/SHA1, nunca hash caseiro, nunca `==` para comparar hash.
  ⚠️ CONFIRMAR: `PASSWORD_ARGON2ID` só existe se o PHP foi **compilado** com libargon2
  (≥ 20161029); em 7.4, o build com libsodium pode prover Argon2 mesmo sem libargon2 —
  confirmar no binário real com `password_algos()`.
  ⚠️ CONFIRMAR: parâmetros de custo (memory/time/threads para Argon2id; `cost` para
  bcrypt) adequados à recomendação OWASP vigente.
- **Criptografia de dados:** **ext/sodium nativa** (desde 7.2) —
  `sodium_crypto_secretbox` (simétrica autenticada), `sodium_crypto_sign` (assinatura).
  **mcrypt foi removido em 7.2** — código legado que o usa DEVE migrar, não ser
  reproduzido. ⚠️ CONFIRMAR: quando sodium não estiver no build, a alternativa é
  `openssl_encrypt` com `aes-256-gcm` (autenticado, com tag) — nunca ECB/CBC sem MAC.

```php
// ❌ NUNCA
error_log("password: $password");
// ✅ apenas identificador e ação
$logger->info('login_attempt', ['user_id' => $userId]);
```

### 6.5 Sessão & estado de autenticação

- **Cookies de sessão** com as três flags — a assinatura de `setcookie` com array de
  opções (incluindo `samesite`) existe desde o PHP 7.3, então funciona em 7.4:

```php
setcookie('session', $value, [
    'httponly' => true,      // JS não lê
    'secure'   => true,      // só HTTPS
    'samesite' => 'Strict',  // anti-CSRF
]);
```

  ⚠️ CONFIRMAR: assinatura com array de opções e diretiva ini
  `session.cookie_samesite` disponíveis desde 7.3 (em 7.2 e antes o `samesite` exigia
  gambiarra via `path` — não replicar esse padrão se aparecer no legado).
- Sessão é a **fonte de verdade** de identidade e tenant — regenere o id no login
  (`session_regenerate_id(true)`), expire por inatividade, invalide no logout;
  `session.use_strict_mode=1` para rejeitar id de sessão não iniciado pelo servidor.
  ⚠️ CONFIRMAR: `use_strict_mode` como mitigação de session fixation nesta versão.
- Token de autenticação **não** vai para `localStorage` (concern do front, mas o
  backend deve entregá-lo como cookie `httponly`).
- **CSRF:** forms de estado (POST/PUT/DELETE) exigem token anti-CSRF — gerado com
  `bin2hex(random_bytes(32))`, comparado com `hash_equals()` (timing-safe); APIs
  consumidas por SPA validam origem além da mesma-origem.

### 6.6 Dependências & upload (síntese)

- **Mass assignment:** monte a Entity a partir de um **DTO com campos whitelistados** —
  nunca `->fill($request->all())` nem `foreach ($_POST as $k => $v) $obj->$k = $v`
  (padrão frequente em legado 7.x — é a mesma vulnerabilidade, sem framework).
- **Upload:** whitelist de extensão **e** validação de MIME real via
  `finfo_file(FILEINFO_MIME_TYPE)`; nunca confie no `$_FILES['type']` enviado pelo
  cliente; arquivo salvo fora do docroot ou com nome regenerado.
- **Deserialização:** `unserialize($input)` de entrada externa é RCE em potencial —
  use JSON para dados externos; se `unserialize` for inevitável,
  `['allowed_classes' => false]`.
- **Auditar dependência:** `composer audit` (ver §8) — com runtime EOL, a dependência
  desatualizada é ainda mais crítica, porque é a camada que ainda **pode** ser corrigida.

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico:** **PHPUnit 9** (`^9.6`) — exige PHP ≥ 7.3, é a última major que
roda em 7.4 (PHPUnit 10+ exige PHP 8.1). Projetos presos em PHPUnit 8 funcionam, mas
9 é o alvo. Comando (alimenta `keelson.config.json → quality.test`): `composer test`
(que embrulha `vendor/bin/phpunit`).

**Convenções idiomáticas — atenção às diferenças para o exemplar 8.5:**

- **Annotations, NÃO attributes:** em 7.4/PHPUnit 9 usa-se `/** @test */`,
  `/** @dataProvider xxxProvider */`, `/** @group ... */` em docblock. Os attributes
  `#[Test]`/`#[DataProvider]` são PHPUnit 10+/PHP 8 — em 7.4, `#[...]` é **comentário**
  e o PHPUnit 9 simplesmente **ignora** (teste some sem erro — ver §11).
- **Mocks:** `$this->createMock(Interface::class)`. Não usar Mockery — um único
  mecanismo de mock na base. **Sem intersection types em 7.4**: a propriedade do mock
  não pode ser tipada `Interface&MockObject` — declare sem tipo nativo e documente com
  `@var`.
- **Nomes reveladores de intenção:** o padrão do time (ex.: `deveXxx()` /
  `naoDeveXxx()`, ou prefixo `test`) — consistente e descrevendo a regra sob teste.
- **AAA:** Arrange → Act → Assert, blocos separados visualmente.
- **Agrupamento:** `@group` para separar testes que precisam de banco dos puramente
  unitários (o gate roda o subconjunto certo).

```php
/**
 * @group skip-migration
 */
final class CreateUserUseCaseTest extends TestCase
{
    /** @var UserRepositoryInterface&MockObject */
    private $repo; // intersection type não existe em 7.4 — docblock cumpre o papel

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
        $this->assertSame('John', $user->getName());
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

**Fixtures / dados compartilhados (Art. 3):** teste de repositório/endpoint que precisa
de banco roda num **SQLite em memória**, e o **schema e os dados de teste vivem num
helper central** (por convenção, sob `tests/Support/`) — um método por tabela para o
schema, um builder com defaults+overrides por linha. Declarar `CREATE TABLE`/`INSERT`
**inline** no teste é a mesma violação DRY dos helpers de produção: cópias divergem e
quebram em massa por *drift*. Coluna nova → edite o helper, num lugar só.

> ⚠️ **SQLite ≠ o banco de produção.** O teste em SQLite não substitui o *smoke* contra
> o banco real (MySQL/Postgres) quando o SQL do repositório muda — construções do
> dialeto (e erros como HY093) só aparecem lá.

**Régua (Art. 1):** existe teste que **falha se o comportamento regredir**. Gate de
autorização exige o teste de **403 sem permissão**, com o stack HTTP e a ordem de
middlewares de produção.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador:** **Composer 2** — roda em PHP ≥ 7.2.5, portanto funciona em 7.4.
`composer.json` declara, `composer.lock` **fixa** — o lock é **commitado** para builds
reprodutíveis.

- **Trave a plataforma:** `"require": { "php": "^7.4" }` **e**
  `"config": { "platform": { "php": "7.4.33" } }` no `composer.json` — sem isso, um
  `composer update` rodado numa máquina com PHP 8 resolve pacotes 8.x que explodem no
  servidor 7.4.
- **Política de versão:** constraints com caret para libs maduras; o `.lock` garante a
  versão exata em CI/produção. `composer install` em CI (respeita o lock);
  `composer update` só deliberadamente. **Realidade EOL:** as versões atuais da maioria
  das libs exigem PHP 8 — o 7.4 vive de majors antigas (ex.: Symfony 5.4 LTS,
  Laravel 8, PHPUnit 9). ⚠️ CONFIRMAR: essas majors ainda recebem correção de
  **segurança** hoje? A maioria das LTS 7.4-compatíveis já encerrou o suporte — cada
  dependência congelada é um item no inventário de risco do projeto.
- **Auditar vulnerabilidade conhecida:** `composer audit` no pipeline — o comando
  existe desde o **Composer 2.4** (que roda em 7.4, então é viável neste alvo).
  Ele consulta a **Packagist Security Advisories API**, que agrega o **GitHub Advisory
  Database** e o repositório **FriendsOfPHP/security-advisories** (sincronizados com
  CVE/NVD). Reprovar em severidade relevante, **citando o CVE/advisory ID**.
  Alternativas quando o Composer do ambiente for < 2.4: o binário standalone
  `local-php-security-checker` (não depende do PHP do projeto) ou o pacote
  `roave/security-advisories` (`dev-latest` — bloqueia a **instalação** de versão
  vulnerável via conflito). ⚠️ CONFIRMAR: `roave/security-advisories` instalável sob
  plataforma 7.4 sem conflitar com todo o lock congelado.
- **Higiene:** `composer outdated` para atrasos; evite pacote **abandonado** (o
  Packagist marca `abandoned`) e confira **licença** compatível antes de adicionar.
- **Autoload PSR-4:** classe nova exige `composer dump-autoload` (ou `-o` em produção).

**Armadilha comum:** não commitar o `composer.lock` (ou rodar `composer update` no
deploy) — cada ambiente resolve versões diferentes e o bug "só na produção" nasce aí.
Em base 7.4 o estrago é pior: o update acidental pode puxar major 8.x e derrubar o
deploy inteiro com parse error.

---

## 9. Reúso: o que já existe → Charter Art. 3

**Antes de escrever** helper, validação, conversão, DTO ou trait, **procure o
equivalente** — reimplementar o que existe (ou duplicar entre arquivos) é proibido,
mesmo que o código fique correto.

- **Casting/parse de entrada** (string→int/float/date, com null-safety) mora num
  **trait canônico de parsing** consumido por todos os DTOs — nunca reimplemente o
  conversor.
- **Par Create/Update** de um domínio compartilha validação/sanitização num **trait do
  domínio** — nunca duplique a regra entre os dois DTOs.
- **Conceito de domínio recorrente** (CPF, e-mail, código) vira **Value Object** único,
  não validação repetida em cada ponto de uso.
- **Funções 8.x que fazem falta** (`str_contains`, `str_starts_with`, `str_ends_with`)
  → **`symfony/polyfill-php80`**, não um helper caseiro por dev — o polyfill é a fonte
  única e desaparece sozinho no upgrade para 8.x (duplo ganho: Art. 3 hoje, migração
  amanhã). ⚠️ CONFIRMAR: `symfony/polyfill-php80` instalável sob PHP 7.4 (é o propósito
  do pacote, mas confirmar a constraint).
- **Prefira a stdlib e o framework** antes de rolar o seu: `filter_var`, `array_*`,
  `password_hash`, `DateTimeImmutable`, o QueryBuilder/HTTP client do framework.

**Como descobrir o que já existe:** busca por nome/conceito no `codePaths` da ficha;
**um guard determinístico** (teste de arquitetura) que **reprova** a reimplementação de
um conversor canônico transforma "lembre de reusar" em falha de build.

**Régua (Art. 3):** a mudança não introduz um **segundo caminho** para algo que já
existia; quando o conceito se repetiu, ele foi **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

O custo patológico mais comum em backend PHP é o **round-trip de banco em laço** (N+1):

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
- **Paginação** (`LIMIT`/`OFFSET`) em toda listagem de tamanho variável; **índice** nas
  colunas de `WHERE`/`ORDER BY`.
- **Grandes volumes:** `fetch()` linha a linha ou **generator (`yield`)** em vez de
  `fetchAll()` (não materializa o array inteiro); `unset()` em variáveis grandes após
  uso.
- **Trabalho pesado** (import/export, e-mail, webhook) vai para **fila/job**, não no
  request.
- **OPcache ligado em produção** e — recurso novo do 7.4 — **preloading**
  (`opcache.preload`) para as classes quentes do framework; exige restart do FPM a cada
  deploy do preload script.

**Ferramenta de medição idiomática:** `EXPLAIN` no banco **real** (não no SQLite de
teste) para plano de query; **Xdebug profiler** ou **SPX** para CPU/memória do PHP.
⚠️ CONFIRMAR: última série do Xdebug com suporte a PHP 7.4 (3.1.x — as séries seguintes
exigem PHP 8); Blackfire ainda oferece agente compatível com 7.4?

**Régua (Art. 8):** não há query/round-trip dentro de laço sobre dados de tamanho
variável; otimização não óbvia **cita a medição** que a justifica — nunca palpite.

**Armadilha comum:** `fetchAll()` num resultado grande e depois iterar — dobra o pico
de memória à toa; o `fetch()` em cursor faz o mesmo trabalho com pegada constante.

---

## 11. Gotchas da versão (7.4) → Charter Art. 1, 7

**Vindo de 7.0–7.3 (subindo para 7.4):**

- **`$str{0}` / `$arr{0}` (chaves) está deprecado** — troque por colchetes `[0]` agora;
  em 8.0 vira parse error. Legado 7.0–7.2 costuma estar cheio disso.
- **Ternário aninhado sem parênteses está deprecado** — `$a ? 1 : $b ? 2 : 3` exige
  parênteses explícitos; a associatividade antiga (à esquerda) era fonte clássica de
  bug silencioso.
- **Concatenação com `+`/`-` sem parênteses** (`'total: ' . $a + $b`) emite deprecation
  — a precedência muda em 8.0; parentesize já.
- **`fn` virou palavra reservada** — função/método chamado `fn()` quebra na subida.
- **Typed property não inicializada lança `Error`** no primeiro acesso ("must not be
  accessed before initialization") — não é `null`. Ao tipar propriedades antigas,
  garanta inicialização no construtor ou default explícito (`?T $x = null`).
- **`array_key_exists()` em objeto está deprecado** — use `property_exists()`/`isset`.
- **Spread em array aceita só chaves inteiras** — `[...$assoc]` com chave string é
  fatal error em 7.4 (string keys só em 8.1).

**Vindo de 8.x para trás (backport de código ou de hábito):**

- **`#[...]` NÃO é erro em 7.4 — é comentário `#`.** Um attribute (`#[Route(...)]`,
  `#[Test]`) é **silenciosamente ignorado**: a rota some, o teste não roda, a validação
  não se aplica — sem nenhuma mensagem. É o gotcha mais traiçoeiro do backport; o lint
  DEVE proibir `#[` no código.
- **Parse errors garantidos:** `match`, named arguments, constructor promotion,
  `readonly`, enums, `?->`, non-capturing catch, `throw` como expressão, trailing comma
  em lista de **parâmetros** (em **chamadas** pode, desde 7.3), `$obj::class` (use
  `get_class($obj)`).
- **Comparação frouxa é a PRÉ-8.0:** em 7.4, `0 == "foo"` é **`true`** (a string vira
  `0`); o "saner string to number comparison" é 8.0. Consequência prática: `in_array`
  e `switch` (comparação frouxa) com tipos mistos são armadilha — use `===`,
  `in_array(..., true)` e `strict_types` em tudo.
- **Erro que em 8.x lança, em 7.4 passa:** `1/0` é warning + `false` (não
  `DivisionByZeroError`); função interna com argumento inválido é warning + `null`
  (não `TypeError`). Sem o handler de `ErrorException` da §5, o fluxo continua com
  valor lixo.
- **`str_contains`/`str_starts_with`/`str_ends_with` não existem** — use o polyfill
  (§9) ou `strpos(...) !== false`; atenção ao clássico `if (strpos($a, $b))` que
  falha quando a agulha está na posição 0.

**Régua (Art. 1/7):** quem migra de/para 7.4 precisa que essas surpresas estejam
**cobertas por teste** (ex.: um teste que provaria o `#[...]` ignorado, um teste da
comparação estrita onde o dado é misto) e **comentadas com o porquê** onde a escolha
não é óbvia.

---

## 12. Ferramentas & comandos

Estes comandos são a ponte entre a doutrina (este perfil) e a automação (os gates leem
a ficha). Cada linha alimenta `keelson.config.json → quality.*`. Todas as ferramentas
abaixo **rodam sob PHP 7.4** (é o critério de escolha das versões):

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `composer test` (embrulha `vendor/bin/phpunit` — **PHPUnit `^9.6`**; 10+ exige PHP 8.1) | `quality.test` |
| **lint** | `vendor/bin/php-cs-fixer fix --dry-run --diff` (php-cs-fixer 3.x, exige PHP ≥ 7.4) ou `vendor/bin/phpcs --standard=PSR12 src tests` | `quality.lint` |
| **typecheck** | `vendor/bin/phpstan analyse` (**PHPStan 2.x roda em PHP ≥ 7.4**; 1.x também serve) ou `vendor/bin/psalm` (**Psalm 5.x** — a última série com suporte a 7.4). PHP não tem compilador; o analisador estático cumpre o papel. Opcional, mas **fortemente recomendado em base EOL** (pega o que o runtime permissivo deixa passar); se não adotado, `null`. | `quality.typecheck` |
| **build** | **não se aplica** — PHP é interpretado. O "build" de deploy é `composer install --no-dev --optimize-autoloader` + warmup de OPcache/preload, não um passo de gate. | `quality.build` (`null`) |

Exemplo de ficha correspondente:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "7.4" } },
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
charter (prova externa e falsificável) fica sem executor. E num alvo EOL, o analisador
estático configurado com `phpVersion: 70400` é também o guard que **reprova sintaxe
8.x** antes de ela virar parse error em produção.
