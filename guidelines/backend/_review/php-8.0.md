# Backlog de revisão humana — `php-8.0.md`

Roteiro de verificação das afirmações `⚠️ não confirmado` do perfil
`guidelines/backend/php-8.0.md` (gerado, `reviewed: false`) — lido só no fluxo de
revisão de perfil, nunca em runtime de implementer/reviewer.

- **§1** — Confirmar se o projeto tem contrato ativo de suporte estendido comercial
  (Zend PHP LTS para 8.0, anunciado até dezembro/2025; TuxCare ELS); sem contrato,
  vale a premissa "runtime sem patches" declarada no perfil.
- **§2** — Confirmar qual série do php-cs-fixer 3.x ainda instala sob
  `config.platform.php: 8.0.x` (releases recentes podem ter subido o piso de PHP
  acima de 8.0).
- **§5** — Confirmar no guia de migração 7.4→8.0 que o default do PDO passou a
  `ERRMODE_EXCEPTION` em 8.0.
- **§6.2** — Confirmar que o default de `htmlspecialchars()` em 8.0 ainda é
  `ENT_COMPAT` e que `ENT_QUOTES | ENT_SUBSTITUTE` só virou default no PHP 8.1.
- **§6.3** — Confirmar o alcance da mudança de comparação do 8.0 (número vs string);
  duas strings numéricas seguem comparadas numericamente (`'0e111' == '0e222'`
  continua `true` — magic hash).
- **§6.4** — Confirmar a disponibilidade de `PASSWORD_ARGON2ID` no binário do
  ambiente-alvo (compilação com libargon2, ou libsodium a partir do 7.4);
  `defined('PASSWORD_ARGON2ID')` no ambiente real.
- **§6.5** — Confirmar que `session.use_strict_mode=1` é a prática recomendada
  documentada para a era 8.0 e validar a configuração do ambiente real.
- **§8** — Confirmar na documentação do Composer da versão instalada a composição
  exata das fontes do `composer audit` (Packagist.org security advisories API:
  FriendsOfPHP/security-advisories + advisories do GitHub).
