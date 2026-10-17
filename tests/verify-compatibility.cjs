const fs = require('node:fs');
const assert = require('node:assert/strict');
const read = file => JSON.parse(fs.readFileSync(file));
const php = read('coverage/php/coverage-summary.json');
const js = read('coverage/js/coverage-summary.json');
const templates = read('coverage/templates/coverage-summary.json');
const theme = process.argv[2];
assert.ok(php.requests.some(request => request.method === 'POST' && request.uri.includes('/coverageprobe/index/save')), 'Missing real Magento POST coverage');
assert.ok(php.covered > 0 && php.covered < php.total, 'PHP needs both covered and uncovered lines');
assert.ok(js.total.lines.covered > 0 && js.total.lines.covered < js.total.lines.total, 'JavaScript needs both covered and uncovered lines');
const suffix = theme === 'hyva' ? 'templates/probe-hyva.phtml' : 'web/template/probe.html';
const entry = templates.templates.find(entry => entry.path.endsWith(suffix));
assert.ok(entry && entry.status === 'observed' && entry.statementSummary.covered > 0, `Missing ${theme} execution: ${suffix}`);
const never = entry.source.split('\n').findIndex(line => line.includes('data-cy="probe-never"')) + 1;
assert.equal(entry.lineHits[never]?.hits, 0, 'A false template branch must stay uncovered');
assert.ok(templates.templates.some(entry => entry.path.endsWith('template/unused.html') && entry.status === 'unobserved' && entry.statementSummary.covered === 0));
if (theme === 'hyva') {
    assert.equal(entry.kind, 'browser-phtml');
    assert.ok(entry.statements.some(statement => statement.syntax === 'alpine:model' && statement.hits > 0));
    const unused = entry.statements.find(statement => statement.binding === '@click' && entry.source.split('\n')[statement.start.line - 1].includes('probe-unused'));
    assert.equal(unused.hits, 0, 'Unclicked Alpine events must stay uncovered');
}
console.log(`Verified ${theme} PHP, JavaScript and template execution, including untouched branches and templates.`);
