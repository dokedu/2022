import promisify from 'cypress-promise'

let _account
beforeEach(async () => {
  const { supabase, account } = await promisify(cy.init_user())
  _account = account
})

describe('Seeds', () => {
  it('should be able seed the db', () => {
    cy.task('testSeed', {
      account_id: _account.id,
    })

    cy.visit('/entries')
    cy.get('[data-cy="entry-body"]').should('have.length', 1)
    cy.get('[data-cy="entry-body"]').eq(0).should('have.text', 'this is a test, coming from a seed.')
  })
})
