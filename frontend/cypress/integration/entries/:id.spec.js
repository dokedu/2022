import promisify from 'cypress-promise'

let _account
let _supabase
beforeEach(async () => {
  const { supabase, account } = await promisify(cy.init_user())
  console.log(account)
  _account = account
  _supabase = supabase
})

it('should show specific entry', () => {
  cy.task('createTestEntries', _account.id).visit('/entries').wait(500).reload(true)
  // there should be three entries
  cy.get('[data-cy="entry-body"]').should('have.length', 3)

  // open the one with test content
  cy.get('[data-cy="entry-body"]').contains('Test content').click()

  // we should get to the entry page
  cy.url().should('match', /.*\/entries\/.{21}/)

  // the content should be correctly displayed.
  // cy.get('[data-cy="entry-body"]').should('contain.text', 'Test content')
})

it('should be possible to delete an entry', () => {
  cy.task('createTestEntries', _account.id).visit('/entries').wait(500).reload(true)

  // there should be three entries
  cy.get('[data-cy="entry-body"]').should('have.length', 3)

  // open first one
  cy.get('[data-cy="entry-body"]').eq(0).click()

  // press delete it. modal should open
  cy.get('[data-cy="more"]').click()
  cy.get('[data-cy="delete"]').click()
  cy.get('[data-cy="modal"]').should('be.visible')

  // cancel shouldn't delete
  cy.get('[data-cy="modal-cancel"]').click()
  cy.get('[data-cy="modal"]').should('not.exist')

  cy.url().should('match', /.*\/entries\/.{21}/)

  // delete it
  cy.get('[data-cy="more"]').click()
  cy.get('[data-cy="delete"]').click()
  cy.get('[data-cy="modal-confirm"]').click()

  // we should get to the entries page
  cy.url().should('match', /.*\/entries/)

  // there should be two entries
  cy.get('[data-cy="entry-body"]').should('have.length', 2)
})

it('should be possible to open an entry with a deleted competence', () => {
  cy.task('createTestEntryDeletedCompetence', [_account.organisation_id, _account.id])
    .visit('/entries')
    .wait(500)
    .reload(true)

  // there should be one entry
  cy.get('[data-cy="entry-body"]').should('have.length', 1)

  // open first one
  cy.get('[data-cy="entry-body"]').eq(0).click()

  // we should get to the entry page
  cy.url().should('match', /.*\/entries\/.{21}/)

  // the content should be correctly displayed.
  cy.get('[data-cy="entry-body"]').should('contain.text', 'Test content')
  cy.get('[data-cy="entry-competence"]').should('have.length', 3)
  cy.get('[data-cy="entry-competence"]').should('contain.text', 'deleted competence')
  cy.get('[data-cy="entry-competence"]').should('contain.text', 'deleted subject')
  cy.get('[data-cy="entry-competence"]').should('contain.text', 'deleted group')
})
