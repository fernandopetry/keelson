---
lang: php
version: "5.6"
charter: 0.3.0
generated-by: profile-writer
reviewed: false
reviewer: null
---

# PHP 5.6 — Perfil de linguagem (legado)

> Instância do `QUALITY-CHARTER.md` (v0.3.0) para **PHP 5.6 legado**. Cada seção pega um
> artigo do charter e responde: *"em PHP 5.6, isto se cumpre assim, com esta ferramenta,
> com esta armadilha a evitar"*. Mesma espinha do exemplar PHP 8.5 (seções 0–12),
> conteúdo específico da versão.
>
> **Este perfil é um rascunho gerado (`reviewed: false`).** Afirmações de segurança
> inferidas sem confirmação documental estão marcadas `⚠️ CONFIRMAR:` para dirigir a
> revisão humana.
>
> **Escopo:** o que é idiomático — e o que é *possível* — em PHP 5.6. A arquitetura
> específica do projeto mora em `guidelines/project/` e na ficha `keelson.config.json`;
> aqui os caminhos são placeholders (`src/`, `tests/`).

---

## 1. Identidade & versão

> **⛔ PHP 5.6 está em fim de vida (EOL) desde 31/12/2018.** Não recebe patch de
> segurança do PHP.net há anos; vulnerabilidades descobertas desde então permanecem
> abertas no runtime. Todo trabalho neste perfil convive com esse fato: a postura é
> **mitigar** (superfície reduzida, isolamento de rede, WAF na frente, dependências
> auditadas) e manter o **plano de upgrade para PHP suportado como recomendação
> permanente** — registrado como dívida, não esquecido.
> ⚠️ CONFIRMAR: se o servidor usa pacote de distro com backport (RHEL, Debian ELTS,
> Ubuntu ESM), verificar **quais** CVEs o backport realmente cobre — cobertura é parcial
> e varia por distro.

O alvo é **PHP 5.6** (última minor da série 5.x). O teto de sintaxe é rígido: código
com construção de 7.x/8.x **não passa do parser** (ver §11).

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| **Variadics `...$args`** | Assinatura variádica declarada, no lugar de `func_get_args()` | 5.6 |
| **Argument unpacking `...$arr`** | Espalhar array em chamada, no lugar de `call_user_func_array` | 5.6 |
| **Constant expressions** | `const FOO = BAR * 2;`, `const LIST = ['a', 'b'];` | 5.6 |
| **`use function` / `use const`** | Importar função/constante de namespace | 5.6 |
| **`hash_equals()`** | Comparação de strings em tempo constante (tokens, HMAC) | 5.6 |
| **Generators (`yield`)** | Iterar grandes volumes sem materializar o array | 5.5 |
| **`finally`** | Limpeza garantida em `try/catch` | 5.5 |
| **`password_hash` / `password_verify`** | Hash de senha (bcrypt) — obrigatório sobre md5/sha1 | 5.5 |
| **`::class`** | FQCN sem string mágica | 5.5 |
| **OPcache embutido** | Cache de opcode em produção | 5.5 |
| **Traits** | Reúso horizontal (validação/parsing compartilhado) | 5.4 |
| **Short array `[]`** | Sintaxe de array curta, sempre | 5.4 |

**O que NÃO existe em 5.6** (usar = parse error ou função indefinida — ver §11):
`declare(strict_types=1)`, scalar type hints, return types, `??`, `<=>`, classes
anônimas, `random_bytes`/`random_int`, `\Throwable`/`\Error`, multi-catch, arrow
functions, typed properties, `match`, named arguments, enums, `readonly`,
first-class callable. **A disciplina de tipo se faz por docblocks (`@param`,
`@return`, `@var`) + validação manual na borda** (ver §4).

**Construções que existem em 5.6 mas NÃO DEVEM ser usadas:** extensão `mysql_*`
(insegura, removida no 7.0 — use PDO), `mcrypt_*` (lib abandonada — use `openssl_*`,
ver §6.6), `preg_replace` com modificador `/e` (injeção de código — use
`preg_replace_callback`), construtor estilo PHP 4 (método com nome da classe — use
`__construct`), `ereg_*`, `split()`, o operador `@`.

**Por que a versão é seção de primeira classe:** "PHP" em 5.6 e em 8.x é quase outra
linguagem. Quem escreve com memória muscular de 8.x produz código que **nem parseia**
em 5.6 — e o erro só aparece no servidor. O guard disso é lint de parse com o binário
5.6 real + PHPCompatibility (§11, §12).

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Guia canônico: PSR-2** — o padrão de estilo da era 5.x. PSR-12/PER pressupõem
construções de PHP 7+ (`declare(strict_types)`, return types) e as ferramentas que os
impõem exigem runtime mais novo.
⚠️ CONFIRMAR: viabilidade prática de ruleset PSR-12 nas versões de ferramenta que
rodam em 5.6 — a recomendação segura é PSR-2.

- **Linter de estilo:** `phpcs`/`phpcbf` (PHP_CodeSniffer 3.x) com `--standard=PSR2`.
  ⚠️ CONFIRMAR: PHP_CodeSniffer 3.x roda em PHP 5.4+ (portanto no próprio 5.6).
