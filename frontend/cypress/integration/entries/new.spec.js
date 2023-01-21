import promisify from 'cypress-promise'

let _account
let _supabase
beforeEach(async () => {
  const { supabase, account } = await promisify(cy.init_user())
  _account = account
  _supabase = supabase
})

it('should create new entry', () => {
  cy.task('createAccount', [_account.organisation_id, 'student'])
  cy.visit('/entries/new')

  cy.get('[data-cy=entry-description]').type('Test entry')
  cy.get('[data-cy=button-create]').click()

  // we should automatically get to the (newly created) entry page
  cy.url().should('match', /.*\/entries\/.{21}/)
  cy.get('[data-cy="entry-body"]').should('contain.text', 'Test entry')

  // the main page should now show one created entry
  cy.visit('/entries')

  cy.get('[data-cy="entry-body"]').should('have.length', 1)
})
