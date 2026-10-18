const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {syncDependencies} = require('../bin/sync-dependencies.cjs');
const versions = {CYPRESS_VERSION: '16.2.0', PLAYWRIGHT_VERSION: '1.64.1',
    ISTANBUL_LIB_REPORT_VERSION: '3.0.1', ISTANBUL_REPORTS_VERSION: '3.2.0',
    TEMPLATE_COVERAGE_VERSION: '1.1.2', CYPRESS_CODE_COVERAGE_VERSION: '4.0.3',
    ISTANBUL_LIB_COVERAGE_VERSION: '3.2.2', ISTANBUL_LIB_INSTRUMENT_VERSION: '6.0.3', NYC_VERSION: '18.0.0'};

test('switching installers selects one runner and prunes the old runner from manifests and lock', t => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'magelens-profile-'));
    t.after(() => fs.rmSync(root, {recursive: true, force: true}));
    fs.writeFileSync(path.join(root, 'package.json'), JSON.stringify({name: 'profile-fixture', devDependencies: {unrelated: '1.0.0'}}));
    let resolutions = 0;
    const resolve = (_command, _args, {cwd}) => {
        resolutions++;
        const manifest = JSON.parse(fs.readFileSync(path.join(cwd, 'package.json')));
        fs.writeFileSync(path.join(cwd, 'package-lock.json'), JSON.stringify({lockfileVersion: 3, packages: {
            '': {devDependencies: manifest.devDependencies},
            ...Object.fromEntries(Object.entries(manifest.devDependencies).map(([name, version]) => [`node_modules/${name}`, {version}]))
        }}));
    };
    for (const runner of ['cypress', 'playwright', 'cypress']) {
        syncDependencies(root, {...versions, MAGELENS_RUNNER: runner}, resolve);
        const manifest = JSON.parse(fs.readFileSync(path.join(root, 'package.json')));
        const lock = JSON.parse(fs.readFileSync(path.join(root, 'package-lock.json')));
        for (const name of ['cypress', '@cypress/code-coverage', '@playwright/test']) {
            const expected = runner === 'playwright' ? name === '@playwright/test' : name !== '@playwright/test';
            assert.equal(name in manifest.devDependencies, expected, `${runner}: ${name}`);
            assert.equal(`node_modules/${name}` in lock.packages, expected, `${runner} lock: ${name}`);
        }
        assert.equal(manifest.devDependencies.unrelated, '1.0.0');
        assert.equal(syncDependencies(root, {...versions, MAGELENS_RUNNER: runner}, resolve), false);
    }
    assert.equal(resolutions, 3);
});

test('unknown runners are rejected before modifying the installation', () => {
    assert.throws(() => syncDependencies('/does-not-exist', {...versions, MAGELENS_RUNNER: 'both'}), /runner/i);
});