- **Formatter alternativo:** **PHP-CS-Fixer 2.19** (última linha 2.x; suporta PHP
  5.6–7.4 — confirmado). Config da era 2.x é **`.php_cs.dist`** na raiz (o nome
  `.php-cs-fixer.dist.php` é da linha 3.x, que não roda em 5.6).
- **Lint de parse (obrigatório):** `php -l` com o **binário 5.6 real** em todo arquivo
  tocado — é o único guard barato contra sintaxe 7.x/8.x acidental. Em lote:
  PHP Parallel Lint. ⚠️ CONFIRMAR: versão do parallel-lint que roda em PHP 5.6 (a
  linha antiga `jakub-onderka/php-parallel-lint`; o fork atual
  `php-parallel-lint/php-parallel-lint` declara suporte a PHP antigo).
- **É erro (bloqueia):** violação PSR-2 reportada pelo phpcs; qualquer parse error no
  `php -l`; uso de `mysql_*`, `mcrypt_*`, `@`, `/e` (detectáveis por sniff/grep).
- **É aviso (não bloqueia):** ordenação de `use`, largura de linha — decisão do time.
- **Comando de lint** (alimenta `keelson.config.json → quality.lint`):
  `vendor/bin/phpcs --standard=PSR2 src/ tests/` (exit ≠ 0 reprova).

**Armadilha comum:** rodar o fixer/`phpcbf` (que reescrevem) no gate em vez do modo
verificação — o gate deve **reprovar**, não corrigir silenciosamente. E rodar o lint
de estilo com um binário PHP 8 local: o estilo passa, mas o parse contra 5.6 nunca foi
testado — os dois checks são independentes.

---

## 3. Nomenclatura & idioma → Charter Art. 5

**Convenção por símbolo** (PSR-1/PSR-4 — já vigentes na era 5.6, sem exceção):

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Classe / Interface / Trait | `PascalCase` | `CreateUserUseCase` |
| Método / função / variável / propriedade | `camelCase` | `findById`, `$emailExists` |
| Constante de classe / global | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `STATUS_OPEN` |
| Arquivo | idêntico ao FQCN (PSR-4), 1 classe por arquivo | `CreateUserUseCase.php` |

**Padrões de nome que sinalizam papel:** `*Interface` (contrato) · `Pdo*Repository`
(implementação PDO) · `*UseCase` (um caso de uso, um `execute()`) · `*DTO`
(transporte, sem lógica) · `*Trait` (reúso horizontal) · `*Test` (teste da classe
homônima). Sem enums na linguagem, **conjuntos fechados de valores viram constantes de
classe com prefixo comum** (`Status::OPEN`, `Status::CLOSED`) — o prefixo é o nome do
conceito, nunca constantes soltas.

**Idioma:** identificadores em **inglês** (norma do ecossistema PHP). Idioma dos
comentários é decisão do projeto (`guidelines/project/`), mas **único e consistente**
na base — nunca misturado no mesmo arquivo.

**Docblock é contrato, não decoração:** sem type hints escalares nem return types, o
docblock (`@param string $email`, `@return User|null`) é **a única declaração de tipo
que o leitor e o IDE têm**. Docblock ausente ou mentiroso em API pública é violação do
Art. 5 — o nome + docblock precisam contar a verdade que a assinatura não consegue.

**Armadilha comum:** nomear pela implementação (`$arrayDeUsers`, `processData`) em vez
da intenção (`$activeUsers`, `deactivateExpiredContracts`) — em 5.6, sem tipos na
assinatura, o nome ruim custa dobrado.

---

## 4. Estrutura & arquitetura → Charter Art. 4, 7

O padrão continua **Clean/Hexagonal**, com dependência apontando para dentro:

```
Presentation → Application → Domain ← Infrastructure
```

| Camada | PODE conter | NÃO PODE conter |
|--------|-------------|-----------------|
| **Domain** | Entities, Value Objects, interfaces de repositório | Framework, PDO, HTTP, SQL |
| **Application** | UseCases, DTOs, orquestração | Request/Response, SQL, I/O |
| **Infrastructure** | Implementações das interfaces (PDO, HTTP client) | Regra de negócio |
| **Presentation** | Controllers/Actions, mapear HTTP↔DTO | Regra de negócio, SQL |

**Blocos idiomáticos em 5.6** — sem `readonly`, sem typed properties, sem promoção de
construtor, a imutabilidade e a validação são **disciplina manual**:

- **Value Object / DTO** — propriedades **`private`** + getters; **valida no
  construtor** e lança `InvalidArgumentException`; **nenhum setter** (imutabilidade por
  ausência de mutador, já que `readonly` não existe).
- **UseCase** — um `execute()`; recebe DTO, devolve Entity/resultado; dependências
  entram **pelo construtor** como **interfaces**.
- **Repository** — interface no Domain, implementação PDO na Infrastructure;
  `hydrate()` privado; sem regra de negócio.
