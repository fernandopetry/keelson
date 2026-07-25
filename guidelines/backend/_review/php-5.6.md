# PHP 5.6 — backlog de revisão humana

> Companheiro de `guidelines/backend/php-5.6.md` (`reviewed: false`). Guarda os
> **roteiros de verificação sem valor de runtime** — lido apenas no fluxo de revisão de
> perfil, nunca por implementer/reviewer (a resolução de perfil aponta só para o arquivo
> principal). Afirmações cuja frase já carrega a alternativa/restrição acionável
> permanecem inline no perfil, marcadas `⚠️ não confirmado`.
> Item confirmado pelo revisor → remover a tag no perfil e a entrada aqui; perfil sem
> pendências → promover `reviewed: true` no frontmatter.

## §1/§6 — Backports de distro

Se o servidor usa pacote de distro com backport (RHEL, Debian ELTS, Ubuntu ESM),
verificar **quais** CVEs o backport realmente cobre — cobertura é parcial e varia por
distro.

## §6 — Inventário de CVEs abertos

Levantar o inventário real de CVEs abertos contra a build 5.6 específica do servidor
(via NVD/`/keelson:audit`) — a lista muda conforme a minor/backport.

## §8 — `local-php-security-checker`

Confirmar o estado de manutenção atual do projeto e a cobertura do advisory database.
