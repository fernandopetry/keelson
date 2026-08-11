import { test, expect } from '@playwright/test';

// Arquivo de OUTRO slug (@outro): a tag @AC-001-002 daqui NÃO pode contar como
// cobertura de `demo` — AC-NNN-XXX só é inequívoco dentro do próprio slug.
test.describe('relatório @outro', () => {
  test('exporta CSV @AC-001-002', async ({ page }) => {
    await page.goto('/relatorios');
  });
});
