const fs = require('node:fs');
const path = require('node:path');
// Exercise the elgentos package without invoking its interactive installation
// wizard or copying its global setup into MageLens's isolated fixture.
const directory = '.runtime/elgentos';
fs.mkdirSync(directory, {recursive: true});
fs.cpSync('node_modules/@elgentos/magento2-playwright/tests', `${directory}/base-tests`, {recursive: true});
fs.writeFileSync(`${directory}/tsconfig.json`, JSON.stringify({compilerOptions: {baseUrl: '.',
    paths: {'@base/*': ['./base-tests/*'], '@config': ['./base-tests/config'], '@utils/*': ['./base-tests/utils/*'],
        '@poms/*': ['./base-tests/poms/*'], '@types/*': ['./base-tests/types/*'], '@fixtures/*': ['./base-tests/fixtures/*']}}}, null, 2));
const packageFile = path.join(path.dirname(require.resolve('@vitaliiboiko/magento-template-coverage')), '../package.json');
fs.writeFileSync('.runtime/template-package-version', JSON.parse(fs.readFileSync(packageFile)).version + '\n');
