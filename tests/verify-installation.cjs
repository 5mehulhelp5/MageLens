const fs = require('node:fs');
const assert = require('node:assert/strict');
const [theme, runner] = process.argv.slice(2);
assert.ok(['luma', 'hyva', 'hyva-legacy'].includes(theme));
assert.ok(['cypress', 'playwright'].includes(runner));
const manifest = JSON.parse(fs.readFileSync('package.json'));
const lock = JSON.parse(fs.readFileSync('package-lock.json'));
const selected = runner === 'cypress' ? ['cypress', '@cypress/code-coverage'] : ['@playwright/test', 'playwright', 'playwright-core'];
const rejected = runner === 'cypress' ? ['@playwright/test', 'playwright', 'playwright-core'] : ['cypress', '@cypress/code-coverage'];
for (const name of selected) assert.ok(fs.existsSync(`node_modules/${name}/package.json`), `Missing selected runner package: ${name}`);
for (const name of rejected) {
    assert.equal(manifest.devDependencies[name], undefined, `Unselected dependency in manifest: ${name}`);
    assert.equal(lock.packages[`node_modules/${name}`], undefined, `Unselected dependency in lock: ${name}`);
    assert.equal(fs.existsSync(`node_modules/${name}`), false, `Unselected runner installed: ${name}`);
}
assert.equal(fs.existsSync('/opt/cypress'), runner === 'cypress', 'Cypress browser cache must exist only in Cypress installs');
assert.equal(fs.existsSync('/opt/playwright'), runner === 'playwright', 'Playwright browser cache must exist only in Playwright installs');
assert.ok(fs.existsSync('/usr/share/novnc'), 'Both runners need the desktop viewer');
assert.ok(process.env.DISPLAY, 'Both runners need a container display');
require('node:child_process').execFileSync('xdpyinfo', ['-display', process.env.DISPLAY]);
require('node:child_process').execFileSync(process.execPath, ['/opt/magelens/healthcheck.cjs']);
if (runner === 'playwright') assert.equal(require('../playwright.config.cjs').use.headless, false);
assert.equal(fs.readFileSync('.runtime/install-profile', 'utf8').trim(), `${theme} ${runner}`);
const composer = JSON.parse(fs.readFileSync('src/composer.lock'));
assert.equal(composer.packages.some(pkg => pkg.name === 'hyva-themes/magento2-default-theme'), theme === 'hyva-legacy');
assert.equal(composer.packages.some(pkg => pkg.name === 'hyva-themes/magento2-default-theme-csp'), theme === 'hyva');
console.log(`Verified isolated ${theme}/${runner} installation, packages, browsers and persisted selection.`);
