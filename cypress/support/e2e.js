require('./javascript-coverage');
const {registerTemplateCoverage} = require('@vitaliiboiko/magento-template-coverage/cypress');
registerTemplateCoverage({outputDir: 'coverage/raw/templates'});

Cypress.on('window:before:load', win => {
    // Keep normal navigation and error checks. An adopted sheet also overrides
    // transition rules that Mage-OS renders near the end of the document body.
    const sheet = new win.CSSStyleSheet();
    sheet.replaceSync('@view-transition { navigation: none; }');
    win.document.adoptedStyleSheets = [...win.document.adoptedStyleSheets, sheet];
});

beforeEach(() => {
    const run = Cypress.expose('coverageRun');
    expect(run, 'current PHP collection token').to.match(/^[a-f0-9]{32}$/);
    // Avoid intercepting multipart bodies: header mutation can corrupt binary uploads.
    cy.setCookie('application_coverage', run, {
        domain: new URL(Cypress.config('baseUrl')).hostname, path: '/', sameSite: 'lax', httpOnly: true
    });
});