- **Named constructor** — `public static function fromArray(array $data)` como fábrica
  (funciona igual em 5.6); a validação de tipo que `strict_types` faria é feita ali,
  na borda: `if (!is_string($data['email'])) { throw new \InvalidArgumentException(...); }`.

```php
<?php

namespace App\Application\UseCases\User;

use App\Domain\Repositories\User\UserRepositoryInterface;
use App\Domain\Entities\User\User;

final class CreateUserUseCase
{
    /** @var UserRepositoryInterface */
    private $repo;

    // Depende da ABSTRAÇÃO (interface), nunca do PDO concreto → testável sem banco.
    public function __construct(UserRepositoryInterface $repo)
    {
        $this->repo = $repo;
    }

    /**
     * @param CreateUserDTO $dto
     * @return User
     * @throws \DomainException se o e-mail já existe
     */
    public function execute(CreateUserDTO $dto)
    {
        if ($this->repo->emailExists($dto->getEmail())) {
            throw new \DomainException('Email already registered');
        }

        return $this->repo->save(User::fromDto($dto));
    }
}
```

**Isolamento de efeito colateral:** todo I/O (banco, rede, filesystem, relógio,
`$_SESSION`) entra por **interface injetada no construtor**. Type hint de classe e
interface **existe** em 5.6 (`function __construct(UserRepositoryInterface $repo)`) —
use sempre; só o escalar que não dá para tipar.

**Condicionais e assinaturas (Art. 4, 7):** *early return* (guard clause) antes de
`if/else` aninhado. Sem `match`, o despacho por variante usa **polimorfismo por
interface** (implementações registradas num mapa `['tipo' => Handler]`) ou, para casos
simples, `switch` **num único ponto** — o mesmo `switch` repetido em vários arquivos é
o sinal de que a interface está faltando. Método passando de **~4 parâmetros** →
agrupe num **objeto de parâmetro/DTO** (classe simples com getters); named arguments
não existem, então parâmetro opcional demais vira DTO, não cauda de `null`s.

**Padrões na prática (5.6)** — a construção idiomática antes do padrão clássico:

- **Strategy/State** → interface + mapa de implementações; **não** existe enum/match.
- **Factory** → *named constructor* estático antes de classe-fábrica dedicada.
- **Observer** → o event dispatcher do framework da época, não implementação manual.
- **Reúso horizontal** → **trait** (5.4) para validação/parsing compartilhado entre
  DTOs — antes de herança.
- **Armadilhas PHP:** Singleton e `static` mutável; *service location* (puxar do
  container global) dentro de Domain/Application; herança para reuso (composição
  primeiro); `global $db` — o clássico do legado 5.x, proibido em código novo.

