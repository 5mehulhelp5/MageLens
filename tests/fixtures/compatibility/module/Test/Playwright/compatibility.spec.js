const {test, expect} = require('../../../../../../../playwright/support.cjs');
test('collects real PHP, JavaScript and template execution', async ({page}) => {
    await page.goto('/coverageprobe/');
    await expect(page.locator('[data-cy="probe-count"]')).toHaveText('0');
    await page.locator('[data-cy="probe-increment"]').click();
    await expect(page.locator('[data-cy="probe-count"]')).toHaveText('1');
    await page.getByRole('textbox', {name: 'Probe name'}).fill('coverage');
    await expect(page.locator('[data-cy="probe-echo"]')).toHaveText('coverage');
    await page.locator('[data-cy="probe-save"]').click();
    await expect(page.locator('[data-cy="probe-saved"]')).toHaveText('Saved coverage');
    await expect(page.locator('[data-cy="probe-item"]')).toHaveCount(2);
    await expect(page.locator('[data-cy="probe-never"]')).toHaveCount(0);
    await page.goto('/customer/account/login/');
    await expect(page.locator('#email')).toBeVisible();
});
test('starts the next test with fresh state', async ({page}) => {
    await page.goto('/coverageprobe/');
    await expect(page.locator('[data-cy="probe-count"]')).toHaveText('0');
    await expect(page.getByRole('textbox', {name: 'Probe name'})).toHaveValue('initial');
});
