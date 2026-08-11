import { test, expect } from '@playwright/test';

// Defeitos plantados: @AC-001-009 não existe na SPEC (tag órfã) e AC-001-002
// não é tagueado em arquivo algum deste slug (ac-sem-spec-e2e).
test.describe('login @demo', () => {
  test('entra com credencial válida @AC-001-001', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/dashboard/);
  });

  test('tag órfã aponta AC inexistente @AC-001-009', async ({ page }) => {
    await page.goto('/login');
  });
});
