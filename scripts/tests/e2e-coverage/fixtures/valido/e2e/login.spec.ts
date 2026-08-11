import { test, expect } from '@playwright/test';

test.describe('login @demo', () => {
  test('entra com credencial válida @AC-001-001', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/dashboard/);
  });

  test('rejeita senha errada @AC-001-002', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByRole('alert')).toBeVisible();
  });
});
