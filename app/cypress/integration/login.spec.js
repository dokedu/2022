// login.spec.js created with Cypress
//
// Start writing your Cypress tests below!
// If you're unfamiliar with how Cypress works,
// check out the link below and learn how to write your first test:
// https://on.cypress.io/writing-first-test
import promisify from 'cypress-promise'

describe('Login', () => {
  let _user
  beforeEach(async () => {
    const {supabase, user} = await promisify(cy.init_user())
    _user = user

    // don't use the automatically generated session
    await promisify(supabase.auth._removeSession())
  })

  it('should be able to login', () => {
    cy.visit('/login')
    cy.get('#email').type(_user.email)
    cy.get('#password').type('12345678')
    cy.get('[data-cy="submit"]').click()

    cy.url().should('contain', '/entries')
  })
})
