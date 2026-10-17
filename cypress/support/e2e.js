require('./javascript-coverage');
const {registerTemplateCoverage} = require('@vitaliiboiko/magento-template-coverage/cypress');
registerTemplateCoverage({outputDir: 'coverage/raw/templates'});

Cypress.on('window:before:load', win => {
    // Cross-document animation snapshots conflict with Cypress's iframe
    // navigation between Hyvä and Admin. Keep normal navigation and error checks.
    win.document.addEventListener('DOMContentLoaded', () => {
        const style = win.document.createElement('style');
        style.textContent = '@view-transition { navigation: none; }';
        win.document.head.append(style);
    }, {once: true});
});

beforeEach(() => {
    const run = Cypress.expose('coverageRun');
    expect(run, 'current PHP collection token').to.match(/^[a-f0-9]{32}$/);
    // Avoid intercepting multipart bodies: header mutation can corrupt binary uploads.
    cy.setCookie('application_coverage', run, {
        domain: new URL(Cypress.config('baseUrl')).hostname, path: '/', sameSite: 'lax', httpOnly: true
    });
});
