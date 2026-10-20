const fs = require('node:fs');
const {spawnSync} = require('node:child_process');
const {chromium} = require('@playwright/test');

async function main() {
    if (process.argv.includes('--warmup')) {
        const browser = await chromium.launch({headless: false});
        try {
            const page = await browser.newPage({ignoreHTTPSErrors: true});
            await require('@vitaliiboiko/magento-template-coverage/playwright').installTemplateRuntime(page.context());
            const response = await page.goto(process.env.PLAYWRIGHT_BASE_URL || process.env.CYPRESS_BASE_URL, {timeout: 180000});
            if (!response?.ok()) throw new Error(`Storefront warm-up HTTP ${response?.status()}`);
            await page.waitForLoadState('networkidle', {timeout: 180000});
            fs.writeFileSync('coverage/warmup-results.json', JSON.stringify({runner: 'playwright', status: 'passed'}));
        } finally { await browser.close(); }
        return;
    }
    const result = spawnSync(process.execPath, [require.resolve('@playwright/test/cli'), 'test', '--config=playwright.config.cjs'], {stdio: 'inherit'});
    if (result.error) throw result.error;
    if (result.status !== 0) throw new Error('Playwright failed. Inspect coverage/playwright-results.json and coverage/playwright-artifacts.');
    const tests = JSON.parse(fs.readFileSync('coverage/playwright-results.json'));
    if (tests.status !== 'passed' || !tests.totalTests || tests.totalPassed !== tests.totalTests || tests.totalFailed || tests.totalSkipped || tests.totalPending) {
        throw new Error('The full Playwright suite did not pass.');
    }
}
main().catch(error => {console.error(error); process.exitCode = 1;});
