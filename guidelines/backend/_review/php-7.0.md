# Backlog de revisão humana — `php-7.0.md`

> Companheiro de `guidelines/backend/php-7.0.md` (`reviewed: false`). Roteiro de
> verificação das afirmações `⚠️ não confirmado` do perfil — lido só no fluxo de
> revisão de perfil, nunca em runtime de implementer/reviewer. Afirmação cuja frase já
> carrega a alternativa/restrição acionável permanece inline no perfil, com a tag.
> Item confirmado → corrigir/ratificar no perfil, remover a tag lá e a entrada aqui;
> sem pendências → promover `reviewed: true` no frontmatter.

- **§2** — phpcs: confirmar faixa exata de PHP suportada pelo PHP_CodeSniffer 3.x
  (documentação indica 5.4+) e a versão mínima 3.5 para o ruleset PSR12.
- **§2** — php-cs-fixer 2.x: confirmar em qual release entrou o ruleset `@PSR12`
  (a série começou com `@PSR2`).
- **§2** — PHPCompatibility: confirmar faixa de instalação compatível com phpcs 3.x
  em runtime 7.0.
- **§4** — Observer: confirmar que `psr/event-dispatcher` (PSR-14) requer PHP 7.2 e
  a lib substituta compatível com a era (ex.: `league/event` 2.x).
- **§6** — Backports EOL: se o runtime é de distro enterprise (RHEL/Debian
  LTS/Ubuntu ESM), verificar se o pacote recebe backports de segurança do
  distribuidor.
- **§6.2** — Header injection: confirmar que o bloqueio de CR/LF em `header()`
  (PHP ≥ 5.1.2) cobre os vetores no build 7.0 em uso.
- **§6.4** — phpdotenv: confirmar faixa de versão instalável em 7.0 (2.x é a
  referência da era).
- **§6.4** — Criptografia: confirmar a ausência de AEAD em `openssl_encrypt()` no 7.0
  (`$tag` GCM é 7.1) e as faixas exatas de instalação de `defuse/php-encryption` v2 /
  `paragonie/sodium_compat` / PECL `libsodium` com o Composer da era.
- **§6.5** — SameSite: validar o workaround de header manual
  (`header('Set-Cookie: ...; SameSite=Lax', false)`) — vale o risco/complexidade no
  projeto ou o token CSRF basta?
- **§6.5** — Sessão: confirmar `session.use_strict_mode=1` +
  `session.use_only_cookies=1` no ini de produção (defaults de builds antigos podem
  permitir session id via URL — session fixation).
- **§7** — PHPUnit 6.5: confirmar o FQCN correto do mock em docblock
  (`\PHPUnit_Framework_MockObject_MockObject`, nome legado) antes de padronizar.
- **§8** — Composer: confirmar 2.2 LTS como série máxima que roda em 7.0 (≥ 2.3
  exige 7.2.5+) e a ausência do `composer audit` (chegou no 2.4).
- **§8** — `local-php-security-checker`: confirmar se o projeto segue mantido; se
  arquivado, validar o substituto (`symfony security:check` do Symfony CLI).
- **§9** — Polyfills: confirmar faixa dos pacotes `symfony/polyfill-php7x`/`php80`
  instalável em runtime 7.0.
- **§10** — Profiling: confirmar Xdebug 2.5/2.6 como séries compatíveis com 7.0 e a
  disponibilidade atual de agente Blackfire/Tideways/XHProf para a era.
- **§12** — typecheck: confirmar PHPStan 0.9.x como última série a rodar em runtime
  7.0, ou o suporte ao `phpVersion` alvo rodando PHPStan moderno noutro binário.