**Armadilha comum:** SQL, `$_SESSION`, `$_GET`/`$_POST` ou `getenv()` dentro de
UseCase/Domain — em bases 5.6 legadas isso é endêmico; código **novo** não repete o
padrão, e código tocado é migrado oportunisticamente (Art. 6: escopo restrito — não
reescreva o arquivo inteiro junto).

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceções, não códigos de retorno**, para condição excepcional. Fluxo normal ("não
encontrado" esperado) PODE ser `null` (documentado como `@return User|null`); violação
de regra é **exceção tipada** (`DomainException`, `InvalidArgumentException` — as SPL
existem desde sempre). Nunca lance `\Exception` cru.

**A diferença crítica de 5.6: não existe `\Throwable`.** Erro fatal de engine (método
inexistente, argumento de tipo errado em type hint de classe, esgotamento de memória)
**não é capturável** — em 7.x ele vira `\Error`; em 5.6 ele **derruba o request**.
Consequências práticas:

- `catch (\Exception $e)` é o topo da hierarquia capturável. `catch (\Throwable $e)`
  é **parse-ok mas nunca casa** (a classe não existe) — bug silencioso clássico de
  quem porta código de 7.x.
- Fatais são registrados via `register_shutdown_function` + `error_get_last()` — é o
  único jeito de logar o fatal antes do processo morrer. Esse handler é parte da
  fundação do app, não opcional.
- `set_error_handler` convertendo warnings/notices em `ErrorException` torna os erros
  "moles" visíveis e testáveis em vez de poluir o log.

**Regras:**

- **Nunca engolir:** `catch (\Exception $e) {}` vazio e o operador `@` são proibidos —
  capturou, ou trata, ou re-lança com contexto.
- **Produção:** `display_errors=Off`, `log_errors=On`. Em 5.6 EOL isso é ainda mais
  crítico: stack trace na tela entrega versão e paths a um atacante contra um runtime
  sem patch.
- **Fronteira de conversão:** um único ponto (front controller / handler global)
  captura `\Exception`, loga o detalhe do lado do servidor e devolve mensagem
  **genérica** com o status HTTP correto. `$e->getMessage()` **não** vai cru na
  resposta.

```php
try {
    $user = $this->useCase->execute($dto);
    return $this->ok($response, $user->toArray());
} catch (\InvalidArgumentException $e) {
    return $this->error($response, 'Validation failed', 422);
} catch (\DomainException $e) {
    return $this->error($response, $e->getMessage(), 400); // mensagem de negócio, curada
} catch (\Exception $e) {
    $this->logger->error('user.create.failed', array('exception' => $e->getMessage()));
    return $this->error($response, 'Internal error', 500);  // genérico para o cliente
}
```

**O que logar (Art. 2):** identificadores e ação (`user_id`, `action`), a exceção com
stack **do lado do servidor** — **nunca** senha, token, PII ou corpo cru da requisição.

**Armadilha comum — Information Disclosure:** sanear a mensagem só no log e devolver
`$e->getMessage()` cru na resposta. E, específico de 5.6: confiar num
`catch (\Throwable)` portado de 7.x que **nunca executa** — o fatal passa direto e o
usuário vê a tela branca (ou o stack, se `display_errors` estiver ligado).

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> **⛔ Runtime EOL: a primeira mitigação é reduzir a exposição.** PHP 5.6 não recebe
> patch — vulnerabilidade no interpretador/extensões fica aberta. Postura obrigatória
> enquanto o upgrade não acontece: **superfície mínima** (desabilitar extensões e
> endpoints não usados, `expose_php=Off`), **isolamento** (segmentação de rede, o
> app 5.6 não fala com o que não precisa), **WAF/proxy reverso** na frente filtrando o
> grosso (e escondendo o banner de versão), **auditoria de dependências** (§8) e o
> **plano de upgrade como recomendação permanente** em toda entrega relevante.
> ⚠️ CONFIRMAR: inventário real de CVEs abertos contra a build 5.6 específica do
> servidor (via NVD/`/keelson:audit`) — a lista muda conforme a minor/backport.
>
> Cada item abaixo é um item da **Régua do Art. 2** traduzido para "como se faz e como
> se erra em PHP 5.6". Vulnerabilidade aqui é **rejeição imediata** no review.

### 6.1 Injeção → sempre parametrizar

**SQL — PDO com parâmetros nomeados**, nunca concatenação nem interpolação:

```php
// ✅ prepared statement, parâmetros nomeados — funciona igual em 5.6
$stmt = $pdo->prepare('SELECT id, name, email FROM users WHERE email = :email');
$stmt->execute(array('email' => $email));

// ❌ NUNCA — concatenar/interpolar entrada externa é SQL Injection
$pdo->query("SELECT * FROM users WHERE email = '$email'");

// ❌ NUNCA — a extensão mysql_* existe em 5.6 e é PROIBIDA (removida no 7.0)
mysql_query("SELECT * FROM users WHERE email = '$email'");
```

- `PDO::ATTR_EMULATE_PREPARES => false` (prepared statements reais no driver) e
  **charset no DSN** (`mysql:host=...;dbname=...;charset=utf8mb4`) — sem o charset no
  DSN, prepares emulados + charset multi-byte (GBK e afins) reabrem a injeção clássica
  que o escaping não cobre.
- O que não dá para bindar (coluna em `ORDER BY`) → **whitelist**, nunca interpolação.
- **Command injection:** evite `exec/shell_exec/system`; se inevitável,
  `escapeshellarg()` em cada argumento.
- **Path traversal:** `basename()` + validação contra diretório-base; nunca
  `file_get_contents($userInput)` cru; `allow_url_include=Off` (e conferir
  `allow_url_fopen`).
- **Code injection específico da era:** `preg_replace` com `/e` (deprecado em 5.5,
  ainda funcional em 5.6) executa o replacement como código — **proibido**; use
  `preg_replace_callback`. `eval()`, `assert()` com string e `extract($_REQUEST)`
  idem.
- **Object injection:** `unserialize()` em 5.6 **não tem** `allowed_classes` (a opção
  é do 7.0) — **nunca** desserialize entrada externa; o formato de troca é
  `json_decode`/`json_encode`.

**Armadilha comum:** "escapar com `addslashes`/`mysql_real_escape_string` é
suficiente" — não é, e a segunda função pertence à extensão proibida. Parametrização é
o mecanismo; escaping de SQL manual é o anti-padrão.

### 6.2 Saída / escaping → escapar no destino

Escape **por contexto de saída**, no ponto de renderização:

```php
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); // HTML — charset SEMPRE explícito
echo rawurlencode($value);                           // componente de URL
echo json_encode($value);                            // contexto JS/JSON — ver nota abaixo
```

- **`JSON_THROW_ON_ERROR` não existe** (é do 7.3): todo `json_encode`/`json_decode`
  em fronteira **verifica `json_last_error()`** — em falha, o encode devolve `false`
  silenciosamente e a resposta corrompida segue adiante.
- Em template PHP cru (o comum na era 5.6), **todo `echo` de dado externo passa por
  `htmlspecialchars`** — centralize num helper (`e($value)`) para não depender de
  disciplina ponto a ponto. Se houver Twig/Smarty, o autoescape fica **ligado**.
- Para JSON embutido em `<script>`, `json_encode` com
  `JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT` (todas existem em 5.6).

**Armadilha comum:** sanear o valor na entrada ("limpei no POST") e considerá-lo
seguro para sempre — escaping é do **sink**, não da entrada; cada contexto de saída
escapa de novo, no seu formato.

### 6.3 Autorização → negar por padrão

Toda ação verifica **permissão antes de executar**; o default é **negar**. Em apps
5.6 sem pipeline de middleware, a checagem vive num **ponto único do bootstrap/front
controller** — nunca como `include 'check_auth.php'` copiado por página (um
esquecimento = endpoint aberto; é negar-por-padrão invertido).

- **IDOR / acesso por registro:** permissão genérica não basta — o registro pertence
  ao solicitante (`WHERE owner_id = :currentUserId` na própria query).
- **Tenant/instância:** o identificador vem da **sessão server-side**, populado num
  ponto único — nunca de header/query/path. Leitor ausente **nega**; default
  permissivo (`isset($x) ? $x : 1`) é bug de segurança.
- **Serialização de dado sensível:** default **fail-closed** — omitir por padrão,
  expor por parâmetro explícito.
- **Prova:** gate de autorização exige teste provando **403 sem a permissão** (não só
  200 com ela).

⚠️ CONFIRMAR: no framework legado real do projeto (CodeIgniter 2/3, CakePHP 2, Zend 1,
app procedural…), **onde** é o ponto único de autorização e se a ordem
bootstrap→auth→ação é garantida — cada um da era faz diferente.

### 6.4 Segredos & configuração → fora do código, fora do log

- Segredos vêm de **variável de ambiente / arquivo de config fora do webroot** —
  nunca hardcoded, nunca commitados. `.env` no `.gitignore`.
  ⚠️ CONFIRMAR: versão de `vlucas/phpdotenv` compatível com 5.6 (linha 2.x), se o
  projeto usar `.env`.
- Segredo **nunca** em log, mensagem de erro, nem query string de URL.
- **Senhas: `password_hash($senha, PASSWORD_DEFAULT)`** (bcrypt em 5.6) +
  `password_verify` + `password_needs_rehash` para migrar hashes legados (md5/sha1/
  `crypt`) **no próximo login**. `PASSWORD_ARGON2ID` **não existe** (7.3+). MD5/SHA1
  para senha é rejeição imediata.
- Comparação de token/HMAC com **`hash_equals()`** (existe em 5.6) — `==`/`===` em
  segredo é vulnerável a timing.

```php
// ❌ NUNCA
error_log("password: $password");
// ✅ apenas identificador e ação
$logger->info('login_attempt', array('user_id' => $userId));
```

### 6.5 Sessão & estado de autenticação

- **Config de sessão** (ini/bootstrap): `session.cookie_httponly=1`,
  `session.cookie_secure=1` (só HTTPS), `session.use_strict_mode=1` (recusa id de
  sessão não iniciado pelo servidor — existe desde 5.5.2), `session.use_only_cookies=1`.
- **`SameSite` NÃO existe em 5.6**: o suporte em `setcookie()`/sessão é do PHP 7.3.
  Consequência direta: **a proteção CSRF não pode se apoiar em cookie — token
  anti-CSRF é obrigatório** em todo POST/PUT/DELETE, gerado com CSPRNG (§6.6) e
  comparado com `hash_equals()`.
  ⚠️ CONFIRMAR: se optarem por emitir `SameSite` manualmente via `header('Set-Cookie: ...')`,
  validar o comportamento (duplicação de header de sessão, compat de navegador) — é
  workaround frágil, não substitui o token CSRF.
- `session_regenerate_id(true)` **no login** (anti session fixation); expiração por
  inatividade; invalidação no logout (destruir a sessão server-side, não só o cookie).
- Token de autenticação para SPA/mobile: entregue como cookie `httponly` — nunca
  orientar `localStorage`.

### 6.6 Criptografia, aleatoriedade & upload

- **`random_bytes`/`random_int` NÃO existem** (7.0+). O canônico é o polyfill
  **`paragonie/random_compat`** (usa libsodium → `/dev/urandom` → `mcrypt_create_iv`,
  nesta ordem) — instale e chame `random_bytes()` normalmente.
  `openssl_random_pseudo_bytes()` só como **último recurso**, sempre verificando o
  parâmetro `$crypto_strong` — o próprio random_compat a **removeu** dos fallbacks por
  risco de entropia insuficiente. `rand()`, `mt_rand()` e `uniqid()` para
  token/segurança são rejeição imediata.
- **`mcrypt_*` existe em 5.6 e DEVE ser evitado** (libmcrypt abandonada; removida do
  PHP no 7.2): cifra nova usa **`openssl_encrypt`/`openssl_decrypt`**. Atenção: em
  5.6 o `openssl_encrypt` **não tem** os parâmetros AEAD (`$tag` é do 7.1), então
  **GCM não é utilizável** — o padrão é **AES-256-CBC + HMAC (encrypt-then-MAC)** com
  chaves separadas, ou a biblioteca **`defuse/php-encryption` v2** (suporta PHP 5.6+,
  OpenSSL 1.0.1+), que encapsula isso corretamente.
  ⚠️ CONFIRMAR: qual release da linha 2.x do defuse/php-encryption ainda instala
  limpo sob Composer com `platform.php = 5.6`.
- **TLS de saída:** PHP 5.6 foi a versão que passou a **verificar peer por padrão**
  nos stream wrappers — não desligue (`verify_peer=false` / `CURLOPT_SSL_VERIFYPEER=false`
  são rejeição imediata). ⚠️ CONFIRMAR: a build de OpenSSL do servidor legado suporta
  TLS 1.2 — builds da era param em TLS 1.0/1.1, hoje rejeitados por APIs externas.
- **Mass assignment:** Entity montada de **DTO com campos whitelistados** — nunca
  `fromArray($_POST)` direto.
- **Upload:** whitelist de extensão **e** MIME real (`finfo_file`); arquivo salvo
  **fora do webroot** com nome gerado (nunca o nome do cliente); em 5.6 EOL, upload
  executável dentro do webroot é RCE de manual.

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico: PHPUnit 5.7** — a última linha que roda em PHP 5.6 (confirmado;
PHPUnit 4.8 é o fallback se alguma dependência travar a resolução). Comando (alimenta
`keelson.config.json → quality.test`): `vendor/bin/phpunit` (embrulhado em
`composer test` se o projeto definir o script).

**Convenções da era — o que muda vs. o exemplar 8.5:**

- **Annotations, não atributos:** `@test`, `@dataProvider`, `@group` em docblock —
  atributos (`#[Test]`) são sintaxe PHP 8 e **nem parseiam** aqui.
- **`setUp()` sem `: void`** — return type é sintaxe 7.x; escrever
  `protected function setUp(): void` quebra o parse do arquivo inteiro.
- **Mocks:** `$this->createMock(Interface::class)`.
  ⚠️ CONFIRMAR: `createMock()` entrou na linha 5.x do PHPUnit (por volta de 5.4);
  em PHPUnit 4.8 o equivalente é `getMockBuilder(...)->getMock()`.
- **Exceções:** `$this->expectException(\DomainException::class)`.
  ⚠️ CONFIRMAR: disponível a partir de PHPUnit 5.2; em 4.8, `setExpectedException()`.
- Um único mecanismo de mock na base (sem misturar Mockery).

```php
<?php

use App\Application\UseCases\User\CreateUserUseCase;
use App\Application\DTOs\User\CreateUserDTO;
use App\Domain\Repositories\User\UserRepositoryInterface;

/**
 * @group skip-migration
 */
final class CreateUserUseCaseTest extends PHPUnit_Framework_TestCase
{
    /** @var UserRepositoryInterface|\PHPUnit_Framework_MockObject_MockObject */
    private $repo;

    /** @var CreateUserUseCase */
    private $useCase;

    protected function setUp() // sem ": void" — sintaxe 7.1 não parseia em 5.6
    {
        $this->repo = $this->createMock('App\Domain\Repositories\User\UserRepositoryInterface');
        $this->useCase = new CreateUserUseCase($this->repo);
    }

    /** @test */
    public function deveCriarUsuarioQuandoEmailInedito()
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
    public function naoDeveCriarComEmailExistente()
    {
        $this->repo->method('emailExists')->willReturn(true);

        $this->expectException('DomainException');
        $this->useCase->execute(new CreateUserDTO('John', 'john@example.com'));
    }
}
```

**Testar comportamento, não implementação:** prove regra de negócio, cálculo crítico,
validação de domínio e edge cases; não teste getter trivial nem infraestrutura
externa. Mocke as **fronteiras** (interfaces); nunca a unidade sob teste.

**Fixtures / dados compartilhados (Art. 3):** teste que precisa de banco roda em
**SQLite em memória** (`sqlite::memory:` via PDO — funciona em 5.6); schema e dados de
teste vivem num **helper central** (`tests/Support/`) — um método por tabela, um
builder com defaults+overrides por linha. `CREATE TABLE`/`INSERT` inline no teste é a
violação DRY que quebra em massa por *drift*.

> ⚠️ **SQLite ≠ banco de produção** — e em 5.6 o *smoke* contra o banco real importa
> dobrado: os servidores MySQL da era (5.5/5.6) têm dialeto e defaults (`sql_mode`
> frouxo, charset) que o SQLite não simula.

**Régua (Art. 1):** existe teste que **falha se o comportamento regredir**; gate de
autorização exige o teste de **403 sem permissão** com o stack real.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador: Composer** — funciona normalmente com PHP 5.6, com uma bifurcação
importante:

- **Composer rodando no próprio 5.6:** a última linha compatível é a **2.2 LTS**
  (Composer 2.3+ exige PHP 7.2.5 — confirmado). **`composer audit` NÃO existe** nessa
  linha (o comando entrou no **2.4** — confirmado).
- **Alternativa recomendada:** rodar um Composer **atual** num binário PHP moderno
  (CI/máquina de build) com **`config.platform.php: "5.6.40"`** no `composer.json` —
  a resolução de dependências respeita o 5.6 do runtime, e `composer audit` volta a
  existir no pipeline.

**Auditoria de vulnerabilidade conhecida** (o gate não fica sem executor):

1. **`composer audit`** via Composer moderno + `platform.php` (caminho preferido) —
   consulta a **Packagist Security Advisory API**, alimentada pelo
   **FriendsOfPHP/security-advisories** e sincronizada com CVE/NVD; reprovar em
   severidade relevante **citando o advisory/CVE ID**.
2. **`roave/security-advisories` (`dev-latest`)** como `require-dev` — metapacote de
   `conflict` que **impede instalar/atualizar** para versão vulnerável (não escaneia o
   lock existente, previne daqui para frente).
   ⚠️ CONFIRMAR: instalação limpa sob Composer 2.2 com `platform.php = 5.6` — o
   pacote é só metadata, mas os conflitos podem travar libs legadas já vulneráveis
   (o que, a rigor, é o aviso funcionando).
3. **`local-php-security-checker`** (binário Go, independente do PHP do servidor) —
   escaneia o `composer.lock` contra o mesmo advisory database.
   ⚠️ CONFIRMAR: estado de manutenção atual do projeto e cobertura do database.

**Política de versão:** `composer.lock` **commitado**; `composer install` em CI
(respeita o lock), `composer update` só deliberado. Constraints com caret. Realidade
5.6: o ecossistema **não publica mais** versões compatíveis — a maioria das libs está
congelada em linhas antigas (elas próprias EOL). Toda dependência nova exige checar
compatibilidade com 5.6 **e** entra na conta da dívida de upgrade.

**Armadilha comum:** rodar `composer update` num binário PHP 8 **sem**
`config.platform.php` — o resolver escolhe versões para PHP 8, o deploy instala no
5.6 e explode em runtime (ou nem instala). O `platform.php` é obrigatório no
`composer.json` deste perfil.

---

## 9. Reúso: o que já existe → Charter Art. 3

**Antes de escrever** helper, validação, conversão, DTO ou trait, **procure o
equivalente** — reimplementar o que existe é proibido, mesmo correto.

- **Casting/parse de entrada** (string→int/float/date, com null-safety manual — sem
  `??`, o padrão é `isset($x) ? (int) $x : null` **centralizado**) mora num **trait
  canônico de parsing** consumido pelos DTOs — nunca reimplemente o conversor, e nunca
  espalhe o ternário-de-isset pelo código: ele é exatamente o tipo de expressão que
  diverge silenciosamente.
- **Par Create/Update** de um domínio compartilha validação num **trait do domínio**.
- **Conceito recorrente** (CPF, e-mail, código) vira **Value Object** único.
- **Prefira a stdlib antes de rolar o seu:** `filter_var` (validação de e-mail/URL/IP),
  `array_*`, `password_hash`, `DateTimeImmutable` (existe desde 5.5), `finfo`,
  `hash_equals`.
- **Polyfills canônicos antes de gambiarra:** `paragonie/random_compat`
  (`random_bytes`); ⚠️ CONFIRMAR: `symfony/polyfill-php70` como fonte de outras
  funções de 7.0 (`intdiv`, `error_clear_last`) em 5.6 — verificar a versão da linha
  polyfill que ainda suporta instalar sob 5.6.

**Como descobrir o que já existe:** busca por nome/conceito nos `codePaths` da ficha;
um guard determinístico que reprova a reimplementação de um conversor canônico
transforma "lembre de reusar" em falha de build.

**Régua (Art. 3):** a mudança não introduz um **segundo caminho** para algo que já
existia; conceito repetido foi **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

O custo patológico número um continua o **round-trip de banco em laço** (N+1):

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
$stmt->execute(array('status' => 'OPEN'));
```

Padrões a seguir — com o agravante de que **o runtime 5.6 é ~2× mais lento que o 7.x**
(a migração de versão é a maior otimização disponível, e entra no argumento do plano
de upgrade):

- **`SELECT` só das colunas usadas**; **paginação** em toda listagem; índice nas
  colunas de `WHERE`/`ORDER BY`.
- **Grandes volumes:** `fetch()` linha a linha ou **generator (`yield`, 5.5)** em vez
  de `fetchAll()`; `unset()` de variáveis grandes após uso — o limite de memória por
  request morde mais cedo em 5.6.
- **OPcache ligado em produção** (embutido desde 5.5) — sem ele, cada request
  recompila tudo; é a otimização de maior retorno disponível dentro da versão.
- **Trabalho pesado** (import/export, e-mail, webhook) vai para fila/cron, não no
  request.

**Ferramenta de medição idiomática:** `EXPLAIN` no banco **real**; para CPU/memória do
PHP, **Xdebug 2.x** (profiler cachegrind) — ⚠️ CONFIRMAR: a última versão da linha 2.x
compatível com PHP 5.6 (a linha 3.x não suporta PHP 5). `microtime(true)` + log para
medições pontuais quando instalar profiler no legado não for viável.

**Régua (Art. 8):** não há query/round-trip dentro de laço sobre dados de tamanho
variável; otimização não óbvia **cita a medição** — nunca palpite.

---

## 11. Gotchas da versão (5.6) → Charter Art. 1, 7

O perfil-espelho do exemplar: aqui as pegadinhas são para **quem vem de 7.x/8.x e
escreve para 5.6** — a maioria quebra **no parse**, ou seja, derruba o arquivo inteiro
no servidor:

- **Sintaxe que NÃO parseia em 5.6** (checklist de review): `declare(strict_types=1)` ·
  scalar type hints (`function f(int $x)`) · return types (`: void`, `: User`) · `??`
  e `??=` · `<=>` · `fn() =>` · `match` · named args (`f(x: 1)`) · enums · `readonly` ·
  typed properties (`private int $x`) · promoção de construtor · classes anônimas ·
  multi-catch (`catch (A | B $e)`) · group use (`use App\{A, B}`) · visibilidade em
  constante de classe (`private const`) · **vírgula final em chamada de função**
  (7.3+) · first-class callable (`strlen(...)`). O guard disso é `php -l` com binário
  5.6 + **PHPCompatibility** (ruleset do phpcs) com `testVersion 5.6`.
  ⚠️ CONFIRMAR: requisitos de runtime da versão atual do PHPCompatibility (se roda no
  binário 5.6 ou precisa rodar num PHP moderno apontando para o código legado).
- **O que parseia mas mente:** `catch (\Throwable $e)` compila e **nunca captura**
  (§5); `random_bytes()`/`random_int()`/`intdiv()` parseiam e explodem em runtime como
  função indefinida — e sem `\Error`, isso é **fatal não capturável**.
- **Comportamentos da era que surpreendem quem vem de 8.x:** divisão por zero é
  warning + `false` (não exceção); string não numérica em aritmética vira `0` sem
  `TypeError`; `count(null)` devolve `0` sem aviso; `"abc" == 0` é **`true`** na
  comparação frouxa de 5.6 (a semântica só mudou no PHP 8) — **`===` sempre**;
  `foreach` interage com o ponteiro interno do array de forma diferente do 7.x
  (comportamento redefinido no 7.0); *uniform variable syntax* do 7.0 mudou a ordem de
  avaliação de `$$foo['bar']` — expressões variáveis-variáveis escritas num mundo não
  rodam igual no outro (mais um motivo para bani-las).
- **Legado dentro do legado:** construtor estilo PHP 4, `mysql_*`, `ereg_*`, `/e` —
  funcionam em 5.6 e são proibidos em código novo (§1); todos morrem na migração 7.x.
- **Migração 5.6 → 7.x (o plano permanente):** rode **PHPCompatibility com
  `testVersion 7.x`** sobre a base para inventariar quebras; os pontos clássicos são
  `mysql_*` (removida), `/e` (removido), construtores PHP 4 (deprecados), a mudança de
  semântica do `foreach` e do uniform variable syntax, e o novo mundo `\Throwable`/
  `\Error` (handlers de erro precisam ser revisados). O prêmio: ~2× de performance e
  um runtime com patch de segurança.

**Régua (Art. 1/7):** as surpresas acima, onde relevantes ao projeto, estão
**cobertas por teste** (ex.: teste que prova o comportamento do handler de fatal) e
**comentadas com o porquê** onde a escolha não é óbvia (ex.: por que o ternário-isset
em vez de `??`).

---

## 12. Ferramentas & comandos

Estes comandos alimentam `keelson.config.json → quality.*` — a ponte entre a doutrina
e a automação. Ferramental **de época**, compatível com o runtime 5.6:

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `vendor/bin/phpunit` (PHPUnit **5.7**; 4.8 como fallback) | `quality.test` |
| **lint** | `vendor/bin/phpcs --standard=PSR2 src/ tests/` **+** lint de parse com o binário 5.6 (`vendor/bin/parallel-lint src/ tests/` ou `php -l`) — os dois papéis são distintos e ambos bloqueiam | `quality.lint` |
| **typecheck** | **Limitado nesta versão.** PHPStan/Psalm exigem runtime PHP 7+ e ⚠️ CONFIRMAR: não aceitam `phpVersion` alvo 5.6 — análise com eles gera falsos positivos/negativos. O papel prático de "typecheck" aqui é o **parse-check com binário 5.6 + PHPCompatibility (`testVersion 5.6`)**; se não adotado, `null`. | `quality.typecheck` |
| **build** | **não se aplica** — PHP é interpretado. O deploy é `composer install --no-dev --optimize-autoloader` (Composer 2.2 LTS no servidor, ou moderno com `platform.php` no CI) — não é passo de gate. | `quality.build` (`null`) |

Exemplo de ficha correspondente:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "5.6" } },
  "codePaths": { "backend": ["src"] },
  "quality": {
    "test": "vendor/bin/phpunit",
    "lint": "vendor/bin/phpcs --standard=PSR2 src/ tests/ && vendor/bin/parallel-lint src/ tests/",
    "typecheck": null,
    "build": null
  }
}
```

E o `composer.json` do projeto DEVE fixar a plataforma para resolução reprodutível:

```jsonc
{
  "config": { "platform": { "php": "5.6.40" } }
}
```

**Por quê:** sem estes comandos declarados, o gate não sabe o que rodar — e neste
perfil o lint de **parse com o binário 5.6 real** é o guard mais importante de todos:
é ele que impede a sintaxe 7.x/8.x de chegar viva ao servidor.
