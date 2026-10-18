describe('Magento storefront coverage compatibility', () => {
    it('collects real PHP, JavaScript and template execution', () => {
        cy.visit('/coverageprobe/');
        cy.get('[data-cy="inline-probe"]').should('have.text', 'inline-ready');
        cy.get('[data-cy="probe-count"]').should('have.text', '0');
        cy.get('[data-cy="probe-increment"]').click();
        cy.get('[data-cy="probe-count"]').should('have.text', '1');
        cy.get('[data-cy="probe-name"]').clear().type('coverage');
        cy.get('[data-cy="probe-echo"]').should('have.text', 'coverage');
        cy.get('[data-cy="probe-save"]').click();
        cy.get('[data-cy="probe-saved"]').should('have.text', 'Saved coverage');
        cy.get('[data-cy="probe-item"]').should('have.length', 2);
        cy.get('[data-cy="probe-never"]').should('not.exist');
        cy.visit('/customer/account/login/');
        cy.get('#email').should('be.visible');
    });
    it('starts the next test with fresh state', () => {
        cy.visit('/coverageprobe/');
        cy.get('[data-cy="inline-probe"]').should('have.text', 'inline-ready');
        cy.get('[data-cy="probe-count"]').should('have.text', '0');
        cy.get('[data-cy="probe-name"]').should('have.value', 'initial');
    });
});
