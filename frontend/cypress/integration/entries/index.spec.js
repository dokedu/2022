import promisify from 'cypress-promise'

let _account
let _supabase
beforeEach(async () => {
  const { supabase, account } = await promisify(cy.init_user())
  _account = account
  _supabase = supabase
})

it('should show entries', () => {
  cy.task('createTestEntries', _account.id)

  cy.visit('/entries')

  // there should be three entries
  cy.get('[data-cy="entry-body"]').should('have.length', 3)

  // they should contain text.
  cy.get('[data-cy="entry-body"]').should('contain.text', 'Test content.')
  cy.get('[data-cy="entry-body"]').should('contain.text', 'we support emojis. 🥵🔥')
  cy.get('[data-cy="entry-body"]').should('contain.text', '中文文本没问题。')
})
