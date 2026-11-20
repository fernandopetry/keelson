# Fixture limpa

Doutrina que cita `commands/alpha.md` e a convenção `docs/_meta/conventions/x.md`.
O diretório `skills/beta/` existe; a âncora `scripts/run.sh:12` também resolve.

Casos que NUNCA acusam: placeholder `{docsRoot}/specs`, glob `commands/*.md`,
exemplo `<slug>`, caminho do consumidor `guidelines/project/lessons.md`,
raiz desconhecida `app/Models/User.php` e nome sem barra `CHANGELOG.md`.

```bash
cat "${CLAUDE_PLUGIN_ROOT}/skills/beta/SKILL.md"
cat docs/naoexiste.md   # fora do prefixo do plugin, fence é ignorada
```
