# Backlog de revisão humana — `php-7.4.md`

> Companheiro de `guidelines/backend/php-7.4.md` (`reviewed: false`). Roteiro de
> verificação das afirmações `⚠️ não confirmado` do perfil — lido só no fluxo de
> revisão de perfil, nunca em runtime de implementer/reviewer. Afirmação cuja frase já
> carrega a alternativa/restrição acionável permanece inline no perfil, com a tag.
> Item confirmado → corrigir/ratificar no perfil, remover a tag lá e a entrada aqui;
> sem pendências → promover `reviewed: true` no frontmatter.

- **§1/§6** — Backports EOL: confirmar disponibilidade de backports de segurança
  pagos/da distro para 7.4 (Ubuntu Pro/ESM, RHEL, Freexian ELTS) no ambiente real do
  projeto.
- **§2** — php-cs-fixer: confirmar se a release mais recente da série 3.x ainda
  instala sob PHP 7.4; se não, pinar a última cujo `composer.json` aceite `^7.4`.
- **§6.1** — PDO: confirmar default `ERRMODE_SILENT` em 7.4 (mudança para
  `ERRMODE_EXCEPTION` documentada como 8.0).
- **§6.2** — `htmlspecialchars`: confirmar default `ENT_COMPAT | ENT_HTML401` em 7.4
  e a inclusão de `ENT_QUOTES` no default apenas em 8.1.
- **§6.2** — Contexto `<script>`: confirmar o conjunto de flags recomendado
  (`JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP`).
- **§6.4** — phpdotenv: confirmar versão de `vlucas/phpdotenv` compatível com 7.4
  (v4/v5), se o projeto usar `.env`.
- **§6.4** — Argon2: confirmar no binário real, via `password_algos()`, se
  `PASSWORD_ARGON2ID` está disponível (build com libargon2 ≥ 20161029; build com
  libsodium pode prover Argon2 sem libargon2).
- **§6.4** — Custo de hash: confirmar parâmetros (memory/time/threads para Argon2id;
  `cost` para bcrypt) contra a recomendação OWASP vigente.
- **§6.4** — Fallback sem sodium: confirmar `openssl_encrypt` com `aes-256-gcm`
  (autenticado, com tag) como alternativa.
- **§6.5** — `setcookie`: confirmar assinatura com array de opções e diretiva ini
  `session.cookie_samesite` disponíveis desde 7.3.
- **§6.5** — `session.use_strict_mode`: confirmar como mitigação de session fixation
  nesta versão.
- **§8** — LTS congeladas: confirmar se as majors 7.4-compatíveis (Symfony 5.4 LTS,
  Laravel 8, PHPUnit 9) ainda recebem correção de segurança.
- **§8** — `roave/security-advisories`: confirmar instalável sob plataforma 7.4 sem
  conflitar com o lock congelado.
- **§9** — `symfony/polyfill-php80`: confirmar constraint de instalação sob PHP 7.4.
- **§10** — Profiling: confirmar 3.1.x como última série do Xdebug com suporte a 7.4
  e se o Blackfire ainda oferece agente compatível.
